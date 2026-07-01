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
  ["concept-design"]="Develop a design concept describing architecture, patterns, and responsibilities. Use when a design area needs a critiqueable, auditable conceptual sketch before detailed design."
  ["design"]="Create a technical design for an approved feature spec. Use when a feature needs architecture, interfaces, and tradeoff analysis."
  ["epic-plan"]="Decompose shaping output into a scoped epic with backlog items. Use when concepts or research are ready to become an implementation plan."
  ["example-command"]="Example Codex prompt generated from the example Claude command."
  ["git-manage"]="Handle git workflow tasks such as worktrees, merges, and conflict resolution. Use when you need structured git help."
  ["handoff"]="Write a handoff document to the OS temp directory so a fresh agent can continue the work. Use when ending a session and the next agent needs focus, context references, key discoveries, and suggested skills."
  ["implement"]="Execute an approved implementation plan with validation. Use when plan work should be carried through in the codebase."
  ["plan"]="Create a phased implementation plan from a spec and design. Use when work needs sequencing, validation, and file-level execution steps."
  ["product-design"]="Flesh out experience and interaction design for a consumer-facing surface before technical design. Use when a spec has UX, API, or interface decisions that should be resolved from the consumer's perspective."
  ["project-find"]="Find relevant project management context in .project/. Use when you need to locate specs, plans, designs, or recent research quickly."
  ["project-manage"]="Review project status, identify gaps, and suggest next steps. Use when coordinating work across backlog, active items, and completed artifacts."
  ["quick-edit"]="Handle a small focused change without the full spec-design-plan flow. Use when the task is scoped and implementation-ready."
  ["research"]="Research a topic or code area deeply and save findings. Use when you need investigation before design or implementation."
  ["review-design"]="Critically review a design document before implementation. Use when you need flaws, risks, or open questions surfaced."
  ["spec"]="Uncover and capture the problem, success criteria, and known requirements through critical questioning. Use when a feature or change needs its requirements clarified and documented before design."
  ["spec-review"]="Adversarially review a spec before it becomes the design contract. Use when a spec needs a devil's-advocate audit for faithfulness, problem framing, and pipeline risk."
  ["wrap-up"]="Summarize session work and update project context. Use when closing a session and refreshing .project/CURRENT_WORK.md or related docs."
)

declare -A AGENT_DESCRIPTIONS=(
  ["example-agent"]="Example custom Codex agent generated from the Claude agent template."
)

NATIVE_SKILL_ALLOWLIST=(
  "example-skill"
)
