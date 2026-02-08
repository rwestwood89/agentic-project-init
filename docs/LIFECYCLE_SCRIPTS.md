# Lifecycle Scripts Usage Guide

This document provides comprehensive usage documentation for all dashboard system lifecycle scripts.

## Overview

The dashboard system provides six CLI tools for managing project work items:

- **register-item** - Create new work items
- **move-item** - Move items between stages (backlog → active → completed)
- **update-artifact** - Update artifact frontmatter (status, progress, owner)
- **reconcile-registry** - Rebuild registry from filesystem
- **generate-dashboard** - Generate HTML Kanban dashboard
- **watch-project** - Auto-regenerate dashboard on file changes

All scripts:
- Use atomic file writes (all-or-nothing, no corruption)
- Output JSON for machine parsing (stdout)
- Write human errors to stderr
- Support `--verbose` flag for debug logging
- Exit with code 0 (success), 1 (input error), or 2 (state error)

## Prerequisites

Install dependencies with UV:

```bash
uv sync
```

Run scripts with:

```bash
uv run <script-name> [options]
```

## register-item

Create a new work item in the project registry.

### Usage

```bash
uv run register-item --title "Item Title" [--epic EP-NNN] [--stage backlog|active] [--verbose]
```

### Options

- `--title TEXT` (required) - Work item title
- `--epic EP-NNN` (optional) - Parent epic code (e.g., EP-001)
- `--stage {backlog,active}` (optional) - Initial stage (default: backlog)
- `--verbose` (optional) - Enable debug logging

### Behavior

**Backlog items** (default):
- Registry entry created with `path: null`
- No folder or files created
- Item exists only in registry.json

**Active items** (`--stage active`):
- Registry entry created with path
- Folder created: `.project/active/<slug>/`
- Spec skeleton created: `.project/active/<slug>/spec.md` with frontmatter

### Examples

```bash
# Create backlog item
uv run register-item --title "Add user authentication"

# Create active item with epic
uv run register-item --title "Implement login flow" --epic EP-001 --stage active

# Debug mode
uv run register-item --title "Fix bug #42" --verbose
```

### Output

JSON on stdout:

```json
{
  "code": "WI-001",
  "title": "Add user authentication",
  "epic": null,
  "stage": "backlog",
  "path": null
}
```

### Exit Codes

- `0` - Success
- `1` - Input error (invalid epic, missing title)
- `2` - State error (registry corrupted, missing epic)

---

## move-item

Move a work item between stages.

### Usage

```bash
uv run move-item <code> --to {backlog|active|completed} [--verbose]
```

### Options

- `code` (required) - Work item code (e.g., WI-001)
- `--to {backlog,active,completed}` (required) - Target stage
- `--verbose` (optional) - Enable debug logging

### Valid Transitions

| From | To | Effect |
|------|-----|--------|
| backlog | active | Create folder and spec.md |
| active | backlog | Delete folder (loses artifacts!) |
| active | completed | Rename folder with date prefix, update CHANGELOG.md |

**Invalid transitions**: backlog→completed, completed→anywhere

### Behavior

**backlog → active**:
- Creates `.project/active/<slug>/`
- Generates `spec.md` skeleton with frontmatter
- Updates registry with new path and stage

**active → completed**:
- Renames folder: `active/<slug>/ → completed/YYYY-MM-DD_<slug>/`
- Prepends completion date to `CHANGELOG.md` in folder
- Checks if epic is complete (all items completed)
- Updates registry

**active → backlog**:
- Deletes `.project/active/<slug>/` folder (WARNING: loses spec/design/plan)
- Updates registry with `path: null`

### Examples

```bash
# Move backlog item to active
uv run move-item WI-001 --to active

# Complete an item
uv run move-item WI-002 --to completed

# Move back to backlog (careful!)
uv run move-item WI-003 --to backlog

# Debug mode
uv run move-item WI-004 --to completed --verbose
```

### Output

JSON on stdout:

```json
{
  "code": "WI-001",
  "old_stage": "backlog",
  "new_stage": "active",
  "old_path": null,
  "new_path": "active/add-user-authentication"
}
```

### Exit Codes

