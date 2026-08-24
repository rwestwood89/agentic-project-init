# Design: Codex Orchestrator Observable Waiting

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-13 12:22:31 PDT
**Branch:** `anchor-on-the-point`
**Commit:** `b114400`

## Overview

Replace model-visible stage polling with completion-driven supervision while preserving the
existing blocking helper, compact result contract, stage isolation, and diagnostic logs. Add
explicit cancellation forwarding so stopping the parent does not orphan the headless Codex stage.

## Related Artifacts

- Spec: `.project/active/codex-orchestrator-observable-waiting/spec.md`
- Spike: `.project/active/codex-orchestrator-observable-waiting/spike-findings.md`
- Product lens: `.project/active/codex-orchestrator-observable-waiting/product-lens.md`
- Prior Codex design: `.project/active/codex-orchestrator-fork/design.md`
- Prior Codex helper spike: `.project/active/codex-orchestrator-fork/spike-findings.md`
- Active decision: `.project/adr/0007-pre-pr-branch-gate-after-close.md`
- Official Codex contract: <https://learn.chatgpt.com/docs/non-interactive-mode>

This item has no parent epic or product-design artifact.

## The Point

- **[NEED]** Codex orchestration must stop filling the main terminal timeline with repeated no-news
  waits and must stop invoking the parent model merely to learn that a stage remains active. The
  owner described the current result as making “following the progress of the main agent in terminal
  impossible” and the polling as “kind of a waste of tokens.”
- **[INHERITED]** This is an observation-layer correction. One isolated headless agent still owns
  each stage, the commit trail remains auditable, and orchestration still leaves `close` and the
  post-close `pre_pr` branch gate to the human unless asked (`docs/guide.md:137`;
  `.project/adr/0007-pre-pr-branch-gate-after-close.md:37-42`).

## Research Findings

- The Codex replacement skill explains how to call the helper and consume its compact result, but
  says nothing about how the parent should wait (`codex-overrides/command-skill-replacements/orchestrate/SKILL.md:36-62`).
  The parent therefore falls back to the host's ordinary yield-and-recheck behavior.
- The helper is intentionally blocking. It creates raw JSONL, stderr, and final-message paths, then
  redirects both live Codex streams to files until `codex exec` exits
  (`codex-overrides/scripts/orchestrate-stage-codex.sh:178-196`). The parser already reduces that
  evidence to `{session_id,result,raw,stderr,is_error}`
  (`codex-overrides/scripts/orchestrate-stage-codex.sh:51-109`).
- Official OpenAI documentation says `codex exec --json` emits JSONL events while running and that
  `codex exec resume <SESSION_ID>` resumes a non-interactive session. Capturing those streams is a
  supported use, not a private CLI assumption. The helper's decision to retain rather than forward
  them is local policy.
- The spike completed a 66.1-second stage in one host call with zero records, parent tool calls,
  waits, or token events between launch and terminal output. A forced outer yield completed with one
  long wait. This proves completion-driven supervision on the current host without proving an
  undocumented maximum (`spike-findings.md:138-168`).
- The spike could not prove that scheduled `notify` output appears before completion. Streaming or
  summarizing events would also put child activity back into the main transcript. Neither is needed
  to remove polling (`spike-findings.md:129-136`).
- Outer cancellation currently kills the helper but can leave its `timeout`/Codex descendant alive
  (`spike-findings.md:119-127`). A focused follow-up probe showed that sending `TERM` directly to the
  final `timeout` PID in the asynchronous current pipeline exits it with 143, reaches the fake Codex
  signal trap, and leaves no child. `$!` was also the process-group id shared by the fake child. The
  missing behavior is signal ownership in the helper, not a new process manager.
- The generated-product test already owns helper fixtures, replacement-skill assertions, and
  installer checks (`scripts/test_codex_orchestrator_pack.sh:37-130`). The generator copies the full
  replacement and Codex scripts (`scripts/build-codex-pack.sh:262-289,393-410`), and setup installs
  the skill and scripts (`scripts/setup-codex.sh:261-281`). No new distribution lane is needed.

## Core Concept

This feature is a completion protocol around the existing blocking stage call, not a background-job
system. For each `run` or `resume`, the Codex orchestrator opens one host execution cell whose
deadline is longer than the helper's own timeout. That cell starts the helper, drains any terminal
session internally, and returns to the parent model only when it has a terminal result. The client’s
ordinary running-tool state is the liveness signal. No timer creates commentary, a model turn, or a
new terminal row.

