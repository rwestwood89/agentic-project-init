
## Purpose
Define the structure and semantics of `.project/registry.json` as the source of truth for structural project data.

## Requirements
- Registry is a single JSON file at `.project/registry.json`
- Contains three top-level keys: `epics`, `items`, `next_epic_id`, `next_item_id`
- `epics` maps epic codes to epic metadata objects
- `items` maps work item codes to work item metadata objects
- `next_epic_id` and `next_item_id` are integers tracking next code to assign
- Epic metadata must include: code, title, status
- Item metadata must include: code, title, epic (nullable), stage, path (nullable)
- Path is relative to `.project/` directory
- Stage is one of: `backlog`, `active`, `completed`
- Backlog items have `path: null` (no folder exists yet)
- Registry can be regenerated from filesystem and artifact frontmatter (rebuildable index)
- All writes must be atomic (temp file + rename pattern)

## Acceptance Criteria

**Given** a registry file with 5 items and 2 epics  
**When** the registry is parsed  
**Then** all fields are present and correctly typed per schema

**Given** an item in backlog stage  
**When** the registry is read  
**Then** the item's path field is null

**Given** an active item with folder `active/implement-auth-flow/`  
**When** the registry is read  
**Then** the item's path is `active/implement-auth-flow`

**Given** a registry update operation  
**When** the write is performed  
**Then** data is written to temp file, then atomically renamed to `registry.json`

**Given** two scripts attempt to update registry simultaneously  
**When** both perform atomic writes  
**Then** last write wins (no partial corruption), but concurrent access is out of scope for v1

**Given** registry and filesystem are out of sync  
**When** reconciliation script runs  
**Then** registry is rebuilt from filesystem with all codes preserved from frontmatter

## Interfaces

### File Location
`.project/registry.json`

### JSON Schema

```typescript
{
  epics: {
    [epicCode: string]: {
      title: string,
      status: "active" | "completed"
    }
  },
  items: {
    [itemCode: string]: {
      title: string,
      epic: string | null,  // Epic code or null
      stage: "backlog" | "active" | "completed",
      path: string | null   // Relative to .project/, null for backlog items
    }
  },
  next_epic_id: number,   // Next EP code numeric part
  next_item_id: number    // Next WI code numeric part
}

