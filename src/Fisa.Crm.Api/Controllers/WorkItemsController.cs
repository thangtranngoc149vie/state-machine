using Fisa.Crm.Application.WorkItems;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using RestSharp;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;

namespace Fisa.Crm.Api.Controllers;

[ApiController]
[Route("api/crm/work-items")]
public sealed class WorkItemsController : ControllerBase
{
    private readonly IWorkItemAppService _workItemAppService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<WorkItemsController> _logger;

    public WorkItemsController(IWorkItemAppService workItemAppService, IConfiguration configuration, ILogger<WorkItemsController> logger)
    {
        _workItemAppService = workItemAppService;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpPost("{id:guid}/actions")]
    [ProducesResponseType(typeof(WorkItemActionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ApplyActionAsync(Guid id, [FromBody] WorkItemActionRequest request, CancellationToken cancellationToken)
    {
        var prefix = $"ApplyActionAsync {id} ";
        _logger.LogInformation(prefix + JsonConvert.SerializeObject(request));
        if (!HttpContext.Request.Headers.TryGetValue("X-Current-User-Id", out var currentUserHeader)
            || !Guid.TryParse(currentUserHeader, out var currentUserId))
        {
            _logger.LogError(prefix + "BadRequest MissingCurrentUser");
            return BadRequest(new { error = "MissingCurrentUser", message = "Header X-Current-User-Id is required" });
        }

        try
        {
            WorkItemActionResponse response = null;
            if (request.Action.ToLower() != "resolve" && request.Action.ToLower() != "close")
            {
                _logger.LogInformation(prefix + "not resolve, not close");
                response = await _workItemAppService.ApplyActionAsync(id, request, currentUserId, cancellationToken);
                _logger.LogInformation(prefix + "response=" + JsonConvert.SerializeObject(response));
                ThreadPool.QueueUserWorkItem(async _ =>
                {
                    try
                    {
                        var notiInput = new WorkItemActionToOutbox()
                        {
                            note = request.Note,
                            old_status = response.OldStatus,
                            new_status = response.NewStatus,
                            id = id
                        };
                        var r = await SendNotification(notiInput);
                    }
                    catch (Exception e)
                    {
                        _logger.LogError(prefix + "Noti Err: " + e.Message + e.StackTrace);
                    }
                });
            }
            else
            {
                _logger.LogInformation(prefix + "Call completion");
                var currentStepId = await _workItemAppService.GetStepAsync(id, cancellationToken);
                var nextStepId = await _workItemAppService.GetNextTransitionStepAsync(id, cancellationToken);
                if (nextStepId == null)
                {
                    response = await _workItemAppService.ApplyActionAsync(id, request, currentUserId, cancellationToken);
                    ThreadPool.QueueUserWorkItem(async _ =>
                    {
                        try
                        {
                            var notiInput = new WorkItemActionToOutbox()
                            {
                                note = request.Note,
                                old_status = response.OldStatus,
                                new_status = response.NewStatus,
                                id = id
                            };
                            var r = await SendNotification(notiInput);
                        }
                        catch (Exception e)
                        {
                            _logger.LogError(prefix + "Noti Err: " + e.Message + e.StackTrace);
                        }
                    });
                }
                else
                {
                    response = await _workItemAppService.ApplyStatusAsync(id, "in_progress", request, currentUserId, cancellationToken);
                    ThreadPool.QueueUserWorkItem(async _ =>
                    {
                        try
                        {
                            var notiInput = new WorkItemActionToOutbox()
                            {
                                note = request.Note,
                                old_status = response.OldStatus,
                                new_status = response.NewStatus,
                                id = id
                            };
                            var r = await SendNotification(notiInput);
                            
                        }
                        catch (Exception e)
                        {
                            _logger.LogError(prefix + "Noti Err: " + e.Message + e.StackTrace);
                        }
                    });
                }
                var completionResponse = await CompleteWorkflowStep(currentStepId.Value, request.Note, Guid.Parse(currentUserHeader.FirstOrDefault()));
                var stepCompletionStatus = completionResponse.StatusCode.ToString();
                var stepCompletionError = completionResponse.ErrorMessage;
                StepCompletionResponse stepCompletionResponse = null;
                if (completionResponse.IsSuccessful)
                {
                    stepCompletionResponse = completionResponse.Data;
                }
                _logger.LogInformation(prefix + "stepId=" + currentStepId);
                _logger.LogInformation(prefix + "nextTransitionStepId=" + nextStepId);

                if (response != null)
                {
                    response.StepCompletionStatus = stepCompletionStatus;
                    response.StepCompletionResponse = stepCompletionResponse;
                    response.StepCompletionError = stepCompletionError;
                }
                _logger.LogInformation(prefix + "final response=" + JsonConvert.SerializeObject(response));
            }
            
            return Ok(response);
        }
        catch (WorkItemNotFoundException ex)
        {
            _logger.LogError(prefix + "BadRequest NotFound");
            return NotFound(new { error = ex.ErrorCode, message = ex.Message });
        }
        catch (InvalidTransitionException ex)
        {
            _logger.LogError(prefix + "BadRequest InvalidTransitionException");
            return BadRequest(new { error = ex.ErrorCode, message = ex.Message });
        }
        catch (InvalidActionException ex)
        {
            _logger.LogError(prefix + "BadRequest InvalidTransitionException");
            return BadRequest(new { error = ex.ErrorCode, message = ex.Message });
        }
        catch (Exception e)
        {
            _logger.LogError(prefix + "ERR: " + e.Message + e.StackTrace);
            return StatusCode(500, e.Message + e.StackTrace);
        }
    }

    private async Task<RestResponse> SendNotification(WorkItemActionToOutbox input)
    {
        var options = new RestClientOptions("http://localhost:5000");
        var client = new RestClient(options);

        // 2. Create the input data
        var body = input;
        _logger.LogInformation("body=" + JsonConvert.SerializeObject(input));
        // 3. Create the request
        var request = new RestRequest($"/api/outboxevents/work_items_status?id={input.id}&old_status={input.old_status}&new_status={input.new_status}&note={input.note}", Method.Get);

        // RestSharp handles "Content-Type: application/json" by default with AddJsonBody.
        // Since your curl used "application/json-patch+json", we specify it here:
        request.AddBody(body, "application/json-patch+json");

        // 4. Execute the request
        var response = await client.ExecuteAsync(request);
        _logger.LogInformation("noti" + response.IsSuccessful);
        _logger.LogInformation("noti" + response.StatusCode);
        _logger.LogInformation("noti" + response.StatusDescription);
        _logger.LogInformation("noti" + response.Content);
        return response;
    }

    private async Task<RestResponse<StepCompletionResponse>> CompleteWorkflowStep(Guid stepId, string note, Guid userId)
    {
        // 1. Create the client
        var client = new RestClient(_configuration.GetValue<string>("CompletionDomain"));

        // 2. Create the request resource (URL path)
        var request = new RestRequest($"workflow-instance-steps/{stepId}/complete", Method.Post);
        request.AddHeader("X-User-Id", $"{userId.ToString()}");

        // RestSharp may automatically add the Content-Type header when using AddJsonBody/AddBody, 
        // but it's often safer to include it.

        // 4. Create an instance of your class with the required data
        var requestBody = new CompleteWorkflowStepRequest
        {
            Note = note,
            Force = false,
            ProcessFormData = null
        };

        // 5. Add the class instance as the JSON body
        // RestSharp will automatically serialize the C# object (requestBody) into the required JSON format.
        request.AddBody(requestBody);
        // *Note*: In RestSharp version 107+, the modern method is request.AddBody(requestBody), 
        // which defaults to JSON serialization.

        // 6. Execute the request
        RestResponse<StepCompletionResponse> response = null;
        response = await client.ExecuteAsync<StepCompletionResponse>(request);
        return response;
    }
}
