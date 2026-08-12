# Audit: Product Intent Ledger

**Verdict:** Needs Work
**Audited:** 2026-08-12
**Branch:** anchor-on-the-point
**Commit:** fc48123

---

## The Point

Cold coding agents and product-lens agents need one sparse, durable, current orientation surface
for major implemented product promises. Each entry must summarize the promise directly and trace
its authority. The ledger must serve both consumers without mandatory evidence, a certification
sequence, or a completeness gate.

## Summary

The read/write wiring, documentation, distribution, and happy-path script behavior are present,
and the repository's eight relevant suites pass. Certification is blocked because the cross-seam
entry rule contradicts an owner requirement, while focused probes exposed duplicate ids and
history-rewriting lifecycle transitions that the suite does not cover.

## Product Judgment

This is the right piece of work, but the implementation is not yet a trustworthy product-intent
ledger. The product-lens ledger is **BLOCKED (audit-F1)**: the pointer-entry exception at
`project-pack/product/README.md:106` forbids restating the promise, contradicting the owner's rule
that entries summarize it. Smell 3 fires on that exception. Smells 1 and 6 also fire because
ledger logic and installed copies require manual synchronization while the tests exercise only
one selected copy. These smells are unresolved, so the item cannot be certified.

## Findings

### Plan completion

- **Phase 1 needs work.** `project-pack/scripts/product.sh:98` calculates the next id and writes
  the file without an atomic claim. A 24-worker audit probe created repeated ids; the test at
  `scripts/test_product.sh:54` only simulates a number claimed before a sequential call. Add a real
  concurrency test and make allocation preserve unique ids. Because D2 shares this engine pattern,
  verify the ADR script as part of the correction.
- **Phase 2 verified.** ADR 0008, session-start reading, lens SOURCES, all call sites, close beats,
  and orientation pointers are present.
- **Phase 3 needs work.** `.project/active/product-intent-ledger/fixture-transcripts.md:41` records
  E3 hand-writing script-managed state, the raw E4 verdict was not retained, and the retained E5
  output at `fixture-transcripts.md:82` does not name the cited authority source required by the
  pre-written bar. Preserve compliant evidence and rerun the affected exercises.
- **Phase 4 verified.** Documentation, template seeding, dogfood copies, generated Codex output,
  and distribution checks are present.

### Spec conformance

- **SC1 — verified.** The startup rule points agents to the one generated index
  (`claude-pack/rules/context-loading.md:5`), and E1/E3 demonstrate relevant-entry discovery.
- **SC2 — open.** Both consumers are wired to the same discovery surface, but E4's raw result was
  not retained, so the behavioral claim is not fully verified.
- **SC3 — gap.** Normal entries have Promise and Authority sections, but the cross-seam rule says
  a local pointer entry must never restate the promise (`project-pack/product/README.md:106`).
  Make cross-seam entries satisfy the same owner-stated restate-and-cite contract.
- **SC4 — verified.** The density bar and exclusions are explicit
  (`project-pack/product/README.md:14`), and close treats zero entries as normal.
- **SC5 — gap.** `new` publishes an active entry with `checked` already set while Promise and
  Authority still contain placeholders (`project-pack/scripts/product.sh:128`). Make active and
  checked state mean the documented claim at `project-pack/product/README.md:101`.
- **SC6 — gap.** `supersede` warns when an entry already has a successor but still overwrites that
  successor (`project-pack/scripts/product.sh:176`); self-links are also accepted. Reject invalid
  transitions and add a no-successor withdrawal path so a removed promise can leave the current
  index without an active tombstone.
- **SC7 — verified.** Evidence is optional and no stage gates on ledger contents
  (`project-pack/product/README.md:9`; `claude-pack/commands/_my_close.md:51`).
- **SC8 — open.** The retained evidence does not verify all five pre-written exercise bars.

Known requirements follow the same result: sparse admission, optional evidence, honest absence,
first capture, distribution, and index-first lens discovery are implemented. Implemented-only,
Authority-before-entry, restate-and-cite, append-only history, and fully demonstrated equal-consumer
behavior remain open for the gaps above. The non-goals were respected; no backfill, inventory, new
stage, or ledger completeness gate was added.

### Design conformance

D1, D5, D6, D7, and D9 are implemented as designed. D3 and D4 are partial because `new` exposes
an active, checked placeholder before required content exists. D8 follows the design but conflicts
with the owner-stated spec contract. D2's bounded duplication remains unresolved at audit because
the required synchronization is manual and exact-copy drift is not guarded.

The derived-index, honest-absence, citation-grading, and no-gate invariants hold on the tested
paths. Unique identity, valid lifecycle history, implemented-only active entries, required
Authority, and honest checked state do not yet hold under supported operations.

### Code integrity

- `project-pack/scripts/product.sh:50` resolves duplicate ids by selecting the first match. It
  must reject ambiguity instead of mutating an arbitrary entry. This is the concrete smell-6
  failure exposed by the concurrent probe.
- `project-pack/scripts/product.sh:38` reports no error when a requested frontmatter field is
  absent; callers can print success without applying the mutation. Verify exactly one field was
  changed and fail on malformed entries.
- `project-pack/scripts/product.sh:170` accepts self-supersession, re-supersession, self-amendment,
  and incompatible targets. Enforce lifecycle preconditions and reciprocal consistency.
- `project-pack/scripts/product.sh:128` places verification policy in `new`: filing time becomes
  the checked time before the promise is filled or verified. Move that policy to a point where the
  caller has actually established the invariant.

No god function, parameter-sprawl, deep-nesting, broad-exception, or compatibility-shim issue was
found. Product-drift smells 4 and 5 did not fire.

---

## Certification

Verified SC1, SC4, and SC7 and marked those criteria in `spec.md`. Verified Plan Phases 2 and 4.
Left SC2, SC3, SC5, SC6, and SC8 open; reopened the Phase 1 collision-test item and Phase 3 evidence
claim. Appended the independent audit verdict to `product-lens.md` and updated `CURRENT_WORK.md` to
Needs Work. No parent epic exists.

Checks run: `test_product.sh` (36/36), `test_adr.sh` (25/25), `test_docs.sh`,
`test_pipeline_sync.sh`, `test_global_setup.sh`, `test_init_project.sh`,
`test_codex_orchestrator_pack.sh`, `test_concept_design_quality_gate.sh`, and `git diff --check`.
All passed. Focused lifecycle and concurrency probes exposed the gaps above.

**Not checked:** Long-term density behavior (B3), promise-change frequency over time (B2), actual
external user-home install state, and fresh reruns of E1-E5. This audit assessed the current tree,
retained fixture evidence, generated Codex artifacts, and temporary-project behavior.
