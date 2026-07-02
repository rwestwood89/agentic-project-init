# Design: Epic Template Foundation

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** LOW
**Epic:** WORKFLOW-V2, Item 1

---

## Overview

Add Source Documents and Required Reading to the epic template, and update the EPIC_GUIDE to explain the traceability mechanism. Four files change; no code, no commands, no logic.

## Related Artifacts

- **Spec:** `.project/active/epic-template-foundation/spec.md`
- **Epic:** `.project/backlog/epic_workflow_v2.md`, Item 1
- **Target state:** README_v2 artifact, Sections 3 and 10

---

## Core Concept

The epic is the bridge between shaping (concepts, research) and scoping (spec, design, plan). Today it has no formal link back to the shaping-tier files it was built from, so context gets lost crossing the boundary.

Two additions fix this. **Source Documents** is a top-level section listing the shaping-tier files the epic was built from — provenance. **Required Reading** is a per-item field listing the specific files the work-item pipeline must read for that item — operational input. Source Documents answers "where did this epic come from?" Required Reading answers "what should the agent read before working on this item?"

The template defines the structure. The EPIC_GUIDE explains why it exists and how to fill it in. Downstream commands (spec, product-design, design) consuming Required Reading is Item 3's scope.

---

## Key Decisions

- **D1. Source Documents placement: after Executive Summary, before "Why This Epic?".** This matches the pattern already used in `epic_workflow_v2.md` and keeps provenance near the top where it's visible on a skim. Rejected: after "Why This Epic?" (too far down; readers skim top-to-bottom and Source Documents orients the whole epic).

- **D2. Required Reading placement: after Dependencies in the item template.** Required Reading is contextual input for the pipeline, conceptually adjacent to Dependencies (which are ordering inputs). Rejected: after Objective (too early — reader hasn't seen scope yet); after Success/Done State (too late — it's an input, not an output).

- **D3. EPIC_GUIDE gets an ASCII traceability diagram.** The README_v2 has one. The guide should show the chain visually so the reader sees the shape before reading the explanation. Rejected: prose-only (harder to see the full chain at a glance).

- **D4. The EPIC_GUIDE backlog item template also gets Required Reading.** The guide has its own copy of the item template. If it doesn't match the main template, they'll drift. Both get the field.

---

## Architecture

Four files, three types of change:

1. **`project-pack/epic_template.md`** — the source template
   - Add `## Source Documents` section after the `---` following Critical Success Factor, before `## Why This Epic?`
   - Add `**Required Reading:**` field to the backlog item template, after `**Dependencies:**`

2. **`project-pack/EPIC_GUIDE.md`** — the methodology guide
   - Add a new section explaining Source Documents and Required Reading
   - Include the ASCII traceability diagram from README_v2 (adapted to guide context)
   - Add Required Reading field to the backlog item template already in the guide

3. **`.project/epic_template.md`** — the live project copy
   - Mirror changes from `project-pack/epic_template.md`

4. **`.project/EPIC_GUIDE.md`** — the live project copy
   - Mirror changes from `project-pack/EPIC_GUIDE.md`

---

## Component Overview

### Source Documents section (epic template)

Placed between Executive Summary and "Why This Epic?". Contains:
- A brief guidance comment explaining what goes here
- Bulleted list of file paths with type annotations (concept, concept-design, research)

Template text:

```markdown
## Source Documents

[Shaping-tier files this epic was built from. These are the provenance
record — where the epic's goals came from.]

- `{path}` — [concept | concept-design | research]
```

### Required Reading field (item template)

Placed after Dependencies in each backlog item. Contains:
- A brief inline hint about what to list
- Bulleted list of file paths the work-item pipeline must read

Template text:

```markdown
**Required Reading:** [Files the work-item pipeline must read for this item. Usually a subset of Source Documents — concepts, concept-designs, or research files that carry intent relevant to this specific item. Optional for items that need no upstream shaping context.]
- `{path}`
```

### EPIC_GUIDE traceability section

A new section titled "Source Documents and Required Reading" (or similar), placed after the existing Initialization section and before Decomposition. Contains:
- One-paragraph explanation of the traceability problem
- ASCII diagram showing the chain: shaping → Source Documents → Required Reading → pipeline
- Explanation of Source Documents (what, where, when to fill in)
- Explanation of Required Reading (what, where, how it differs from Source Documents)
- The rule: Required Reading applies to the entire work-item pipeline, not just spec

---

## Required Invariants

- The epic template and the EPIC_GUIDE backlog item template stay in sync — both include Required Reading in the same position.
- Source Documents is always a top-level epic section, never per-item.
- Required Reading is always per-item, never top-level.
- The live project copies (`.project/`) match the source templates (`project-pack/`).

---

## Non-Goals

- Writing the `/_my_epic_plan` command that fills these sections (Item 2)
- Modifying downstream commands to read Required Reading (Item 3)
- Restructuring other parts of the epic template
- Modifying any existing epic to use the new format

---

## Implementation Notes

- The ASCII traceability diagram in the EPIC_GUIDE should be adapted from the README_v2 Section 3 chain, but simplified to focus on Source Documents → Required Reading → pipeline consumption. Don't reproduce the full command-level detail.
- Required Reading guidance text should mention that it's optional — not every item needs it.
- The live project copies are currently identical to the source templates. After editing the source templates, copy them over (or diff and apply the same changes).

---

## Validation Approach

- Diff `project-pack/epic_template.md` against `.project/epic_template.md` — should be identical after changes.
- Diff `project-pack/EPIC_GUIDE.md` against `.project/EPIC_GUIDE.md` — should be identical after changes.
- Read the updated EPIC_GUIDE and verify the traceability explanation is clear on a single read.
- Verify the `epic_workflow_v2.md` epic (which already has a Source Documents section) is consistent with the new template format.

---

## Next-Stage Handoff

**Fixed:** Template placement (D1, D2), guide structure (D3, D4), file list.
**Open:** Exact wording of guidance text — use the drafts above as starting points, refine during implementation.
**Risk:** None significant. These are documentation changes.

---

Next Step: After approval → `/_my_plan` or direct implementation (this is small enough to implement without a formal plan).
