# Spec Review: Session Bookkeeping

**Spec:** `.project/active/session-bookkeeping/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/session-bookkeeping/spec-review.md`
**Date:** 2026-09-10

---

## Reality Check

**Sound, with contract-level concerns.** The spec is about the right work item, its Problem matches the current command and templates, and its core direction follows the owner-grade concept: keep current state in `CURRENT_WORK.md`, put bounded completion history in the CHANGELOG read, and make wrap-up write records rather than documents. Design would not need a new foundation, but it would inherit two false premises and one invented mechanism unless the findings below are resolved.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim:** The measured coverage statement is already stale because it describes the repository before this item's two prerequisites closed. The spec says the newest five CHANGELOG entries span 2025-12-30 to 2026-09-10 and that `CURRENT_WORK.md` has 13 completed entries (`Problem`; *The two CHANGELOG entry weights*). The live files now contain seven CHANGELOG entries, whose newest five end at 2026-07-01, and 15 `Recently Completed` entries (`.project/completed/CHANGELOG.md:7-100`; `.project/CURRENT_WORK.md:124-216`). The important residual still holds: nine completed items have no CHANGELOG counterpart. Ask the spec agent to refresh the counts and describe the trade from the post-prerequisite state that implementation will actually start from.

**L1-2 · Direct claim:** The `[NEED]` at *What wrap-up writes* combines an owner-stated outcome with an agent-chosen git mechanism. The cited concept requires that wrap-up “does not commit without being asked” (`.project/concepts/agent-knowledge-and-enforcement.md`, Success Criterion 7); it does not require wrap-up to stage its writes or show staged state. “It stages what it wrote and shows the owner what is staged” is therefore not supported as `[NEED]`. Keep the no-unasked-commit outcome at owner grade, and move stage-and-show to `[INFERRED]` or leave the mechanism for design unless the owner originated it elsewhere.

**L1-3 · Rewrite request:** The two inherited requirements under *Forced by existing systems* use `[INHERITED: paths]` as the tag. The spec contract requires exactly one vocabulary tag, `[INHERITED]`, with the source cited in the item text (`claude-pack/commands/_my_spec.md:93-106`). Ask the spec agent to normalize the tag while preserving both source paths and the recorded authority.

### Lens 2 — Problem & Approach

**L2-1 · Question to the user:** The Problem says `/_my_wrap_up` “runs every session,” but the workflow only suggests it and ADR 0002 explicitly treats wrap-up as optional (`claude-pack/rules/workflow-accountability.md:30-31`; `.project/adr/0002-adr-touch-points.md`, *Why*). That makes the third Success Criterion stronger than the mechanism: important untracked work cannot be guaranteed to reach boot history when wrap-up is skipped. **Should the contract say “when wrap-up runs, important untracked work reaches boot history,” or do you intend this item to add an automatic/unskippable session-end trigger?** The first matches current scope; the second materially expands it.

### Lens 3 — Pipeline Risk

**L3-1 · Direct claim:** The first Success Criterion contradicts the chosen approach. It requires recent work to appear “without opening `completed/`,” while the mechanism is specifically a read of `.project/completed/CHANGELOG.md`. The product-lens falsifier repeats the same contradiction (`product-lens.md:16`). Ask the spec agent to state the intended outcome precisely, likely that a cold agent gets recent completions through the standard boot read without browsing completed item folders or running `git log`.

**L3-2 · Question to the user:** The spec defers “what `--quick` means afterwards” to design, but `--quick` is user-visible behavior, not an internal mechanism (`Open Questions`; current behavior at `claude-pack/commands/_my_wrap_up.md:9,58`). **Should quick mode remain a CURRENT_WORK-only status refresh, or should it also perform the new CHANGELOG and execution-note record beats?** I recommend keeping it CURRENT_WORK-only because that preserves the option's current promise and keeps “quick” cheap; whichever answer you choose belongs in the spec contract.

