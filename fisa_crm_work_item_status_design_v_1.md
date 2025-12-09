# FISA CRM – Work Item Status Design v1

## 1. Bộ trạng thái chuẩn cho `work_items.status`

### Nhóm 1 – Trước khi chính thức nhận xử lý

1. **`draft`**  
   - Vừa tạo, chưa gửi, đang soạn.  
   - Chỉ chủ yêu cầu (requester) nhìn thấy, có thể chỉnh sửa/xoá.

2. **`open`**  
   - Đã gửi chính thức, đang chờ phân công.  
   - Đây là “điểm bắt đầu” cho SLA.

---

### Nhóm 2 – Đang xử lý (active)

3. **`in_progress`**  
   - Đã được assign cho 1 người/nhóm, đang actively xử lý.  
   - Trạng thái chính mà agent/technician làm việc hàng ngày.

4. **`waiting_internal`**  
   - Đang chờ team nội bộ khác (phòng khác, cấp duyệt…).  
   - Ví dụ: chờ phê duyệt, chờ kỹ thuật khác hỗ trợ.

5. **`waiting_customer`**  
   - Đã phản hồi, đang chờ khách hàng bổ sung thông tin/confirm.

6. **`waiting_external`** *(optional – có thể dùng hoặc bỏ)*  
   - Chờ nhà cung cấp / bên thứ ba.

> 3 trạng thái `waiting_*` quan trọng cho SLA + Dashboard, vì nhìn vào là biết “kẹt ở đâu”.

---

### Nhóm 3 – Đã xử lý xong về mặt kỹ thuật

7. **`resolved`**  
   - Đã có giải pháp, đã xử lý xong **về mặt nghiệp vụ**.  
   - Nhưng chưa confirm/đóng hồ sơ (khách chưa phản hồi hoặc FE chưa bấm Close).  
   - Cho phép **reopen** (resolved → in_progress/open).

---

### Nhóm 4 – Đóng hồ sơ (kết thúc vòng đời)

8. **`closed`**  
   - Đã xác nhận xong, không còn việc phải làm.  
   - Đây là trạng thái **kết thúc “đẹp”** của ticket/request.  
   - Với template **strong coupling**, trạng thái này phải đi cùng `workflow_instances.status = 'completed'`.

9. **`canceled`**  
   - Hủy bởi khách hàng hoặc nội bộ (mở nhầm, không còn nhu cầu…).  
   - Kết thúc vòng đời nhưng **không phải đã giải quyết**.

10. **`rejected`**  
    - Từ chối tiếp nhận xử lý (không thuộc phạm vi, sai kênh, spam…).  
    - Thường dùng ở bước intake/triage.

11. **`archived`**  
    - Đã closed/canceled/rejected lâu ngày, chuyển sang trạng thái lưu trữ.  
    - Chủ yếu dùng cho cơ chế dọn dữ liệu, không phải trạng thái nghiệp vụ người dùng sẽ thao tác trực tiếp.

---

## 2. Mapping qua enum `status_type`

Enum dùng chung:

```sql
CREATE TYPE public.status_type AS ENUM (
  'draft','pending','approved','rejected',
  'ongoing','completed','lead','bidding',
  'ordered','planned','open','paused','archived'
);
```

Đề xuất mapping:

| `work_items.status` | `status_type` | Ghi chú |
|---------------------|--------------|--------|
| `draft`             | `draft`      | Khớp 1-1 |
| `open`              | `open`       | Điểm bắt đầu SLA |
| `in_progress`       | `ongoing`    | Đang xử lý |
| `waiting_internal`  | `pending`    | Đang chờ, vẫn tính active |
| `waiting_customer`  | `pending`    | Tách logic ở app-level |
| `waiting_external`  | `pending`    | Tách logic ở app-level |
| `resolved`          | `completed`  | Đã xử lý xong, chờ close |
| `closed`            | `completed`  | Kết thúc đẹp |
| `canceled`          | `archived`   | Kết thúc nhưng không giải quyết |
| `rejected`          | `rejected`   | Từ chối từ intake |
| `archived`          | `archived`   | Lưu trữ |

Ghi chú:
- Các module khác (projects, contracts…) nếu dùng `status_type` vẫn giữ nguyên.
- Work item sẽ có bộ trạng thái riêng nhưng vẫn gom được về `status_type` để làm filter/report cross-module.

---

## 3. Quy ước kết nối CRM & Workflow

Bám theo mô hình **strong / loose coupling**:

- Với template **strong coupling**:
  - `work_items.status = 'closed'`  ⇒ `workflow_instances.status = 'completed'`.
  - `work_items.status` IN (`'canceled'`, `'rejected'`) ⇒ `workflow_instances.status = 'canceled'`.
- Cho phép **reopen**:
  - `closed`/`resolved` → `open`/`in_progress` ⇒ workflow_instance có transition `reopen`.
- Với template có `allow_post_close_work = true`:
  - Cho phép workflow_instance tiếp tục một số step nội bộ sau khi `work_items.status = 'closed'`, nhưng phải log rõ trong `workflow_instance_journal` + outbox.

---

## 4. Hướng implement

- `work_items.status` hiện là `varchar(50)` + default `'draft'` → **chưa cần đổi schema**.
- BE/FE:
  - Dùng enum trong code (C# & TS) theo bộ status ở mục 1.
  - Viết hàm helper map `WorkItemStatus → status_type` khi cần.
- Nếu sau này muốn siết chặt:
  - Có thể tạo thêm bảng `wi_statuses` hoặc enum `wi_status` + Schema Delta riêng, nhưng giữ backwards-compatible với dữ liệu cũ.

