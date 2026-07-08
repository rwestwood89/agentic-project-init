# Spike Findings: Codex Exec Helper Contract

**Status:** Complete
**Date:** 2026-07-07
**Sandbox repo:** `/tmp/codex-orchestrator-spike/repo`
**Logs:** `/tmp/codex-orchestrator-spike/logs/`
**Codex CLI:** `/home/reid/.codex/packages/standalone/releases/0.143.0-x86_64-unknown-linux-musl/bin/codex`

---

## Summary

The helper contract is viable, with two important corrections to the design:

1. `thread.started.thread_id` is the resume id. `codex exec resume <thread_id>` resumed the previous stage and preserved context.
2. Fresh `codex exec` and `codex exec resume` need separate argv builders. Resume does not accept `--sandbox`; passing it fails before a model call.

The largest surprise is permissions: in this environment, `codex exec --sandbox read-only` did not reliably block writes. A shell `tee` command wrote a file in the temp repo even under read-only. Codex's file-change tool hit the known bwrap failure, but shell command execution still wrote successfully.

## Probes

### 1. `$my-pipeline` Read-Only Skill Probe

Command shape:

```bash
codex exec --json   --output-last-message /tmp/codex-orchestrator-spike/logs/01-pipeline.last   --sandbox read-only   --cd /tmp/codex-orchestrator-spike/repo   "Use \$my-pipeline ..."
```

Result: success.

Findings:

- `$my-pipeline` loaded from `/home/reid/.agents/skills/my-pipeline/SKILL.md`.
- JSONL started with `{"type":"thread.started","thread_id":"019f3ff1-e169-7750-a059-bb339f9f6aca"}`.
- `--output-last-message` captured the final message cleanly.
- Stderr contained `Reading additional input from stdin...`; helper should keep stderr separate and treat this line as nonfatal.
- The final message included the expected pipeline shape.

### 2. Read-Only Write Probe

Command shape:

```bash
codex exec --json   --output-last-message /tmp/codex-orchestrator-spike/logs/02-readonly-write.last   --sandbox read-only   --cd /tmp/codex-orchestrator-spike/repo   "Create a file named codex-readonly-probe.txt ..."
```

Result: read-only was not a reliable write barrier in this environment.

Findings:

- Codex first used a `file_change` item to add `codex-readonly-probe.txt`.
- File-change edits then hit the existing sandbox helper failure: `bwrap: loopback: Failed RTM_NEWADDR`.
- Codex then ran `printf 'readonly should block.' | tee codex-readonly-probe.txt`, which succeeded.
- The file existed afterward as an untracked file.

Implication: the orchestrator helper should still pass least-privilege sandbox flags, but the implementation must not rely on `read-only` as a hard safety boundary in this local environment. Use temp repos/worktrees for live probes.

### 3. `$my-spec` Workspace-Write Artifact Probe

Command shape:

```bash
codex exec --json   --output-last-message /tmp/codex-orchestrator-spike/logs/03-spec.last   --sandbox workspace-write   --cd /tmp/codex-orchestrator-spike/repo   "Use \$my-spec ... end your final message with ARTIFACT: <path>."
```

Result: success.

Findings:

- `$my-spec` loaded and followed its command-derived skill instructions.
- Codex created `.project/active/codex-helper-dry-run/spec.md` and updated `.project/CURRENT_WORK.md` in the temp repo.
- Final message capture worked and ended with `ARTIFACT: .project/active/codex-helper-dry-run/spec.md`.
- JSONL started with `thread_id` `019f3ff3-45a1-7a72-8d6e-0724c31c8ff8`.
- The same bwrap file-edit issue appeared, and Codex worked around it with a shell write.
- Runtime was around 90 seconds, so helper defaults should include a generous timeout for document stages.

### 4. Resume Probe

First attempt:

```bash
codex exec resume 019f3ff3-45a1-7a72-8d6e-0724c31c8ff8   --json --output-last-message ... --sandbox read-only --cd ... "..."
```

Result: failed before model call.

Error:

```text
error: unexpected argument '--sandbox' found
Usage: codex exec resume --json --output-last-message <FILE> <SESSION_ID> [PROMPT]
```

Corrected command:

```bash
codex exec resume --json   --output-last-message /tmp/codex-orchestrator-spike/logs/04-resume.last   019f3ff3-45a1-7a72-8d6e-0724c31c8ff8   "Resume the previous stage ..."
```

Result: success.

Findings:

- Resume JSONL started with the same `thread_id`: `019f3ff3-45a1-7a72-8d6e-0724c31c8ff8`.
- The resumed stage could see previous context and identify the prior artifact path.
- `--output-last-message` worked on resume.
- Stderr was empty on the successful resume.

## Design Updates Needed

- Keep the design decision to use `thread.started.thread_id` as `session_id`.
- Update the helper design so `run` and `resume` have separate supported option sets.
- Do not include `--sandbox` in the resume argv unless a future Codex version supports it. If sandbox behavior is needed on resume, investigate config-based alternatives separately.
- Treat stderr as diagnostic output, not structured output. `Reading additional input from stdin...` is nonfatal.
- Treat read-only sandbox as advisory in this local environment. The safe validation pattern is a disposable git worktree or temp repo.
- Keep the dry-run requirement. It would have caught the invalid resume argv shape without a live model call.

## Verdict

GO for `$my-plan`, with the helper-contract corrections above.

The Codex fork is feasible. The next stage should plan a small implementation that starts with the helper dry-run path and generated-product validation, then adds live helper execution after the argv shape is covered by tests.
