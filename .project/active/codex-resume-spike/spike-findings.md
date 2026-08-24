# Spike: Codex Spawned-Agent Resume

**Date:** 2026-08-20
**Branch:** `anchor-on-the-point`
**Commit:** `e857859`
**Upstream:** `.project/backlog/epic_mental_alignment_skill.md` Item 1

## Summary of Findings

**Confirmed, with one separate measurement gap.** Codex can continue a spawned agent after its first turn has completed. Calling the follow-up-task mechanism on `/root/codex_resume_probe` started a second turn under the same canonical agent identity, and that turn recovered a nonce retained only in the agent's phase-1 conversation context. `verify_probe.sh` confirmed the recovered nonce matched the digest written during phase 1.

Item 5 can therefore implement the Codex resumed-render path by retaining the spawned synthesis agent's identity and sending it the render instructions with a follow-up task. The fallback to a fresh render agent is still needed when the live agent is unavailable.

The current collaboration surface did **not** report per-agent token usage. Spawn, completion, follow-up, wait, and status results exposed identity, lifecycle state, and final text, but no token count. The design premise that the completion notification supplies the comparison's token measure is not supported by this probe. Item 5 must either find a separate supported measurement source or report that token comparison is unavailable on Codex; it should not invent or estimate the value.

## Question / Goal

Assumption under test: Codex can send a follow-up task to a spawned agent after its first turn finishes, and that agent continues with the context from its first turn.

The assumption is confirmed if one spawned agent completes two distinct turns under the same agent identity and reveals on the second turn a random nonce that existed only in its first-turn context. It is disproved if the completed agent cannot be addressed again, the follow-up creates a new agent identity, or the second turn cannot recover the nonce.

This tests the in-session mechanism needed by the mental-alignment render switch. It does not test headless Codex session resume or Claude's `SendMessage` mechanism.

## Log

### 1. Probe setup

Created this living findings document and `verify_probe.sh` before spawning the probe agent. The probe protocol is:

1. Spawn one agent for phase 1.
2. The agent generates a random nonce, retains the nonce only in conversation context, and writes its SHA-256 digest to `probe-evidence.txt`.
3. After phase 1 finishes, send a follow-up task to that same agent.
4. The agent appends the remembered nonce and a phase-2 marker to `probe-evidence.txt`.
5. Run `./verify_probe.sh` to confirm the nonce matches the phase-1 digest and both phases ran.

The spawn result, follow-up result, observations, and verification command are appended below as they occur.

### 2. Initial agent turn

Spawned one fresh Codex agent with canonical identity `/root/codex_resume_probe`. The agent was instructed to keep a fresh nonce only in its conversation context and write only the digest.

Observed after its first turn completed:

```text
phase 1 complete
```

The collaboration status reported `/root/codex_resume_probe` as `completed`. Its evidence file contained:

```text
phase_1_sha256=28bba53a780f0834967aba79be320c273b1d168d563b4776e92931fdd3734762
phase_1_marker=initial_turn_complete
```

The plaintext nonce was absent from both the file and the agent's response.

The exact phase-1 task was:

```text
You are the sole probe agent for phase 1 of a Codex continuation experiment. You own only `.project/active/codex-resume-spike/probe-evidence.txt`. You are not alone in the codebase; do not revert or modify any other file, and accommodate other edits.

Phase 1 instructions:
1. Invent a fresh high-entropy hexadecimal nonce (at least 128 bits) and retain the plaintext nonce only in your conversation context. Do not write or disclose the plaintext nonce yet.
2. Compute its SHA-256 digest.
3. Use apply_patch to create `.project/active/codex-resume-spike/probe-evidence.txt` with exactly these fields:
   phase_1_sha256=<digest>
   phase_1_marker=initial_turn_complete
4. In your final response say only `phase 1 complete`; do not reveal the nonce.

This is deliberately a two-turn task. Do not perform phase 2 until you receive a follow-up task.
```

### 3. Follow-up turn

Sent this follow-up task to the already-completed `/root/codex_resume_probe`:

```text
Phase 2: continue the experiment using your phase-1 context. Append exactly these fields to your owned `.project/active/codex-resume-spike/probe-evidence.txt` using apply_patch:
phase_2_nonce=<the plaintext nonce you invented in phase 1>
phase_2_marker=followup_received
Do not invent a replacement nonce and do not alter the phase-1 fields. Then report that phase 2 is complete.
```

The follow-up was accepted. The same canonical agent identity completed a second turn and responded:

```text
phase 2 complete
```

Its status then reported `/root/codex_resume_probe` as completed with the phase-2 response. The evidence file contained both phase markers and the revealed nonce.

### 4. Verification

Ran:

```bash
.project/active/codex-resume-spike/verify_probe.sh
```

Observed:

```text
PASS: follow-up turn retained the phase-1 nonce
```

This proves context continuation for a completed agent in the current live Codex collaboration tree. It does not establish a retention duration or behavior after the agent is removed, the root conversation ends, or context compaction occurs.

### 5. Token reporting observation

Inspected the results returned by spawn, wait, follow-up, and agent-status operations during both turns. They exposed the canonical identity, completion state, and final response, but no per-agent input, output, or total token count. No reproducible token figure was available from this probe.

## Reproduction

From the repository root:

1. Remove or rename the prior `probe-evidence.txt` if repeating the experiment.
2. Spawn one Codex agent with the phase-1 instructions recorded in the Log.
3. Wait for that agent to finish its first turn.
4. Send the phase-2 instructions recorded in the Log to the same returned agent ID using the Codex follow-up-task mechanism.
5. Wait for the second turn to finish.
6. Run:

   ```bash
   .project/active/codex-resume-spike/verify_probe.sh
   ```

Expected output if context continuation works: `PASS: follow-up turn retained the phase-1 nonce`.

## Open Questions / Follow-ups

- Whether another supported Codex surface exposes per-agent token usage in a stable, machine-readable form.
- How long an idle completed agent remains resumable, and whether compaction affects that lifetime.
