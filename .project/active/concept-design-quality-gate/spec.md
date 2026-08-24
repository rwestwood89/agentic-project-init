# Spec: Concept-Design Architectural Quality Gate

**Status:** Implemented — pending independent audit (2026-08-07)
**Owner:** Reid W
**Created:** 2026-08-07 16:10:02 PDT
**Complexity:** HIGH
**Branch:** anchor-on-the-point

---

## Problem

`my-concept-design` is where the pipeline makes its largest architectural choices: the
system boundaries, responsibility split, core model, invariants, and architectural bets
that later become an epic and several item-level designs. The command asks its author to
self-review those choices, then presents them for owner approval. There is no fresh,
skeptical review before `my-epic-plan` turns that system shape into downstream work.

That missing gate rewards a recurring failure mode: an agent treats the existing pipeline
or implementation as fixed, adds mechanisms around a semantic defect, and then uses
compatibility evidence to prove that the enlarged system faithfully preserves the defect.
The current concept-design instruction strengthens this bias by resolving every mismatch
between the document and code in favor of the code. Current behavior should be evidence.
It is not proof that the current architecture or semantics are correct.

**[REFERENT] Owner-designated agent diagnosis, quoted verbatim:**

> Yes. Item 4 is not an isolated mistake. It is the same architectural behavior repeated:
>
> 1. Encounter a semantic gap.
> 2. Preserve the existing pipeline as an unquestioned constraint.
> 3. Add a mechanism that compensates for the gap.
> 4. Add adapters so the new mechanism coexists with old mechanisms.
> 5. Add tests proving compatibility and byte stability.
> 6. Document the enlarged system as intentional architecture.
> 7. Call the resulting PR a refactor even though little or nothing was removed.
>
> That is how a library ends up with VBR, virtual usages, supplied-value synthesis, a 21-form resolver, group backfill,
> multiple occurrence walkers, consumer-local minting, and now a proposed identity manifest. Each PR made local behavior more
> explicit while making the overall semantic model worse.
>
> The worst part is that the large reviews increased confidence. They proved that enormous rewrites preserved the existing
> output. But the existing output already encoded the defect. “Byte-identical” and “zero regression” became mechanisms for
> protecting broken semantics.

The pipeline needs concept design to make fewer, better, visible architectural decisions.
It then needs an independent architecture review before those decisions become inherited
context. This is a different check from the product lens: the product lens asks whether the
work serves the product's purpose; concept-design review asks whether the proposed software
architecture uses the right abstractions, boundaries, and invariant ownership to solve the
problem. Internal coherence, compatibility, preservation evidence, and product alignment
cannot by themselves establish architectural quality.

## Success Criteria

- [x] `my-concept-design` centers its work on the few load-bearing architectural decisions
  that determine boundaries, responsibility, invariant ownership, and system semantics.
- [x] Concept design evaluates whether the semantic gap should be removed or repaired at
  its source before proposing compensating mechanisms, adapters, parallel representations,
  or compatibility layers.
- [x] Every decision that appears to meet the ADR density bar is visibly flagged before
  acceptance with enough information to review the decision, its reason, affected seams,
  and provenance. A concept with no ADR candidates says so explicitly.
- [x] A fresh, separate `my-concept-design-review` pressure-tests the completed concept
  before `my-epic-plan` or downstream specification work inherits its architecture. It is
  not folded into concept design's authoring loop or treated as another product-lens pass.
- [x] The review leads with and answers, “Are we actually solving the right problem?” It
  can require rework even when the concept is internally consistent, maps accurately to
  current code, aligns with product purpose, and passes every detailed rubric check.
- [x] Every concept-design review spawns a fresh subagent in the ponytail role. That
  subagent returns a written architectural challenge, the reviewer uses it as input to the
  review, and the review visibly dispositions it. The pass cannot be omitted or silently
  reduced to a checklist item.
- [x] The new command and pipeline relationship are available in both shipped Claude and
  Codex surfaces, including the autonomous pipeline path, with generated-product and
  pipeline synchronization checks covering the addition.

## Known Requirements

- **[NEED]** Make `my-concept-design` genuinely focus on high-quality architectural
  decisions. (Owner, 2026-08-07.)
- **[NEED]** Flag the ADRs that would result from the concept-design decisions while those
  decisions are still being shaped and reviewed. (Owner, 2026-08-07.)
- **[NEED]** Add a separate `my-concept-design-review`, rather than an in-stage check, to
  pressure-test whether the concept uses good software architecture to solve the right
  problem. This review evaluates architecture quality; the product lens separately
  evaluates fidelity to product purpose. (Owner resolution L2-1, 2026-08-07.)
- **[NEED]** Every concept-design review must spawn a fresh subagent in the ponytail role
  to be extremely critical of the architecture. It returns a written challenge that the
  reviewer consumes as input to the review document. This reuses ponytail's role and
  attitude; it does not change `my-ponytail` from a session mode into a review command.
  (Owner resolutions L3-1 and L3-2, 2026-08-07.)
- **[NEED]** The seven-step failure pattern and its byte-stability warning in the Problem
  section are the acceptance referent for the new authoring and review behavior. (Owner,
  2026-08-07.)
- **[INHERITED]** Owner-originated decisions may be marked settled. An agent-originated
  architectural recommendation remains `[AGENT]` after owner ratification and must remain
  challengeable against its recorded reasoning. (`claude-pack/rules/capture-fidelity.md`,
  “The settled rule.”)
