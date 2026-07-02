# Design: `/_my_close` Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Branch:** workflow-v2
**Commit:** af02018

---

## Overview

A single-purpose archive command that moves completed work items or epics from `active/` and `backlog/` to `completed/`, updates the three tracking files (CURRENT_WORK.md, CHANGELOG.md, BACKLOG.md), and warns about missing audit certification.

## Related Artifacts

- **Spec:** `.project/active/close-command/spec.md`
- **Epic:** `.project/backlog/epic_workflow_v2.md` (Item 5)
- **README_v2:** `https://claude.ai/code/artifact/9a7e2b06-4412-4e44-9c84-b3fc17b7544a` (Sections 5, 7)
- **Existing close mode:** `claude-pack/commands/_my_project_manage.md:304-416`
- **Audit command (pattern reference):** `claude-pack/commands/_my_audit.md`
- **Epic plan command (pattern reference):** `claude-pack/commands/_my_epic_plan.md`

## Research Findings

### Existing close mode (`_my_project_manage.md:304-416`)

The current close mode has two paths: no-argument (scan all active items, present a status table, ask which to close) and with-argument (verify completion, confirm, archive one item). It uses `git mv` for archiving, updates three files (CURRENT_WORK.md, parent epic, CHANGELOG.md), and checks whether the parent epic is fully complete afterward.

What to preserve: `git mv` for history, the confirmation-before-action pattern, the parent-epic completion check. What to drop: the no-argument scan-all-items mode (that's `/_my_status`'s job now), the status table UI with lettered options.

### Command prompt style

Recent commands (`_my_epic_plan.md` at ~56 lines, `_my_audit.md` at ~161 lines) share a pattern: purpose/input/output header, brief overview, then numbered process steps. No verbose templates — the agent is trusted to compose prose. The epic_plan command is the closest analogue in complexity: read input, present a summary, wait for confirmation, execute, update tracking files, report.

### Tracking file formats

- **CURRENT_WORK.md**: Active Work section has items as `### [Name]` blocks. Recently Completed section has `### [DATE]: [Item Name]` with bullet summaries. The close command removes from one and adds to the other.
- **BACKLOG.md**: Completed epics use strikethrough heading, ✅, status line like `Simplified & Completed (2025-12-30)`, and `Archived to: .project/completed/{path}` (`BACKLOG.md:103-111`).
- **CHANGELOG.md**: Entries use `## [YYYY-MM-DD] - [Name]` heading, then Type, Duration, Summary, Deliverables, Lessons Learned subsections (`completed/CHANGELOG.md:1-45`).

### Audit artifact format

The audit command writes `audit.md` with a `**Verdict:** Certify | Needs Work` field in the header (`_my_audit.md:72-75`). The close command reads this field to determine certification status.

## Core Concept

The close command is a bookkeeping step. It does not evaluate anything — it trusts the upstream pipeline (audit) for that. Its job is three operations in sequence: gather state, confirm with the user, then execute.

"Gather state" means reading the item's artifacts (spec, plan, audit) to build a summary, and checking audit status to surface warnings. "Confirm" means presenting what will happen — what moves where, what gets updated, any certification gaps — and waiting for a yes. "Execute" means `git mv` for the archive, then edits to the three tracking files.

The command handles two scopes (item and epic) but the logic is the same shape in both. The epic scope just loops over child items before archiving the epic file itself.

The command prompt should be short — closer to `_my_epic_plan` (~60 lines) than `_my_audit` (~160 lines). The agent doesn't need lengthy templates for confirmation prose or CHANGELOG entries; it can compose those from the artifacts it reads and the established formats in the existing files.

## Key Bets

- **B1.** The agent can reliably edit CURRENT_WORK.md and BACKLOG.md by reading them and making targeted edits. *If false → tracking files drift or get corrupted.* This is the same bet every other pipeline command makes (spec, implement, audit all edit CURRENT_WORK.md), so it's validated by existing usage.

- **B2.** Prose confirmation in the conversation is sufficient for the user to make an informed archive decision. *If false → users archive things they shouldn't, or the confirmation is too noisy to read.* Mitigated by keeping the summary concise and warnings prominent.

## Key Decisions

