# Spec: Codex Orchestrator Fork

**Status:** Complete
**Owner:** Reid W
**Created:** 2026-07-07T21:05:32-07:00
**Complexity:** HIGH
**Branch:** main

---

## Problem

The Claude workflow orchestrator now has a working shape: a top-level judgment agent delegates each pipeline stage to a headless helper, reads each stage result, resumes stages when it must answer questions or feed back reviews, and leaves artifacts plus commits behind. The Codex compatibility layer currently exposes `my-orchestrate` as a generated skill, but that skill still contains Claude-only instructions: it says to run from a Fable session, calls `~/.claude/scripts/orchestrate-stage.sh`, invokes `/_my_*` commands, and assumes Claude JSON result fields.

Codex has a comparable headless primitive in `codex exec`, but its mechanics differ enough that the generated skill is not usable as-is. The first Codex implementation should be a fork, not a consolidation pass. The existing Claude command and helper work and should remain stable while a Codex-native path proves itself.

The work is to create a Codex orchestration fork that can run the same project pipeline through Codex-native skills and `codex exec`, with clear generated instructions, installable helper scripts, and tests that catch stale Claude references in Codex-facing assets.

## Success Criteria

- [x] `my-orchestrate` in Codex gives usable Codex-native instructions and no longer tells Codex to call `~/.claude/scripts/orchestrate-stage.sh` or `/_my_*` commands for active execution.
- [x] A Codex-specific stage helper can start and resume one pipeline stage through `codex exec`, returning a stable machine-readable summary that includes the Codex session/thread id and the final stage message.
- [x] The Codex fork uses `$my-*` skills or equivalent Codex skill invocation language for stages, with underscore-to-hyphen conversion handled consistently.
- [x] The generated Codex install includes any helper scripts or script instructions needed by the Codex orchestrator.
- [x] The generated Codex `AGENTS.md` and pipeline guidance describe available commands/skills in Codex terms, or explicitly mark any Claude wording as source provenance rather than executable guidance.
- [x] The existing Claude orchestrator command, helper script, setup flow, and tests remain working and are not rewritten for this first Codex implementation.
- [x] Validation covers the generator, installer, stale-reference checks, and a dry-run or low-risk smoke test of the Codex stage helper.

## Known Requirements

- **[NEED]** The first implementation is a fork for Codex, not an edit-in-place conversion of the Claude orchestrator. Some duplication is acceptable to demonstrate that the Codex path works before consolidating shared concepts.
- **[HARD]** The Claude implementation must remain intact: `claude-pack/commands/_my_orchestrate.md`, `claude-pack/scripts/orchestrate-stage.sh`, `claude-pack/scripts/orchestrate-preamble.md`, and `scripts/setup-global.sh` continue to support the Claude path.
- **[HARD]** Codex headless execution uses `codex exec`, not `claude -p`. The local CLI exposes `codex exec`, `codex exec resume`, `--json`, `--output-last-message`, `--output-schema`, `--sandbox`, and `--cd`, so the helper must be designed around those semantics.
- **[HARD]** Codex final-output parsing cannot assume Claude's `--output-format json` result array, `result` field, `session_id` field, or `total_cost_usd` field. Codex emits JSONL events with a `thread.started` event and can write the final message to a file with `--output-last-message`.
- **[HARD]** Codex stage invocations must use Codex skill names such as `$my-spec`, `$my-spec-review`, and `$my-pre-pr`, not Claude slash commands such as `/_my_spec`.
- **[HARD]** Stage name mapping must be deterministic: pipeline names that use underscores map to Codex skill names with hyphens, for example `concept_design` to `my-concept-design`, `spec_review` to `my-spec-review`, and `pre_pr` to `my-pre-pr`.
- **[HARD]** Any Codex helper script needed at runtime must be generated and installed into a Codex-owned or clearly documented user path. The current `scripts/setup-codex.sh` installs agents, skills, hooks, and `AGENTS.md`, but not scripts.
- **[NEED]** Codex `my-orchestrate` should preserve the same orchestration intent as the Claude command: autonomous routing, pipeline stage delegation, review loops, bounded iteration, context discipline, and decision-focused commits.
- **[NEED]** Codex `my-orchestrate` should deviate from the Claude command only where the platform requires it: invocation syntax, helper path, output parsing, session resume, sandbox flags, model flags, and references to available skills.
- **[NEED]** Codex-facing rules should point users and agents at Codex skills. Examples: use `$my-spec` instead of `/_my_spec`, `$my-plan` instead of `/_my_plan`, `$my-audit` instead of `/_my_audit`, and `$my-wrap-up` instead of `/_my_wrap_up`.
- **[NEED]** The always-on pipeline guidance in generated `AGENTS.md` should not tell Codex to run `/_my_pipeline` or read `~/.claude/commands/_my_pipeline.md`. It should point to `$my-pipeline` and Codex skill locations.
- **[NEED]** The Codex fork should keep context lean in the same way as the Claude orchestrator: the orchestrator primarily reads final stage messages, artifact paths, and selected artifacts only when a decision needs them.
- **[NEED]** The Codex helper should expose a dry-run mode that prints the composed `codex exec` command and prompt without making model calls, so generator and prompt-shape tests do not require network or model spend.
- **[NEED]** The installer should remain non-destructive. It may install managed Codex scripts, but it must not overwrite unrelated user scripts or config without `--force`.
- **[INFERRED]** Codex-specific authored overrides belong under `codex-overrides/`, because that is the existing sparse divergence layer for generated Codex assets.
- **[INFERRED]** A practical layout is `codex-overrides/scripts/` as authored Codex-only helper input, generated to `dist/codex/scripts/`, and installed to `~/.codex/scripts/`.
- **[INFERRED]** A practical way to fork `my-orchestrate` without editing `claude-pack` is a command-skill override under `codex-overrides/command-skill-prefixes/orchestrate.md` or a stronger replacement mechanism if prefix-only text cannot reliably override the Claude-specific body.
- **[INFERRED]** Some generated Codex skills still contain Claude-era wording such as `Task tool with subagent_type=Explore`. This work should handle wording that blocks Codex orchestration, but it does not need to fully rewrite every command-derived skill unless that wording prevents the orchestrator from running stages.
- **[INFERRED]** A small live smoke test can use a low-risk document stage, likely `$my-spec` or `$my-pipeline`, before attempting implementation stages with `workspace-write`.

