---
id: 0009
title: Pack capabilities ship as directory skills, not commands with shared scripts
date: 2026-08-20
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [claude-pack, scripts/setup-global.sh, codex-overrides, future capabilities]
supersedes: null
promoted_to: null
---

## Decision

A pack capability is a skill directory — `claude-pack/skills/<name>/` holding a `SKILL.md`
entry point plus sibling instruction and feedback files — installed on Claude as one symlink
to the whole directory. This replaces the pattern of a command file delegating to a shared
spec in `claude-pack/scripts/`. `_my_mental_model` is the first migration and sets the shape
for the rest; the invocation (`/_my_<name>`) is unchanged.

## Why

Owner decision (2026-08-19): "I recognize this is slightly breaking a pattern, but this
feels like the right time to start migrating the Claude 'commands' to skills."

The command + shared-script pattern is the dominant precedent in the pack (product-lens, the
retired v1 mental-model builder). Without this record, a future agent adding or migrating a
capability would plausibly copy that pattern — including its absolute-path delegation into
`~/.claude/scripts/` — instead of the skill-directory shape. The directory form keeps a
capability's supporting instruction files and feedback bodies co-located with their entry
point, shipped and versioned as one unit; `setup-global.sh` already symlinks whole skill
directories, so siblings arrive with no installer change.

Scope note: the sweep migrating the remaining commands, and relocating the existing prose
specs out of `claude-pack/scripts/`, is deliberately deferred (owner, 2026-08-19: "ok let's
deal with the old stuff later"). This record governs new capabilities and future migrations,
not a bulk rewrite.

## Invariants established

- A new or migrated capability lives in `claude-pack/skills/<name>/`, entered through
  `SKILL.md`; long, improvable instructions live in sibling files the entry references.
- A global Claude install places the skill as a single symlink to the pack directory.
- Slash invocation is preserved across a command→skill migration; users see no change.

## Rejected alternatives

- Command file in `claude-pack/commands/` delegating to a spec in `claude-pack/scripts/`
  (the current dominant pattern): rejected as the shape for new capabilities because it
  scatters one capability across two trees and delegates by installed absolute path.
