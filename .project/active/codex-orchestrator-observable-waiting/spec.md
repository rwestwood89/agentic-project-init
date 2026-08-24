# Spec: Codex Orchestrator Observable Waiting

**Status:** Complete
**Owner:** Reid W
**Created:** 2026-08-13T11:20:17-07:00
**Complexity:** MEDIUM
**Branch:** anchor-on-the-point

---

## Problem

Codex `my-orchestrate` can run the pipeline, but a long stage makes the parent agent's terminal
timeline unreadable. The stage helper is one blocking process. When the terminal tool yields, the
parent agent repeatedly wakes, reports that nothing has changed, and checks the same process again.
The interface renders each check under the original long command, so monitoring noise displaces the
main agent's actual decisions and progress.

The same loop spends model work to discover that there is no news. In the observed 2026-08-13 run,
a roughly 27-minute design/design-review window produced 46 terminal polls plus 47 wrapper waits.
Those 93 wait-related model passes processed about 9.14 million input tokens, of which about 9.07
million were cached. The command itself was not rerun; the repeated command text was a display label.

The functional orchestration contract is not the problem. Stage launch, questions, resumption,
completion, failure, timeout, and diagnostic logs still matter. The gap is a waiting path that keeps
those events visible without making elapsed time itself a reason to invoke the parent model or add
another transcript entry.

## Success Criteria

- [x] During a representative long-running stage that crosses at least three current polling
  intervals, the main terminal timeline remains readable: it shows launch, material progress or
  questions, and the terminal outcome without repeated no-news wait rows or repeated prompt bodies.
- [x] The parent model is not invoked solely to learn that the stage is still running. Validation
  distinguishes material-event turns from wait-only turns and records the counts.
- [x] Any periodic liveness indication is concise and does not require a parent-model turn.
- [x] Completion, yielded questions, failure, timeout, cancellation, and resume continue to surface
  promptly with the correct stage/session identity.
- [x] The final stage message and existing raw JSONL, stderr, and final-message diagnostics remain
  available for routing and debugging.
- [x] A `$my-spike` records evidence for the runtime assumptions listed below before design commits
  to a waiting mechanism.
- [x] Generated and installed Codex orchestration assets carry the behavior, with tests that fail if
  repeated model-visible polling returns. The Claude orchestrator continues to work unchanged.
- [x] The waiting change preserves one isolated headless agent per stage, the auditable commit
  trail, and the existing boundary that `close` and post-close `pre_pr` run only when the owner asks.
  (Audit remediation 2026-08-13: the authored and generated skill now gate both commands, the pack
  test asserts the full boundary, and the independent lens resolved `audit-F1` by citation.)

## Known Requirements

- **[NEED]** The terminal must no longer make the owner's stated problem true: “it makes following
  the progress of the main agent in terminal impossible.” (Owner, 2026-08-13.)
- **[NEED]** The solution must address the owner's observed waste: “Codex seems to very actively
  poll, which seems like kind of a waste of tokens.” (Owner, 2026-08-13.)
- **[NEED]** Use a `$my-spike` to check behavioral assumptions before relying on them in design.
  (Owner, 2026-08-13.)
- **[INFERRED]** Elapsed time without a state change must not, by itself, create a parent-agent model
  turn.
- **[INFERRED]** A liveness signal, if retained, must be emitted outside the parent reasoning loop
  and must use a compact stage label rather than restating the stage prompt or full command.
- **[INFERRED]** High-volume child-process events must be drained or summarized outside the main
  conversation. Forwarding every JSONL state change would replace polling noise with event noise.
- **[INFERRED]** The waiting path must clean up or retain a recoverable handle after completion,
  failure, timeout, cancellation, or parent interruption; it must not silently orphan a stage.
- **[INHERITED]** Preserve the Codex helper's `run`/`resume` stage protocol, resumable thread id,
  compact final result, and retained diagnostic files unless the spike demonstrates that one of
  those contracts prevents the owner-stated outcome. Source:
  `.project/active/codex-orchestrator-fork/spec.md` and `design.md`.
