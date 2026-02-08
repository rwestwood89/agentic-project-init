
## Purpose
Rebuild the registry from filesystem state when registry and artifacts are out of sync.

## Requirements
- Provide a `reconcile-registry` script that reconstructs `registry.json` from scratch
- Scan all artifact files in `.project/` tree for YAML frontmatter
- Preserve all existing codes found in frontmatter
- Assign new codes to valid artifacts missing IDs
- Set `next_epic_id` and `next_item_id` to one higher than max found
- Detect and resolve conflicts (duplicate codes, mismatched titles)
- Reconciliation is idempotent (running twice produces same result)
- Script outputs summary of actions taken (items found, codes assigned, conflicts)

## Acceptance Criteria

**Given** registry is deleted and 10 artifacts exist with valid frontmatter  
**When** reconciliation runs  
**Then** registry is rebuilt with all 10 items, codes preserved, next_ids set correctly

**Given** two items have duplicate code `WI-007` in frontmatter  
**When** reconciliation runs  
**Then** first item keeps WI-007, second item receives new code, conflict is logged to stderr

**Given** an artifact exists without YAML frontmatter  
**When** reconciliation runs  
**Then** the artifact is ignored (not added to registry)

**Given** a registry entry exists but artifact file is deleted  
**When** reconciliation runs  
**Then** registry entry is removed (filesystem is source of truth)

**Given** registry has `next_item_id: 5` but highest item code is WI-012  
**When** reconciliation runs  
**Then** `next_item_id` is updated to 13

## Interfaces

### Script: reconcile-registry

**Usage:**
```bash
reconcile-registry [--dry-run]

