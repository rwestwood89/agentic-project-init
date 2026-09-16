---
name: my-spec
description: Capture a work item's intent, then clarify its success criteria and known needs. Use when a feature or change needs to be understood and documented before design.
---

Generated from `claude-pack/commands/_my_spec.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Spec Command

**Purpose:** Capture the intent for a work item and settle what it needs to accomplish
**Input:** A feature idea, bug, user story, or rough need
**Output:** `.project/active/{feature-name}/spec.md`

## What Good Looks Like

Capture in plain English, and with the richness supplied by the owner and surrounding context, what this work item is for. Preserve the problem, desired end state, reasoning, constraints, examples, and named referents that matter. Structure should make the intent easier to use, not replace it with a compressed restatement.

Collect additional context as needed to understand what the owner is looking for. Investigate facts in the codebase or environment yourself. Ask the owner about decisions, not facts you can discover.

After the intent is captured, use questioning rounds to settle the remaining spec-level decisions. Record additional need statements with provenance. Use EARS phrasing when it makes a trigger, state, or response clearer; use ordinary plain English when it does not.

Be aggressive about understanding the problem and conservative about inventing a solution. Preserve a mechanism or standard the owner actually required. Do not introduce one they did not.

## Capture and Context

Read the request and every source it names in full. If the item belongs to an epic, read its Required Reading as primary input. Read `.project/CURRENT_WORK.md`, relevant project docs, and the code at the seams needed to understand the request.

Write the initial Problem section before questioning. It is a faithful working capture of the owner's intent, not a one-sentence summary. Keep the owner's level of detail where that detail carries meaning. Mark owner-given examples and referents with their force under the capture-fidelity rule.

Research gaps that can be answered from code, data, or the environment. Use a fresh-context `explorer` subagent for broad codebase questions. Offer a spike or learning test when actual behavior must be observed. Do not ask the owner to supply discoverable facts.

## Questioning Rounds

Map the unsettled spec decisions as a tree. The **frontier** is every material decision whose prerequisites are already settled. Ask the whole frontier in one round; do not ask a question whose answer depends on another unresolved question in that round.

Number each question. Explain what the answer changes, give the realistic options and their costs, and recommend an answer when you have one. The owner makes decisions; you investigate facts.

After each response, update the working capture, recompute the frontier, and ask the next round. Stop when the intent, success conditions, and known needs are clear enough for design. Put safe-to-defer mechanism and usability choices in Open Questions rather than interrogating the owner about implementation.

If the request and context already settle the work item, ask no questions.

## Write the Spec

Create `.project/active/{feature-name}/spec.md`, add the item to `.project/CURRENT_WORK.md`, and use the smallest subset of this structure that faithfully carries the work:

```markdown
# Spec: [Feature Name]

**Status:** Draft
**Owner:** [Git Username]
**Created:** [Date/Time]
**Complexity:** [LOW | MEDIUM | HIGH]
**Branch:** [Branch name if applicable]

## Problem

[The work item's intent in plain English: current situation, problem, desired end state, and the context needed to understand why this work matters. Match the richness of the source material.]

## Success Criteria

- [ ] [Observable outcome that shows the intended change exists.]

## Known Requirements

- **[HARD]** [Forced by an external interface, physics, or existing system.]
- **[NEED]** [Owner-stated need. Preserve its stated force.]
- **[INFERRED]** [Agent-derived need.]
- **[INHERITED]** [Need carried from an upstream artifact, with source.]

## Non-Goals

- [Deliberate scope boundary, if one matters.]

## Open Questions / Deferred to design

- [Unsettled choice that is safe for design or implementation.]

## Related Artifacts

- **Epic:** [if any]
- **Required Reading:** [if any]
- **Research:** [if any]
- **Product Lens:** `.project/active/{feature-name}/product-lens.md`
- **Design:** `.project/active/{feature-name}/design.md` (to be created)
```

The Problem carries the intent. Success Criteria say what observable change means the work succeeded. Known Requirements add statements that constrain the work beyond that narrative; they are not a second rewrite of the entire request.

Use `[NEED]` only for owner-stated needs, `[INFERRED]` for your conclusions, `[INHERITED]` with its source, and `[HARD]` only for a real external constraint. EARS is optional: use it where event/state/response structure removes ambiguity, not as a translation exercise for every requirement.

## Check and Present

Before presenting, compare the spec directly with the request and its sources. The intent should still be recognizable at the same richness. Check that examples, referents, numbers, and named standards retained their force; inferred needs are not presented as owner statements; and open implementation choices did not harden into requirements.

Spawn a fresh-context `default` subagent whose entire instruction set is `$HOME/.codex/scripts/product-lens.md` (pack source: `claude-pack/scripts/product-lens.md`). Give it the repo's durable product sources plus owner-verbatim shaping material as SOURCES, and the drafted spec as WORK. Append its ledger block to `.project/active/{feature-name}/product-lens.md`. An unresolved owner/`[HARD]` contradiction blocks; lower-authority findings receive a visible disposition and may proceed.

If the item belongs to an epic, record `Epic: <id>` in the item's first product-lens block even when the epic has no current finding. Reference existing epic findings without copying them, preserving their source grade, so later gates can resolve the epic's live state.

Present the spec, take corrections, and update the artifact. After approval, proceed to ``my-design``; use ``my-product-design`` first when the consumer-facing behavior needs separate attention. Use ``my-spec-review`` only when an adversarial review adds confidence.

**Last Updated:** 2026-09-16 — centered plain-English intent capture and frontier-based questioning rounds.

