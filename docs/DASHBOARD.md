# Dashboard Documentation

This document describes the HTML Kanban dashboard features and usage.

## Overview

The dashboard provides a visual Kanban board for tracking project work items. It shows:

- Three-column layout: **Backlog** | **Active** | **Completed**
- Items grouped under epic headers
- Real-time progress indicators
- Click-to-copy item codes
- Hover tooltips with metadata

## Generating the Dashboard

### Manual Generation

```bash
uv run generate-dashboard
```

Output: `.project/dashboard.html`

### Custom Output Location

```bash
uv run generate-dashboard --output /path/to/dashboard.html
```

### Auto-Regeneration

Use the file watcher to automatically regenerate on changes:

```bash
uv run watch-project
```

Dashboard updates within 2 seconds of registry or artifact changes.

---

## Dashboard Layout

### Three-Column Kanban

```
┌─────────────┬─────────────┬─────────────┐
│  Backlog    │   Active    │  Completed  │
│             │             │             │
│ ┌─────────┐ │ ┌─────────┐ │ ┌─────────┐ │
│ │ EP-001  │ │ │ EP-001  │ │ │ EP-001  │ │
│ └─────────┘ │ └─────────┘ │ └─────────┘ │
│   WI-002    │   WI-001    │   WI-003    │
│   WI-004    │             │             │
│             │             │             │
│ ┌─────────┐ │ ┌─────────┐ │ ┌─────────┐ │
│ │No Epic  │ │ │No Epic  │ │ │No Epic  │ │
│ └─────────┘ │ └─────────┘ │ └─────────┘ │
│   WI-006    │   WI-005    │   WI-007    │
└─────────────┴─────────────┴─────────────┘
```

### Epic Headers

Epic headers show:

- **Epic code** (e.g., `EP-001`)
- **Epic title** (e.g., "User Authentication System")
- **Progress summary** (e.g., "2 / 5 complete")

Items are grouped under their parent epic. Ungrouped items (no epic) appear in a separate "No Epic" section.

### Item Cards

Each item card shows:

- **Item code** (e.g., `WI-001`) - click to copy
- **Item title** (e.g., "Implement login flow")
- **Progress indicator** - badges or progress bar
- **Completion date** (completed items only)

---

## Progress Indicators

Dashboard shows two types of progress indicators based on work phase.

### Definition Phase (Badges)

Before implementation starts, dashboard shows badges for three artifacts:

```
[spec] [design] [plan]
```

- ✅ **Green badge** - artifact complete (`status: complete`)
- ⬜ **Gray badge** - artifact incomplete (missing or `status: draft/in-progress`)

**Example:**

```
WI-001: Implement login flow
[spec] [design] ▢ plan
```

Means: spec and design are complete, plan not started.

### Implementation Phase (Progress Bar)

When a plan exists with `phases_total` and `phases_complete`, dashboard shows a progress bar:

```
████████░░ 60% (3 / 5)
```

- **Progress bar** - visual fill based on percentage
- **Percentage** - `phases_complete / phases_total * 100`
- **Fraction** - `phases_complete / phases_total`

**Example:**

```
WI-001: Implement login flow
████████████████████ 100% (5 / 5)
```

Means: all 5 implementation phases are complete.

### Automatic Switching

Dashboard automatically switches between badge and progress bar modes:

- **Badges shown** when plan has no `phases_total` field
- **Progress bar shown** when plan has `phases_total` > 0

---

## Interactive Features

### Click to Copy Item Codes

Click any item code to copy it to clipboard:

```
┌─────────────────────────┐
│ WI-001 ← click here     │
│ Implement login flow    │
└─────────────────────────┘
```

After clicking:

1. Code copied to clipboard
2. Visual feedback: code briefly turns green
3. Tooltip shows "Copied!"

**Use case**: Quickly copy codes for use in commands:

```bash
uv run move-item WI-001 --to completed
```

### Hover Tooltips

Hover over any item card to see metadata tooltip:

```
┌─────────────────────────────┐
│ Owner: Alice                │
│ Created: 2026-02-01 10:00   │
│ Updated: 2026-02-08 14:30   │
│ Status: in-progress         │
└─────────────────────────────┘
```

Tooltip shows:

- **Owner** - Person responsible
- **Created** - Initial creation date
- **Updated** - Last modification date
- **Status** - Current status (draft/in-progress/complete)

---

## Completion Dates

Completed items show completion date extracted from folder name:

```
WI-003: Fix session timeout bug
Completed: 2026-02-08
```

Dashboard extracts date from folder prefix:

