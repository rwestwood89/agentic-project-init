# Design Review: Render + Switch + Feedback (Claude)

**Design:** `.project/active/render-switch-feedback/design.md`
**Spec:** `.project/active/render-switch-feedback/spec.md`
**Review File:** `.project/active/render-switch-feedback/design-review.md`
**Date:** 2026-08-20
**Status:** Final — findings dispositioned

---

## The Point

After the mandatory synthesis pause, the owner chooses a resumed render, a fresh render, or both
against the same corrected synthesis. The HTML keeps the synthesis's narrative and adds detail through
the visual medium. It does not restate the markdown in an HTML wrapper. Any source restriction continues
through the render. Each HTML, its available measurements, the owner's quality assessment, and its
feedback remain attributable to the path that produced it. New feedback lands project-local first, and
only the owner initiates promotion to a shared feedback file.

[source: `.project/concepts/mental-alignment-checkpoint.md` SC3, SC4, SC7, SC12 and Owner's Words;
grade: owner / `[OWNER]` and `[OWNER-VERBATIM]`]

## Fundamental Assessment

**Assessment: Fail. Rework before implementation.**

This is the right piece of work. Item 3 stops at the exact seam this item needs to continue, and the
design's central shape is appropriately small: one synthesis, two optional render paths, and feedback
stored in two existing tiers. The directory-skill placement and filename-stem pairing also match the
current system.

The design is not a usable implementation contract yet. The independent product lens returned two
owner-grade BLOCK findings. It also fired structural smell 7: the design changes who owns an invariant
without carrying the change honestly. That tripwire controls this review even though the core feature is
sound.

### DR-1: Clean-room behavior is unresolved while the render brief permits repository reads

The owner uses clean room to prevent excluded or stale material from influencing the result. The design
recognizes the conflict, recommends carrying the restriction forward, but leaves D9 unsettled
(`design.md:185-186,211-218`). At the same time, B2, D6, and the render flow tell the renderer to follow
the synthesis's pointers into the repository without restriction (`design.md:138-141,173-176,243-245`).

That is not a mechanism detail. It decides whether the run honors the owner's source boundary. The
product lens recorded this as `design_review-F1` with an owner-grade BLOCK.

**Recommendation:** Make clean-room scope a run-wide invariant. The render agent may follow a synthesis
pointer only when its target is within the owner's allowed sources. State the resulting evidence limit in
the HTML. If the design wants broader render discovery instead, take that premise conflict to the owner
before continuing.

### DR-2: Cross-runtime ownership rests on a superseded ADR

The design says ADR 0010 is active and uses it to require runtime-neutral Steps 5–9 and sibling files
(`design.md:31-32,203-209,298-299,345-347`). ADR 0010 is superseded. Active owner-grade ADR 0011 assigns
translation of every skill-directory file to the Codex adapter and explicitly permits Claude-native
phrasing (`.project/adr/0011-native-skill-codex-adapter.md:15-22,54-63`).

The design therefore assigns cross-runtime correctness to authored prose when the current platform
decision assigns it to the adapter. This is the product lens's `design_review-F2` and one instance of
structural smell 7. The ledger gate is BLOCKED.

**Recommendation:** Re-read ADR 0011 and re-derive D13, the sibling-file invariant, the Component
Overview, Non-Goals, Implementation Notes, and handoff. Use precise Claude-native coordinator language
where it helps. Record any required Codex translation as Item 5 adapter work. Runtime-neutral wording may
remain where it is naturally clearest, but it is no longer an invariant or compatibility mechanism.

### DR-3: The correction fallback contradicts the stated ownership boundary

The spec requires the coordinator to pass a correction to the synthesis agent, which updates the saved
synthesis (`spec.md:103-113`). The existing coordinator says it does not write synthesis content
(`claude-pack/skills/_my_mental_model/SKILL.md:8-10`). The design keeps that boundary in one paragraph,
then gives the coordinator authority to edit the synthesis and its frontmatter when the agent is gone
(`design.md:231-233,263-275`).

Calling the edit transcription does not remove authorship or resolve the contradiction. This is a second
instance of structural smell 7 and a direct conflict with an owner-resolved spec requirement.

**Recommendation:** Keep synthesis-content ownership with an agent. If the original synthesis agent
cannot be resumed, either stop and offer a fresh synthesis-editor agent with the owner's exact correction,
or ask the owner how to proceed. The coordinator should not silently become a synthesis author.

---

## Dimensional Review

Not performed. The design-review contract requires the review to stop at Stage 0 when an owner-grade
product contradiction is unresolved or a structural smell fires. No dimensional pass is implied.

---

## Issues by Severity

### Critical

- **DR-1 / `design_review-F1`:** Clean-room source restrictions do not yet govern rendering.
- **DR-2 / `design_review-F2`:** The design contradicts active ADR 0011 and assigns cross-runtime
  correctness to the wrong owner.
- **DR-3:** The coordinator correction fallback takes ownership of synthesis content contrary to the
  spec and the design's own boundary.

### Major

- Not assessed because the review stopped at Stage 0.

### Minor

- Not assessed because the review stopped at Stage 0.

---

## Recommendations

1. Settle clean-room rendering as a run-wide source restriction or obtain an explicit owner override.
2. Rebase all cross-runtime decisions on active ADR 0011 and remove ADR 0010 as binding authority.
3. Remove coordinator-authored synthesis correction. Define a fresh-agent or explicit-stop fallback.
4. Re-run `my-design-review` after the revised design resolves all three issues. The detailed dimensions
   should be reviewed only then.

---

## Resolutions

- **DR-1 / `design_review-F1` — Owner override, 2026-08-20.** Clean room constrains the synthesis by
  default, not the render. Rendering defaults to fresh exploration so the render agent can add the
  detail layer. At the checkpoint, the owner may override that default and require the renderer to keep
  the synthesis's source restriction. The design must make the default and override visible when it
  presents the render choice.

- **DR-2 / `design_review-F2` — Existing owner decision controls.** Active ADR 0011 supersedes ADR 0010.
  The revised design must assign cross-runtime translation to the Codex adapter and remove ADR 0010 as
  binding authority. This needs no new owner decision.

- **DR-3 — Owner decision, 2026-08-20.** The original synthesis subagent performs synthesis
  corrections. The design's unavailable-agent correction fallback is not a second supported path. If a
  runtime failure makes that agent unavailable during the checkpoint, the coordinator reports the
  failure and stops. It does not edit the synthesis or delegate the correction to a different agent.

---

**Overall:** Rework

**Next Steps:** Re-run `my-design` or return to the design-agent session and point it at this finalized
review. The reviewer does not edit the design.
