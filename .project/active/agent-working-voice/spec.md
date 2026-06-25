# Spec: Agent Working Voice

**Status:** Implementation Complete
**Owner:** Reid W
**Created:** 2026-06-23
**Complexity:** MEDIUM
**Branch:** agent-working-voice

---

## Work Item Summary

Define the voice the agent uses when working with the user — in conversation and in the internal workflow artifacts the user reads (specs, designs, plans, research, concept docs, reviews, handoffs). Today that voice is dense, jargon-heavy, and tiring to read, and it has gotten worse with recent models. This work item writes one global rule for that voice, rewrites the command prompts so they stop teaching the agent to write badly, and adds a writing-style check to the review commands. Done means: the user reads an artifact or a message once, mid-task, and immediately knows what's going on and what to decide.

## Why This Matters Now

The bad voice compounds. Early-stage docs set the vocabulary; specs, designs, and plans inherit it; by the time the user reads anything, every artifact is jargon-filled dense crap. The user ends up rescuing every decision by hand ("walk through each question, explain the full context, the crux, what's impacted, then your recommendation and why"). The patterns this repo sets up all fail if the writing style is bad, so fixing the voice is upstream of everything else the pack does.

## Key Bets / Constraints

- **Bet:** The agent mirrors the register of its own instructions. If the command prompts are written in the bad voice, the agent writes in the bad voice — so rewriting the prompts themselves is the real lever, not just adding a rule for them to cite.
- **Bet:** A passive auto-loaded rule is enough for the conversational and artifact voice. The only enforcement we add is a writing-style check in the review commands.
- **Constraint:** Three registers exist; this work owns exactly one. It governs the *working voice* (texture and decision-presentation). It does not touch external-explainer guidance, and it does not touch per-command artifact structure (what goes where).
- **Constraint:** Editing a command's voice must not disturb its structural guidance. `concept_design`'s register discipline, `spec`'s normative-language rules, and similar all stay.
- **Non-goal:** External explainer artifacts. Out of scope, untouched.
- **Non-goal:** Rewriting what artifacts contain or how they are organized.

---

## Business Goals

### Why This Matters

The user has to read these artifacts and these messages to do their job. The current voice makes that slow and unpleasant, to the point of avoidance. Every downstream pattern in the pack depends on artifacts being readable; the voice is the bottleneck. This is a recurring, worsening battle, not a one-off complaint.

### Success Criteria

- [ ] A tired engineer reads an artifact or a chat message once and knows the situation and the decision without a second pass.
- [ ] The irritating texture is gone — not just the unclear structure, but the tone (hedging, inflated stakes, em-dash triplets, "robust/leverage/seamless" register).
- [ ] Decisions are presented in the format the user keeps asking for by hand, without being asked.
- [ ] The command prompts read in the target voice, so the agent has a good register to mirror.
- [ ] The standard lives in one place; the workflow stops fighting it at every stage.

### Priority

High. Upstream of the value of every other command in the pack.

---

## Problem Statement

### Current State

- No global rule governs the agent's working voice. The only writing guidance is scattered and uneven: an external-explainer section in one project's `CLAUDE.md`, structural rules inside `concept_design` and `spec_review`, and lighter "be clear" lines in `spec` and `research`.
- The command prompts themselves are written in the dense register, which the agent then mirrors into its output.
- The user has no shorthand for the decision walkthrough they want; they paste the same rescue prompt every time.

### Desired Outcome

- One auto-loaded rule defines the working voice: a decision-presentation format plus a short, concrete list of voice do's and don'ts with before/after examples.
- The command prompts are written in that voice, so good register is the default the agent copies.
- The review commands flag artifacts that violate the voice, so bad writing is caught before the user has to read it.

---

## Scope

### In Scope

- **A global rule** in `claude-pack/rules/` (new file). Auto-loaded every session; propagated to Codex through the existing build.
- **An audit and edit of all `_my_*` commands, plus skills and agents**, for two things:
  1. Voice *instructions* that overlap, conflict, or duplicate — reconciled, pointed at the rule.
  2. The prompt's *own* voice — rewritten in the target voice where it reads badly.
- **A writing-style check** added to the review commands that assess written artifacts (`_my_spec_review`, `_my_review_design`; audit confirms whether `_my_review_compact` and `_my_code_review` carry a lighter version).
- **Codex propagation** verified after the rule and command edits land.

### Out of Scope

- External explainer artifacts and any external-audience writing guidance.
- Per-command artifact structure (what sections an artifact has, what goes where).
- Code-readability guidance inside `implement` / `code_review` / `code_quality` (a separate axis from prose voice; their user-facing summaries still follow the working voice).
- A forced per-command voice self-review pass. Not wanted.

### Edge Cases & Considerations

