# Spec: Epic Template Foundation

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** LOW
**Epic:** WORKFLOW-V2, Item 1

---

## Problem

Concepts live in `concepts/` and research lives in `research/`, but neither has a formal link to the epics built from them. When the workflow crosses from shaping (concept, concept-design, research) into scoping (spec, design, plan), intent gets lost. The agent running the pipeline has no way to trace a backlog item back to the shaping-tier files that motivated it.

The fix is structural: the epic template itself should carry two things it currently lacks.

1. **Source Documents** — a top-level provenance record listing which concept, concept-design, and research files the epic was built from.
2. **Required Reading** — a per-item field listing the specific shaping-tier files the work-item pipeline must read when working on that item.

These two sections create the traceability chain defined in the README_v2 artifact: shaping output flows into the epic as Source Documents, then the epic distributes it downstream as Required Reading per item. Downstream commands (spec, product-design, design) consume Required Reading — but that consumption is Item 3's scope, not this one.

## Success Criteria

- [x] The epic template (`project-pack/epic_template.md`) has a Source Documents section at the top level, with guidance text explaining what goes there
- [x] Each backlog item in the epic template has a Required Reading field, with guidance text explaining what types of files to list
- [x] `project-pack/EPIC_GUIDE.md` explains the traceability mechanism: what Source Documents and Required Reading are, why they exist, and how Required Reading carries shaping-tier intent into the work-item pipeline
- [x] The live project copy (`.project/epic_template.md`) matches the updated template

## Known Requirements

- **[HARD]** Source Documents is a top-level epic section, not per-item. It lists the shaping-tier files (concepts, concept-designs, research) the epic was built from. This is the provenance record — where the epic's goals came from.
- **[HARD]** Required Reading is a per-item field. It lists the specific files the work-item pipeline must read for that item. Different items in the same epic may have different Required Reading lists.
- **[NEED]** Required Reading should be optional per item. Not every item needs upstream shaping context. Items that are purely mechanical (cleanup, renames) may have no Required Reading.
- **[NEED]** The EPIC_GUIDE explanation should cover the full traceability chain: shaping → Source Documents → Required Reading → pipeline consumption. The guide doesn't need to explain *how* downstream commands consume Required Reading (that's Item 3), but it should explain *that* they do and *why*.
- **[INFERRED]** Source Documents goes after the Executive Summary / Critical Success Factor block, before "Why This Epic?" — matching the placement used in `epic_workflow_v2.md`.
- **[INFERRED]** Required Reading goes after the Dependencies field in the backlog item template — it's conceptual input, similar to dependencies but for context rather than ordering.

## Non-Goals

- Modifying any existing epic in `backlog/` to use the new format (that happens when `/_my_epic_plan` runs, Item 2)
- Changing what downstream commands (spec, product-design, design) do with Required Reading (that's Item 3)
- Restructuring other parts of the epic template (e.g., replacing the Deliverables section) — stay in scope
- Modifying the BACKLOG.md template

## Open Questions / Deferred to design

- ~~Whether the EPIC_GUIDE should include a visual traceability diagram~~ **Resolved:** Yes, include a visual traceability diagram in the EPIC_GUIDE (similar to the ASCII chain in the README_v2 artifact).
- Whether the backlog item template in EPIC_GUIDE should also be updated to include Required Reading, or only the main `epic_template.md`. Likely yes for consistency, but deferred to implementation.

---

## Related Artifacts

- **Source (target state):** README_v2 artifact — Section 3 (Traceability Chain), Section 7 (Lifecycle Rules), Section 10 (Changes from v1)
- **Epic:** `.project/backlog/epic_workflow_v2.md`, Item 1
- **Design:** `.project/active/epic-template-foundation/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design` — though this is low-complexity enough that design may be brief or skipped.
