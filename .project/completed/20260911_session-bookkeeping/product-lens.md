# Product-Lens Ledger: session-bookkeeping

Append-only. Each block is one product-lens run, in the format of `claude-pack/scripts/product-lens.md` §3. Never edit a prior block; a changed gate is a new dated block.

---

## spec — 2026-09-10 — rev .project/active/session-bookkeeping/spec.md (uncommitted, worktree @ 78ea3b5)

Epic: KNOWLEDGE-HOMES
Epic pointer: `.project/backlog/epic_knowledge_homes.md`, Item 3. The epic's Product-Lens gate is the source of truth for its own findings; ship gates and epic-scope audit resolve this item against it.

Point (re-derived): Session end writes cheap records and never curated documents and never commits unasked; `CURRENT_WORK.md` holds only current state; and a cold agent's boot read still shows current work plus what just shipped, at a cost that does not grow with the archive.
  [source: `.project/concepts/agent-knowledge-and-enforcement.md` — Success Criteria 5, 6, 7, plus the owner-verbatim reasons in *Owner's Words* ("this encourages slop on documents that are valued to stay tight"; "the reason for including \"Recently Completed\" is that reading it gives a better picture of the state of things"); grade: **owner**]
  [secondary: `.project/adr/0008-product-ledger-touch-points.md` — the ledger skim lives in `context-loading.md` as a recorded invariant (agent/ratified); `.project/adr/0001-decision-records-convention.md` — no current-state doc maintenance duty (owner); `docs/guide.md:132-136` *Between sessions* (INHERITED/aspirational)]

Falsifier: after this item, `/_my_wrap_up` writes a file under `docs/` or commits unasked; or a pack instruction sends an agent to a `CURRENT_WORK.md` section that no longer exists; or a fresh session's boot read cannot name the most recent completed work without opening `completed/` or running `git log`; or the boot read's cost changes as `completed/CHANGELOG.md` grows.

Findings:

- spec-F1 [DO] The spec states no requirement for `wrap_up`'s `CURRENT_WORK.md` write — the first of the three writes concept Success Criterion 7 names, and one of the five elements of wrap-up's final shape the epic puts in scope ("the `CURRENT_WORK.md` step narrowed"). *What wrap-up writes* carries requirements for the light CHANGELOG entry, the execution note, no-docs and no-commit, and nothing for `CURRENT_WORK.md`; the only trace is an aside inside a Non-Goal (`spec.md:67`, "because `wrap_up` appends a status bullet per session"). Concretely unhandled: `claude-pack/commands/_my_wrap_up.md:31` instructs the agent to "Move completed items from 'Active Work' to 'Recently Completed'" — the section this item deletes. The spec catches exactly this orphaning for the other writer (`spec.md:59`, `_my_close.md:83`, called "the only other writer of that section") but not for the command it owns. Design would inherit no requirement to trace, and the epic's own *Why This Epic* indicts this bug class in this same command ("`_my_wrap_up.md:37-54` … a section that is not in the file it targets").
  — source: concept Success Criterion 7 (**owner**); epic Item 3 *In Scope* (agent/ratified) — disposition: **BLOCK**
  Falsifier: after implementation, `grep -n "Recently Completed" claude-pack/commands/_my_wrap_up.md` still returns a line; or the rewritten command carries no `CURRENT_WORK.md` duty while concept SC 7 names it as a write.
  Clearing path: add a `[NEED]` stating what the narrowed step does — Active Work status and Up Next only, Recently Completed move dropped. No new owner decision is needed; the authority is SC 7 itself, so a later block can record FIXED with authority `owner`.

- spec-F2 [DO] The owner's 2026-09-10 amendment to concept Success Criterion 5's justification is recorded only in this spec's Non-Goals (`spec.md:67`) — at owner grade, with both quotes, which is the right register — while the amended text still stands unqualified in the two artifacts a later reader meets: the concept's SC 5 ("No section in it accumulates, so no retention rule is needed") and the epic's Item 3 done state ("`CURRENT_WORK.md` and its template contain no section that accumulates"). Active Work does accumulate by owner decision (15 items, entries 3 to 22 lines, appended per session), so that epic checkbox cannot be honestly ticked as written at close. `capture-fidelity.md` §3 asks a correction to amend the corrected content at the owner's emphasis rather than leave it standing with a downstream note; in-place amendment of a concept has precedent (`.project/concepts/mental-alignment-checkpoint.md:285`).
  — source: `claude-pack/rules/capture-fidelity.md` §3 (INHERITED, process rule), against the owner's 2026-09-10 statements (owner) — disposition: DISPOSE-and-proceed
  Falsifier: read the concept alone and SC 5 reads as though nothing accumulates; tick the epic's Item 3 checkbox as written and it is false.

- spec-F3 [DO] The spec marks `epic_plan-F4` resolved (`spec.md:52`) on the cost axis, and the coverage axis F4 was about goes unstated. The owner did decide the size at owner grade ("middle one is good, 5 is reasonable"), which discharges the surfacing duty; what is missing is what was traded. Measured today: the newest 5 CHANGELOG entries are 2026-09-10, 08-26, 07-06, 07-01 and 2025-12-30, so the boot read reaches a nine-month-old entry while dropping `docs-overhaul` (2026-08-08) — a committed completion the section being deleted currently shows, with no CHANGELOG counterpart — and 9 of the 14 `Recently Completed` entries leave the boot read permanently, backfill being owner-excluded. Stating that residual is what "surfaced, not silently resolved" requires; F4's own terms are that declining to create new records and destroying existing ones are different acts.
  — source: epic finding `epic_plan-F4` and its measured counts (AGENT/INFERRED) against the owner-verbatim reason for `Recently Completed` (owner) — disposition: DISPOSE-and-proceed
  Falsifier: a reader of `spec.md:52` alone concludes the boot read shows at least what `Recently Completed` showed.

- spec-F4 [DO] Three provenance citations point at paths that no longer exist: `.project/active/execution-register/design.md` (`spec.md:44`, `:47`), `design-review.md` (`spec.md:13`, `:47`), and the *Related Artifacts* pointer (`spec.md:88`). Item 2 was archived to `.project/completed/20260910_execution-register/` on 2026-09-10, and every `[INFERRED]` requirement resting on those cites is now unverifiable from the spec. `capture-fidelity.md` §2 lets payload survive by path; a dead path does not.
  — source: `claude-pack/rules/capture-fidelity.md` §2 (INHERITED, process rule) — disposition: DISPOSE-and-proceed
  Falsifier: follow any of the four cites and the file is absent.

Smells fired:

- Smell 1 — two representations must be manually kept synchronized. Three artifacts now state whether a `CURRENT_WORK.md` section accumulates; one is amended and two are not, with nothing keeping them in agreement. Fires on spec-F2, and must be disposed inside the stage's judgment rather than noted.

Checked, no finding:

- ADR 0008's product-ledger skim survives and is placed before the new CHANGELOG read, named `[INHERITED]` with the reason (`spec.md:38`) — this discharges `epic_plan-F3` for the file Item 3 edits.
- ADR 0001's no-current-state-maintenance rejection is not violated by leaving Active Work unbounded: the owner took the duty himself in words ("not your problem. that is the user's problem"), so no agent maintenance duty is created.
- The two CHANGELOG weights are shaped so the boot read needs no branch (`spec.md:53-54`) — the deliberate opposite of smell 1.
- `[HARD]` on `USER_DATA_FILES` and on the `dist/` rebuild matches the house convention for repo-internal forcing facts (`.project/completed/20260910_retire-hidden-memories/spec.md:77-79`), so it is not grade inflation.
- Item 2's two carry-forwards are both claimed: the `_my_wrap_up.md:14` CLAUDE.md routing (`spec.md:46`) and the execution register's "Nothing else triggers it" (`.project/execution/README.md:5`, claimed at `spec.md:60`).
- Entry-count arithmetic: `spec.md:15` and `:52` say 13 `Recently Completed` entries over 78 lines; measured 14 entries over `.project/CURRENT_WORK.md:128-210`. Off by one, not load-bearing for any requirement.

Gate: BLOCKED (spec-F1)

Resolves:
- epic_plan-F4: DEFERRED — authority: owner (size decided 2026-09-10, "middle one is good, 5 is reasonable") — basis: the surfacing duty is discharged at owner grade and the sizing input landed in the spec; the coverage residual it named is still unstated and is carried forward here as spec-F3. Original source grade preserved as the epic records it: DISPOSE-and-proceed, AGENT/INFERRED counts against an owner-verbatim reason. The epic file stays the source of truth for the finding's text.

---

## spec — dispositions — 2026-09-10 — rev .project/active/session-bookkeeping/spec.md (uncommitted)

Not a new lens run. This block records how the `spec` stage dispositioned the findings in the block above, per product-lens §3 resolution-by-citation. The prior block stands unedited.

- **spec-F1 — FIXED.** Authority: owner, via concept Success Criterion 7, which names `CURRENT_WORK.md` as the first of wrap-up's three writes. No new owner decision was needed, as the finding's own clearing path states. A `[NEED]` was added to *What wrap-up writes*: wrap-up updates active-item status, items started but not finished, and Up Next, and the `Recently Completed` move at `claude-pack/commands/_my_wrap_up.md:31` goes with the section. Verified: that instruction exists at `:31` as the finding reported.
- **spec-F2 — FIXED, by amending upstream rather than noting downstream.** Authority: owner (2026-09-10 statements, both quoted). Per `capture-fidelity.md` §3 the correction lands on the corrected content, so two edits were made: the concept's Success Criterion 5 now carries the amendment inline with both owner quotes, and the epic's Item 3 done-state checkbox is reworded to what the owner authorized — no *history* section, with Active Work's item count and entry depth explicitly out of scope. The old wording could not have been honestly ticked, and the amended checkbox says so. Smell 1 no longer fires: one claim, amended in all three places.
- **spec-F3 — FIXED.** Authority: owner (size decided at owner grade); the residual is now stated, not closed. An `[INFERRED]` line in *The two CHANGELOG entry weights* records what the bound trades: the five newest entries reach back to 2025-12-30 because the CHANGELOG is sparse where the deleted section was dense, nine of the thirteen completed items have no CHANGELOG counterpart and disappear rather than moving, and `docs-overhaul` (2026-08-08, committed `43bca3c`) is the most recent of those nine. Backfilling stays owner-excluded. The epic's Item 3 *In Scope* sizing line also now records the settled call.
- **spec-F4 — FIXED.** All four citations repathed to `.project/completed/20260910_execution-register/`, verified present (`spec.md` Problem, the two `[NEED]`/`[INFERRED]` requirements resting on Item 2's design and design review, and the *Related Artifacts* pointer).

Correction to the prior block's *Checked, no finding* list: the `Recently Completed` entry count is **13**, not 14 — verified against `git show HEAD:.project/CURRENT_WORK.md`. The spec's 13 was right; the finding block's 14 was the off-by-one. Nothing load-bearing either way.

Gate: CLEAR (spec-F1 fixed at owner authority; F2, F3, F4 dispositioned and fixed)

**Correction to this block's falsifier, 2026-09-10 (spec-review L3-1):** the clause "without opening `completed/`" is wrong as written — the mechanism *is* a bounded read of `.project/completed/CHANGELOG.md`. Read it as: without browsing item folders under `completed/` and without running `git log`. The spec's Success Criterion 1 now carries the corrected wording; nothing else in the block changes.

---

## design_review — 2026-09-10 — rev .project/active/session-bookkeeping/design.md (uncommitted, worktree @ 78ea3b5)

Point (re-derived): Session end writes cheap records and never curated documents or an unasked commit; `CURRENT_WORK.md` holds current state; and the standard boot read shows what just shipped at a cost that does not grow with the archive. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Success Criteria 5, 6, 7 and *Owner's Words*; grade: owner]

Falsifier: after this item, a confirmed light completion is absent from the next standard boot excerpt; the excerpt presents a template placeholder as shipped work; `/_my_wrap_up` writes under `docs/` or commits unasked; or the excerpt's output grows with the CHANGELOG.

Findings:

- design_review-F1 [DO] Make newest-first insertion an explicit invariant owned by both CHANGELOG writers. The reader counts the first five `## [` headings (`design.md:92,161`), but wrap-up is told to append its light entry (`design.md:83,103`), which places it after the seven existing entries and outside the next boot excerpt. The Required Invariants name heading and section delimiters but never chronological order or insertion position, and the existing close instruction only says to "Add an entry." The design's own one-session data flow therefore does not deliver the confirmed completion it says the next session sees. — `.project/concepts/agent-knowledge-and-enforcement.md` Success Criteria 6 and 7 (owner) — disposition: BLOCK

- design_review-F2 [DON'T] Do not activate the bounded reader over known fake completion entries in existing protected CHANGELOGs. The design correctly removes the placeholder from the template for new projects, but explicitly leaves existing projects' user-data files unchanged while acknowledging that their boot read will surface `## [YYYY-MM-DD] - [Epic/Item Name]` as a completion (`design.md:42,73,186`). Its mitigation is also false: one real close cannot push the placeholder past position five; that takes five newer entries. This sends a cold agent false state through the standard orientation path. — `.project/concepts/agent-knowledge-and-enforcement.md` Success Criterion 6 and the owner-verbatim reason for preserving completion history (owner) — disposition: BLOCK

Smells fired:

- Smell 7 — the proposed solution changes who owns an invariant without saying so. The first-five reader makes reverse-chronological insertion correctness-critical for both `close` and `wrap_up`, but the design's invariant list assigns neither writer that duty and its wrap-up wording says the opposite. This escalates design_review-F1 into the stage judgment.
- Smell 2 — does not fire. The design does not make the consumer compensate for a producer or platform guarantee; its defect is that the producer-side ordering contract is absent.

Gate: BLOCKED (design_review-F1, design_review-F2)

---

## design — dispositions — 2026-09-10 — rev .project/active/session-bookkeeping/design.md (uncommitted)

Not a new lens run. Dispositions for the `design_review` block above, per product-lens §3 resolution-by-citation. The prior block stands unedited.

- **design_review-F1 — FIXED, the finding was correct.** A real defect: the design told wrap-up to append while the reader takes the first five entries of a newest-first file, so a confirmed light completion would never appear in the next boot excerpt. The design's own one-session data flow promised the opposite. Fixed at three points — wrap-up's step 4 now inserts at the top and names why the two registers order oppositely (the CHANGELOG is read from the top, the register is not read at all); the data flow says the same; and Required Invariants gains newest-first ordering as a named, correctness-critical contract.
- **Smell 7 — FIXED with the same change.** The invariant is now assigned to both writers rather than to neither: a clause in `_my_close.md` (stating existing behavior, not changing what it writes — the epic's non-goal protects the four fields, not the insertion position), a clause in `_my_wrap_up.md`, and a line in the template CHANGELOG's header, which is the one home both writers see.
- **design_review-F2 — defect accepted, disposition declined, fixed differently.** Three parts, graded separately:
  - The **factual correction is right and the design was wrong**: one real close does not push a placeholder past position five, it takes five. That risk row is corrected and says so explicitly.
  - The **severity is overstated.** What a reader would actually receive is `## [YYYY-MM-DD] - [Epic/Item Name]`, `**Type**: Epic | Item`, `**Duration**: [X days] (estimated: [Y days])`, "Brief description of what was accomplished." Bracketed metavariables are not plausibly read as shipped work. This is noise in the boot excerpt, not false state — the gap between those two is the gap between the finding's grade and its evidence.
  - The **disposition — "do not activate the bounded reader" — is disproportionate to a one-character-class fix.** The reader's heading anchor becomes `/^## \[[0-9]/`, which skips any non-dated heading. Verified both directions: the template CHANGELOG now yields nothing, and this repo's real CHANGELOG still returns the same five entries and 25 non-blank lines. Deactivating the reader would forfeit the owner-decided boot history to avoid a placeholder; anchoring costs four characters and reaches the existing protected files the template edit cannot.

  Recorded as a disposition rather than a silent rewrite because the finding was raised at owner grade: the defect is real and is fixed, the proposed remedy is not the one taken, and the owner can overrule this on sight.

Gate: CLEAR (design_review-F1 fixed; design_review-F2 defect fixed by a different remedy, disposition recorded)
