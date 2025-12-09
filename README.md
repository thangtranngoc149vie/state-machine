# Máy trạng thái Work Item của FISA CRM

Kho lưu trữ này hiện thực máy trạng thái work item mô tả trong `fisa_crm_work_item_state_machine_and_workflow_integration_v_1.md` và thiết kế trạng thái trong `fisa_crm_work_item_status_design_v_1.md`. Mã nguồn nhắm tới .NET 8 và được tổ chức để dịch vụ tầng ứng dụng kiểm soát các chuyển đổi theo workflow trong khi vẫn ghi dữ liệu khớp với `schema_dump_v7i.sql`.

## Kiến trúc

- **Tầng ứng dụng** (`src/Fisa.Crm.Application`)
  - `WorkItems/IWorkItemStateMachine` cung cấp điểm vào duy nhất để thay đổi trạng thái work item trong cùng giao dịch cơ sở dữ liệu.
  - `WorkItemStateMachine` thi hành luật bằng `WorkItemStateMachineRules`, lưu thay đổi vào `public.work_items` và `public.work_item_state_history` thông qua Dapper.
  - `WorkItemAction`, `WorkItemStatuses` và các DTO hỗ trợ (`WorkItemActionContext`, `WorkItemStateChangeResult`) phản ánh từ vựng hành động và trạng thái từ tài liệu nghiệp vụ.
  - `IClock` trừu tượng hóa thời gian để dễ kiểm thử và đóng dấu `updated_at` / `closed_at` nhất quán.
- **Kiểm thử** (`src/Fisa.Crm.Tests`)
  - Unit test cho luật máy trạng thái đảm bảo các chuyển đổi được phép luôn bám theo đặc tả và phát hiện hồi quy mà không cần truy cập cơ sở dữ liệu.

Máy trạng thái thực thi ma trận chuyển đổi từ đặc tả:

| Hành động | Trạng thái hiện tại | Trạng thái đích |
| --- | --- | --- |
| Create | — | `draft` |
| Submit | `draft` | `open` |
| Assign | `open`, `in_progress` | `in_progress` |
| StartWork | `open` | `in_progress` |
| SetWaitingInternal | `in_progress` | `waiting_internal` |
| SetWaitingCustomer | `in_progress` | `waiting_customer` |
| SetWaitingExternal | `in_progress` | `waiting_external` |
| BackToInProgress | `waiting_internal`, `waiting_customer`, `waiting_external` | `in_progress` |
| Resolve | `in_progress`, `waiting_*` | `resolved` |
| Close | `resolved` | `closed` |
| Cancel | `draft`, `open`, `in_progress`, `waiting_*` | `canceled` |
| Reject | `draft`, `open` | `rejected` |
| Reopen | `resolved`, `closed` | `in_progress` |
| AutoCloseFromWorkflow | `in_progress`, `waiting_*`, `resolved` | `closed` |
| Archive | `closed`, `canceled`, `rejected` | `archived` |

Các hành động kết thúc work item (`close`, `cancel`, `reject`, `archive`) cũng đóng dấu `closed_at` theo cột cho phép null trong `schema_dump_v7i.sql`. Mỗi lần đổi trạng thái sẽ ghi một dòng audit vào `public.work_item_state_history` với người thực hiện và ghi chú lấy từ `WorkItemActionContext`.

Cờ tích hợp workflow làm theo hướng dẫn: máy trạng thái đặt `ShouldNotifyWorkflow` cho các hành động `Close`, `Cancel`, `Reopen` và `AutoCloseFromWorkflow` để caller có thể đồng bộ với Workflow Runtime v1 sau khi giao dịch cơ sở dữ liệu thành công.

## Cài đặt .NET SDK

Dự án nhắm tới .NET 8. Bạn có thể cài SDK bằng dotnet-install script khi môi trường chưa có sẵn toolchain:

```bash
curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version 8.0.401 --install-dir "$HOME/.dotnet"
export PATH="$HOME/.dotnet:$PATH"
```

Nếu mạng đi qua HTTPS proxy, hãy đặt biến `HTTPS_PROXY`/`HTTP_PROXY` trước khi chạy script.

## Build và kiểm thử

Sau khi có .NET SDK, chạy khôi phục và kiểm thử từ thư mục gốc repository:

```bash
cd src
dotnet restore
cd ..
dotnet test src/Fisa.Crm.Tests
```

`WorkItemStateMachine` không phụ thuộc cơ sở dữ liệu trong unit test; nó nhận `IDbConnection` và `IDbTransaction` để test tích hợp có thể kiểm tra đường đi SQL với schema trong `schema_dump_v7i.sql`.

## Cấu trúc dự án

```
src/
  Fisa.Crm.Application/
    WorkItems/
      WorkItemAction.cs
      WorkItemStatuses.cs
      WorkItemStateMachine.cs
      WorkItemStateMachineRules.cs
      WorkItemRecord.cs
      IWorkItemStateMachine.cs
  Fisa.Crm.Tests/
    WorkItemStateMachineRulesTests.cs
```

## Ghi chú khớp cơ sở dữ liệu

- `WorkItemStateMachine` cập nhật `public.work_items.status`, `updated_at`, `updated_by`, `assignee_id` và `closed_at` đúng như định nghĩa trong `schema_dump_v7i.sql`.
- Lịch sử trạng thái được ghi vào `public.work_item_state_history` với UUID sinh bởi `uuid_generate_v4()`, khớp định nghĩa bảng trong file dump.
- Mọi literal trạng thái dùng giá trị snake_case theo tài liệu thiết kế trạng thái.
