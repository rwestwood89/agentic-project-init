# Spec: Lean Spec Redesign

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-06-25 16:30 PDT
**Complexity:** MEDIUM
**Branch:** lean-spec-redesign

> Note: this spec is written in the new lean format it proposes. It is the first worked example of the target shape.

---

## Problem

`/_my_spec` produces low-density, over-specified, fixed-size artifacts, and its prose can't fix it because the template's structure causes the problems.

Three structural faults, all visible in `echo-workspace/.project/active/dispatch-comparison-framework/spec.md`:

- **The "why" is asked four times.** Work Item Summary, Why This Matters Now, Business Goals → Why This Matters, and Problem Statement all circle the same facts. Four slots, one idea.
- **"What done looks like" is asked three times.** Success Criteria, Functional Requirements, and Acceptance Criteria are parallel lists of the same outcomes. The Window 2 target appears verbatim in all three (`spec.md:38`, `:100`, `:116`).
- **The FR + RFC-2119 block rewards over-specification.** "Switch between plots" became "dropdown" locked in three places (`:22`, `:96`, `:132`). Nothing in the template asks whether the dropdown is a real constraint or just one way to meet a need.

A fourth fault is posture, not structure: the command casts the agent as a stenographer (*"CAPTURE the user's requirements, NOT invent them"*, `_my_spec.md:11`). A stenographer fills the `## Questions` slot with manufactured questions and never probes deeply. The user wants an investigator: one that uncovers the problem through critical questioning and research, while still not inventing solutions.

Worth doing now because the spec is the entry point to the whole pipeline; a weak spec degrades every downstream stage, and we just finished cleaning up voice, so the prompts are otherwise in good shape.

---

## Success Criteria

What "done" changes:

- [ ] A debug-ticket-sized ask and a large constrained feature produce visibly different-sized specs. Depth tracks the input, not the template.
- [ ] No fact appears in two sections. There is exactly one home for the problem, one for outcomes, one for requirements.
- [ ] Every requirement carries a tag — `[HARD]`, `[NEED]`, or `[INFERRED]` — and `[NEED]` items are phrased as outcomes, not mechanisms.
- [ ] On the dispatch-comparison example, "switch between plots" would be captured as a `[NEED]` outcome, not a locked dropdown.
- [ ] The agent asks questions one at a time, ranked by leverage, each carrying context + options + a defer option. It asks zero questions when nothing is high-leverage.
- [ ] The agent offers targeted research when an open item could hide a `[HARD]` requirement, instead of guessing or asking the user.
- [ ] The spec reviewer (`_my_spec_review.md`) judges against the new posture and the three tags, not the old "did it invent requirements" framing alone.
- [ ] The Codex skill build still produces a valid SKILL.md (description override updated if the purpose line changed).

---

## Known Requirements

### The artifact: a lean core

- **[HARD]** The spec template MUST collapse to five core sections: **Problem**, **Success Criteria**, **Known Requirements**, **Non-Goals**, **Open Questions / Deferred to design**. The redundant sections (Work Item Summary, Why This Matters Now, Business Goals, Problem Statement, separate Acceptance Criteria, Requirement Selection Notes) are removed.
- **[HARD]** Success Criteria and Acceptance Criteria MUST merge into one outcomes list. Outcomes are stated as outcomes; concrete targets (numbers, reproduction checks) stay concrete and testable.
- **[HARD]** Each requirement MUST carry exactly one tag: `[HARD]` (forced by an interface, physics, or existing system), `[NEED]` (a stakeholder/UX/performance outcome, mechanism left open), or `[INFERRED]` (implied by the ask, not stated — kept because it is scannable on review).
- **[NEED]** `[NEED]` items read as outcomes a reader can't mistake for an implementation choice.
- **[NEED]** The artifact scales with the input: a thin ask yields a thin spec (Problem + a success criterion or two is a complete spec); a heavy ask grows the Known Requirements catalog. No tier/mode selection.

### The posture: aggressive about the problem, conservative about the solution

- **[HARD]** The command MUST replace the "capture, don't invent" framing with: probe, research, and classify honestly to uncover the problem; do not commit to solutions the user didn't ask for. Uncovering the problem is encouraged; inventing the solution is not.

### The questioning loop (replaces the fixed `## Questions` slot)

- **[HARD]** Questions MUST be asked one at a time, in prose, not via the multiple-choice tool and not as a batch slot in the artifact.
- **[HARD]** The agent MUST rank open items by leverage (how much the answer changes the spec × how uncertain it is) and ask only high-leverage items. If nothing is high-leverage, it asks nothing.
- **[HARD]** Each question MUST follow the "presenting a decision" shape already in `claude-pack/rules/working-voice.md`: situation, options and their costs, a recommendation when the agent has one, and an explicit "or defer to design" option.
- **[HARD]** After each answer the agent MUST re-rank: resolved items drop, new items raised by the answer are added.
- **[HARD]** "Defer" MUST file the item into Open Questions / Deferred to design. Deferral is lossless, not a drop.
- **[NEED]** Investigate the request and light context before questioning, so questions are informed rather than generic.

### Research offer

- **[HARD]** When an open item could be answered by code or data (a hidden interface constraint, existing behavior, a physical limit), the agent MUST offer targeted investigation to surface `[HARD]` requirements, rather than guessing or asking the user to supply what the code already knows.

### Prose budget

- **[NEED]** The rewrite removes guardrail prose that the new structure makes redundant (the long MUST/MUST-NOT lists begging the agent not to repeat itself or over-specify). Structure enforces; prose explains.
- **[INFERRED]** One or two short worked examples (a one-line bug spec, a fuller constrained spec) anchor "fill only what's load-bearing" better than more rules.

---

## Non-Goals

- **Designing the spec → design split.** Splitting product/UX design from technical design is the next work item. This spec only makes the spec comfortable leaving usability under-specified; it does not build the downstream stage.
- **Changing `_my_design.md` or later pipeline commands.** Out of scope beyond what the spec hand-off requires.
- **A generalized "critical questioning" method shared across commands.** The loop lives in the spec command for now. Generalizing later is possible but not in scope.
- **Tiered specs / separate ticket command.** Rejected in favor of adaptive depth.

---

## Open Questions / Deferred to design

- **Exact section ordering and headers in the template.** The five sections are settled; their precise titles and order are a design-stage call.
- **How worked examples are embedded.** Inline in the command, a sibling reference file, or an appendix — defer.
- **How far the reviewer changes.** Whether `_my_spec_review.md` needs new lenses or just amended existing ones (Faithfulness, Pipeline Risk) is for the design/draft step to determine against the actual reviewer text.
- **Whether the "investigate before questioning" step needs a depth cap** so the agent doesn't over-research a trivial ticket. Likely yes; mechanism deferred.

---

## Related Artifacts

- **Command under revision:** `claude-pack/commands/_my_spec.md`
- **Reviewer to update:** `claude-pack/commands/_my_spec_review.md`
- **Voice rule reused by the questioning loop:** `claude-pack/rules/working-voice.md`
- **Evidence exhibit (the problem):** `echo-workspace/.project/active/dispatch-comparison-framework/spec.md`
- **Codex build path:** `dist/codex/skills/my-spec/SKILL.md` via `scripts/build-codex-pack.sh`

---

**Next Steps:** Draft the changes to `_my_spec.md` and `_my_spec_review.md` against this spec.