The helper keeps its current role and output contract. Its only lifecycle change is to own the
`timeout` subprocess it launches. On parent cancellation it forwards the signal to that subprocess,
waits for cleanup, and exits with the corresponding signal status. This split is right because the
host cell is the only boundary that can prevent parent inference, while the helper is the only
boundary that reliably owns the child process.

## Key Bets

- **B1.** Supported Codex hosts can keep one execution cell pending through a normal stage deadline
  without waking the parent model. *If false → repository instructions cannot deliver
  completion-driven waiting; the feature must stop and surface a host-capability conflict rather
  than return to polling.*
- **B2.** A concise launch message plus the client’s existing running-tool state gives enough
  liveness during a stage. *If false → polling can be removed, but the terminal still feels hung;
  meeting the experience goal then requires a host/UI notification capability the spike did not
  establish.*
- **B3.** Material stage interaction can remain terminal-result-driven: a stage finishes or returns
  questions, and the parent then resumes that session. *If false → meaningful mid-turn interaction
  would require a streaming protocol and this design would suppress information the orchestrator
  needs.*

## Key Decisions

- **D1. Use one host-owned execution cell per helper call.** Its outer yield is the helper timeout
  plus 30 seconds; nested terminal-session draining stays inside the cell. *Rejected: a
  detached helper-side daemon or status file. Detachment still needs parent polling to discover
  completion and adds recovery state.*
- **D2. Permit one bounded fallback wait after an unexpected outer yield.** It waits on the same cell
  for the remaining deadline and emits no no-news commentary. A second premature yield is a host
  compatibility failure: cancel safely and report it. *Rejected: repeated fixed-interval waits.
  They recreate both the transcript noise and the model-turn cost.*
- **D3. Show launch and terminal outcome only.** Do not use `notify`, tail stderr, or forward JSONL
  progress. *Rejected: time-based liveness and filtered semantic progress. The first was not observed
  live, and either can replace polling noise with event noise.*
- **D4. Make the existing helper forward cancellation to an owned `timeout` child.** Run the current
  pipeline asynchronously so `$!` captures its final `timeout` process, trap `HUP`/`INT`/`TERM`,
  forward the signal, allow five seconds for exit, then kill the timeout-owned process group if it
  survives. *Rejected: `setsid`, a recursive process-tree walker, or a Python supervisor. GNU
  `timeout` already manages the Codex child, and direct forwarding was sufficient in the probe.*
- **D5. Preserve the helper's result and log protocol.** Successful and stage-reported results keep
  the current compact JSON. Shell failure, timeout, and cancellation remain nonzero exits with
  stage-labelled stderr and retained log paths. *Rejected: a second status schema or progress file.
  Neither is needed for completion routing.*
- **D6. Extend the existing generated-product test.** Add supervision-contract guards and fake-Codex
  lifecycle cases there, then require one live host acceptance check. *Rejected: a new production
  supervisor module or parallel test suite. The current test already owns this seam.*

## Architecture

Normal flow:

```text
parent model → one host execution cell → blocking helper → timeout → codex exec
                                          ↓ logs              ↓ JSONL/stderr
parent model ← one compact terminal result ← parse after exit
```

1. The orchestrator chooses a stage exactly as it does now and emits one short launch update naming
   the stage. It passes an explicit helper timeout `T`.
2. It invokes one host execution cell with an outer deadline of `T + 30 seconds`. Inside that cell,
   `exec_command` starts the unchanged helper command. If the terminal call yields a session handle,
   `write_stdin` waits on it inside the same cell until completion.
3. The helper composes the prompt and log names as today. It runs the same prompt-to-`timeout`
   pipeline asynchronously and retains the final `timeout` PID. JSONL and stderr continue to drain
   directly to their retained files.
4. Normal exit restores signal handlers, captures the timeout child's status, applies the existing
   timeout/CLI error rules, parses the logs, and prints exactly one compact JSON object.
5. The host cell returns that object. Only then does the parent model route the result, read an
   artifact, answer questions, or resume the same session.
6. If the outer host yields first, the parent uses one long wait on that cell for the remaining
   deadline. It does not describe unchanged state. A second premature yield triggers safe
   cancellation and an explicit compatibility error.

Cancellation flow:

