# Design: `/_my_epic_plan` Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** MEDIUM
**Epic:** WORKFLOW-V2, Item 2

---

## Overview

Design the command prompt for `/_my_epic_plan` — the bridge command that takes shaping-tier files and produces a scoped epic with Source Documents and Required Reading. The main design tension is keeping the prompt tight while the job is substantial. The lever is delegation: the EPIC_GUIDE already carries the decomposition methodology, so the command defines the process and references the guide for the method.

## Related Artifacts

- **Spec:** `.project/active/epic-plan-command/spec.md`
- **Epic:** `.project/backlog/epic_workflow_v2.md`, Item 2
- **Decomposition methodology:** `project-pack/EPIC_GUIDE.md` (the guide this command references)
- **Epic template:** `project-pack/epic_template.md` (the template the output must follow)
- **Absorbed from:** `_my_project_manage.md`, decompose mode (lines 139-300)

---

## Core Concept

The command prompt has one structural insight: it separates the _process_ (what steps to follow, what checkpoints to hit) from the _methodology_ (how to decompose well). The process lives in the command. The methodology lives in the EPIC_GUIDE.

This is the same pattern as `/_my_plan`, which defines the phasing process but references `design.md` for architecture details rather than restating them. Here, `/_my_epic_plan` defines the three-stage process with two user checkpoints, but references `EPIC_GUIDE.md` for sizing rules, scope checks, and decomposition quality standards.

The result is a prompt that's ~80-100 lines — enough to be specific about the process, short enough that the agent reads it in one pass without losing the thread.

---

## Key Bets

- **B1. The EPIC_GUIDE is sufficient methodology.** The guide already covers sizing (Goldilocks principle), scope checks, independence checks, decomposition anti-patterns, and the item template. If the guide is incomplete, the command will produce bad decompositions no matter how much methodology it restates. *If false → the guide needs improving, not the command.*

- **B2. Two checkpoints are the right number.** Scope first, decomposition second. Fewer and the user loses control. More and the command becomes tedious for small epics. *If false → the process is either too rigid or too loose for the typical epic.*

---

## Key Decisions

- **D1. The command does not include the epic template inline.** It instructs the agent to copy `epic_template.md` and fill it in. The template is the source of truth for structure. *Rejected: embedding the template in the command (duplicates content, drifts over time).*

- **D2. The command does not include the EPIC_GUIDE's item template or quality checks.** It tells the agent to read and follow `EPIC_GUIDE.md`. *Rejected: restating the methodology in the command (the old decompose mode did this — 160 lines of checks and templates that duplicated the guide).*

- **D3. Epic name is derived from the primary concept name, confirmed with the user at the scope checkpoint.** The agent proposes a name; the user can adjust. *Rejected: always asking the user upfront (adds a step before the agent has context to suggest a good name); always auto-deriving (user may want a different name).*

- **D4. Source Documents are populated during Stage 1 (scope), not after decomposition.** The agent knows all the input files from the start. Listing them early anchors the epic's provenance before the user reviews scope. *Rejected: populating Source Documents after decomposition (delays provenance record, user can't verify inputs during scope review).*

- **D5. Required Reading is assigned during Stage 3 (write items), not proposed in the decomposition checkpoint.** At the decomposition checkpoint, the user is validating item boundaries and sizing. Required Reading is a detail that the agent works out when writing the full items — it requires thinking about which source documents are relevant to which items. *Rejected: including Required Reading in the decomposition proposal (overloads the checkpoint with detail the user can't usefully evaluate at that stage).*

---

## Architecture

The command prompt has four parts:

1. **Header** — Purpose line, input/output, one-line instruction to read EPIC_GUIDE.
2. **Stage 1: Scope** — Read inputs, copy template, fill in Executive Summary / Source Documents / Why This Epic / Success Criteria. Present to user. Wait for approval.
3. **Stage 2: Decompose** — Propose item breakdown in-console (table or list: name, type, effort, one-line purpose). Wait for approval.
4. **Stage 3: Write Items** — Think through dependencies, Required Reading assignments, and item details using EPIC_GUIDE methodology. Write full items into the epic. Update BACKLOG.md.

No guidelines section, no anti-patterns, no quality checklists — the EPIC_GUIDE carries all of that. The command is process, not pedagogy.

---

## Required Invariants

- The command references `EPIC_GUIDE.md` for decomposition methodology — it never restates sizing rules, scope checks, or the item template.
- The epic template file (`epic_template.md`) is the source of truth for output structure — the command never embeds a copy.
- Two user checkpoints, both requiring explicit approval before proceeding.
- Source Documents is populated from the input files the agent actually read, not fabricated.
- Required Reading per item is a deliberate assignment (which source docs matter for this item), not a blanket copy of all Source Documents.

---

## Component Overview

### The prompt file

`claude-pack/commands/_my_epic_plan.md` — a single markdown file, targeting ~80-100 lines.

Sections:
- **Purpose/Input/Output** header (3-4 lines)
- **Context loading** instruction: read EPIC_GUIDE.md, read input files, read BACKLOG.md (3-5 lines)
- **Stage 1: Scope** (15-20 lines) — read inputs, copy template, fill scope sections, present to user
- **Stage 2: Decompose** (10-15 lines) — propose breakdown in-console, get approval
- **Stage 3: Write Items** (15-20 lines) — work through details, write into epic, update BACKLOG.md
- **Input handling** (5-10 lines) — how to find/accept shaping-tier files

### Codex config entry

One line in `codex-overrides/config.sh` `COMMAND_SKILL_DESCRIPTIONS`:
```
["epic-plan"]="Decompose shaping output into a scoped epic with backlog items. Use when concepts or research are ready to become an implementation plan."
```

---

## Non-Goals

- Rewriting or expanding the EPIC_GUIDE (if it's missing something, that's a separate fix)
- Adding a "decompose existing epic" mode
- Handling multi-epic decomposition (one concept → multiple epics)

---

## Implementation Notes

- The in-console decomposition proposal (Stage 2) should follow the pattern from `/_my_plan` Step 2: a structured but conversational presentation, not a template dump. A table works well: `| # | Item | Type | Effort | Purpose |`.
- The Stage 3 instruction should explicitly tell the agent to think through Required Reading assignments — which source documents are relevant to each specific item. This is the part that requires careful judgment, not just template-filling.
- The `$ARGUMENTS` pattern should accept: a concept file path, a concept name (agent searches `.project/concepts/`), or nothing (agent scans and asks).

---

## Validation Approach

- The command prompt should be readable in one pass — a human should be able to skim it and understand the full process in under a minute.
- Test by invoking `/_my_epic_plan` with a real concept and verifying: the scope checkpoint fires before decomposition, the decomposition checkpoint fires before writing items, the output epic has populated Source Documents and Required Reading.
- Compare the output epic against the `epic_workflow_v2.md` format for structural consistency.

---

## Next-Stage Handoff

**Fixed:** Three-stage process with two checkpoints. Delegation to EPIC_GUIDE for methodology. No template duplication. Epic name derived and confirmed at scope checkpoint. Required Reading assigned at write time, not at decomposition proposal.

**Open:** Exact wording of each stage's instructions — use the architecture above as the skeleton, refine during implementation.

**Risk:** The prompt might be too terse for the agent to produce quality decompositions. If so, the fix is improving the EPIC_GUIDE, not bloating the command.

---

Next Step: After approval → implement directly (write the command file and add the Codex config entry).
