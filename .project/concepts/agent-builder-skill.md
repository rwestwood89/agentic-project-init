# Concept: Agent Builder Skill

**Created:** 2026-09-07
**Status:** Draft

---

## Problem Statement

Four skills exist in this repo — `show-me`, `convince-me`, `_my_mental_model`, `_my_mental_model_v2` — and the fifth costs about as much as the first. The patterns that make them work are real and reusable, but they only exist as instances. A session starting a new skill re-derives them, or doesn't.

The default help pushes the wrong way. Agents asked to build an AI-centric process reliably produce a numbered procedure where a stated outcome belonged. This failure showed up inside the conversation that produced this concept: asked to keep it light, the agent invented a three-layer framework, formalized the owner's reference examples into a tier system, and asked seven questions before writing anything.

So the skill has to do the thing it is about. A prompt written as prescribed process teaches the executing agent to write prescribed process.

## Owner's Words

- **[OWNER-VERBATIM]** "I want to start building my own 'agent builder' skill. To capture the patterns and learnings that I find helpful."
- **[OWNER-VERBATIM]** "I'm not sure the right shape yet."
- **[OWNER-VERBATIM]** "agents who help build AI-centric processes tend to overprescribe process"
- **[OWNER-VERBATIM]** "be really clear about outcome objectives and responsibilities, and try to be as light as possible on prescriptive process"
- **[OWNER-VERBATIM]** "Mention tools and techniques, but leave judgement to the executing agent"
- **[OWNER-VERBATIM]** "a good technique is to provide available patterns, like `show-me`"
- **[OWNER-VERBATIM]** "the main agent is not REQUIRED to address everything -- the main agent is responsible for end quality and should use their best judgement"
- **[OWNER-VERBATIM]** "that subagent's job is to try and discern whether there is anything ACTUALLY generalizable about the feedback, and if so, recording it in a file"
- **[OWNER-VERBATIM]** "we should not overprescribe."

### Reference examples — [EXAMPLE], not a tier system

The owner gave three shapes to illustrate the range. They show the kind; they are not a ladder with entry criteria, and the skill does not route a request into one of them.

- **[OWNER-VERBATIM]** "A simple one needs just a prompt"
- **[OWNER-VERBATIM]** "A more complex task needs an artifact and specific rules: reference the pattern I shared (main, review, feedback)"
- **[OWNER-VERBATIM]** "Anything more sophisticated needs to be thoughtfully architected"

### The main / review / feedback pattern — [OWNER], as described

- The main agent produces a written artifact.
- The main agent invokes a review agent, which can handle mechanical checks (traceability), flagging anti-patterns, applying past learnings and feedback, or just being an adversarial review.
- The main agent is not required to address everything. It owns end quality and uses its best judgement.
- A feedback channel: when the owner gives feedback, the main agent invokes a record-feedback subagent. That subagent decides whether anything is actually generalizable, and records it in a file if so.

## Success Criteria

When this work is complete:

1. **The skill fires on the real request.** Asking to build or revise a skill loads it, without the owner naming it explicitly.
2. **Its output does not need a voice rewrite.** A `SKILL.md` produced through it reads as stated outcomes and responsibilities, not as a numbered procedure the executing agent audits itself against.
3. **The skill is itself an instance of its own advice.** A reader can point at places where it names a technique and leaves the call to the executing agent, and cannot find a step list that removes judgement.
4. **Intent is settled before building starts.** The owner is asked what they actually want before a draft exists.

---

## Why This Shape

- **Key bet:** The patterns are recoverable from the four skills already written, so this is capture, not invention.
- **Why this shape is promising:** The alternative — a procedure for authoring skills — is the exact failure the owner named. A collection of available patterns with honest tradeoffs, plus the writing standard, plus intent-elicitation up front, leaves the shape decision where it belongs.
- **Constraint to preserve downstream:** Every prescriptive line the design adds has to earn its place against "leave judgement to the executing agent." Light is the requirement, not the preference.

---

## User Stories

**US-1: Build a new skill**
As the owner, I can ask for a new skill and get my intent pulled out of me first, so the draft is aimed at what I meant rather than at my first sentence.

**US-2: Get the shape right for the task**
As the owner, I can have the building agent see the available shapes and their tradeoffs, so a simple skill stays a prompt and a complex one gets the machinery it needs.

**US-3: Not rewrite the voice afterward**
As the owner, I can read the produced skill once and ship it, so building a skill doesn't cost a separate voice pass.

**US-4: Record a learning**
As the owner, I can correct something and have the genuinely generalizable part captured, so the next skill starts further along.

---

## Key Concepts

### 1. Available patterns, not a route

The skill presents shapes and techniques with what each buys and costs. The building agent picks. `show-me` closes exactly this way — "You may use one of these, you may use several, it is unlikely you will use all of them. Use your judgement" (`claude-pack/skills/show-me/SKILL.md:130`).

### 2. Outcome and responsibility over process

