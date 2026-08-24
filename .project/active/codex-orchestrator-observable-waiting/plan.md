# Implementation Plan: Codex Orchestrator Observable Waiting

**Status:** Complete
**Created:** 2026-08-13 12:38:38 PDT
**Last Updated:** 2026-08-13 12:38:38 PDT

## Source Documents

- **Spec:** `.project/active/codex-orchestrator-observable-waiting/spec.md`
- **Design:** `.project/active/codex-orchestrator-observable-waiting/design.md`
- **Spike:** `.project/active/codex-orchestrator-observable-waiting/spike-findings.md`

## The Point

- **[NEED]** Codex orchestration must stop burying the main terminal timeline under repeated
  no-news waits and must stop invoking the parent model merely to learn that a stage remains active.
  The owner described the current output as making “following the progress of the main agent in
  terminal impossible” and the polling as “kind of a waste of tokens.”
- **[INHERITED]** This remains one isolated headless agent per stage with an auditable commit trail.
  Orchestration still leaves `close` and post-close `pre_pr` to the human unless asked.

## Implementation Strategy

**Phasing Rationale:**
Prove child cleanup first because changing the parent's wait makes safe interruption more important.
Then encode the completion-driven host contract behind static generated-product tests. Rebuild and
install only after both authored behaviors are protected, and use the installed host session as the
final gate because shell tests cannot certify model wakeups or terminal rendering.

**Critical Path:**
Cancellation regression test → helper signal ownership → waiting-contract test → Codex skill recipe
→ generated pack → installed host acceptance.

**First Proof Point:**
The new external-cancellation test fails against the current helper, then passes with the fake Codex
child gone, the cancellation status nonzero, and compact stdout unaffected for normal runs.

**Overall Validation Approach:**

- Start every phase with a failing test or acceptance stencil.
- Test authored behavior through generated assets, never hand-edited `dist/codex` files.
- Preserve current run/resume, parser, log, sandbox, and installer assertions throughout.
- Treat installed host acceptance as required. A host-capability failure stops implementation; it
  does not permit periodic polling as a fallback.

---

## Phase 1: Own and Clean Up the Stage Process

### Goal

Make external cancellation safe while locking the existing helper lifecycle into permanent tests.
This comes first because the later long-lived host cell needs a reliable interruption path.

### Assumption Under Test

The existing asynchronous prompt-to-`timeout` pipeline exposes its final `timeout` PID through
`$!`, and forwarding a signal to that owned process terminates the fake Codex descendant within the
five-second cleanup grace without changing normal result behavior.

### Test Stencil (Write This First)

```bash
FAKE_CODEX_MODE=hang "$HELPER" run design --timeout 30 < prompt &
helper_pid=$!
wait_for_file "$fake_pid_file"
kill -TERM "$helper_pid"
set +e; wait "$helper_pid"; rc=$?; set -e
[ "$rc" -eq 143 ]
fake_pid="$(sed -n '1p' "$fake_pid_file")"
assert_process_gone "$fake_pid"
assert_contains "$signal_file" terminated
```

### Changes Required

