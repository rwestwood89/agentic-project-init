---
id: 0010
title: Native-skill Codex lane — copy whole, keep bodies runtime-neutral
date: 2026-08-20
owner: Reid W
status: superseded
amended_by: []
superseded_by: 0011
provenance: "[AGENT] (ratified by owner, 2026-08-20)"
seams: [scripts/build-codex-pack.sh, scripts/setup-codex.sh, codex-overrides/config.sh, future native skills]
supersedes: null
promoted_to: null
---

## Decision

The Codex build and install copy every file of an allowlisted skill directory, not just
`SKILL.md`. In exchange, native skill bodies must be written in runtime-neutral delegation
language: no sanitization pass exists for them, unlike command-derived skills, whose bodies
are rewritten by `sanitize_command_body_for_skill`. The `_my_x` → `my-x` name mapping applies
to native skills the same as commands.

## Why

The consequence of ADR 0009 at the Codex seam. A future skill author would plausibly assume
the command-lane rewrite pass applies to native skills too, write Claude-specific delegation
text (`subagent_type=`, "Explore agent", …), and break the Codex build — the dist scan in
`test_codex_orchestrator_pack.sh` forbids those terms in generated skills. The alternative, a
second rewrite engine for native skills, would duplicate the command lane's sanitizer and
drift from it.

Enforcement scope is deliberately partial: the dist scan checks `SKILL.md` files only, so
sibling instruction files carry the runtime-neutrality obligation by convention. Whether to
widen the scan is a spec-level follow-up, not part of this decision.

Two adjacent gotchas this record preserves: `NATIVE_SKILL_ALLOWLIST` in
`codex-overrides/config.sh` is opt-in — a skill directory absent from it is silently excluded
from the Codex build; and native skills take their Codex description from their own
frontmatter (there is no override map for them), so the description must be plain prose — a
leading `*` crashes Codex's YAML parse.

## Invariants established

- An allowlisted skill directory reaches `dist/codex/skills/` and the Codex install with all
  of its files.
- Native skill bodies (entry and siblings) contain no runtime-specific delegation vocabulary;
  the dist scan enforces this for `SKILL.md`, convention covers the rest.
- A native skill ships to Codex under the `my-<name>` mapping of its `_my_<name>` directory.

## Rejected alternatives

- A native-skill sanitization pass mirroring the command lane: rejected as a second rewrite
  engine that would have to be kept in step with the first.
- Shipping directory skills Claude-only: rejected; Codex parity for pack capabilities is in
  scope per the mental-alignment concept.
