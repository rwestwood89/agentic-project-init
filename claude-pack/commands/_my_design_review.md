# Design Review Command

**Purpose:** Decide whether a technical design is safe and clear enough to implement
**Input:** Design document reference (`.project/active/{feature-name}/design.md`)
**Output:** `.project/active/{feature-name}/design-review.md` and a presentation to the user

## The Job

Review the design as a skeptical senior engineer who wants implementation to start once the important thinking is sound. Find material design failures, not the largest possible list of unanswered questions.

A design is ready when a competent implementer can begin without guessing the architecture, violating an important invariant, or making a consequential product decision. It does not need to pre-decide reversible implementation details. The implementation agent will have better local evidence while reading and changing the code; audit, human code review, and PR review judge those choices in working code.

**You own the review doc; you never edit the design.** Record the user's resolutions in the review and let the authoring session incorporate them. The one exception is an explicit user request to edit the design directly.

When invoked, use the supplied feature name or design path. If neither is supplied, ask for it.

## What Blocks Implementation

A finding blocks only when the design:

- contradicts an owner requirement, a hard constraint, or the product's point;
- could materially lead implementation to build the wrong behavior;
- leaves system shape, a public or cross-component contract, or ownership of an important invariant ambiguous;
- leaves two materially different architectures open when choosing later would carry meaningful cost;
- rests on a load-bearing premise that lacks evidence and cannot be tested cheaply during implementation; or
- defers a problem whose later correction would require broad rework rather than a local change.

Missing detail is not itself a blocker. Do not block on file layout, helper shape, exact test representation, dependency flags, framework mechanics, local error handling, or another reversible choice unless that choice changes one of the concerns above.

For every observation, ask where the decision has the best evidence and the cheapest correction:

- **Design:** system shape, responsibility or invariant ownership, consequential contracts, or expensive-to-reverse choices.
- **Implementation:** local and reversible choices best made while reading and changing the code.
- **Audit/code review:** claims that can only be judged against working behavior.
- **Follow-up:** useful hardening outside the current success criteria.

Only design findings affect the verdict. Record implementation or audit observations briefly as non-blocking watchpoints when forgetting them would create real risk. Omit speculative suggestions and harmless preferences.

## Review

Read the design, its spec, relevant upstream decisions, and the code at the seams the design changes. Explore enough of the codebase to verify the design's important claims; exhaustive discovery is not the goal.

When complexity or abstraction quality is a material concern, consider invoking `/_my_ponytail` as a deletion-first lens. Its suggestions are evidence for the review, not automatic findings; they still have to meet the blocker bar above.

Spawn a `general-purpose` subagent whose entire instruction set is `~/.claude/scripts/product-lens.md` (pack source: `claude-pack/scripts/product-lens.md`). SOURCES are the repo's durable product statements plus owner-verbatim material in the concept or Required Reading. WORK is the design and the code it touches. Append the lens result to `.project/active/{feature-name}/product-lens.md`.

An unresolved owner/`[HARD]` contradiction is a blocker. A structural smell is a signal to inspect the consequence, not an automatic verdict. It blocks only when the consequence meets the materiality bar above.

Judge the design holistically:

- Is this the right piece of work and the right overall approach?
- Is there a simpler shape that meets the same requirements without losing an important property?
- Are boundaries, data flow, responsibilities, and invariant ownership clear where they matter?
- Does the design compose with the existing system instead of creating a parallel mechanism?
- Are its load-bearing bets honest, and can uncertain behavior be learned cheaply in code?
- Can a reader understand the system's model and the consequential decisions without reconstructing them from implementation detail?

Use these questions to find material issues. Do not produce a pass/fail entry for every question, and do not manufacture a finding to prove the review was skeptical.

If the foundation is wrong, keep the review short, but still make one breadth pass for other independent design blockers already visible. Present all currently discoverable blockers together so the owner does not learn them serially across review reruns.

## Verdicts

- **Approve:** no design blocker remains. Non-blocking implementation or audit watchpoints may still exist.
- **Revise:** the overall approach is sound, but one or more bounded design blockers must be corrected before implementation. Minor, objectively verifiable corrections do not require another fresh review once their fixes are checked.
- **Rework:** the system shape, product direction, or invariant ownership is fundamentally wrong enough that bounded edits cannot make the design trustworthy.

Do not use Revise or Rework for implementation details, optional hardening, or uncertainty that is cheaper to resolve while coding.

## Persist and Present

Write `.project/active/{feature-name}/design-review.md` with the smallest structure that carries the judgment:

```markdown
# Design Review: [Feature Name]

**Design:** [path]
**Spec:** [path]
**Date:** [date]

## Judgment
[Is this the right work and approach? Why?]

## Design Blockers
- **[ID]** [Material problem, consequence, evidence, and the smallest adequate correction.]

## Implementation and Audit Watchpoints
- [Non-blocking observation worth carrying forward. Omit this section when empty.]

## Resolutions
- **[ID]** [The user's decision in their terms.]

**Overall:** [Approve / Revise / Rework]
**Next:** [What must happen before implementation, if anything.]
```

An approved review can have an empty Design Blockers section. Say "None" rather than inventing content. Keep evidence close to each finding and cite exact artifact or code locations.

The review is a draft until the user engages with it. Record their resolutions faithfully without relitigating an override. If bounded corrections resolve every blocker, update the verdict; do not demand another fresh review merely to replace a stale verdict.

---

**Related Commands:**
- Before review: `/_my_design`
- After approval: `/_my_implement` or `/_my_plan`

**Last Updated:** 2026-09-16 — added a materiality bar, routed implementation detail to code, and removed automatic checklist and smell escalation.
