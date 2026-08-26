# Spike: Codex context-inheriting spawn

**Status:** Complete — confirmed on the live collaboration surface
**Owner:** Reid W
**Date:** 2026-08-20
**Branch:** `anchor-on-the-point`
**Commit:** `aeb969d`
**Triggered by:** `spec.md`, success criterion 4

## Summary of Findings

**Yes, this Codex collaboration surface has a context-inheriting spawn.** `spawn_agent` exposes
`fork_turns`; its own declaration says `"all"` provides “all surrounding context” and `"none"`
provides none. In the controlled probe, a nested worker with `fork_turns: "all"` recovered a
256-bit nonce from its parent's completed conversation turn. The digest check passed. The same
parent then spawned a negative control with `fork_turns: "none"`; that worker returned
`CANNOT_RECOVER`.

The boundary matters. Two workers spawned by this root while the root's turn was still running
could not recover a nonce from either a shell-tool result or a root assistant commentary message.
This probe therefore establishes inheritance of **completed conversation turns**, not arbitrary
in-progress parent scratch state. That is enough for the carried-policy requirement when the policy
arrives in the user's request or earlier conversation. Anything the coordinator derives during its
current turn must still be put in the worker task.

`codex exec resume` is different. Its help calls it “Resume a previous session.” A completed
throwaway session resumed under the same thread ID and recovered a marker from the earlier turn.
Against this root's actual thread ID while the root was running, it failed with `already has an
active writer`. It is a continuation of one session after the first writer exits, not a concurrent
second worker.

For success criterion 4, use live collaboration `spawn_agent` with `fork_turns: "all"`, retain the
returned agent identity, and use `followup_task` to resume that spawned agent for rendering. Do not
use `codex exec resume` as the spawn mechanism.

## Question / Goal

Does Codex expose a supported way to spawn a second agent that inherits the spawning agent's
conversation, equivalent in the relevant respect to Claude's `subagent_type: "fork"`?

The primary assumption is confirmed if a worker spawned through this conversation's live
collaboration surface can report a high-entropy nonce that appeared only in the parent's
conversation: never in a project file and never in the worker's task prompt. The reported value
must match the SHA-256 digest recorded before spawn.

The upstream requirement is success criterion 4 in `spec.md`: “spawns a context-inheriting agent
under carried policy.”

## Log

### 2026-08-20 — establish the two surfaces

Installed CLI:

```text
codex-cli 0.148.0
```

The live collaboration surface and `codex exec resume` are tested separately below. A result from
one is not treated as a runtime rule for the other.

Official OpenAI documentation search did not surface a page defining this host's collaboration
tool or the CLI resume concurrency rule. The authorities used below are the live tool declaration,
the installed CLI's own help, and controlled runtime output.

Raw CLI help is in `fork-spike/evidence/`. The live collaboration declaration is preserved at
`fork-spike/evidence/collaboration-surface.txt`.

### 2026-08-20 — enumerate the live collaboration spawn

The exposed parameter schema is:

```text
spawn_agent({
  agent_type?: string,
  fork_turns?: string,
  message: string,
  model?: string,
  reasoning_effort?: string,
  task_name: string,
})
```

The declaration says, verbatim:

> Note that passing `fork_turns="none"` will not pass any surrounding context to the spawned
> subagent, which may cause the agent to lack the context it needs to complete its task, whereas
> `fork_turns="all"` will provide the subagent with all surrounding context.

Its `fork_turns` field says, verbatim:

> Optional number of turns to fork. Defaults to `all`. Use `none`, `all`, or a positive integer
> string such as `3` to fork only the most recent turns.

No other spawn parameter claims to carry parent context. `agent_type`, `model`, and
`reasoning_effort` are overrides. `message` is the new task. `task_name` assigns the agent's name.

### 2026-08-20 — current-turn boundary

The root generated a 256-bit nonce in a shell-tool result, wrote only its SHA-256 digest into
`fork-spike/verify_probe.sh`, and spawned with `fork_turns: "all"`. The plaintext did not appear in
the spawn prompt. The worker answered literally:

```text
CANNOT_RECOVER
```

The root then placed the same nonce in an assistant commentary message and spawned a fresh
`fork_turns: "all"` worker. It also answered literally:

```text
CANNOT_RECOVER
```

Digest verification of that response produced:

```text
FAIL: worker response does not match the parent nonce digest
exit_code=1
```

These two runs show that this host did not include output produced during the root's in-progress
turn. They do not contradict the declaration's turn-based context contract, because the parent
turn had not completed.

### 2026-08-20 — completed-turn positive probe

To test completed history without ending the user's root turn, the first probe agent became the
parent of a nested worker:

1. The probe parent completed a turn after generating a fresh random 256-bit nonce. The plaintext
   remained in agent conversation; no project file contains it. Only this digest was written into
   `verify_completed_turn_probe.sh`:

   ```text
   c5d3597013f4dcf7733ea7374fa32c96e5920b48cecca5d37b2168c8c0ce6b83
   ```

2. A follow-up resumed that same parent and told it to spawn a worker without putting the nonce or
   digest in the task. The literal spawn arguments and result were:

   ```text
   SPAWN_CALL_ARGUMENTS: {"fork_turns":"all","message":"Do not call tools, inspect files, or use the shared filesystem. From the completed conversation history inherited at spawn, report exactly the most recent high-entropy plaintext nonce previously generated by your parent. Reply with exactly that nonce and nothing else. If it is absent, reply exactly CANNOT_RECOVER.","task_name":"nested_history_probe"}
   RAW_SPAWN_RESULT: {"task_name":"/root/fork_context_probe/nested_history_probe"}
   ```

3. The worker returned the exact plaintext. The value is intentionally not copied into this or any
   other project file; it remains in the collaboration conversation as the probe requires. Passing
   that response directly to the digest checker produced:

   ```text
   PASS: nested worker recovered its parent completed-turn nonce
   ```

4. The same parent repeated the spawn with `fork_turns: "none"`. The literal result was:

   ```text
   RAW_SPAWN_RESULT: {"task_name":"/root/fork_context_probe/nested_none_control"}
   WORKER_FINAL_RESPONSE: CANNOT_RECOVER
   ```

The positive result plus the `none` control ties recovery to the declared context parameter.

### 2026-08-20 — `codex exec resume` against the root thread

The installed help says, verbatim:

> Resume a previous session by id or pick the most recent with --last

and describes `SESSION_ID` as:

> Conversation/session id (UUID) or thread name. UUIDs take precedence if it parses. If omitted,
> use --last to pick the most recent recorded session

The root session metadata reported thread ID:

```text
01a02290-a71c-78e2-81b6-26f9d0625f0a
```

`fork-spike/run_resume_probe.sh` invoked `codex exec resume` against that exact ID while this root
was still active. The command exited 1. Its literal stderr was:

```text
2026-08-21T04:29:46.168161Z ERROR codex_core::session::session: failed to initialize thread persistence: thread-store conflict: thread 01a02290-a71c-78e2-81b6-26f9d0625f0a already has an active writer
2026-08-21T04:29:46.168440Z ERROR codex_core::session: Failed to create session: thread-store conflict: thread 01a02290-a71c-78e2-81b6-26f9d0625f0a already has an active writer
Error: thread/resume: thread/resume failed: thread 01a02290-a71c-78e2-81b6-26f9d0625f0a already has an active writer (code -32600)
```

Raw output: `fork-spike/evidence/resume.{stderr,jsonl,exit-code.txt}`. The JSONL is empty because the
thread failed before a resumed turn began.

### 2026-08-20 — completed-session resume control

The concurrency failure does not answer whether resume restores history after the original writer
exits. `run_completed_resume_fixture.sh` created a disposable session, let it finish, then resumed
its returned ID. Literal runner output:

```text
session_id=01a02297-07ba-7772-b8f5-ba769ed30a11
parent_final=PARENT_COMPLETE
resume_final=RESUME-FIXTURE-4f7c92b16a8de305
```

Both raw JSONL streams begin with the same thread ID:

```json
{"type":"thread.started","thread_id":"01a02297-07ba-7772-b8f5-ba769ed30a11"}
```

The resumed turn recovered the marker from the prior conversation. This confirms history
continuation for a completed session on CLI 0.148.0. Combined with the active-writer rejection, it
does not provide a second concurrent worker.

## Reproduction

From the repository root, capture the installed surface and repeat the completed-session control:

```bash
.project/active/directory-skill-build-pattern/fork-spike/capture_cli_surface.sh
.project/active/directory-skill-build-pattern/fork-spike/run_completed_resume_fixture.sh
```

The second command needs permission to write Codex's session store. Expected final lines are
`parent_final=PARENT_COMPLETE` and
`resume_final=RESUME-FIXTURE-4f7c92b16a8de305`. Raw JSONL, stderr, and final messages land under
`fork-spike/evidence/completed-resume-fixture/`.

To repeat the live collaboration probe:

1. In a parent agent, generate a random nonce and complete the turn with the nonce retained only in
   conversation. Record only its SHA-256 digest in a copy of `verify_completed_turn_probe.sh`.
2. Resume that parent with `followup_task` and have it call `spawn_agent` using the exact task in the
   positive log, `fork_turns: "all"`, and no nonce or digest in `message`.
3. Pass the returned value directly over stdin:

   ```bash
   printf '%s\n' '<worker response>' | \
     .project/active/directory-skill-build-pattern/fork-spike/verify_completed_turn_probe.sh
   ```

4. Repeat with `fork_turns: "none"`; expect `CANNOT_RECOVER`.

To reproduce the active-writer rejection, replace `session_id` in `run_resume_probe.sh` with the
currently active root thread ID, then invoke the script from another process before the root turn
ends. The saved ID from this run is historical; once its writer exits, it no longer reproduces the
concurrency condition.

## Open Questions / Follow-ups

- The probe did not map positive integer `fork_turns` values or retention across compaction. Success
  criterion 4 only needs `"all"`.
- The installed CLI also advertises `codex exec fork` as “Fork a previous session by id into a new
  session.” That separate CLI surface was captured in
  `fork-spike/evidence/codex-exec-fork-help.txt` but not exercised. The live collaboration spawn
  already satisfies the upstream requirement, so this spike does not infer behavior from that help
  line.
