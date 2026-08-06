---
id: 0004
title: Product-lens extends the pipeline ADR touch-point map
date: 2026-08-05
owner: Reid W
status: superseded
amended_by: []
superseded_by: 0005
provenance: "[AGENT] (ratified by owner, 2026-08-05)"
seams: [claude-pack/commands, project-pack]
supersedes: 0003
promoted_to: null
---

## Decision

The product-lens (`claude-pack/scripts/product-lens.md`) **extends** the pipeline's ADR
touch-point map beyond what ADR 0002 recorded. It **reads** `.project/adr/` as graded
product-truth SOURCES at `_my_epic_plan`, `_my_spec`, `_my_design_review`, and `_my_audit`
(item and epic scope), and **writes** a decision record when a finding is disposed as an intended
contract change. ADR 0002's "audit, spec, epic-plan… untouched" clause is amended: those stages now
carry product-lens ADR contacts. This does not move ADR 0002's decision-record *write* points; it
adds the product-lens reads and the disposition-driven write.

## Why

The observable ADR use genuinely changed — ADRs are now read at four new sites and can be written
via disposition. Recording that plainly is required by ADR 0001 (load-bearing cross-seam decisions
are recorded). The superseded 0003 tried to keep 0002's "exactly four touch points" true by calling
the new reads a separate product-lens-mediated *kind*. That is a special-category exemption whose
observable meaning is unchanged — smell 3 in this very feature's list — so it was the wrong framing.
The honest record is: the map is larger now, and 0002 is amended to say so.

## Invariants established

- The product-lens reads `.project/adr/` only as graded product-truth SOURCES; it counts a **live**
  ADR (`status: active` or `amended`) as owner-grade, and a `superseded` entry as non-binding.
- A product-lens "intended contract change" disposition that alters a recorded decision must
  `adr.sh amend|supersede` the affected live entry and carry owner-ratified provenance.
- ADR 0002's decision-record write discipline (records filed at acceptance and close) still holds;
  this entry adds contacts, it does not relocate those writes.

## Rejected alternatives

- Preserve "exactly four touch points" by classing the product-lens reads as a separate kind: a special-category exemption despite changed observable use — the move this feature's smells exist to catch (superseded 0003 did this).
- Supersede ADR 0002 outright: its write-point core still holds; amend, do not replace.
- Edit 0003's body in place: bodies are append-only; supersession is the sanctioned correction.
