using System.Data;
using Dapper;

namespace Fisa.Crm.Application.WorkItems;

public sealed class WorkItemStateMachine : IWorkItemStateMachine
{
    private readonly IClock _clock;

    public WorkItemStateMachine(IClock clock)
    {
        _clock = clock;
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
}
