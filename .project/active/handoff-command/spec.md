# `/_my_handoff` Command

**Status:** Implemented — 2026-05-21

## Goal

Quick way to dump session context to a temp-dir handoff file a fresh agent can read to continue work without re-discovering everything.

## Requirements

- Save document to the OS temp directory (`${TMPDIR:-/tmp}`), never inside the workspace.
- Sections: Focus, Context (references only — no duplication of PRDs/plans/ADRs/issues/commits/diffs), Key Discoveries, Suggested Skills, Open Questions.
- Treat `$ARGUMENTS` as the next session's focus when provided.
- Redact secrets (API keys, tokens, passwords, PII, customer data) before writing.
- Keep the command body under 20 lines.

## Deliverables

- `claude-pack/commands/_my_handoff.md`
- Codex description override in `codex-overrides/config.sh` (`handoff`)

## Follow-ups

- Run `./scripts/setup-global.sh` so the symlink lands in `~/.claude/commands/`.
- Optionally rebuild Codex pack via `./scripts/build-codex-pack.sh` + `./scripts/setup-codex.sh --copy`.