- **[INHERITED]** Keep the existing Claude orchestration path intact. Source:
  `.project/active/codex-orchestrator-fork/spec.md`.
- **[INHERITED]** Preserve one isolated headless agent per stage and the commit trail the owner can
  audit afterward. Source: `docs/guide.md`.
- **[INHERITED]** Orchestration leaves `close` and the post-close `pre_pr` branch gate to the human
  unless requested. Source: `.project/adr/0007-pre-pr-branch-gate-after-close.md` (`[OWNER]`).
- **[INHERITED]** Author Codex-specific behavior in `codex-overrides/` and regenerate
  `dist/codex/`; do not hand-edit generated output. Source: `docs/STRUCTURE.md`.

## Non-Goals

- Reduce the child stage agent's own exploration, tool calls, or reasoning-token use. That is a
  separate efficiency problem.
- Redesign pipeline stages, stage selection, review policy, or artifact protocols.
- Stream every child JSONL event into the main terminal.
- Require the Codex behavior to copy Claude's background-task mechanism internally.
- Change the Claude orchestrator while correcting the Codex waiting path.
- Guarantee a particular dollar saving or account-rate-limit effect; validation concerns observable
  model turns and token counts.
- Redesign terminal rendering outside the orchestration workflow except where the current wait path
  supplies the repeated command label.

## Spike Results / Deferred to design

The required `$my-spike` ran on 2026-08-13 with a controllable fake Codex stage. It found:

- One host-owned execution call completed a 66-second stage without an intermediate parent
  inference or model-visible poll.
- A deliberately yielded execution cell needed one long completion wait, not repeated short polls.
- Scheduled `notify` output was retained only after the terminal result. Design must not depend on
  it for live progress.
- Success, resume, reported failure, timeout, compact results, and diagnostic logs retained their
  identity and shape.
- Outer cancellation left the fake child alive after one second. The helper needs explicit signal
  and process-group cleanup.
- Session markers and the absence of events between launch and completion provide automatable
  polling evidence. Pricing semantics remain out of scope.

The spike tested:

- whether one tool invocation can own and collect a stage across the relevant timeout without
  model-visible polling;
- whether an out-of-band notification or equivalent reaches the terminal without another parent
  inference;
- whether completion, failure, timeout, cancellation, and resume retain the correct process and
  Codex thread identity;
- whether JSONL can be drained without blocking while only material events reach the parent;
- whether the terminal can display a concise stage label instead of the full heredoc on wait events;
- and whether saved session evidence can distinguish launch/terminal-event turns from wait-only
  turns and report their token use.

Design may select completion-driven waiting, but it must preserve the two limits the spike exposed:
periodic live notification is unavailable as tested, and cancellation cleanup is not yet safe. The
full evidence and reproduction harness are in `spike-findings.md` and `probes/`.

---

## Related Artifacts

- **Prior Codex orchestrator:** `.project/active/codex-orchestrator-fork/{spec,design,spike-findings,plan}.md`
- **Codex orchestrator source:** `codex-overrides/command-skill-replacements/orchestrate/SKILL.md`
- **Codex helper source:** `codex-overrides/scripts/orchestrate-stage-codex.sh`
- **Claude reference:** `claude-pack/commands/_my_orchestrate.md` and
  `claude-pack/scripts/orchestrate-stage.sh`
- **Generated-product test:** `scripts/test_codex_orchestrator_pack.sh`
- **Distribution contract:** `docs/STRUCTURE.md`
- **Product description:** `README.md` and `docs/guide.md`
- **Observed parent session:**
  `/home/reid/.codex/sessions/2026/08/13/rollout-2026-08-13T10-19-18-019ffc22-aa00-79c2-b59f-8a723ce21c41.jsonl`
- **Spike findings:** `.project/active/codex-orchestrator-observable-waiting/spike-findings.md`
- **Product lens:** `.project/active/codex-orchestrator-observable-waiting/product-lens.md`
- **Design:** `.project/active/codex-orchestrator-observable-waiting/design.md`

---

**Next Steps:** Run `$my-audit` to certify the implementation against this spec and its plan.
