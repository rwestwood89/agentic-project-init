# Spec: `/_my_close` Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** MEDIUM
**Branch:** workflow-v2

---

## Problem

The workflow has no archive step. When a work item or epic is done, its artifacts sit in `active/` and `backlog/` indefinitely. There is no command that moves completed work to `completed/`, updates tracking files, or records what shipped. The close mode inside `_my_project_manage` exists but is buried behind a mode flag, handles only items (not epics), and will be retired when `_my_project_manage` is decomposed.

The result: `active/` accumulates finished work, CURRENT_WORK.md drifts, CHANGELOG.md is never written, and an autonomous agent has no way to close the loop on a work item without manual file juggling.

## Success Criteria

- [ ] `/_my_close {item}` archives a work item from `active/` to `completed/` and updates CURRENT_WORK.md and CHANGELOG.md
- [ ] `/_my_close {epic}` archives an epic and all its unarchived child items, updating BACKLOG.md, CURRENT_WORK.md, and CHANGELOG.md
- [ ] User is prompted for confirmation before any archiving happens
- [ ] The command warns (but does not refuse) when an item lacks audit certification or has a "Needs Work" verdict

## Known Requirements

### Input and invocation

- **[HARD]** Takes exactly one argument: an item name (folder in `active/`) or an epic name (file in `backlog/`). No mode flags.
- **[HARD]** Requires user confirmation before archiving. The confirmation prompt must show what will be moved and what tracking files will be updated.
- **[NEED]** When invoked with no argument, the command should ask what to close rather than guessing.

### Work-item scope

- **[HARD]** Moves `active/{item}/` to `completed/{YYYYMMDD}_{item}/` using `git mv` to preserve history.
- **[HARD]** Updates CURRENT_WORK.md: removes the item from Active Work and adds it to Recently Completed with a date and brief summary.
- **[HARD]** Adds an entry to `completed/CHANGELOG.md` using the established format (Type, Duration, Summary, Deliverables, Lessons Learned). The command should auto-populate from spec and plan artifacts where possible, and fill what it can't derive with placeholders for the user.
- **[NEED]** If the item belongs to an epic, updates the epic's backlog item status (marks checkboxes, appends ✅ to the item heading if all success criteria pass).
- **[INFERRED]** After updating the parent epic, checks whether all epic items are now complete and suggests `/_my_close {epic}` if so.

### Epic scope

- **[HARD]** Archives all child items still in `active/` to `completed/{YYYYMMDD}_{item}/`. Skips items already in `completed/` (previously closed individually).
- **[HARD]** Archives the epic file: `backlog/epic_{name}.md` → `completed/{YYYYMMDD}_epic_{name}.md`.
- **[HARD]** Updates BACKLOG.md: marks the epic as complete with strikethrough, ✅, status "Complete ({date})", and an archive reference.
- **[HARD]** Updates CURRENT_WORK.md: removes any remaining child items from Active Work, adds a single Recently Completed entry for the epic.
- **[HARD]** Adds a single CHANGELOG.md entry for the epic (not one per child item — the epic entry summarizes the whole body of work).

### Certification awareness

- **[NEED]** Before presenting the confirmation prompt, reads the audit artifact (`active/{item}/audit.md`) if it exists. If no audit exists or the verdict is "Needs Work," includes a visible warning in the confirmation summary. Does not block archiving.
- **[INFERRED]** For epic scope, flags any child items that lack certification in the confirmation summary.

## Non-Goals

- Evaluating or certifying code. That is `/_my_audit`.
- Session context persistence. That is `/_my_wrap_up`.
- Reviewing what is closeable or assessing project status. That is `/_my_status`.
- Handling undo/restore of archived items.

## Open Questions / Deferred to design

- **Confirmation UX.** The command must confirm before archiving, but the mechanism (prose summary with a yes/no prompt, or a structured preview) is a design decision.
- **CHANGELOG auto-population depth.** The spec requires auto-populating from spec/plan/audit, but exactly which fields to extract and how to summarize is a design decision. The Lessons Learned section may always need a placeholder.
- **Commit behavior.** Should close auto-commit the archive changes, or leave them staged for the user? The existing `_my_project_manage` uses `git mv` but doesn't auto-commit. Defer to design.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_workflow_v2.md` (Item 5)
- **README_v2 artifact:** `https://claude.ai/code/artifact/9a7e2b06-4412-4e44-9c84-b3fc17b7544a` (Section 5: Completion Flow, Section 7: Lifecycle Rules)
- **Existing close behavior:** `claude-pack/commands/_my_project_manage.md` (lines 304-416, close mode being absorbed)
- **Tracking file templates:** `project-pack/CURRENT_WORK.md`, `project-pack/completed/CHANGELOG.md`, `project-pack/backlog/BACKLOG.md`
- **Design:** `.project/active/close-command/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
