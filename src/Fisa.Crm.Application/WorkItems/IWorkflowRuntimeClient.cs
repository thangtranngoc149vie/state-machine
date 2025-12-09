using System.Data;

namespace Fisa.Crm.Application.WorkItems;

public interface IWorkflowRuntimeClient
{
    Task NotifyStateChangeAsync(Guid workItemId, string newStatus, IDbTransaction transaction, CancellationToken cancellationToken);
}

public sealed class NoopWorkflowRuntimeClient : IWorkflowRuntimeClient
{
    public Task NotifyStateChangeAsync(Guid workItemId, string newStatus, IDbTransaction transaction, CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
