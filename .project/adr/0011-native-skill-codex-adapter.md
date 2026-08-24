---
id: 0011
title: Skill directories go through the Codex adapter, same as commands
date: 2026-08-20
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [scripts/build-codex-pack.sh, scripts/setup-codex.sh, codex-overrides/config.sh, claude-pack/skills, future native skills]
supersedes: 0010
promoted_to: null
---

## Decision

Every file of an allowlisted skill directory goes through the same Codex adapter that command
files already use — the substitution dictionary in `sanitize_command_body_for_skill`
(`scripts/build-codex-pack.sh:133-160`) — applied recursively over the whole directory, not just
`SKILL.md`. Skill bodies may therefore be written in the pack's Claude-native vocabulary. When a
skill body needs a harness-specific phrase, that phrase's translation belongs in the dictionary.
The `_my_x` → `my-x` name mapping is unchanged from 0010.

## Why

Owner decision (2026-08-20), reversing 0010: *"it seems like the only good solution is just
extending the same 'codex adapter' pattern from 'command' to 'skill'."*

0010 required native skill bodies to be runtime-neutral, on the reasoning that no translation pass
existed for them and a second one shouldn't be built. The first real directory skill shows the
requirement cannot be met. `claude-pack/skills/_my_mental_model/SKILL.md` has to state two things
that differ per harness:

- **Where the skill directory is.** Its coordinator hands an absolute path to a *spawned* agent.
  That agent is not a skill invocation and is told nothing about the directory. Claude prepends
  `Base directory for this skill: <abs path>` and runs with the project directory as the working
  directory; Codex prepends nothing and runs with the skill directory as the working directory.
- **How to spawn a context-inheriting agent.** `subagent_type: "fork"` on Claude,
  `fork_turns: "all"` on Codex.

Commands never hit this, which is why 0010 looked sufficient when it was written: a command is a
single file with nothing beside it, so no pack file had ever needed to locate itself. A skill
directory is the first pack artifact whose files have neighbors.

The cost this record accepts, stated plainly so a future author is not surprised by it: an authored
skill body and the dictionary are two things kept in step by hand. A harness-specific phrase the
dictionary does not know ships clean and surfaces only when the skill runs on Codex. The owner
rejected guarding that with a test, because a test can only list phrases someone already thought
of, and a phrase you can name is one you would have put in the dictionary instead. The accepted
detector is the skill failing on the runtime: *"if the build fails, the build fails"* / *"if the
build doesn't fail, I find out when the skill fails"* — meaning no tolerance is built for failure,
and **no new failure conditions are added**. `NATIVE_SKILL_ALLOWLIST` stays opt-in and silent.

## Invariants established

- An allowlisted skill directory reaches `dist/codex/skills/` and the Codex install with all of its
  files, at the same relative paths, nested directories included.
- Every file in that directory passes through the adapter. No file is copied to Codex untranslated
  on the assumption its content is runtime-neutral.
- A skill body may contain harness-specific phrasing. The dictionary is where its translation
  lives, and adding the phrase to the dictionary is part of the change that introduces it.
- An unlisted harness-specific phrase is not caught by any check. It ships and surfaces at Codex
  runtime. This is accepted, not an oversight.
- A native skill ships to Codex under the `my-<name>` mapping of its `_my_<name>` directory, and
  the derived name is written into the generated frontmatter, because Codex registers the
  frontmatter `name` and does not answer to the directory name.

## Rejected alternatives

- Requiring runtime-neutral skill bodies with no translation pass (0010's decision): rejected
  because the first real skill cannot be written that way — locating its own directory and spawning
  a context-inheriting agent both differ per harness.
- A second sanitization engine specific to native skills (0010's rejected alternative, still
  rejected): the command dictionary is the one that exists and the one that already covers the
  pack's stock delegation vocabulary.
- A test that enumerates harness-specific phrases and fails when one reaches `dist/`: rejected by
  the owner — it can only catch phrases already known, and a known phrase belongs in the dictionary.
