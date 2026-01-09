using Fisa.Crm.Application.Database;
using Microsoft.Extensions.Configuration;
using RestSharp;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace Fisa.Crm.Application.WorkItems;

public interface IWorkItemAppService
{
    Task<WorkItemActionResponse> ApplyActionAsync(Guid workItemId, WorkItemActionRequest request, Guid currentUserId, CancellationToken cancellationToken);
    Task<WorkItemActionResponse> ApplyStatusAsync(Guid workItemId, string status, WorkItemActionRequest request, Guid currentUserId, CancellationToken cancellationToken);
    Task<Guid?> GetNextTransitionStepAsync(Guid workItemId, CancellationToken cancellationToken);
    Task<Guid?> GetStepAsync(Guid workItemId, CancellationToken cancellationToken);
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
        var stepId = await _stateMachine.GetStepAsync(workItemId, connection);
        return new WorkItemActionResponse
        {
            WorkItemId = workItemId,
            OldStatus = result.OldStatus,
            NewStatus = result.NewStatus,
            StatusChanged = result.StatusChanged,
            DisplayStatus = WorkItemStatusDisplay.GetDisplayStatus(result.NewStatus),
            AllowedNextActions = allowedNextActions.ToArray(),
            StepId = stepId
        };
    }

    public async Task<WorkItemActionResponse> ApplyStatusAsync(Guid workItemId, string status, WorkItemActionRequest request, Guid currentUserId, CancellationToken cancellationToken)
    {
        await using var connection = (System.Data.Common.DbConnection)_connectionFactory.Create();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);
        Enum.TryParse<WorkItemAction>(request.Status, ignoreCase: true, out var parsedAction);
        var result = await _stateMachine.ApplyStatusAsync(
            workItemId,
            status,
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

        //if (result.ShouldNotifyWorkflow)
        //{
        //    await _workflowRuntimeClient.NotifyStateChangeAsync(workItemId, result.NewStatus, transaction, cancellationToken);
        //}

        await transaction.CommitAsync(cancellationToken);

        var allowedNextActions = WorkItemStateMachineRules
            .GetAllowedActionsFromStatus(result.NewStatus)
            .Where(UiActions.Contains)
            .Select(action => action.ToString());
        var stepId = await _stateMachine.GetStepAsync(workItemId, connection);
        return new WorkItemActionResponse
        {
            WorkItemId = workItemId,
            OldStatus = result.OldStatus,
            NewStatus = result.NewStatus,
            StatusChanged = result.StatusChanged,
            DisplayStatus = WorkItemStatusDisplay.GetDisplayStatus(result.NewStatus),
            AllowedNextActions = allowedNextActions.ToArray(),
            StepId = stepId
        };
    }

    public async Task<Guid?> GetNextTransitionStepAsync(Guid workItemId, CancellationToken cancellationToken)
    {
        await using var connection = (System.Data.Common.DbConnection)_connectionFactory.Create();
        await connection.OpenAsync(cancellationToken);
        return await _stateMachine.GetNextTransitionStepAsync(workItemId, connection);
    }

    public async Task<Guid?> GetStepAsync(Guid workItemId, CancellationToken cancellationToken)
    {
        await using var connection = (System.Data.Common.DbConnection)_connectionFactory.Create();
        await connection.OpenAsync(cancellationToken);
        return await _stateMachine.GetStepAsync(workItemId, connection);
    }
}

public sealed class WorkItemActionRequest
{
    public string Action { get; init; } = default!;
    public string? Note { get; init; }
    public Guid? NewAssigneeId { get; init; }
    public string? Source { get; init; }
    public string? Status { get; set; }
}

public class WorkItemActionResponse
{
    public Guid WorkItemId { get; init; }
    public string OldStatus { get; init; } = default!;
    public string NewStatus { get; init; } = default!;
    public bool StatusChanged { get; init; }
    public string? DisplayStatus { get; init; }
    public string[] AllowedNextActions { get; init; } = Array.Empty<string>();
    public Guid? StepId { get; set; }
    public StepCompletionResponse? StepCompletionResponse { get; set; }
    public string? StepCompletionError { get; set; }
    public string? StepCompletionStatus { get; set; }
}

public class InvalidActionException : BusinessException
{
    public InvalidActionException(string message) : base(message, "InvalidAction")
    {
    }
}

public class WorkItemActionToOutbox
{
    public Guid id { get; set; }
    public string old_status { get; set; }
    public string new_status { get; set; }
    public string note { get; set; }
}