```text
parent/tool interrupt → helper trap → timeout PID → codex child
                              ↓ wait and labelled nonzero exit
```

The handler is race-safe: it tolerates cancellation before the child PID is set and after the child
has already exited. A bounded kill escalation is permitted only if normal signal forwarding does
not stop the owned child within the cleanup grace.

## Required Invariants

- Elapsed time without a state change never causes a parent-model turn.
- A normal stage produces one concise launch update and one tool entry that changes from running to
  terminal. It produces no repeated prompt body, wait row, or no-news commentary.
- At most one model-visible fallback wait is allowed for a prematurely yielded host cell. The
  implementation fails loudly instead of degrading to periodic polling.
- Periodic `notify` calls and live JSONL/stderr forwarding are absent from the waiting path.
- The helper's stdout is either its single compact JSON result or empty on shell-level failure; raw
  JSONL, stderr, and final-message files remain available.
- `run` and `resume` retain their current argv differences and session identity. Resume still omits
  unsupported sandbox flags (`codex-overrides/scripts/orchestrate-stage-codex.sh:150-152,184-189`).
- After timeout, cancellation, or parent interruption, the owned timeout/Codex child is gone within
  the cleanup grace or the helper reports cleanup failure.
- Every lifecycle diagnostic names the stage label or resume prefix and the retained evidence paths.
- Claude orchestration files are unchanged. Stage isolation, commit history, and the human-owned
  `close`/`pre_pr` boundary are unchanged.
- Authored changes live in `codex-overrides/`; generated and installed assets derive from those
  sources and are never hand-edited.

## Component Overview

- **`codex-overrides/command-skill-replacements/orchestrate/SKILL.md` — modify.** Owns the
  completion-driven host-call recipe, outer deadline, single fallback, concise launch behavior, and
  prohibition on periodic polling/notification.
- **`codex-overrides/scripts/orchestrate-stage-codex.sh` — modify.** Owns the timeout child PID,
  cancellation traps, signal forwarding, cleanup grace, and labelled lifecycle errors. It retains
  prompt composition, CLI argv, logging, parsing, and compact output.
- **`scripts/test_codex_orchestrator_pack.sh` — modify.** Owns static generated-skill assertions and
  fake-Codex lifecycle coverage for success, resume, event failure, helper timeout, and outer
  cancellation cleanup.
- **`dist/codex/skills/my-orchestrate/SKILL.md`, `dist/codex/scripts/orchestrate-stage-codex.sh`, and
  `dist/codex/manifest.json` — regenerate.** These are disposable generated outputs.
- **`scripts/build-codex-pack.sh` and `scripts/setup-codex.sh` — validate only.** Their existing
  replacement, script-copy, and installation lanes already carry the changed files.
- **Spike probes — evidence only.** `.project/active/codex-orchestrator-observable-waiting/probes/`
  remains reproducible design evidence; it is not installed as product code.

## Non-Goals

- Reduce the child stage's own reasoning, exploration, or tokens.
- Add a daemon, job registry, status file, notification service, or general background-task API.
- Stream or summarize every child event in the main terminal.
- Change stage selection, review policy, stage prompts, artifact protocols, or result schemas.
- Change Claude orchestration or make it share the new Codex supervision recipe.
- Change terminal rendering outside the rows generated by this orchestration workflow.
- Run `close` or post-close `pre_pr` without an explicit owner request.

## Implementation Notes

The orchestrator skill should show this host recipe directly. Internal waits may repeat because they
do not return control to the parent model:

```text
functions.exec(yield = T + 30s):
    result = tools.exec_command(helper)
    while result has a terminal session id:
        result = tools.write_stdin(session, yield = min(remaining, 300s))
    return result
if the outer cell yields: functions.wait(cell, remaining deadline) once
```

The helper must run its current `printf | timeout codex` pipeline asynchronously and capture `$!`,
which is the final `timeout` command (`codex-overrides/scripts/orchestrate-stage-codex.sh:191`). Clear
the tracked PID immediately after `wait` so a later signal cannot target a reused PID. Do not add an
`EXIT` trap or `set -e`; expected nonzero exits must still be captured and classified. If normal
forwarding misses the cleanup deadline, escalation targets the timeout-owned process group, not an
unrelated parent group.

Install-time behavior matters: the skill is copied to `$HOME/.agents/skills`, while scripts use the
existing managed install path. Rebuild first, run the pack test against `dist/codex`, then refresh
the installed pack before the live acceptance check.

