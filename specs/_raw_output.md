Perfect! Now I have the full concept document. I'll create individual specification files based on this comprehensive design. Let me break it down into focused, single-concern specs.

```markdown specs/01-work-item-identity.md
# Work Item Identity System

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
```

### Outputs Used By
- Dashboard generation (spec `06-dashboard-generation.md`)
- CLI script arguments (spec `04-lifecycle-scripts.md`)
- Commit messages and documentation references
- Agent command invocations

## Constraints
- MUST NOT reassign codes after initial assignment
- MUST NOT reuse codes from deleted items
- MUST maintain sequential ordering (no gaps by design, but gaps are acceptable if items are removed)
- Code assignment MUST be atomic (write next_id and item entry together)
- Legacy items created before this system MUST NOT be migrated or assigned codes

## Out of Scope
- Human-readable slugs (codes are numeric only)
- Cross-project code namespacing
- Code compaction or resequencing after deletions
- Validation that old `EPIC-NNN` format (from legacy system) is not confused with new `EP-NNN` format
```

```markdown specs/02-registry-data-model.md
# Registry Data Model

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
```

### Example
```json
{
  "epics": {
    "EP-001": { "title": "Authentication System", "status": "active" },
    "EP-002": { "title": "Dashboard UI", "status": "completed" }
  },
  "items": {
    "WI-001": {
      "title": "Design auth flow",
      "epic": "EP-001",
      "stage": "completed",
      "path": "completed/2026-01-15_design-auth-flow"
    },
    "WI-002": {
      "title": "Implement login endpoint",
      "epic": "EP-001",
      "stage": "active",
      "path": "active/implement-login-endpoint"
    },
    "WI-003": {
      "title": "Setup session management",
      "epic": "EP-001",
      "stage": "backlog",
      "path": null
    }
  },
  "next_epic_id": 3,
  "next_item_id": 4
}
```

### Used By
- `04-lifecycle-scripts.md` (all scripts read/write registry)
- `06-dashboard-generation.md` (reads registry as primary data source)
- `07-reconciliation.md` (rebuilds registry)

## Constraints
- MUST NOT store per-artifact status (belongs in frontmatter)
- MUST NOT store implementation details like phase counts (belongs in plan frontmatter)
- MUST be writable atomically (no partial states on disk)
- MUST use relative paths (portable across machines)
- Title in registry MAY differ from frontmatter temporarily (reconciliation resolves)

## Out of Scope
- Locking or concurrent access coordination
- Version history or audit trail of registry changes
- Backup/restore mechanisms
- Schema migration for breaking changes
- Validation that paths actually exist on filesystem (registry is authoritative, reconciliation fixes drift)
```

```markdown specs/03-yaml-frontmatter-schema.md
# YAML Frontmatter Schema

## Purpose
Define standardized YAML frontmatter structure for spec, design, and plan artifacts to enable reliable automated parsing.

## Requirements
- All spec.md, design.md, and plan.md files begin with YAML frontmatter
- Frontmatter is delimited by `---` on separate lines before and after YAML content
- Common fields (all artifact types): `id`, `title`, `type`, `status`, `epic`, `owner`, `created`, `updated`
- Plan-specific fields: `phases_total`, `phases_complete`
- `id` must match work item code from registry
- `type` must be one of: `spec`, `design`, `plan`
- `status` must be one of: `draft`, `in-progress`, `complete`
- `epic` is epic code or `null`
- Timestamps must use ISO 8601 format
- Frontmatter must be parseable by standard YAML libraries
- Scripts must preserve frontmatter formatting when updating values

## Acceptance Criteria

**Given** a spec file with valid frontmatter  
**When** parsed by a Python YAML library  
**Then** all required fields are present and correctly typed

**Given** a plan file at 0% progress  
**When** the frontmatter is read  
**Then** `phases_total` is a positive integer and `phases_complete` is 0

**Given** a completed design artifact  
**When** the frontmatter status is read  
**Then** the status field equals `"complete"`

**Given** a script updates the `updated` timestamp  
**When** the file is written back  
**Then** all other frontmatter fields and all content below frontmatter are preserved

**Given** an artifact with missing or malformed frontmatter  
**When** the dashboard generation runs  
**Then** the item is ignored (not shown), no error is raised

## Interfaces

### Frontmatter Structure

**Common fields (spec, design, plan):**
```yaml
---
id: WI-NNN
title: Human-readable item title
type: spec | design | plan
status: draft | in-progress | complete
epic: EP-NNN | null
owner: Author name or identifier
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```

**Additional fields for plan artifacts:**
```yaml
phases_total: <positive integer>
phases_complete: <non-negative integer, <= phases_total>
```

### Example: Spec File
```yaml
---
id: WI-015
title: Design authentication flow
type: spec
status: complete
epic: EP-002
owner: agent-alpha
created: 2026-02-08T14:30:00Z
updated: 2026-02-08T16:45:00Z
---

