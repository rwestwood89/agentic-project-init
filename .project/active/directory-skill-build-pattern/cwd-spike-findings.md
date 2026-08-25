# Spike: Codex skill working directory

**Status:** Complete — the assumption was disproved
**Owner:** Reid W
**Date:** 2026-08-20
**Branch:** anchor-on-the-point
**Commit:** 67d8991
**Triggered by:** `spec.md`, Open Questions / Deferred to design

## Summary of Findings

Activating a Codex skill does **not** change the working directory. The earlier B5 probe measured a
shell command that the agent ran from the skill directory; it did not establish a runtime rule.

Two fresh `codex exec` runs invoked the same repository skill. One launched with `-C` set to the
repository root, and the other with `-C` set to a nested directory. In both runs:

- `pwd` and the relative write landed in the `-C` launch directory;
- Codex read the selected skill from the absolute `SKILL.md` path in its available-skills inventory;
- the skill invoked a sibling script by joining that supplied path, and the script read a second
  sibling successfully; and
- no relative-write file appeared in the installed skill directory.

The spec's three answers are therefore:

1. **Relative project paths are safe.** They land under the Codex working root, which is normally
   the project directory.
2. **The supported control is session-level, not skill-level.** `codex -C/--cd <DIR>` selects the
   working root. Official frontmatter has only `name` and `description`; optional
   `agents/openai.yaml` has no working-directory field.
3. **A skill reaches siblings from its own supplied file path.** Resolve sibling paths relative to
   the directory containing the selected `SKILL.md`; do not depend on process cwd.

There is no defect in the roughly thirty command-derived skills that write relative `.project/…`
paths, and the eight project-relative paths in `_my_mental_model/SKILL.md` need no rewrite. The
Codex adapter only needs to translate the skill-directory vocabulary used to reach sibling files.

## Question / Goal

The assumption under test is that activating a Codex skill changes the process working directory
from the project directory to the installed skill directory. A relative write landing in the skill
directory would confirm it. A relative write landing in the Codex launch directory, with the skill
still reaching a sibling from its supplied `SKILL.md` path, would disprove it.

The probe answers the spec's three blocking questions:

1. Where does a relative write land during a Codex skill run?
2. Can the working directory be controlled by a supported setting, frontmatter field, or invocation
   flag?
3. When the working directory is the project directory, how does the skill reach its siblings?

## Log

### 2026-08-20 17:13 PDT — establish the supported surface

Commands:

```bash
codex --version
codex --help
codex exec --help
sed -n '1,240p' ~/.codex/config.toml
```

Observed:

- Installed runtime: `codex-cli 0.148.0`.
- Both interactive and non-interactive CLI help expose `-C, --cd <DIR>` as: "Tell the agent to use
  the specified directory as its working root."
- The local config has no skill working-directory setting.
- The official OpenAI skill documentation says Codex includes each skill's file path in the initial
  skills list. It defines `SKILL.md` frontmatter as `name` and `description`; optional
  `agents/openai.yaml` covers display metadata, invocation policy, and tool dependencies. Neither
  surface defines a skill-specific working directory.
- The same documentation says repository skills are discovered by scanning `.agents/skills` from
  the launch working directory up to the repository root. This ties skill discovery to the launch
  directory without saying that activation changes it.

