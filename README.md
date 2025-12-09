# Máy trạng thái Work Item của FISA CRM

Kho lưu trữ này hiện thực state machine và API thay đổi trạng thái work item theo tài liệu `fisa_crm_work_item_state_machine_and_workflow_integration_v_2.md`. Tất cả logic bám sát bộ trạng thái `draft/open/in_progress/waiting_*/resolved/closed/canceled/rejected/archived` và cách tích hợp với Workflow Engine Runtime v1.

## Thành phần chính

- **Fisa.Crm.Application**
  - `WorkItemStateMachine` thi hành bảng chuyển đổi trạng thái, cập nhật `public.work_items` và ghi lịch sử vào `public.work_item_state_history`.
  - `WorkItemAppService` mở transaction, gọi máy trạng thái và bọc kết quả cho API (bao gồm allowed next actions và display status).
  - `WorkItemStateMachineRules` định nghĩa allowed transitions, tính trạng thái kế tiếp, cờ `ShouldNotifyWorkflow` và liệt kê action tiếp theo hợp lệ.
  - `WorkItemStatusDisplay` map trạng thái sang nhãn tiếng Việt để FE hiển thị nhanh.
  - `NpgsqlConnectionFactory` cung cấp kết nối PostgreSQL từ biến môi trường `FISA_CRM_DB_CONNECTION_STRING` (hoặc connection string trong cấu hình API).
- **Fisa.Crm.Api**
  - API duy nhất `POST /api/crm/work-items/{id}/actions` nhận yêu cầu đổi trạng thái qua `WorkItemAppService`.
  - Header `X-Current-User-Id` bắt buộc để đóng dấu người thao tác.
- **Fisa.Crm.Tests**
  - Kiểm thử ma trận chuyển trạng thái và các cờ tích hợp workflow.

## Cài đặt .NET 8 SDK

Môi trường đã được cấu hình với .NET SDK 8 (gói `dotnet-sdk-8.0`). Nếu cần tự cài, có thể dùng apt repository của Microsoft:

```bash
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0
```

## Cấu hình cơ sở dữ liệu

Đặt biến môi trường `FISA_CRM_DB_CONNECTION_STRING` (hoặc connection string `Postgres` trong appsettings) để API và application service mở kết nối PostgreSQL khớp schema `schema_dump_v7i.sql`:

```bash
export FISA_CRM_DB_CONNECTION_STRING="Host=localhost;Port=5432;Database=fisa_crm;Username=postgres;Password=changeme"
```

## Chạy API state machine

1. Khôi phục và build solution:
   ```bash
   dotnet restore
   dotnet build
   ```
2. Khởi động API:
   ```bash
   dotnet run --project src/Fisa.Crm.Api
   ```
3. Gửi yêu cầu đổi trạng thái:
   ```bash
   curl -X POST http://localhost:5000/api/crm/work-items/{id}/actions \
     -H "Content-Type: application/json" \
     -H "X-Current-User-Id: 11111111-1111-1111-1111-111111111111" \
     -d '{"action":"SetWaitingCustomer","note":"Đã gửi email cho khách","newAssigneeId":"22222222-2222-2222-2222-222222222222"}'
   ```

Phản hồi mẫu:

```json
{
  "workItemId": "{id}",
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

Nếu action không hợp lệ sẽ trả 400 với `error: InvalidAction`; nếu work item không tồn tại sẽ trả 404.

## Luồng áp dụng action (tóm tắt)

1. Controller nhận request, lấy `currentUserId` từ header, map `action` (string) sang `WorkItemAction` (chỉ whitelist cho UI).
2. `WorkItemAppService` mở transaction, gọi `WorkItemStateMachine.ApplyActionAsync` và commit.
3. `WorkItemStateMachine`:
   - Khoá bản ghi `public.work_items` bằng `FOR UPDATE`.
   - Validate transition theo `WorkItemStateMachineRules`.
   - Cập nhật `status`, `assignee_id`, `updated_at`, `updated_by`, `closed_at` (nếu trạng thái kết thúc).
   - Ghi một dòng vào `public.work_item_state_history` với ghi chú và người thao tác.
   - Trả về `ShouldNotifyWorkflow` cho integration với Workflow Engine Runtime v1.
4. `WorkItemAppService` trả JSON gồm trạng thái mới, nhãn hiển thị và danh sách action kế tiếp khả dụng để FE dựng UI.

## Build & kiểm thử

Chạy toàn bộ test từ thư mục gốc:

```bash
dotnet test src/Fisa.Crm.Tests
```

Các test không cần kết nối cơ sở dữ liệu vì state machine hoạt động trên các DTO và giao diện kết nối trừu tượng.

## Tài liệu liên quan

- `fisa_crm_work_item_state_machine_and_workflow_integration_v_2.md` – guideline triển khai state machine & workflow integration.
- `schema_dump_v7i.sql` – schema PostgreSQL tham chiếu.
- `fisa_crm_work_item_status_design_v_1.md` – ý nghĩa từng trạng thái.
