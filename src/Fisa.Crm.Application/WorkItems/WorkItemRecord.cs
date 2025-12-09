namespace Fisa.Crm.Application.WorkItems;

public sealed class WorkItemRecord
{
    public Guid Id { get; init; }
    public string Status { get; init; } = WorkItemStatuses.Draft;
    public Guid? AssigneeId { get; init; }
    public Guid? WorkflowInstanceId { get; init; }
    public Guid? WorkflowTemplateId { get; init; }
    public string? WorkflowTemplateCode { get; init; }
    public Guid? AppliedBindingId { get; init; }
    public DateTimeOffset? ClosedAt { get; init; }
}
