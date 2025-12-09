# Changelog

## 2025-12-11
- Bổ sung hướng dẫn từng bước để chạy `WorkItemStateMachine` trong README, bao gồm ví dụ mở transaction và khởi tạo `IClock`.

## 2025-12-10
- Thêm `NpgsqlConnectionFactory` để cấu hình chuỗi kết nối PostgreSQL qua biến môi trường `FISA_CRM_DB_CONNECTION_STRING` hoặc
  tham số truyền vào.
- Bổ sung hướng dẫn đặt connection string và ví dụ sử dụng vào README.

## 2025-12-09
- Added .NET 8 application layer implementation for the work item state machine following FISA CRM specs.
- Captured status/action definitions and workflow notification flags in code and unit tests.
- Documented installation, architecture, and database alignment in the README.
- Installed .NET SDK 8.0 in the working environment and translated the README to tiếng Việt for clearer onboarding.