- **D1. Don't auto-commit.** Leave the `git mv` and file edits staged but uncommitted. *Rejected: auto-committing with a generated message.* The agent running the command is typically mid-session and may want to bundle the close with other work. This matches the existing `_my_project_manage` pattern and every other pipeline command's behavior.

- **D2. Prose confirmation, not structured UI.** Present the confirmation as a short summary in conversation and wait for the user to say yes. *Rejected: the `AskUserQuestion` multiple-choice tool.* The user has expressed a preference against multiple-choice for impactful decisions (auto-memory: `avoid-askuserquestion-complex-decisions`). A prose summary lets the user see the full picture and respond naturally.

- **D3. No no-argument scan mode.** When invoked without an argument, ask what to close. Don't scan all active items. *Rejected: the scan-and-recommend pattern from `_my_project_manage`.* That's `/_my_status`'s job now. Close takes a target and archives it.

- **D4. CHANGELOG auto-population with explicit placeholders.** Pull what we can from artifacts; mark what we can't with `[TODO: ...]`. *Rejected: leaving CHANGELOG entries fully empty for the user to fill.* The artifacts contain enough to produce a useful first draft. Specifically:
  - **Type**: "Item" or "Epic" — derived from scope.
  - **Duration**: computed from spec's `Created` date to today.
  - **Summary**: pulled from the spec's Problem section (first 2-3 sentences).
  - **Deliverables**: listed from the artifacts that exist in the item folder (spec.md, design.md, plan.md, audit.md, plus any code deliverables mentioned in the spec).
  - **Lessons Learned**: always a placeholder `[TODO: Add lessons learned]`. Too subjective to auto-generate.

## Architecture

The command is a markdown prompt file at `claude-pack/commands/_my_close.md`. No scripts, no subagents. The agent reads it and follows the steps.

### Data flow

```
Input: item or epic name (from $ARGUMENTS)
  │
  ├─ Resolve scope
  │   ├─ Check .project/active/{arg}/ exists → item scope
  │   ├─ Check .project/backlog/epic_{arg}.md exists → epic scope
  │   └─ Neither → error, ask user
  │
  ├─ Gather state
  │   ├─ Item scope: read spec.md, plan.md, audit.md from active/{item}/
  │   │   └─ Find parent epic by scanning backlog/*.md for the item name
  │   └─ Epic scope: read the epic file, identify child items
  │       ├─ For each child: check if in active/ (needs archiving) or completed/ (already done)
  │       └─ For each active child: read audit.md for certification status
  │
  ├─ Build confirmation summary
  │   ├─ What will be moved (paths)
  │   ├─ What tracking files will be updated
  │   ├─ Certification warnings (if any)
  │   └─ For epic scope: list of child items and their status
  │
  ├─ Present and wait for user confirmation
  │
  └─ Execute (after confirmation)
      ├─ git mv for archive operations
      ├─ Edit CURRENT_WORK.md (remove from Active, add to Recently Completed)
      ├─ Edit CHANGELOG.md (add auto-populated entry)
      ├─ [Item scope] Edit parent epic (mark item done, check if epic complete)
      ├─ [Epic scope] Edit BACKLOG.md (mark epic complete)
      └─ Report what was done
```

### Scope detection

The argument could be either an item name or an epic name. The command resolves it by checking the filesystem:

- If `.project/active/{arg}/` exists → item scope.
- If `.project/backlog/epic_{arg}.md` exists → epic scope. The user can pass either `epic_foo` or just `foo`; the command tries both patterns.
- If both exist (unlikely but possible) → ask the user which scope they mean.
- If neither → report the error and ask for a valid name.

### Parent epic discovery (item scope)

When closing an item, the command needs to find the parent epic to update its checkboxes. It does this by grepping the `backlog/` directory for the item name. The spec's Related Artifacts section may also reference the epic directly — check there first as a fast path.

### Child item discovery (epic scope)

When closing an epic, the command reads the epic file's Backlog Items section and extracts item names from the `**Location**:` fields (e.g., `.project/active/close-command/` → item name `close-command`). For each, it checks whether the item is in `active/` (needs archiving) or already in `completed/` (skip).

## Required Invariants