**L3-3 · Direct claim:** The requirement that a reader can distinguish the light and structured CHANGELOG weights has no success criterion that would catch its failure (`Known Requirements`, *The two CHANGELOG entry weights*). An implementation could satisfy every listed criterion while using an ambiguous `Type` and otherwise identical visible fields. Add an outcome-level check that the boot excerpt identifies whether an entry came from close or from wrap-up without consulting another file.

### Lens 4 — Hygiene

No material hygiene finding beyond the nonstandard inherited tags in L1-3.

### Lens 5 — Reader Comprehension

No material comprehension finding. The spec is long, but the headings expose the work item, its trade, and the deferred decisions on one pass.

---

## Engagement Summary

**Overall take:** The work item and its central bet are sound, so this needs revision rather than rework. Before design, the spec must stop promising behavior an optional command cannot guarantee, separate the owner's no-commit outcome from the agent's stage-and-show mechanism, and repair the boot-read contradiction.

**Here's what I need you to weigh in on:**

1. **[L2-1]** Decide whether recording untracked work is conditional on running wrap-up, or whether this item must make session-end capture automatic. I recommend the conditional contract.
2. **[L3-2]** Decide whether `--quick` remains CURRENT_WORK-only or also writes the new records. I recommend preserving CURRENT_WORK-only behavior.
3. **[L1-2]** Confirm whether stage-and-show was your own requirement. If not, it must lose `[NEED]` authority and remain a design option.
4. **[L3-1]** Replace “without opening `completed/`” with the real boundary: no browsing completed item folders and no `git log`; the standard boot rule may read the CHANGELOG inside `completed/`.
5. **[L1-1, L3-3]** Refresh the post-prerequisite measurements and add a success check that the two entry weights remain distinguishable.

---

## Resolutions

No findings resolved yet.

---

**Verdict:** Revise
**Next Steps:** Record the owner's resolutions here, then re-run `my-spec` (or return to the spec-agent session) and point it at this review to incorporate. The reviewer does not edit the spec.

---

## Resolutions — 2026-09-10

All five items resolved against the record; none needed a new owner decision.

- **L1-1 — FIXED.** Counts refreshed to the post-prerequisite state: 7 CHANGELOG entries with the newest five reaching back to 2026-07-01, 15 `Recently Completed` entries over 87 lines, `CURRENT_WORK.md` at 241 lines of which 113 are history. The residual the review protected is unchanged: nine completed items have no CHANGELOG counterpart.
- **L1-2 — FIXED, and the reviewer was right that the grade was wrong.** Split in two: `[NEED]` keeps the owner-grade outcome (no commit unless asked, concept SC 7), and stage-and-show moves to `[INHERITED]` citing the epic's Item 3 *In Scope* line (`.project/backlog/epic_knowledge_homes.md:207`), which is where it actually comes from. Not owner-originated, so not `[NEED]`.
- **L1-3 — FIXED.** Both tags normalized to bare `[INHERITED]` with the source paths moved into the item text.
- **L2-1 — RESOLVED as conditional**, the reviewer's recommendation. An automatic session-end trigger is a scope expansion nothing in the concept or epic asks for, and ADR 0002 treats wrap-up as optional on purpose. Success Criterion 3 now reads as a contract for when wrap-up runs, and the Problem states the optionality rather than claiming the command "runs every session."
- **L3-1 — FIXED.** The criterion now names the real boundary: the standard session-start reads alone, no browsing item folders under `completed/`, no `git log`. The bounded read of `completed/CHANGELOG.md` is one of those standard reads, so the contradiction is gone.
- **L3-2 — RESOLVED as CURRENT_WORK-only**, the reviewer's recommendation, promoted out of Open Questions into a `[NEED]`. It preserves the flag's current promise, and a quick mode that wrote records would not be quick. Step renumbering stays deferred to design.
- **L3-3 — FIXED.** New success criterion: reading the boot excerpt alone, without opening another file, tells whether an entry came from `close` or from `wrap_up`.

The design at `.project/active/session-bookkeeping/design.md` was drafted before this review and is refreshed for the same counts and the L3-1 wording. Its decisions already matched the two resolutions above — `--quick` runs state hygiene only (D2), and no automatic trigger is proposed anywhere.

**Verdict after resolutions:** Revise → addressed.
