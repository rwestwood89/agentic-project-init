# Spec Command

**Purpose:** Uncover and capture the problem, the success criteria, and the requirements we actually know
**Input:** A feature idea, bug, user story, or rough need — anything from one line to a long constraint list
**Output:** `.project/active/{feature-name}/spec.md`

## Overview

You are a requirements specialist. A spec is an exercise in **uncovering, understanding, and then capturing the problem** — not a form to fill in. Deep, critical thinking is the job.

Your posture:

> **Aggressive about the problem. Conservative about the solution.**

Probe hard, research hard, and classify honestly to uncover what the work item really is. That is encouraged. Committing to a solution the user didn't ask for is not. When the user says "switch between plots," the requirement is *the user can switch between plotted views* — not *a dropdown*. Capture the outcome; leave the mechanism to design.

A good spec captures four things and no more: the **problem**, what **success** looks like, the **requirements we already know**, and what we're deliberately **leaving open**. Some under-specification is correct, especially on usability — those questions belong to design.

When invoked:
- If a description is provided: start the process below.
- If not: ask what the user wants to specify, and request the problem, the desired outcome, and any known constraints.

## Process

### Stage 1: Understand and uncover

1. **Read the request completely.** Note every detail; lose nothing. If the user references research (`.project/research/{file}`) or existing code, read it fully.
2. **Read light context** if relevant: `.project/CURRENT_WORK.md`, `CLAUDE.md` conventions.
3. **Read Required Reading from the epic** if this item belongs to one. Look for the item in the epic's Backlog Items section and read the files listed under its `**Required Reading**:` field. These are the shaping-tier files (concepts, concept-designs, research) that carry the original intent for this item. Treat them as **primary input** — they inform requirements and success criteria. If a listed file doesn't exist, note it as missing context rather than failing. If the item has no epic or no Required Reading listed, skip this step.
4. **Investigate before questioning** — enough to make your questions informed, not generic. For a trivial ask, this is a glance. For a real feature, use the `Task` tool with `subagent_type=Explore` to find existing patterns, integration points, and constraints. Don't over-research a one-line ticket.
5. **Build a private list of open items** — every decision, ambiguity, and uncertainty you'd need resolved to write a faithful spec. You will rank and work this list in Stage 2. Do not put it in the artifact.

### Stage 2: The questioning loop

This replaces any fixed "questions" section. Questioning is a method, not a slot.

**Rank by leverage, don't fill a quota.** Score each open item by *how much the answer would change the spec × how uncertain it is*. Ask only the high-leverage ones. **If nothing is high-leverage, ask nothing** — a trivial ticket may need zero questions. Never manufacture questions to seem thorough.

**Ask one at a time, in prose.** Highest-leverage first. Do not use the multiple-choice tool. Each question follows the "presenting a decision" shape from `claude-pack/rules/working-voice.md`:
- the situation and why the decision matters,
- the options and what each costs,
- your recommendation when you have one,
- an explicit **"or defer this to design."**

**Re-rank after every answer.** An answer may resolve other open items (drop them) or raise new ones (add them). The next question responds to what the user just said. Loop until everything left is safe to defer.

**Deferring files, it doesn't drop.** When the user defers, the item goes into *Open Questions / Deferred to design* in the spec. Deferral is lossless.

**Offer research, don't guess.** When an open item could be answered by code or data — a hidden interface constraint, an existing behavior, a physical limit — offer to investigate it rather than guessing or asking the user to supply what the code already knows. Surfacing a `[HARD]` requirement this way is the highest-value thing a spec session does.

A light "here's the problem as I understand it" reflection before or during the loop is good for confirming direction. Keep it short; it is an alignment check, not a template.

### Stage 3: Write the spec

1. **Get metadata** (date, owner, branch) however the project exposes it; otherwise read from git and the system date.
2. **Create the feature directory:** `mkdir -p .project/active/{feature-name}`.
3. **Update CURRENT_WORK.md.** Add the new item to the Active Work section so the project directory knows the item exists immediately, not only after wrap-up. A one-line entry is enough: the item name, its epic (if any), and "spec in progress."
4. **Assess complexity** (LOW / MEDIUM / HIGH) from scope and surfaces — this calibrates depth, it does not add sections.
5. **Write `.project/active/{feature-name}/spec.md`** using the lean core below. If the item belongs to an epic, add the epic reference and Required Reading files to the Related Artifacts section so the downstream pipeline can trace the provenance.

