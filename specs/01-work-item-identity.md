
## Purpose
Provide stable, unique codes for referencing work items and epics throughout their lifecycle.

## Requirements
- Every work item receives a permanent code in format `WI-NNN` (e.g., `WI-001`, `WI-015`)
- Every epic receives a permanent code in format `EP-NNN` (e.g., `EP-001`, `EP-003`)
- Codes are assigned at creation/registration time and never change
- Codes are independent of stage, epic membership, or folder location
- Item codes and epic codes use separate auto-incrementing sequences
- Codes start at 001 for both sequences in new projects
- Code assignment must be deterministic (no race conditions in single-agent operation)
- Codes must be easily parseable with regex: `(EP|WI)-\d{3}`

## Acceptance Criteria

**Given** a new work item is created  
**When** the creation script is invoked  
**Then** the next available `WI-NNN` code is assigned atomically

**Given** multiple items are registered during epic decomposition  
**When** the decomposition script runs  
**Then** each item receives a unique sequential code in a single transaction

**Given** an item is moved between stages  
**When** the move operation completes  
**Then** the item's code remains unchanged

**Given** a user searches for an item by code  
**When** querying the registry  
**Then** the code resolves to exactly one item with current location

**Given** the registry is corrupted and reconciliation is triggered  
**When** the reconciliation script scans existing artifacts  
**Then** existing codes in YAML frontmatter are preserved, new items receive next-available codes

## Interfaces

### Data Storage
- **Registry format**: Defined in `02-registry-data-model.md`
- **Frontmatter format**: Defined in `03-yaml-frontmatter-schema.md`

### Code Format
```regex
Epic:      ^EP-\d{3}$
Work Item: ^WI-\d{3}$

