using System.Data;

namespace Fisa.Crm.Application.WorkItems;

public interface IWorkItemStateMachine
{
    Task<WorkItemStateChangeResult> ApplyActionAsync(
        Guid workItemId,
        WorkItemAction action,
        WorkItemActionContext context,
        IDbConnection connection,
        IDbTransaction transaction);
    Task<WorkItemStateChangeResult> ApplyStatusAsync(
        Guid workItemId,
        string status,
        WorkItemAction action,
        WorkItemActionContext context,
        IDbConnection connection,
        IDbTransaction transaction);
    Task<Guid> GetStepAsync(Guid workItemId, IDbConnection connection);
    Task<Guid?> GetNextTransitionStepAsync(Guid workItemId, IDbConnection connection);
    Task<WorkflowTransitionWithTemplateDto> GetNextTransitionStepDetailAsync(Guid workItemId, IDbConnection connection);
    Task<int> SetStepStatusAsync(Guid workflowInstanceStepId, string status, IDbConnection connection);
    Task<string> GetWorkflowTemplateCodeOfWorkItem(Guid id, IDbConnection connection);
    Task<Guid> GetWarehouseIdOfWorkItem(Guid id, IDbConnection connection);
    Task<Guid> GetOrgIdOfWorkItem(Guid id, IDbConnection connection);
    Task<List<string>> GetRoleListOfConfigStepRolesAsync(Guid orgId, string workflowTemplateCode, string stepCode, IDbConnection connection);
}

public sealed class WorkItemActionContext
{
    public Guid CurrentUserId { get; init; }
    public string? Note { get; init; }
    public Guid? NewAssigneeId { get; init; }
    public string Source { get; init; } = "CRM_UI";
}

public sealed class WorkItemStateChangeResult
{
    public Guid WorkItemId { get; init; }
    public string OldStatus { get; init; } = default!;
    public string NewStatus { get; init; } = default!;
    public bool StatusChanged { get; init; }
    public bool ShouldNotifyWorkflow { get; init; }
    public bool ShouldPublishEvent { get; init; } = true;
}

public interface IClock
{
    DateTimeOffset UtcNow { get; }
}

public class BusinessException : Exception
{
    public string ErrorCode { get; }

    public BusinessException(string message, string errorCode = "BusinessError") : base(message)
    {
        ErrorCode = errorCode;
    }
}

public sealed class WorkItemNotFoundException : BusinessException
{
    public WorkItemNotFoundException(Guid workItemId)
        : base($"Work item {workItemId} not found", "WorkItemNotFound")
    {
    }
}

public sealed class InvalidTransitionException : BusinessException
{
    public InvalidTransitionException(WorkItemAction action, string status)
        : base($"Action {action} is not allowed from status {status}", "InvalidTransition")
    {
    }
}

public class WorkflowTransitionWithTemplateDto
{
    public Guid id { get; set; }
    public Guid? workflow_template_id { get; set; }
    public string? workflow_template_code { get; set; }
    public string? name { get; set; }
    public string? label { get; set; }
    public string? transition_type { get; set; }
    public int? order_index { get; set; }
    public Guid? from_step_template_id { get; set; }
    public string? from_step_template_code { get; set; }
    public int? from_step_template_order { get; set; }
    public Guid? to_step_template_id { get; set; }
    public string? to_step_template_code { get; set; }
    public int? to_step_template_order { get; set; }
}
public class ConfigAssignmentPolicyWorkflowRoot
{
    public List<ConfigAssignmentPolicyWorkflowStep> steps { get; set; }
    public string workflowCode { get; set; }
}
public class ConfigAssignmentPolicyWorkflowStep
{
    public string? mode { get; set; }
    public string? stepKey { get; set; }
    public List<string> roles { get; set; }
    public string? ownerRole { get; set; }
}