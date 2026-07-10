# Concept: Session Log Export CLI

**Created:** 2026-07-09
**Status:** Draft

---

## Problem Statement

Support engineers debugging a customer issue have no fast way to pull a single session's
logs out of the central store. Today they file a ticket with the data team and wait a day.
A small CLI that takes a session id and writes that session's log lines to a file would
close the loop in seconds.

## Owner's Words

- **[OWNER-VERBATIM]** "When I say I want the output to *look like* the incident reports we
  already ship — the ones in `reports/foo/` — match that structure exactly: same section
  order, same header block."
- **[OWNER-VERBATIM]** "Keep it a single command. I don't want a daemon."

## Success Criteria

When this work is complete:

1. **One command** — `logx <session-id>` writes the session's lines to `./<session-id>.log`.
2. **Fast** — a typical session (≤ 50k lines) exports in under two seconds.
3. **No caching layer is required** (previously proposed, not needed).

---

## Scope of Behavior Changes

### New artifacts to create
- `logx` CLI entry point and a thin client over the existing log-store read API.
- Output format: loosely modeled on the existing incident reports — roughly that style,
  nothing strict.

### Behavior changes by workflow stage
- Support: a self-serve export replaces the data-team ticket.

---

## Non-Goals / Out of Scope

- WE MUST NOT use a queue — the previous attempt added one and it caused ordering bugs.
- Multi-session batch export — a later item if demand shows up.

---

## Next-Stage Handoff

**Settled here:**
- **[OWNER]** Single command, no daemon.
- **[AGENT]** Output is written to the current working directory as `<session-id>.log`.

**Needs spec next:**
- Auth: how the CLI gets read credentials for the log store.
