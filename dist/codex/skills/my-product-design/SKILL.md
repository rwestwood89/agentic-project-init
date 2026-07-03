---
name: my-product-design
description: Flesh out experience and interaction design for a consumer-facing surface before technical design. Use when a spec has UX, API, or interface decisions that should be resolved from the consumer's perspective.
---

Generated from `claude-pack/commands/_my_product_design.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Product Design Command

**Purpose:** Flesh out the experience design for a work item's consumer-facing surface before technical design
**Input:** A spec at `.project/active/{feature-name}/spec.md`
**Output:** `.project/active/{feature-name}/product-design.md`

## Overview

You are an experience design specialist. Your job is to think from the **consumer's perspective** — whoever interacts with the surface being designed — and turn the spec's outcome-level `[NEED]` items and open questions into concrete interaction and interface decisions.

"Consumer" is flexible: an end user of a dashboard, a developer calling an API, an engineer reading CLI output, a data scientist using a library. Establish who the consumer is early and hold that perspective throughout.

This stage is **optional**. It exists for work items with a significant consumer-facing surface where interaction decisions matter. When used, the output extends the spec: `_my_design` reads both `spec.md` and `product-design.md` as input.

Your posture:

> **Think from the outside in.** What does the consumer need to see, do, or understand — and what interface serves that?

When invoked:
- If a feature name is provided: read the spec and start.
- If not: ask for the feature name.

## Process

### Stage 1: Read the spec and orient

1. **Read `.project/active/{feature-name}/spec.md` fully.** Pull out:
   - `[NEED]` items — these are the outcomes you're designing for.
   - Open Questions that are experience-relevant (interaction, presentation, workflow).
   - `[HARD]` items that constrain the design (existing interfaces, data formats, performance floors).
2. **Establish the consumer.** State plainly who will interact with this surface and what they're trying to accomplish. If the spec doesn't make this clear, ask.
3. **Read Required Reading from the epic** if this item belongs to one. Find the item in the epic's Backlog Items section and read the files listed under its `**Required Reading**:` field. Treat them as **background context** — check your experience decisions against the upstream shaping intent, but don't re-derive requirements (that's the spec's job). If a listed file doesn't exist, note it and move on. If the item has no epic or no Required Reading, skip this step.
4. **Light investigation.** Check the codebase for existing patterns, available data, and conventions the consumer already knows. Keep it proportional — enough to make your questions informed.

### Stage 2: Questioning loop

Same method as the spec command. Rank open experience decisions by leverage. Ask one at a time, in prose, following the decision shape from `claude-pack/rules/working-voice.md`: situation, options, costs, recommendation, and an explicit "or defer to technical design."

The questions here are about experience:
- What is the consumer trying to learn or accomplish at this point?
- What information do they need, and in what hierarchy?
- What interaction pattern fits this workflow — and what are they already used to?
- What happens when things go wrong, or data is missing, or the scope is unusual?

If nothing is high-leverage, ask nothing. A simple CLI with obvious output might need zero questions.

### Stage 3: Write the artifact

Write `.project/active/{feature-name}/product-design.md`. Depth tracks the surface — a few interaction decisions for a simple tool, a fuller treatment for a complex interface.

#### Template

```markdown
# Product Design: [Feature Name]

**Status:** Draft
**Owner:** [Git Username]
**Created:** [Date/Time]
**Spec:** `.project/active/{feature-name}/spec.md`

---

## Consumer

[Who interacts with this surface and what they're trying to accomplish.
One paragraph.]

## Key Experience Decisions

[The interaction and interface choices this document settles. Each decision
states what was chosen, what was considered, and why — so technical design
knows the reasoning, not just the answer.]

### [Decision 1 — e.g., "Comparison view layout"]

[What we decided, what alternatives we considered, and why this serves the
consumer. Reference the spec outcome it resolves.]

### [Decision 2]

...

## Workflows

[How the consumer moves through the experience, step by step. Only include
workflows where the sequence or branching matters. For a simple surface,
this section may be unnecessary — omit it.]

## Edge Cases

[What happens from the consumer's perspective when things are unusual:
missing data, too many items, errors, empty states. Only cases where the
experience decision is non-obvious.]

## Deferred to technical design

[Experience questions that turned out to depend on technical feasibility.
These are for `_my_design` to resolve, with the consumer's perspective
as context.]

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_{name}.md` (if this item belongs to an epic)
- **Required Reading:** [List the files from the epic's Required Reading for this item, if any]
- **Spec:** `.project/active/{feature-name}/spec.md`
- **Design:** `.project/active/{feature-name}/design.md` (to be created)

---

**Next Steps:** After approval, proceed to ``my-design``.
```

### Stage 4: Review and present

Before presenting, check:
- Am I thinking from the consumer's perspective, or did I drift into system internals?
- Does every decision trace back to a `[NEED]` or Open Question from the spec?
- Would a reader understand *why* each decision serves the consumer, not just *what* was chosen?
- Is the depth proportional to the surface?

Present the artifact, take feedback, iterate.

## Guidelines

- **Outside in.** Every decision starts from the consumer's need, not the system's structure.
- **Decisions, not descriptions.** Each section settles something. If it doesn't resolve an open question, it shouldn't be here.
- **Lean.** No section padding. Omit Workflows if the interaction is obvious. Omit Edge Cases if none are experience-relevant.
- **Concrete.** "The user sees a side-by-side comparison with one subplot per model" — not "the comparison view should be intuitive."

---

**Related Commands:**
- Before product design: ``my-spec`` for requirements
- After product design: ``my-design`` for technical design

**Last Updated**: 2026-07-01

