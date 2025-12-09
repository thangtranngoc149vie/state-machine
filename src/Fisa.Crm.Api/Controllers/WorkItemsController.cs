using Fisa.Crm.Application.WorkItems;
using Microsoft.AspNetCore.Mvc;

namespace Fisa.Crm.Api.Controllers;

[ApiController]
[Route("api/crm/work-items")]
public sealed class WorkItemsController : ControllerBase
{
    private readonly IWorkItemAppService _workItemAppService;

    public WorkItemsController(IWorkItemAppService workItemAppService)
    {
        _workItemAppService = workItemAppService;
    }

    [HttpPost("{id:guid}/actions")]
    [ProducesResponseType(typeof(WorkItemActionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ApplyActionAsync(Guid id, [FromBody] WorkItemActionRequest request, CancellationToken cancellationToken)
    {
        if (!HttpContext.Request.Headers.TryGetValue("X-Current-User-Id", out var currentUserHeader)
            || !Guid.TryParse(currentUserHeader, out var currentUserId))
        {
            return BadRequest(new { error = "MissingCurrentUser", message = "Header X-Current-User-Id is required" });
        }

        try
        {
            var response = await _workItemAppService.ApplyActionAsync(id, request, currentUserId, cancellationToken);
            return Ok(response);
        }
        catch (WorkItemNotFoundException ex)
        {
            return NotFound(new { error = ex.ErrorCode, message = ex.Message });
        }
        catch (InvalidTransitionException ex)
        {
            return BadRequest(new { error = ex.ErrorCode, message = ex.Message });
        }
        catch (InvalidActionException ex)
        {
            return BadRequest(new { error = ex.ErrorCode, message = ex.Message });
        }
    }
}
