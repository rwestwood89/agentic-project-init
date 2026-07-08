# Implementation Plan: Codex Orchestrator Fork

**Status:** Complete
**Created:** 2026-07-07T21:24:23-07:00
**Last Updated:** 2026-07-08T06:25:00-07:00

## Source Documents

- **Spec:** `.project/active/codex-orchestrator-fork/spec.md`
- **Design:** `.project/active/codex-orchestrator-fork/design.md`
- **Spike:** `.project/active/codex-orchestrator-fork/spike-findings.md`

## Implementation Strategy

**Phasing Rationale:**
Start with tests and dry-run behavior because the spike showed argv shape is the easiest place to make an expensive mistake. Then add generated asset lanes, then replace unsafe Codex-facing content, then add live execution parsing, and only then run install and live smoke validation.

**Critical Path:**
Dry-run contract -> generator/installer script lane -> `my-orchestrate` replacement and rule transforms -> real `codex exec` run/resume parser -> rebuild/install/smoke verification.

**First Proof Point:**
A testable dry-run invocation proves stage-name mapping and separate `run` vs `resume` argv construction without making a model call.

**Overall Validation Approach:**
- Each phase starts with a test or dry-run check.
- Generated products are tested after `scripts/build-codex-pack.sh`.
- Live `codex exec` validation stays in disposable repos/worktrees because local read-only sandboxing did not reliably block shell writes.

---

## Phase 1: Dry-Run Helper Contract and Validation Harness

### Goal

Create the Codex generated-product test harness and a minimal `orchestrate-stage-codex.sh --dry-run` path. This proves the most fragile helper contract before any live model calls.

### Assumption Under Test

The Codex helper can be validated offline if dry-run prints stable prompt and argv output for both fresh run and resume paths. See `design.md#implementation-notes` and `spike-findings.md#design-updates-needed`.

### Test Stencil (Write This First)

```bash
# scripts/test_codex_orchestrator_pack.sh
run_dry="$ROOT/dist/codex/scripts/orchestrate-stage-codex.sh run spec --dry-run"
out="$($run_dry <<< 'Build the thing')"
echo "$out" | grep -q 'codex exec'
echo "$out" | grep -q 'Use $my-spec'
echo "$out" | grep -q -- '--sandbox workspace-write'

resume="$ROOT/dist/codex/scripts/orchestrate-stage-codex.sh resume 019-test --dry-run"
out="$($resume <<< 'Continue')"
echo "$out" | grep -q 'codex exec resume'
! echo "$out" | grep -q -- '--sandbox'
```

### Changes Required

**See `design.md` for:**
- Helper contract -> `design.md#implementation-notes`
- Required invariants -> `design.md#required-invariants`
- Validation shape -> `design.md#validation-approach`

**Specific file changes:**

#### 1. Generated-Product Test
**File:** `scripts/test_codex_orchestrator_pack.sh` (NEW)
- [x] Create the test script with repo-root discovery matching existing script style.
- [x] Add checks for helper dry-run stage mapping: `spec` -> `$my-spec`, `spec_review` -> `$my-spec-review`, `pre_pr` -> `$my-pre-pr`.
- [x] Add checks that resume dry-run omits `--sandbox`.

#### 2. Codex Helper Skeleton
**File:** `codex-overrides/scripts/orchestrate-stage-codex.sh` (NEW)
- [x] Implement `run`, `resume`, option parsing, and `--dry-run` only.
- [x] Print a stable dry-run format with argv section and prompt section.
- [x] Keep real execution paths as explicit not-yet-implemented errors for this phase. Superseded by Phase 4 in the same implementation pass; real execution is now implemented.

#### 3. Codex Preamble
**File:** `codex-overrides/scripts/orchestrate-preamble-codex.md` (NEW)
- [x] Add the noninteractive stage guidance referenced by dry-run prompt composition.

### Validation

**Automated:**
- [x] `bash scripts/test_codex_orchestrator_pack.sh` -> fails only on assets not yet generated, then passes after local phase wiring if run directly against override helper.
- [x] `codex-overrides/scripts/orchestrate-stage-codex.sh run spec --dry-run <<< 'x'` -> prints `$my-spec` and `codex exec` argv.
- [x] `codex-overrides/scripts/orchestrate-stage-codex.sh resume 019-test --dry-run <<< 'x'` -> prints `codex exec resume` and no `--sandbox`.

