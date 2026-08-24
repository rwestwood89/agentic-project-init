# Audit: Codex Orchestrator Observable Waiting

**Verdict:** Needs Work
**Audited:** 2026-08-13
**Branch:** `anchor-on-the-point`
**Commit:** `b114400` + uncommitted working tree

---

## The Point

Codex orchestration must stop burying the main terminal timeline under repeated no-news waits, and
must stop invoking the parent model merely to learn that a stage is still running. The owner stated
the problem twice: the current output "makes following the progress of the main agent in terminal
impossible," and the polling is "kind of a waste of tokens" (owner, 2026-08-13). The observed bad
run spent 93 wait-related model passes over a 27-minute window.

This is an observation-layer correction only. One isolated headless agent still owns each stage, the
commit trail stays auditable, and orchestration still leaves `close` — and the post-close `pre_pr`
branch gate — to the human unless asked (`docs/guide.md:137`;
`.project/adr/0007-pre-pr-branch-gate-after-close.md`).

## Summary

The waiting mechanism works and is well evidenced. I re-ran the saved parent session through the
analyzer myself: a 36.1-second normal stage crossed with zero intermediate records, parent tool
calls, waits, and token events, and a real live Codex stage returned a genuine thread id, compact
result, and retained logs with the same zero counts. All six validation commands pass, `dist/codex`
rebuilds byte-identical to the working tree, and the installed pack matches generated output.

The block is not in the waiting path. The Codex orchestrator skill's finish rule gates `$my-close`
but says nothing about the post-close `pre_pr` branch gate, while listing `$my-pre-pr` as an
ordinary stage. ADR 0007 is an active owner/`[HARD]` invariant binding orchestrators to both. The
spec claims that boundary as a checked success criterion; the artifact does not carry it. The fix is
one line in the authored skill plus a rebuild, a reinstall, and a test assertion.

## Product Judgment

**Is this the right piece of work? Yes — and it does what the owner asked.** The mechanism is the
smallest thing that removes the owner's stated pain: one host-owned execution cell, no daemon, no
new schema, no streaming. The evidence for that is real, not asserted.

**Product-lens ledger gate: BLOCKED** (`product-lens.md`, `audit` run). Every block in the ledger
was scanned: the two spec-stage findings are resolved by citation; the audit run adds one new block.

- **audit-F1 (BLOCK, owner/`[HARD]`, unresolved).** Confirmed independently.
  `codex-overrides/command-skill-replacements/orchestrate/SKILL.md:118` reads "Leave `$my-close` to
  the human unless explicitly asked to archive the work." The Claude command states the full rule —
  "leave `close` — and the post-close `pre_pr` branch gate — to the human unless asked"
  (`claude-pack/commands/_my_orchestrate.md:73-74`). ADR 0007's established invariant is
  "Orchestrators leave `close` and the post-close `pre_pr` to the human unless asked." Meanwhile the
  Codex skill lists `$my-pre-pr` as a common stage twice with no gate (`:108`, `:145`), which is
  exactly the misreading the ADR exists to stop. The gap predates this item, but the spec's own
  success criterion asserts the boundary holds after this change, and it does not. This forbids
  Certify.

**Structural smells that fired, and how I resolve them:**

- **audit-F2 — Smell "two representations manually synchronized" (fired).** Resolved as a real
  cleanup, not a block. The stage timeout `T` appears three times in the recipe and must be
  hand-synced. Drift is bounded, though: an early yield lands in the single `functions.wait`
  fallback, and a second yield is a loud compatibility failure by contract, so the failure mode
  costs one extra parent turn rather than restoring the polling loop. Fix it, don't gate on it.
- **audit-F3 — Smells "test selects one route" and "correctness depends on an external internal
  detail" (fired).** Resolved as non-blocking. The escalation branch is empirically correct — the
  lens ran a TERM-ignoring fake codex and the group kill reaped it after the grace, and I confirmed
  separately that GNU `timeout` makes itself a process-group leader with its child in that group
  (`ps -o pgid`: timeout 162607 / sleep 162609 both PGID 162607). So this is a coverage gap and an
  unstated dependency, not a live defect.

No epic exists for this item, so there is no epic-level gate to consult.

## Findings

### Plan completion

All three phases are implemented, and the notes are honest — they record the expected red results,
the two live-run failures, and the one deviation. Two checkboxes overstate their evidence:

