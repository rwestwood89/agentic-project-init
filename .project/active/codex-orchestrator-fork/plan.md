# Implementation Plan: Codex Orchestrator Fork

**Status:** Draft
**Created:** 2026-07-07T21:24:23-07:00
**Last Updated:** 2026-07-07T21:24:23-07:00

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
- [ ] Create the test script with repo-root discovery matching existing script style.
- [ ] Add checks for helper dry-run stage mapping: `spec` -> `$my-spec`, `spec_review` -> `$my-spec-review`, `pre_pr` -> `$my-pre-pr`.
- [ ] Add checks that resume dry-run omits `--sandbox`.

#### 2. Codex Helper Skeleton
**File:** `codex-overrides/scripts/orchestrate-stage-codex.sh` (NEW)
- [ ] Implement `run`, `resume`, option parsing, and `--dry-run` only.
- [ ] Print a stable dry-run format with argv section and prompt section.
- [ ] Keep real execution paths as explicit not-yet-implemented errors for this phase.

#### 3. Codex Preamble
**File:** `codex-overrides/scripts/orchestrate-preamble-codex.md` (NEW)
- [ ] Add the noninteractive stage guidance referenced by dry-run prompt composition.

### Validation

**Automated:**
- [ ] `bash scripts/test_codex_orchestrator_pack.sh` -> fails only on assets not yet generated, then passes after local phase wiring if run directly against override helper.
- [ ] `codex-overrides/scripts/orchestrate-stage-codex.sh run spec --dry-run <<< 'x'` -> prints `$my-spec` and `codex exec` argv.
- [ ] `codex-overrides/scripts/orchestrate-stage-codex.sh resume 019-test --dry-run <<< 'x'` -> prints `codex exec resume` and no `--sandbox`.

**Manual:**
- [ ] Inspect dry-run output and confirm no model call happens.

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
- [ ] Create `dist/codex/scripts` alongside agents/skills/hooks.
- [ ] Copy files from `codex-overrides/scripts/` preserving executable bits where applicable.
- [ ] Track included scripts in `manifest.json` near the existing included asset arrays at `scripts/build-codex-pack.sh:365`.

#### 2. Installer Script Lane
**File:** `scripts/setup-codex.sh:187`
- [ ] Ensure `~/.codex/scripts` exists.
- [ ] Install `dist/codex/scripts/*` using `install_path` so user-authored files are skipped unless `--force` is used.
- [ ] Include scripts in install output and summary.

#### 3. Test Harness Update
**File:** `scripts/test_codex_orchestrator_pack.sh` (NEW/UPDATE)
- [ ] Add generated script and installer dry-run checks.

### Validation

**Automated:**
- [ ] `bash scripts/build-codex-pack.sh` -> `dist/codex/scripts` exists.
- [ ] `bash scripts/test_codex_orchestrator_pack.sh` -> script lane checks pass.
- [ ] `bash scripts/setup-codex.sh --dry-run` -> reports script installation without writing.

**Manual:**
- [ ] Confirm existing generated skills still appear in `dist/codex/skills`.

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
- [ ] Write the full Codex-native `my-orchestrate` instructions.
- [ ] Reference `$my-pipeline`, `$my-*` stages, and `~/.codex/scripts/orchestrate-stage-codex.sh`.
- [ ] Preserve orchestration judgment rules from `claude-pack/commands/_my_orchestrate.md` without Claude mechanics.

#### 2. Generator Replacement Logic
**File:** `scripts/build-codex-pack.sh:226`
- [ ] Before emitting a command-derived skill, check for a full replacement file.
- [ ] If replacement exists, copy it to the generated skill path instead of appending sanitized Claude body.
- [ ] Record replacements in `manifest.json`.

#### 3. Codex Rule Transform
**File:** `scripts/build-codex-pack.sh:323`
- [ ] Add a Codex rule sanitization/transform function for generated `AGENTS.md`.
- [ ] Convert `/_my_foo_bar` to `$my-foo-bar` in active guidance.
- [ ] Rewrite or remove known false Codex claims: auto-memory and `.claude/rules` symlink note.
- [ ] Rewrite `~/.claude/commands/_my_pipeline.md` to `$HOME/.agents/skills/my-pipeline/SKILL.md` or equivalent Codex wording.