- `0` - Success
- `1` - Input error (unknown code, invalid transition)
- `2` - State error (registry corrupted, missing folder)

---

## update-artifact

Update artifact frontmatter (status, progress, owner).

### Usage

```bash
uv run update-artifact <code> --artifact {spec|design|plan} [options]
```

### Options

- `code` (required) - Work item code (e.g., WI-001)
- `--artifact {spec,design,plan}` (required) - Artifact type to update
- `--status {draft,in-progress,complete}` (optional) - New status value
- `--phases-complete N` (optional) - Phases completed (plan artifacts only)
- `--owner TEXT` (optional) - Owner name or identifier
- `--verbose` (optional) - Enable debug logging

### Behavior

- Locates artifact file in registry path (e.g., `.project/active/<slug>/spec.md`)
- Parses YAML frontmatter
- Updates specified fields
- Automatically updates `updated` timestamp to current ISO 8601 time
- Writes file atomically (preserves content)
- Fails gracefully on backlog items (no path)

### Validation

- `phases_complete` must be non-negative
- `phases_complete` cannot exceed `phases_total` (from frontmatter)
- Artifact file must exist
- Frontmatter must be valid YAML

### Examples

```bash
# Mark spec as complete
uv run update-artifact WI-001 --artifact spec --status complete

# Update plan progress
uv run update-artifact WI-002 --artifact plan --phases-complete 3

# Update multiple fields
uv run update-artifact WI-003 --artifact design --status in-progress --owner "Alice"

# Debug mode
uv run update-artifact WI-004 --artifact spec --status complete --verbose
```

### Output

JSON on stdout:

```json
{
  "code": "WI-001",
  "artifact": "spec",
  "updated_fields": {
    "status": "complete",
    "updated": "2026-02-08T14:23:15Z"
  }
}
```

### Exit Codes

- `0` - Success
- `1` - Input error (invalid status, invalid phases_complete)
- `2` - State error (artifact not found, malformed frontmatter, backlog item)

---

## reconcile-registry

Rebuild registry.json from filesystem artifacts.

### Usage

```bash
uv run reconcile-registry [--dry-run] [--project-root .project] [--verbose]
```

### Options

- `--dry-run` (optional) - Show changes without writing to disk
- `--project-root PATH` (optional) - Path to .project/ directory (default: .project)
- `--verbose` (optional) - Enable debug logging

### Behavior

Scans `.project/` directories (backlog/, active/, completed/) for artifacts:
- `spec.md`, `design.md`, `plan.md`

For each artifact:
1. Parse YAML frontmatter
2. Extract `id` field (EP-NNN or WI-NNN)
3. Preserve existing codes
4. Detect duplicate codes (first keeps code, conflict logged to stderr)
5. Determine stage from filesystem location
6. Build new registry

Then:
- Remove registry entries for missing files
- Update `next_epic_id` and `next_item_id` to prevent code conflicts
- Write registry.json atomically (unless --dry-run)

### Idempotent

Safe to re-run. Running twice produces identical registry.

### Examples

```bash
# Preview changes
uv run reconcile-registry --dry-run

# Rebuild registry
uv run reconcile-registry

# Use non-default project root
uv run reconcile-registry --project-root /path/to/project/.project

# Debug mode
uv run reconcile-registry --verbose
```

### Output

JSON on stdout:

```json
{
  "preserved": 15,
  "assigned": 0,
  "conflicts": 0,
  "removed": 2
}
```

- `preserved` - Items with existing codes kept
- `assigned` - Items with missing codes (new codes assigned) *deferred in v1*
- `conflicts` - Duplicate codes detected (first keeps, second gets new code)
- `removed` - Registry entries for missing files

### Exit Codes

- `0` - Success
- `1` - Input error (invalid project root)
- `2` - State error (permission errors, write failures)

---

## generate-dashboard

Generate HTML Kanban dashboard from registry.

### Usage

```bash
uv run generate-dashboard [--output PATH] [--project-root PATH] [--verbose]
```

### Options

- `--output PATH` (optional) - Output path for HTML (default: .project/dashboard.html)
- `--project-root PATH` (optional) - Project root directory (default: current directory)
- `--verbose` (optional) - Enable debug logging

