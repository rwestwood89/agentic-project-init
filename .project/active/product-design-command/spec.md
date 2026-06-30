# Spec: Product Design Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-06-29 11:40 PDT
**Complexity:** LOW
**Branch:** product-design-command

---

## Problem

The lean spec redesign deliberately leaves UX and usability under-specified — `[NEED]` items are phrased as outcomes, and mechanism questions land in Open Questions. That's the right call: the spec captures the problem, not the solution. But when the work item has a significant UX surface (a data visualization viewer, an interactive dashboard, a CLI with complex output), there's a gap between "the user can switch between plotted views" and a technical design that knows *what* to build.

Right now that gap gets closed in one of two places, both wrong:

- **In the spec** — the agent locks a dropdown or a layout as a `[HARD]` requirement. This is exactly the over-specification failure the lean redesign fixed.
- **In `_my_design`** — the technical design agent makes experience decisions as an afterthought while planning modules and data flows. It's not thinking from the consumer's perspective; it's thinking from the code's perspective.

Neither stage is designed to do the work of thinking through how someone actually interacts with the thing — whether that's a user navigating a dashboard, a developer calling an API, or an engineer reading CLI output. What do they need to see, do, or understand — and what interface serves that?

## Success Criteria

- [ ] A new `/_my_product_design` command produces `.project/active/{feature-name}/product-design.md`.
- [ ] When used, `_my_design` reads `product-design.md` alongside `spec.md` and treats its UX decisions as settled input (flagging only where a technical constraint conflicts).
- [ ] The command is optional — work items without a UX surface skip it entirely; the pipeline doesn't break.
- [ ] On the dispatch-comparison example, the product design would resolve "the user can switch between plotted views" into a concrete interaction decision (tabs? dropdown? side-by-side?) with reasoning, before technical design begins.
- [ ] `_my_spec.md` mentions `/_my_product_design` as an optional next step for UX-heavy items.

## Known Requirements

- **[HARD]** The command MUST be a new file `claude-pack/commands/_my_product_design.md`. It does not replace or merge with `_my_concept_design` (which is about architecture, lives in `.project/concepts/`, and serves a different purpose).
- **[HARD]** The output MUST live at `.project/active/{feature-name}/product-design.md` — a sibling to `spec.md`, so `_my_design` can find and read it.
- **[HARD]** The command MUST read `spec.md` as input, specifically the `[NEED]` items and Open Questions that are UX-relevant. It picks up where the spec left off.
- **[HARD]** `_my_design.md` MUST be updated to check for and read `product-design.md` when it exists, treating its UX decisions as settled input for the technical design.
- **[HARD]** `_my_spec.md` MUST be updated to mention `/_my_product_design` as an optional step for UX-heavy items (in the Next Steps and Related Commands sections).
- **[NEED]** The agent thinks from the consumer's perspective, not the code's. "Consumer" is whoever interacts with the surface being designed: an end user of a dashboard, a developer calling an API, an engineer reading CLI output. The agent should establish who the consumer is early and hold that perspective throughout.
- **[NEED]** The command uses the same questioning method as the spec: one question at a time, ranked by leverage, lossless defer. But the questions are about experience — what the consumer is trying to accomplish, what information or interface serves them, what interactions or conventions feel natural — not about system internals.
- **[NEED]** The artifact is lean, like the spec. Depth tracks the UX surface: a simple CLI output might be a few interaction decisions; a complex dashboard gets a fuller treatment.
- **[INFERRED]** The Codex skill build needs a description override in `codex-overrides/config.sh` and a `dist/` rebuild.
- **[INFERRED]** The artifact should be structured around the consumer's experience (workflows, information architecture, interaction decisions, API ergonomics), not around system components.

## Non-Goals

- **Visual design.** This is interaction/interface design, not pixel-level styling, branding, or color palettes.
- **User research / personas.** The user knows who the consumer is. The product design works from that context, not from personas.
- **Changing `_my_concept_design`.** That command is about architecture and is the strongest artifact in the pipeline per the alignment research. Leave it alone.
- **A product design reviewer.** Not in this scope. If it's needed, it can be added later.

## Open Questions / Deferred to design

- **Exact artifact sections.** The spec says "structured around the user's experience" — the command prompt should define what sections serve that. Likely: user goals, workflows/journeys, information architecture, interaction decisions, edge cases. But the exact shape is a design-stage call.
- **How much codebase investigation the agent should do.** It needs to know what data is available to present and what existing UI patterns exist, but it's primarily a UX exercise. The depth of investigation is a prompt-design question.
- **Whether product design decisions can be challenged by `_my_design`.** My assumption: product design decisions are settled for `_my_design`, but design should flag genuine technical infeasibility. The exact language for that relationship is a prompt-design call.

---

## Related Artifacts

- **Spec command (updated in this work):** `claude-pack/commands/_my_spec.md`
- **Design command (updated in this work):** `claude-pack/commands/_my_design.md`
- **Concept design command (NOT changed):** `claude-pack/commands/_my_concept_design.md`
- **Pipeline alignment research:** `.project/research/20260419-081514_artifact-pipeline-alignment-review.md`
- **Lean spec redesign (predecessor):** `.project/active/lean-spec-redesign/spec.md`
- **Codex build config:** `codex-overrides/config.sh`

---

**Next Steps:** After approval, draft the command prompt and the updates to `_my_spec.md` and `_my_design.md`.
