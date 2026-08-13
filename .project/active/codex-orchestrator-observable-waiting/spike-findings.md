# Spike: Completion-Driven Codex Stage Waiting

**Date:** 2026-08-13 11:32:19 PDT
**Branch:** `anchor-on-the-point`
**Commit:** `1456213`
**Codex CLI:** `0.147.0`
**Upstream:** `.project/active/codex-orchestrator-observable-waiting/spec.md`

## Summary of Findings

**Verdict: partially confirmed, with a viable completion-driven path and two hard design
constraints.** A 66.1-second fake stage completed inside one model-visible host invocation. The
saved session contains no parent inference, wait call, or token-count event between launch and the
terminal result. A separate forced-yield run completed with one long `wait`, which shows that an
unexpected host yield does not require periodic polling.

The helper retained JSONL and stderr diagnostics, returned its compact result, preserved resume
identity, surfaced a reported failure, and cleaned up its own timeout. Two assumptions did not
hold. Scheduled `notify` messages were recorded only after the terminal result, so live
out-of-band progress is not established. Cancelling the helper from outside left the fake Codex
child alive after one second; the probe harness had to terminate that exact PID.

The smallest design may therefore use one host-owned execution cell with a completion deadline
slightly beyond the stage helper's own timeout. It should show one concise launch message, rely on
the client's existing running-tool indicator for liveness, and return only on a material outcome.
If the cell yields unexpectedly, the parent may issue one wait for the remaining deadline, never a
short polling loop. The helper must also trap external cancellation and terminate its child process
group. Periodic `notify` output is not part of the design unless a later UI-level test proves it is
rendered before completion.

## Question / Goal

Assumption under test: the available Codex host tools can supervise one blocking orchestration
stage through a single model-visible tool invocation, emit concise out-of-band liveness, and wake
the parent model only when a material terminal event is ready.

The assumption is confirmed if a fake stage lasting longer than three former polling intervals:

1. completes without a model-visible `wait` or `write_stdin` polling loop;
2. produces user-visible liveness without an intervening parent inference;
3. returns the existing compact helper result and retained diagnostic logs; and
4. preserves observable behavior for resume, reported failure, timeout, and cancellation cleanup.

The assumption is disproved if the host must return control to the model to keep waiting, if
notifications themselves trigger parent inference, or if avoiding polls loses lifecycle identity or
leaves the child running. The probes split this compound assumption: completion-driven waiting is
confirmed; live notification is unconfirmed; external-cancellation cleanup is disproved for the
current helper.

## Log

### 1. Contract and environment

Commands:

```bash
.project/scripts/get-metadata.sh
codex --version
codex exec --help
sed -n '1,260p' codex-overrides/scripts/orchestrate-stage-codex.sh
```

Observed:

- Metadata: 2026-08-13 11:32:19 PDT, branch `anchor-on-the-point`, commit `1456213`.
- Installed CLI: `codex-cli 0.147.0`.
- Official OpenAI documentation says ordinary `codex exec` streams progress on stderr and prints
  the final message on stdout. With `--json`, stdout becomes a JSONL event stream containing
  `thread.started`, turn events, and item events. `codex exec resume <SESSION_ID>` resumes a saved
  non-interactive session. Source: <https://learn.chatgpt.com/docs/non-interactive-mode>.
- The current helper redirects JSONL stdout and stderr to files and emits its compact result only
  after `codex` exits (`codex-overrides/scripts/orchestrate-stage-codex.sh:178-196`). This explains
  the silent terminal job, but does not establish how the outer host can wait for it.

### 2. Reproducible probe harness

The harness is in `probes/` beside this document:

- `probes/codex` is a fake Codex CLI. It emits valid JSONL and stderr progress, writes the requested
  final-message file, preserves a requested resume id, and records signal cleanup.
- `probes/run-helper-probes.sh` runs the authored helper against that fake CLI. Its `all` case covers
  a 36-second success plus resume, an event-reported failure, timeout cleanup, and outer
  cancellation cleanup.
- `probes/analyze-parent-session.sh` counts tool calls, waits, and token events between a marked
  parent tool call and its terminal result in a saved Codex session.

The 36-second case crosses three 10-second polling intervals from the observed bad run. It avoids a
live nested model call while exercising the same helper process, redirect, parser, and timeout
shape.

### 3. One-shot host supervision and lifecycle matrix

Command shape:

```javascript
const notice = setTimeout(() => notify("fake design stage remains active"), 12000);
let result = await tools.exec_command({
  cmd: ".project/active/codex-orchestrator-observable-waiting/probes/run-helper-probes.sh all",
  yield_time_ms: 30000,
});
while (result.session_id) {
  result = await tools.write_stdin({
    session_id: result.session_id,
    chars: "",
    yield_time_ms: 300000,
  });
}
clearTimeout(notice);
```

The host call also scheduled notices at 12 and 24 seconds with `notify`. It ran
`probes/run-helper-probes.sh all` and returned after 54.4 seconds. Evidence is retained under
`probe-output/20260813-113536-2/`.

