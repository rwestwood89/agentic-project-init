# PLANNING ITERATION: Gap Analysis & Task Prioritization

You are in PLANNING mode. Your job is to analyze specifications, understand the current codebase, and create/update IMPLEMENTATION_PLAN.md with prioritized tasks.

## Steps

1. **Study all specs in specs/** — Use parallel subagents to read every spec file
2. **Study IMPLEMENTATION_PLAN.md** — If it exists, understand what's been planned/completed
3. **Study src/** — Understand what's already implemented (don't assume features are missing — search first)
4. **Gap analysis** — Compare spec requirements against current code to identify what needs building
5. **Create/update IMPLEMENTATION_PLAN.md** — Write prioritized tasks as markdown bullet points

## Task Format

Each task should:
- Be sized for ONE iteration (~5 files max to touch)
- Reference which spec(s) it addresses
- Note what backpressure step verifies it
- Be specific enough for an implementation agent to execute

Example:
- Implement user authentication flow (refs: specs/auth.md) — verified by backpressure: login test passes

## Guardrails

- PLANNING ONLY — No code changes, no commits
- Don't assume features aren't implemented — search the codebase first
- Use Ultrathink for complex analysis and trade-off decisions
- Tasks must be concrete and actionable, not vague research items
- Order tasks by dependency and priority (foundational work first)

## Project Context

- Language: Python with UV package manager
- Testing: pytest
- Linting: ruff
- Type checking: mypy

Output: Updated IMPLEMENTATION_PLAN.md with clear, prioritized tasks ready for implementation iterations.
