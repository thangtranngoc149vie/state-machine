using Fisa.Crm.Application.WorkItems;
using Xunit;

namespace Fisa.Crm.Tests;

public class WorkItemStateMachineRulesTests
{
    [Theory]
    [InlineData(WorkItemStatuses.Draft, WorkItemAction.Submit, WorkItemStatuses.Open)]
    [InlineData(WorkItemStatuses.Open, WorkItemAction.StartWork, WorkItemStatuses.InProgress)]
    [InlineData(WorkItemStatuses.InProgress, WorkItemAction.SetWaitingCustomer, WorkItemStatuses.WaitingCustomer)]
    [InlineData(WorkItemStatuses.WaitingCustomer, WorkItemAction.BackToInProgress, WorkItemStatuses.InProgress)]
    [InlineData(WorkItemStatuses.Resolved, WorkItemAction.Close, WorkItemStatuses.Closed)]
    [InlineData(WorkItemStatuses.Closed, WorkItemAction.Archive, WorkItemStatuses.Archived)]
    [InlineData(WorkItemStatuses.Resolved, WorkItemAction.Reopen, WorkItemStatuses.InProgress)]
    public void GetNextStatus_ReturnsExpectedStatus(string from, WorkItemAction action, string expected)
    {
        Assert.True(WorkItemStateMachineRules.IsTransitionAllowed(from, action));
        Assert.Equal(expected, WorkItemStateMachineRules.GetNextStatus(from, action));
    }

    [Theory]
    [InlineData(WorkItemStatuses.Closed, WorkItemAction.SetWaitingCustomer)]
    [InlineData(WorkItemStatuses.Canceled, WorkItemAction.Reopen)]
    [InlineData(WorkItemStatuses.Draft, WorkItemAction.Close)]
    [InlineData(WorkItemStatuses.Resolved, WorkItemAction.Assign)]
    public void IsTransitionAllowed_RejectsInvalidMoves(string from, WorkItemAction action)
    {
        Assert.False(WorkItemStateMachineRules.IsTransitionAllowed(from, action));
    }

    [Theory]
    [InlineData(WorkItemAction.Close, true)]
    [InlineData(WorkItemAction.Cancel, true)]
    [InlineData(WorkItemAction.Reopen, true)]
    [InlineData(WorkItemAction.AutoCloseFromWorkflow, true)]
    [InlineData(WorkItemAction.Resolve, false)]
    public void ShouldNotifyWorkflow_FollowsSpec(WorkItemAction action, bool expected)
    {
        Assert.Equal(expected, WorkItemStateMachineRules.ShouldNotifyWorkflow(action));
    }

    [Fact]
    public void GetAllowedActionsFromStatus_ReturnsNextSteps()
    {
        var fromWaitingCustomer = WorkItemStateMachineRules.GetAllowedActionsFromStatus(WorkItemStatuses.WaitingCustomer);
        Assert.Contains(WorkItemAction.Resolve, fromWaitingCustomer);
        Assert.Contains(WorkItemAction.BackToInProgress, fromWaitingCustomer);
        Assert.Contains(WorkItemAction.Cancel, fromWaitingCustomer);

        var fromClosed = WorkItemStateMachineRules.GetAllowedActionsFromStatus(WorkItemStatuses.Closed);
        Assert.Contains(WorkItemAction.Archive, fromClosed);
        Assert.Contains(WorkItemAction.Reopen, fromClosed);
    }
}
