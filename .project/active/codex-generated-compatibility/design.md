# Design: Codex Generated Compatibility Layer

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-04-18 14:02:24 PDT
**Branch:** codex-setup

---

## Overview

Design a generated Codex compatibility layer that uses `claude-pack/` as immutable input and produces installable Codex-native assets without introducing a second hand-maintained pack. Memory-dependent features are deliberately excluded in this phase.

## Related Artifacts

- **Spec:** `.project/active/codex-generated-compatibility/spec.md`
- **Research:** `.project/research/20260418-083015_codex-cli-compatibility-mapping.md`

---

## Goals and Constraints

### Goals

1. Reuse authored content from `claude-pack/`
2. Make Codex installation straightforward
3. Keep Codex-specific divergence small and explicit
4. Preserve future room for memory support

### Hard Constraints

1. Do not edit `claude-pack/`
2. Do not maintain a parallel authored `codex-pack/`
3. Do not implement memories, recall, or transcript persistence in this phase

---

## Key Design Decisions

### 1. Commands become prompts, not skills

Most `claude-pack/commands/_my_*.md` files represent explicitly invoked workflows. In Codex, those map more naturally to prompt files than to skills.

This avoids overloading skills as a substitute for slash commands and keeps user-invoked workflows explicit.

### 2. `claude-pack/` is input, `dist/codex/` is output

All generated Codex artifacts live under a dedicated output tree such as `dist/codex/`. Nothing under `claude-pack/` is edited, renamed, or rewritten.

### 3. Use a sparse override layer

Some Codex targets need metadata that is absent from Claude files, especially descriptions and file structure conventions. Instead of creating a second pack, add a tiny override layer outside `claude-pack/` for:

- prompt descriptions
- exclusion lists
- optional Codex-only wrapper text
- agent metadata defaults

### 4. Exclude memory-dependent features completely

The wrong move in phase 1 is partial emulation of memories. Excluding those flows keeps the compatibility layer coherent and avoids building on unstable assumptions about transcript storage.

### 5. Install by additive sync, not replacement

The installer should create or update only the managed Codex assets and leave unrelated `~/.codex/` content intact. This is especially important for user config, custom prompts, and existing agents.

---

## Proposed Repository Structure

```text
claude-pack/                       # canonical authored source, untouched
codex-overrides/
├── config.sh                      # shell-friendly metadata and exclusions
├── prompt-prefixes/               # optional preambles per generated prompt
├── skills/                        # optional Codex-only skill wrappers
└── agents/                        # optional Codex-only agent metadata

dist/
└── codex/
    ├── prompts/
    ├── agents/
    ├── skills/
    ├── hooks/
    ├── hooks.json
    ├── AGENTS.md
    └── manifest.json

scripts/
├── build-codex-pack.sh
└── setup-codex.sh
```

### Why `config.sh`

A shell-sourced config file avoids introducing a TOML or YAML write dependency into the build path. The existing repo already relies on shell-first tooling, and this keeps the generator easy to inspect and modify.

Example responsibilities:

- excluded commands
- excluded agents
- prompt descriptions
- skill conversion allowlist
- optional hook allowlist

---

## Conversion Model

### A. Commands -> `dist/codex/prompts/*.md`

Input:
- `claude-pack/commands/_my_spec.md`

Output:
- `dist/codex/prompts/spec.md`

Transformation rules:

1. Strip `_my_` prefix from filename
2. Generate prompt metadata block compatible with Codex prompt files
3. Preserve the core instructional body
4. Optionally prepend Codex-specific guidance from `codex-overrides/prompt-prefixes/<name>.md`
5. Use override descriptions when the source file lacks Codex-appropriate metadata

Supported initial command set:

- `_my_concept`
- `_my_research`
- `_my_spec`
- `_my_design`
- `_my_plan`
- `_my_implement`
- `_my_code_review`
- `_my_code_quality`
- `_my_quick_edit`
- `_my_git_manage`
- `_my_project_manage`
- `_my_project_find`
- `_my_wrap_up`
- `_my_review_design`
- `_my_audit_implementation`

Excluded command set:

- `_my_capture`
- `_my_memorize`
- `_my_recall`
- `_my_review_compact`

### B. Agents -> `dist/codex/agents/*.toml`

Input:
- `claude-pack/agents/*.md`

Output:
- `dist/codex/agents/<name>.toml`

Transformation rules:

1. Parse or infer agent name from filename
2. Provide generated `name`, `description`, and `developer_instructions`
3. Layer on Codex-specific settings only when explicitly configured
4. Exclude memory-dependent agents such as `recall`

Initial behavior:

- Non-memory agents convert directly
- Memory agents are omitted and listed in the manifest

### C. Rules -> `dist/codex/AGENTS.md`

Input:
- `claude-pack/rules/*.md`

Output:
- `dist/codex/AGENTS.md`

Transformation rules:

1. Concatenate rule files in stable order
2. Wrap each source file in a named section
3. Add a small generated header explaining provenance

This keeps rule maintenance in the Claude-authored files while giving Codex the consolidated format it expects.

### D. Skills -> `dist/codex/skills/*/SKILL.md`

Input:
- `claude-pack/skills/*`

Output:
- `dist/codex/skills/<name>/SKILL.md`

Transformation rules:

1. Create required directory-per-skill structure
2. Add Codex-required metadata: `name` and `description`
3. Preserve the skill body when compatible
4. Allow Codex-only wrapper text from `codex-overrides/skills/`

Important constraint:

- Do not auto-convert command files into skills unless there is a specific reason. Prompt files remain the primary compatibility target for explicit workflows.

### E. Hooks -> `dist/codex/hooks/` and `dist/codex/hooks.json`