Observed:

- The 36-second success completed with the expected thread id and compact result. Its retained log
  has nine JSONL events and six stderr progress lines.
- Resume returned the requested `019-spike-resume` identity.
- A `turn.failed` event produced the helper's structured error result and exit code 3.
- The helper's own two-second timeout terminated the fake child. After one second the child was
  gone and its signal trap had run.
- Cancelling the helper from outside returned promptly, but after one second the fake child was
  still alive and had not received a signal. The harness then killed that exact recorded PID as
  cleanup. This disproves prompt cancellation cleanup in the current helper shape.

The parent session log contains one outer tool call at `18:35:36.317Z` and its terminal result at
`18:36:30.709Z`, with no intervening token-count event or model-visible wait call. The next
token-count event appears after the terminal result. This confirms that a host-owned wait can remove
the periodic parent inference loop for a stage that finishes within that outer call's yield window.

The two `notify` records appear in the saved session only after the terminal result, both timestamped
`18:36:30.750Z`. The host may have rendered them earlier, but the retained evidence cannot establish
that. Treat live out-of-band liveness as unconfirmed, not as a capability the design may assume.

### 4. Host yield boundary

The first attempt set the fake duration beyond the helper's own 60-second timeout. It correctly
timed out, but did not answer the host question. The harness now accepts separate fake-duration and
helper-timeout controls, and standalone cases propagate a failed return code.

Two corrected runs answered the boundary question:

- A 61-second fake stage with a deliberately one-second outer yield returned a cell id. One
  56.6-second `wait` collected the terminal success. There were no intermediate waits.
- A 66-second fake stage used a 70-second outer yield and a 90-second helper timeout. It completed
  in one outer tool call. In the saved parent session, the launch is at `18:41:33.813Z` and the
  terminal result is at `18:42:39.957Z`. No event exists between those records.

These runs establish that the host can wait beyond 60 seconds when its outer yield is set
accordingly. They do not prove a product-wide maximum or promise future host behavior. Design and
acceptance tests should set the outer deadline from the helper timeout and retain the forced-yield
fallback as a bounded recovery path.

### 5. What the design may assume

- **Confirmed:** one host call can own a stage for at least 66 seconds without parent polling.
- **Confirmed:** if that call yields, one long completion wait can collect it without a polling
  loop.
- **Confirmed:** JSONL and stderr are drained to retained files while the parent receives only the
  compact terminal result.
- **Confirmed:** success, resume identity, event-reported failure, and helper timeout keep their
  expected result shape.
- **Disproved for the current helper:** outer cancellation promptly cleans up the Codex child.
- **Unconfirmed:** `notify` reaches the terminal before the host call completes. The session log and
  this transcript place its output after the terminal result.
- **Unneeded for the core fix:** custom terminal labels for wait rows. Completion-driven waiting
  removes those rows; the original launch command may still appear once.

### 6. Proposed design constraint

Keep the stage helper blocking. Change the Codex orchestrator's supervision instructions so the
parent starts it once inside a host-owned execution call whose yield covers the helper deadline.
The nested host code may drain its execution session, but that loop must remain inside the same tool
call and must not return no-news results to the model. If the outer cell yields despite that
deadline, issue one `functions.wait` for the remaining stage deadline.

Do not schedule periodic parent turns or depend on `notify`. Before changing the orchestration
instructions, add explicit signal trapping and process-group cleanup to the helper. Acceptance must
inspect the saved parent session for zero wait-only turns and inspect child cleanup after both
timeout and outer cancellation.

## Reproduction

From the repository root:

```bash
chmod +x \
  .project/active/codex-orchestrator-observable-waiting/probes/codex \
  .project/active/codex-orchestrator-observable-waiting/probes/run-helper-probes.sh \
  .project/active/codex-orchestrator-observable-waiting/probes/analyze-parent-session.sh

.project/active/codex-orchestrator-observable-waiting/probes/run-helper-probes.sh all

.project/active/codex-orchestrator-observable-waiting/probes/analyze-parent-session.sh \
  /home/reid/.codex/sessions/2026/08/13/rollout-2026-08-13T11-07-27-019ffc4e-bf3d-7091-ba76-de80ace2804b.jsonl \
  OBS_WAIT_SPIKE_LONG_ONE_SHOT_V3
```

The host-level command shape is recorded in the Log because it uses the Codex tool host's `notify`,
`exec_command`, and `write_stdin` primitives rather than a standalone shell API. The saved parent
session retains the exact call under marker `OBS_WAIT_SPIKE_LONG_ONE_SHOT_V3`.

## Open Questions / Follow-ups

- A real 600-second stage was not held open for the full timeout. Design should avoid depending on
  an undocumented maximum and keep the one-long-wait fallback.
- Whether the client renders `notify` before completion needs a UI-level test. It is not required
  by the proposed solution.
- The spike can establish whether the current host primitives work. It cannot guarantee that their
  UI representation or session-log schema remains stable across future Codex releases.