## Non-Goals

- Do not consolidate Claude and Codex orchestration into one shared helper in this work.
- Do not remove or degrade the existing Claude orchestrator path.
- Do not implement Codex memory, recall, transcript capture, or compaction equivalents.
- Do not redesign the whole Codex compatibility layer from command-derived skills back to prompts.
- Do not run a full autonomous end-to-end implementation pipeline as the first validation target.
- Do not require broad `danger-full-access` as the default Codex execution mode.

## Open Questions / Deferred to design

- Whether `my-orchestrate` should be generated from the Claude source with a strong Codex override, or supplied as a fully Codex-authored skill fork under `codex-overrides/`. Prefix-only overrides may leave too much stale Claude instruction in the body.
- The exact Codex helper interface. It should probably mirror the Claude helper shape (`run <stage>`, `resume <session_id>`) but the returned JSON fields need to be chosen around Codex JSONL and final-message files.
- Whether the helper should use `--output-schema` to force the final stage response into a structured shape, or keep the existing prose-plus-`ARTIFACT:` convention and parse only the Codex JSONL envelope.
- How to identify the correct resume id from Codex output across versions. `thread.started.thread_id` appears to be the likely field, but the implementation should prove this with a smoke test.
- The default Codex sandbox policy by stage. A likely split is `read-only` for reference/review-only stages, `workspace-write` for artifact-producing stages, and a stricter opt-in for broad project commands.
- Whether Codex `exec` model selection should be exposed in the helper with a default, or left to user config/profile for the first implementation.
- Whether generated Codex rules should be transformed generally with a mapping pass (`/_my_foo` to `$my-foo`, `~/.claude` to Codex paths where applicable), or handled with targeted Codex-specific rule overrides for pipeline and workflow accountability.
- Whether to add a Codex-specific pipeline sync test separate from `scripts/test_pipeline_sync.sh`, or extend that test to compare Claude source, generated Codex skill, and generated Codex `AGENTS.md` after applying the expected syntax mapping.

---

## Related Artifacts

- **Claude orchestrator source:** `claude-pack/commands/_my_orchestrate.md`
- **Claude helper:** `claude-pack/scripts/orchestrate-stage.sh`
- **Shared non-interactive preamble:** `claude-pack/scripts/orchestrate-preamble.md`
- **Codex generated orchestrator skill:** `dist/codex/skills/my-orchestrate/SKILL.md`
- **Installed Codex orchestrator skill:** `$HOME/.agents/skills/my-orchestrate/SKILL.md`
- **Codex generator:** `scripts/build-codex-pack.sh`
- **Codex installer:** `scripts/setup-codex.sh`
- **Codex override config:** `codex-overrides/config.sh`
- **Generated Codex global instructions:** `dist/codex/AGENTS.md`
- **Always-on pipeline rule source:** `claude-pack/rules/pipeline.md`
- **Workflow accountability rule source:** `claude-pack/rules/workflow-accountability.md`
- **Existing Claude orchestrator spec/design:** `.project/active/workflow-orchestrator/{spec,design,plan,spike-findings}.md`
- **Prior Codex compatibility spec/design:** `.project/active/codex-generated-compatibility/{spec,design}.md`
- **Design:** `.project/active/codex-orchestrator-fork/design.md` (to be created)

---

**Next Steps:** Review this spec, then proceed to `$my-design` for the Codex fork. The design should start by choosing the fork layout and helper contract before touching generated assets.
