---
name: my-orchestrate
description: Given a concept or outcomes document, drive it to implemented, reviewed work through Codex-native pipeline stages.
---

Generated from `codex-overrides/command-skill-replacements/orchestrate/SKILL.md`. This is a full Codex replacement for the Claude orchestrator command. Rebuild it instead of editing generated output by hand.

# Orchestrate

**Purpose:** Given a concept or outcomes document, drive it to implemented, reviewed work autonomously. You run the pipeline by delegating each stage to a headless Codex helper, then leave artifacts and a decision trail the human can audit afterward.

**Input:** A concept/outcomes doc path or inline outcomes.

**Output:** Pipeline artifacts and code in `.project/`, plus commits when the work and repository state call for them.

## What Matters Most

You are trusted for judgment, not just coordination.

- **Hold the engineering bar.** Do not accept stage output that is vague, untested, placeholder-heavy, or inconsistent with the repository's patterns. Resume the stage with concrete feedback when the work falls short.
- **Stay on intent.** Keep the objective and its broader context visible. Each stage should serve the real outcome, not only produce the next artifact.
- **Keep context lean.** Read stage final messages first. Read artifacts or code only when you need detail to route, review, or decide.

## Tools

Delegate each stage through the Codex helper:

```bash
~/.codex/scripts/orchestrate-stage-codex.sh run <stage> <<'ARGS'
...
ARGS
```

Resume a stage with answers, review feedback, or continuation context:

```bash
~/.codex/scripts/orchestrate-stage-codex.sh resume <session_id> <<'MSG'
...
MSG
```

Each call returns compact JSON:

- `session_id`: the Codex thread id to resume.
- `result`: the stage's final message.
- `raw`: the JSONL log path.
- `stderr`: the stderr log path.
- `is_error`: whether Codex reported a failed turn.

The helper maps pipeline stages to Codex skills. For example, `spec` invokes `$my-spec`, `spec_review` invokes `$my-spec-review`, and `pre_pr` invokes `$my-pre-pr`.

## Running the Pipeline

1. **Orient.** Read the objective. Decide where to enter the pipeline and whether this is a single item or an epic.
2. **Read `$my-pipeline`.** Use it as the canonical map for stages, branches, and paired reviews.
3. **Start each stage with enough context.** Include the objective, relevant prior artifacts, explicit decisions already made, and the stage outcome you need.
4. **Handle questions by resuming.** If a stage asks questions, answer from the objective and your judgment. If the objective cannot settle a question, tell the stage to choose and record the decision.
5. **Run review loops deliberately.** Where the pipeline pairs a stage with a review, feed must-fix findings back to the producing stage. Do not chase a review loop past about two rounds without a clear reason.
6. **Commit decisions when appropriate.** Keep commits focused, with subjects that name the decision or completed stage.
7. **Finish at the right boundary.** Leave `$my-close` to the human unless explicitly asked to archive the work.

## Stage Result Protocol

A stage result has one of two shapes:

- It asks questions. Answer them in one resume message.
- It finishes and ends with `ARTIFACT: <relative path>`. Read that artifact when you need to route or review the next stage.

If a stage result is incomplete, ambiguous, or misses the requested outcome, resume the same session with specific feedback. Do not route a weak artifact forward just because it exists.

## Sandbox Defaults

The helper chooses the least needed sandbox for fresh stage runs:

- `read-only` for reference and review-only stages.
- `workspace-write` for artifact-producing or implementation stages.
- `danger-full-access` is never a default. Use it only when the user explicitly approves that risk.

Resume calls do not pass `--sandbox` because the current Codex CLI resume path does not accept the same flags as a fresh run.

## Related

Pipeline reference: `$my-pipeline`.

Common inputs: `$my-concept`, `$my-concept-design`, `$my-research`.

Common stages: `$my-epic-plan`, `$my-spec`, `$my-spec-review`, `$my-product-design`, `$my-design`, `$my-design-review`, `$my-plan`, `$my-implement`, `$my-audit`, `$my-pre-pr`.

Mechanism: `~/.codex/scripts/orchestrate-stage-codex.sh`.
