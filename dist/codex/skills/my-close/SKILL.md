---
name: my-close
description: Archive a completed work item or epic to completed/ and update tracking files (CURRENT_WORK.md, CHANGELOG.md, BACKLOG.md). Use when work is done and ready to be moved out of active development.
---

Generated from `claude-pack/commands/_my_close.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Close Command

**Purpose:** Archive a completed work item or epic to `completed/` and update all tracking files
**Input:** Item name (folder in `active/`) or epic name (file in `backlog/`) via `User-provided arguments are supplied when this skill is invoked.`
**Output:** Archived artifacts in `completed/`, updated CURRENT_WORK.md, CHANGELOG.md, and (for epics) BACKLOG.md

## Overview

You are an archive utility. Your job is to move completed work out of `active/` and `backlog/`, update the project's tracking files, record what shipped, and file the decisions that emerged during implementation before their context is archived. You do not evaluate or certify — that is ``my-audit``. You archive and update the books.

When invoked:
- If `User-provided arguments are supplied when this skill is invoked.` names an item or epic, resolve the scope and start.
- If no argument, ask what to close.

## Step 1: Resolve Scope

Determine whether the argument is a work item or an epic:
- If `.project/active/{arg}/` exists → **item scope**.
- If `.project/backlog/epic_{arg}.md` exists → **epic scope**. Try both `epic_{arg}.md` and `{arg}.md` if the user included the prefix.
- If both match → ask the user which scope they mean.
- If neither → report what you checked and ask for a valid name.

## Step 2: Gather State

**Item scope:**
1. Read `spec.md`, `plan.md`, and `audit.md` from `active/{item}/` (skip any that don't exist).
2. Check audit status: look for the `**Verdict:**` field in `audit.md`. Note whether it says "Certify," "Needs Work," or is absent.
3. Find the parent epic: check the spec's Related Artifacts section for an epic reference. If not found, grep `.project/backlog/epic_*.md` for the item name. If no parent epic, note it as standalone.
4. **Scan for emergent decisions**: read `plan.md` deviation/implementation notes and `audit.md` findings for decisions made *during* implementation — discovered constraints, deviations from the design, workarounds against another component or repo's behavior. Apply the density bar in `.project/adr/README.md` (would a future agent re-derive the wrong thing or relitigate without a record?). Most items yield none.

**Epic scope:**
1. Read the epic file. Extract child items from the Backlog Items section — use each item's `**Location**:` field to get the folder name.
2. For each child item, check whether it is in `active/` (needs archiving) or already in `completed/` (skip).
3. For each active child, read `audit.md` and note certification status.

## Step 3: Confirm

Present a summary to the user. Include:

- What will be archived (source → destination paths).
- What tracking files will be updated.
- **Decisions to record** — the candidate decision-record entries from the emergent-decision scan, or "none found." For a workaround against another repo's behavior, note the placement: the ruling entry files in the repo that must uphold it, plus a local pointer entry (see `.project/adr/README.md`); if that repo is unreachable, file the pointer and surface the gap.
- **Certification warnings** — if any item has no audit or a "Needs Work" verdict, flag it visibly. Example: `⚠️ {item} has no audit certification.`
- For epic scope: a list of child items showing which will be archived and which are already in `completed/`.

**Wait for user confirmation. Do not proceed without it.**

## Step 4: Execute

After confirmation, execute in this order:

### 4a. Read data for CHANGELOG

Before moving anything, read the data you need for the CHANGELOG entry from the item's artifacts (spec Problem section, spec Created date, list of artifacts present). Once `git mv` runs, the source paths are gone.

### 4b. File decision records

For each approved candidate from the confirm step: `.project/scripts/adr.sh new <slug>`,
fill in the body, set provenance and seams. Do this **before** archiving, while the source
artifacts still exist at their `active/` paths. If the script is missing (repo not
re-initialized), note the gap; don't hand-mint ids.

### 4c. Archive

Use `git mv` for all moves:
- **Item scope:** `git mv .project/active/{item} .project/completed/$(date +%Y%m%d)_{item}`
- **Epic scope:** For each active child item, `git mv` to `completed/`. Then `git mv .project/backlog/epic_{name}.md .project/completed/$(date +%Y%m%d)_epic_{name}.md`.

### 4d. Update tracking files

**CURRENT_WORK.md:**
- Remove the item (or child items) from the Active Work section.
- Add a concise entry to Recently Completed. Format: `### YYYY-MM-DD: {Item Name}` with 2-3 bullet points summarizing what was accomplished. For epic scope, add one entry for the epic, not one per child.

**CHANGELOG.md** (`completed/CHANGELOG.md`):
- Add an entry using the established format. Auto-populate:
  - **Type**: "Item" or "Epic"
  - **Duration**: computed from the spec's `Created` date to today
  - **Summary**: the first 2-3 sentences of the spec's Problem section, reframed as what was accomplished
  - **Deliverables**: list the artifacts that exist in the item folder (spec.md, design.md, plan.md, audit.md, plus code deliverables from the spec)
  - **Lessons Learned**: `[TODO: Add lessons learned]`
- For epic scope, write one entry summarizing the entire epic, not per-child entries.

**Parent epic** (item scope only):
- If the item belongs to an epic, mark the item's success/done-state checkboxes `- [x]` in the epic file. If all success criteria pass, append ✅ to the item heading.
- Check if all epic items are now complete. If so, suggest: "All items in {epic} are now complete. Run ``my-close` {epic}` to archive the epic."

**BACKLOG.md** (epic scope only):
- Update the epic's entry: strikethrough the heading, add ✅, change status to `Complete (YYYY-MM-DD)`, add `Archived to: .project/completed/{path}`.

### 4e. Report

Show the user what was done: what was archived, what files were updated, and any next steps (e.g., suggesting epic close if all items are done).

Do not auto-commit. Leave all changes staged.

---

**Related Commands:**
- Before close: ``my-audit`` to certify, ``my-pre-pr`` for quality checks
- After close (epic items done): ``my-close` {epic}` to archive the epic
- Session context: ``my-wrap-up`` to persist session state

**Last Updated**: 2026-07-19 — added the emergent-decision scan and decision-record filing (W2) before archive.

User-provided arguments are supplied when this skill is invoked.

