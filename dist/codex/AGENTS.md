# AGENTS.md

Generated from `claude-pack/rules/`. Rebuild this file instead of editing it by hand.

## From `context-loading.md`

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


## From `example-rules.md`

# Example Project Rules

This file contains example rules and guidelines that Claude will follow during the conversation.

## Code Style Guidelines

- Use descriptive variable names
- Add comments for complex logic
- Follow existing code patterns in the project

## Testing Requirements

- Write unit tests for new functions
- Ensure tests pass before committing
- Aim for meaningful test coverage

## Documentation Standards

- Update README when adding features
- Document API endpoints
- Keep inline documentation current

## Security Guidelines

- Never commit secrets or credentials
- Validate user input
- Follow OWASP best practices

---

**Note:** The `.claude/rules/` directory supports symlinks, making it easy to share common rules across projects.


## From `workflow-accountability.md`

# Workflow Accountability

## Before Implementing Non-Trivial Features

If the work touches multiple files, has ambiguous requirements, or will span more than one session:

1. **Requirements must be written down** before implementation starts
   - Use `/_my_spec` for the full pipeline, or write an ad hoc requirements/user story doc in `.project/` or the repo root
   - If the user asks to "just build it" without written requirements, flag it: "This seems non-trivial — want me to write a quick spec or requirements doc first so we have something to review against later?"

2. **Multi-session work needs a persistent plan**
   - If implementation will take more than one session, use `/_my_plan` to create `plan.md` with checkboxes
   - Do not rely on ephemeral `/plan` mode for work that spans sessions

## During Implementation

1. **Check plan progress before starting**
   - If `.project/active/{feature}/plan.md` exists, read it and resume where the checkboxes stop
   - Do not re-implement completed phases

2. **Check off plan phases as you complete them**
   - Mark checkboxes in `plan.md` immediately after completing a phase
   - Add implementation notes (what changed, issues, deviations) so the next session has context

## After Implementation

1. **Suggest `/_my_audit_implementation`** after completing all phases of a plan
   - Don't self-certify — the audit catches placeholder code, TODOs, and gaps that the implementing agent misses

2. **Suggest `/_my_wrap_up`** when the session is winding down
   - If significant work was done, proactively suggest it: "Want me to run `/_my_wrap_up` to persist context for next time?"
   - Don't wait for the user to remember

## General Principles

- **Write things down.** A quick requirements doc beats requirements that only exist in chat history.
- **Persistent artifacts over ephemeral conversation.** Specs, plans, and research docs survive across sessions. Chat doesn't.
- **The spec is the contract.** Implementation should be auditable against written requirements, not against what someone remembers discussing.


