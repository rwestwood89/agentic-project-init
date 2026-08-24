---
id: 0003
title: Product-lens adds product-truth touch points and can file decision records
date: 2026-08-05
owner: Reid W
status: superseded
amended_by: []
superseded_by: 0004
provenance: "[AGENT] (ratified by owner, 2026-08-05)"
seams: [claude-pack/commands, project-pack]
supersedes: null
promoted_to: null
---

## Decision

The product-lens (`claude-pack/scripts/product-lens.md`) adds a second line of touch points to
the pipeline, distinct from the decision-record touch points ADR 0002 fixed. It **reads**
`.project/adr/` (among README/`docs/`) as product-truth SOURCES at `_my_epic_plan`, `_my_spec`,
`_my_design_review`, and `_my_audit`; and it **files** a decision record when a finding is
disposed as an intended contract change (via `adr.sh`, at `_my_close`, or at the stage that makes
the disposition). This amends ADR 0002: the decision-record read/write map it froze now has these
additional, product-lens-mediated contacts.

## Why

ADR 0001 requires load-bearing cross-seam decisions to be recorded, and ADR 0002 fixed the
decision-record touch-point map ("audit, spec, epic-plan… untouched"). The product-lens feature
changes that map — it reads ADRs at four new sites and can file one via disposition — so leaving
0002 unamended would let a future agent re-derive the old map and rule the product-lens reads
out of contract. The two touch-point systems are deliberately separate: ADR 0002 governs where the
*decision-record mechanism* is operated; this entry governs where the *product-lens* consults and
(rarely) feeds it. Recording the distinction is what the product-lens itself demands — its first
dogfood audit BLOCKED on this very obligation.

## Invariants established

- The product-lens reads `.project/adr/` only as graded product-truth SOURCES; it counts an ADR
  as owner-grade only while `status: active`.
- A product-lens "intended contract change" disposition that alters a recorded decision must
  `adr.sh amend|supersede` the affected active entry and carry owner-ratified provenance — not the
  default `[AGENT]`.
- ADR 0002's core decision (the decision-record mechanism has exactly four touch points) still
  holds; this entry adds the product-lens contacts, it does not move 0002's four points.

## Rejected alternatives

- Supersede ADR 0002 outright: its four-touch-point core is still true; amendment, not replacement, is correct.
- File nothing and keep the design's "no conflict" claim: that is the silent premise-conflict resolution this feature exists to stop.
- A separate append-only product-lens decision log: fails the density bar; the per-item ledger already carries transient findings, and only contract changes reach an ADR.
