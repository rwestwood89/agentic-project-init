# Spec: `/_my_status` Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** LOW
**Branch:** workflow-v2

---

## Problem

Project orientation is buried inside `_my_project_manage`, a multi-mode command that requires remembering flags. With decompose, close, and backlog management split to their own commands (`/_my_epic_plan`, `/_my_close`), the remaining job — reading project state, assessing health, and recommending next steps — should be a standalone command with no flags.

The backlog mode's orientation function (what's prioritized, what's stale) also belongs here, not in a separate command. An agent or user starting a session needs one place to ask "where are we and what should I do next?"

## Success Criteria

- [ ] `/_my_status` produces a status report covering active work, backlog priorities, and gaps
- [ ] Includes backlog orientation: what's prioritized, what's stale, what's next
- [ ] No mode flags required — single invocation, one output

## Known Requirements

### What it reads

- **[HARD]** `.project/CURRENT_WORK.md` — active items, recent completions, blockers.
- **[HARD]** `.project/backlog/BACKLOG.md` — epic priorities and status.
- **[HARD]** `.project/backlog/epic_*.md` — individual epic files for item-level status.
- **[NEED]** `.project/active/*/spec.md` and `active/*/plan.md` — to assess progress on active items (which phase, how far along).
- **[NEED]** `.project/completed/CHANGELOG.md` — recent completions for context.

### What it produces

- **[NEED]** A status report saved to `.project/reports/{YYYY-MM-DD-HHMM}-status-report.md`. The report covers: current active work with progress, backlog priorities with staleness assessment, gaps and inconsistencies, and recommended next steps.
- **[NEED]** A concise conversational summary presented to the user. The full report is the artifact; the conversation gets the highlights.

### Analysis

- **[NEED]** Identifies gaps: stale dates in CURRENT_WORK.md, items claimed active that have no recent progress, epics with all items done but not closed, inconsistencies between tracking files.
- **[NEED]** Assesses backlog health: are priorities current, are any epics stale (no activity, no items started), is the backlog well-ordered?
- **[NEED]** Recommends next steps: what to work on next based on priority and dependency, what to close, what to review.

## Non-Goals

- Decomposing epics. That is `/_my_epic_plan`.
- Archiving completed work. That is `/_my_close`.
- Managing or editing the backlog (reprioritizing, adding epics). Status reads and analyzes — it doesn't write to BACKLOG.md.
- Quick context lookup for a single item or epic. That is `/_my_project_find`.

### Depth and output

- **[NEED]** Default invocation (no arguments) should be light: a concise summary that highlights what matters most. The agent decides what's important — gaps, stale items, observed risks — and leads with that. If nothing is noteworthy, a simple summarization table is enough.
- **[NEED]** The user may request a deeper inspection (e.g., `/_my_status deep`, or "give me a thorough status"). The command should scale up its analysis and report depth accordingly.
- **[NEED]** No fixed conversational output structure. The agent adapts to what it finds — it's an assessment, not a form to fill.
- **[NEED]** The persistent report (`.project/reports/`) should also be concise by default. A proportional report, not a padded one.

## Open Questions / Deferred to design

- **Mechanism for requesting depth.** The user can ask for a deeper inspection, but the exact trigger (an argument like `deep`, or just natural language) is a design decision.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_workflow_v2.md` (Item 7)
- **Command being replaced:** `claude-pack/commands/_my_project_manage.md` (status mode: lines 23-135, backlog mode: lines 419-455)
- **Boundary reference:** `claude-pack/commands/_my_project_find.md` (quick lookup, not analysis)
- **Design:** `.project/active/status-command/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
