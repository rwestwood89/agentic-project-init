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