#### 4. Test Harness Update
**File:** `scripts/test_codex_orchestrator_pack.sh`
- [ ] Add checks for replacement skill and transformed `AGENTS.md`.

### Validation

**Automated:**
- [ ] `bash scripts/build-codex-pack.sh`
- [ ] `bash scripts/test_codex_orchestrator_pack.sh`
- [ ] `rg -n 'claude -p|~/.claude/scripts/orchestrate-stage.sh|/_my_' dist/codex/skills/my-orchestrate/SKILL.md` -> no matches.

**Manual:**
- [ ] Read `dist/codex/skills/my-orchestrate/SKILL.md` once for coherence.
- [ ] Read generated `dist/codex/AGENTS.md` pipeline section for Codex-native wording.

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
- [ ] Implement `run` using `codex exec --json --output-last-message ... --sandbox <mode> --cd <dir>`.
- [ ] Implement `resume` using `codex exec resume --json --output-last-message ... <session_id> <prompt>` with no `--sandbox`.
- [ ] Add timeout handling and raw log paths.
- [ ] Parse JSONL for `thread.started.thread_id`, `turn.failed`, and `error`.
- [ ] Return compact JSON with `session_id`, `result`, `raw`, `stderr`, and `is_error`.

#### 2. Parser Fixture Support
**File:** `codex-overrides/scripts/orchestrate-stage-codex.sh`
- [ ] Add a test-only parse path or factor parser logic so fixture tests can run without a model call.

#### 3. Test Harness Update
**File:** `scripts/test_codex_orchestrator_pack.sh`
- [ ] Add fixture parser tests.
- [ ] Add failure fixture test for `turn.failed` or `error` event.

### Validation

**Automated:**
- [ ] `bash scripts/test_codex_orchestrator_pack.sh` -> dry-run and parser fixture tests pass.
- [ ] `bash scripts/build-codex-pack.sh && bash scripts/test_codex_orchestrator_pack.sh` -> generated helper still passes tests.

**Manual:**
- [ ] Run generated helper dry-run for `run spec`, `run spec_review`, and `resume 019-test`.

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
- [ ] Rebuild generated Codex assets.
- [ ] Verify `dist/codex/scripts`, replacement `my-orchestrate`, transformed `AGENTS.md`, and manifest updates.

#### 2. Installer Verification
**File:** `scripts/setup-codex.sh`
- [ ] Fix any dry-run/install reporting gaps found in Phase 5 validation.

#### 3. Optional Live Smoke Notes
**File:** `.project/active/codex-orchestrator-fork/implementation-notes.md` or plan notes
- [ ] If live smoke is run, record temp repo path, commands, logs, result, and cleanup status.

### Validation

**Automated:**
- [ ] `bash scripts/build-codex-pack.sh`
- [ ] `bash scripts/test_codex_orchestrator_pack.sh`
- [ ] `bash scripts/setup-codex.sh --dry-run`
- [ ] Existing project tests that are relevant and available: `bash scripts/test_pipeline_sync.sh`, `bash scripts/test_docs.sh`, and setup tests if they do not require unavailable fixtures.

**Manual:**
- [ ] Inspect `dist/codex/manifest.json` for scripts and replacements.
- [ ] Optional, with explicit approval if needed: run generated helper against a temp repo using `$my-pipeline` or `$my-spec`, then run one resume.

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
**Completed:** TBD
**Actual Changes:** TBD
**Issues:** TBD
**Deviations:** TBD

### Phase 2 Completion
**Completed:** TBD
**Actual Changes:** TBD
**Issues:** TBD
**Deviations:** TBD

### Phase 3 Completion
**Completed:** TBD
**Actual Changes:** TBD
**Issues:** TBD
**Deviations:** TBD

### Phase 4 Completion
**Completed:** TBD
**Actual Changes:** TBD
**Issues:** TBD
**Deviations:** TBD

### Phase 5 Completion
**Completed:** TBD
**Actual Changes:** TBD
**Issues:** TBD
**Deviations:** TBD

---

**Status**: Draft
