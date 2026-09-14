# Design Review: Session Bookkeeping

**Design:** `.project/active/session-bookkeeping/design.md`
**Spec:** `.project/active/session-bookkeeping/spec.md`
**Review File:** `.project/active/session-bookkeeping/design-review.md`
**Product-Lens Ledger:** `.project/active/session-bookkeeping/product-lens.md` — `design_review` gate BLOCKED
**Date:** 2026-09-10

---

## The Point

Session end writes cheap records rather than curated documents, and it never commits without the owner asking. `CURRENT_WORK.md` holds current state. The standard boot read still shows what just shipped, at a cost that does not grow with the CHANGELOG. This is owner-grade from `.project/concepts/agent-knowledge-and-enforcement.md`, Success Criteria 5, 6 and 7, including the owner's reason for keeping completion history visible: it gives a cold agent a better picture of the current state.

## Fundamental Assessment

**Fail.** This is the right piece of work, and the direct-edit architecture is appropriately small. The core read/write route does not work as designed, however. The reader takes the first five CHANGELOG entries, while wrap-up is told to append its light entry to the end of a newest-first file. A confirmed completion therefore misses the next boot read. The design also activates that reader over known fake completion entries in existing protected CHANGELOGs, so some projects receive false state at boot.

The independent product lens grades both failures against owner-level Success Criteria 6 and 7 and records `design_review-F1` and `design_review-F2` as BLOCKs. Structural smell 7 also fires: the first-five reader makes reverse-chronological insertion a correctness-critical invariant for both CHANGELOG writers, but the design neither assigns that ownership nor states the invariant, and its wrap-up route says the opposite. Per the design-review gate, the detailed dimensional audit stops here. The foundation needs rework before lower-level findings are useful.

**Is this the right approach at all?** Yes after the route is corrected. A bounded reader over the existing CHANGELOG remains simpler than maintaining a second recent-completions representation. No new abstraction is needed.

---

## Issues by Severity

### Critical

- **C1 — The light write goes to the wrong end of the CHANGELOG.** The design says wrap-up appends the confirmed light entry (`design.md:83,103`), while the reader counts the first five `## [` headings (`design.md:92,156`) and the live CHANGELOG is newest-first (`.project/completed/CHANGELOG.md:7,25,45`). A literal append cannot appear in the next boot excerpt. The design must require newest-first insertion for both `close` and `wrap_up`, assign ownership of that invariant, and make the write instructions unambiguous. This is product-lens `design_review-F1` and the smell-7 tripwire.

- **C2 — Existing protected templates become fake shipped work at boot.** Existing projects keep their `completed/CHANGELOG.md` because it is protected user data (`scripts/init-project.sh:123-130`). Those files can still contain the placeholder heading `## [YYYY-MM-DD] - [Epic/Item Name]`, which the new reader counts as a completion. The design acknowledges this but claims one real close pushes it past position five (`design.md:186`); it actually remains visible until five newer entries exist. The design needs a route that never emits the placeholder, either by safely recognizing it in the bounded reader or by removing it when a CHANGELOG writer encounters it. This is product-lens `design_review-F2`.

### Major

Detailed review skipped because Stage 0 failed.

### Minor

Detailed review skipped because Stage 0 failed.

---

## Recommendations

1. Define the CHANGELOG as newest-first and require both writers to insert immediately before the current first entry. Put chronological order and insertion position in Required Invariants, not only implementation prose.
2. Choose an existing-project strategy for the fake placeholder. Filtering the exact template heading in the reader is local and migration-free; writer-side cleanup also works but leaves false boot state until a writer runs. The selected behavior must satisfy the boot-read criterion from the first session after the new rule ships.
3. Re-check the entry-format ownership while revising this seam. Removing the template entry also removes the only exact heavy-entry example, while the reader now depends on the `## [` heading and `### Deliverables` delimiter. Ensure the close writer owns and states that grammar rather than relying on an example the design deletes.
4. After revision, append a product-lens resolution block citing `design_review-F1` and `design_review-F2`, then rerun `my-design-review` for the dimensional audit.

---

## Resolutions

No issues resolved yet.

---

**Overall:** Rework
**Next Steps:** Resolve C1 and C2 in this review, then re-run `my-design` (or return to the design-agent session) and point it at this review. The reviewer does not edit the design.
