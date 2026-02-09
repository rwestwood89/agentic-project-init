# Concept: Project Dashboard & Management Upgrade

**Created:** 2026-02-08
**Status:** Draft

---

## Problem Statement

The current `.project/` management system works but has reliability and visibility gaps:

- **No at-a-glance visibility.** Understanding project status requires reading multiple markdown files across directories. There is no unified view of what's backlogged, active, or complete.
- **Inconsistent metadata.** Artifact headers (spec, design, plan) vary in format and fields. This makes automated parsing unreliable and creates drift between documents.
- **No formal work item identity.** Items are referenced by folder name, which is fragile. There is no stable code system for referencing items in commits, conversations, or cross-document links.
- **Manual, error-prone operations.** Moving items between stages, updating status fields, and keeping tracking docs in sync is done manually by the agent. This leads to stale data (e.g., CURRENT_WORK.md last updated 2025-12-30) and inconsistencies.

## Success Criteria

When this work is complete:

1. **A visual Kanban dashboard exists** that shows all work items organized into Backlog, Active, and Completed columns, grouped by epic. It renders as HTML in a VSCode tab via Live Preview and stays current as `.project/` files change.
2. **Every work item and epic has a stable, unique code** (e.g., `EP-003`, `WI-017`) that is assigned at creation/decomposition and never changes. These codes are the primary way to reference items.
3. **All spec, design, and plan files use standardized YAML frontmatter** with a defined schema. Any script or tool can reliably extract metadata from any artifact.
4. **Core lifecycle operations are handled by deterministic scripts** — creating items, moving items between stages, and updating status. Agents call these scripts rather than performing raw file operations.
5. **Active items on the dashboard show meaningful progress** — whether they are "in definition" (which artifacts exist) or "in implementation" (phases completed out of total).
6. **The agentic commands (`/_my_spec`, `/_my_design`, `/_my_plan`, `/_my_implement`, `/_my_project_manage`)** instruct agents to use the new scripts for lifecycle operations.

---

## User Stories

### Visibility

**US-1: Dashboard at a glance**
As a project manager, I can open a single dashboard in VSCode and immediately see all work items organized as a Kanban board (Backlog | Active | Completed), so I understand project status without reading individual files.

**US-2: Epic grouping**
As a project manager, I can see work items grouped under their parent epic on the dashboard, so I can track progress toward larger goals. Items not assigned to an epic appear in an "Ungrouped" section.

**US-3: Active item progress**
As a project manager, I can see at a glance whether an active item is still being defined (which of spec/design/plan exist) or is in implementation (e.g., "Phase 2 of 5 complete"), so I know where things stand without opening individual files.

**US-4: Dashboard freshness**
As a project manager, the dashboard reflects the current state of `.project/` within seconds of any file change, so I can trust what I'm seeing. The HTML regenerates automatically via a file watcher and Live Preview picks up changes. If the watcher is not running, I can manually trigger regeneration via a script or agentic command as a fallback.

### Referenceability

**US-5: Stable work item codes**
As a developer or agent, every work item has a stable code (e.g., `WI-015`) that I can use in commit messages, conversations, cross-references, and command arguments. The code never changes regardless of the item's stage or epic.

**US-6: Epic codes**
As a developer or agent, every epic has a stable code (e.g., `EP-003`) that I can use to reference the epic and find all items under it.

**US-7: Easy code access from dashboard**
As a user viewing the dashboard, I can quickly copy a work item's code (e.g., via click-to-copy) so I can reference it in my current work session.

### Reliability

**US-8: Scripted item creation**
As an agent running `/_my_spec`, the script that creates a new work item automatically assigns the next available code, creates the folder, generates a properly formatted spec.md with correct YAML frontmatter, and registers the item in the registry.

**US-9: Scripted stage transitions**
As an agent running `/_my_project_manage close`, the script that moves an item from active to completed handles renaming, updates the registry, updates CHANGELOG.md, and updates the epic's completion status — all atomically.

**US-10: Scripted status updates**
As an agent, when I update an artifact's status (e.g., Draft to Complete), I call a script that updates the YAML frontmatter and ensures the registry reflects the change. I do not manually edit metadata fields.

**US-11: Consistent frontmatter**
As a system (dashboard, scripts, agents), every spec.md, design.md, and plan.md has YAML frontmatter conforming to a defined schema. I can parse any artifact reliably.

### Robustness

**US-12: Registry reconciliation**
As a developer, if the registry and filesystem get out of sync (e.g., manual edits, agent errors, partial failures), I can run a reconciliation script that rebuilds the registry from the filesystem and artifact frontmatter. The registry is a rebuildable index, not an irreplaceable database.

