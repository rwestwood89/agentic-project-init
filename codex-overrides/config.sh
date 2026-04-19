#!/bin/bash

# Shared exclusions for the Codex compatibility layer.
COMMAND_SKILL_PREFIX="my-"

EXCLUDED_COMMANDS=(
  "_my_capture"
  "_my_memorize"
  "_my_recall"
  "_my_review_compact"
)

EXCLUDED_AGENTS=(
  "recall"
)

EXCLUDED_HOOKS=(
  "capture.sh"
  "precompact-capture.sh"
  "query-transcript.py"
  "parse-transcript.py"
)

declare -A COMMAND_SKILL_DESCRIPTIONS=(
  ["audit-implementation"]="Audit completed work against an implementation plan. Use when you need a post-implementation gap check against plan phases."
  ["code-quality"]="Run code quality checks and fix issues systematically. Use when you want tests, lint, or validation work driven to closure."
  ["code-review"]="Review implementation against requirements and design. Use when you want a bug-focused audit or requirements check."
  ["concept"]="Develop a feature concept with scope and success criteria. Use when an idea needs definition before specification."
  ["design"]="Create a technical design for an approved feature spec. Use when a feature needs architecture, interfaces, and tradeoff analysis."
  ["example-command"]="Example Codex prompt generated from the example Claude command."
  ["git-manage"]="Handle git workflow tasks such as worktrees, merges, and conflict resolution. Use when you need structured git help."
  ["implement"]="Execute an approved implementation plan with validation. Use when plan work should be carried through in the codebase."
  ["plan"]="Create a phased implementation plan from a spec and design. Use when work needs sequencing, validation, and file-level execution steps."
  ["project-find"]="Find relevant project management context in .project/. Use when you need to locate specs, plans, designs, or recent research quickly."
  ["project-manage"]="Review project status, identify gaps, and suggest next steps. Use when coordinating work across backlog, active items, and completed artifacts."
  ["quick-edit"]="Handle a small focused change without the full spec-design-plan flow. Use when the task is scoped and implementation-ready."
  ["research"]="Research a topic or code area deeply and save findings. Use when you need investigation before design or implementation."
  ["review-design"]="Critically review a design document before implementation. Use when you need flaws, risks, or open questions surfaced."
  ["spec"]="Create a feature specification with goals and acceptance criteria. Use when a feature needs requirements clarified and documented."
  ["wrap-up"]="Summarize session work and update project context. Use when closing a session and refreshing .project/CURRENT_WORK.md or related docs."
)

declare -A AGENT_DESCRIPTIONS=(
  ["example-agent"]="Example custom Codex agent generated from the Claude agent template."
)

NATIVE_SKILL_ALLOWLIST=(
  "example-skill"
)
