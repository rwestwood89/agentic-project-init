# Design: Audit Certification

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Branch:** workflow-v2

## Overview

Replace `_my_audit_implementation` with `_my_audit` — a certification command that evaluates code against the full upstream chain (plan, spec, design, epic) and updates tracking artifacts to reflect actual completion status.

## Related Artifacts

- **Spec:** `.project/active/audit-certification/spec.md`
- **Epic:** `.project/backlog/epic_workflow_v2.md` — Item 4
- **Existing command being replaced:** `claude-pack/commands/_my_audit_implementation.md`
- **Existing command partially absorbed:** `claude-pack/commands/_my_code_review.md`
- **README_v2 artifact:** `https://claude.ai/code/artifact/9a7e2b06-4412-4e44-9c84-b3fc17b7544a`

## Research Findings

**Existing command patterns:**
- Execution-tier commands (`_my_implement.md`: 229 lines, `_my_plan.md`: 397 lines) use a staged process with clear sections. The longer commands include full markdown templates.
- `_my_audit_implementation.md` (77 lines) is organized as a checklist of audit questions with an output format description. Tight and effective.
- `_my_code_review.md` (467 lines) is over-engineered — heavy traceability matrices, RFC 2119 framework, exhaustive sub-question lists. The useful parts are the *what to check* (requirements traceability, design conformance), not the *how to report it*.

**Tracking artifact formats:**
- Plan phases use `- [ ]`/`- [x]` under "Changes Required" and "Validation" subsections (`_my_plan.md` template; live example at `.project/active/agent-working-voice/plan.md`).
- Spec success criteria use individual `- [ ]` lines, one per verifiable condition (`.project/active/epic-template-foundation/spec.md`).
- Epic item status: completed items get ✅ appended to the heading (e.g., `### Item 1: Epic Template Foundation ✅`), and their success/done-state checkboxes are marked `- [x]`.
- CURRENT_WORK.md entries are minimal: item name, status phrase, optional file path.

**What to absorb from `_my_code_review`:**
- Stage 2 (Requirements Traceability): the idea of verifying each spec requirement has implementation. Drop the matrix template and RFC 2119 framework — spec uses `[HARD]`/`[NEED]`/`[INFERRED]` tags.
- Stage 3 (Design Conformance): architecture check, design decision check. Drop the exhaustive sub-question lists.
- Drop entirely: Stage 4 (Code Quality Bug Hunt) → pre-PR, Stage 5 (bloated report template).

**What to keep from `_my_audit_implementation`:**
- All six audit areas: completion accuracy, deviation justification, fresh code review, abstraction quality, failure honesty, test coverage. These are already well-written and concise.

## Core Concept

The audit is a certification agent. It reads one work item's upstream artifacts — plan, spec, design, and the epic it belongs to — evaluates whether the code delivers what was specified, and then does two things: writes its assessment as `audit.md`, and mechanically updates the tracking checkboxes in plan, spec, and epic to reflect what it verified.

The key insight is the separation between judgment and bookkeeping. The evaluation is judgment-driven — the agent reads code, traces requirements, and flags gaps. The checkbox updates are mechanical consequences of that judgment: if the agent verified a plan phase is complete, it marks the checkbox. If a spec success criterion is met, it marks that too. The agent never marks what it hasn't verified.

Epic scope is a layer on top. It doesn't re-audit every item from scratch — it reads existing `audit.md` files, checks that all items are individually certified, then does the higher-level assessment: does the delivered work fulfill the original shaping-tier intent from the Source Documents?

## Key Bets

- **B1.** An agent can reliably verify spec requirements and design decisions by reading code. *If false → audit becomes a rubber stamp, marking checkboxes without catching real gaps.*
- **B2.** The existing `audit.md` from work-item audits provides enough signal for epic-scope assessment without re-auditing every item. *If false → epic audit becomes impractically expensive, needing to re-examine all code for every item.*

## Key Decisions

- **D1. Single command file with scope determined by argument**, not two separate commands. *Rejected: separate `_my_audit_item` and `_my_audit_epic` commands (unnecessary duplication — they share evaluation concepts and the prompt is short enough to cover both).*

