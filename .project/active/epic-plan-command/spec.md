# Spec: `/_my_epic_plan` Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** MEDIUM
**Epic:** WORKFLOW-V2, Item 2

---

## Problem

Shaping produces concepts, concept-designs, and research files. Scoping works on backlog items. There is no command that bridges the two — someone has to manually create an epic, copy the template, decompose the work, link back to the source files, and populate Required Reading per item.

The old `/_my_project_manage decompose` mode partially covered this, but it assumed the epic already existed. It didn't handle Source Documents, Required Reading, or creating the epic from shaping-tier input. And it was buried behind a mode flag in an overloaded command.

`/_my_epic_plan` replaces this with a standalone command that takes shaping output as input and produces a complete epic — with Source Documents tracing provenance and Required Reading distributing context to each item's pipeline.

## Success Criteria

- [x] Command exists at `claude-pack/commands/_my_epic_plan.md` and can be invoked as `/_my_epic_plan`
- [x] Accepts shaping-tier files as input (concept, concept-design, research) via arguments or interactive discovery
- [x] Produces a complete epic file at `.project/backlog/epic_{name}.md` using the updated template, including populated Source Documents and Required Reading per item
- [x] Updates `.project/backlog/BACKLOG.md` with a new entry for the epic
- [x] Follows the EPIC_GUIDE decomposition methodology for sizing and scoping backlog items
- [x] Codex skill description added to `codex-overrides/config.sh`

## Known Requirements

- **[HARD]** The output epic must use the updated template format with Source Documents and Required Reading sections (from Item 1).
- **[HARD]** Source Documents in the output must list every shaping-tier file the command read as input, with type annotations (concept, concept-design, research).
- **[HARD]** Required Reading per item must list the specific subset of source documents relevant to that item. Different items may reference different subsets.
- **[HARD]** The process has two user checkpoints, both requiring approval before proceeding:
  1. **Scope checkpoint:** After filling in Executive Summary, Source Documents, Why This Epic, and Success Criteria — present to user for confirmation before decomposing.
  2. **Decomposition checkpoint:** After proposing the item breakdown in-console (names, types, effort, one-line purposes — similar to how `/_my_plan` proposes high-level phases) — get approval before writing items into the epic.
- **[HARD]** After both checkpoints pass, the command thinks through dependencies, Required Reading assignments, and item details carefully, then writes the full backlog items into the epic file.
- **[NEED]** The command prompt must stay tight. The EPIC_GUIDE already carries the decomposition methodology, sizing rules, and quality checks. The command references `EPIC_GUIDE.md` for those — it does not restate them.
- **[NEED]** The command must handle the case where shaping-tier files don't exist in the expected locations. It should ask the user to identify or provide them rather than failing silently.
- **[INFERRED]** The command accepts arguments in flexible form — a concept name, file paths, or a description. If input is ambiguous or missing, it scans `.project/concepts/` and `.project/research/` and asks the user to identify the relevant files.
- **[INFERRED]** The BACKLOG.md entry format follows the existing pattern (priority, status, estimate, category, brief description, items list with checkboxes).

## Non-Goals

- Modifying existing epics (this creates new ones)
- Backlog reprioritization
- Changing the EPIC_GUIDE decomposition methodology
- Writing specs, designs, or plans for individual items (those happen downstream)
- Modifying downstream commands to read Required Reading (that's Item 3)

## Open Questions / Deferred to design

- ~~Whether the command should also support a "decompose an existing epic" mode~~ **Resolved:** No. This command only creates new epics from shaping output. Decomposing an existing epic is not in scope.
- How the command determines the epic name for the output file. Options: derive from the concept name, ask the user, or both. Defer to design.

---

## Related Artifacts

- **Source (target state):** README_v2 artifact — Section 2 (Bridge), Section 3 (Traceability), Section 10 (Changes)
- **Epic:** `.project/backlog/epic_workflow_v2.md`, Item 2
- **Absorbed from:** `_my_project_manage.md`, decompose mode (lines 139-300)
- **Depends on:** Item 1 (epic template with Source Documents and Required Reading)
- **Input format reference:** `_my_concept.md`, `_my_concept_design.md` output templates
- **Decomposition methodology:** `project-pack/EPIC_GUIDE.md`
- **Design:** `.project/active/epic-plan-command/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
