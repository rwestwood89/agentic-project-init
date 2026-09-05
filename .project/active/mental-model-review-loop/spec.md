# Spec: Mental-Model Review Loop

**Status:** Complete
**Owner:** Reid W
**Created:** 2026-09-05
**Complexity:** LOW
**Branch:** mental-model-reviewer

---

## Problem

The reviewer currently follows a prescribed checklist and runs once. In the first live run, the review found problems, the writer revised the artifact, and violations still reached the coordinator's accepted version. Adding more checklist procedure would repeat the mistake. The agents need clear responsibilities and an iterative review loop whose continuation is judged by the coordinator.

## Success Criteria

- [x] The reviewer prompt states the review outcome and responsibility without prescribing a checklist or review procedure.
- [x] After each review, the coordinator decides whether another writer-and-reviewer cycle is needed.
- [x] When another cycle runs, the original writer receives a coordinator-authored fixing prompt that references the review, revises the artifact, and can receive another review.
- [x] The coordinator can continue despite a favorable review or stop when another cycle would not improve the artifact.

## Known Requirements

- **[NEED]** The writer owns the artifact and remains the only agent that revises it.
- **[NEED]** The reviewer owns producing a useful review that identifies all issues and violations it finds against the writer's prompt and feedback so the original writer can address them.
- **[NEED]** The coordinator remains accountable for artifact quality, reads the artifact and review, and decides whether another cycle runs.
- **[NEED]** The coordinator decides what its fixing prompt says from the context it already has; the skill prescribes only that the prompt references the review.
- **[INHERITED]** The loop applies to the synthesis and each render, and the reviewer receives no sources or conversation. Source: `.project/active/mental-model-reviewer/spec.md`.

## Non-Goals

- Adding mechanical checks, review checklists, prescribed reading passes, or a note quota.
- Prescribing how the coordinator evaluates the review or what its fixing prompt says.
- Changing the synthesis and visualization rules or the feedback entries.
- Making the reviewer the gate or the sole stopping authority.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2, amends Item 6)
- **Required Reading:** `.project/concepts/mental-alignment-checkpoint.md`; `.project/adr/0012-mental-model-prompt-feedback-split-and-reviewer.md`; `.project/active/mental-model-quality-ownership/change.md`
- **Predecessor spec:** `.project/active/mental-model-reviewer/spec.md`
- **Product lens:** `.project/active/mental-model-review-loop/product-lens.md`

---

**Implemented:** 2026-09-05. The owner waived design and plan artifacts for this prompt-only change. Authored and generated Codex prompts updated; `test_codex_orchestrator_pack.sh`, `test_docs.sh`, and `git diff --check` pass.
