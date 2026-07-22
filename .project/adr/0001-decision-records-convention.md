---
id: 0001
title: Load-bearing decisions are recorded append-only in .project/adr
date: 2026-07-19
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [project-pack, claude-pack/commands]
supersedes: null
promoted_to: null
---

## Decision

Load-bearing decisions — and the contracts and invariants they establish across major
seams — are recorded as append-only entries in `.project/adr/`, with `INDEX.md` generated
by `adr.sh` and status flips as the only permitted mutation.

## Why

Descriptions rot silently; decisions stay true as historical facts until explicitly
superseded, and supersession is markable. The constraint-execution post-mortem
(2026-07-19) traced a week of remediation to load-bearing knowledge scattered across
ephemeral artifacts with no durable, findable home. Owner-stated: no current-state doc
maintenance — "waste of tokens and will never actually work."

## Invariants established

- Entry bodies are immutable after filing; only frontmatter status fields change, and only via `adr.sh`.
- `INDEX.md` is derived state — regenerable from entries alone, never hand-edited.
- A cross-seam decision files in the repo that must uphold it; the discovering repo files a pointer entry.

## Rejected alternatives

- A maintained current-state architecture register: unmaintainable by experience; reconstructions are dated entries instead.
- Homing the record in repo-official docs: the pack owns only the `.project/` convention across repos with differing doc norms.
