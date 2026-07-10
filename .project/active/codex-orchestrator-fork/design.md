# Design: Codex Orchestrator Fork

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-07T21:05:32-07:00
**Branch:** main
**Complexity:** HIGH

---

## Overview

Add a Codex-native orchestration lane beside the existing Claude orchestrator. The lane keeps the pipeline judgment model, but replaces the Claude-specific command body, helper script, rule wording, and output parsing with Codex-specific generated assets built around `codex exec`.

## Related Artifacts

- **Spec:** `.project/active/codex-orchestrator-fork/spec.md`
- **Claude orchestrator design:** `.project/active/workflow-orchestrator/design.md`
- **Codex compatibility design:** `.project/active/codex-generated-compatibility/design.md`
- **Generated Codex orchestrator today:** `dist/codex/skills/my-orchestrate/SKILL.md`
- **Official Codex noninteractive reference:** `/tmp/codex-manual.md` fetched from `developers.openai.com/codex/codex-manual.md`

## Research Findings

- The existing generator already has the right extension point for command-derived skills. It maps `_my_foo_bar.md` to `my-foo-bar`, checks for `codex-overrides/command-skill-prefixes/<name>.md`, then appends the sanitized Claude body (`scripts/build-codex-pack.sh:226-259`). That prefix hook is useful for small guidance, but not strong enough for `my-orchestrate` because the appended body still tells Codex to call Claude paths.
- The generator currently converts only inline command bodies, native skills, agents, rules, and hooks. It creates `dist/codex/agents`, `dist/codex/skills`, and `dist/codex/hooks`, but no `dist/codex/scripts` lane (`scripts/build-codex-pack.sh:219-221`).
- Generated `AGENTS.md` is a straight concatenation of `claude-pack/rules/*.md` (`scripts/build-codex-pack.sh:323-331`). That preserves meaning but also preserves active Claude instructions such as `/_my_wrap_up`, `/_my_pipeline`, and `~/.claude/commands/_my_pipeline.md` (`dist/codex/AGENTS.md:17-18`, `dist/codex/AGENTS.md:68-81`).
- The installer has a good managed-file pattern: `install_path` skips user-authored files unless forced, supports dry-run/copy/symlink, and increments install/skip counts (`scripts/setup-codex.sh:75-138`). It installs agents, skills, `AGENTS.md`, and hooks, but not scripts (`scripts/setup-codex.sh:196-230`).
- The Claude helper is the mechanical model to fork: `run`/`resume`, stdin body, dry-run, log dir, timeout, stage-specific permission defaults, and compact JSON output (`claude-pack/scripts/orchestrate-stage.sh:8-21`, `claude-pack/scripts/orchestrate-stage.sh:41-87`). The Codex helper cannot reuse its invocation or parser because it composes `/_my_<stage>`, calls `claude`, and parses Claude's result array (`claude-pack/scripts/orchestrate-stage.sh:72-80`, `claude-pack/scripts/orchestrate-stage.sh:101-118`).
- The current generated `my-orchestrate` is not safe as executable Codex guidance. It says “Claude-only,” points at `~/.claude/scripts/orchestrate-stage.sh`, says stages are `/_my_*` commands, and still names the Claude helper path in Related (`dist/codex/skills/my-orchestrate/SKILL.md:16-17`, `dist/codex/skills/my-orchestrate/SKILL.md:31-46`, `dist/codex/skills/my-orchestrate/SKILL.md:73-74`).
- Codex noninteractive mode is the correct primitive. Official docs say noninteractive mode is invoked with `codex exec`, streams progress to stderr, emits the final message to stdout, supports JSONL via `--json`, can write the final message via `--output-last-message`, supports `--output-schema`, and resumes with `codex exec resume <SESSION_ID>` (`/tmp/codex-manual.md:8882-8887`, `/tmp/codex-manual.md:8906-8918`, `/tmp/codex-manual.md:8945-8967`, `/tmp/codex-manual.md:8969-8997`, `/tmp/codex-manual.md:9048-9058`).
- Codex sandboxing differs from Claude permission modes. The docs say `codex exec` defaults to read-only and automation should explicitly choose the least needed sandbox, with `workspace-write` for edits and `danger-full-access` only in controlled environments (`/tmp/codex-manual.md:8930-8941`). The local spike found that read-only did not reliably block shell writes in this environment, so sandbox flags should be treated as intent, not as the only safety boundary.
- The live spike confirmed `thread.started.thread_id` is usable with `codex exec resume`, but resume has a different argv shape from fresh exec and does not accept `--sandbox`. See `.project/active/codex-orchestrator-fork/spike-findings.md`.
- Existing validation focuses on Claude source sync. `scripts/test_pipeline_sync.sh` compares only `claude-pack/rules/pipeline.md` and `claude-pack/commands/_my_pipeline.md` using the `<!-- pipeline-shape -->` marker (`scripts/test_pipeline_sync.sh:14-52`). The Codex lane needs a second check after generation.

