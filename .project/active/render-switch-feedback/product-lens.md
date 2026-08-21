Epic: MENTAL-ALIGN-V2

## spec — 2026-08-20 — rev `.project/active/render-switch-feedback/spec.md`

Point (re-derived): The render step's governing obligation is threefold: (1) the HTML inherits the synthesis narrative and adds a second detail layer using what HTML can do — visuals, disclosure, color — and must never restate the synthesis in a different format; (2) the owner chooses at the mandatory pause between resumed agent, fresh agent, or both on one synthesis for a side-by-side comparison measured on wall-clock time, tokens (when available), and the owner's read of quality; (3) two feedback bodies (synthesis, HTML) across two tiers (shared starter, project-local), with new feedback landing project-local first, manual promotion targeting the shared file, and copy-install promotion failing closed.
[source: `.project/concepts/mental-alignment-checkpoint.md` SC3, SC5, SC6, SC7, SC12; owner-verbatim on skeleton/meat, execution shapes, feedback; grade: owner/`[OWNER]`]

Falsifier: The spec would violate the point if it allows the render to reproduce the synthesis verbatim in an HTML wrapper, omits either render path, drops the owner's choice at the pause, or lets new feedback land directly in the shared file.

Findings: none.

Gate: CLEAR

## design_review — 2026-08-20 — rev `.project/active/render-switch-feedback/design.md`

Point (re-derived): After the mandatory synthesis pause, the owner must be able to choose a resumed render, a fresh render, or both against the same corrected synthesis while the run continues to honor any source restriction; each result and its wall-clock, available-token, quality, and feedback attribution must remain distinguishable, with new feedback project-local and shared promotion owner-initiated.   [source: `.project/concepts/mental-alignment-checkpoint.md` SC4, SC7, SC12 and "Two Execution Shapes, Switched and Compared", grade: owner]
Falsifier: An owner requests a clean-room comparison, but a render reads excluded repository material, or the two HTMLs/readings/feedback cannot be attributed to their producing path.
Findings:
- design_review-F1 [DO] Carry the owner's clean-room source restriction through the render step; D9 leaves that obligation unsettled while B2 and the render brief permit following pointers into the repository. — `.project/concepts/mental-alignment-checkpoint.md` "Context Policy, Classified From the Request" and SC4 (owner) — disposition: BLOCK
- design_review-F2 [DON'T] Do not make runtime-neutral authored prose own cross-runtime correctness under superseded ADR 0010; D13, the sibling-reference invariant, and Implementation Notes contradict live ADR 0011, which assigns recursive translation of every skill file to the Codex adapter. This fires smell 7, "The proposed solution changes who owns an invariant without saying so," and must lead the design-review judgment. — `.project/adr/0011-native-skill-codex-adapter.md` (owner) — disposition: BLOCK
Gate: BLOCKED (design_review-F1, design_review-F2)
