# FISA CRM – Work Item State Machine & Workflow Integration v1

> **Mục đích tài liệu**: để dev nhìn vào là biết **cần code những gì**, ở **layer nào**, đó là **API, service hay worker**, và cách các phần này **phối hợp với Workflow Engine Runtime v1**.

---

## 1. Mục tiêu & phạm vi

### 1.1. Mục tiêu

- Định nghĩa **state machine cho **`` theo bộ trạng thái đã chốt (draft/open/in\_progress/waiting\_\*/resolved/closed/canceled/rejected/archived).
- Chuẩn hoá cách **thay đổi trạng thái work item** thông qua **actions**, không cho phép set status trực tiếp.
- Mô tả cách **phối hợp** giữa:
  - **CRM Work Item Layer** (API màn Tạo / Xử lý yêu cầu), và
  - **Workflow Engine Runtime v1** (instances, steps, tasks, transitions).
- Chỉ rõ **dev phải code những gì**: controller API, application service, state machine service, wiring với Workflow Engine, worker.

### 1.2. Phạm vi

- Không thay đổi DB (bám theo `schema_dump_v7i.sql`).
- Không phá contract hiện tại với Workflow Engine Runtime v1, chỉ bổ sung thêm integration và refactor nhẹ cho đúng state machine.
- Tài liệu này là **guideline implement** cho team .NET 8 + Dapper.

---

## 2. Tổng quan kiến trúc code

### 2.1. Các project/layer liên quan (gợi ý)

Trong solution FISA hiện tại, giả định có cấu trúc (có thể khác chút, nhưng ý là tách layer):

- `Fisa.Crm.Api`              → Web API (controllers)
- `Fisa.Crm.Application`      → Application service, use cases (CQRS/Services)
- `Fisa.Crm.Domain`           → Entities, enums, domain logic đơn giản
- `Fisa.Crm.Infrastructure`   → Dapper repo, DB access
- `Fisa.WorkflowEngine.*`     → Runtime v1 (đã có)

**State Machine** sẽ nằm ở:

- Interface ở `Fisa.Crm.Application`.
- Implement ở `Fisa.Crm.Application` (hoặc tách sang `Fisa.Crm.Domain` nếu muốn domain-driven hơn).
- Repo/Dapper vẫn nằm ở `Fisa.Crm.Infrastructure`.

### 2.2. Đường đi của 1 action

Ví dụ user bấm nút **"Đóng yêu cầu (Close)"** trên màn hình xử lý yêu cầu:

1. FE gọi API: `POST /api/crm/work-items/{id}/actions` với body `{ "action": "CLOSE", "note": "..." }`.
2. `WorkItemsController` (CRM API) nhận request.
3. Gọi xuống `IWorkItemAppService.CloseAsync(id, requestDto)`.
4. `WorkItemAppService` mở transaction, gọi `IWorkItemStateMachine.ApplyActionAsync(...)`.
5. `IWorkItemStateMachine`:
   - Load work item FOR UPDATE.
   - Validate action với status hiện tại.
   - Tính `newStatus`.
   - Update `work_items` + insert `work_item_state_history`.
   - Trả về `WorkItemStateChangeResult` (old/new status, flags cần sync với workflow).
6. `WorkItemAppService` nếu thấy cần sync với Workflow Engine (ví dụ action CLOSE):
   - Gọi `IWorkflowRuntimeService.CompleteCloseStepAsync(workItemId, ...)` hoặc gửi outbox event tuỳ kiến trúc.
7. Commit transaction.
8. Controller trả JSON kết quả cho FE.

Tóm lại: **API (controller)** → **Application Service** → **State Machine** → **(Workflow Engine)**.

---

## 3. Bộ trạng thái Work Item (tóm tắt)

- Pre-intake: `draft`, `open`.
- Active: `in_progress`, `waiting_internal`, `waiting_customer`, `waiting_external`.
- Done kỹ thuật: `resolved`.
- Kết thúc: `closed`, `canceled`, `rejected`, `archived`.

Chi tiết ý nghĩa đã nằm trong tài liệu `FISA_CRM_WorkItem_Status_Design_v1.md`, ở đây dùng để build state machine.

---

## 4. Khái niệm Action & danh sách action

### 4.1. Tại sao dùng Action

- Tránh việc các nơi trong code tự `UPDATE work_items SET status = ...`.
- Gom mọi thay đổi trạng thái qua **1 service duy nhất** (state machine) để:
  - Kiểm soát logic.
  - Ghi lịch sử.
  - Sync với SLA & Workflow.

### 4.2. Enum `WorkItemAction`

Dev cần tạo enum (hoặc static class) ở `Fisa.Crm.Domain` hoặc `Fisa.Crm.Application`:

```csharp
public enum WorkItemAction
{
    Create,             // internal
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
    AutoCloseFromWorkflow, // internal - do Workflow Engine gọi
    Archive
}
```

- FE **không cần** biết hết enum này; API sẽ expose một số action code dưới dạng string.

---

## 5. Bảng state machine – allowed transitions

### 5.1. Bảng From → To theo Action