# Authentication Flow Specification

[Content continues below frontmatter...]
```

### Example: Plan File
```yaml
---
id: WI-022
title: Implement user dashboard
type: plan
status: in-progress
epic: EP-003
owner: agent-beta
created: 2026-02-10T09:00:00Z
updated: 2026-02-10T11:30:00Z
phases_total: 5
phases_complete: 2
---

# Implementation Plan: User Dashboard

[Plan content...]
```

### Used By
- `04-lifecycle-scripts.md` (creates, reads, updates frontmatter)
- `06-dashboard-generation.md` (reads frontmatter for progress display)
- `07-reconciliation.md` (reads frontmatter to rebuild registry)

## Constraints
- Frontmatter MUST be at the very start of file (no content before first `---`)
- Closing `---` MUST be followed by blank line before markdown content
- `updated` timestamp MUST be updated whenever any field changes
- `id` MUST match the registry entry (reconciliation enforces this)
- MUST NOT use YAML features that could execute code (no `!!python/object`)
- `phases_complete` MUST NOT exceed `phases_total`

## Out of Scope
- Rich metadata like tags, labels, or custom fields
- Version history within frontmatter
- Nested or hierarchical metadata structures
- Localization or multi-language support for field values
- Validation of `owner` field against a user registry (free-form string)
```

```markdown specs/04-lifecycle-scripts.md
# Lifecycle Scripts

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
```

**Arguments:**
- `--title` (required): Work item title
- `--epic` (optional): Parent epic code
- `--stage` (optional): Initial stage, default `backlog`

**Output (stdout):**
```json
{"code": "WI-016", "path": null}
```
or if `--stage active`:
```json
{"code": "WI-016", "path": "active/item-title-slug"}
```

**Exit codes:**
- 0: Success
- 1: Invalid arguments
- 2: Registry corruption or filesystem error

**Behavior:**
- Reads registry, assigns next `next_item_id` as code
- Creates registry entry with stage, title, epic, path
- If stage is `active`: creates folder, generates spec.md skeleton with frontmatter
- If stage is `backlog`: sets path to null, no folder created
- Writes registry atomically
- Increments `next_item_id`

### Script 2: move-item

**Purpose:** Move item between stages (backlog→active, active→completed, etc.)

**Usage:**
```bash
move-item <WI-NNN> --to <backlog|active|completed>
```

**Arguments:**
- Item code (positional, required)
- `--to` (required): Target stage

**Output (stdout):**
```json
{"code": "WI-016", "old_stage": "active", "new_stage": "completed", "path": "completed/2026-02-08_item-title-slug"}
```

**Exit codes:**
- 0: Success
- 1: Invalid arguments or item not found
- 2: Invalid transition (e.g., backlog→completed without passing through active)

**Behavior:**
- Reads registry, finds item by code
- Validates transition (backlog can only move to active, active can move to completed or back to backlog)
- If moving to `active` from `backlog`: creates folder, generates spec.md skeleton
- If moving to `completed` from `active`: renames folder with date prefix, updates CHANGELOG.md
- If moving back to `backlog` from `active`: deletes folder (with confirmation?)
- Updates registry `stage` and `path` fields
- Checks if epic has all items completed, updates epic status if so
- Writes registry atomically

### Script 3: update-artifact

**Purpose:** Update YAML frontmatter fields in artifact files

**Usage:**
```bash
update-artifact <WI-NNN> --artifact <spec|design|plan> --status <draft|in-progress|complete>
update-artifact <WI-NNN> --artifact plan --phases-complete <N>
```

