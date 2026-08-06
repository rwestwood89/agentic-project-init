---
id: 0005
title: Product-lens ADR touch-point map and its liveness-vs-authority grading
date: 2026-08-05
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[AGENT] (ratified by owner, 2026-08-05)"
seams: [claude-pack/commands, project-pack]
supersedes: 0004
promoted_to: null
---

## Decision

Two things, correcting the superseded 0004:

1. **Touch-point map.** The product-lens extends the pipeline's ADR touch-point map beyond ADR
   0002. It reads `.project/adr/` as graded product-truth SOURCES at `_my_epic_plan`, `_my_spec`,
   `_my_design_review`, and `_my_audit` (item and epic scope), and writes a decision record when a
   finding is disposed as an intended contract change. ADR 0002's "audit, spec, epic-plan…
   untouched" clause is amended to reflect those contacts; 0002's decision-record *write* points are
   unchanged.
2. **Grading — liveness and authority are separate axes.** An ADR's `status` decides whether it
   binds at all (`active` or `amended` bind; `superseded` does not). Its `provenance` decides the
   authority: only an `[OWNER]`-provenance live ADR is owner-grade and can BLOCK a stage. A live
   `[AGENT] (ratified)` ADR is a real, binding decision but **not** owner-grade — contradicting it
   is DISPOSE-and-proceed and is challenged by re-deriving against its Why.

## Why

0004 conflated the two axes — it said "counts a live ADR as owner-grade," which would launder every
ratified-agent decision (including 0002 and this entry itself) into owner authority and let the lens
BLOCK on a challengeable agent decision as if the owner had set it. Capture-fidelity already draws
this line: only owner-*originated* items are settled/owner-grade; a ratified agent recommendation
stays agent-grade and challengeable. Status answers "does it still apply," provenance answers "whose
authority is it" — collapsing them breaks the tiered enforcement the whole feature rests on.

## Invariants established

- The lens counts an ADR as binding while `status` is `active` or `amended`; a `superseded` entry
  does not bind.
- Only `[OWNER]`-provenance binding ADRs (and `[OWNER]`/`[OWNER-VERBATIM]` concept items, `[HARD]`
  constraints) are owner-grade and BLOCK. `[AGENT] (ratified)` and `[INHERITED]` are
  DISPOSE-and-proceed.
- A "intended contract change" disposition altering a recorded decision must
  `adr.sh amend|supersede` the affected live entry with owner-ratified provenance.

## Rejected alternatives

- Treat any live ADR as owner-grade (superseded 0004): laundered ratified-agent decisions into owner authority.
- Preserve ADR 0002's "exactly four touch points" by classing the new reads a separate kind (superseded 0003): a special-category exemption despite changed observable use.
- Supersede ADR 0002 outright: its write-point core still holds; amend, do not replace.