Input:
- `claude-pack/hooks/*`

Output:
- reusable scripts copied into `dist/codex/hooks/`
- generated `dist/codex/hooks.json`

Transformation rules:

1. Include only hooks that still make sense without memories
2. Exclude `precompact-capture.sh`, `capture.sh`, and transcript tooling for phase 1
3. If no supported hooks remain, emit no `hooks.json`

Rationale:

Hooks are not the core value proposition for phase 1. They should not drive risky config mutation in `~/.codex/config.toml`.

---

## Build Flow

```text
claude-pack/ + codex-overrides/
        |
        v
scripts/build-codex-pack.sh
        |
        v
dist/codex/
```

### Build Steps

1. Load `codex-overrides/config.sh`
2. Remove any prior generated `dist/codex/`
3. Generate prompt files from supported Claude commands
4. Generate agent TOML files from supported Claude agents
5. Generate `AGENTS.md` from Claude rules
6. Generate Codex skills from Claude skills where applicable
7. Copy any supported hook scripts and generate `hooks.json` if needed
8. Write a `manifest.json` summarizing:
   - source commit
   - generated timestamp
   - included assets
   - excluded assets

### Manifest Purpose

The manifest gives the installer and the developer a deterministic record of what happened during generation. It also makes exclusions explicit.

---

## Install Flow

```text
dist/codex/
    |
    v
scripts/setup-codex.sh
    |
    v
~/.codex/
```

### Install Responsibilities

1. Validate that `dist/codex/` exists
2. Create missing target directories:
   - `~/.codex/prompts/`
   - `~/.codex/agents/`
   - `~/.codex/skills/`
   - `~/.codex/hooks/` when needed
3. Install generated files by symlink or copy
4. Record source metadata in a managed marker file
5. Report exclusions from the manifest

### Config Handling Strategy

`~/.codex/config.toml` is the riskiest file to modify because naive appends can create invalid TOML or duplicate tables.

For phase 1:

1. Do not rewrite `config.toml` wholesale
2. Install prompts, agents, skills, and `AGENTS.md` without requiring config edits
3. Only attempt hook activation as a best-effort additive step when it is unambiguous
4. If hook activation is not safe, write a clear post-install instruction rather than mutating config destructively

This keeps the initial Codex support useful without making hook activation a blocker.

---

## Detailed Component Design

### `scripts/build-codex-pack.sh`

Responsibilities:

- shell entrypoint for all generation
- stable naming rules
- exclusion enforcement
- manifest generation

Failure modes:

- missing source directories
- unsupported file shape
- missing required override metadata for a converted asset

Failure behavior:

- fail fast on structural errors
- skip intentionally excluded items
- print a build summary at the end

### `scripts/setup-codex.sh`

Responsibilities:

- install or update generated assets in `~/.codex/`
- preserve unrelated user assets
- stay idempotent

Recommended behavior:

- symlink generated assets where feasible for easy updates
- avoid deleting unmanaged user files
- keep a managed marker such as `.agentic-pack-codex-source`

### `codex-overrides/config.sh`

Suggested contents:

```bash
EXCLUDED_COMMANDS=(
  "_my_capture"
  "_my_memorize"
  "_my_recall"
  "_my_review_compact"
)

EXCLUDED_AGENTS=(
  "recall"
)
```

Optionally:

- prompt description variables
- agent description variables
- skill allowlist

---

## Data and Naming Rules

### Prompt naming

- `_my_spec.md` -> `spec.md`
- `_my_project_manage.md` -> `project-manage.md` or `project_manage.md`

Recommendation:

Use hyphenated Codex prompt filenames derived from the semantic command name. Keep the mapping stable and document it in the manifest.

### Section provenance

Generated `AGENTS.md` should contain per-source headings such as:

```markdown
## From `context-loading.md`
...
```

This makes debugging and future edits straightforward.

---

## Risks and Mitigations

### Risk: Claude command bodies are not ideal prompt bodies

Mitigation:
- allow a small per-prompt Codex wrapper prefix
- keep the original command body intact after the wrapper

### Risk: `config.toml` merge breaks user setup

Mitigation:
- treat hook activation as optional in phase 1
- prefer explicit instruction over destructive mutation

### Risk: hidden drift between source and generated layer

Mitigation:
- never hand-edit `dist/codex/`
- regenerate on demand
- include source commit in manifest

### Risk: unsupported memory features confuse users

Mitigation:
- show exclusions clearly in build and install output
- document them in the generated manifest and README updates

---

## Rollout Plan

### Phase 1

1. Implement `build-codex-pack.sh`
2. Implement `setup-codex.sh`
3. Convert supported commands into prompts
4. Convert supported agents into Codex agents
5. Generate `AGENTS.md`
6. Exclude all memory-related assets

### Phase 2

1. Improve prompt wrappers
2. Expand skill conversion beyond minimal compatibility
3. Revisit safe hook activation

### Deferred

1. Memory capture and recall
2. Plugin packaging
3. Project-local `.codex/` vendoring

---

## Testing Strategy

1. Build output validation
   - expected files exist
   - excluded files do not exist

2. Idempotence validation
   - repeated builds produce the same file set
   - repeated installs do not duplicate artifacts

3. Local Codex smoke test
   - prompts appear under the Codex prompt surface
   - generated agents are discoverable
   - generated `AGENTS.md` is loaded in a test repo

4. Safety validation
   - existing unrelated `~/.codex/` content remains intact after install

---

## Open Questions

1. Should generated prompt filenames use hyphens or underscores in Codex?
2. Should the installer symlink generated assets from `dist/codex/` or copy them into `~/.codex/`?

These do not block the architecture. The compatibility model remains the same either way.
