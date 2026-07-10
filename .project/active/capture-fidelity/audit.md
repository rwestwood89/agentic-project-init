# Audit: Capture Fidelity

**Verdict:** Certify
**Audited:** 2026-07-10
**Branch:** `capture-fidelity`
**Commit:** none — all work is uncommitted on the branch (base b79c40c). Flagged below.

---

## Summary

The implementation delivers the spec: the four laws live in one 40-line rule
(`claude-pack/rules/capture-fidelity.md`), the eight command touches are faithful to the
design's placements and budgets, the phase-2/3 gate story is coherent with its one
deviation (P3 refit) correctly reasoned from the design, and every recorded deviation is
documented with its why. Two minor items to fix before PR; nothing structural.

## Findings

### Plan completion

All five phases verified complete against the working tree.

- **Phase 1:** rule exists; 45 non-blank lines = 40 substantive excluding the 5 headings —
  the budget claim holds on that counting basis. Concept and spec touches match the plan.
- **Phase 2 (gate):** fixture + expected-findings files exist, written fixture-first; the
  3/4 → P3-refit → 4/4 story is documented with the P3 analysis traced to `design.md:71`
  (first-hop compression is owner-checked, so "referent absent" is not reviewer-detectable
  in a concept). The refit to "binding referent softened into a vibe" is within-artifact
  detectable and is the better plant. The refit reasoning is sound, not a rationalization:
  B2 is about correction/provenance signatures (P1, P2, P4), all caught pre-refit.
- **Phase 3:** review touches match; the refit P3 verified present in the fixture
  (`fixture-planted-concept.md:17,36`).
- **Phase 4:** orchestrate diff read in full — line 9 reconciled, Align exchange and tier
  rule share the "reserved gates" vocabulary, no internal contradiction found. Net +23/−5.
- **Phase 5:** `~/.claude/rules/capture-fidelity.md` symlink resolves; AGENTS.md inlining
  verified as pre-existing build behavior (Working Voice and Pipeline Shape are inlined the
  same way), so the Codex outcome respects the spec Non-Goal — nothing Codex-specific built.

### Spec conformance

All 8 success criteria verified as devices-delivered. Note the criteria describe *ongoing
behaviors* (corrections shrinking, referents surviving); what this audit certifies is that
the devices implementing them exist, are placed per design, and passed the planted-violation
gate — not that future sessions will comply. That distinction is inherent to prompt work.

1. Rule: single, always-loaded, four laws, 40 substantive lines, no failure-specific
   content on read-through, referenced-not-restated ✓ (grep: law text only in the rule).
2. Provenance grades + structural settled restriction ✓ (rule table; concept template
   `_my_concept.md:212-215`; `_my_spec_review.md:42`).
3. Verbatim preservation + payload force marking + unclear→ask ✓ (`_my_concept.md:132-139,
   243-244`; rule law 2).
4. Correction discipline + static signatures ✓ (rule law 3 with the owner's BAD/GOOD pair
   verbatim — byte-checked against `spec.md`; signatures in `_my_spec_review.md:42`).
5. Orchestrate Align + tiers ✓ (diff verified end to end).
6. Review structural checks without failure-specific rubric ✓ (one bullet per review; reads
   as structure).
7. Handoff claim marking ✓ (`_my_handoff.md:14-16`).
8. Audit scope honesty ✓ (`_my_audit.md:105-107`) — this audit is its first live consumer.

Tagged requirements: all met. Non-goals: all respected (no concept-review stage, no
mandatory exemplars, no notification feature, no Codex-specific representation, no pipeline
shape change — `pipeline.md` untouched).

### Design conformance

Implementation follows the design. Required invariants hold (single statement, verbatim
pair, settled restriction, unchanged tag semantics + additive `[INHERITED]`, budget, tags
scoped to decision-carrying items). Two deviations, both documented and sound:

- **6-of-8 rule references** (audit + handoff don't reference the rule): deliberate, the
  reasoning is correct — their behaviors are not among the four laws, and a reference would
  point at a rule that doesn't state them. The plan's "all eight" was written before the
  law set was pinned. Documented in the phase-4/5 notes.
- **Owner's Words placed after Problem Statement** (design didn't specify): reasonable,
  documented.

### Code integrity

No issues. Touches are tight, reference-based, and within their stated budgets
(orchestrate +23/−5 against the ~25 exception; every other file ≤ ~10).

**Two minor findings to fix before PR:**

1. **Stale tag enumeration** — `_my_spec_review.md:39` still enumerates three tags and
   describes `[NEED]` as "a stakeholder outcome"; `_my_spec.md` now defines four tags with
   `[NEED]` owner-stated. A reviewer following `:39` literally would treat `[INHERITED]` as
   an unknown tag three lines above the bullet that checks it. Update the enumeration to the
   four-tag vocabulary.
2. **Nothing is committed.** The whole implementation (plus this feature's `.project/`
   artifacts) sits uncommitted on `capture-fidelity`. Not a defect of the work, but the
   commit trail is part of the deliverable discipline — handle at `/_my_pre_pr`.

---

## Certification

Checked: all 5 plan phases against the working tree; all 8 success criteria; all tagged
requirements and non-goals; design invariants and both recorded deviations; rule line
budget, single-sourcing grep, reference grep, symlink, Codex AGENTS.md precedent; fixture
plants verified present on disk. Marked: spec success criteria 1–8; plan checkboxes were
already implementer-marked and are confirmed. CURRENT_WORK updated to certified.

**Not checked:** the phase-2/3 dogfood results (3/4, then 4/4 with 0 false positives) are
implementer-reported — I verified the fixture and expected-findings files exist and contain
the plants, but did not re-run the reviewer subagent. The laws' behavioral efficacy (bet
B3 — that the rule changes capture behavior where memories didn't) is unverifiable at
audit; only live use tests it. Codex output was grep-verified, not executed in a Codex
session. Auditor independence is partial: I authored the spec/design/plan (a different
session implemented); an author-auditor reads their own contract charitably.