Source: [Official OpenAI documentation: Build skills](https://learn.chatgpt.com/docs/build-skills).

### 2026-08-20 17:13 PDT — create the executable probe

Files:

- `cwd-spike/.agents/skills/codex-cwd-probe/SKILL.md` — tells Codex to derive the skill directory
  from the supplied `SKILL.md` path, invoke the sibling script by absolute path, and avoid `cd` or a
  shell workdir override.
- `cwd-spike/.agents/skills/codex-cwd-probe/probe.sh` — records its inherited working directory,
  reads a sibling token through the script directory, and performs one relative write.
- `cwd-spike/run-cwd-spike.sh` — installs only a temporary repository discovery symlink, runs the
  probe once from the repository root and once from a nested launch directory, records raw JSONL
  and filesystem evidence, then removes the discovery symlink.

The summary remains blank until both runs and evidence inspection complete.

### 2026-08-20 17:17 PDT — run from the repository root

Invocation:

```bash
codex exec --ephemeral --json --sandbox workspace-write \
  -C /home/rwestwood/agentic-project-init \
  '$codex-cwd-probe Run the probe exactly. Do not do any unrelated work.'
```

Observed:

```text
PWD_PHYSICAL=/home/rwestwood/agentic-project-init
SKILL_DIRECTORY_ARG=/home/rwestwood/agentic-project-init/.agents/skills/codex-cwd-probe
SCRIPT_DIRECTORY=/home/rwestwood/agentic-project-init/.project/active/directory-skill-build-pattern/cwd-spike/.agents/skills/codex-cwd-probe
SIBLING_TOKEN=SIBLING-READ-OK-8V3K
RELATIVE_TARGET_ABSOLUTE=/home/rwestwood/agentic-project-init/codex-cwd-relative-write.txt
RELATIVE_WRITE_EXISTS=yes
```

The discovery path was a temporary symlink. Codex received that absolute path in its skill
inventory. The sibling script resolved through the link to the scratch fixture. The relative write
landed at the repository root, not beside either copy of the skill.

Evidence: `cwd-spike/evidence/root-launch.{jsonl,final.txt,locations.txt,stderr}`.

### 2026-08-20 17:20 PDT — change only the launch working root

The same command and same skill ran with `-C` set to
`cwd-spike/nested-launch/`.

Observed:

```text
PWD_PHYSICAL=/home/rwestwood/agentic-project-init/.project/active/directory-skill-build-pattern/cwd-spike/nested-launch
SKILL_DIRECTORY_ARG=/home/rwestwood/agentic-project-init/.agents/skills/codex-cwd-probe
SIBLING_TOKEN=SIBLING-READ-OK-8V3K
RELATIVE_TARGET_ABSOLUTE=/home/rwestwood/agentic-project-init/.project/active/directory-skill-build-pattern/cwd-spike/nested-launch/codex-cwd-relative-write.txt
RELATIVE_WRITE_EXISTS=yes
```

Changing `-C` changed both `pwd` and the relative-write destination. Skill activation changed
neither. The raw JSONL shows the agent reading the exact supplied `SKILL.md` path and invoking the
sibling by its absolute path, with no `cd` in either command.

Evidence: `cwd-spike/evidence/nested-launch.{jsonl,final.txt,locations.txt,stderr}` and
`cwd-spike/evidence/skill-directory-check.txt` (`SKILL_DIRECTORY_WRITE=absent`).

### 2026-08-20 17:21 PDT — cleanup and interpretation

The runner's exit trap removed the temporary `.agents/skills/codex-cwd-probe` discovery symlink.
The two relative-write files were recorded in evidence and then removed. No user or pack skill was
changed.

The earlier B5 raw observation remains real: `pwd` printed the skill directory in that run. Its
interpretation was wrong. The earlier prompt asked Codex to exercise bare-relative sibling reads,
and the agent ran that diagnostic shell from the skill directory. A single command's chosen
working directory was mistaken for a harness-wide skill activation behavior. The controlled `-C`
runs isolate the two variables and falsify that conclusion.

## Reproduction

From the repository root:

```bash
bash .project/active/directory-skill-build-pattern/cwd-spike/run-cwd-spike.sh
```

Expected evidence is written under `cwd-spike/evidence/`. A successful run records one
`codex-cwd-relative-write.txt` in each `-C` launch directory, reports the sibling token
`SIBLING-READ-OK-8V3K`, leaves no relative-write file in the skill directory, and removes both
generated write files after recording them.

## Open Questions / Follow-ups

- The desktop/IDE host may expose the working-root choice differently from the CLI's `-C` flag.
  That host UI question does not block the design: the active session already reports the project
  root in its environment, and skill activation preserves it.