## Core Concept

The Codex orchestrator fork is a generated Codex product made from two kinds of input: Claude-derived workflow content where direct conversion is still correct, and Codex-authored overrides where platform mechanics are different. The stage workflows stay as `$my-*` skills, but orchestration itself becomes a full Codex replacement skill that calls a Codex helper. The helper is the only place that knows `codex exec` details; the orchestrator skill remains the judgment layer that routes work, answers yielded questions, manages review loops, and records decisions.

This is the right split because the failure is not the pipeline model. The failure is that direct conversion leaves executable Claude mechanics inside Codex instructions. A full replacement for only the unsafe surfaces keeps duplication limited while avoiding a brittle pile of regex edits against a Claude command body.

## Key Bets

- **B1. Codex can run the existing command-derived stage skills headlessly well enough for the orchestrator to use their final messages as the stage channel.** *If false -> the helper works mechanically, but stages fail to produce coherent artifacts or ask/resume cleanly, so Codex orchestration cannot reuse the current generated skill set.*
- **B2. A small set of Codex-specific overrides is enough to make orchestration safe without rewriting the whole compatibility layer.** *If false -> stale Claude assumptions remain in too many stage skills or rules, and the fork becomes a broader Codex pack redesign.*
- **B3. Codex JSONL plus `--output-last-message` gives enough stable data to resume and route stages.** *If false -> the helper cannot reliably return `session_id` and final message, and orchestration needs a different protocol or API surface.*

## Key Decisions

- **D1. Replace the generated `my-orchestrate` body completely for Codex.** *Rejected: prefix-only override. The current generator would still append lines that say Claude-only, call `~/.claude/scripts/orchestrate-stage.sh`, and describe `/_my_*` stages, which are active instructions rather than harmless provenance.*
- **D2. Add a Codex-only script lane under `codex-overrides/scripts/` -> `dist/codex/scripts/` -> `~/.codex/scripts/`.** *Rejected: asking the user to keep helper scripts outside the generated install. The skill needs a stable helper path, and the installer already owns managed user-level Codex assets.*
- **D3. Keep the helper shell-first and structurally parallel to the Claude helper.** *Rejected: Python helper for the first fork. Shell matches the existing scripts, keeps dependency weight low, and can still delegate JSONL parsing to a tiny Python block where structured parsing is needed.*
- **D4. Use `--output-last-message` as the authoritative stage result and JSONL only for envelope data.** *Rejected: requiring every stage to produce schema-conformant JSON in v1. The existing orchestration protocol expects prose plus `ARTIFACT: <path>`, and forcing schemas into every stage is a broader prompt change.*
- **D5. Build separate argv paths for fresh run and resume.** *Rejected: one shared argv builder. The spike proved `codex exec resume` does not accept the same flags as fresh `codex exec`, especially `--sandbox`.*
- **D6. Transform Codex-facing rule text at generation time for known workflow references.** *Rejected: maintaining a full parallel rule pack. A targeted transform for `/_my_*`, selected `.claude` path references, and auto-memory lines fixes executable guidance while keeping rule authorship in `claude-pack/rules/`.*
- **D7. Add Codex-specific validation instead of widening the existing Claude pipeline sync test.** *Rejected: making `test_pipeline_sync.sh` understand both source and generated products. A separate test keeps the current Claude invariant simple and checks the generated Codex product after build.*

## Architecture

The build has three lanes.

1. **Common generated lane.** Existing command-derived skills, native skills, agents, and hooks continue to come from `claude-pack/` plus `codex-overrides/config.sh`. This lane keeps the current command name mapping and managed output tree.
2. **Codex replacement lane.** A new override directory supplies full replacement files for generated skills whose body cannot safely be inherited from Claude. The first file is `codex-overrides/command-skill-replacements/orchestrate/SKILL.md` or an equivalent replacement path. When present, the generator writes that file to `dist/codex/skills/my-orchestrate/SKILL.md` instead of appending the sanitized Claude command.
3. **Codex support lane.** A new scripts/rules support path copies Codex-only helper scripts and applies targeted Codex wording transforms to global rules before writing `dist/codex/AGENTS.md`.