**Manual:**
- [x] Inspect dry-run output and confirm no model call happens.

**What We Know Works After This Phase:**
The helper contract can be tested offline, and the spike's invalid resume argv failure is guarded before implementation reaches live Codex calls.

---

## Phase 2: Generate and Install Codex Scripts

### Goal

Wire Codex-only scripts into the generated pack and installer so the future `my-orchestrate` replacement has a stable runtime path.

### Assumption Under Test

The existing generated compatibility layer can grow a scripts lane without disrupting current agents, skills, hooks, or `AGENTS.md`. See `design.md#architecture`.

### Test Stencil (Write This First)

```bash
bash scripts/build-codex-pack.sh
[ -x dist/codex/scripts/orchestrate-stage-codex.sh ]
[ -f dist/codex/scripts/orchestrate-preamble-codex.md ]
grep -q '"scripts"' dist/codex/manifest.json
bash scripts/setup-codex.sh --dry-run | grep -q '~/.codex/scripts'
```

### Changes Required

**See `design.md` for:**
- Script lane -> `design.md#component-overview`
- Installer invariant -> `design.md#required-invariants`

**Specific file changes:**

#### 1. Generator Script Lane
**File:** `scripts/build-codex-pack.sh:219`
- [x] Create `dist/codex/scripts` alongside agents/skills/hooks.
- [x] Copy files from `codex-overrides/scripts/` preserving executable bits where applicable.
- [x] Track included scripts in `manifest.json` near the existing included asset arrays at `scripts/build-codex-pack.sh:365`.

#### 2. Installer Script Lane
**File:** `scripts/setup-codex.sh:187`
- [x] Ensure `~/.codex/scripts` exists.
- [x] Install `dist/codex/scripts/*` using `install_path` so user-authored files are skipped unless `--force` is used.
- [x] Include scripts in install output and summary.

#### 3. Test Harness Update
**File:** `scripts/test_codex_orchestrator_pack.sh` (NEW/UPDATE)
- [x] Add generated script and installer dry-run checks.

### Validation

**Automated:**
- [x] `bash scripts/build-codex-pack.sh` -> `dist/codex/scripts` exists.
- [x] `bash scripts/test_codex_orchestrator_pack.sh` -> script lane checks pass.
- [x] `bash scripts/setup-codex.sh --dry-run` -> reports script installation without writing.

**Manual:**
- [x] Confirm existing generated skills still appear in `dist/codex/skills`.

**What We Know Works After This Phase:**
The Codex helper can be generated and installed through the same managed pack workflow as the rest of Codex compatibility.

---

## Phase 3: Replace `my-orchestrate` and Transform Codex Rules

### Goal

Remove active Claude-only instructions from Codex-facing orchestration and global workflow guidance.

### Assumption Under Test

A full replacement for `my-orchestrate` plus narrow rule transforms is enough to make Codex-facing guidance executable without forking every command-derived skill. See `design.md#key-decisions`.

### Test Stencil (Write This First)

```bash
bash scripts/build-codex-pack.sh
orch=dist/codex/skills/my-orchestrate/SKILL.md
! grep -q '~/.claude/scripts/orchestrate-stage.sh' "$orch"
! grep -q 'claude -p' "$orch"
! grep -q '/_my_' "$orch"
grep -q '~/.codex/scripts/orchestrate-stage-codex.sh' "$orch"
grep -q '\$my-pipeline' dist/codex/AGENTS.md
! grep -q '~/.claude/commands/_my_pipeline.md' dist/codex/AGENTS.md
```

### Changes Required

**See `design.md` for:**
- Replacement lane -> `design.md#architecture`
- Rule transform scope -> `design.md#implementation-notes`

**Specific file changes:**

#### 1. Replacement Skill Source
**File:** `codex-overrides/command-skill-replacements/orchestrate/SKILL.md` (NEW)
- [x] Write the full Codex-native `my-orchestrate` instructions.
- [x] Reference `$my-pipeline`, `$my-*` stages, and `~/.codex/scripts/orchestrate-stage-codex.sh`.
- [x] Preserve orchestration judgment rules from `claude-pack/commands/_my_orchestrate.md` without Claude mechanics.

