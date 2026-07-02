# Spec: Audit Certification

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** HIGH
**Branch:** workflow-v2

---

## Problem

The current post-implementation audit (`/_my_audit_implementation`) only evaluates code against the plan. It checks whether plan phases are complete and flags slop, but it never traces back to the spec, design, or epic. Spec and design conformance lives in a separate command (`/_my_code_review`), tangled with code quality checks that have nothing to do with conformance.

The result: three things stay broken.

- Plan checkboxes, spec success criteria, and epic item status never get marked off. An agent finishes implementing, but the tracking artifacts still show everything unchecked.
- Conformance (does the code match what was specified?) and quality (is the code clean?) are fused in one command. They're different jobs at different points in the lifecycle.
- There's no way to certify an entire epic — no command reviews all items and checks them against the original shaping-tier intent.

## Success Criteria

- [ ] `/_my_audit {item}` evaluates code against plan, spec, and design; updates plan phase checkboxes, spec success criteria, and epic item status; writes `audit.md` in the work item directory
- [ ] `/_my_audit {epic}` reviews all items in the epic and assesses against the epic's Source Documents; certifies epic-level success criteria
- [ ] Old `_my_audit_implementation.md` is retired (replaced by `_my_audit.md`)
- [ ] CURRENT_WORK.md is updated with certification status after audit completes

## Known Requirements

### Invocation and naming

- **[HARD]** Command file is `_my_audit.md`, replacing `_my_audit_implementation.md`.
- **[HARD]** Two invocation scopes: work-item (`/_my_audit {item}`) and epic (`/_my_audit {epic}`).

### Work-item scope

- **[NEED]** Evaluates code against the full upstream chain: plan phases, spec requirements and success criteria, design decisions and architecture.
- **[NEED]** Updates tracking artifacts after evaluation: marks plan phase checkboxes, marks spec success criteria, updates epic item status (if the item belongs to an epic).
- **[NEED]** Writes `audit.md` artifact in the work item directory (`active/{item}/audit.md`).
- **[NEED]** Updates CURRENT_WORK.md with certification status — either "certified" or "needs work" with a summary of gaps.

### Epic scope

- **[NEED]** Reviews all items in the epic, checking that each has been individually certified.
- **[NEED]** Assesses the epic's deliverables against its Source Documents (concept, concept-design, research files) — does the implemented work fulfill the original shaping-tier intent?
- **[NEED]** Certifies epic-level success criteria.

### Absorbed responsibilities

- **[NEED]** Absorbs spec conformance from `_my_code_review`: requirements traceability — did the code implement what the spec requires?
- **[NEED]** Absorbs design conformance from `_my_code_review`: design decision verification — did the code follow the approved architecture, decisions, and invariants?
- **[NEED]** Slop detection stays in audit — abstraction quality, failure honesty, and design-conformance-level code checks. Pre-PR owns automated quality (tests, linting, formatting), not the judgment calls about whether abstractions are justified or fallbacks are hiding bugs.

### Prompt constraints

- **[NEED]** The command prompt must be succinct. The current `_my_code_review` (467 lines) is too verbose — too many sub-questions, heavy templates, traceability matrices. Audit should keep the evaluation scope (what to check) but pare back the scaffolding (how to report it). A good command prompt is short enough to read in one pass.

## Non-Goals

- Code quality checks (tests, linting, formatting, pattern violations, slop detection) — that's `/_my_pre_pr`.
- Archiving completed work to `completed/` — that's `/_my_close`.
- Evaluating code that skipped the pipeline entirely (ad-hoc changes with no spec or plan) — audit requires upstream artifacts to audit against.

## Open Questions / Deferred to design

- **Minimal-artifact items.** Some work items skip product-design or even design (quick edits, small fixes). Audit needs a graceful path when only a subset of upstream artifacts exist — plan + spec at minimum, design optional. The exact behavior when artifacts are missing is a design decision.
- **Report structure.** The current `_my_code_review` has an exhaustive report template (traceability matrices, test coverage tables, severity-graded issues). The new audit needs something leaner that matches the prompt-succinctness constraint. What the report looks like is a design question.
- **Epic-scope orchestration.** How does epic-scope audit review multiple items? Sequential subagents, one long pass, or something else? Design decision.
- **Checkbox update mechanism.** The agent directly edits markdown files to toggle checkboxes. The exact format (how to locate and update checkboxes across plan, spec, and epic files) is a design detail.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_workflow_v2.md` — Item 4
- **Required Reading:** (epic predates Required Reading format — Source Documents serve as upstream context)
  - README_v2 artifact: `https://claude.ai/code/artifact/9a7e2b06-4412-4e44-9c84-b3fc17b7544a`
  - Handoff: `/tmp/handoff-20260630-165453.md`
- **Existing command being replaced:** `claude-pack/commands/_my_audit_implementation.md`
- **Existing command being partially absorbed:** `claude-pack/commands/_my_code_review.md`
- **Design:** `.project/active/audit-certification/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