### Behavior

1. Reads `.project/registry.json`
2. Generates three-column Kanban layout: Backlog | Active | Completed
3. Groups items under epic headers
4. Shows ungrouped items separately
5. Renders progress indicators:
   - Definition phase: badges for spec/design/plan
   - Implementation phase: progress bar (phases_complete / phases_total)
6. Writes self-contained HTML file with embedded CSS/JS

### Dashboard Features

- **Click-to-copy** item codes (JavaScript)
- **Hover tooltips** with owner, dates, status
- **Epic progress** calculated from item completion
- **Completion dates** extracted from folder prefixes (e.g., `2026-02-08_item-name`)
- **Last generated** timestamp in footer
- **Self-contained** - no CDN dependencies

### Performance

Generates in <1 second for 100 items.

### Examples

```bash
# Generate dashboard
uv run generate-dashboard

# Custom output location
uv run generate-dashboard --output /tmp/dashboard.html

# Non-default project root
uv run generate-dashboard --project-root /path/to/project

# Debug mode
uv run generate-dashboard --verbose
```

### Output

JSON on stdout:

```json
{
  "output": ".project/dashboard.html",
  "items": 15,
  "epics": 3,
  "generated_at": "2026-02-08T14:30:00Z"
}
```

### Exit Codes

- `0` - Success
- `1` - Input error (invalid paths)
- `2` - State error (missing registry, permission errors)

---

## watch-project

Auto-regenerate dashboard on file changes.

### Usage

```bash
uv run watch-project [--debounce SECONDS] [--project-root PATH] [--output PATH] [--verbose]
```

### Options

- `--debounce SECONDS` (optional) - Debounce period (default: 2.0)
- `--project-root PATH` (optional) - Project root directory (default: current directory)
- `--output PATH` (optional) - Dashboard output path (default: .project/dashboard.html)
- `--verbose` (optional) - Enable debug logging

### Behavior

1. Monitors `.project/` directory for file changes
2. Watches:
   - `registry.json`
   - `spec.md`, `design.md`, `plan.md` files
3. Ignores `dashboard.html` changes (prevents infinite loop)
4. Debounces rapid changes (default 2 seconds)
5. Triggers `generate-dashboard` on changes
6. Logs regeneration events with timestamps
7. Runs as long-lived background process
8. Graceful shutdown on SIGTERM/SIGINT (Ctrl+C)
9. Continues running on generation failures (logs error)

### Signal Handling

- `SIGTERM` - Graceful shutdown
- `SIGINT` (Ctrl+C) - Graceful shutdown

### Examples

```bash
# Start watching
uv run watch-project

# Custom debounce (faster updates)
uv run watch-project --debounce 1.0

# Non-default paths
uv run watch-project --project-root /path/to/project --output /tmp/dashboard.html

# Debug mode
uv run watch-project --verbose
```

### Output

Logs to stderr (timestamped):

```
2026-02-08 14:35:12 - Watching .project/ for changes...
2026-02-08 14:35:30 - Detected change: .project/registry.json
2026-02-08 14:35:32 - Regenerating dashboard...
2026-02-08 14:35:33 - Dashboard regenerated successfully
```

### Exit Codes

- `0` - Normal shutdown (SIGTERM/SIGINT)
- `1` - Input error (invalid paths)
- `2` - State error (permission errors)

---

## Common Workflows

### Create and complete a work item

```bash
# 1. Register new item (backlog)
uv run register-item --title "Add dark mode toggle"

# 2. Move to active
uv run move-item WI-001 --to active

# 3. Mark spec complete
uv run update-artifact WI-001 --artifact spec --status complete

# 4. Mark design complete
uv run update-artifact WI-001 --artifact design --status complete

# 5. Mark plan complete
uv run update-artifact WI-001 --artifact plan --status complete

# 6. Update implementation progress
uv run update-artifact WI-001 --artifact plan --phases-complete 1
uv run update-artifact WI-001 --artifact plan --phases-complete 2

# 7. Complete item
uv run move-item WI-001 --to completed

# 8. Generate dashboard
uv run generate-dashboard
```