- A command may carry both a structural rule and a voice problem in the same paragraph. The edit must change the voice and leave the structure intact.
- The rule must be written in its own voice — it is the first proof, and a verbose voice rule is self-defeating.
- The decision-presentation format must fit conversation *and* artifacts without becoming a rigid template that mangles short messages.
- Codex parses skill frontmatter strictly; rule content that breaks the build (e.g. a description leading with `*`) must be avoided, per `CLAUDE.md`.

---

## Requirement Selection Notes

The normative requirements below cover the three concrete deliverables (rule, command edits, review check) and the constraints that keep this work from bleeding into the other two registers. The actual *content* of the voice rule — the specific do's, don'ts, and examples — is left to the design/drafting stage; it is a writing problem, not a requirement to enumerate here. The exact edit surface across commands is deliberately deferred to an audit, which is the first implementation step.

---

## Requirements

### Functional Requirements

> From the user's request unless marked [INFERRED].

1. **FR-1**: A new global rule file MUST exist in `claude-pack/rules/` defining the agent's working voice. It MUST be auto-loaded (live in `rules/`) and MUST propagate to Codex through the existing build.
2. **FR-2**: The rule MUST define the decision-presentation format the user wants: situation → crux/decision → implications of each option and why → recommendation and why, leading with the frame rather than the mechanism.
3. **FR-3**: The rule MUST cover both registers it owns — the conversational voice with the user and the voice of internal workflow artifacts.
4. **FR-4**: The rule MUST be written in the voice it defines.
5. **FR-5**: All `_my_*` commands, skills, and agents MUST be audited for voice instructions that overlap, conflict, or duplicate the rule. Conflicts MUST be reconciled; where a command needs voice guidance it SHOULD point at the rule rather than restate it.
6. **FR-6**: The command/skill/agent prompts MUST themselves be rewritten in the target voice where they currently read in the dense register. [This is the primary lever: the agent mirrors the register of its instructions.]
7. **FR-7**: A writing-style check MUST be added to the review commands that assess written artifacts (`_my_spec_review`, `_my_review_design` at minimum). The check flags artifacts that violate the working voice.
8. **FR-8**: Editing voice MUST NOT alter per-command artifact-structure guidance (e.g. `concept_design` register discipline, `spec` normative language).
9. **FR-9**: External-explainer guidance and external-audience writing MUST be left untouched.

### Non-Functional Requirements

- The rule SHOULD be short. Length is itself a voice failure.
- The rule SHOULD lean on concrete before/after examples, since examples move a model's register more than abstract instruction.

---

## Acceptance Criteria

### Core Functionality

- [ ] Global working-voice rule exists in `claude-pack/rules/`, auto-loads, and appears in the Codex build output.
- [ ] The rule contains the decision-presentation format (FR-2) and applies to chat and artifacts (FR-3).
- [ ] The rule reads in its own voice (FR-4) — short, plain, no AI-tells.
- [ ] Every `_my_*` command/skill/agent has been audited; the audit output names each file touched and why (FR-5, FR-6).
- [ ] No two prompts give conflicting voice instructions; voice guidance points at the rule (FR-5).
- [ ] Prompts that read in the dense register have been rewritten (FR-6).
- [ ] `_my_spec_review` and `_my_review_design` include a writing-style check (FR-7).
- [ ] `concept_design` / `spec` structural guidance is unchanged (FR-8); external-explainer guidance is unchanged (FR-9).

### Quality & Integration

- [ ] `build-codex-pack.sh` + `setup-codex.sh` run clean with the new rule and edits.
- [ ] `setup-global.sh` symlinks the new rule into `~/.claude/rules/`.

---

## Next-Stage Handoff

**Settled in this spec:**
- The three-register model and that this work owns only the working voice.
- The three deliverables: global rule, command/skill/agent audit-and-rewrite, review-command writing check.
- The agent-mirrors-its-instructions bet: prompts get rewritten, not just pointed at the rule.
- Enforcement is limited to the review-command check; no forced per-command self-review pass.

**Design must figure out:**
- The actual content of the voice rule: the specific do's, don'ts, examples, and the exact phrasing of the decision-presentation format.
- The shape of the writing-style check in the review commands — what it flags, how it reports, how to keep it from firing on trivial awkwardness.
- The audit method: how to sweep all commands/skills/agents and classify each hit as "instruction conflict," "prompt voice," "structure — leave alone," or "external — leave alone."
- Whether `_my_review_compact` and `_my_code_review` get a lighter version of the check.

**Watch-outs for design:**
- Voice and structure often live in the same sentence; edits must separate them.
- The rule must not grow into a style bible; short and example-driven beats exhaustive.
- The decision format must degrade gracefully for a one-line answer.

---

## Related Artifacts

- **Feedback source:** `/tmp/claude-writing-feedback.md` (the agent's own diagnosis of why it writes this way — primary input for the rule's content)
- **Reference for good writing:** echo `Technical Writing` section (external-explainer register — a *pointer*, not a thing to copy or touch)
- **Design:** `.project/active/agent-working-voice/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
