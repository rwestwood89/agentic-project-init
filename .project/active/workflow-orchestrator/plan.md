# Implementation Plan: Workflow Orchestrator

**Status:** Draft
**Created:** 2026-07-02
**Last Updated:** 2026-07-02

## Source Documents
- **Spec:** `.project/active/workflow-orchestrator/spec.md`
- **Design:** `.project/active/workflow-orchestrator/design.md` ← component details, decisions (D1–D8), bets (B1–B4), invariants, risks
- **Spike 1 (mechanism already proven):** `.project/active/workflow-orchestrator/spike-findings.md` + `spike/`

## Implementation Strategy

**Phasing rationale.** De-risk before building. Phase 1 is a second throwaway spike that closes the
two mechanism unknowns the design flags in [Next-Stage Handoff](design.md#next-stage-handoff). Only
once those hold do we build the helper (Phase 2), then the judgment prompt (Phase 3), then prove the
whole thing unattended (Phase 4). Judgment quality (B1) is inherently a Phase 4 finding — Phases 1–2
prove *mechanism*, not *judgment*.

**Note on "test-first" for this work.** The deliverables are prompt files and a bash helper, not
unit-testable code. So each phase leads with the concrete **probe or validation run** that proves
it, executed against real `claude -p` — the style of Spike 1.

**Critical path:** Phase 1 (spike) → Phase 2 (helper) → Phase 3 (command prompt) → Phase 4 (dogfood).

**First proof point:** Phase 1 — a stage resumed after yielding questions produces a good artifact,
and `/_my_implement` runs headless without hanging.

**Overall validation:** each phase runs against real headless calls; Phase 4 is the real success
criteria from [spec Success Criteria](spec.md#success-criteria).

---

## Phase 1: Second spike — de-risk the two unproven legs

### Goal
Prove the mechanism end to end before writing production files. Throwaway probes only.

### Assumption Under Test
- **Yield-and-react (D7/D8):** a stage told "make your questions your final message and stop" stops
  (shown in Spike 1), and after the orchestrator answers and **resumes**, the stage **produces a
  good artifact** (unproven — the interrupted leg).
- **Implement headless:** `/_my_implement` runs non-interactively, and its "confirm scope / stop on
  deviation" gates become **recorded decisions, not hangs**. Validates the D5 `bypassPermissions`
  posture in practice.

### Test Stencil (run these first)
```bash
# Probe A — yield -> resume -> produce (completes the interrupted D7 test)
cd $SANDBOX && cat spike/prompts/spec-question-mode.txt | claude -p --output-format json \
  --permission-mode acceptEdits > 06-question.json          # expect: QUESTIONS in result, NO spec.md written
SID=$(jq -r '.[]|select(.type=="result").session_id' 06-question.json)
claude -p --resume $SID --output-format json --permission-mode acceptEdits < answers.txt \
  > 07-produce.json                                          # expect: spec.md now exists, reflects answers

# Probe B — implement headless (needs a minimal real plan.md first)
cd $SANDBOX && cat spike/prompts/implement.txt | claude -p --output-format json \
  --permission-mode bypassPermissions --max-budget-usd 5 > 08-implement.json
# expect: code written OR a deviation surfaced as a recorded decision in result; NOT a hang/timeout
```

### Changes Required
**See design for:** [D7/D8 protocol](design.md#key-decisions), [Validation Approach](design.md#validation-approach), [Potential Risks](design.md#potential-risks).

- [x] Probe A: authored the **uniform preamble** (not the old question-mode prompt — see deviations) and ran `spec` under it, on both a clear item and an un-defaultable one; ran the yield→resume→produce loop.
- [x] Probe B: hand-authored a minimal design + plan for `wordfreq` (see deviations), ran `/_my_implement` headless under the uniform preamble with `timeout` + `--max-budget-usd`, on both a 1-phase and a 2-phase plan.
- [x] Appended a **"Spike 2"** section to `spike-findings.md` with the results and a GO verdict.

### Validation
**Automated:**
- [x] Probe A: after resume, the discount `spec.md` exists and reflects the supplied answers (grep confirmed).
- [x] Probe B: every run exited within the timeout (no hang); implement produced real code (independently: 3/5 tests pass), and its scope gate surfaced as a prose yield + a recorded discrepancy.

**Manual:**
- [x] Produced discount spec read as a *good* artifact — testable success criteria, sensible `[INFERRED]`, open items parked.
- [x] Implement `result` on the 2-phase run: scope question + docs/code discrepancy surfaced as clear questions, not a guess or a hang.

**What We Know Works After This Phase:** the full yield→resume→produce loop (shaping stage) and
yield→resume→implement loop; implement is safe headless; the uniform preamble preserves each command's
own asking threshold. **GO** for Phase 2.

---

## Phase 2: Helper script + uniform preamble

### Goal
Build the mechanism layer: `orchestrate-stage.sh` and `orchestrate-preamble.md`.

### Assumption Under Test
The helper cleanly wraps the proven call and returns exactly what the orchestrator needs, with the
Spike-1 gotchas encoded once (stdin piping, stderr separation, `type:result` parsing).

### Test Stencil (write this first)
```bash
# spike/test-helper.sh — smoke test the helper against a real trivial call
out=$(claude-pack/scripts/orchestrate-stage.sh status --model sonnet --budget 2)
echo "$out" | jq -e '.session_id and .result and (.cost|type=="number")'   # fields present
sid=$(echo "$out" | jq -r .session_id)
claude-pack/scripts/orchestrate-stage.sh --resume "$sid" --model sonnet "say RESUMED_OK" \
  | jq -e '.result|contains("RESUMED_OK")'                                  # resume re-enters context
```

### Changes Required
**See design for:** [Component Overview](design.md#component-overview), [Implementation Notes](design.md#implementation-notes) (the sentinel/stdin/JSON gotchas), [D8](design.md#key-decisions).

- [x] `claude-pack/scripts/orchestrate-preamble.md` (NEW) — the single uniform non-interactive preamble.
- [x] `claude-pack/scripts/orchestrate-stage.sh` (NEW) — generalizes `spike/run.sh`. Refinement: exposes **`run <stage>` / `resume <session_id>` subcommands** instead of a `--resume` flag (cleaner — preamble injection is `run`-only policy; `resume` re-enters an existing session with no preamble). Flags `--model` (default opus), `--budget`, `--timeout`, `--perm`, `--log-dir`, `--preamble`, `--dry-run`. Returns `{session_id, result, cost, is_error}`; does **not** interpret `result`.
- [x] `spike/test-helper.sh` (NEW) — the smoke test.

### Validation
**Automated:**
- [x] `spike/test-helper.sh` passes: dry-run composition, real `run` (parseable fields), resume re-enters session. (Real calls on sonnet, ~$0.3.)
- [~] `shellcheck` unavailable in this env; substituted `bash -n` (syntax clean) on both scripts. Run `shellcheck` before PR.

**What We Know Works After This Phase:** a single, reliable command to run/resume any stage headless, returning clean JSON the orchestrator reads.

---

## Phase 3: The orchestrator command prompt

### Goal
Write `_my_orchestrate.md` — the judgment prompt. The bulk of the work.

### Assumption Under Test
B1 — the orchestrator can drive a real item coherently: orient, route, run the uniform loop, converge
reviews, commit with decisions in the subject.

### Test Stencil (prove incrementally)
```bash
# Dry single-stage drive in a sandbox: the command runs ONE stage via the helper and reacts.
# Success = it invoked the helper, read `result`, answered any yielded questions, committed.
cd $SANDBOX && claude --model fable "/_my_orchestrate outcomes.md --only spec"   # (a --only flag aids testing)
git -C $SANDBOX log --oneline    # expect a commit whose subject leads with the routing/spec decision
```

### Changes Required
**See design for:** [Core Concept](design.md#core-concept), [Architecture](design.md#architecture) (the loop), [D3](design.md#key-decisions) (convergence), [D4](design.md#key-decisions) (commit trail), [Required Invariants](design.md#required-invariants).

- [x] `claude-pack/commands/_my_orchestrate.md` (NEW) — role (judgment agent, not workflow engine); the mechanism (helper `run`/`resume`, read `result` as prose, models/perms/budget); orient & route (Stage 0); the uniform per-item loop (Stage P) with reviewer convergence; epic branch (Stage E); commit discipline; guidelines + anti-patterns; flags.
- [x] Invocation flags added: `--budget`, `--only <stage>`, `--from <stage>` (speculative — no proven need, low cost), `--model`.

### Validation
**Automated:**
- [→] Single-stage live drive (`--only spec`) — **moved to Phase 4.** The command references the
  installed helper path `~/.claude/scripts/orchestrate-stage.sh` (correct for production — it runs in
  arbitrary target projects), so any live drive needs `setup-global.sh` first, which is Phase 4's
  first step. Coupling recorded below; recommend running the first live drive as the opening of Phase 4.
**Manual:**
- [x] Self-review vs. design: uniform loop, D3 convergence, D4 commit trail, D7 (stage decides), D8
  (`result` as prose), front-loading, autonomy, epic branch — all present. Command is discoverable
  (harness lists it as a skill). Holds up.

**What We Know Works After This Phase:** the command prompt exists and is internally sound; the first
*live* orchestrator drive is the opening move of Phase 4 (post-install).

---

## Phase 4: End-to-end dogfood + wiring

### Goal
Prove the whole thing unattended, then wire it into the packs.

### Assumption Under Test
The real success criteria: a full run completes without interaction, artifacts are coherent, and the
git log reconstructs the reasoning (B1 at full scope).

### Test Stencil (the real test)
```bash
# In a throwaway git worktree, hand it a small well-specified outcomes doc and walk away.
git worktree add ../orch-dogfood && cd ../orch-dogfood
claude --model fable "/_my_orchestrate side-project-outcomes.md --budget 40"
# then inspect, do not intervene:
git log --oneline          # every stage/decision present, subjects lead with the decision
ls .project/active/*/       # spec, design, plan, audit artifacts coherent
```

### Changes Required
**See design for:** [Integration Strategy](design.md#integration-strategy), [Validation Approach](design.md#validation-approach).

- [ ] Run the dogfood on a **LOW-complexity single item** first; capture findings (append to `spike-findings.md` or a short `dogfood-notes.md`).
- [ ] Then run a **small epic** to exercise the epic branch + sequential items.
- [ ] `codex-overrides/config.sh` — add `_my_orchestrate` to `EXCLUDED_COMMANDS`.
- [ ] Run `scripts/setup-global.sh` (symlink the command + scripts into `~/.claude/`).
- [ ] Update `CLAUDE.md` (Commands section) and `CURRENT_WORK.md`.

### Validation
**Automated:**
- [ ] Codex build excludes the command (`./scripts/build-codex-pack.sh` produces no `my-orchestrate` skill).
- [ ] `setup-global.sh` symlinks resolve.
**Manual:**
- [ ] Single-item dogfood: unattended completion; coherent artifacts; git log tells the story.
- [ ] Epic dogfood: decomposition sane; items run in dependency order.

**What We Know Works After This Phase:** the command, end to end, on real work — the go/no-go on whether autonomous mode is trustworthy.

---

## Environment Setup

**See CLAUDE.md.** New command + scripts require `scripts/setup-global.sh` before use in other
sessions. `shellcheck` for the helper. All probes/dogfood run against real `claude -p` (real spend) —
use `--budget` and git worktrees for isolation.

## Risk Management

**See [design.md#potential-risks](design.md#potential-risks).**

**Phase-specific mitigations:**
- **Phase 1:** wall-clock `timeout` + `--max-budget-usd` on every probe; sandbox project so nothing real is touched.
- **Phase 3–4:** `--only`/`--budget` flags to keep test runs cheap and scoped; git worktree isolation so a bad dogfood run is discarded, not cleaned up.
- **Judgment quality (B1):** the honest go/no-go is deferred to Phase 4 by design — don't treat Phases 1–2 passing as evidence the *judgment* works.

## Implementation Notes

### Phase 1 Completion
**Completed:** 2026-07-02 · **Cost:** $2.19 (sonnet, 6 headless calls) · **Verdict: GO**

**What happened:** All probes passed with no hangs. Full results in `spike-findings.md` → "Spike 2".
- Yield→resume→produce proven for a shaping stage (`spec` on an un-defaultable item).
- Implement proven safe headless (1-phase proceeds; 2-phase yields the scope question as prose, then
  resumes and implements both phases; tests pass). It also surfaced a real docs/code discrepancy as a
  question rather than guessing.
- The uniform preamble faithfully preserves each command's own asking threshold — the stage decides
  whether to yield, not the orchestrator (validates D7/D8).

**Deviations from plan (deliberate):**
- Used the **uniform preamble** (`spike/prompts/uniform-preamble.txt`) instead of the plan's stencil
  reference to the old `spec-question-mode.txt`. The plan's stencil predated the D7/D8 redesign; the
  uniform preamble is what the design now specifies, so it was the correct thing to probe.
- **Hand-authored** a minimal `design.md` + `plan.md` for `wordfreq` rather than generating them via
  headless `design`/`plan` calls. Isolated the implement question cheaply; the generation mechanism
  was already proven in Spike 1. Both artifacts are in the p1 sandbox.

**Carry into Phase 3 (command prompt):** a well-specified item makes shaping stages proceed without
yielding, so the orchestrator only injects concept intent when the stage judges a question
high-leverage — the lever for more intent is richer stage args, not the preamble. No "when in doubt,
yield" bias was needed.

### Phase 2 Completion
**Completed:** 2026-07-02 · smoke test passes (real sonnet calls, ~$0.3)

**Delivered:** `claude-pack/scripts/orchestrate-stage.sh`, `claude-pack/scripts/orchestrate-preamble.md`,
`spike/test-helper.sh`.

**Refinement vs. design:** the helper exposes **`run` / `resume` subcommands** rather than a
`--resume` flag. Cleaner abstraction — preamble injection is policy that only `run` needs, and
`resume` re-enters an existing session (which already holds the preamble) with just a message. Worth
reflecting back into design D-notes when convenient (minor).

**Gaps:** `shellcheck` isn't installed here; used `bash -n` instead. Run `shellcheck` before the PR.

**Carry into Phase 3:** the orchestrator calls `orchestrate-stage.sh run <stage>` (stage args on
stdin) and `orchestrate-stage.sh resume <sid>` (message on stdin), then reads the returned JSON's
`result` as prose to decide the next move. Default stage model is opus; implement/pre_pr need
`--perm bypassPermissions`.

### Phase 3 Completion (prompt written + self-reviewed; live drive deferred to Phase 4)
**Completed:** 2026-07-02

**Delivered:** `claude-pack/commands/_my_orchestrate.md` — the judgment prompt. Self-review confirms
it encodes the uniform loop, D3/D4/D7/D8, front-loading, autonomy, and the epic branch, with no
per-command-internals reasoning. Command is discoverable (harness lists it as a skill).

**Sequencing finding (real):** the command references the **installed** helper path
`~/.claude/scripts/orchestrate-stage.sh`. This is correct — the orchestrator runs in arbitrary target
projects that don't contain `claude-pack/`, so it must use the global install, not a repo-relative
path. Consequence: **no live orchestrator drive is possible until `setup-global.sh` runs** (Phase 4's
first step). The plan's Phase 3 live `--only spec` test therefore moves to the opening of Phase 4.
Not a defect — a phase-boundary correction.

**Carry into Phase 4:** run `setup-global.sh` first; then the opening validation is a single
`--only spec` live drive in a git-init'd sandbox/worktree before the full end-to-end dogfood.

---

**Status**: Draft → In Progress → Complete