| Action                  | From states                                                | To state            |
| ----------------------- | ---------------------------------------------------------- | ------------------- |
| `Create` (internal)     | —                                                          | `draft` hoặc `open` |
| `Submit`                | `draft`                                                    | `open`              |
| `Assign`                | `open`, `in_progress`                                      | `in_progress`       |
| `StartWork`             | `open`                                                     | `in_progress`       |
| `SetWaitingInternal`    | `in_progress`                                              | `waiting_internal`  |
| `SetWaitingCustomer`    | `in_progress`                                              | `waiting_customer`  |
| `SetWaitingExternal`    | `in_progress`                                              | `waiting_external`  |
| `BackToInProgress`      | `waiting_internal`, `waiting_customer`, `waiting_external` | `in_progress`       |
| `Resolve`               | `in_progress`, `waiting_*`                                 | `resolved`          |
| `Close`                 | `resolved`                                                 | `closed`            |
| `Cancel`                | `draft`, `open`, `in_progress`, `waiting_*`                | `canceled`          |
| `Reject`                | `draft`, `open`                                            | `rejected`          |
| `Reopen`                | `resolved`, `closed`                                       | `in_progress`       |
| `AutoCloseFromWorkflow` | `in_progress`, `waiting_*`, `resolved`                     | `closed`            |
| `Archive`               | `closed`, `canceled`, `rejected`                           | `archived`          |

Dev cần implement bảng này bằng code (switch-case, dictionary…).

---

## 6. Interface & implementation chi tiết

### 6.1. Interface `IWorkItemStateMachine` (Application layer)

File gợi ý: `Fisa.Crm.Application/WorkItems/IWorkItemStateMachine.cs`

```csharp
public interface IWorkItemStateMachine
{
    Task<WorkItemStateChangeResult> ApplyActionAsync(
        Guid workItemId,
        WorkItemAction action,
        WorkItemActionContext context,
        IDbConnection connection,
        IDbTransaction transaction);
}
```

**Dev cần tạo thêm 2 class:**

```csharp
public sealed class WorkItemActionContext
{
    public Guid CurrentUserId { get; init; }
    public string? Note { get; init; }
    public Guid? NewAssigneeId { get; init; }
    public string Source { get; init; } = "CRM_UI"; // hoặc "WORKFLOW_ENGINE"...
}

public sealed class WorkItemStateChangeResult
{
    public Guid WorkItemId { get; init; }
    public string OldStatus { get; init; } = default!;
    public string NewStatus { get; init; } = default!;
    public bool StatusChanged { get; init; }

    // Flags hỗ trợ integration
    public bool ShouldNotifyWorkflow { get; init; }
    public bool ShouldPublishEvent { get; init; } = true;
}
```

### 6.2. Implement `WorkItemStateMachine` (Application layer)

File gợi ý: `Fisa.Crm.Application/WorkItems/WorkItemStateMachine.cs`

Pseudo-code chi tiết:

```csharp
public sealed class WorkItemStateMachine : IWorkItemStateMachine
{
    private readonly IClock _clock; // abstraction cho DateTimeOffset.UtcNow

    public async Task<WorkItemStateChangeResult> ApplyActionAsync(
        Guid workItemId,
        WorkItemAction action,
        WorkItemActionContext ctx,
        IDbConnection conn,
        IDbTransaction tx)
    {
        var wi = await conn.QuerySingleAsync<WorkItemRecord>(
            "SELECT * FROM public.work_items WHERE id = @id FOR UPDATE",
            new { id = workItemId }, tx);

        var oldStatus = wi.Status; // string

        if (!IsTransitionAllowed(oldStatus, action))
            throw new BusinessException($"Action {action} is not allowed from status {oldStatus}");

        var newStatus = GetNextStatus(oldStatus, action);

        if (newStatus == oldStatus)
        {
            return new WorkItemStateChangeResult
            {
                WorkItemId = workItemId,
                OldStatus = oldStatus,
                NewStatus = newStatus,
                StatusChanged = false,
                ShouldNotifyWorkflow = false
            };
        }

        // Update work_items
        await conn.ExecuteAsync(@"
            UPDATE public.work_items
            SET status = @newStatus,
                updated_at = @now,
                updated_by = @userId
            WHERE id = @id",
            new
            {
                id = workItemId,
                newStatus,
                now = _clock.UtcNow,
                userId = ctx.CurrentUserId
            }, tx);

        // Insert work_item_state_history
        await conn.ExecuteAsync(@"
            INSERT INTO public.work_item_state_history (
                id, work_item_id, from_status, to_status,
                by_user, note, created_at
            ) VALUES (
                uuid_generate_v4(), @workItemId, @fromStatus, @toStatus,
                @userId, @note, @now
            )",
            new
            {
                workItemId,
                fromStatus = oldStatus,
                toStatus = newStatus,
                userId = ctx.CurrentUserId,
                note = ctx.Note,
                now = _clock.UtcNow
            }, tx);

        return new WorkItemStateChangeResult
        {
            WorkItemId = workItemId,
            OldStatus = oldStatus,
            NewStatus = newStatus,
            StatusChanged = true,
            ShouldNotifyWorkflow = ShouldNotifyWorkflow(action)
        };
    }

    private static bool IsTransitionAllowed(string currentStatus, WorkItemAction action)
    {
        // TODO: implement theo bảng ở mục 5
    }

    private static string GetNextStatus(string currentStatus, WorkItemAction action)
    {
        // TODO: implement mapping action + currentStatus -> newStatus
    }

    private static bool ShouldNotifyWorkflow(WorkItemAction action)
        => action is WorkItemAction.Close
                or WorkItemAction.Cancel
                or WorkItemAction.Reopen
                or WorkItemAction.AutoCloseFromWorkflow;
}
```

**Dev cần làm:**