```
.project/completed/2026-02-08_fix-session-timeout-bug/
                   ^^^^^^^^^^
```

Format: `YYYY-MM-DD_<slug>`

---

## Epic Progress

Epic headers calculate aggregate progress from all items in the epic:

```
EP-001: User Authentication System
2 / 5 complete
```

- **2** - Number of completed items in epic
- **5** - Total number of items in epic

Progress percentage determines header color:

- **0%** - Gray (not started)
- **1-99%** - Blue (in progress)
- **100%** - Green (complete)

---

## Dashboard Features

### Self-Contained HTML

Dashboard is a single HTML file with:

- **Embedded CSS** - No external stylesheets
- **Embedded JavaScript** - No external scripts
- **No CDN dependencies** - Works offline

Open dashboard in any browser without internet connection.

### Responsive Layout

Dashboard adapts to screen size:

- **Desktop** - Three columns side-by-side
- **Tablet** - Columns stack vertically
- **Mobile** - Single column layout

### Last Generated Timestamp

Dashboard footer shows generation timestamp:

```
Last generated: 2026-02-08 14:30:00 UTC
```

Helps identify stale dashboards.

---

## Opening the Dashboard

### macOS

```bash
open .project/dashboard.html
```

### Linux

```bash
xdg-open .project/dashboard.html
```

### Windows

```bash
start .project/dashboard.html
```

### Direct Path

Open in browser:

```
file:///home/user/project/.project/dashboard.html
```

---

## Customization

### Dashboard Location

Change output location with `--output` flag:

```bash
uv run generate-dashboard --output ./public/dashboard.html
```

Useful for:

- Serving from web server
- Deploying to static hosting
- Custom project structure

### File Watcher Configuration

Configure file watcher:

```bash
# Faster updates (1 second debounce)
uv run watch-project --debounce 1.0

# Custom dashboard location
uv run watch-project --output ./public/dashboard.html
```

---

## Performance

Dashboard generation is fast:

| Project Size | Generation Time |
|--------------|-----------------|
| 10 items     | <100ms          |
| 50 items     | <300ms          |
| 100 items    | <500ms          |
| 500 items    | <2s             |

Performance tested on typical laptop (2023 MacBook Pro).

### Large Projects

For projects with >500 items:

- Generation may take several seconds
- Consider splitting into multiple projects
- Use epic filtering (future feature)

---

## Dashboard Updates

Dashboard updates in three ways:

### 1. Manual Generation

Regenerate anytime:

```bash
uv run generate-dashboard
```

### 2. Automatic File Watcher

File watcher monitors `.project/` and regenerates on changes:

```bash
uv run watch-project
```

Triggers on:

- Registry changes (`.project/registry.json`)
- Artifact changes (`spec.md`, `design.md`, `plan.md`)
- File creation/deletion/modification

Ignores:

- Dashboard changes (prevents infinite loop)
- Temporary files (`.tmp`, `~`)

### 3. Command Integration

Agentic commands trigger regeneration automatically:

- `/_my_spec` → register item → regenerate dashboard
- `/_my_implement` → update progress → regenerate dashboard
- `/_my_project_manage close` → move to completed → regenerate dashboard

---

## Troubleshooting

### Dashboard Not Updating

**Symptom**: File watcher running but dashboard not updating.

**Check:**

```bash
# Verify watcher is running
ps aux | grep watch-project

# Check watcher logs
uv run watch-project --verbose
```

**Fix:**

Restart file watcher:

```bash
# Stop (Ctrl+C)
# Start
uv run watch-project
```

### Missing Items

**Symptom**: Items in registry but not showing in dashboard.

**Check:**

1. Verify registry is valid JSON:

```bash
cat .project/registry.json | jq .
```

2. Check for frontmatter issues:

```bash
head -n 20 .project/active/*/spec.md
```

**Fix:**

Rebuild registry:

```bash
uv run reconcile-registry
uv run generate-dashboard
```

### Incorrect Progress

**Symptom**: Progress bar shows wrong percentage.

**Check:**

```bash
# Verify plan frontmatter
grep -A 15 "^---" .project/active/*/plan.md
```

**Fix:**

Update phases:

```bash
uv run update-artifact WI-001 --artifact plan --phases-complete 3
```

### Dashboard Not Opening

**Symptom**: Dashboard file exists but won't open in browser.

**Check:**

```bash
ls -lh .project/dashboard.html
file .project/dashboard.html
```

**Fix:**

Regenerate:

```bash
uv run generate-dashboard
```

### Styling Issues

