# Wrap Up

**Purpose:** End-of-session command to persist context for future sessions. Updates CURRENT_WORK.md, MEMORY.md, and relevant docs so the next Claude session doesn't re-research what you just figured out.

## Usage

```
/_my_wrap_up                   # review session and update all context files
/_my_wrap_up --quick           # just update CURRENT_WORK.md status
```

## Why This Exists

New Claude sessions only auto-load a few files (CLAUDE.md, `.claude/rules/`, auto-memory). Everything else requires discovery. If session learnings aren't distilled into these auto-loaded files, the next session will re-research the same things.

This command closes the loop: work happens → wrap-up persists the knowledge → next session boots with it.

## Instructions

### Step 1. Review What Changed

1. **Review the conversation** to identify what was worked on, decisions made, and problems solved this session. The conversation is the source of truth for what *this* session did.
2. **Cross-check with git** — run `git diff --stat` and `git log --oneline -5` to validate. If the git log contains commits that don't match your conversation (e.g., from another concurrent session), ignore them — only summarize your own work.
3. Read `.project/CURRENT_WORK.md` to understand the current state
4. Briefly summarize to the user: "Here's what happened this session: [summary]"

### Step 2. Update CURRENT_WORK.md

Update `.project/CURRENT_WORK.md` to reflect the session's work:

- **Move completed items** from "Active Work" to "Recently Completed" with date and status
- **Update active items** with current status, blockers, next steps
- **Add new items** if work was started but not finished
- **Update "Up Next"** if priorities shifted
- Keep entries concise — future Claude sessions will read this to get oriented

### Step 3. Update Auto-Memory (MEMORY.md)

Check whether this session produced knowledge that would save a future session time:

**Update auto-memory if you discovered:**
- A gotcha or pitfall (API quirk, data format issue, edge case)
- A convention or pattern that isn't documented
- A decision that changes how things work
- A bug fix whose root cause wasn't obvious
- A key command or workflow that's easy to forget

**Auto-memory location:** `~/.claude/projects/*/memory/MEMORY.md` (project-specific) or create a topic file in the same directory for detailed notes.

**Rules:**
- Keep MEMORY.md under 200 lines (it's auto-loaded every session)
- Distill, don't dump — write what you'd want to know, not what you did
- Update "Recent Decisions" section with date and one-line summary
- Remove stale entries that are no longer relevant

### Step 4. Update Docs (if applicable)

If the session involved changes that affect documented behavior:

- **Architecture changes** → update `docs/architecture.md` or equivalent
- **New commands/features** → update `docs/commands.md` or equivalent
- **Operations changes** → update `docs/operations.md` or equivalent
- **Bug fixes with non-obvious causes** → add to troubleshooting docs

Only update docs that already exist. Don't create new docs unless the user asks.

### Step 5. Report

Summarize what was updated:

```
Wrap-up complete:
- CURRENT_WORK.md: [what changed]
- MEMORY.md: [what was added/updated, or "no changes needed"]
- Docs: [which files updated, or "none needed"]
```

If `--quick` was passed, only do Step 2 and report.

---

**When to use this:**
- End of a work session before closing Claude
- After completing a significant piece of work
- After discovering something that burned time (so it doesn't burn time again)
- When the user says "wrap up", "update docs", "save context", or similar

**Related Commands:**
- `/_my_capture` — save conversation transcript for later analysis
- `/_my_memorize` — create structured memory from a transcript

$ARGUMENTS
