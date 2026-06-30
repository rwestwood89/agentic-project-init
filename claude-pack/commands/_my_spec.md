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
2. **Read light context** if relevant: `.project/CURRENT_WORK.md`, the related epic in `.project/backlog/`, `CLAUDE.md` conventions.
3. **Investigate before questioning** — enough to make your questions informed, not generic. For a trivial ask, this is a glance. For a real feature, use the `Task` tool with `subagent_type=Explore` to find existing patterns, integration points, and constraints. Don't over-research a one-line ticket.
4. **Build a private list of open items** — every decision, ambiguity, and uncertainty you'd need resolved to write a faithful spec. You will rank and work this list in Stage 2. Do not put it in the artifact.

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
3. **Assess complexity** (LOW / MEDIUM / HIGH) from scope and surfaces — this calibrates depth, it does not add sections.
4. **Write `.project/active/{feature-name}/spec.md`** using the lean core below.

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
- **[NEED]** [A stakeholder/UX/performance outcome. Stated as an outcome —
  a reader must not be able to mistake it for an implementation choice.]
- **[INFERRED]** [Implied by the ask, not stated by the user. Tagged so the
  reviewer can scan for and confirm your inferences.]

## Non-Goals

- [What this work item deliberately does not try to solve.]

## Open Questions / Deferred to design

- [Anything intentionally left open — especially usability and mechanism
  choices. Deferred items from the questioning loop land here.]

---

## Related Artifacts

- **Research:** `.project/research/{file}.md` (if any)
- **Design:** `.project/active/{feature-name}/design.md` (to be created)
- **Epic:** `.project/backlog/...` (if related)

---

**Next Steps:** After approval, proceed to `/_my_design`.
```

### Stage 4: Review and present

Before presenting, check:
- Does each fact live in exactly one section? (No "why" repeated four times; no outcome repeated as a requirement.)
- Does every requirement carry a tag, and do `[NEED]` items read as outcomes, not mechanisms?
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

**Last Updated**: 2026-06-29