#### 2. Generator Replacement Logic
**File:** `scripts/build-codex-pack.sh:226`
- [x] Before emitting a command-derived skill, check for a full replacement file.
- [x] If replacement exists, copy it to the generated skill path instead of appending sanitized Claude body.
- [x] Record replacements in `manifest.json`.

#### 3. Codex Rule Transform
**File:** `scripts/build-codex-pack.sh:323`
- [x] Add a Codex rule sanitization/transform function for generated `AGENTS.md`.
- [x] Convert `/_my_foo_bar` to `$my-foo-bar` in active guidance.
- [x] Rewrite or remove known false Codex claims: auto-memory and `.claude/rules` symlink note.
- [x] Rewrite `~/.claude/commands/_my_pipeline.md` to `$HOME/.agents/skills/my-pipeline/SKILL.md` or equivalent Codex wording.

#### 4. Test Harness Update
**File:** `scripts/test_codex_orchestrator_pack.sh`
- [x] Add checks for replacement skill and transformed `AGENTS.md`.

### Validation

**Automated:**
- [x] `bash scripts/build-codex-pack.sh`
- [x] `bash scripts/test_codex_orchestrator_pack.sh`
- [x] `rg -n 'claude -p|~/.claude/scripts/orchestrate-stage.sh|/_my_' dist/codex/skills/my-orchestrate/SKILL.md` -> no matches.

**Manual:**
- [x] Read `dist/codex/skills/my-orchestrate/SKILL.md` once for coherence.
- [x] Read generated `dist/codex/AGENTS.md` pipeline section for Codex-native wording.

**What We Know Works After This Phase:**
Codex-facing orchestration and always-on workflow guidance no longer point Codex at Claude commands or helper paths.

---

## Phase 4: Real Helper Execution and JSONL Parsing

### Goal

Implement real `run` and `resume` execution in the Codex helper after dry-run and generated assets are protected by tests.

### Assumption Under Test

The verified spike behavior can be encoded into a shell helper that returns compact JSON for the orchestrator. See `spike-findings.md#summary` and `design.md#implementation-notes`.

### Test Stencil (Write This First)

```bash
# Unit-style fixture test inside scripts/test_codex_orchestrator_pack.sh
fixture="$TMPDIR/codex-events.jsonl"
printf '%s\n' \
  '{"type":"thread.started","thread_id":"019-test"}' \
  '{"type":"turn.completed","usage":{"input_tokens":1}}' > "$fixture"
last="$TMPDIR/last-message.txt"
printf 'ARTIFACT: .project/active/demo/spec.md\n' > "$last"
parsed="$($HELPER --parse-only "$fixture" "$last")"
echo "$parsed" | grep -q '"session_id":"019-test"'
echo "$parsed" | grep -q 'ARTIFACT:'
```

### Changes Required

**See `design.md` for:**
- JSONL parsing -> `design.md#implementation-notes`
- Runtime flow -> `design.md#architecture`
- Spike corrections -> `spike-findings.md#design-updates-needed`

**Specific file changes:**

#### 1. Codex Helper Real Execution
**File:** `codex-overrides/scripts/orchestrate-stage-codex.sh`
- [x] Implement `run` using `codex exec --json --output-last-message ... --sandbox <mode> --cd <dir>`.
- [x] Implement `resume` using `codex exec resume --json --output-last-message ... <session_id> <prompt>` with no `--sandbox`.
- [x] Add timeout handling and raw log paths.
- [x] Parse JSONL for `thread.started.thread_id`, `turn.failed`, and `error`.
- [x] Return compact JSON with `session_id`, `result`, `raw`, `stderr`, and `is_error`.

#### 2. Parser Fixture Support
**File:** `codex-overrides/scripts/orchestrate-stage-codex.sh`
- [x] Add a test-only parse path or factor parser logic so fixture tests can run without a model call.

#### 3. Test Harness Update
**File:** `scripts/test_codex_orchestrator_pack.sh`
- [x] Add fixture parser tests.
- [x] Add failure fixture test for `turn.failed` or `error` event.

### Validation

**Automated:**
- [x] `bash scripts/test_codex_orchestrator_pack.sh` -> dry-run and parser fixture tests pass.
- [x] `bash scripts/build-codex-pack.sh && bash scripts/test_codex_orchestrator_pack.sh` -> generated helper still passes tests.