- **D2. Four evaluation areas for work-item scope**, not the six from `_my_audit_implementation` plus the stages from `_my_code_review`. The four areas are: plan completion, spec conformance, design conformance, and code integrity (slop + failure honesty). *Rejected: keeping all six audit-implementation areas as separate sections plus adding code-review stages (too many headings, overlapping concerns). Fresh code review and test coverage fold into the four areas rather than standing alone.*

- **D3. Lean report template** — verdict, summary, findings with `file:line` references. No traceability matrices, no severity tables, no RFC 2119 framework. *Rejected: the exhaustive `_my_code_review` report format (the user explicitly said it's too verbose — "pare back the traceability matrix, lighten up the template, generally keep it simple").*

- **D4. Audit updates checkboxes directly by editing markdown files.** *Rejected: producing a "certification report" that someone else applies (adds a manual step that defeats the purpose of certification).*

- **D5. Epic scope reads existing audit.md files rather than re-auditing.** It checks for gaps (items without audits, items with "needs work" verdicts) and then does the source-document assessment. *Rejected: re-running work-item audit on every item (expensive, redundant, and the agent can't verify code for items it didn't implement without extensive context).*

## Architecture

Two flows through the same command, determined by whether the argument matches an item in `active/` or an epic in `backlog/`.

### Work-item flow

```
Read upstream artifacts (plan, spec, design, epic)
  │
  ▼
Evaluate four areas
  │  ├── Plan completion
  │  ├── Spec conformance
  │  ├── Design conformance
  │  └── Code integrity (slop + failure honesty)
  │
  ▼
Write audit.md → active/{item}/audit.md
  │
  ▼
Update checkboxes (plan, spec, epic)
  │
  ▼
Update CURRENT_WORK.md
```

### Epic flow

```
Read epic + Source Documents
  │
  ▼
Check all items have audit.md with "certify" verdict
  │  (flag items without audits or with "needs work")
  │
  ▼
Assess delivered work against Source Documents
  │  (does what was built match the original shaping intent?)
  │
  ▼
Update epic success criteria checkboxes
  │
  ▼
Update CURRENT_WORK.md
```

### Evaluation areas (work-item scope)

1. **Plan completion.** Are all phases marked done? Any placeholder code, TODOs, or partial implementations? For each phase, verify the changes-required and validation checkboxes are genuinely complete.

2. **Spec conformance.** For each success criterion and tagged requirement (`[HARD]`, `[NEED]`, `[INFERRED]`): does the code deliver it? Trace through the implementation with `file:line` references. Flag gaps, partial implementations, and requirements that are claimed done but aren't.

3. **Design conformance.** Does the code follow the architecture, key decisions, and required invariants from the design? Are components where the design said they'd be? Were design decisions actually followed, or silently deviated from?

4. **Code integrity.** Slop detection and failure honesty — carried over from the existing audit-implementation command. Abstraction quality (god functions, policy in utilities, parameter sprawl, leaky names). Failure honesty (silent fallbacks on invariant violations, broad excepts, backwards-compat shims). For each finding: `file:line`, what's wrong, what should change.

### Certification mechanics

After evaluation, the agent updates tracking artifacts:

- **Plan:** mark `- [ ]` → `- [x]` for phases verified as complete. Leave unchecked if not verified.
- **Spec:** mark success criteria `- [ ]` → `- [x]` for criteria verified as met.
- **Epic:** if all spec success criteria pass, append ✅ to the item heading and mark the item's success/done-state checkboxes `- [x]`.
- **CURRENT_WORK.md:** update the item's status to "certified" or "needs work — [summary of gaps]".

The agent only marks what it has verified. Partial certification is valid — some checkboxes marked, others left open with findings explaining why.

### Minimal-artifact handling

Not every item goes through the full pipeline. The audit adapts:
- **Plan + spec + design all exist:** full four-area evaluation.
- **Plan + spec, no design:** skip design conformance. Evaluate the other three areas.
- **Spec only, no plan:** evaluate spec conformance and code integrity. No plan-completion check.
- **No spec:** refuse to audit. Audit requires at least a spec to audit against.

## Required Invariants

- Audit never marks a checkbox it hasn't verified. Partial certification is the norm, not a failure.
- Audit writes `audit.md` before updating checkboxes — the assessment is the record, the checkboxes are the consequence.
- Epic-scope audit never re-audits items from scratch. It reads existing `audit.md` files.
- The command prompt fits in ~150–200 lines. The evaluation areas are described, not exhaustively enumerated with sub-questions.

## Component Overview

One component: `claude-pack/commands/_my_audit.md`.

This is a command prompt (markdown instruction file), not application code. There are no classes, modules, or functions to design. The "component" is the prompt itself, which instructs the agent on what to evaluate, how to certify, and what artifacts to produce.

## Non-Goals

- Code quality checks (tests, linting, formatting) — `/_my_pre_pr`.
- Archiving completed work — `/_my_close`.
- Ad-hoc code review without upstream artifacts — audit requires at least a spec.
- Running automated tools or scripts — audit is agent-driven evaluation.

## Implementation Notes

- The command prompt should follow the structure of `_my_audit_implementation` (checklist of evaluation areas) more than `_my_code_review` (heavy staged process). List what to check, describe the report format, explain the certification mechanics. Don't over-scaffold.
- The four evaluation areas in the prompt should be described in 3–5 lines each, not 20. The agent is an LLM — it knows how to verify requirements against code. Tell it *what* to look for, not *how* to look.
- The slop detection and failure honesty descriptions from `_my_audit_implementation:28-58` are already well-written and concise. Port them with minimal changes.
- Epic scope should be a separate section in the prompt, not interleaved with work-item scope. The agent reads the argument and jumps to the right section.
- Codex skill description needed in `codex-overrides/config.sh`. Key: `audit`. Pattern: `"Certify a work item or epic: evaluate code against plan/spec/design, update checkboxes, write audit.md. Use after implementation is complete."`

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent marks checkboxes prematurely (rubber-stamp risk) | High | The invariant "never mark what you haven't verified" is stated explicitly. The audit.md is written first as the evidentiary record. |
| Epic-scope audit misses issues because it trusts item-level audits | Med | Epic scope also reads Source Documents and assesses overall intent — it's not just a checkbox aggregator. |
| Prompt too long despite the succinctness goal | Low | Target 150–200 lines. The current audit-implementation is 77 lines and covers 6 areas. Adding spec/design conformance, certification mechanics, and epic scope roughly doubles it. |

## Integration Strategy

**Replaces:** `_my_audit_implementation.md` (retired after this ships).
**Absorbs from:** `_my_code_review.md` (spec/design conformance — the rest goes to `_my_pre_pr` in Item 6).
**Fits into the pipeline as:**
- `/_my_implement` → `/_my_audit {item}` → `/_my_pre_pr` → `/_my_close {item}`
- All items done → `/_my_audit {epic}` → `/_my_close {epic}`

**Cross-references to update** (in Item 9 cleanup):
- `_my_implement.md:227` references `/_my_project_manage` → should reference `/_my_audit`
- `_my_quick_edit.md:100` references `/_my_code_review` → should reference `/_my_pre_pr`
- `workflow-accountability.md:27` references `/_my_audit_implementation` → should reference `/_my_audit`

## Validation Approach

1. Write the command prompt and verify it's under 200 lines.
2. Invoke `/_my_audit` against a completed item in this repo (e.g., Item 1 or Item 2 from the workflow-v2 epic) and verify it:
   - Reads the upstream artifacts correctly
   - Writes `audit.md` with a clear verdict and findings
   - Updates checkboxes in plan, spec, and epic
   - Updates CURRENT_WORK.md
3. Test epic scope against the workflow-v2 epic (at least Items 1 and 2 are complete).
4. Test the no-design case (an item with only spec + plan).

## Next-Stage Handoff

**Fixed (don't revisit):**
- Four evaluation areas for work-item scope
- Lean report format (verdict + findings, no matrices)
- Certification mechanics (direct markdown editing)
- Epic scope reads existing audits, doesn't re-audit
- Single command file with scope from argument

**Open (plan should address):**
- Exact prompt wording for each evaluation area
- The `audit.md` template (keep it minimal)
- How to word the epic-scope assessment section
- Codex skill description wording

**De-risk first:**
- Write the prompt and test it against a real completed item before iterating on wording.

---

Next Step: After approval → `/_my_plan` or `/_my_implement`
