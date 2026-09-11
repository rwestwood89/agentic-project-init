---
id: 0013
title: Execution facts leave the decision register
date: 2026-09-10
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER] (design D8, owner-dispositioned 2026-09-10)"
seams: [_my_close, execution-register, adr-register]
supersedes: null
promoted_to: null
---

## Decision

Close's Step 2 becomes one record scan with three destinations — `.project/adr/`, `.project/product/`, `.project/execution/` — replacing the separate decision and promise scans. Behavior facts discovered while working (how a component, tool, or data format actually behaves) go to the execution register, not to the decision register.

## Why

The decision scan's own text at `_my_close.md:29` claimed "workarounds against another component or repo's behavior," which is the execution register's headline class. Added as a third scan, the register would receive nothing: the decision scan runs first and absorbs the class. Three precedents confirm the overlap — `.project/adr/0010:36-40` files two Codex build gotchas that are pure behavior facts, and `CLAUDE.md:53` holds a third. The class was never homeless; it was absorbed by the decision register for want of a better home. One scan with three destinations states the boundary once and ensures each finding routes to exactly one home.

## Invariants established

- Close's record scan is the single place the three-way routing boundary is defined for the write path. The execution register's `README.md` restates the boundary for the reader, but the scan is what routes.
- The write map is unchanged: close remains the single normal write point for `.project/adr/` (ADR 0002) and `.project/product/` (ADR 0008). What changes is the subject boundary inside close's scan.

## Rejected alternatives

- Adding the execution register as a third scan (the decision scan runs first and absorbs the class — the register receives nothing).
- Narrowing the decision scan's text instead of restructuring (works, but puts the boundary in two places that must be kept in agreement by hand).
