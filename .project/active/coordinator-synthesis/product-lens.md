## spec — 2026-08-20 — rev `.project/active/coordinator-synthesis/spec.md`

Epic: MENTAL-ALIGN-V2

Point (re-derived): The mental-alignment checkpoint's governing obligation is on-demand, question-led visual reconstruction of the owner's mental model through three independently instructable steps, with a mandatory pause after synthesis where the owner reads, corrects, and chooses the render path. Policy and shape are classified from the request — no flags. The synthesis is the skeleton: high-level logic, narrative, maximum compression. Judgment stays separable from evidence claims.
[source: `.project/concepts/mental-alignment-checkpoint.md` SC1–SC5, SC12–SC13; owner-verbatim quotes on skeleton/meat and no-flags, grade: owner/`[OWNER]`]

Falsifier: The spec would violate the point if it allows the synthesis agent to see a render instruction, omits the mandatory pause, drops the classification-before-spawning requirement, or lets the synthesis be something other than a skeleton (detailed document rather than compressed narrative with pointers).

Findings: none.

Gate: CLEAR

### Observations

1. **Judgment separation** (concept SC5, `[OWNER]`). The synthesis file structure grades the judgment-section content as `[INFERRED]`, but the text is a near-verbatim restatement of the owner's SC5. The obligation is present and enforceable; the `[NEED]`-graded three-region structure already ensures judgment is a mandatory separate section.

2. **Render choice at the pause** (concept SC12, `[OWNER]`). The spec captures the coordinator offering three options at the pause as a `[NEED]` requirement. Since the render paths are Item 4's scope and SC6 guarantees the pause, the choice presentation is adequately covered without its own SC.

### Epic-level reference

The epic_plan product-lens block (gate CLEAR, no findings) stands. Its three observations for spec authors are addressed:
- Observation 1 (starter feedback as explicit deliverable): covered by SC8.
- Observation 2 (unowned proofs — slash resolution): covered by SC7.
- Observation 3 (ADR reference): Item 5's concern.

Forward handoffs from old Item 2's product-lens (spec-F2, spec-F3): spec-F2 is Item 5's scope; spec-F3 is this item's SC7.