**US-13: Non-conforming items are invisible**
As a developer, if I manually create a spec/design/plan without YAML frontmatter, or if legacy items exist from before this system, they are simply invisible to the dashboard and registry. The system does not crash, warn, or attempt to parse them — it only tracks items created through the proper scripts. This is by design: the registry is the canonical list of tracked items.

### Agent Experience

**US-14: Structured project queries**
As an agent running `/_my_project_manage status`, I can query the registry for structured data about item states, epic progress, and backlog contents, so my status reports are faster and more accurate than parsing multiple markdown files.

**US-15: Code-based references in commands**
As an agent, I can reference work items by code (e.g., `WI-015`) when calling lifecycle scripts and agentic commands, rather than relying on folder names or paths.

---

## Key Concepts

### 1. Work Item Code System

Every work item gets a permanent, auto-incrementing code:
- **Epics:** `EP-NNN` (e.g., `EP-001`, `EP-002`)
- **Work Items:** `WI-NNN` (e.g., `WI-001`, `WI-015`)

This is a new system. Existing items/epics created before this system (e.g., the current `EPIC-NNN` items in BACKLOG.md) are not migrated — they are simply not tracked by the dashboard or registry. The new `EP-NNN` sequence starts fresh.

Codes are **independent sequences** — items are not renumbered if they move between epics. Each item carries a reference to its parent epic, but its code is stable.

Items are registered (receive a code) at **epic decomposition time**, before work begins. This means backlog items are trackable on the dashboard immediately. When an epic is decomposed into N items, all N receive codes and registry entries at once, even though no artifact files or folders exist yet.

A **registry file** (`.project/registry.json`) serves as the source of truth for **structural data**:
- Code-to-item mapping
- Epic-to-items mapping
- Item stage (backlog, active, completed)
- Current folder path

### 2. Standardized YAML Frontmatter

All spec.md, design.md, and plan.md files use a `---` delimited YAML block as their first content. The schema includes (at minimum):

- `id` — Work item code (e.g., `WI-015`)
- `title` — Human-readable name
- `type` — `spec`, `design`, or `plan`
- `status` — `draft`, `in-progress`, `complete`
- `epic` — Parent epic code (e.g., `EP-002`) or `null`
- `owner` — Author
- `created` — ISO 8601 timestamp
- `updated` — ISO 8601 timestamp

Plan files additionally include:
- `phases_total` — Number of implementation phases
- `phases_complete` — Number of completed phases

The exact schema will be refined during the spec phase. The key constraint is: **scripts must be able to parse and update this frontmatter reliably.**

**Source of truth boundaries:** The registry owns structural data (code assignments, epic membership, stage, folder path). Frontmatter owns per-artifact status (draft/in-progress/complete) and content metadata. If they disagree, a reconciliation script rebuilds the registry from the filesystem and frontmatter.

### 3. Work Item Registry

A central JSON file (`.project/registry.json`) provides a fast, parseable index of all items:

```
{
  "epics": {
    "EP-001": { "title": "...", "status": "completed" },
    ...
  },
  "items": {
    "WI-001": { "title": "...", "epic": "EP-001", "stage": "completed", "path": "..." },
    ...
  },
  "next_epic_id": 4,
  "next_item_id": 16
}
```

This is the dashboard's primary data source. Scripts update it atomically whenever items are created, moved, or have their status changed.

### 4. Deterministic Lifecycle Scripts

Three scripts handle the core operations that agents currently do manually:

**Create work item** — Given a title and optional epic code:
- Assigns the next available `WI-NNN` code
- Creates the folder in `.project/active/`
- Generates a skeleton file (e.g., spec.md) with correct YAML frontmatter
- Registers the item in the registry
- Outputs the assigned code

**Move/archive item** — Given an item code and target stage:
- Moves the folder (e.g., active → completed with date prefix)
- Updates the registry's stage and path
- Updates CHANGELOG.md with a completion entry
- Updates epic completion status if all items are done

**Update status** — Given an item code, artifact type, and new status:
- Updates the YAML frontmatter in the specified file
- Updates the registry if the change is stage-relevant
- For plan files: can update `phases_complete` count

Scripts are the **intended** way agents modify metadata and move items. Since agents are LLMs, direct edits may occasionally happen. The reconciliation script (US-12) provides a safety net for drift.

### 5. Visual Dashboard

An HTML file (`.project/dashboard.html`) generated by a script that reads the registry and artifact frontmatter.

**Layout:**
- Kanban board with three columns: **Backlog | Active | Completed**
- Items grouped under epic headers within each column
- Ungrouped items appear in a separate section

