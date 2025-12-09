using System.Collections.Immutable;
using System.Linq;

namespace Fisa.Crm.Application.WorkItems;

internal static class WorkItemStateMachineRules
{
    private static readonly ImmutableDictionary<WorkItemAction, ImmutableHashSet<string>> AllowedTransitions =
        new Dictionary<WorkItemAction, ImmutableHashSet<string>>
        {
            [WorkItemAction.Submit] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Draft),
            [WorkItemAction.Assign] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Open, WorkItemStatuses.InProgress),
            [WorkItemAction.StartWork] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Open),
            [WorkItemAction.SetWaitingInternal] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.InProgress),
            [WorkItemAction.SetWaitingCustomer] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.InProgress),
            [WorkItemAction.SetWaitingExternal] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.InProgress),
            [WorkItemAction.BackToInProgress] = ImmutableHashSet.Create(
                StringComparer.OrdinalIgnoreCase,
                WorkItemStatuses.WaitingInternal,
                WorkItemStatuses.WaitingCustomer,
                WorkItemStatuses.WaitingExternal),
            [WorkItemAction.Resolve] = ImmutableHashSet.Create(
                StringComparer.OrdinalIgnoreCase,
                WorkItemStatuses.InProgress,
                WorkItemStatuses.WaitingInternal,
                WorkItemStatuses.WaitingCustomer,
                WorkItemStatuses.WaitingExternal),
            [WorkItemAction.Close] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Resolved),
            [WorkItemAction.Cancel] = ImmutableHashSet.Create(
                StringComparer.OrdinalIgnoreCase,
                WorkItemStatuses.Draft,
                WorkItemStatuses.Open,
                WorkItemStatuses.InProgress,
                WorkItemStatuses.WaitingInternal,
                WorkItemStatuses.WaitingCustomer,
                WorkItemStatuses.WaitingExternal),
            [WorkItemAction.Reject] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Draft, WorkItemStatuses.Open),
            [WorkItemAction.Reopen] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Resolved, WorkItemStatuses.Closed),
            [WorkItemAction.AutoCloseFromWorkflow] = ImmutableHashSet.Create(
                StringComparer.OrdinalIgnoreCase,
                WorkItemStatuses.InProgress,
                WorkItemStatuses.WaitingInternal,
                WorkItemStatuses.WaitingCustomer,
                WorkItemStatuses.WaitingExternal,
                WorkItemStatuses.Resolved),
            [WorkItemAction.Archive] = ImmutableHashSet.Create(StringComparer.OrdinalIgnoreCase, WorkItemStatuses.Closed, WorkItemStatuses.Canceled, WorkItemStatuses.Rejected)
        }.ToImmutableDictionary();

    internal static bool IsTransitionAllowed(string currentStatus, WorkItemAction action)
    {
        if (action == WorkItemAction.Create)
        {
            return true;
        }

        return AllowedTransitions.TryGetValue(action, out var fromStatuses) && fromStatuses.Contains(currentStatus);
    }

    internal static string GetNextStatus(string currentStatus, WorkItemAction action)
        => action switch
        {
            WorkItemAction.Create => string.IsNullOrWhiteSpace(currentStatus) ? WorkItemStatuses.Draft : currentStatus,
            WorkItemAction.Submit => WorkItemStatuses.Open,
            WorkItemAction.Assign => WorkItemStatuses.InProgress,
            WorkItemAction.StartWork => WorkItemStatuses.InProgress,
            WorkItemAction.SetWaitingInternal => WorkItemStatuses.WaitingInternal,
            WorkItemAction.SetWaitingCustomer => WorkItemStatuses.WaitingCustomer,
            WorkItemAction.SetWaitingExternal => WorkItemStatuses.WaitingExternal,
            WorkItemAction.BackToInProgress => WorkItemStatuses.InProgress,
            WorkItemAction.Resolve => WorkItemStatuses.Resolved,
            WorkItemAction.Close => WorkItemStatuses.Closed,
            WorkItemAction.Cancel => WorkItemStatuses.Canceled,
            WorkItemAction.Reject => WorkItemStatuses.Rejected,
            WorkItemAction.Reopen => WorkItemStatuses.InProgress,
            WorkItemAction.AutoCloseFromWorkflow => WorkItemStatuses.Closed,
            WorkItemAction.Archive => WorkItemStatuses.Archived,
            _ => currentStatus
        };

    internal static bool ShouldNotifyWorkflow(WorkItemAction action)
        => action is WorkItemAction.Close
            or WorkItemAction.Cancel
            or WorkItemAction.Reopen
            or WorkItemAction.AutoCloseFromWorkflow;

    internal static bool ShouldSetClosedAt(string status)
        => status is WorkItemStatuses.Closed or WorkItemStatuses.Canceled or WorkItemStatuses.Rejected or WorkItemStatuses.Archived;

    internal static IReadOnlyCollection<WorkItemAction> GetAllowedActionsFromStatus(string status)
    {
        var allowedActions = AllowedTransitions
            .Where(kvp => kvp.Value.Contains(status))
            .Select(kvp => kvp.Key)
            .ToArray();

        if (string.IsNullOrWhiteSpace(status))
        {
            return allowedActions.Append(WorkItemAction.Create).ToArray();
        }

        return allowedActions;
    }
}
