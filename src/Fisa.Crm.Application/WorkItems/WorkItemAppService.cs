using Fisa.Crm.Application.Database;

namespace Fisa.Crm.Application.WorkItems;

public interface IWorkItemAppService
{
    Task<WorkItemActionResponse> ApplyActionAsync(Guid workItemId, WorkItemActionRequest request, Guid currentUserId, CancellationToken cancellationToken);
}

public sealed class WorkItemAppService : IWorkItemAppService
{
    public static readonly IReadOnlyCollection<WorkItemAction> UiActions = new[]
    {
        WorkItemAction.Submit,
        WorkItemAction.Assign,
        WorkItemAction.StartWork,
        WorkItemAction.SetWaitingInternal,
        WorkItemAction.SetWaitingCustomer,
        WorkItemAction.SetWaitingExternal,
        WorkItemAction.BackToInProgress,
        WorkItemAction.Resolve,
        WorkItemAction.Close,
        WorkItemAction.Cancel,
        WorkItemAction.Reject,
        WorkItemAction.Reopen,
    };

    private readonly IDbConnectionFactory _connectionFactory;
    private readonly IWorkItemStateMachine _stateMachine;
    private readonly IWorkflowRuntimeClient _workflowRuntimeClient;

    public WorkItemAppService(
        IDbConnectionFactory connectionFactory,
        IWorkItemStateMachine stateMachine,
        IWorkflowRuntimeClient workflowRuntimeClient)
    {
        _connectionFactory = connectionFactory;
        _stateMachine = stateMachine;
        _workflowRuntimeClient = workflowRuntimeClient;
    }

    public async Task<WorkItemActionResponse> ApplyActionAsync(
        Guid workItemId,
        WorkItemActionRequest request,
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Action))
        {
            throw new InvalidActionException("Action is required");
        }

        if (!Enum.TryParse<WorkItemAction>(request.Action, ignoreCase: true, out var parsedAction) || !UiActions.Contains(parsedAction))
        {
            throw new InvalidActionException($"Action {request.Action} is not allowed via API");
        }

        await using var connection = (System.Data.Common.DbConnection)_connectionFactory.Create();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        var result = await _stateMachine.ApplyActionAsync(
            workItemId,
            parsedAction,
            new WorkItemActionContext
            {
                CurrentUserId = currentUserId,
                Note = request.Note,
                NewAssigneeId = request.NewAssigneeId,
                Source = request.Source ?? "CRM_API"
            },
            connection,
            transaction);

        if (result.ShouldNotifyWorkflow)
        {
            await _workflowRuntimeClient.NotifyStateChangeAsync(workItemId, result.NewStatus, transaction, cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);

        var allowedNextActions = WorkItemStateMachineRules
            .GetAllowedActionsFromStatus(result.NewStatus)
            .Where(UiActions.Contains)
            .Select(action => action.ToString());

        return new WorkItemActionResponse
        {
            WorkItemId = workItemId,
            OldStatus = result.OldStatus,
            NewStatus = result.NewStatus,
            StatusChanged = result.StatusChanged,
            DisplayStatus = WorkItemStatusDisplay.GetDisplayStatus(result.NewStatus),
            AllowedNextActions = allowedNextActions.ToArray()
        };
    }

}

public sealed class WorkItemActionRequest
{
    public string Action { get; init; } = default!;
    public string? Note { get; init; }
    public Guid? NewAssigneeId { get; init; }
    public string? Source { get; init; }
}

public sealed class WorkItemActionResponse
{
    public Guid WorkItemId { get; init; }
    public string OldStatus { get; init; } = default!;
    public string NewStatus { get; init; } = default!;
    public bool StatusChanged { get; init; }
    public string? DisplayStatus { get; init; }
    public string[] AllowedNextActions { get; init; } = Array.Empty<string>();
}

public sealed class InvalidActionException : BusinessException
{
    public InvalidActionException(string message) : base(message, "InvalidAction")
    {
    }
}