State what the agent is accountable for and what "good" looks like. Name tools and techniques as available. Leave the sequencing to the agent doing the work.

### 3. Information collection up front

The skill being built should consider collecting information before it starts producing. Where the agent is unlikely to reliably have enough context for a high-quality result: research first (the codebase or otherwise), try to synthesize, then ask the user for clarifications. Questions may be intent-related, technical decisions, or anything else. `/grill-me` and `/_my_ask_me` are the two known techniques for the asking.

### 4. Main / review / feedback

The pattern above, for work large or important enough to earn it.

---

## Ideas for Rules, Guidance, and Patterns

A running list of candidate content for the skill. Not settled, not ordered, not all in scope.

**From the owner:**

- **[OWNER]** Be clear about outcome objectives and responsibilities; be as light as possible on prescriptive process.
- **[OWNER]** Mention tools and techniques; leave judgement to the executing agent.
- **[OWNER]** Provide available patterns — `show-me` is the reference for how.
- **[OWNER]** The main/review/feedback pattern for artifact-producing skills, as described above.
- **[OWNER]** The main agent owns end quality and is never obliged to act on every review finding.
- **[OWNER]** A record-feedback subagent judges whether feedback is actually generalizable before writing it down.
- **[OWNER]** Get intent clear before building — grilling rounds or `/_my_ask_me`.
- **[OWNER]** Information collection up front. Where it's unlikely the agent will reliably have enough context to deliver a high-quality result, the skill should consider: research (codebase or otherwise), try to synthesize, then ask the user for clarifications via `/grill-me` or `/_my_ask_me`. The questions may be intent-related, technical decisions, or anything else.

**From the four existing skills:**

- **[AGENT]** The `description` is the trigger and it fails silently — a skill that never loads is indistinguishable from one that doesn't exist. Write it in the words the owner would actually use. `convince-me`'s description names the question forms: is it true, does it work, is it fixed.
- **[AGENT]** Disambiguate against the neighbouring skill in the body. `claude-pack/skills/convince-me/SKILL.md:8` — "`/show-me` explains a shape. `/convince-me` proves a claim."
- **[AGENT]** Negative examples do more work than rules. `convince-me`'s "Not evidence" list, and the bad/good pairs that make up the whole feedback corpus in `claude-pack/skills/_my_mental_model_v2/feedback/synthesis.md`.
- **[AGENT]** Teach by showing the output. `show-me` is almost entirely examples of what to produce, with one short guidance section at the end.
- **[AGENT]** The agent mirrors the register of its own prompt — recorded in this repo from the working-voice work (`.project/CURRENT_WORK.md`, session notes 2026-06-25). Writing the skill well is the mechanism, not polish.
- **[AGENT]** Grammatical form carries the overprescription. A numbered step list invites compliance-checking; a stated outcome invites judgement.
- **[AGENT]** Build self-falsification into the method when there's no second reader. `convince-me` gets its rigour from "name the falsifier" and "run a control," not from a reviewer.
- **[AGENT]** A review agent is the same falsification handed to someone who doesn't share the writer's blind spots. That's what it buys over a self-check.
- **[AGENT]** The reviewer needs isolation to be worth anything — no sources, no conversation, no verdict authority. `claude-pack/skills/_my_mental_model_v2/review.md`.
- **[AGENT]** Feedback entries that quote the rejected line and its replacement verbatim survive better than summarized lessons.

---

## Non-Goals / Out of Scope

- **[OWNER]** The three reference examples stay examples. Out of scope: turning them into tiers with entry criteria, because that reintroduces the routing the skill exists to avoid.
- **[OWNER]** The mental-model-v2 coordinator machinery — readiness gate, render paths, browser inspection — is out of scope. Those solve v2's problem; the general pattern is main, review, feedback.

---

## Assumptions & Prerequisites

- The four existing skills are the source corpus and are treated as good instances.
- Skills in `claude-pack/skills/` ship to Codex through the existing build; whether this one does is open.

## Open Questions

1. Does the agent-builder skill use its own main/review/feedback pattern, or is it just a prompt?
2. Where does intent-elicitation come from — invoke `/_my_ask_me`, vendor the grilling technique, or write its own?
3. Does it cover revising an existing skill, or only building new ones?
4. What is its relationship to the built-in `skill-creator`?
5. Is it repo-local, or does it travel to other projects like `echo-workspace`?
6. Does it have its own feedback file, and where does that live?

---

## Next-Stage Handoff

**Settled here:**

- **[OWNER]** The skill's job is to capture the owner's patterns and learnings for building skills.
- **[OWNER]** Light on prescriptive process; clear on outcome objectives and responsibilities.
- **[OWNER]** Available patterns are presented, not routed.
- **[OWNER]** The main/review/feedback pattern is described as the owner stated it.

**Needs spec next:**

- The open questions above, questions 1–3 first — they change what the skill is.
- What goes in the skill versus what goes in a sibling reference file.

**Decomposition guidance:**

- Small enough to be one item unless question 1 answers toward the fuller architecture.
