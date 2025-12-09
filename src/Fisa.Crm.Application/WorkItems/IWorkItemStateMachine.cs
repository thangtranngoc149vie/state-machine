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
