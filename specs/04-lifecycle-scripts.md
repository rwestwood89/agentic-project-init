
## Purpose
Provide deterministic, atomic scripts for creating, moving, and updating work items to replace manual agent operations.

## Requirements
- Three primary scripts: `register-item`, `move-item`, `update-artifact`
- Scripts are command-line tools with well-defined arguments and exit codes
- All scripts must be idempotent where possible
- Scripts update both registry and filesystem atomically per operation
- All scripts written in Python using standard library only (no external dependencies)
- Scripts output JSON for machine-readable results
- Scripts write human-readable errors to stderr
- Exit code 0 for success, non-zero for errors

## Acceptance Criteria

**Given** the `register-item` script is called with title and epic  
**When** the script completes successfully  
**Then** registry is updated, folder is created, skeleton artifact exists with frontmatter, code is output

**Given** the `move-item` script is called to move WI-015 from active to completed  
**When** the script executes  
**Then** folder is renamed with date prefix, registry is updated, CHANGELOG.md has entry, epic status is updated if all items complete

**Given** the `update-artifact` script is called to mark a spec as complete  
**When** the script runs  
**Then** YAML frontmatter `status` and `updated` fields are modified, file content is preserved

**Given** `move-item` is called on an already-completed item  
**When** the script runs  
**Then** exits with code 2 (state error), outputs error message explaining item is already completed

**Given** `update-artifact` is called with an invalid status value  
**When** the script validates input  
**Then** exits with code 1 (input error), outputs usage information

## Interfaces

### Script 1: register-item

**Purpose:** Create new work item entry (used at epic decomposition or ad-hoc item creation)

**Usage:**
```bash
register-item [--epic EP-NNN] --title "Item title" [--stage backlog|active]