**Item cards show:**
- Work item code (click-to-copy)
- Title
- For active items in definition: which artifacts exist (spec, design, plan) as indicator badges
- For active items in implementation: phase progress (e.g., "3 / 5" with a progress bar)
- For completed items: completion date

**Epic headers show:**
- Epic code and title
- Aggregate progress (e.g., "4 of 6 items complete")

**Freshness mechanism:**
- A file-watcher script monitors `.project/` for changes
- On change, it regenerates `dashboard.html`
- VSCode Live Preview extension auto-refreshes when the file changes
- The dashboard includes a "last generated" timestamp for confidence

**Interactivity:**
- Click-to-copy on item codes
- Tooltips on item cards showing additional metadata (owner, dates, status details)
- Minimal JS — the goal is a lightweight, fast-rendering page

---

## Scope of Behavior Changes

### New artifacts to create
- `.project/registry.json` — Central item/epic registry
- `.project/dashboard.html` — Generated dashboard file
- Lifecycle scripts (create item, move item, update status, reconcile registry)
- Dashboard generation script + file watcher script
- YAML frontmatter schema definition (location TBD)

### Existing artifacts to modify
- **`_my_spec` command** — Instruct agent to use create-item script instead of manual `mkdir` + header writing
- **`_my_design` command** — Instruct agent to use update-status script when changing design status
- **`_my_plan` command** — Instruct agent to use update-status script; ensure phase counts are set in frontmatter
- **`_my_implement` command** — Instruct agent to use update-status script when completing phases and items
- **`_my_project_manage` command** — Instruct agent to use move-item and update-status scripts for close/archive operations
- **`.claude/settings.local.json`** — Add permissions for new scripts

### Behavior changes by workflow stage
- **Epic decomposition**: Items are registered in the registry at decomposition time (receive codes, appear in backlog)
- **Starting work**: `/_my_spec` calls create-item script; folder and skeleton are set up automatically
- **During definition**: `/_my_design` and `/_my_plan` use update-status to mark artifact completion
- **During implementation**: `/_my_implement` uses update-status to increment `phases_complete`
- **Closing items**: `/_my_project_manage close` calls move-item script instead of manual `mv` + edits
- **Viewing status**: User opens dashboard.html in VSCode for visual project overview

---

## Out of Scope

- **VSCode extension** — Future evolution. v1 uses generated HTML + Live Preview.
- **Epic creation/management scripts** — Epic management remains a manual/agent-driven process. Scripts handle items only.
- **Automated backlog prioritization** — Dashboard displays priority but doesn't manage it.
- **Cross-project dashboards** — Dashboard covers a single `.project/` directory.
- **Notification system** — No alerts or Slack integration.
- **Historical metrics / burndown charts** — Future consideration. v1 shows current state only.
- **Migration of existing items** — No migration. Items/epics created before this system are not tracked. The registry and dashboard start fresh with only newly-created items.
- **Concurrent agent access** — v1 assumes single-agent operation. Concurrent modification of `registry.json` by multiple agents is not handled.
- **CURRENT_WORK.md / session boot changes** — `CURRENT_WORK.md`, `/_my_wrap_up`, and the session boot sequence are a separate workflow concern and are not modified by this effort.

---

## Assumptions & Prerequisites

- **Environment:** VSCode with Remote SSH support. Live Preview extension installed. Unix-like OS (Linux/macOS). Python 3 available for YAML/JSON parsing.
- **Performance target:** Dashboard generation should complete in under 1 second for projects with up to 100 items.
- **Single-agent operation:** Only one agent modifies `.project/` at a time. No locking or conflict resolution needed for v1.

## Open Questions

1. **Script language** — Bash or Python? The project uses both (`get-metadata.sh` is bash; `parse-transcript.py` and `query-transcript.py` are Python). YAML parsing is far simpler in Python. Likely Python for scripts that parse/write YAML+JSON, bash for the file watcher.
2. **Backlog item detail** — When an item is registered at decomposition but hasn't started, what metadata exists? Minimum: code, title, epic, stage=backlog. No folder or artifact files yet. Exact fields to be defined during spec.

---

## Decomposition Guidance

This concept spans several distinct capability areas that should be implemented as separate work items:

1. **YAML frontmatter schema** — Define the standardized schema for spec, design, and plan files
2. **Registry system + code assignment** — Create registry.json, implement code generation, build reconciliation script
3. **Lifecycle scripts** — Create item, move item, update status scripts
4. **Dashboard generation** — HTML generator + file watcher
5. **Command updates** — Modify agentic commands to use scripts
6. **Integration testing** — End-to-end validation of the full workflow

Items 1-2 are foundational (everything else depends on them). Item 3 depends on 1-2. Item 4 depends on 1-3. Item 5 can partially parallel item 4.
