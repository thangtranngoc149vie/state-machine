using Dapper;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Data;
using System.Runtime.CompilerServices;

namespace Fisa.Crm.Application.WorkItems;

public sealed class WorkItemStateMachine : IWorkItemStateMachine
{
    private readonly IClock _clock;
    private ILogger<WorkItemStateMachine> _logger;
    public WorkItemStateMachine(IClock clock, ILogger<WorkItemStateMachine> logger)
    {
        _clock = clock;
        _logger = logger;
    }
    public async Task<Guid> GetStepAsync(Guid workItemId, IDbConnection connection)
    {
        var sql = @"
SELECT
                        wi.current_step_id
                    FROM public.workflow_instances AS wi
                    WHERE wi.work_item_id = @WorkItemId
                    ORDER BY wi.started_at DESC
                    LIMIT 1";
        var result = await connection.QuerySingleOrDefaultAsync<Guid>(sql, new { WorkItemId = workItemId });
        return result;
    }
    public async Task<int> SetStepStatusAsync(Guid workflowInstanceStepId, string status, IDbConnection connection)
    {
        var sql = @"
UPDATE public.workflow_instance_steps set status = @Status::wf_step_status, updated_at = now()
where id = @WorkflowInstanceStepId";
        var result = await connection.ExecuteAsync(sql, new { WorkflowInstanceStepId = workflowInstanceStepId, Status = status });
        return result;
    }
    public async Task<string> GetWorkflowTemplateCodeOfWorkItem(Guid id, IDbConnection connection)
    {
        var sql = @"select code from workflow_templates where id = (
select workflow_template_id  from work_items where id = @Id
)
";
        var result = await connection.QuerySingleOrDefaultAsync<string>(sql, new { Id = id });
        return result;
    }
    public async Task<WorkItemStateChangeResult> ApplyActionAsync(
        Guid workItemId,
        WorkItemAction action,
        WorkItemActionContext context,
        IDbConnection connection,
        IDbTransaction transaction)
    {
        var workItem = await connection.QuerySingleOrDefaultAsync<WorkItemRecord>(
            "SELECT id, status, assignee_id AS AssigneeId, workflow_instance_id AS WorkflowInstanceId, workflow_template_id AS WorkflowTemplateId, workflow_template_code AS WorkflowTemplateCode, applied_binding_id AS AppliedBindingId, closed_at AS ClosedAt FROM public.work_items WHERE id = @id FOR UPDATE",
            new { id = workItemId },
            transaction);

        if (workItem is null)
        {
            throw new WorkItemNotFoundException(workItemId);
        }

        var oldStatus = workItem.Status ?? WorkItemStatuses.Draft;

        if (!WorkItemStateMachineRules.IsTransitionAllowed(oldStatus, action))
        {
            throw new InvalidTransitionException(action, oldStatus);
        }

        var newStatus = WorkItemStateMachineRules.GetNextStatus(oldStatus, action);

        if (string.Equals(oldStatus, newStatus, StringComparison.OrdinalIgnoreCase))
        {
            return new WorkItemStateChangeResult
            {
                WorkItemId = workItemId,
                OldStatus = oldStatus,
                NewStatus = newStatus,
                StatusChanged = false,
                ShouldNotifyWorkflow = false,
                ShouldPublishEvent = false
            };
        }

        var now = _clock.UtcNow;
        var assigneeId = context.NewAssigneeId ?? workItem.AssigneeId;
        var closedAt = WorkItemStateMachineRules.ShouldSetClosedAt(newStatus)
            ? workItem.ClosedAt ?? now
            : null as DateTimeOffset?;
        _logger.LogInformation("newStataus=" + newStatus);
        await connection.ExecuteAsync(
            @"UPDATE public.work_items
              SET status = @newStatus,
                  updated_at = @now,
                  updated_by = @userId,
                  assignee_id = @assigneeId,
                  closed_at = @closedAt
              WHERE id = @id",
            new
            {
                id = workItemId,
                newStatus,
                now,
                userId = context.CurrentUserId,
                assigneeId,
                closedAt
            },
            transaction);

        await connection.ExecuteAsync(
            @"INSERT INTO public.work_item_state_history (
                    id, work_item_id, from_status, to_status, by_user, note, created_at)
              VALUES (
                    uuid_generate_v4(), @workItemId, @fromStatus, @toStatus, @userId, @note, @now)",
            new
            {
                workItemId,
                fromStatus = oldStatus,
                toStatus = newStatus,
                userId = context.CurrentUserId,
                note = context.Note,
                now
            },
            transaction);

        return new WorkItemStateChangeResult
        {
            WorkItemId = workItemId,
            OldStatus = oldStatus,
            NewStatus = newStatus,
            StatusChanged = true,
            ShouldNotifyWorkflow = WorkItemStateMachineRules.ShouldNotifyWorkflow(action),
            ShouldPublishEvent = true
        };
    }

    public async Task<Guid?> GetNextTransitionStepAsync(Guid workItemId, IDbConnection connection)
    {
        var sql = @"
                    SELECT tr.id
FROM   public.workflow_transitions tr 
WHERE  tr.workflow_template_id = 
(select workflow_template_id from work_items where id = @WorkItemId)
AND  tr.from_step_template_id = (
select step_template_id from workflow_instance_steps where id = 
(select current_step_id from workflow_instances where id =
(select workflow_instance_id from work_items where id = @WorkItemId)
)
)
  AND  COALESCE(tr.is_deleted, false) = false 
ORDER BY COALESCE(tr.order_index, 0)";
        var result = await connection.QueryFirstOrDefaultAsync<Guid?>(sql, new { WorkItemId = workItemId });
        return result;
    }

    public async Task<WorkItemStateChangeResult> ApplyStatusAsync(Guid workItemId, string status, WorkItemAction action, WorkItemActionContext context, IDbConnection connection, IDbTransaction transaction)
    {
        var workItem = await connection.QuerySingleOrDefaultAsync<WorkItemRecord>(
            "SELECT id, status, assignee_id AS AssigneeId, workflow_instance_id AS WorkflowInstanceId, workflow_template_id AS WorkflowTemplateId, workflow_template_code AS WorkflowTemplateCode, applied_binding_id AS AppliedBindingId, closed_at AS ClosedAt FROM public.work_items WHERE id = @id FOR UPDATE",
            new { id = workItemId },
            transaction);

        if (workItem is null)
        {
            throw new WorkItemNotFoundException(workItemId);
        }

        var oldStatus = workItem.Status ?? WorkItemStatuses.Draft;

        var now = _clock.UtcNow;
        var assigneeId = context.NewAssigneeId ?? workItem.AssigneeId;
        var closedAt = WorkItemStateMachineRules.ShouldSetClosedAt(status)
            ? workItem.ClosedAt ?? now
            : null as DateTimeOffset?;

        await connection.ExecuteAsync(
            @"UPDATE public.work_items
              SET status = @status,
                  updated_at = @now,
                  updated_by = @userId,
                  assignee_id = @assigneeId,
                  closed_at = @closedAt
              WHERE id = @id",
            new
            {
                id = workItemId,
                status,
                now,
                userId = context.CurrentUserId,
                assigneeId,
                closedAt
            },
            transaction);

        await connection.ExecuteAsync(
            @"INSERT INTO public.work_item_state_history (
                    id, work_item_id, from_status, to_status, by_user, note, created_at)
              VALUES (
                    uuid_generate_v4(), @workItemId, @fromStatus, @toStatus, @userId, @note, @now)",
            new
            {
                workItemId,
                fromStatus = oldStatus,
                toStatus = status,
                userId = context.CurrentUserId,
                note = context.Note,
                now
            },
            transaction);

        return new WorkItemStateChangeResult
        {
            WorkItemId = workItemId,
            OldStatus = oldStatus,
            NewStatus = status,
            StatusChanged = true,
            ShouldNotifyWorkflow = WorkItemStateMachineRules.ShouldNotifyWorkflow(action),
            ShouldPublishEvent = true
        };
    }
    public async Task<Guid> GetOrgIdOfWorkItem(Guid id, IDbConnection connection)
    {
        var sql = @"select org_id from work_items where id=@id";
        return await connection.QueryFirstOrDefaultAsync<Guid>(sql, new { id = id });

    }
    public async Task<Guid> GetWarehouseIdOfWorkItem(Guid id, IDbConnection connection)
    {
        Guid? result = Guid.Empty;
        var sqlMr = @"select warehouse_id from warehouse.mr_headers mh where work_item_id=@id";
        var sqlReceipt = @"select warehouse_id from warehouse.receipt_headers where work_item_id=@id";
        var sqlIssue = @"select warehouse_id from warehouse.issue_headers where work_item_id=@id";
        result = await connection.QueryFirstOrDefaultAsync<Guid>(sqlMr, new {id=id});
        if (result != null) return result ?? Guid.Empty;
        result = await connection.QueryFirstOrDefaultAsync<Guid>(sqlReceipt, new { id = id });
        if (result != null) return result ?? Guid.Empty;
        result = await connection.QueryFirstOrDefaultAsync<Guid>(sqlIssue, new { id = id });
        if (result != null) return result ?? Guid.Empty;
        return result ?? Guid.Empty;

    }

    public async Task<WorkflowTransitionWithTemplateDto> GetNextTransitionStepDetailAsync(Guid workItemId, IDbConnection connection)
    {
        var sql = @"select tr.*, 
                wt.code workflow_template_code,
                wstf.code from_step_template_code,
                wstf.""order"" from_step_template_order,
                wstt.code to_step_template_code,
                wstt.""order"" to_step_template_order
                from workflow_transitions tr
                left join workflow_templates wt on tr.workflow_template_id = wt.id
                left join workflow_step_templates wstf on tr.from_step_template_id = wstf.id
                left join workflow_step_templates wstt on tr.to_step_template_id = wstt.id 
                WHERE  tr.workflow_template_id = 
                (select workflow_template_id from work_items where id = @WorkItemId)
                AND  tr.from_step_template_id = (
                select step_template_id from workflow_instance_steps where id = 
                (select current_step_id from workflow_instances where id =
                (select workflow_instance_id from work_items where id = @WorkItemId)
                )
                )
                  AND  COALESCE(tr.is_deleted, false) = false 
                ORDER BY COALESCE(tr.order_index, 0)";
        var result = await connection.QueryFirstOrDefaultAsync<WorkflowTransitionWithTemplateDto>(sql, new { WorkItemId = workItemId });
        return result;
    }

    public async Task<string> GetConfigByOrgIdAndKey(Guid org_id, string key, IDbConnection connection)
    {
        var sql = @"SELECT value::text FROM configs WHERE org_id = @org_id AND key = @key";
        var result = await connection.QueryFirstOrDefaultAsync<string>(sql, new { org_id = org_id, key = key });
        return result;
    }
    public async Task<List<string>> GetRoleListOfConfigStepRolesAsync(Guid orgId, string workflowTemplateCode, string stepCode,  IDbConnection connection)
    {
        var result = new List<string>();
        var cfgJson = await GetConfigByOrgIdAndKey(orgId, "assignment_policy:" + workflowTemplateCode, connection);
        if (cfgJson != null)
        {
            var cfg = JsonConvert.DeserializeObject<ConfigAssignmentPolicyWorkflowRoot>
                (cfgJson);
            if (cfg != null && cfg.steps != null)
            {
                var stepCfg = cfg.steps.FirstOrDefault(x => x.stepKey.ToLower() == stepCode.ToLower());
                if (stepCfg != null)
                {
                    result = stepCfg.roles;
                }
            }
        }
        return result;
    }
}