Runtime flow:

1. Codex loads global rules from `~/.codex/AGENTS.md` and skills from `$HOME/.agents/skills`.
2. The user invokes `$my-orchestrate` with a concept/outcomes path or inline objective.
3. The Codex orchestrator reads the objective, follows `$my-pipeline`, and calls `~/.codex/scripts/orchestrate-stage-codex.sh run <stage>` for each stage.
4. The helper maps `<stage>` to `$my-<stage-with-hyphens>`, composes the noninteractive prompt and preamble, then runs `codex exec --json --output-last-message <file> --sandbox <mode> ...`.
5. The helper returns compact JSON to the orchestrator, shaped around `{session_id, result, raw, stderr, is_error}`. The orchestrator reads `result` as prose, just like the Claude design.
6. For questions or review feedback, the orchestrator calls `orchestrate-stage-codex.sh resume <session_id>`, and the helper invokes `codex exec resume <session_id>` with the next message.

The stage helper owns mechanics. The replacement skill owns judgment. The generator/installer owns making both available in a fresh Codex environment.

## Required Invariants

- The Claude orchestrator files remain unchanged unless a later consolidation task explicitly changes them.
- Generated Codex `my-orchestrate` contains no active references to `~/.claude`, `claude -p`, or `/_my_*` stage invocation.
- Stage names have one mapping: remove any leading `_my_`, convert underscores to hyphens, then prefix with `$my-` when composing a skill prompt.
- The helper always keeps raw JSONL, final-message, and stderr logs for debugging.
- The helper returns nonzero when `codex exec` fails, times out, produces no thread id, or produces no final message.
- Fresh run sandboxing is explicit and least-permissive by stage; resume omits `--sandbox` unless a future Codex version supports it.
- Live validation runs in disposable repos/worktrees because local read-only sandboxing did not reliably block shell writes.
- Installer behavior remains additive and non-destructive for user-authored files.

## Component Overview

- **`codex-overrides/command-skill-replacements/orchestrate/SKILL.md`**: Full Codex-authored replacement for the generated orchestration skill. It keeps the orchestration policy but uses `$my-*`, `codex exec`, `~/.codex/scripts/orchestrate-stage-codex.sh`, Codex sandbox language, and Codex JSON result names.
- **`codex-overrides/scripts/orchestrate-stage-codex.sh`**: Forked helper for one Codex stage run or resume. It mirrors the Claude helper interface but calls `codex exec` and parses Codex outputs.
- **`codex-overrides/scripts/orchestrate-preamble-codex.md`**: Codex-specific noninteractive preamble. It can reuse most of the Claude preamble, but names Codex stages as skills and avoids Claude permission/session wording.
- **`scripts/build-codex-pack.sh`**: Extended to create `dist/codex/scripts`, copy Codex override scripts, use full skill replacements when present, transform generated rules, and include scripts/replacements in `manifest.json`.
- **`scripts/setup-codex.sh`**: Extended to install `dist/codex/scripts/*` into `~/.codex/scripts/` with the existing `install_path` rules.
- **`scripts/test_codex_orchestrator_pack.sh`**: New generated-product test. It runs after `build-codex-pack.sh` and checks for expected helper files, replacement skill content, rule transforms, pipeline shape preservation, and absence of forbidden active Claude references.

## Non-Goals

- No shared helper abstraction between Claude and Codex in this pass.
- No full rewrite of every command-derived skill.
- No Codex memory/recall/compaction support.
- No full autonomous live pipeline as a required test.
- No mutation of `~/.codex/config.toml` for this feature.

## Implementation Notes

The Codex helper interface should stay familiar:

```text
orchestrate-stage-codex.sh run <stage> [opts]
orchestrate-stage-codex.sh resume <session_id> [opts]
```

Suggested helper options for `run`: `--model`, `--timeout`, `--sandbox`, `--cd`, `--log-dir`, `--preamble`, and `--dry-run`. Suggested helper options for `resume`: `--model`, `--timeout`, `--log-dir`, `--preamble`, and `--dry-run`. Skip `--budget` for v1 unless Codex exposes a direct per-call budget flag in the installed CLI. Do not pass `--sandbox` to `codex exec resume` in the current CLI.

