---
id: 0008
title: Product-ledger touch-point map: reads at session start + lens SOURCES, write at close
date: 2026-08-09
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[AGENT] (ratified by owner, 2026-08-09)"
seams: [claude-pack, project-pack, product-lens]
supersedes: null
promoted_to: null
---

## Decision

The product-intent ledger (`.project/product/`) gets exactly three pipeline touch points:
**reads** at session start (`claude-pack/rules/context-loading.md` sends every session to skim
`INDEX.md`) and in the product-lens SOURCES definition (`claude-pack/scripts/product-lens.md`
plus its five call-site strings, index-first, discovery-not-authority); **write** at
`/_my_close` (promise scan → owner confirm → file via `product.sh`, beside the existing ADR
beats). `_my_status` and `_my_project_find` carry pointer lines as secondary orientation.
Nothing gates on the ledger anywhere.

## Why

ADRs 0002/0005/0006 established that the pipeline touch-point map is a recorded decision and
that extending it silently is a premise-conflict failure (the anchor-on-the-point audit BLOCKed
exactly that). This entry records the map for a new artifact — it amends nothing, because
0002/0005 govern *decision-record* touch points and this is a parallel map for the product
ledger. Placement reasoning: session-start read reuses the one always-on read list rather than
a new rule (rule-budget discipline, auto-ships to Codex via AGENTS.md); the lens gets the
ledger as discovery only, because entry summaries carrying citation authority would launder
inferred intent into product truth; the write attaches to close because a write duty on an
optional stage is skipped forever (ADR 0002's Why), and close already carries the
scan→confirm→file beat.

## Invariants established

- The ledger is read-only orientation for every stage except `/_my_close`, the single normal
  write point (first-capture entries for owner-stated promises are the recorded exception).
- No stage, gate, or command blocks on ledger state; "no promises to record" always proceeds.
- Lens consumption is index-first discovery; oracles derive from entry citations at their own
  grades, never from entry summaries.

## Rejected alternatives

- A new always-on rule file for the session-start read — context-loading.md already owns
  session-start reads.
- A write touch point in `_my_quick_edit` or `_my_wrap_up` — quick edits essentially never
  cross the density bar; optional-stage write duties defeat the control.
- Silent extension of the touch-point map without this record.
