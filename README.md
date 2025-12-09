# FISA CRM Work Item State Machine

This repository implements the CRM work-item state machine described in `fisa_crm_work_item_state_machine_and_workflow_integration_v_1.md` and the status design in `fisa_crm_work_item_status_design_v_1.md`. The code targets .NET 8 and is organized so that application-layer services own the workflow-driven transitions while keeping database writes consistent with `schema_dump_v7i.sql`.

## Architecture

- **Application layer** (`src/Fisa.Crm.Application`)
  - `WorkItems/IWorkItemStateMachine` exposes a single entry point for mutating work item status inside an existing database transaction.
  - `WorkItemStateMachine` implements the rules via `WorkItemStateMachineRules`, persisting changes to `public.work_items` and `public.work_item_state_history` using Dapper.
  - `WorkItemAction`, `WorkItemStatuses`, and supporting DTOs (`WorkItemActionContext`, `WorkItemStateChangeResult`) mirror the action and status vocabulary from the functional documents.
  - `IClock` abstracts time to keep the service testable and to stamp `updated_at` / `closed_at` consistently.
- **Tests** (`src/Fisa.Crm.Tests`)
  - Unit coverage for the state-machine rules ensures the allowed transitions stay aligned with the specification and catch regressions without hitting the database.

The state machine enforces the transition matrix from the specification:

| Action | From statuses | To status |
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

Actions that terminate a work item (`close`, `cancel`, `reject`, `archive`) also stamp `closed_at` following the nullable column in `schema_dump_v7i.sql`. Each status change writes an audit row into `public.work_item_state_history` with the acting user and note supplied by the `WorkItemActionContext`.

Workflow integration flags follow the document’s guidance: the state machine sets `ShouldNotifyWorkflow` for `Close`, `Cancel`, `Reopen`, and `AutoCloseFromWorkflow` so callers can sync with Workflow Runtime v1 after the database transaction succeeds.

## Installing .NET SDK

The project targets .NET 8. Use the dotnet-install script to fetch the SDK in environments without a preinstalled toolchain:

```bash
curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version 8.0.401 --install-dir "$HOME/.dotnet"
export PATH="$HOME/.dotnet:$PATH"
```

If your network is behind an HTTPS proxy, ensure `HTTPS_PROXY`/`HTTP_PROXY` is set appropriately before running the script.

## Building and testing

Run restores and tests from the repository root once the .NET SDK is available:

```bash
cd src
dotnet restore
cd ..
dotnet test src/Fisa.Crm.Tests
```

`WorkItemStateMachine` is database-agnostic for unit tests; it accepts an `IDbConnection` and `IDbTransaction` so integration tests can exercise the SQL paths against the schema in `schema_dump_v7i.sql`.

## Project layout

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

## Notes on database alignment

- `WorkItemStateMachine` updates `public.work_items.status`, `updated_at`, `updated_by`, `assignee_id`, and `closed_at` exactly as defined in `schema_dump_v7i.sql`.
- State history writes go to `public.work_item_state_history` with a generated UUID (`uuid_generate_v4()`), matching the table definition in the schema dump.
- All status literals use the snake_case values mandated by the status design document.