Default sandbox policy should be stage-aware:

- `read-only`: review-only/reference stages where no artifact is expected.
- `workspace-write`: artifact-producing stages, including `spec`, `design`, `plan`, `implement`, and `pre_pr`.
- `danger-full-access`: never default. Leave it as an explicit opt-in only.

The helper should parse JSONL defensively:

- first `thread.started.thread_id` becomes `session_id`;
- `turn.failed` or `error` marks the call failed;
- the final message file from `--output-last-message` becomes `result`;
- raw paths are returned so the orchestrator can inspect logs only when needed.

Rule transforms should be narrow and auditable. Start with `/_my_([a-z_]+)` -> `$my-<hyphenated>`, `~/.claude/commands/_my_pipeline.md` -> `$HOME/.agents/skills/my-pipeline/SKILL.md`, and remove or rewrite auto-memory claims that are not true in Codex. Keep source headings so provenance remains visible.

## Potential Risks

- **Codex resume id format changes or differs from docs.** Mitigation: make the smoke test prove `thread.started.thread_id` can be passed to `codex exec resume`, and fail clearly if not.
- **Stage skills retain hidden Claude assumptions.** Mitigation: v1 validates the orchestrator and global rules strictly, then smoke-tests one document stage before claiming the fork works.
- **Rule transforms overreach.** Mitigation: keep transforms small, add tests around exact known phrases, and preserve source headings for review.
- **Scripts installed under `~/.codex/scripts` conflict with user files.** Mitigation: use existing managed-file detection and skip user-authored files unless `--force` is passed.
- **Nested Codex calls consume unexpected time or tokens.** Mitigation: require dry-run validation, keep a stage timeout, and start live validation with one low-risk stage.

## Integration Strategy

This fits as an extension of the existing generated compatibility layer. `claude-pack/` remains the main authored source for ordinary workflow commands. `codex-overrides/` becomes the explicit home for Codex-only behavior where direct conversion is wrong. The generated `dist/codex/` tree remains disposable and installable with `scripts/setup-codex.sh`.

The first implementation should not alter the Claude orchestrator or its tests. Once the Codex fork is proven, a later consolidation task can decide whether the two helpers should share a common template or stay separate.

## Validation Approach

- Run `scripts/build-codex-pack.sh` and inspect `dist/codex/manifest.json` for scripts and replacement metadata.
- Run `scripts/setup-codex.sh --dry-run` and confirm scripts would install under `~/.codex/scripts/`.
- Add and run `scripts/test_codex_orchestrator_pack.sh` to verify:
  - `dist/codex/skills/my-orchestrate/SKILL.md` is the Codex replacement;
  - no active `~/.claude/scripts/orchestrate-stage.sh`, `claude -p`, or `/_my_` references remain in Codex orchestrator instructions;
  - generated `AGENTS.md` points to `$my-*` and Codex skill paths for workflow guidance;
  - pipeline shape is preserved after syntax mapping;
  - helper dry-run emits `$my-spec` for `run spec` and `$my-spec-review` for `run spec_review`.
- Run the Codex helper in `--dry-run` mode for representative stages.
- Optional live smoke test: run one low-risk stage in a temporary git worktree with `codex exec --sandbox workspace-write`, then resume it once if the stage asks a question.

## Next-Stage Handoff

Treat these as fixed for planning:

- Use a full Codex replacement for `my-orchestrate`.
- Add `codex-overrides/scripts` and install generated scripts to `~/.codex/scripts`.
- Keep the helper shell-first and close to the Claude helper interface.
- Use `--output-last-message` for the stage result and JSONL for `thread_id`/error envelope data.
- Add a Codex generated-product validation script rather than expanding the Claude pipeline sync test.

Still risky and worth de-risking early:

- Already confirmed by spike: `thread.started.thread_id` is the correct resume id in the local CLI.
- Already confirmed by spike: command-derived skills can run through `codex exec` with `$my-*` invocation and produce usable final messages/artifacts.
- De-risk early in implementation: dry-run should catch invalid resume argv before any live model call.
- Decide during implementation whether rule transforms live as inline shell/perl logic or small helper functions in `build-codex-pack.sh`.

---

Next Step: After approval -> `$my-plan`