### Recover from registry corruption

```bash
# Rebuild registry from filesystem
uv run reconcile-registry

# Verify changes first
uv run reconcile-registry --dry-run
```

### Watch project during development

```bash
# Start file watcher (in background)
uv run watch-project &

# Work normally - dashboard auto-updates
uv run move-item WI-002 --to active
uv run update-artifact WI-002 --artifact spec --status complete

# Open dashboard in browser
open .project/dashboard.html
```

---

## Error Handling

All scripts follow consistent error patterns:

### Input Errors (Exit Code 1)

- Missing required arguments
- Invalid enum values (status, stage, artifact type)
- Unknown item/epic codes
- Invalid transitions

**Example:**

```bash
$ uv run move-item WI-999 --to active
Error: Item WI-999 not found in registry
Available items: WI-001, WI-002, WI-003
Run 'uv run reconcile-registry' to rebuild registry from filesystem
```

### State Errors (Exit Code 2)

- Registry corrupted or missing
- Artifact file not found
- Permission errors
- Filesystem errors

**Example:**

```bash
$ uv run update-artifact WI-001 --artifact spec --status complete
Error: Artifact not found: .project/active/add-dark-mode/spec.md
Item WI-001 is in backlog stage (path: null)
Move to active first: uv run move-item WI-001 --to active
```

### Debug Logging

Use `--verbose` flag for detailed logs:

```bash
$ uv run register-item --title "Test" --verbose
[DEBUG] Loading registry from .project/registry.json
[DEBUG] Registry loaded: 15 items, 3 epics
[DEBUG] Generating next item code: WI-016
[DEBUG] Creating backlog item: WI-016
[DEBUG] Saving registry to .project/registry.json
[INFO] Created item WI-016: Test
```

---

## Integration with Agentic Commands

The lifecycle scripts are integrated with agentic commands:

- `/_my_spec` calls `register-item` to create new specs
- `/_my_design` calls `update-artifact` after design approval
- `/_my_plan` calls `update-artifact` after plan completion
- `/_my_implement` calls `update-artifact` to track phases
- `/_my_implement` calls `move-item` to complete items
- `/_my_project_manage` reads `registry.json` for status
- `/_my_project_manage close` calls `move-item` to complete items

See `.claude/settings.json` for script permissions.

---

## Troubleshooting

### "Registry not found"

```bash
# Initialize registry
echo '{"epics": {}, "items": {}, "next_epic_id": 1, "next_item_id": 1}' > .project/registry.json

# Or rebuild from existing artifacts
uv run reconcile-registry
```

### "Item not found in registry"

```bash
# Rebuild registry from filesystem
uv run reconcile-registry

# Verify item exists
cat .project/registry.json | jq '.items'
```

### "Permission denied"

```bash
# Check file permissions
ls -la .project/

# Fix permissions
chmod 644 .project/registry.json
chmod 755 .project/active/
```

### Dashboard not updating

```bash
# Manually regenerate
uv run generate-dashboard

# Check file watcher logs
uv run watch-project --verbose
```

---

## Performance

Script execution times (100 items, 10 epics):

- `register-item`: <10ms
- `move-item`: <50ms (folder rename)
- `update-artifact`: <20ms
- `reconcile-registry`: <200ms (full scan)
- `generate-dashboard`: <500ms
- `watch-project`: background, <50ms per event

All operations are fast enough for interactive use.

---

## Best Practices

1. **Use backlog by default** - Only create active items when ready to work
2. **Reconcile after manual edits** - Run `reconcile-registry` after editing frontmatter
3. **Watch during development** - Keep `watch-project` running for live dashboard
4. **Dry-run first** - Use `--dry-run` flag when uncertain
5. **Version control registry** - Commit `.project/registry.json` to git
6. **Backup before reconcile** - Reconciliation is idempotent but backup first
7. **Use --verbose for debugging** - All scripts support `--verbose` flag

---

## Future Enhancements

Deferred to future versions:

- Concurrent access handling (registry locking)
- Assign codes to items missing IDs
- Multi-user collaboration
- Real-time dashboard updates (WebSocket)
- GitHub integration (issue sync)
- Custom dashboard themes
