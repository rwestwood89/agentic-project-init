
## Purpose
Define behavior for work items in backlog stage that have no filesystem artifacts yet.

## Requirements
- Backlog items exist in registry with `stage: "backlog"` and `path: null`
- No folder or artifact files exist for backlog items
- Backlog items are created during epic decomposition via `register-item --stage backlog`
- Transition from backlog to active creates folder and spec.md skeleton
- Dashboard displays backlog items in Backlog column grouped by epic
- Backlog items show only code and title (no progress indicators)
- Registry must store enough metadata to render backlog items on dashboard

## Acceptance Criteria

**Given** an epic is decomposed into 5 work items  
**When** decomposition script runs  
**Then** 5 registry entries are created with `stage: "backlog"`, `path: null`, no folders created

**Given** a backlog item WI-012 with title "Setup database schema"  
**When** dashboard is generated  
**Then** item appears in Backlog column with code and title only

**Given** a backlog item WI-012  
**When** `move-item WI-012 --to active` is called  
**Then** folder `active/setup-database-schema/` is created, `spec.md` skeleton is generated, registry path is updated

**Given** a backlog item with `path: null`  
**When** `update-artifact` is called on this item  
**Then** script exits with error "Item is in backlog, no artifacts exist"

**Given** reconciliation runs and finds an item in active/ stage  
**When** the item has valid frontmatter  
**Then** registry entry is created with `stage: "active"` and correct path, never as backlog item

## Interfaces

### Registry Entry for Backlog Item

```json
{
  "WI-012": {
    "title": "Setup database schema",
    "epic": "EP-003",
    "stage": "backlog",
    "path": null
  }
}