**Arguments:**
- Item code (positional, required)
- `--artifact` (required): Which file to update
- `--status` (optional): New status value
- `--phases-complete` (optional, plan only): Update phase count

**Output (stdout):**
```json
{"code": "WI-016", "artifact": "spec", "updated_fields": ["status", "updated"]}
```

**Exit codes:**
- 0: Success
- 1: Invalid arguments, item not found, or artifact file does not exist
- 2: Invalid status value or phases_complete > phases_total

**Behavior:**
- Reads registry to resolve code to path
- Reads artifact file, parses YAML frontmatter
- Updates specified field(s)
- Updates `updated` timestamp
- Writes file atomically (temp file + rename)
- **Does NOT update registry** (frontmatter is separate concern)

### Used By
- `08-command-integration.md` (agentic commands call these scripts)
- Agents during manual operations (fallback if commands don't cover scenario)

### Dependencies
- `01-work-item-identity.md` (uses code format)
- `02-registry-data-model.md` (reads/writes registry)
- `03-yaml-frontmatter-schema.md` (parses/writes frontmatter)

## Constraints
- MUST validate all inputs before modifying filesystem or registry
- MUST use atomic writes for both registry and artifact files
- MUST preserve all existing content when updating frontmatter
- MUST NOT execute any YAML content (safe parsing only)
- MUST handle missing registry gracefully (error, do not auto-create)
- Scripts MUST be standalone executables (shebang `#!/usr/bin/env python3`)

## Out of Scope
- Bulk operations (batch moves, batch updates)
- Interactive prompts (fully non-interactive for agent use)
- Rollback or undo functionality
- Git integration (scripts modify files, agents handle commits)
- Validation that artifact content matches its status (only metadata is updated)
- Creation of design or plan artifacts (only spec.md is auto-generated)
```

```markdown specs/05-reconciliation.md
# Registry Reconciliation

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
```

**Arguments:**
- `--dry-run` (optional): Output actions without writing registry

**Output (stdout):**
```json
{
  "items_found": 12,
  "epics_found": 3,
  "codes_assigned": 2,
  "conflicts_resolved": 1,
  "registry_written": true
}
```

**Exit codes:**
- 0: Success
- 1: Filesystem read errors
- 2: Unable to write registry

**Behavior:**
1. Traverse `.project/{backlog,active,completed}/` directories
2. For each markdown file, attempt to parse YAML frontmatter
3. Extract `id`, `title`, `type`, `epic`, `status`
4. Build in-memory maps of items and epics
5. Detect duplicate codes: first occurrence wins, others get new codes
6. Infer `stage` from folder location (backlog/, active/, completed/)
7. Set `path` to relative path from `.project/`
8. Compute `next_epic_id` = max(epic codes) + 1
9. Compute `next_item_id` = max(item codes) + 1
10. Write reconstructed registry atomically
11. Output summary JSON

### Used By
- Manual recovery after agent errors
- CI/CD validation (detect drift)
- Post-migration from legacy system

### Dependencies
- `02-registry-data-model.md` (writes registry format)
- `03-yaml-frontmatter-schema.md` (parses frontmatter)

## Constraints
- MUST NOT modify artifact files (read-only on filesystem)
- MUST treat filesystem as source of truth (registry is derived)
- MUST preserve existing codes (no renumbering)
- MUST handle partial failures gracefully (skip unparseable files, continue processing)
- MUST log conflicts and resolutions to stderr for auditability

## Out of Scope
- Fixing malformed YAML frontmatter (artifacts without valid frontmatter are ignored)
- Merging registry changes from multiple sources
- Interactive conflict resolution (first-wins policy is deterministic)
- Backup of old registry before overwrite (user should use version control)
```

```markdown specs/06-dashboard-generation.md
# Dashboard Generation

## Purpose
Generate an HTML Kanban dashboard showing all work items organized by stage and epic.

## Requirements
- Script `generate-dashboard` creates `.project/dashboard.html`
- Dashboard layout: three columns (Backlog, Active, Completed)
- Items grouped under epic headers within each column
- Ungrouped items appear in separate section per column
- Epic headers show epic code, title, and aggregate progress
- Item cards show code, title, progress indicator, and completion date
- Progress indicator for active items: definition phase (badges) or implementation phase (progress bar)
- Dashboard includes "Last generated" timestamp
- Click-to-copy functionality on item codes (minimal JavaScript)
- Tooltips on cards showing owner, dates, status details
- HTML is self-contained (embedded CSS, minimal embedded JS, no external CDN dependencies)
- Generation completes in <1 second for projects with 100 items

## Acceptance Criteria

**Given** a registry with 3 epics and 15 items  
**When** dashboard generation runs  
**Then** HTML file is created with three column layout, items correctly placed, epics as headers

**Given** an active item with spec and design complete, plan not started  
**When** dashboard renders the item  
**Then** item card shows badges: `[spec]` `[design]` and missing badge for plan

**Given** an active item with plan showing phases_complete=3, phases_total=5  
**When** dashboard renders the item  
**Then** item card shows progress bar at 60% with text "3 / 5"

**Given** a completed item moved on 2026-02-08  
**When** dashboard renders the item  
**Then** item card shows completion date "2026-02-08"

**Given** an item code is clicked in the dashboard  
**When** JavaScript handler runs  
**Then** code is copied to clipboard and visual feedback is shown

**Given** mouse hovers over an item card  
**When** tooltip is displayed  
**Then** tooltip shows owner, created date, updated date, current status

## Interfaces

### Script: generate-dashboard

**Usage:**
```bash
generate-dashboard [--output PATH]
```

**Arguments:**
- `--output` (optional): Output file path, default `.project/dashboard.html`

**Output (stdout):**
```json
{"items_rendered": 15, "epics_rendered": 3, "generation_time_ms": 234}
```

**Exit codes:**
- 0: Success
- 1: Registry not found or invalid
- 2: Unable to write output file

**Behavior:**
1. Read `.project/registry.json`
2. For each active item, read artifact files to determine definition progress
3. For each active item with plan, read `phases_complete` / `phases_total`
4. Group items by epic within each stage
5. Generate HTML using embedded Python string template
6. Add timestamp to HTML
7. Write HTML atomically

### HTML Structure (Wireframe)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Project Dashboard</title>
  <style>/* Embedded CSS for Kanban layout */</style>
</head>
<body>
  <header>
    <h1>Project Dashboard</h1>
    <span class="timestamp">Last generated: 2026-02-08 14:32:15</span>
  </header>
  <div class="board">
    <div class="column" data-stage="backlog">
      <h2>Backlog</h2>
      <div class="epic-group">
        <h3 class="epic-header">EP-001: Authentication System <span>(2 / 4 items)</span></h3>
        <div class="item-card" data-code="WI-003" title="Owner: agent-alpha, Created: 2026-02-05">
          <span class="item-code" onclick="copyCode('WI-003')">WI-003</span>
          <span class="item-title">Setup session management</span>
        </div>
        <!-- More items... -->
      </div>
      <div class="epic-group">
        <h3 class="epic-header">Ungrouped</h3>
        <!-- Ungrouped items... -->
      </div>
    </div>
    <div class="column" data-stage="active">
      <h2>Active</h2>
      <!-- Similar structure... -->
    </div>
    <div class="column" data-stage="completed">
      <h2>Completed</h2>
      <!-- Similar structure... -->
    </div>
  </div>
  <script>
    function copyCode(code) {
      navigator.clipboard.writeText(code);
      // Visual feedback
    }
  </script>
</body>
</html>
```

### Used By
- `07-file-watcher.md` (triggered on file changes)
- Manual dashboard refresh command
- Agents via `/_my_project_manage status` command

### Dependencies
- `02-registry-data-model.md` (reads registry)
- `03-yaml-frontmatter-schema.md` (reads artifact frontmatter for progress)

## Constraints
- MUST render in modern browsers (Chrome, Firefox, Safari, Edge)
- MUST NOT require internet connection (no CDN dependencies)
- MUST NOT execute any user content as code (XSS prevention)
- MUST handle missing artifacts gracefully (show partial progress)
- MUST handle large projects (100 items) without performance degradation
- HTML MUST be valid (passes W3C validator)

## Out of Scope
- Sorting or filtering controls
- Drag-and-drop item movement
- Inline editing of item fields
- Real-time updates via websockets
- Mobile-responsive layout optimization
- Dark mode toggle
- Customizable column definitions
- Historical views or timeline visualization
```

```markdown specs/07-file-watcher.md
# File Watcher

## Purpose
Automatically regenerate dashboard when project files change to keep dashboard current.

## Requirements
- Script `watch-project` monitors `.project/` directory for changes
- Triggers `generate-dashboard` when relevant files change
- Debounces rapid changes (wait N seconds after last change before regenerating)
- Watches registry.json and all artifact files (spec.md, design.md, plan.md)
- Ignores changes to dashboard.html itself (prevent infinite loop)
- Outputs log messages for monitoring
- Runs as long-lived background process
- Can be gracefully stopped via SIGTERM

## Acceptance Criteria

**Given** the watch script is running  
**When** `registry.json` is modified  
**Then** dashboard regenerates within 2 seconds

**Given** a spec.md file is updated  
**When** the change is detected  
**Then** dashboard regenerates after debounce period (2 seconds)

**Given** 5 files are modified in rapid succession  
**When** debounce logic activates  
**Then** dashboard regenerates once, 2 seconds after the last change

**Given** dashboard.html is regenerated  
**When** the watcher sees dashboard.html change  
**Then** no regeneration is triggered (infinite loop prevented)

**Given** the watcher process receives SIGTERM  
**When** signal handler runs  
**Then** process logs shutdown message and exits gracefully

**Given** dashboard generation fails due to corrupt registry  
**When** watcher detects the failure  
**Then** error is logged to stderr, watcher continues running

## Interfaces

### Script: watch-project

**Usage:**
```bash
watch-project [--debounce SECONDS]
```

**Arguments:**
- `--debounce` (optional): Seconds to wait after last change, default 2

**Output (stdout):**
```
[2026-02-08 14:32:10] Watching .project/ for changes...
[2026-02-08 14:35:22] Change detected: registry.json
[2026-02-08 14:35:24] Regenerating dashboard...
[2026-02-08 14:35:24] Dashboard updated successfully
```

**Exit codes:**
- 0: Graceful shutdown via signal
- 1: Initialization error (directory not found, inotifywait not available)

**Behavior:**
1. Validate `.project/` directory exists
2. Initialize file watcher on `.project/**/*.{json,md}` excluding `dashboard.html`
3. Enter watch loop
4. On file change event: reset debounce timer
5. When debounce timer expires: call `generate-dashboard`
6. Log result (success or error)
7. Continue watching

### Implementation Technology
- **Linux**: `inotifywait` from inotify-tools package (bash script wrapping inotifywait)
- **macOS**: `fswatch` (bash script wrapping fswatch)
- **Fallback**: Manual triggering via command if watcher tools not available

### Used By
- Developers who open dashboard in VSCode Live Preview
- Background process started with project workspace

### Dependencies
- `06-dashboard-generation.md` (calls generate-dashboard script)

## Constraints
- MUST NOT trigger on its own output (dashboard.html)
- MUST handle high-frequency changes without overloading system
- MUST continue running after generation errors (resilient)
- MUST be manually started (not auto-started by other scripts)
- MUST log all activity for debugging

## Out of Scope
- Auto-start on workspace open (user responsibility)
- Cross-platform unified implementation (platform-specific tools are acceptable)
- Watching changes from remote filesystems or network drives
- Notification to user when dashboard is stale (reliance on timestamp in HTML)
- Rate limiting beyond debounce (debounce is sufficient for single-agent operation)
```

```markdown specs/08-command-integration.md
# Command Integration

## Purpose
Integrate lifecycle scripts into existing agentic commands to automate registry and metadata management.

## Requirements
- Update five agentic commands: `_my_spec`, `_my_design`, `_my_plan`, `_my_implement`, `_my_project_manage`
- Commands must call lifecycle scripts at appropriate workflow steps
- Commands must handle script failures gracefully (log error, inform user, allow manual fallback)
- Commands must preserve existing behavior when scripts are not available
- Updated command prompts must instruct agents to use scripts, not manual file operations
- Integration points must be documented in command source
- Settings file `.claude/settings.local.json` must include permissions for new scripts

## Acceptance Criteria

**Given** `/_my_spec` command is invoked to create a new item  
**When** the command reaches the "create item" step  
**Then** the agent calls `register-item` script instead of manually creating folder

**Given** `/_my_implement` command marks a phase complete  
**When** the agent updates progress  
**Then** the agent calls `update-artifact --phases-complete N` instead of editing frontmatter

**Given** `/_my_project_manage close` command is invoked  
**When** the command reaches the move step  
**Then** the agent calls `move-item WI-NNN --to completed` and does NOT manually move folder or edit CHANGELOG.md

**Given** a lifecycle script fails with exit code 2  
**When** the command detects the failure  
**Then** the agent logs the error, informs the user, and pauses for user decision

**Given** lifecycle scripts are not installed  
**When** the command attempts to call a script  
**Then** the command detects absence, warns user, falls back to previous manual method

## Interfaces

### Command Modifications

#### `_my_spec` command
**Integration point:** After user confirms item title and epic  
**Action:** Call `register-item --title "..." [--epic EP-NNN] --stage active`  
**Output handling:** Parse JSON output for assigned code, use code in subsequent steps

#### `_my_design` command
**Integration point:** After design document is written and user approves  
**Action:** Call `update-artifact <code> --artifact design --status complete`  
**Output handling:** Log success, update session context with completion

#### `_my_plan` command
**Integration point:** After plan document is written  
**Action:** Call `update-artifact <code> --artifact plan --status complete`  
**Additional:** Set `phases_total` in frontmatter during plan creation

#### `_my_implement` command
**Integration point:** After each phase completion is confirmed  
**Action:** Call `update-artifact <code> --artifact plan --phases-complete N`  
**Output handling:** Verify success, continue to next phase or mark item complete

**Integration point:** After final phase completion  
**Action:** Call `move-item <code> --to completed`  
**Output handling:** Verify CHANGELOG.md is updated, confirm epic completion status

#### `_my_project_manage` command
**Subcommand: status**  
**Integration point:** Beginning of status report generation  
**Action:** Read `.project/registry.json` directly for structured data  
**Output handling:** Use registry as primary data source instead of parsing markdown files

**Subcommand: close**  
**Integration point:** After user confirms item to close  
**Action:** Call `move-item <code> --to completed`  
**Output handling:** Verify folder renamed, CHANGELOG.md updated

**Subcommand: archive**  
**Integration point:** After user confirms item to archive  
**Action:** Call `move-item <code> --to completed` (if not already), then perform archival compression  
**Output handling:** Verify registry reflects completion before archiving

### Settings File: `.claude/settings.local.json`

**New entries required:**
```json
{
  "allowedCommands": [
    ".project/scripts/register-item",
    ".project/scripts/move-item",
    ".project/scripts/update-artifact",
    ".project/scripts/reconcile-registry",
    ".project/scripts/generate-dashboard"
  ]
}
```

### Used By
- Agents during all project management workflows

### Dependencies
- `04-lifecycle-scripts.md` (calls all three scripts)
- `06-dashboard-generation.md` (status command may trigger dashboard refresh)

## Constraints
- Commands MUST NOT bypass scripts and perform manual operations (except as fallback)
- Commands MUST validate script availability before workflow begins
- Commands MUST parse script JSON output correctly
- Commands MUST propagate script errors to user with actionable messages
- Fallback to manual mode MUST be explicit (warn user that registry will be stale)

## Out of Scope
- Automatic installation of scripts (user/agent must install manually)
- Retry logic for transient script failures
- Command-level transactions (if script succeeds but command fails later, no rollback)
- Migration of existing commands to use registry exclusively (hybrid approach is acceptable for v1)
```

```markdown specs/09-atomic-writes.md
# Atomic File Writes

## Purpose
Ensure all registry and artifact file modifications are atomic to prevent corruption from partial writes or failures.

## Requirements
- All scripts that write files must use atomic write pattern
- Pattern: write to temporary file, then rename to target path
- Python implementation uses `tempfile.mkstemp()` or `tempfile.NamedTemporaryFile()` and `os.rename()`
- Temporary files must be in same filesystem as target (for atomic rename guarantee)
- If write or rename fails, temporary file is cleaned up
- Atomic writes apply to: registry.json, all artifact frontmatter updates, dashboard.html
- Permissions of target file are preserved after rename

## Acceptance Criteria

**Given** a script writes an updated registry  
**When** the write operation is performed  
**Then** data is written to a temp file in `.project/`, then renamed to `registry.json`

**Given** a script updates artifact frontmatter  
**When** the update is performed  
**Then** new content is written to temp file in same directory as artifact, then renamed

**Given** a write operation fails halfway through (disk full, interrupted)  
**When** the error occurs  
**Then** target file is unchanged (old content remains), temp file is deleted

**Given** a rename operation succeeds  
**When** the file is replaced  
**Then** the operation is atomic (no partial states visible to other processes)

**Given** a script crashes after writing temp file but before rename  
**When** the script is re-run  
**Then** orphaned temp file is ignored or cleaned up, new temp file is used

## Interfaces

### Python Implementation Pattern

```python
import tempfile
import os
import json

def atomic_write_json(data, target_path):
    """Write data to target_path atomically."""
    dir_path = os.path.dirname(target_path)
    fd, temp_path = tempfile.mkstemp(dir=dir_path, prefix='.tmp_', suffix='.json')
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(data, f, indent=2)
        os.chmod(temp_path, 0o644)  # Set readable permissions
        os.rename(temp_path, target_path)
    except Exception as e:
        os.unlink(temp_path)  # Clean up on failure
        raise e
```

### Used By
- `04-lifecycle-scripts.md` (all scripts writing registry or artifacts)
- `06-dashboard-generation.md` (writing dashboard.html)
- `05-reconciliation.md` (writing rebuilt registry)

## Constraints
- Temporary files MUST be in same directory as target file (same filesystem)
- Temporary files MUST have unique names to avoid collisions
- Temporary file prefix MUST start with `.` (hidden) to avoid clutter
- Cleanup MUST occur in exception handlers (no temp file leaks)
- MUST NOT use `os.replace()` fallback on Windows without testing atomicity

## Out of Scope
- Locking to prevent concurrent writes (single-agent assumption)
- Backup of previous file version before overwrite
- Transactional multi-file updates (each file write is independent)
- Fsync or disk flush (rely on OS buffering for performance)
```

```markdown specs/10-backlog-item-handling.md
# Backlog Item Handling

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
```

### Dashboard Rendering

Backlog items appear as simple cards:
```html
<div class="item-card backlog-item" data-code="WI-012">
  <span class="item-code">WI-012</span>
  <span class="item-title">Setup database schema</span>
</div>
```

### Used By
- `04-lifecycle-scripts.md` (register-item creates backlog entries, move-item transitions to active)
- `06-dashboard-generation.md` (renders backlog items without progress data)

### Dependencies
- `02-registry-data-model.md` (defines path: null semantics)

## Constraints
- Backlog items MUST NOT have folders or artifact files on filesystem
- Scripts MUST validate stage before attempting to read artifact files
- Dashboard MUST handle `path: null` gracefully (no broken links)
- Reconciliation MUST NOT create backlog entries (only active/completed items found on disk)

## Out of Scope
- Ordering or prioritization within backlog
- Bulk promotion of multiple backlog items to active
- Rich metadata for backlog items (minimal fields only: code, title, epic, stage)
- Estimation or sizing fields for backlog items
```

Perfect! I've created 10 focused specification files covering the complete Ralph Loop dashboard system. Each spec:

1. **Addresses a single concern** (identity, registry, frontmatter, scripts, reconciliation, dashboard, watcher, integration, atomic writes, backlog handling)
2. **Uses the exact format requested** with Purpose, Requirements, Acceptance Criteria, Interfaces, Constraints, and Out of Scope sections
3. **Is 50-150 lines** as specified
4. **Ordered by dependency** (foundational specs first)
5. **Cross-references other specs** by filename in the Interfaces sections
6. **Includes machine-verifiable acceptance criteria** using Given/When/Then format

The specifications progress from foundational concepts (identity system, data models) through implementation details (scripts, reconciliation) to user-facing features (dashboard, watcher) and finally integration concerns (command updates, atomic operations, edge cases).

Each spec is implementable independently once its dependencies are complete, making them suitable for a Ralph Loop where an agent picks a spec, implements it, tests it, and commits.