- **[INHERITED]** Only load-bearing decisions that a future agent would plausibly
  re-derive incorrectly or relitigate receive ADRs. Routine choices and facts visible from
  code do not. (`.project/adr/README.md`, “What gets an entry.”)
- **[INHERITED]** Amended ADR 0002 and active ADR 0005 together define the current
  decision-record touch-point map: 0002 retains the acceptance/close write discipline,
  while 0005 adds product-lens reads and intended-contract-change writes at later stages.
  If the new review creates another ADR interaction, the design must challenge and
  explicitly amend or supersede the applicable live decision rather than silently extending
  the map. (`.project/adr/0002-adr-touch-points.md`;
  `.project/adr/0005-product-lens-touch-points-and-grading.md`.)
- **[INHERITED]** Prior research rejected another review stage as the primary repair when
  the reviewer consumes the same narrowed artifacts and inherits their oracle. This work
  must not claim success from stage presence alone. The new gate instead rests on a fresh,
  independent architecture review and a real written ponytail challenge; it does not claim
  that another product-lens pass proves architectural quality.
  (`.project/research/20260803-210317_pipeline-product-truth-control-review.md`,
  “Add another review stage.”)
- **[INFERRED]** ADR candidates are proposals, not settled records. The review must be able
  to reject or reshape them before acceptance; filing preserves the true source grade and
  follows the existing append-only ADR lifecycle.
- **[INFERRED]** Concept design must treat code, existing pipelines, research, tests, and
  compatibility baselines as evidence rather than unquestioned constraints. Before it
  accepts compensating machinery, it examines the root semantic model, the component that
  should own the invariant, and the option of deleting or replacing existing behavior.
  Preservation evidence establishes stability, not semantic correctness.
- **[INFERRED]** The mandatory ponytail challenge asks whether the work needs to exist,
  whether machinery can be deleted, whether the repair belongs upstream, and whether the
  proposed architecture is the smallest system that owns the invariant correctly. A small
  patch at the wrong semantic layer is not a passing result.
- **[INFERRED]** `my-concept-design-review` is paired with concept design and runs in a
  fresh context before epic decomposition. It reviews the cross-item system shape, not the
  later per-item details owned by `my-design-review`.
- **[INFERRED]** A failed “right problem” judgment or unresolved high-authority conflict
  blocks progression. Detailed rubric scores cannot average it away.

## Non-Goals

- Guaranteeing that every architectural decision will be correct.
- Turning concept design into a detailed work-item spec, implementation plan, or per-item
  technical design.
- Duplicating `my-design-review`'s later review of one item's detailed interfaces and
  implementation-facing design.
- Recording every design choice as an ADR or lowering the existing ADR density bar.
- Rejecting compatibility requirements categorically. The review requires their semantic
  justification; it does not assume preservation is wrong.
- Adding a generic approval stage whose reviewer inherits the concept's framing and merely
  checks its internal consistency.

## Open Questions / Deferred to design

- How should concept design display ADR candidates so they are easy to pressure-test
  without filing them prematurely or bloating the main concept?
- At what exact acceptance transition are reviewed ADR candidates filed, and how are
  rejected or reshaped candidates kept out of the durable log?
- How should Claude and Codex reuse the existing ponytail role and rules in a
  result-returning subagent while leaving the current ponytail session mode unchanged?
- What context should the ponytail subagent receive, and in what order, so it understands
  the real problem without inheriting the concept's proposed mechanisms as truth?
- Where should the sibling concept-design review artifact live, and how should it record
  owner resolutions without conflating architecture findings with the product-lens ledger?

---

## Related Artifacts

- **Concept-design command:** `claude-pack/commands/_my_concept_design.md`
- **Concept-design review command:** `claude-pack/commands/_my_concept_design_review.md`
- **Existing detailed-design review:** `claude-pack/commands/_my_design_review.md`
- **Ponytail mode:** `claude-pack/commands/_my_ponytail.md`
- **Product-lens specification:** `claude-pack/scripts/product-lens.md`
- **Product-lens ledger:** `.project/active/concept-design-quality-gate/product-lens.md`
- **Spec review:** `.project/active/concept-design-quality-gate/spec-review.md`
- **ADR convention:** `.project/adr/README.md`
- **Relevant decisions:** `.project/adr/0002-adr-touch-points.md` (amended) and
  `.project/adr/0005-product-lens-touch-points-and-grading.md` (amended), plus
  `.project/adr/0006-concept-design-review-adr-touch-point.md` (active, agent-grade)
- **Research:** `.project/research/20260803-210317_pipeline-product-truth-control-review.md`
- **Related concept:** `.project/concepts/anchor-on-the-point.md`
- **Design:** Skipped by owner instruction on 2026-08-07; implementation proceeded directly
  from this reviewed spec.

---

## Implementation Notes

- Added a separate concept-design architecture review with a mandatory, result-returning
  ponytail-role subagent at ultra intensity.
- Refocused concept design on root semantic ownership, deletion before compensation,
  explicit load-bearing decisions, and pre-acceptance ADR candidates.
- Wired the paired stage through the canonical pipeline, Claude/Codex installation,
  autonomous orchestration, user docs, generated Codex skills, and focused structural tests.
- Refreshed the global Claude symlinks and installed the rebuilt Codex skills/scripts.
- Amended the live ADR touch-point map with agent-grade ADR 0006. Review reads relevant
  live records but never files candidates; final concept acceptance remains the write point.
- Validation passed: focused quality-gate checks, pipeline sync, Codex orchestrator pack,
  ADR suite (25/25), docs, global install, project init, rename, and uninstall suites.

---

**Next Steps:** Run `my-audit` in a fresh session.