**Manual:**
- [x] Run generated helper dry-run for `run spec`, `run spec_review`, and `resume 019-test`.

**What We Know Works After This Phase:**
The helper can construct valid Codex commands, parse recorded Codex outputs, and produce the JSON shape the orchestrator skill expects.

---

## Phase 5: End-to-End Pack Validation and Optional Live Smoke

### Goal

Validate the whole generated/installable Codex fork and, if approved for live model calls, repeat a small temp-repo smoke test through the generated helper.

### Assumption Under Test

The generated pack is installable and the helper works from its installed/generated location, not only from source paths. See `design.md#validation-approach`.

### Test Stencil (Write This First)

```bash
bash scripts/build-codex-pack.sh
bash scripts/test_codex_orchestrator_pack.sh
bash scripts/setup-codex.sh --dry-run | tee /tmp/setup-codex-dry-run.txt
grep -q 'orchestrate-stage-codex.sh' /tmp/setup-codex-dry-run.txt
```

### Changes Required

**See `design.md` for:**
- Integration strategy -> `design.md#integration-strategy`
- Validation approach -> `design.md#validation-approach`

**Specific file changes:**

#### 1. Final Generated Output
**File:** `dist/codex/**` (GENERATED)
- [x] Rebuild generated Codex assets.
- [x] Verify `dist/codex/scripts`, replacement `my-orchestrate`, transformed `AGENTS.md`, and manifest updates.

#### 2. Installer Verification
**File:** `scripts/setup-codex.sh`
- [x] No dry-run/install reporting gaps found in Phase 5 validation.

#### 3. Optional Live Smoke Notes
**File:** `.project/active/codex-orchestrator-fork/implementation-notes.md` or plan notes
- [x] Live smoke not run; no smoke notes file needed.

### Validation

**Automated:**
- [x] `bash scripts/build-codex-pack.sh`
- [x] `bash scripts/test_codex_orchestrator_pack.sh`
- [x] `bash scripts/setup-codex.sh --dry-run`
- [x] Existing project tests that are relevant and available: `bash scripts/test_pipeline_sync.sh`, `bash scripts/test_docs.sh`, `bash scripts/test_global_setup.sh`, and `bash scripts/test_init_project.sh`. `bash scripts/test_uninstall.sh` was not run because escalation was rejected as too risky for home/config paths.

**Manual:**
- [x] Inspect `dist/codex/manifest.json` for scripts and replacements.
- [x] Optional live smoke was not run; dry-run, fixture parsing, and installer dry-run validation covered this phase.

**What We Know Works After This Phase:**
The Codex orchestrator fork is generated, test-covered, installable, and has at least dry-run validation of the full helper/orchestrator path. Optional live smoke proves the installed helper contract against real Codex execution.

---

## Environment Setup

No `CLAUDE.md` is present in this checkout. Use the repository scripts directly:

- `bash scripts/build-codex-pack.sh`
- `bash scripts/setup-codex.sh --dry-run`
- `bash scripts/test_pipeline_sync.sh`
- `bash scripts/test_docs.sh`

Live `codex exec` probes must run in a disposable temp repo or git worktree. The spike showed `--sandbox read-only` did not reliably prevent shell writes in this local environment.

## Risk Management

**See `design.md#potential-risks` for detailed risk analysis.**

**Phase-Specific Mitigations:**

- **Phase 1:** Dry-run tests catch invalid argv construction before live model calls.
- **Phase 2:** Installer uses existing managed-file semantics to avoid clobbering user-authored files.
- **Phase 3:** Generated-product tests catch stale Claude references in `my-orchestrate` and `AGENTS.md`.
- **Phase 4:** Fixture parser tests keep JSONL parsing stable without requiring network/model access.
- **Phase 5:** Live validation, if run, stays in disposable repos/worktrees.

## Implementation Notes

### Phase 1 Completion
**Completed:** 2026-07-07 21:38 PDT
**Changes Made:**
- Created `scripts/test_codex_orchestrator_pack.sh` with generated helper dry-run checks for `spec`, `spec_review`, `pre_pr`, and `resume`.
- Created `codex-overrides/scripts/orchestrate-stage-codex.sh` with run/resume option parsing and stable dry-run output.
- Created `codex-overrides/scripts/orchestrate-preamble-codex.md` with noninteractive stage instructions.

