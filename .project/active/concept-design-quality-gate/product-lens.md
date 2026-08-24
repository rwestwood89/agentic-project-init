## spec — 2026-08-07 — rev `.project/active/concept-design-quality-gate/spec.md`
Point (re-derived): The pipeline must identify and stop work that violates the product’s central promise; downstream stages must not certify a contradiction inherited from upstream framing.   [source: `.project/concepts/anchor-on-the-point.md`, grade: owner/HARD]
Falsifier: The spec permits an owner-grade product contradiction to remain unresolved while the review or downstream pipeline proceeds.
Findings:
- spec-F1 [DON'T] The spec treats ADR 0002’s original four-touch-point map as current and omits live ADR 0005, which explicitly extends that map and governs liveness-versus-authority grading — `.project/adr/0005-product-lens-touch-points-and-grading.md` (agent/ratified) — disposition: DISPOSE-and-proceed; correct the Known Requirement and Related Artifacts citation before design
Gate: DISPOSED (spec-F1)

## spec resolution — 2026-08-07 — rev `.project/active/concept-design-quality-gate/spec.md`
Resolves:
- spec-F1: FIXED — authority: agent/ratified — basis: the Known Requirement and Related Artifacts now carry amended ADR 0002 together with active ADR 0005 and require any new ADR interaction to amend or supersede the applicable live decision openly
Gate: CLEAR
