namespace Fisa.Crm.Application.WorkItems;

public enum WorkItemAction
{
    Create,
    Submit,
    Assign,
    StartWork,
    SetWaitingInternal,
    SetWaitingCustomer,
    SetWaitingExternal,
    BackToInProgress,
    Resolve,
    Close,
    Cancel,
    Reject,
    Reopen,
    AutoCloseFromWorkflow,
    Archive
}