## Potential Risks

- **Host yield behavior changes.** Mitigation: encode the contract explicitly, keep one bounded
  fallback, and make live session evidence a release check. Do not silently reintroduce polling.
- **The untested 600-second boundary is lower than expected.** Mitigation: derive the outer deadline
  from `T`, verify a stage longer than the old polling window, and treat a second premature yield as
  a compatibility failure rather than an invitation to loop.
- **Cancellation races with startup or normal exit.** Mitigation: install traps before launching,
  guard PID use, restore handlers before parsing, and test both early and active-child cancellation.
- **Signal forwarding stops `timeout` but not a future Codex descendant.** Mitigation: the fake-child
  test asserts descendant cleanup. If a future CLI changes that behavior, revisit process groups
  then; do not pre-install that complexity now.
- **Prompt guidance is followed inconsistently.** Mitigation: static generated-skill checks plus a
  live parent-session acceptance test. This behavior cannot be proven by shell unit tests alone.

## Integration Strategy

Implement producer-first. Change the authored Codex replacement skill and helper, extend the
existing generated-product test, rebuild `dist/codex`, and run tests against generated output. Then
refresh the installed Codex pack and run the host-level acceptance check. `claude-pack/`, the
generator logic, installer logic, and public pipeline docs require no behavioral edit.

This complements the prior Codex fork rather than replacing its boundaries. The replacement skill
still owns orchestration judgment; the shell helper still owns one stage's mechanics; the generated
pack still owns distribution. The only new relationship is explicit: the skill owns *when the
parent may wake*, and the helper owns *what happens to the child when waiting is cancelled*.

## Validation Approach

Automated validation:

- Expand `scripts/test_codex_orchestrator_pack.sh` with a PATH-injected fake `codex` that covers
  `run`, `resume`, `turn.failed`, timeout, and external cancellation. Assert exact result/session
  shapes, retained logs, expected exit codes, and that no fake child remains after cleanup grace.
- Assert the generated orchestrator skill requires one completion-driven host cell, forbids
  periodic polling and `notify`, allows only one fallback wait, and retains the existing helper and
  stage-result protocol.
- Run `bash -n` on the authored and generated helper, `bash scripts/build-codex-pack.sh`,
  `bash scripts/test_codex_orchestrator_pack.sh`, `bash scripts/test_pipeline_sync.sh`, and
  `bash scripts/setup-codex.sh --dry-run`.
- Verify generated output matches authored sources through the existing build and install checks;
  do not edit `dist/codex` directly.

Host-level acceptance after installing the rebuilt pack:

1. Run a controllable fake stage longer than three former polling intervals. The terminal shows one
   concise launch, one running tool, and one terminal result; the heredoc/prompt is not repeated.
2. Analyze the saved parent session between launch and result. Require zero intermediate records,
   parent tool calls, waits, and token events for the normal path.
3. Force the outer cell to yield once. Require exactly one long fallback wait and the same final
   stage/session identity, with no intermediate commentary.
4. Cancel an active stage. Require prompt terminal cancellation, stage-labelled evidence paths, and
   no live fake helper, timeout, or Codex child after cleanup grace.
5. Exercise a question/result followed by `resume`. Require the original Codex thread id, compact
   result, and retained logs.
6. Run one low-risk live document stage in a disposable worktree. Confirm the installed skill, not
   the source copy, follows the same terminal shape.

## Next-Stage Handoff

Treat as fixed:

- One host execution cell is the normal supervision boundary; no daemon or second inventory exists.
- No time-based parent turns, periodic `notify`, or child-event streaming.
- One bounded fallback wait is allowed; repeated polling is a compatibility failure.
- The helper forwards cancellation through its owned `timeout` child and preserves its output/log
  contract.
- Only the three authored files named in Component Overview require source edits. Generated assets
  are rebuilt; build/install scripts are validation-only.

Keep these risks visible in planning:

- Write the cancellation/fake-child test before restructuring the helper launch.
- Write generated-skill contract assertions before changing its tool recipe.
- Run the host-level acceptance after installation; shell tests cannot certify parent wakeups or
  terminal rendering.
- If current Codex cannot hold the execution cell for the configured deadline, stop and surface the
  premise conflict. Do not redefine success as slower polling.

---

Next Step: After approval → `$my-plan`