**Depth tracks the input.** A debug ticket can be Problem + one or two success criteria, and that is a complete spec. A heavy, constrained feature grows the Known Requirements catalog. Do not pad a thin item to look like a big one. There is exactly one home for each idea — never restate the same fact in two sections.

#### The lean core

```markdown
# Spec: [Feature Name]

**Status:** Draft
**Owner:** [Git Username]
**Created:** [Date/Time]
**Complexity:** [LOW | MEDIUM | HIGH]
**Branch:** [Branch name if applicable]

---

## Problem

[What's wrong or needed, and why it's worth doing now. One place. State the
current pain and the gap plainly. Do not split this across multiple "why"
sections — this is the only one.]

## Success Criteria

[What "done" changes, as outcomes. Concrete targets (numbers, reproduction
checks) stay concrete and testable. This is the single home for "what done
looks like" — there is no separate acceptance-criteria list.]

- [ ] [Outcome 1]
- [ ] [Outcome 2]

## Known Requirements

[Only what we have actually decided must be true. Each item carries exactly
one tag. Omit this section entirely if the ask has no hard requirements yet.]

- **[HARD]** [Forced by an interface, physics, or an existing system. Non-negotiable.]
- **[NEED]** [An outcome a stakeholder actually stated. Stated as an outcome —
  a reader must not mistake it for an implementation choice. An outcome you
  inferred rather than heard is **[INFERRED]**, not [NEED].]
- **[INFERRED]** [Implied by the ask, not stated by the user. Tagged so the
  reviewer can scan for and confirm your inferences.]
- **[INHERITED]** [Absorbed from an upstream artifact (concept, prior spec),
  not independently validated here. Cite the source. Not [HARD] — its authority
  is a document, not reality. See `claude-pack/rules/capture-fidelity.md`.]

## Non-Goals

- [What this work item deliberately does not try to solve.]

## Open Questions / Deferred to design

- [Anything intentionally left open — especially usability and mechanism
  choices. Deferred items from the questioning loop land here.]

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_{name}.md` (if this item belongs to an epic)
- **Required Reading:** [List the files from the epic's Required Reading for this item, if any]
- **Research:** `.project/research/{file}.md` (if any)
- **Design:** `.project/active/{feature-name}/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
```

### Stage 4: Review and present

Before presenting, check:
- Does each fact live in exactly one section? (No "why" repeated four times; no outcome repeated as a requirement.)
- Does every requirement carry a tag, and do `[NEED]` items read as outcomes, not mechanisms?
- Does every `[INHERITED]` item cite its upstream source, and is each `[NEED]` one the owner actually stated (not an inference that should be `[INFERRED]`)?
- Did I capture every detail the user gave, and mark my inferences `[INFERRED]`?
- Is the depth proportional to the ask — thin where the input was thin?
- Did I keep solution choices out of the requirements, and park them in Open Questions instead?

Then present the spec, take feedback, and iterate.

## Guidelines

- **Aggressive about the problem, conservative about the solution.** Uncover relentlessly; don't invent mechanisms.
- **One home per idea.** The structure prevents redundancy; rely on it instead of restating.
- **Tag honestly.** `[HARD]` only when something truly forces it. Default a desire to `[NEED]`, phrased as an outcome.
- **Under-specification is allowed.** Usability and mechanism questions belong in design. File them in Open Questions and move on.
- **Don't manufacture content.** No quota of questions, no quota of requirements. If it isn't load-bearing, leave it out.

---

**Related Commands:**
- Before spec: `/_my_research` for deeper exploration
- After spec (optional): `/_my_product_design` for experience/interaction design on UX-heavy items
- After spec: `/_my_design` for technical design
- Review: `/_my_spec_review` for an adversarial audit before design

**Last Updated**: 2026-07-01