- **No archive without confirmation.** The command must present a summary and receive explicit user approval before any `git mv` or file edit.
- **git mv, not filesystem mv.** All moves go through `git mv` so history is preserved and changes are staged.
- **CHANGELOG entry before git mv.** The CHANGELOG entry reads from artifacts in `active/{item}/`. Writing the entry must happen before moving the folder, or the source data is gone. (Alternatively: read the data first, then move, then write.)
- **Epic scope skips already-archived items.** If a child item was individually closed earlier, it's already in `completed/`. The epic close does not move it again or create a duplicate CHANGELOG entry.

## Component Overview

One file: `claude-pack/commands/_my_close.md`. No supporting scripts, agents, or skills.

The file follows the established command structure: purpose/input/output header, then a concise process the agent follows. Target length: ~80-100 lines — short enough to read in one pass, detailed enough that the agent knows exactly what to do at each step.

## Non-Goals

- **No evaluation or certification.** The command does not assess code quality or spec conformance. It reads audit.md for warnings but does not produce its own verdict.
- **No undo.** Archived items stay archived. `git mv` is reversible through git, but the command doesn't offer a restore mode.
- **No scan/discover mode.** Close takes a specific target. Discovery is `/_my_status`.

## Implementation Notes

- The command prompt references `$ARGUMENTS` for the item/epic name, matching the pattern in `_my_epic_plan.md:56`.
- For CURRENT_WORK.md edits, the agent reads the file, identifies the item's section in Active Work, removes it, and adds a concise entry to Recently Completed. The format matches the existing entries (e.g., `### 2026-06-25: agent-working-voice rule (merged, PR #21)` with bullet points).
- For BACKLOG.md edits on epic close, follow the format at `BACKLOG.md:103-111`: strikethrough heading, ✅, status `Complete (YYYY-MM-DD)`, archive reference.
- CHANGELOG entries follow the format at `completed/CHANGELOG.md:7-45`.
- The Codex skill description should be added to `codex-overrides/config.sh` in the `COMMAND_SKILL_DESCRIPTIONS` array, key `close`.

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent edits CURRENT_WORK.md incorrectly (wrong section, formatting drift) | Low | Same risk every pipeline command takes; established pattern works |
| CHANGELOG auto-population produces unhelpful summaries | Low | Placeholder for Lessons Learned; user can edit before committing |
| Parent epic discovery fails (item name doesn't appear in any epic) | Low | Standalone items simply skip the epic update step |
| Epic close misidentifies child items | Med | Use the `**Location**:` field in the epic, not fuzzy matching |

## Integration Strategy

Close sits at the end of the work-item lifecycle: implement → audit → close. It's invoked by the user or an autonomous agent after audit certifies the work. The audit command already references `/_my_close` in its Related Commands section (`_my_audit.md:158`).

After close, no further pipeline commands run for that item. The item's artifacts are preserved in `completed/` for historical reference.

## Validation Approach

- **Item scope**: Create a test item in `active/`, run `/_my_close` on it, verify the folder moved to `completed/YYYYMMDD_{item}/`, CURRENT_WORK.md updated, CHANGELOG.md entry added.
- **Epic scope**: Test with an epic that has some items already closed and some still active. Verify only active items are moved, the epic file is archived, BACKLOG.md is updated.
- **Certification warning**: Close an item without an audit.md and verify the warning appears in the confirmation summary.
- **Edge case**: Close an item that has no parent epic — verify it skips the epic update gracefully.

## Next-Stage Handoff

**Fixed (don't revisit):**
- Scope detection logic (check filesystem, not a flag)
- Confirmation before action (prose summary, not multiple-choice)
- No auto-commit
- CHANGELOG auto-population strategy (pull from artifacts, placeholder for Lessons Learned)
- Single file output: `claude-pack/commands/_my_close.md`

**Open (resolve during implementation):**
- Exact wording of the certification warning in the confirmation summary
- Whether to read data before `git mv` or read-then-move-then-write (implementation detail)

**Risk to de-risk first:**
- The CURRENT_WORK.md editing pattern — test this early since it's the most fragile file operation (finding and removing a section, adding a new one).

---

Next Step: After approval → `/_my_plan` or `/_my_implement`
