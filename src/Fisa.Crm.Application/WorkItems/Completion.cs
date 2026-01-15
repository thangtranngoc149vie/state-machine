using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace Fisa.Crm.Application.WorkItems
{
    public class CompleteWorkflowStepRequest
    {
        public string? Note { get; set; }

        public bool Force { get; set; }

        public JsonDocument? ProcessFormData { get; set; }
        public Guid? WorkflowTransitionId { get; set; }
    }
    public class StepCompletionResponse
    {
        public Guid InstanceId { get; init; }

        public CompletedStepState OldStep { get; init; } = new();

        public ActivatedStepState? NewStep { get; init; }

        public string InstanceStatus { get; init; } = string.Empty;

        public DateTimeOffset? InstanceCompletedAt { get; init; }

        public WorkItemState? WorkItem { get; init; }
    }

    public class CompletedStepState
    {
        public Guid Id { get; init; }

        public string Status { get; init; } = string.Empty;

        public DateTimeOffset? CompletedAt { get; init; }
    }

    public class ActivatedStepState
    {
        public Guid Id { get; init; }

        public string? Name { get; init; }

        public string Status { get; init; } = string.Empty;

        public DateTime? DueDate { get; init; }
    }

    public class WorkItemState
    {
        public Guid Id { get; init; }

        public string Status { get; init; } = string.Empty;

        public DateTimeOffset? ClosedAt { get; init; }
    }
}