- Implement `IsTransitionAllowed` và `GetNextStatus` theo bảng.
- Áp dụng convention status ở DB là lowercase snake\_case (`in_progress`, `waiting_internal`, ...).

---

## 7. API – thiết kế rõ cho dev

### 7.1. Endpoint chung: `POST /api/crm/work-items/{id}/actions`

**Mục đích**: Endpoint duy nhất để FE yêu cầu **thay đổi trạng thái** work item thông qua **state machine**.

- **URL**: `/api/crm/work-items/{id}/actions`
- **Method**: `POST`
- **Auth**: bắt buộc (user đăng nhập, lấy `currentUserId` từ context)
- **Idempotent**: logic nghiệp vụ, không dùng HTTP PUT (vẫn là POST nhưng bên trong phải xử lý tránh double-update).

#### 7.1.1. Input

**Path parameter**

- `id` (uuid) – ID của work item trong `public.work_items.id`.

**Request body (JSON)**

```json
{
  "action": "SetWaitingCustomer",
  "note": "Đã liên hệ, chờ khách phản hồi",
  "newAssigneeId": "9f5df1a4-3fd2-4d2e-9d12-6d2d9c1e7b10"
}
```

Các field:

- `action` (string, **bắt buộc**)
  - Giá trị hợp lệ (map sang enum `WorkItemAction`):
    - `Submit`, `Assign`, `StartWork`, `SetWaitingInternal`, `SetWaitingCustomer`, `SetWaitingExternal`,
    - `BackToInProgress`, `Resolve`, `Close`, `Cancel`, `Reject`, `Reopen`.
    - Các action internal như `Create`, `AutoCloseFromWorkflow`, `Archive` **chỉ dùng nội bộ**, không expose ra UI.
- `note` (string, optional)
  - Ghi chú nghiệp vụ; sẽ được lưu vào `work_item_state_history.note`.
- `newAssigneeId` (uuid, optional)
  - Nếu action đồng thời thay đổi người xử lý, có thể truyền kèm; app service sẽ update cột `assignee_id` trong `work_items` ngoài việc đổi status.

**Validation ở controller**

- `action` không được null/empty.
- Kiểm tra `action` có nằm trong whitelist cho UI không, nếu không → trả 400.

#### 7.1.2. Output

**Response 200 (OK)**

```json
{
  "workItemId": "5b8b4de3-5f52-4b6a-9c71-1d9f5e8f5f11",
  "oldStatus": "in_progress",
  "newStatus": "waiting_customer",
  "statusChanged": true,
  "displayStatus": "Chờ khách hàng",
  "allowedNextActions": [
    "BackToInProgress",
    "Resolve",
    "Cancel"
  ]
}
```

Giải thích:

- `workItemId` – id work item.
- `oldStatus` – trạng thái trước khi áp dụng action.
- `newStatus` – trạng thái sau khi áp dụng action (theo state machine).
- `statusChanged` – true nếu có chuyển trạng thái, false nếu action hợp lệ nhưng không làm đổi status (hiếm).
- `displayStatus` – label tiếng Việt để FE hiển thị (optional, có thể trả thêm hoặc FE tự map).
- `allowedNextActions` – danh sách action tiếp theo được phép (optional, hữu ích cho FE disable nút).

**Response 400 (BadRequest)**

```json
{
  "error": "InvalidAction",
  "message": "Action SetWaitingCustomer is not allowed from status closed"
}
```

**Response 404 (NotFound)**

```json
{
  "error": "WorkItemNotFound",
  "message": "Work item 5b8b4de3-5f52-4b6a-9c71-1d9f5e8f5f11 not found"
}
```

#### 7.1.3. Sample flows

1. **Đang xử lý → Chờ khách hàng** (nút "Cập nhật" + dropdown "Chờ khách hàng")

```http
POST /api/crm/work-items/5b8b4de3-5f52-4b6a-9c71-1d9f5e8f5f11/actions
Content-Type: application/json

{
  "action": "SetWaitingCustomer",
  "note": "Đã gửi email cho khách, chờ phản hồi"
}
```

Kết quả: `in_progress → waiting_customer`.

2. **Resolved → Closed** (nút "Đóng" khi đã resolved)

```http
POST /api/crm/work-items/5b8b4de3-5f52-4b6a-9c71-1d9f5e8f5f11/actions
Content-Type: application/json

{
  "action": "Close",
  "note": "Khách đã xác nhận kết quả"
}
```

Kết quả: `resolved → closed`, sau đó app service có thể gọi Workflow Engine nếu cần.

3. **Draft/Open/InProgress/Waiting → Canceled** (nút "Đóng" hiểu là huỷ yêu cầu)

```http
POST /api/crm/work-items/5b8b4de3-5f52-4b6a-9c71-1d9f5e8f5f11/actions
Content-Type: application/json

{
  "action": "Cancel",
  "note": "Khách không còn nhu cầu"
}
```

Kết quả: `current → canceled`.

#### 7.1.4. Database query (gợi ý Dapper)

Endpoint này sử dụng **state machine** nên query chính nằm trong `WorkItemStateMachine`.

**Bước 1 – Load work item FOR UPDATE**

```sql
SELECT *
FROM public.work_items
WHERE id = @WorkItemId
FOR UPDATE;
```

**Bước 2 – Validate & tính trạng thái mới**