**Issues Encountered:**
- Local sandboxed command execution and patch reads intermittently failed with `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`; affected commands were rerun with explicit escalation.

**Deviations from Plan:**
- The helper did not stop at not-yet-implemented real execution because Phases 1-4 were approved together. Phase 4 real execution was implemented in the same pass.

### Phase 2 Completion
**Completed:** 2026-07-07 21:38 PDT
**Changes Made:**
- Modified `scripts/build-codex-pack.sh` to create `dist/codex/scripts`, copy `codex-overrides/scripts/*`, preserve executable bits, and record scripts in `manifest.json`.
- Modified `scripts/setup-codex.sh` to install generated scripts into `~/.codex/scripts` through `install_path`.
- Extended `scripts/test_codex_orchestrator_pack.sh` to verify generated scripts and installer dry-run output.

**Issues Encountered:**
- None beyond the environment sandbox execution issue noted in Phase 1.

**Deviations from Plan:**
- None.

### Phase 3 Completion
**Completed:** 2026-07-07 21:38 PDT
**Changes Made:**
- Created `codex-overrides/command-skill-replacements/orchestrate/SKILL.md` as a full Codex-native replacement for `my-orchestrate`.
- Modified `scripts/build-codex-pack.sh` to use full command-skill replacements when present and record replacements in `manifest.json`.
- Added targeted Codex rule transforms for generated `AGENTS.md`, including `$my-*` command references, the pipeline skill path, auto-memory wording, and the `.claude/rules` symlink note.
- Regenerated `dist/codex/skills/my-orchestrate/SKILL.md` and `dist/codex/AGENTS.md`.

**Issues Encountered:**
- The first rule transform missed the wildcard form `/_my_*`; the generated-product test caught it and the transform now rewrites it to `$my-*`.
- A Perl replacement initially emitted an unescaped literal dollar sign; `scripts/build-codex-pack.sh` failed fast and the transform was corrected.

**Deviations from Plan:**
- None.

### Phase 4 Completion
**Completed:** 2026-07-07 21:38 PDT
**Changes Made:**
- Implemented real `codex exec` run and resume paths in `codex-overrides/scripts/orchestrate-stage-codex.sh`.
- Added explicit log paths for JSONL, stderr, and final-message output.
- Added `--parse-only` fixture parsing for JSONL and final-message files.
- Added parser tests for successful `thread.started.thread_id` extraction and `turn.failed` error reporting.
- Verified local CLI help for `codex exec` and `codex exec resume`; updated the helper to pass `-` explicitly for stdin and to use documented resume option ordering.

**Issues Encountered:**
- The local Codex CLI documents resume as `codex exec resume [OPTIONS] [SESSION_ID] [PROMPT]`; the helper was tightened to `codex exec resume --json --output-last-message <file> <session_id> -` before Phase 4 was marked complete.

**Deviations from Plan:**
- None.

### Phase 5 Completion
**Completed:** 2026-07-08 06:25 PDT
**Changes Made:**
- Rebuilt generated Codex assets in `dist/codex/`, including scripts, manifest metadata, replacement `my-orchestrate`, and transformed `AGENTS.md`.
- Tightened `scripts/build-codex-pack.sh` so Codex rule transforms rewrite the Markdown auto-memory line in `context-loading.md`.
- Added a regression assertion in `scripts/test_codex_orchestrator_pack.sh` so generated `AGENTS.md` cannot keep the stale auto-memory claim.

**Issues Encountered:**
- Sandboxed command startup repeatedly failed with `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`; validation commands were rerun with explicit escalation.
- Manual inspection found generated `AGENTS.md` still said auto-memory was already loaded. The first Codex pack test did not catch it, so the generator transform and generated-product test were updated.
- `bash scripts/test_uninstall.sh` was not run because the escalation reviewer rejected an unsandboxed uninstall test as too risky for home/config paths.

**Deviations from Plan:**
- Optional live smoke was not run. Phase 5 completed with generated helper dry-run checks, JSONL parser fixtures, installer dry-run validation, and project setup/docs checks.

---

**Status**: Complete
