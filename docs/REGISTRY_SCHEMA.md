# Registry Schema Documentation

This document describes the structure and semantics of `.project/registry.json`.

## Overview

The registry is the **source of truth** for structural project data. It tracks:

- All epics and their status
- All work items and their stage/location
- Next available epic and item IDs

The registry is a **rebuildable index** - it can be regenerated from filesystem artifacts using the `reconcile-registry` script.

## File Location

```
.project/registry.json
```

## Top-Level Schema

```typescript
{
  epics: {
    [epicCode: string]: EpicMetadata
  },
  items: {
    [itemCode: string]: ItemMetadata
  },
  next_epic_id: number,   // Next EP-NNN numeric part
  next_item_id: number    // Next WI-NNN numeric part
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `epics` | object | Yes | Map of epic codes to epic metadata |
| `items` | object | Yes | Map of work item codes to item metadata |
| `next_epic_id` | number | Yes | Next numeric ID for epic codes (1-999) |
| `next_item_id` | number | Yes | Next numeric ID for item codes (1-999) |

## Epic Metadata

```typescript
{
  title: string,
  status: "active" | "completed"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Human-readable epic title |
| `status` | enum | Yes | Epic status: `active` or `completed` |

### Epic Status Rules

- Epic is `active` if any work item in the epic is not completed
- Epic is `completed` if all work items in the epic are completed
- Empty epics (no items) remain `active`

### Example

```json
{
  "EP-001": {
    "title": "User Authentication System",
    "status": "active"
  },
  "EP-002": {
    "title": "Payment Integration",
    "status": "completed"
  }
}
```

## Item Metadata

```typescript
{
  title: string,
  epic: string | null,
  stage: "backlog" | "active" | "completed",
  path: string | null
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Human-readable item title |
| `epic` | string or null | Yes | Parent epic code (e.g., `EP-001`) or `null` |
| `stage` | enum | Yes | Item stage: `backlog`, `active`, or `completed` |
| `path` | string or null | Yes | Path relative to `.project/`, or `null` for backlog |

### Stage Descriptions

| Stage | Path | Folder Location | Description |
|-------|------|-----------------|-------------|
| `backlog` | `null` | *none* | Planned but not started |
| `active` | `active/<slug>` | `.project/active/<slug>/` | In progress |
| `completed` | `completed/YYYY-MM-DD_<slug>` | `.project/completed/YYYY-MM-DD_<slug>/` | Finished |

### Path Rules

- **Backlog items**: `path` MUST be `null` (no folder exists)
- **Active items**: `path` MUST be `active/<slug>` (folder exists)
- **Completed items**: `path` MUST be `completed/YYYY-MM-DD_<slug>` (date-prefixed folder)
- Paths are relative to `.project/` directory
- Slug is URL-safe version of title (lowercase, hyphens, no special chars)

### Example

```json
{
  "WI-001": {
    "title": "Implement login flow",
    "epic": "EP-001",
    "stage": "active",
    "path": "active/implement-login-flow"
  },
  "WI-002": {
    "title": "Add password reset",
    "epic": "EP-001",
    "stage": "backlog",
    "path": null
  },
  "WI-003": {
    "title": "Fix session timeout bug",
    "epic": null,
    "stage": "completed",
    "path": "completed/2026-02-08_fix-session-timeout-bug"
  }
}
```

## Code Format

### Epic Codes

Format: `EP-NNN`

- Prefix: `EP-` (uppercase)
- Number: 3 digits (001-999), zero-padded
- Examples: `EP-001`, `EP-042`, `EP-123`

Regex: `^EP-\d{3}$`

### Work Item Codes

Format: `WI-NNN`

- Prefix: `WI-` (uppercase)
- Number: 3 digits (001-999), zero-padded
- Examples: `WI-001`, `WI-042`, `WI-123`

Regex: `^WI-\d{3}$`

### Next ID Fields

`next_epic_id` and `next_item_id` track the next numeric ID to assign:

- Range: 1-999
- Incremented after each code assignment
- Used to prevent code conflicts
- Updated by `reconcile-registry` to be one higher than max existing code

**Example:**

```json
{
  "epics": {
    "EP-001": { ... },
    "EP-003": { ... }
  },
  "items": {
    "WI-001": { ... },
    "WI-002": { ... },
    "WI-005": { ... }
  },
  "next_epic_id": 4,   // Next epic will be EP-004
  "next_item_id": 6    // Next item will be WI-006
}
```

## Complete Example

```json
{
  "epics": {
    "EP-001": {
      "title": "User Authentication System",
      "status": "active"
    },
    "EP-002": {
      "title": "Payment Integration",
      "status": "completed"
    }
  },
  "items": {
    "WI-001": {
      "title": "Implement login flow",
      "epic": "EP-001",
      "stage": "active",
      "path": "active/implement-login-flow"
    },
    "WI-002": {
      "title": "Add password reset",
      "epic": "EP-001",
      "stage": "backlog",
      "path": null
    },
    "WI-003": {
      "title": "Integrate Stripe API",
      "epic": "EP-002",
      "stage": "completed",
      "path": "completed/2026-01-15_integrate-stripe-api"
    },
    "WI-004": {
      "title": "Add payment UI",
      "epic": "EP-002",
      "stage": "completed",
      "path": "completed/2026-01-20_add-payment-ui"
    },
    "WI-005": {
      "title": "Fix typo in README",
      "epic": null,
      "stage": "completed",
      "path": "completed/2026-02-01_fix-typo-in-readme"
    }
  },
  "next_epic_id": 3,
  "next_item_id": 6
}
```

## Data Integrity Rules

### Mandatory Constraints

1. **All items have stage and path consistency**:
   - `stage == "backlog"` implies `path == null`
   - `stage == "active"` implies `path != null` and starts with `active/`
   - `stage == "completed"` implies `path != null` and starts with `completed/`

2. **All epic references are valid**:
   - If `item.epic != null`, then epic code must exist in `epics` object

3. **Codes are unique**:
   - Epic codes are unique within `epics`
   - Item codes are unique within `items`
   - No collisions between epic and item namespaces (different prefixes)

4. **Next IDs are sequential**:
   - `next_epic_id` > max existing epic numeric ID
   - `next_item_id` > max existing item numeric ID

### Recommended Constraints

1. **Epic status matches items**:
   - Epic is `completed` only if all its items are `completed`
   - Scripts enforce this rule when moving items

2. **Paths match filesystem**:
   - If `path != null`, folder `.project/{path}/` should exist
   - If `path == null`, folder should NOT exist
   - Use `reconcile-registry` to rebuild registry from filesystem

## Atomic Writes

All registry updates MUST use atomic writes:

1. Write to temp file: `.project/.registry.json.tmp.XXXXXX`
2. Atomically rename to target: `.project/registry.json`

This ensures:
- All-or-nothing writes (no partial corruption)
- Concurrent reads always see valid JSON
- Failed writes leave registry unchanged

**Python Implementation:**

```python
from src.utils.atomic_write import atomic_write_json

registry = {
    "epics": {...},
    "items": {...},
    "next_epic_id": 3,
    "next_item_id": 6
}

atomic_write_json(".project/registry.json", registry)
```

## Reconciliation

Registry can be rebuilt from filesystem using `reconcile-registry` script.

### Reconciliation Algorithm

1. **Scan** `.project/` for artifacts:
   - `backlog/*/spec.md`
   - `active/*/spec.md`, `active/*/design.md`, `active/*/plan.md`
   - `completed/*/spec.md`, `completed/*/design.md`, `completed/*/plan.md`

2. **Extract** codes from YAML frontmatter `id` field

3. **Preserve** existing codes (first artifact wins on duplicates)

4. **Detect** duplicate codes (log conflict, second gets new code)

5. **Determine** stage from filesystem location

6. **Build** new registry with all discovered items

7. **Update** `next_epic_id` and `next_item_id` to prevent conflicts

8. **Write** registry atomically

### When to Reconcile

Run `reconcile-registry` after:

- Manual frontmatter edits
- Moving files in `.project/` manually
- Merging git branches (registry conflicts)
- Deleting artifacts manually
- Registry corruption

### Idempotency

Reconciliation is idempotent:

```bash
uv run reconcile-registry
uv run reconcile-registry
# Registry unchanged on second run
```

## Version Control

Commit `.project/registry.json` to git:

```gitignore
# .gitignore
.project/dashboard.html   # Generated, don't commit
.project/.registry.json.tmp.*  # Temp files
```

Registry is small (typically <50KB for 100 items) and compresses well.

## Migration and Compatibility

### Adding New Fields

New optional fields can be added without breaking existing readers:

```json
{
  "items": {
    "WI-001": {
      "title": "...",
      "epic": "EP-001",
      "stage": "active",
      "path": "active/...",
      "priority": "high"  // New optional field
    }
  }
}
```

Readers should ignore unknown fields.

### Removing Fields

Required fields cannot be removed (breaking change).

Optional fields can be deprecated:

1. Mark field as deprecated in docs
2. Continue writing field (for old readers)
3. After transition period, stop writing field

### Schema Versioning

Future versions may add top-level `schema_version` field:

```json
{
  "schema_version": 2,
  "epics": {...},
  "items": {...}
}
```

Current version is implicitly `1` (no version field).

## Performance Considerations

### Size Limits

Recommended limits:

- **Epics**: 1-100 (typically 5-20)
- **Items**: 1-1000 (typically 50-200)
- **File size**: <1MB (100KB typical)

Performance degrades with >1000 items (dashboard generation slow).

### Indexing

Registry uses object keys for O(1) lookup:

```python
registry["items"]["WI-001"]  # Fast lookup by code
```

No additional indexing needed.

### Caching

Scripts load registry on startup, cache in memory during execution:

```python
registry = Registry.load(".project/registry.json")  # Load once
# Use registry for multiple operations
registry.save(".project/registry.json")  # Save once
```

Avoid loading/saving for every operation.

## Error Handling

### Missing Registry

If `.project/registry.json` not found:

```python
# Initialize empty registry
registry = {
    "epics": {},
    "items": {},
    "next_epic_id": 1,
    "next_item_id": 1
}
```

Or run `reconcile-registry` to rebuild from filesystem.

### Corrupted Registry

If JSON parse fails:

1. Backup corrupted file: `registry.json.backup`
2. Run `reconcile-registry` to rebuild
3. Manually merge if needed

### Schema Violations

If registry violates constraints (invalid stage, missing path):

1. Scripts fail fast with clear error
2. Run `reconcile-registry` to fix
3. Manually fix if reconciliation fails

## Security Considerations

### Path Traversal

Registry paths MUST be validated:

```python
import os

def validate_path(path: str) -> None:
    """Ensure path is relative and within .project/"""
    if os.path.isabs(path):
        raise ValueError(f"Path must be relative: {path}")
    if ".." in path:
        raise ValueError(f"Path traversal not allowed: {path}")
    if not path.startswith(("active/", "completed/")):
        raise ValueError(f"Invalid path prefix: {path}")
```

Prevents attackers from writing outside `.project/` directory.

### Code Injection

Codes are validated with strict regex:

```python
import re

EPIC_CODE_PATTERN = re.compile(r"^EP-\d{3}$")
ITEM_CODE_PATTERN = re.compile(r"^WI-\d{3}$")

def validate_epic_code(code: str) -> None:
    if not EPIC_CODE_PATTERN.match(code):
        raise ValueError(f"Invalid epic code: {code}")
```

Prevents shell injection or filesystem exploits.

## Best Practices

1. **Always use atomic writes** - Use `atomic_write_json()` utility
2. **Validate before write** - Check schema constraints before saving
3. **Version control registry** - Commit to git for history
4. **Reconcile after manual edits** - Keep registry in sync with filesystem
5. **Back up before reconcile** - Reconciliation is safe but backup first
6. **Use scripts, not manual edits** - Scripts enforce invariants
7. **Monitor registry size** - Performance degrades with >1000 items

## Related Documentation

- [Lifecycle Scripts Usage Guide](LIFECYCLE_SCRIPTS.md) - CLI tools for registry manipulation
- [Frontmatter Schema](FRONTMATTER_SCHEMA.md) - YAML frontmatter structure in artifacts
- [Dashboard Documentation](DASHBOARD.md) - HTML dashboard generation