- `plan.md:290` — "Active cancellation returns promptly and leaves no fake helper, timeout, or Codex
  child after five seconds" is listed under **Host-Level Acceptance**, but the evidence recorded at
  `plan.md:386-388` is the Phase 1 shell fixture (`/tmp/codex-orchestrator-cancel.dhCVwz`), which
  sends TERM to the helper directly. I searched the saved session for a cancellation marker: only
  `NORMAL`, `FORCED_YIELD`, `LIVE_QUESTION*`, and `LIVE_RESUME*` are present. Nothing demonstrates
  that interrupting a Codex `functions.exec` cell delivers a signal the helper's trap can see. The
  whole D4 cancellation design rests on that assumption. Either run the host-level case or move this
  item out of the host-acceptance list and state the assumption as unverified.
- `plan.md:294` — "Question/result plus resume preserves the original Codex thread id" is met, but
  the resume run needed a `functions.wait` fallback (see Spec conformance below). The checkbox reads
  cleaner than the evidence.

### Spec conformance

- **SC1 — readable timeline across three polling intervals.** Met. Session lines 205-206: launch
  20:07:20.444Z, terminal 20:07:56.582Z, `records_between: 0`. One `custom_tool_call` in, one output
  back, no repeated prompt body.
- **SC2 — parent not invoked solely to learn the stage is still running.** Met for the normal path
  (0 parent tool calls, 0 waits, 0 token events between launch and result), and the counts are
  recorded as the criterion requires. Partially qualified in live use: the real resume stage
  (`OBS_WAIT_ACCEPTANCE_LIVE_RESUME_V2_20260813`, session lines 278-291) had its outer cell yield at
  ~61s despite a T+30 = 150s deadline, then spent exactly one wait-only parent turn on the fallback.
  That is design decision D2 working as specified and bounded at one, not a regression — 2 parent
  turns where the old path spent ~7. Flagging it because bet **B1** ("hosts can keep one cell pending
  through a normal stage deadline") is weakly contradicted by live evidence, and the owner should
  know real long stages cost one wait turn, not zero.
- **SC3 — periodic liveness is concise and needs no parent turn.** Met by removal: D3 drops `notify`
  and relies on the client's running-tool indicator.
- **SC4 — completion, questions, failure, timeout, cancellation, resume surface with correct
  identity.** Met at shell level; all five cases pass in `scripts/test_codex_orchestrator_pack.sh`
  (fresh session id, resume id preserved, `turn.failed` → exit 3, timeout → exit 1, cancellation →
  exit 143). Live question/resume preserved thread `019ffcbf-4087-7171-9300-9c726bdaff74`.
  Cancellation is unverified at host level (see Plan completion).
- **SC5 — final message and raw/stderr/final diagnostics remain available.** Met; asserted in the
  test and visible in the live acceptance output.
- **SC6 — a `$my-spike` records evidence before design commits.** Met; `spike-findings.md` and
  `probes/` are complete and reproducible.
- **SC7 — generated and installed assets carry the behavior, with tests that fail if polling
  returns; Claude orchestrator unchanged.** Met. `git status claude-pack/` is clean, the rebuild is
  byte-identical, and the installed skill/helper match `dist/codex`.
- **SC8 — preserves one isolated headless agent per stage, the auditable commit trail, and the
  `close`/post-close `pre_pr` human boundary.** **Not met.** Isolation and the commit trail are
  preserved. The `pre_pr` half of the boundary is absent from the Codex skill (audit-F1). I have
  unchecked this criterion in `spec.md`.
- **Non-goals respected.** Yes. No daemon, no status file, no event streaming, no Claude change, no
  stage-selection change.

### Design conformance

Implementation follows the design, with one gap:

- D1 (one host cell, T+30 outer yield), D2 (one bounded fallback, `terminate: true` on a second
  yield), D3 (launch and terminal only), D5 (result/log protocol unchanged), D6 (extend the existing
  test) are all implemented and asserted.
- D4 is implemented as specified: async pipeline, `$!` is the final `timeout`, traps installed before
  launch, PID cleared after `wait`, escalation targets the timeout-owned group.
- **Gap — `codex-overrides/scripts/orchestrate-stage-codex.sh:235`.** The required invariant says
  "After timeout, cancellation, or parent interruption, the owned timeout/Codex child is gone within
  the cleanup grace **or the helper reports cleanup failure**" (`design.md:174-175`). On the timeout
  path (`RC=124`) the helper calls `die` immediately. GNU `timeout` without `-k` sends only TERM; a
  child that ignores it survives, and nothing checks or reports that. The cleanup-failure clause has
  no implementation on any path. Either add a post-`die` liveness check on the timeout path, or drop
  the clause from the invariant so the design stops promising it.

### Code integrity

- **`codex-overrides/scripts/orchestrate-stage-codex.sh:229-230` — startup signal race.** A signal
  arriving between the backgrounded pipeline and `RUNNER_PID=$!` leaves `cancel_runner` with an empty
  PID; it exits 143 and orphans the pipeline. The window is one bash command wide and the design
  anticipated tolerating it, but "tolerates" here means "orphans silently," which contradicts the
  spec's `[INFERRED]` requirement that the waiting path never silently orphan a stage. Cheapest fix:
  on empty `RUNNER_PID`, say so on stderr rather than exiting quietly.
- **`codex-overrides/scripts/orchestrate-stage-codex.sh:204` — unstated process-group dependency.**
  `kill -KILL -- "-$runner_pid"` is only correct because GNU `timeout` calls `setpgid(0,0)`. Nothing
  in the script says so. Add a one-line comment; a future switch to `timeout --foreground` or a
  BusyBox `timeout` silently turns this into a no-op.
- **`scripts/test_codex_orchestrator_pack.sh:74-119` — escalation branch never exercised.** The fake
  codex traps HUP/INT/TERM and exits, so every test reaches cleanup through normal forwarding. Add a
  TERM-ignoring mode so the 5-second grace and group kill are covered.
- **`codex-overrides/command-skill-replacements/orchestrate/SKILL.md:42-60` — `T` stated three
  times.** `--timeout T` in the command, `helperTimeoutSeconds = 600` in the JS, and the literal
  `630000` in the `// @exec:` pragma must be kept in agreement by hand. The pragma genuinely cannot
  be computed, but the JS constant can be derived from it, and the test can assert the arithmetic.
- No god functions, policy-in-utility, broad excepts, or dead compatibility shims. `cancel_runner` is
  a single-purpose function with a readable contract. Auto-memory `feedback_*` entries hold no
  constraint this change violates.

---

## Certification

**Not certified.** The product-lens ledger gate is BLOCKED on audit-F1, an unresolved owner/`[HARD]`
contradiction with ADR 0007. Per the audit contract that is Needs Work, not a nitpick.

What I verified and marked:

- Ran all six validation commands myself: `test_codex_orchestrator_pack.sh`, `test_pipeline_sync.sh`,
  `test_docs.sh`, `setup-codex.sh --dry-run`, `build-codex-pack.sh`, `git diff --check`. All pass.
- Confirmed `dist/codex` rebuilds to the committed working-tree state (manifest timestamp/revision
  churn only), and that the installed skill (copy) and helper (symlink) match `dist/codex`.
- Re-derived the host acceptance counts from the saved session rather than trusting `plan.md`. The
  NORMAL, FORCED_YIELD, and LIVE_QUESTION_V2 numbers match the plan exactly.
- Confirmed GNU `timeout` process-group behavior empirically.
- Left every plan checkbox as marked, with two evidence-overstatement notes recorded above rather
  than silent unchecking — the work was done, the evidence is narrower than the wording.
- **Unchecked spec success criterion 8** (`spec.md`), which asserts the `close`/post-close `pre_pr`
  boundary is preserved. It is not.

To reach Certify: fix audit-F1 in the authored Codex skill, rebuild, reinstall, add a test assertion
for the `pre_pr` boundary, then re-run the product-lens and resolve the block by citation. audit-F2,
audit-F3, and the four code-integrity findings are worth doing in the same pass but do not gate.

**Not checked:**

- Host-level cancellation of a `functions.exec` cell. Whether interrupting the host delivers a signal
  the helper's trap can observe is untested; all cancellation evidence is shell-level.
- A stage that actually runs to the full default `T = 600` outer deadline. The longest observed cell
  is 61 seconds before yield, so the T+30 boundary is asserted, never exercised.
- Whether `Date.now()` behaves as assumed inside a Codex `// @exec:` cell. Every recorded acceptance
  run hardcoded its yield times instead of using the skill's arithmetic, so the literal recipe as
  written in the skill was never executed end to end.
- Whether the static string assertions in the pack test would actually catch a reintroduced polling
  loop expressed in different words. They catch `setInterval`, `setTimeout`, `yield_control`, and
  `notify(`, and require the "Do not poll" / "only once" wording to survive.
- The disposable live worktree `/tmp/codex-observable-waiting-live-20260813` and its artifacts, which
  were removed before this audit ran. I verified the live run through the saved session log instead.
- Behavior on non-GNU `timeout`, and any Codex CLI other than the installed 0.147.0.
