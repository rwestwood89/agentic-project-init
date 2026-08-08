---
id: 0007
title: pre_pr is a branch gate run after close
date: 2026-08-08
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [claude-pack/commands, claude-pack/rules, docs, codex-overrides]
supersedes: null
promoted_to: null
---

## Decision

`/_my_pre_pr` is a branch-level gate, not a work-item stage. It runs **after** `/_my_close`,
once per PR: after closing an item that is shippable on its own, or once at the end of an
epic when its items ship together. The per-item tail of the pipeline is `audit → close`;
`pre_pr` sits outside the item flow.

## Why

Owner decision (2026-08-08): "pre-pr should be AFTER a close, and done when the item itself
is shippable. otherwise, it should be done at the end of the epic."

The reasoning: `audit` certifies an item; `pre_pr` clears a branch. Its scope is git state,
project tooling (tests/lint/format), and PR submission — none of which is item-shaped. A
branch carrying several items gets several audits and closes but exactly one pre_pr.
Executing agents were observed re-deriving the wrong timing (running it per item or
mid-item) from the old shape line `audit → pre_pr → close`, which miscast it as an item
stage — the drift this record exists to stop.

Mechanical consequence: because pre_pr runs post-close, its fail-closed product-lens gate
must find ledgers in `completed/{date}_{item}/` as well as `active/{item}/`.

## Invariants established

- The canonical shape line ends `… → audit → close → pre_pr`.
- `pre_pr` runs at most once per PR, and only when the branch has something to ship.
- Orchestrators leave `close` and the post-close `pre_pr` to the human unless asked.
- `pre_pr`'s product-lens gate reads ledgers from both `active/` and `completed/`.

## Rejected alternatives

- `pre_pr` as an item stage between `audit` and `close`: rejected because the gate is
  branch-scoped, and the placement caused agents to run it per item regardless of
  shippability.