See [`design.md#architecture`](design.md#architecture),
[`design.md#required-invariants`](design.md#required-invariants), and
[`design.md#implementation-notes`](design.md#implementation-notes).

#### 1. Generated-product test

**File:** `scripts/test_codex_orchestrator_pack.sh:34-101`

- [x] Add a temp PATH-injected fake `codex` and test helpers before changing the production helper.
- [x] Add success, resume, reported-failure, helper-timeout, and external-cancellation cases.
- [x] Assert exact exit/result/session shapes, retained evidence paths, recorded signal, and no live
  fake child after cleanup grace.
- [x] Run the new cancellation case against the current generated helper and record the expected red
  result before implementation.

#### 2. Authored helper

**File:** `codex-overrides/scripts/orchestrate-stage-codex.sh:178-197`

- [x] Add guarded runner-PID and signal cleanup behavior from
  [`design.md#key-decisions`](design.md#key-decisions).
- [x] Run the current pipeline asynchronously, capture and clear the final `timeout` PID safely, and
  preserve its exit classification.
- [x] Forward `HUP`/`INT`/`TERM`, wait five seconds, then escalate only against the timeout-owned
  process group; keep all lifecycle diagnostics on stderr.
- [x] Preserve prompt bytes, run/resume argv differences, compact JSON stdout, and retained logs.

#### 3. Generated helper

**File:** `dist/codex/scripts/orchestrate-stage-codex.sh` (GENERATED)

- [x] Rebuild from the authored helper with `bash scripts/build-codex-pack.sh`.

### Validation

**Automated:**

- [x] `bash -n codex-overrides/scripts/orchestrate-stage-codex.sh`
- [x] `bash scripts/build-codex-pack.sh`
- [x] `bash -n dist/codex/scripts/orchestrate-stage-codex.sh`
- [x] `bash scripts/test_codex_orchestrator_pack.sh`

**Manual:**

- [x] Inspect one cancellation fixture: stderr names the stage/evidence paths and stdout is empty.
- [x] Confirm the recorded helper, timeout, and fake-Codex PIDs are gone after the test.

**What We Know Works After This Phase:**
The blocking helper remains contract-compatible and owns the complete lifecycle of its stage child,
including external cancellation.

---

## Phase 2: Encode Completion-Driven Parent Waiting

### Goal

Protect and implement the one-cell/one-fallback supervision contract in the authored Codex
orchestration skill after child cancellation is safe.

### Assumption Under Test

An explicit tool recipe in the generated skill can make completion-driven waiting the only lawful
path while retaining the current stage-selection and result-routing instructions.

### Test Stencil (Write This First)

```bash
contains "$ORCH" 'functions.exec'
contains "$ORCH" 'tools.exec_command'
contains "$ORCH" 'tools.write_stdin'
contains "$ORCH" 'functions.wait'
contains "$ORCH" 'only once'
contains "$ORCH" 'Do not poll'
does_not_contain "$ORCH" 'notify('
does_not_contain "$ORCH" 'setInterval'
```

### Changes Required

See [`design.md#core-concept`](design.md#core-concept),
[`design.md#key-decisions`](design.md#key-decisions), and
[`design.md#potential-risks`](design.md#potential-risks).

#### 1. Waiting-contract tests

**File:** `scripts/test_codex_orchestrator_pack.sh:88-101`

- [x] Add assertions for the outer `T + 30s` execution cell, internal terminal-session draining,
  one remaining-deadline fallback, and fail-loud second-yield behavior.
- [x] Require an explicit no-polling rule and add negative assertions against polling timers,
  `notify`, `yield_control`, and live JSONL/stderr forwarding.
- [x] Run against the current generated skill and record the expected red result.

#### 2. Authored Codex orchestrator skill

**File:** `codex-overrides/command-skill-replacements/orchestrate/SKILL.md:36-62`

- [x] Replace the bare helper invocation guidance with the completion-driven host recipe from
  [`design.md#implementation-notes`](design.md#implementation-notes).
- [x] Require one concise stage launch update and no unchanged-state commentary.
- [x] Define one bounded outer-cell fallback and the compatibility-failure path without changing
  stage selection, questions/resume, result routing, or the human-owned finish boundary.

#### 3. Generated skill and manifest

**Files:**

- `dist/codex/skills/my-orchestrate/SKILL.md` (GENERATED)
- `dist/codex/manifest.json` (GENERATED)

- [x] Rebuild generated output from the authored skill.
- [x] Confirm the manifest still reports `my-orchestrate` as the replacement and the helper as an
  included script.

### Validation

**Automated:**

- [x] `bash scripts/build-codex-pack.sh`
- [x] `bash scripts/test_codex_orchestrator_pack.sh`
- [x] `bash scripts/test_pipeline_sync.sh`
- [x] `rg -n 'notify\(|yield_control|setInterval|setTimeout' dist/codex/skills/my-orchestrate/SKILL.md`
  returns no active waiting instruction.

**Manual:**

- [x] Read the generated `my-orchestrate` Tools and Stage Result sections together once. Confirm the
  new recipe is clear without weakening existing routing policy.
- [x] Confirm no Claude helper, command, or file changed.

**What We Know Works After This Phase:**
The authored and generated Codex skill carry one explicit completion-driven waiting contract, and
the generated-product test rejects the old polling policy.

---

## Phase 3: Rebuild, Install, and Certify the Host Behavior

### Goal

Prove the installed pack produces the readable terminal and parent-session behavior that shell and
static tests cannot observe.

### Assumption Under Test

The current Codex host follows the installed skill's one-cell recipe for a representative long
stage, and its forced-yield fallback needs at most one parent-visible wait.

### Test Stencil (Write This First)

```bash
marker=OBS_WAIT_ACCEPTANCE_NORMAL
run_installed_recipe_with_fake_stage "$marker" 36
counts="$(analyze_parent_session "$session_log" "$marker")"
jq -e '.parent_tool_calls_between == 0' <<<"$counts"
jq -e '.wait_calls_between == 0' <<<"$counts"
jq -e '.token_events_between == 0' <<<"$counts"
assert_terminal_has_no_repeated_prompt_body
```

Use
`.project/active/codex-orchestrator-observable-waiting/probes/analyze-parent-session.sh`
for this one-time acceptance evidence. Do not make a production or generated-pack test depend on
that active-work path because `$my-close` will move it.

### Changes Required

See [`design.md#integration-strategy`](design.md#integration-strategy),
[`design.md#validation-approach`](design.md#validation-approach), and
[`design.md#next-stage-handoff`](design.md#next-stage-handoff).

#### 1. Final generated pack

**Files:** `dist/codex/**` (GENERATED)

- [x] Run the final rebuild and verify only expected generated skill/helper/manifest differences.

#### 2. Installed pack

**Files:** `$HOME/.agents/skills/my-orchestrate/SKILL.md` and
`$HOME/.codex/scripts/orchestrate-stage-codex.sh` (INSTALLED, not repository sources)

- [x] Run `bash scripts/setup-codex.sh --dry-run` and inspect the managed targets.
- [x] Refresh the installed Codex pack with the repository setup script.
- [x] Verify installed skill/helper content matches generated output for both copy and symlink lanes.

#### 3. Implementation evidence

**File:** `.project/active/codex-orchestrator-observable-waiting/plan.md`

- [x] Record the saved parent-session path, markers, exact counts, terminal observation, child
  cleanup result, and live-stage result in the phase completion notes.
- [x] If a second premature yield occurs, stop, clean up, and record the premise conflict. Do not
  weaken the acceptance criteria or add polling.

### Validation

**Automated:**

- [x] `bash scripts/build-codex-pack.sh`
- [x] `bash scripts/test_codex_orchestrator_pack.sh`
- [x] `bash scripts/test_pipeline_sync.sh`
- [x] `bash scripts/test_docs.sh`
- [x] `bash scripts/setup-codex.sh --dry-run`
- [x] `git diff --check`

**Host-Level Acceptance:**

- [x] Normal fake stage crosses at least three former polling intervals with zero intermediate
  records, parent tool calls, waits, and token events.
- [x] Terminal shows one concise launch, one running tool entry, and one terminal result without a
  repeated heredoc or prompt body.
- [x] Forced outer yield produces exactly one remaining-deadline wait, then the same final stage and
  session identity with no no-news commentary.
- [x] Direct helper cancellation returns promptly and leaves no fake helper, timeout, or Codex
  child after five seconds. Delivery of a host-cell interrupt to the helper remains unverified.
- [x] Question/result plus resume preserves the original Codex thread id and diagnostic paths; the
  live resume used the one bounded fallback wait after the outer cell yielded early.
- [x] One low-risk live document stage in a disposable worktree uses the installed skill and has the
  same terminal shape.

**What We Know Works After This Phase:**
The generated and installed Codex product removes wait-only parent turns in the observed host,
keeps the terminal readable, cleans up cancellation, and preserves the existing orchestration
contract end to end.

---

## Environment Setup

No root `CLAUDE.md` exists in this checkout. Run from `/home/reid/agentic-project-init` using the
repository scripts named above. The existing helper already depends on Bash, Python 3, and GNU
`timeout`; host evidence analysis also uses `jq` and the saved Codex session JSONL.

Do not edit `dist/codex` or installed files directly. Use `scripts/build-codex-pack.sh` and
`scripts/setup-codex.sh` so authored, generated, and installed assets remain traceable.

## Risk Management

See [`design.md#potential-risks`](design.md#potential-risks).

- **Phase 1:** Put child-lifecycle assertions in place before changing process ownership. Guard PID
  races and prove no descendant survives.
- **Phase 2:** Protect the exact waiting contract before changing the prompt. Keep host-specific
  instructions contained in the Codex replacement skill.
- **Phase 3:** Treat the installed session as the release gate. A host-yield regression is a premise
  conflict, not a reason to relax the no-polling requirement.

## Implementation Notes

### Phase 1 Completion

**Completed:** 2026-08-13 13:03 PDT
**Actual Changes:**
- Added a PATH-injected fake Codex lifecycle matrix to
  `scripts/test_codex_orchestrator_pack.sh` for run success, resume, reported failure, helper
  timeout, and external cancellation.
- Changed `codex-overrides/scripts/orchestrate-stage-codex.sh` to retain the asynchronous
  `timeout` PID, forward `HUP`/`INT`/`TERM`, enforce a five-second cleanup grace, and reserve
  escalation for the owned process group.
- Rebuilt `dist/codex/scripts/orchestrate-stage-codex.sh` from the authored helper.

**Issues:**
- Expected red result before implementation: the old generated helper exited 143 but left fake
  Codex PID 174 alive after the five-second cleanup grace.
- Green fixture `/tmp/codex-orchestrator-cancel.dhCVwz`: helper exited 143, compact stdout was
  empty, stderr named the `run-design` raw/stderr/final evidence, and helper PID 4, timeout PID 17,
  and fake Codex PID 18 were all gone after one second.

**Deviations:**
- None.

### Phase 2 Completion

**Completed:** 2026-08-13 13:05 PDT
**Actual Changes:**
- Added generated-skill guards for one `functions.exec` cell, internal `tools.exec_command` and
  `tools.write_stdin` draining, one `functions.wait` fallback, fail-loud second yield, concise
  launch wording, and the ban on timers, notifications, control yields, and parent polling.
- Replaced the authored skill's bare helper examples with the `T + 30` outer-cell recipe while
  preserving the existing stage selection, question/resume, result protocol, sandbox policy, and
  human-owned finish boundary.
- Rebuilt the generated skill and manifest. The manifest still lists `my-orchestrate` under
  `command_skill_replacements` and `orchestrate-stage-codex.sh` under `scripts`.

**Issues:**
- Expected red result before implementation: the old generated skill failed the first new guard
  because it did not contain a `functions.exec` supervision contract.
- The first green attempt exposed one over-specific wrapped-line assertion for retained JSONL and
  stderr. The guard was split across the two phrases without weakening the behavior it checks.

**Deviations:**
- None. No file under `claude-pack/` changed.

### Phase 3 Completion

**Completed:** 2026-08-13 13:16 PDT
**Actual Changes:**
- Rebuilt the final Codex distribution and installed it with `scripts/setup-codex.sh`. The installed
  `my-orchestrate` skill is a managed copy and the helper is a managed symlink; both compare equal
  to `dist/codex`.
- Saved host evidence in
  `/home/reid/.codex/sessions/2026/08/13/rollout-2026-08-13T12-42-17-019ffca5-9383-71a0-8a00-d8b553bc2460.jsonl`.
  Marker `OBS_WAIT_ACCEPTANCE_NORMAL_20260813` ran 36.1 seconds with 0 records, 0 parent tool
  calls, 0 waits, and 0 token events between launch and terminal result. The terminal showed one
  launch update, one running tool entry, and one compact result without repeated prompt text.
- Marker `OBS_WAIT_ACCEPTANCE_FORCED_YIELD_20260813` preserved session
  `019-acceptance-yield` and recorded 1 parent tool call, exactly 1 wait, and 1 token event across
  the forced yield. There was no unchanged-state commentary and no second yield.
- Cancellation fixture `/tmp/codex-orchestrator-cancel.dhCVwz` returned 143 with empty stdout,
  stage-labelled evidence paths, and helper PID 4, timeout PID 17, and fake Codex PID 18 all gone
  after one second.
- The live question marker `OBS_WAIT_ACCEPTANCE_LIVE_QUESTION_V2_20260813` returned session
  `019ffcbf-4087-7171-9300-9c726bdaff74` with 0 intermediate records, calls, waits, or token events.
  The successful corrective resume kept that same session and diagnostic directory, used exactly
  one bounded host wait after a forced outer yield, and produced the acceptance-only spec plus a
  CLEAR product-lens ledger in `/tmp/codex-observable-waiting-live-20260813`. That disposable
  worktree and its uncommitted fixture-only files were removed after the evidence was recorded.

**Issues:**
- The first live attempt failed immediately because the sandbox blocked Codex's app-server state;
  rerunning the same disposable-worktree acceptance with normal host access resolved it.
- The first live resume drafted the fixture but timed out after 120 seconds because its required
  product-lens path waited with zero receiver thread ids. The helper timed out cleanly with no live
  child. Resuming the same Codex thread with explicit fail-loud routing completed the lens and
  artifact. This exposed a separate stage-agent routing issue; it did not require a waiting-policy
  fallback or a production change.

**Deviations:**
- The live document stage needed one corrective resume because of its empty-recipient product-lens
  wait. All observable-waiting acceptance criteria remained unchanged and passed.

### Audit Remediation

**Completed:** 2026-08-13
**Changes:**
- Added the missing post-close `$my-pre-pr` human boundary beside `$my-close` in the authored Codex
  orchestrator skill, then rebuilt and reinstalled the generated pack.
- Added an exact generated-product assertion for the full ADR 0007 boundary. It failed against the
  pre-remediation generated skill and passed after the authored fix.
- Appended the independent audit-stage lens rerun, which returned CLEAR and resolved `audit-F1` by
  citation; re-checked spec success criterion 8 on that evidence.
- Re-ran the auditor's six-command set (`build-codex-pack`, generated-product test, pipeline sync,
  docs, installer dry-run, and `git diff --check`); all pass. The installed orchestrator skill and
  helper still match the rebuilt distribution.
- Tightened the Phase 3 evidence wording: cancellation is proven at the helper boundary, not through
  a host-cell interrupt; the live resume kept its thread identity but spent the single D2 fallback
  wait after the outer cell yielded at about 61 seconds.

**Deferred non-blocking audit findings:**
- `audit-F2`: the timeout value remains manually synchronized across the pragma, JavaScript recipe,
  and helper argument. Drift is bounded by the one-wait/fail-loud contract.
- `audit-F3`: TERM-ignoring escalation coverage and the GNU `timeout` process-group dependency remain
  follow-up hardening. The auditor verified the mechanism independently.

---

**Status:** Draft → In Progress → Complete
