---
id: 0002
title: Decision-record touch points: read at concept-design and design, write at acceptance and close
date: 2026-07-19
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[AGENT] (ratified by owner, 2026-07-19)"
seams: [claude-pack/commands]
supersedes: null
promoted_to: null
---

## Decision

The record has exactly four pipeline touch points: reads at `_my_concept_design`
(subagent sweep + required Prior Art section) and `_my_design` (index skim at setup);
writes at design acceptance (settled decisions) and `_my_close` (emergent decisions).
Audit, orchestrate, spec, epic-plan, and wrap-up are untouched.

## Why

A read is enforced by an output that depends on it — a required section is the only read
enforcement that works; exhortation gets routed around. A write is attached to a gate the
item cannot skip — close over wrap-up because wrap-up is optional and session-scoped, and
an optional write duty can be skipped forever. Orchestrated runs inherit all four points
through the stages orchestrate invokes.

## Rejected alternatives

- Touch points in audit/orchestrate: audit stays an evaluator; orchestrate inherits everything through its stages.
- Write point at wrap-up: optionality defeats the control.
- Filing decisions at every stage: one decision, one entry, at the stage that settled it; later artifacts cite.
