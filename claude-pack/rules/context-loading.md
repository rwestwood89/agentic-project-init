# Context Loading

## Before Starting Non-Trivial Work

1. **Read `.project/CURRENT_WORK.md`** — active work context, recent decisions, known issues
2. **Read the relevant docs** for the area you're working in (check CLAUDE.md for pointers)
3. **Check auto-memory** (already loaded) for known gotchas before making assumptions

## After Completing Work

If you discovered something that would save a future session time:
1. Suggest running `/_my_wrap_up` to persist context
2. Or at minimum, update `.project/CURRENT_WORK.md` with the current status

## Don't Re-Research What's Already Documented

Before exploring the codebase to understand how something works, check:
- Project docs (often in `docs/`) for existing documentation
- `.project/research/` for previous deep investigations
- `.project/CURRENT_WORK.md` for recent work that may already cover the area