- Logic trong code (C#), không phải SQL:
  - Kiểm tra transition có hợp lệ với `currentStatus`.
  - Tính `newStatus` theo bảng state machine.

**Bước 3 – Update work\_items**

```sql
UPDATE public.work_items
SET
    status      = @NewStatus,
    assignee_id = COALESCE(@NewAssigneeId, assignee_id),
    closed_at   = CASE
                    WHEN @NewStatus IN ('closed', 'canceled', 'rejected')
                      THEN now()
                    ELSE closed_at
                  END,
    updated_at  = now(),
    updated_by  = @UserId
WHERE id = @WorkItemId;
```

> Ghi chú: nếu schema hiện tại chưa có `closed_at` hoặc `assignee_id` thì bỏ các cột này ra, chỉ giữ `status`, `updated_at`, `updated_by`.

**Bước 4 – Ghi lịch sử vào **``

Giả sử cấu trúc bảng (schema v7i) có các cột: `id`, `work_item_id`, `from_status`, `to_status`, `by_user`, `note`, `created_at`.

```sql
INSERT INTO public.work_item_state_history (
    id,
    work_item_id,
    from_status,
    to_status,
    by_user,
    note,
    created_at
) VALUES (
    uuid_generate_v4(),
    @WorkItemId,
    @OldStatus,
    @NewStatus,
    @UserId,
    @Note,
    now()
);
```

**(Tuỳ chọn) Bước 5 – Ghi outbox event **``

Nếu muốn các service khác (notifications, analytics, báo cáo…) biết khi trạng thái thay đổi:

```sql
INSERT INTO public.outbox_events (
    id, aggregate, aggregate_id, event_type,
    payload, occurred_at, created_at, created_by
) VALUES (
    uuid_generate_v4(),
    'work_item',
    @WorkItemId,
    'WORK_ITEM_STATUS_CHANGED',
    @Payload::jsonb,
    now(),
    now(),
    @UserId
);
```

`@Payload` JSON gợi ý:

```json
{
  "workItemId": "5b8b4de3-5f52-4b6a-9c71-1d9f5e8f5f11",
  "oldStatus": "in_progress",
  "newStatus": "waiting_customer",
  "changedBy": "d1f9d1c3-9e3f-4c7f-9ea5-12f1d8c2b3a4",
  "changedAt": "2025-12-09T03:21:45.123Z",
  "source": "CRM_UI"
}
```

Tất cả các bước trên chạy trong **cùng transaction** với `WorkItemAppService.ApplyActionAsync`. Nếu có tích hợp với Workflow Engine (gọi `IWorkflowRuntimeClient`), call đó cũng nên nằm trong cùng transaction để đảm bảo tính nhất quán.

### 7.2. Application service `WorkItemAppService`

File gợi ý: `Fisa.Crm.Application/WorkItems/WorkItemAppService.cs`

```csharp
public sealed class WorkItemAppService : IWorkItemAppService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly IWorkItemStateMachine _stateMachine;
    private readonly IWorkflowRuntimeClient _workflowRuntimeClient; // abstraction gọi Workflow Engine API

    public async Task<WorkItemStateChangeResult> ApplyActionAsync(
        Guid workItemId,
        string actionCode,
        string? note,
        Guid? newAssigneeId,
        Guid currentUserId)
    {
        var action = MapActionCode(actionCode); // string -> enum WorkItemAction

        using var conn = await _connectionFactory.OpenConnectionAsync();
        using var tx = conn.BeginTransaction();

        var ctx = new WorkItemActionContext
        {
            CurrentUserId = currentUserId,
            Note = note,
            NewAssigneeId = newAssigneeId,
            Source = "CRM_UI"
        };

        var result = await _stateMachine.ApplyActionAsync(
            workItemId,
            action,
            ctx,
            conn,
            tx);

        // Tùy theo action, có thể call Workflow Engine ngay tại đây
        if (result.StatusChanged && result.ShouldNotifyWorkflow)
        {
            await _workflowRuntimeClient.SyncWorkItemStatusAsync(
                workItemId,
                result.OldStatus,
                result.NewStatus,
                tx);
        }

        tx.Commit();

        return result;
    }
}
```

### 7.3. Controller API

`Fisa.Crm.Api/Controllers/WorkItemsController.cs`:

```csharp
[HttpPost("{id:guid}/actions")]
public async Task<IActionResult> ApplyAction(Guid id, [FromBody] ApplyWorkItemActionRequest request)
{
    var userId = _currentUser.Id; // lấy từ context

    var result = await _workItemAppService.ApplyActionAsync(
        id,
        request.Action,
        request.Note,
        request.NewAssigneeId,
        userId);

    return Ok(new {
        workItemId = result.WorkItemId,
        oldStatus = result.OldStatus,
        newStatus = result.NewStatus,
        statusChanged = result.StatusChanged,
        displayStatus = MapDisplayStatus(result.NewStatus),
        allowedNextActions = MapAllowedNextActions(result.NewStatus)
    });
}
```

`ApplyWorkItemActionRequest`:

```csharp
public sealed class ApplyWorkItemActionRequest
{
    public string Action { get; set; } = default!; // map sang enum WorkItemAction
    public string? Note { get; set; }
    public Guid? NewAssigneeId { get; set; }
}
```

### 7.2. Application service `WorkItemAppService`

File gợi ý: `Fisa.Crm.Application/WorkItems/WorkItemAppService.cs`

```csharp
public sealed class WorkItemAppService : IWorkItemAppService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly IWorkItemStateMachine _stateMachine;
    private readonly IWorkflowRuntimeClient _workflowRuntimeClient; // abstraction gọi Workflow Engine API

    public async Task<WorkItemStateChangeResult> ApplyActionAsync(
        Guid workItemId,
        string actionCode,
        string? note,
        Guid? newAssigneeId,
        Guid currentUserId)
    {
        var action = MapActionCode(actionCode); // string -> enum

        using var conn = await _connectionFactory.OpenConnectionAsync();
        using var tx = conn.BeginTransaction();

        var ctx = new WorkItemActionContext
        {
            CurrentUserId = currentUserId,
            Note = note,
            NewAssigneeId = newAssigneeId,
            Source = "CRM_UI"
        };

        var result = await _stateMachine.ApplyActionAsync(
            workItemId,
            action,
            ctx,
            conn,
            tx);

        // Tùy theo action, có thể call Workflow Engine ngay tại đây
        if (result.StatusChanged && result.ShouldNotifyWorkflow)
        {
            await _workflowRuntimeClient.SyncWorkItemStatusAsync(
                workItemId,
                result.OldStatus,
                result.NewStatus,
                tx);
        }

        tx.Commit();

        return result;
    }
}
```

**Dev cần implement:**

- Map `actionCode` string → `WorkItemAction` (validate + throw lỗi nếu không hỗ trợ).
- `_workflowRuntimeClient` để gọi sang Workflow Engine Runtime v1 (section 8).

---

## 8. Tích hợp với Workflow Engine Runtime v1

### 8.1. Từ CRM sang Workflow Engine

Trong ví dụ **action CLOSE**:

- Sau khi `ApplyActionAsync` đổi status `resolved` → `closed`, `WorkItemAppService` sẽ gọi:

```csharp
await _workflowRuntimeClient.CompleteCloseStepAsync(workItemId, tx);
```

Hoặc:

```csharp
await _workflowRuntimeClient.OnWorkItemClosedAsync(workItemId, result.NewStatus, tx);
```

`` là abstraction gói việc:

- Gọi API `POST /api/v1/workflow-instance-steps/{id}/complete` hoặc
- Gửi command nội bộ nếu Workflow Engine chạy chung process.

### 8.2. Từ Workflow Engine quay về CRM

Trong Runtime v1, ở chỗ code khi **instance đi đến bước cuối cùng** và muốn auto đóng work item (hoặc sync trạng thái):

Thay vì:

- `UPDATE public.work_items SET status = 'closed' ...`

Thì Workflow Engine sẽ gọi ngược:

```csharp
await _workItemStateMachine.ApplyActionAsync(
    workItemId,
    WorkItemAction.AutoCloseFromWorkflow,
    new WorkItemActionContext
    {
        CurrentUserId = systemUserId,
        Note = "Auto close from workflow end",
        Source = "WORKFLOW_ENGINE"
    },
    connection,
    transaction);
```

**Dev cần:**

- Inject `IWorkItemStateMachine` vào chỗ phù hợp trong Workflow Runtime v1 (service xử lý transition step cuối cùng).
- Đảm bảo dùng chung connection/transaction để update đồng bộ:
  - `workflow_instances` + steps
  - `work_items` + history

### 8.3. Strong vs Loose Coupling

**Strong coupling (default)**:

- Invariant:
  - Nếu `work_items.status = 'closed'` thì `workflow_instances.status` phải là `completed` hoặc `canceled` (trừ khi template cho phép).
  - Nếu `workflow_instances.status = 'completed'` thì Work Item phải nằm ở `closed` (hoặc đã được `AutoCloseFromWorkflow`).

**Loose coupling (**``**)**:

- Cho phép Workflow Instance tiếp tục chạy sau khi ticket đã `closed`.
- Khi đó action CLOSE bên CRM **không** bắt buộc gọi Workflow Engine.
- Nhưng khi instance tự kết thúc, Workflow Engine vẫn có thể gọi `AutoCloseFromWorkflow` (nếu WI chưa closed) cho đồng bộ.

---

## 9. Worker / Outbox – có cần sửa gì không?

### 9.1. Outbox hiện tại

- Sự kiện `WORK_ITEM_CREATED` đã dùng để start workflow instance.
- Tài liệu này **không bắt buộc** thêm event mới, nhưng **có thể** bổ sung:
  - `WORK_ITEM_STATUS_CHANGED` để các service khác (Notification, Analytics) subscribe.

### 9.2. Worker cần làm gì?

- Worker đọc outbox, khi gặp event `WORK_ITEM_CREATED` vẫn xử lý như cũ (Runtime v1).
- Nếu bổ sung event `WORK_ITEM_STATUS_CHANGED`:
  - Worker có thể push thông báo real-time, ghi log bổ sung… nhưng **không bắt buộc** thay đổi workflow logic.

**Quan trọng:**

- Worker **không** được tự đổi `work_items.status`. Mọi thay đổi đều phải đi qua `IWorkItemStateMachine`.

---

## 10. Checklist công việc cho dev

Để dev biết rõ phải làm gì, liệt kê theo bước:

1. **Domain/Application**

   -

2. **Application Service**

   -

3. **API Layer**

   -

4. **Workflow Engine Runtime v1**

   -

5. **Worker / Outbox**

   -

6. **Test**

   -

---

## 11. Ghi chú triển khai

- Tránh để UI/FE tự suy đoán status – luôn dựa vào giá trị backend trả về.
- Mọi nơi trong code cũ đang `UPDATE work_items.status` trực tiếp cần được refactor để đi qua `IWorkItemStateMachine` (tối thiểu là cho các luồng chính).
- Có thể giữ 1 số luồng legacy, nhưng nên đánh dấu TODO để migrate dần.

---

## 12. UI Mapping State Machine (Màn Tạo yêu cầu & Xử lý yêu cầu)

Phần này trả lời câu hỏi: **"Thành phần nào trên giao diện gọi state machine như thế nào?"** dựa trên 2 màn hình:

- Màn **"Danh sách Yêu cầu > Tạo yêu cầu"** (Create screen).
- Màn **"[Đề nghị (Request)] – Chi tiết/Xử lý"** (Process screen).

### 12.1. Màn Tạo yêu cầu – Create Request Screen

Các khối chính trên UI:

- Thanh trên: `Loại yêu cầu`, `Mảng hoạt động`, `Nhóm nghiệp vụ`, `Quy trình cụ thể`.
- Khối **"Thông tin chi tiết"**: tiêu đề, mô tả, ghi chú.
- Cột phải **"Thiết lập chung"**: `Priority`, `Phạm vi (Scope)`, SLA (hạn xử lý), phân công (người xử lý, người theo dõi...).
- Nút **"Hủy bỏ"** và **"Gửi yêu cầu"**.

**Mapping với state machine:**

1. **Khi mở màn hình Tạo yêu cầu**

   - Không gọi state machine.
   - FE chỉ gọi API **load taxonomy/config** (loại yêu cầu, mảng, nhóm, quy trình, scope…).

2. **Khi người dùng bấm "Gửi yêu cầu"**

   - FE gọi API **tạo work item mới** (ví dụ `POST /api/crm/work-items`).
   - Application Service bên trong sẽ:
     - Insert bản ghi mới vào `public.work_items` với `status = 'draft'` (internal).
     - Gọi **state machine** với:
       - `action = WorkItemAction.Create` (internal, set status `draft`).
       - Sau đó `action = WorkItemAction.Submit` để đưa trạng thái ``.
   - Kết quả:
     - Work item mới sinh ra với `status = 'open'`.
     - Lịch sử có 2 dòng `draft → draft` (optional, có thể bỏ) và `draft → open`.
     - Event `WORK_ITEM_CREATED` được ghi vào outbox như thiết kế hiện tại để Workflow Engine khởi tạo instance.

3. **Trường hợp sau này có nút "Lưu nháp" (optional)**

   - Nút "Lưu nháp":
     - Chỉ gọi `WorkItemAction.Create` (hoặc Create + không Submit) → work item ở `status = 'draft'`.
   - Nút "Gửi yêu cầu" từ bản nháp:
     - Gọi API `/actions` với `action = Submit` → `draft → open`.

4. **Nút "Hủy bỏ" trên màn Tạo yêu cầu**

   - Trên UI hiện tại hiểu là **đóng form** (không gửi gì lên backend nếu work item chưa được tạo).
   - Không gọi state machine.

> Tóm lại: **màn Tạo yêu cầu chỉ có 1 điểm chạm với state machine: nút "Gửi yêu cầu" → action **``** (sau khi tạo).**

---

### 12.2. Màn Xử lý/Chi tiết yêu cầu – Process Request Screen

Các thành phần chính liên quan trạng thái trên UI (theo screenshot mẫu):

- Badge trên header: `Status: draft / open / ...` (chỉ hiển thị, **không gọi API**).
- Dropdown **"Chuyển trạng thái"** (ví dụ đang chọn "Đang xử lý").
- Các nút action:
  - **"Cập nhật"** (màu xanh).
  - **"Tạm dừng"** (Pause).
  - **"Đóng"** (Close/Cancel).
- Tabs: `Xử lý`, `Chi tiết`, `Bình luận`, `Lịch sử`.

#### 12.2.1. Dropdown "Chuyển trạng thái" + nút "Cập nhật"

**Ý nghĩa UI:**

- Người dùng có thể chọn trạng thái mong muốn ở dropdown (ví dụ: `Đang xử lý`, `Chờ nội bộ`, `Chờ khách hàng`, ...).
- Sau đó bấm **"Cập nhật"** để lưu.

**Mapping với state machine:**

- FE cần ánh xạ **option trong dropdown** → **action code**.

Ví dụ gợi ý:

| Nhãn dropdown (việt hóa)       | target status      | WorkItemAction tương ứng            |
| ------------------------------ | ------------------ | ----------------------------------- |
| `Đang xử lý`                   | `in_progress`      | `StartWork` hoặc `BackToInProgress` |
| `Chờ nội bộ`                   | `waiting_internal` | `SetWaitingInternal`                |
| `Chờ khách hàng`               | `waiting_customer` | `SetWaitingCustomer`                |
| `Chờ bên thứ ba` (nếu có)      | `waiting_external` | `SetWaitingExternal`                |
| `Đã xử lý (Resolved)` (nếu có) | `resolved`         | `Resolve`                           |

- Khi user bấm **"Cập nhật"**:
  1. FE so sánh **giá trị status hiện tại** (backend trả về) và **lựa chọn mới ở dropdown**.
  2. Nếu **status không đổi** → gọi API **update thông tin khác** (assign, priority, SLA...) KHÔNG qua state machine.
  3. Nếu **status đổi**:
     - FE gửi request tới endpoint `/api/crm/work-items/{id}/actions` với `action` tương ứng.

**Ví dụ request JSON:**

```http
POST /api/crm/work-items/{id}/actions
Content-Type: application/json

{
  "action": "SetWaitingCustomer",
  "note": "Đã liên hệ, chờ khách phản hồi",
  "newAssigneeId": null
}
```

State machine sẽ quyết định chuyển từ:

- `in_progress → waiting_customer`, hoặc
- `waiting_internal → waiting_customer` (nếu cho phép),…

#### 12.2.2. Nút "Tạm dừng" (Pause)

- Đây là **quick action**: user không cần thao tác dropdown, chỉ bấm 1 nút.
- Gợi ý mapping v1:
  - "Tạm dừng" = chuyển sang trạng thái **"Chờ nội bộ"** (`waiting_internal`).
  - Khi bấm:

```http
POST /api/crm/work-items/{id}/actions
{
  "action": "SetWaitingInternal",
  "note": "Tạm dừng xử lý, chờ thêm thông tin nội bộ"
}
```

- Backend kiểm tra state hiện tại (`in_progress` hoặc `open`) và dùng state machine để chuyển sang `waiting_internal` nếu hợp lệ.

> Nếu sau này anh muốn trạng thái riêng `paused`, có thể mở rộng state machine, còn v1 dùng `waiting_internal` để tránh sửa DB.

#### 12.2.3. Nút "Đóng" (Close / Cancel)

Nút **"Đóng"** trên màn xử lý có 2 ý nghĩa tuỳ **status hiện tại**:

1. **Nếu status hiện tại là **`` (đã xử lý xong):
   - "Đóng" = **Close** chuẩn.
   - FE gọi:

```http
POST /api/crm/work-items/{id}/actions
{
  "action": "Close",
  "note": "Khách đã xác nhận xong"
}
```

- State machine: `resolved → closed`.
- Sau đó `WorkItemAppService` có thể gọi `WorkflowRuntimeClient` để engine hoàn thành bước cuối cùng.

2. **Nếu status hiện tại là **``**, **``**, **``**, hoặc **``:
   - "Đóng" = **Huỷ yêu cầu** (Cancel), không phải Close chuẩn.
   - FE gọi:

```http
POST /api/crm/work-items/{id}/actions
{
  "action": "Cancel",
  "note": "Khách không còn nhu cầu"
}
```

- State machine: `current → canceled`.

3. **Nếu status hiện tại là **``**, **``**, **``**, **``:
   - Nút "Đóng" nên **disabled** trên UI (không cho bấm, không gọi API).

#### 12.2.4. Tab "Lịch sử" và "Chi tiết" / "Bình luận"

- Các tab này **không gọi state machine**.
- Chỉ gọi các API dạng `GET` để đọc dữ liệu:
  - `GET /api/crm/work-items/{id}` → header + chi tiết.
  - `GET /api/crm/work-items/{id}/state-history` → render tab Lịch sử.
  - `GET /api/crm/work-items/{id}/comments` → tab Bình luận.

---

### 12.3. Tóm tắt UI → State Machine

- **Màn Tạo yêu cầu**:
  - Chỉ có **"Gửi yêu cầu"** tác động state machine → action `Submit` (sau khi tạo).
- **Màn Xử lý/Chi tiết**:
  - Dropdown "Chuyển trạng thái" + nút "Cập nhật" → map sang các action: `StartWork`, `SetWaitingInternal`, `SetWaitingCustomer`, `SetWaitingExternal`, `Resolve`.
  - Nút **"Tạm dừng"** → quick action `SetWaitingInternal`.
  - Nút **"Đóng"**:
    - Nếu đang `resolved` → action `Close`.
    - Nếu đang `draft/open/in_progress/waiting_*` → action `Cancel`.

Nhờ mapping này, dev FE/BE nhìn UI là biết **khi nào phải gọi **``** (state machine)** và khi nào chỉ gọi API update dữ liệu thường, tránh lẫn lộn giữa update field và chuyển trạng thái nghiệp vụ.

---

## 13. Canonical Action & Status Values

### 13.1. Giá trị chuẩn của `work_items.status` trong DB

Bảng `public.work_items` trong `schema_dump_v7i.sql` định nghĩa cột:

```sql
"status" character varying(50) DEFAULT 'draft'::character varying
```

Tài liệu này chuẩn hoá danh sách giá trị **string** (lowercase, snake\_case nếu nhiều từ):

| Trạng thái       | Giá trị DB (`work_items.status`) | Mô tả ngắn                        |
| ---------------- | -------------------------------- | --------------------------------- |
| Draft            | `draft`                          | Đang soạn, chưa gửi               |
| Open             | `open`                           | Đã gửi, chờ phân công             |
| In progress      | `in_progress`                    | Đang xử lý                        |
| Waiting internal | `waiting_internal`               | Chờ nội bộ                        |
| Waiting customer | `waiting_customer`               | Chờ khách hàng                    |
| Waiting external | `waiting_external`               | Chờ bên thứ ba (nếu dùng)         |
| Resolved         | `resolved`                       | Đã xử lý xong kỹ thuật            |
| Closed           | `closed`                         | Đóng hồ sơ (kết thúc đẹp)         |
| Canceled         | `canceled`                       | Huỷ yêu cầu                       |
| Rejected         | `rejected`                       | Từ chối tiếp nhận                 |
| Archived         | `archived`                       | Lưu trữ (sau closed/canceled/...) |

> Dev phải dùng đúng các literal trên khi insert/update `work_items.status` (qua state machine). Không tự invent giá trị mới nếu chưa update tài liệu.

### 13.2. Label hiển thị trên UI (gợi ý)

FE có thể map `status` → label tiếng Việt:

| Giá trị DB         | Label gợi ý    |
| ------------------ | -------------- |
| `draft`            | Nháp           |
| `open`             | Mở             |
| `in_progress`      | Đang xử lý     |
| `waiting_internal` | Chờ nội bộ     |
| `waiting_customer` | Chờ khách hàng |
| `waiting_external` | Chờ bên thứ ba |
| `resolved`         | Đã xử lý       |
| `closed`           | Đã đóng        |
| `canceled`         | Đã huỷ         |
| `rejected`         | Từ chối        |
| `archived`         | Lưu trữ        |

### 13.3. Canonical `WorkItemAction` & action code string

Enum `WorkItemAction` (ở backend) và string mà FE gửi vào `ApplyWorkItemActionRequest.Action` cần khớp 1-1:

| Enum `WorkItemAction` | String FE gửi (`action`) |
| --------------------- | ------------------------ |
| `Submit`              | `"Submit"`               |
| `Assign`              | `"Assign"`               |
| `StartWork`           | `"StartWork"`            |
| `SetWaitingInternal`  | `"SetWaitingInternal"`   |
| `SetWaitingCustomer`  | `"SetWaitingCustomer"`   |
| `SetWaitingExternal`  | `"SetWaitingExternal"`   |
| `BackToInProgress`    | `"BackToInProgress"`     |
| `Resolve`             | `"Resolve"`              |
| `Close`               | `"Close"`                |
| `Cancel`              | `"Cancel"`               |
| `Reject`              | `"Reject"`               |
| `Reopen`              | `"Reopen"`               |

Các action internal (chỉ gọi từ code):

| Enum internal           | String (nếu cần logging)  |
| ----------------------- | ------------------------- |
| `Create`                | `"Create"`                |
| `AutoCloseFromWorkflow` | `"AutoCloseFromWorkflow"` |
| `Archive`               | `"Archive"`               |

> FE không nên gửi các action internal; nếu gửi sẽ bị backend `400 InvalidAction`.

### 13.4. Error codes chuẩn cho `/actions`

Để trả lỗi nhất quán:

| HTTP | `error` code        | Khi nào dùng                                                            |
| ---- | ------------------- | ----------------------------------------------------------------------- |
| 400  | `InvalidAction`     | `action` không parse được hoặc không hỗ trợ                             |
| 400  | `InvalidTransition` | action hợp lệ nhưng không được phép từ status hiện tại                  |
| 403  | `PermissionDenied`  | User không có quyền thực hiện action                                    |
| 404  | `WorkItemNotFound`  | Không tìm thấy work item                                                |
| 409  | `ConflictState`     | Trạng thái hiện tại khác với dữ liệu FE nghĩ (optimistic check, nếu có) |

---

## 14. Test Matrix gợi ý cho State Machine

Bảng này dùng cho unit/integration test để đảm bảo state machine hoạt động đúng.

### 14.1. Test case chính (happy path)

| #  | From status        | Action                  | Expected to status |
| -- | ------------------ | ----------------------- | ------------------ |
| 1  | `draft`            | `Submit`                | `open`             |
| 2  | `open`             | `StartWork`             | `in_progress`      |
| 3  | `in_progress`      | `SetWaitingCustomer`    | `waiting_customer` |
| 4  | `waiting_customer` | `BackToInProgress`      | `in_progress`      |
| 5  | `in_progress`      | `Resolve`               | `resolved`         |
| 6  | `resolved`         | `Close`                 | `closed`           |
| 7  | `open`             | `Cancel`                | `canceled`         |
| 8  | `open`             | `Reject`                | `rejected`         |
| 9  | `resolved`         | `Reopen`                | `in_progress`      |
| 10 | `in_progress`      | `AutoCloseFromWorkflow` | `closed`           |

### 14.2. Test case lỗi (invalid transition)

| #  | From status | Action               | Expected result         |
| -- | ----------- | -------------------- | ----------------------- |
| 11 | `closed`    | `SetWaitingCustomer` | 400 `InvalidTransition` |
| 12 | `canceled`  | `Reopen`             | 400 `InvalidTransition` |
| 13 | `rejected`  | `Resolve`            | 400 `InvalidTransition` |
| 14 | `draft`     | `Close`              | 400 `InvalidTransition` |

### 14.3. Test case liên quan Workflow Engine

| #  | From status   | Action                  | Ghi chú                                                                 |
| -- | ------------- | ----------------------- | ----------------------------------------------------------------------- |
| 15 | `in_progress` | `AutoCloseFromWorkflow` | Gọi từ Workflow Runtime v1, WI `closed`, instance `completed`           |
| 16 | `resolved`    | `Close` (từ CRM UI)     | Sau khi close, gọi `WorkflowRuntimeClient.SyncWorkItemStatusAsync(...)` |
| 17 | `closed`      | `AutoCloseFromWorkflow` | Không đổi status, có thể log warning; không được throw lỗi fatal        |

Các test này nên được implement ở cả:

- Unit test cho `WorkItemStateMachine` (không cần DB, chỉ test mapping from/to status).
- Integration test cho `/api/crm/work-items/{id}/actions` với DB thật (PostgreSQL) để đảm bảo query & transaction hoạt động đúng với schema `v7i`.

---

Tài liệu đến đây đủ để dev 1 năm kinh nghiệm:

- Biết chính xác các giá trị status/action hợp lệ.
- Biết lỗi nào phải trả khi transition sai.
- Có bảng test case cụ thể để viết unit/integration test.