**Symptom**: Dashboard looks broken or unstyled.

**Check:**

Browser console for JavaScript errors.

**Fix:**

Regenerate with latest script:

```bash
uv run generate-dashboard
```

---

## Dashboard Data Flow

```
┌───────────────────┐
│ Filesystem        │
│ ├─ registry.json  │
│ ├─ spec.md        │
│ ├─ design.md      │
│ └─ plan.md        │
└───────┬───────────┘
        │
        ▼
┌───────────────────┐
│ File Watcher      │
│ (watch-project)   │
└───────┬───────────┘
        │
        ▼
┌───────────────────┐
│ Dashboard Gen     │
│ (generate-dash)   │
└───────┬───────────┘
        │
        ▼
┌───────────────────┐
│ dashboard.html    │
│ (self-contained)  │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ Browser           │
│ (view dashboard)  │
└───────────────────┘
```

---

## Example Dashboard

### Small Project (5 items, 1 epic)

**Registry:**

```json
{
  "epics": {
    "EP-001": {
      "title": "User Authentication",
      "status": "active"
    }
  },
  "items": {
    "WI-001": {
      "title": "Implement login",
      "epic": "EP-001",
      "stage": "active",
      "path": "active/implement-login"
    },
    "WI-002": {
      "title": "Add password reset",
      "epic": "EP-001",
      "stage": "backlog",
      "path": null
    },
    "WI-003": {
      "title": "Add signup flow",
      "epic": "EP-001",
      "stage": "completed",
      "path": "completed/2026-02-01_add-signup-flow"
    }
  }
}
```

**Dashboard:**

```
┌─────────────────┬──────────────────┬──────────────────┐
│ Backlog         │ Active           │ Completed        │
├─────────────────┼──────────────────┼──────────────────┤
│ EP-001          │ EP-001           │ EP-001           │
│ User Auth       │ User Auth        │ User Auth        │
│ 1 / 3 complete  │ 1 / 3 complete   │ 1 / 3 complete   │
│                 │                  │                  │
│ ┌─────────────┐ │ ┌──────────────┐ │ ┌──────────────┐ │
│ │ WI-002      │ │ │ WI-001       │ │ │ WI-003       │ │
│ │ Add pwd     │ │ │ Implement    │ │ │ Add signup   │ │
│ │ reset       │ │ │ login        │ │ │              │ │
│ │             │ │ │ [spec][des]  │ │ │ 2026-02-01   │ │
│ └─────────────┘ │ └──────────────┘ │ └──────────────┘ │
└─────────────────┴──────────────────┴──────────────────┘
```

---

## Best Practices

1. **Keep watcher running** - Run `watch-project` during active development
2. **Open in separate window** - Keep dashboard visible while working
3. **Refresh manually** - Browser auto-refreshes when file changes (with live server)
4. **Use click-to-copy** - Click codes instead of typing manually
5. **Check tooltips** - Hover for quick metadata lookup
6. **Monitor epic progress** - Use epic headers to track milestone progress
7. **Archive completed epics** - Move old completed items to archive (manual process)

---

## Integration with Workflow

Dashboard integrates seamlessly with agentic workflow:

### 1. Create Spec

```bash
/_my_spec   # Creates WI-NNN, updates registry
# Dashboard auto-regenerates, shows new backlog item
```

### 2. Move to Active

```bash
uv run move-item WI-001 --to active
# Dashboard auto-regenerates, item moves to Active column
```

### 3. Track Progress

```bash
/_my_implement WI-001   # Updates plan phases
# Dashboard auto-regenerates, progress bar updates
```

### 4. Complete Item

```bash
/_my_project_manage close WI-001
# Dashboard auto-regenerates, item moves to Completed column
```

### 5. Review Progress

Open dashboard to see visual overview of all work.

---

## Future Enhancements

Planned for future versions:

- **Filtering** - Filter by epic, owner, status
- **Sorting** - Sort by date, priority, title
- **Search** - Search items by title or code
- **Themes** - Dark mode, custom colors
- **Export** - Export to PDF, CSV
- **Real-time updates** - WebSocket for live updates
- **Mobile app** - Native mobile dashboard
- **Analytics** - Velocity charts, burndown charts

---

## Related Documentation

- [Lifecycle Scripts Usage Guide](LIFECYCLE_SCRIPTS.md) - CLI tools that update dashboard data
- [Registry Schema](REGISTRY_SCHEMA.md) - Data source for dashboard
- [Frontmatter Schema](FRONTMATTER_SCHEMA.md) - Metadata used in progress indicators
