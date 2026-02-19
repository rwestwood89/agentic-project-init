# Building Production Codebases with Claude Code

A practical guide for developers who want to ship top-tier, professional-grade software with Claude Code, not just vibe code.

## Who This Is For

You're a developer using Claude Code (Opus 4.6 or later) and you've noticed the gap: the model is excellent at writing code, but your multi-day features still fall apart. Context gets lost between sessions. Requirements drift without anyone noticing. The AI builds the wrong thing because it forgot what you agreed on yesterday.

This repo fixes the persistence problem. It gives Claude Code a structured workspace where specs, designs, plans, and session context survive across sessions and compactions. Everything else -- the code generation, the debugging, the refactoring -- the model handles natively.

---

## What Vanilla Claude Code Gets Wrong

Claude Code ships with real capabilities: extended thinking, sub-agents, auto-memory, plan mode, CLAUDE.md, and rules. For single-session tasks, it's genuinely good. The problems start when work spans multiple sessions.

**Sessions are ephemeral.** When context compacts or you start a new conversation, the model loses the thread. It doesn't know what you decided yesterday, what phase of implementation you're in, or which requirements you've already verified. Auto-memory helps, but it captures fragments -- not the structured state needed to resume complex work.

**Without artifacts, requirements drift.** When the spec lives only in chat history, nobody can audit whether the implementation actually satisfies it. Code review becomes "looks good to me" instead of "FR-1 maps to `handler.py:45`, VERIFIED." You can't trace a requirement to its implementation because the requirement was never written down.

**Better models don't fix discipline problems.** Opus 4.6 is dramatically better at code generation than earlier models. But "better at coding" doesn't help when the model doesn't know where you left off, what you agreed to build, or what's already been tested. Persistence and structure are process problems, not intelligence problems.

---

## The Essential Commands

Out of 18 commands in this repo, **9 are essential**. These are organized into three groups: the build pipeline, session continuity, and project management.

### The Build Pipeline

These five commands form a progression: define what to build, design how, plan the phases, implement, then verify. Each command produces a persistent artifact in `.project/active/{feature-name}/`.

#### `/_my_spec` -- Define Requirements

**Creates:** `.project/active/{feature-name}/spec.md`

The spec command captures *what* you're building and *why*. It walks you through scoping, asks clarifying questions, distinguishes your stated requirements from inferences, and produces a document with business goals, functional requirements (using RFC 2119 keywords like SHALL/SHOULD/MAY), acceptance criteria, and scope boundaries.

**Vanilla approach:** You describe the feature in chat. The requirements live in conversation history. When the session ends or compacts, those requirements are gone. Two sessions later, Claude builds something subtly different because it's working from a paraphrase of a paraphrase. Code review is subjective because there's nothing written to review against.

**With `/_my_spec`:** Requirements are a persistent file. The next session reads them. Code review audits against them line by line. When someone asks "does this feature handle edge case X?", you check the spec instead of trying to remember what you said in chat last Tuesday.

**When to use:** Any feature that touches multiple files or has ambiguous requirements. The spec becomes the contract that code review audits against.

**When to skip:** Bug fixes, config changes, single-file edits. Use `/_my_quick_edit` instead.

#### `/_my_design` -- Technical Architecture

**Creates:** `.project/active/{feature-name}/design.md`

The design command takes your spec and produces a technical design through iterative research. It explores the codebase, identifies existing patterns and integration points, presents alternatives when decisions are needed, and documents the chosen approach with `file:line` references.

**Vanilla approach:** You ask "how should I build this?" and get a response in chat. Claude suggests an architecture, you discuss trade-offs, you agree on an approach. Then the session ends. The next session might make completely different architecture decisions because it doesn't know what was decided. Worse, it doesn't know *why* -- the reasoning behind choosing approach A over approach B is gone.

**With `/_my_design`:** The design rationale, alternatives considered, codebase analysis, and chosen approach are all in `design.md`. The implementation command reads it before writing code. If you come back a month later to extend the feature, you read the design to understand why things are structured the way they are.

**When to use:** When the *how* isn't obvious. New subsystems, API designs, database schema changes, anything where architecture matters.

**When to skip:** When the implementation approach is obvious from the spec. Simple CRUD endpoints, adding a field to an existing model, following an established pattern. You can go straight from spec to plan.

#### `/_my_plan` -- Phased Implementation

**Creates:** `.project/active/{feature-name}/plan.md`

The plan command breaks implementation into testable phases with a test-first approach. Each phase has a goal, a test stencil (write tests before code), specific file changes referencing the design, and validation steps. Phases include checkboxes that track progress.

**Vanilla approach:** Claude's built-in `/plan` mode creates an implementation plan in the conversation. It's decent for single-session work, but the plan is ephemeral -- it lives in context and disappears when the session ends. You can't check off phases, track what's done, or hand it to the next session. If the context compacts mid-implementation, the plan is gone and you're re-explaining the feature from scratch.

**With `/_my_plan`:** The plan is a file. It references the design document instead of duplicating it. Each phase has checkboxes that get checked off as work completes. When you come back tomorrow, you open `plan.md`, see that Phases 1-2 are done, and pick up at Phase 3. The implement command reads this file and offers to resume where you left off.

**When to use:** Any implementation that will take more than one session. The plan is what the next session reads to know where to resume.

**When to skip:** Changes small enough to complete in one pass. Use `/_my_quick_edit` for those.

#### `/_my_implement` -- Execute the Plan

**Reads:** `spec.md`, `design.md`, `plan.md`
**Produces:** Code changes, updated plan with completion notes

The implement command reads the spec, design, and plan before writing any code. It offers codebase exploration, confirms scope, then executes phase by phase -- starting with tests, validating as it goes, and checking off plan items. When something deviates from the plan, it stops and asks.

After each phase, it writes implementation notes directly into `plan.md`: what actually changed, issues encountered, deviations and why. This is critical for the next session or for code review.

**Vanilla approach:** You say "build this feature" and Claude starts writing code. It doesn't know your requirements (they were in a previous session), doesn't follow a phased approach, and doesn't track what's done vs. what's remaining. If it gets halfway through and the session ends, the next session has no idea what was completed and what wasn't. Deviations from the original intent go undocumented.

**With `/_my_implement`:** Claude reads the spec, design, and plan before touching any code. It understands *why* things are structured the way they are. It checks off phases as it goes, writes completion notes, and documents deviations. If the session ends mid-feature, the next session picks up exactly where this one stopped.

#### `/_my_audit_implementation` -- Verify Against the Plan

The audit command checks completed plan phases against what was actually implemented. It looks for placeholder code, TODOs, partial implementations, unjustified deviations, test coverage gaps, and mocked-out functionality that needs production testing.

**Vanilla approach:** You finish implementing and say "I think that's done." Claude agrees because it was the one writing the code -- it's not going to audit its own work critically. There's no systematic check for completeness. Placeholder code and skipped edge cases slip through because nobody went back to compare the implementation against the plan.

**With `/_my_audit_implementation`:** An independent audit reads `plan.md` and inspects every completed phase. It flags TODOs, stubs, unjustified deviations, and gaps in test coverage with `file:line` references. Issues are aggregated by severity (Critical / Major / Minor). You get a clear picture of what's actually done vs. what was supposed to be done.

**When to use:** After implementation, before considering a feature complete. Quick, practical, and catches the things that slip through when the same agent builds and "reviews" its own work.

### Session Continuity

These two commands solve the persistence problem directly.

#### `/_my_wrap_up` -- End-of-Session Context Persistence

**Updates:** `.project/CURRENT_WORK.md`, auto-memory (`MEMORY.md`), relevant docs

This is the single most important command in the system. Run it before closing Claude Code. It reviews what happened in the session, updates `CURRENT_WORK.md` with current status, persists key learnings to auto-memory, updates any affected docs, and commits the changes.

The next session auto-loads `MEMORY.md` and is instructed (via the `context-loading` rule) to read `CURRENT_WORK.md` before starting non-trivial work. That's the boot sequence: `/_my_wrap_up` writes it, the next session reads it.

**Vanilla approach:** You close the session. Tomorrow, Claude has auto-memory fragments and your `CLAUDE.md`, but doesn't know what you were working on, what's done, what's blocked, or what decisions you made. You spend the first 10 minutes re-explaining context: "We're building a security analyzer, we finished the parser yesterday, the classifier still needs work, and we decided to use regex instead of AST parsing because..." Every session starts with archaeology.

**With `/_my_wrap_up`:** You run one command. It writes the current state to `CURRENT_WORK.md` and distills key learnings into `MEMORY.md`. Tomorrow's session boots with full context: what's active, what's done, what's next, and what gotchas to avoid. No archaeology. No re-explaining.

**When to use:** End of every work session. After completing significant work. After discovering a gotcha that would burn time again.

**Cost:** 30 seconds. **Saves the next session:** 10+ minutes of re-orientation.

#### `/_my_research` -- Persistent Exploration

**Creates:** `.project/research/{timestamp}_{topic}.md`

The research command produces a standalone document from deep codebase exploration. It spawns parallel sub-agents to find related files and patterns, synthesizes findings with `file:line` references, and assesses feasibility. The output lives in `.project/research/` where any future session can find it.

**Vanilla approach:** You ask Claude to explore a codebase area. It reads files, finds patterns, explains how things work. The findings exist only in conversation. Next month when you need the same information, you re-explore from scratch -- same files, same questions, same 20 minutes. If the context compacts mid-exploration, you lose the synthesis and are left with fragments.

**With `/_my_research`:** The exploration becomes a document. It has `file:line` references, architecture insights, feasibility assessments, and recommendations. Next month, you or the next session reads the research doc instead of re-exploring. The 20-minute investment pays off every time someone needs to understand that code area.

**When to use:** Before speccing a feature in an unfamiliar area. When you spend 20 minutes exploring a codebase, this command turns that into a document. Next month when you need to touch that code again, you read the research instead of re-exploring.

### Project Management

These commands replace external PM tools. Your backlog, epics, and active work tracking live in the repo.

#### `/_my_project_manage` -- Status, Decomposition, Closure, Backlog

**Modes:**
- `/_my_project_manage` or `status` -- Full status report with gap analysis and recommendations
- `/_my_project_manage decompose <epic>` -- Break an epic into well-scoped backlog items (0.5-2 day chunks)
- `/_my_project_manage close [item]` -- Archive completed work to `.project/completed/`, update tracking
- `/_my_project_manage backlog` -- Interactive backlog management (add, reprioritize, review epics)

**Vanilla approach:** You track work in Jira, Linear, a spreadsheet, or your head. Claude has zero visibility into your project state. You context-switch to an external tool to check what's next, then context-switch back to explain it to Claude. Completed work isn't archived -- it just accumulates in random directories until someone cleans up.

**With `/_my_project_manage`:** Your backlog, epics, active work, and completion tracking live in `.project/` -- the same place Claude already reads from. Status reports identify gaps and recommend next steps. Closing an item archives it properly and updates all tracking files. No external tools, no context-switching.

#### `/_my_project_find` -- Quick Context Lookups

**Topics:**
- `/_my_project_find current` -- What's being worked on now
- `/_my_project_find backlog` -- What's planned next
- `/_my_project_find epic <name>` -- Details of a specific epic
- `/_my_project_find item <name>` -- Details of a specific work item
- `/_my_project_find context` -- Full orientation (default)

**Vanilla approach:** You start a new session and Claude has no idea what you're working on or what's next. You manually explain: "I'm working on the auth system, we finished the login flow last week, the password reset is next." Every session starts with a briefing.

**With `/_my_project_find`:** One command and Claude reads the structured project state. `/_my_project_find current` tells you what's active. `/_my_project_find backlog` shows what's next. No briefing required.

### Shortcuts

#### `/_my_quick_edit` -- When the Full Pipeline Is Overkill

For changes too small to warrant spec/design/plan but not trivial enough to just do. It walks through understanding the change, proposing modifications, optionally planning, executing, and reviewing. Can optionally produce a `change.md` summary.

**When to use:** Small features (1-3 files), clear requirements, some planning needed. Adding a flag to a CLI tool, modifying a validation rule, extending an existing pattern.

#### `/_my_code_quality` -- Automated Quality Checks

Runs all quality checks (tests, linting, formatting, type checking) per your `CLAUDE.md` config, categorizes issues by risk level, fixes low-risk issues directly, and documents medium/high-risk issues for your approval before fixing.

**When to use:** After implementation, before committing. After `/_my_audit_implementation` passes.

---

## Commands You Probably Don't Need

This repo was started when Claude models were weaker. Some commands solved problems that Opus 4.6 now handles natively, and others overlap with the essential commands above. Here's an honest assessment.

### `/_my_concept`

**What it does:** Develops a feature concept with success criteria, user stories, and scope definition. Outputs to `.project/concepts/`.

**Why you can skip it for most work:** If you're going through the normal build pipeline (spec -> design -> plan -> implement), you don't need a separate concept document. Go straight to `/_my_spec`.

**When it's actually designed for:** The Ralph Loop. `/_my_concept` produces the concept document that feeds into the autonomous `ralph-init.sh` pipeline. If you're using Ralph Loop for autonomous project scaffolding, this is the input format it expects. Outside of that workflow, `/_my_spec` covers the same ground.

### `/_my_code_review`

**What it does:** Heavyweight formal review that builds a full requirements traceability matrix (mapping every FR to its implementation with VERIFIED/PARTIAL/GAP/DEVIATION status), checks design conformance across six dimensions, hunts for bugs, and assesses test coverage. Produces a detailed report at `.project/active/{feature-name}/code_review-{timestamp}.md`.

**Why you can skip it:** This was designed for pre-PR formal reviews, but in practice `/_my_audit_implementation` covers what you actually need -- verifying the implementation matches the plan. The full traceability matrix and dimensional analysis add ceremony without proportional value for most features.

**When it's still useful:** When you want a formal, documented review artifact for compliance or team hand-off. If someone needs to audit the feature later, the structured report with RFC 2119 traceability is thorough.

### `/_my_review_design`

**What it does:** Critical review of design documents across six dimensions (spec compliance, pattern consistency, abstraction quality, duplication avoidance, data structure clarity, route safety).

**Why it's listed here:** You might think Opus 4.6 handles this conversationally, and it can -- but the structured dimensional review has caught a surprising number of mistakes that conversational review misses. The forced checklist approach (spec compliance, pattern consistency, abstraction quality, etc.) surfaces issues that "does this look right?" doesn't.

**When to use:** After `/_my_design` produces a design document, before moving to implementation. It's a lightweight gate that's prevented costly rework. Consider it situational rather than redundant -- if the design is straightforward, skip it; if the design involves multiple components or integration points, run it.

### `/_my_capture` and `/_my_memorize`

**What they do:** `/_my_capture` marks the current conversation for later review. `/_my_memorize` parses a transcript and creates a structured memory artifact in `.project/memories/`.

**Why you can skip them:** These were experimental. They were used a few times to scrape conversation content when auto-compaction hit mid-session, but `/_my_wrap_up` now handles the critical persistence proactively. The capture/memorize pipeline produces `.project/memories/` artifacts that aren't auto-loaded and require manual recall.

**When they're still useful:** If auto-compaction hits during a long session and you want to salvage the conversation content. But with `/_my_wrap_up` persisting context before compaction becomes an issue, this scenario is rare.

### `/_my_review_compact`

**What it does:** Reviews auto-compaction captures and creates memory files.

**Why you can skip it:** This was designed for a pre-wrap_up world where context compaction was the main threat to continuity. With `/_my_wrap_up` persisting context proactively, you rarely need to review what was lost during compaction.

**When it's still useful:** If a long session compacts mid-work and you want to verify nothing important was lost.

### `/_my_recall`

**What it does:** Searches past conversation transcripts using a recall sub-agent. Can search the most recent transcript, all transcripts, or indexed/memorized ones.

**Why you can skip it for most work:** With `/_my_wrap_up` distilling key knowledge into auto-memory and `CURRENT_WORK.md`, the next session already has what it needs. Recall is searching raw transcripts, which is slower and noisier.

**When it's still useful:** When you have many past sessions and need to find a specific decision or discussion. "What authentication approach did we discuss last month?" across dozens of transcripts. The more sessions you accumulate, the more useful recall becomes.

### `/_my_git_manage`

**What it does:** Git worktree management -- creating, merging, reconciling, and cleaning up worktrees with project management file isolation to prevent merge conflicts.

**Why you can skip it:** Only relevant if you're using git worktrees for parallel branch development. Most developers work on one branch at a time.

**When it's still useful:** Two scenarios. First, parallel feature development across worktrees. Second -- and this is the more common one -- when you're working on a team where other developers don't want `.project/` checked into the shared repo. The worktree isolation pattern lets you keep your project management workflow in a separate worktree without polluting the team's main branch.

---

## The .project/ Directory

After initialization and use, your project develops this structure:

```
.project/
├── CURRENT_WORK.md          # What's active, recently completed, up next
├── EPIC_GUIDE.md            # How to decompose epics into backlog items
├── epic_template.md         # Template for new epics
├── README.md                # Workflow overview
│
├── active/                  # In-progress features
│   └── {feature-name}/      # One directory per feature
│       ├── spec.md          # Requirements (from /_my_spec)
│       ├── design.md        # Technical design (from /_my_design)
│       ├── plan.md          # Phased implementation (from /_my_plan)
│       ├── code_review-*.md # Review reports (from /_my_code_review, if used)
│       └── change.md        # Quick edit summary (from /_my_quick_edit)
│
├── backlog/                 # Planned work
│   ├── BACKLOG.md           # Prioritized epic list
│   └── epic_*.md            # Individual epic definitions
│
├── completed/               # Archived features (moved from active/)
│   ├── CHANGELOG.md         # Completion log
│   └── {YYYYMMDD}_{name}/   # Archived feature directories
│
├── research/                # Exploration documents
│   └── {timestamp}_{topic}.md  # Research output (from /_my_research)
│
├── reports/                 # Generated reports
│   └── *-status-report.md   # Status reports (from /_my_project_manage)
│
├── concepts/                # Early-stage ideas (from /_my_concept)
│
└── memories/                # Conversation summaries (from /_my_memorize)
```

### Lifecycle

A feature flows through the directory structure:

1. **Backlog:** Epic defined in `backlog/epic_*.md`, listed in `BACKLOG.md`
2. **Active:** Feature directory created in `active/{feature-name}/` with spec, design, plan
3. **Completed:** Archived via `/_my_project_manage close` to `completed/{date}_{name}/`

`CURRENT_WORK.md` tracks the live state across all of these. It's the file `/_my_wrap_up` updates and the file the next session reads first.

---

## Workflow Decision Tree

Not every change needs the full pipeline. Use this to decide what to run.

**Bug fix with clear root cause?**
Just fix it. Read the code, fix the bug, run tests, done.

**Small change (1-3 files, clear requirements)?**
`/_my_quick_edit` -- Understand, propose, execute, review.

**New feature (clear requirements)?**
`/_my_spec` -> `/_my_plan` -> `/_my_implement` -> `/_my_audit_implementation`

Skip `/_my_design` if the implementation approach is obvious from the spec.

**New feature (unclear approach, multiple valid architectures)?**
`/_my_spec` -> `/_my_design` -> `/_my_plan` -> `/_my_implement` -> `/_my_audit_implementation`

**Complex feature in an unfamiliar codebase?**
`/_my_research` -> `/_my_spec` -> `/_my_design` -> `/_my_plan` -> `/_my_implement` -> `/_my_audit_implementation`

**Resuming work from a previous session?**
Read `CURRENT_WORK.md` and the active feature's `plan.md`. Pick up where the checkboxes stop.

**End of session?**
`/_my_wrap_up`. Every time.

---

## What Opus 4.6 Handles Natively

Claude Code has built-in capabilities that overlap with some of this repo's functionality. Understanding what's native helps you avoid redundant work.

**Built-in plan mode** (`/plan`) creates an ephemeral implementation plan. It works for single-session tasks but the plan disappears when the session ends. `/_my_plan` creates a persistent `plan.md` that survives across sessions and tracks progress with checkboxes. Use the built-in plan mode for quick explorations; use `/_my_plan` for anything multi-session.

**Sub-agents** (Task tool with Explore, Plan, general-purpose types) handle parallel research, codebase exploration, and analysis. The commands in this repo use sub-agents internally -- `/_my_research` spawns Explore agents, `/_my_design` uses them for codebase analysis. You don't need to manage sub-agents directly unless you're doing ad-hoc exploration.

**Auto-memory** (`~/.claude/projects/*/memory/MEMORY.md`) persists distilled knowledge across sessions. It's auto-loaded every session. `/_my_wrap_up` writes to it. This is a native feature that this repo builds on, not replaces.

**CLAUDE.md and rules** auto-load every session. The `context-loading` rule from this repo tells Claude to read `CURRENT_WORK.md` before starting non-trivial work. This is how the boot sequence works: native auto-loading triggers a rule that reads project state.

**Code generation, git operations, extended thinking** -- all native. This repo doesn't try to improve code generation. It improves the *process* around code generation: making sure the model builds the right thing, tracks progress, and persists context.

---

## Best Practices

### Write a Good CLAUDE.md

Your project's `CLAUDE.md` is auto-loaded every session. Make it count. Include:

- **Test commands** -- how to run tests, lint, type check
- **Build commands** -- how to build, run, deploy
- **Project conventions** -- naming patterns, directory structure, key abstractions
- **Session Start section** -- point Claude to `CURRENT_WORK.md`:

```markdown
## Session Start
Before starting non-trivial work, read `.project/CURRENT_WORK.md` for current context.
```

This single line bridges the gap between auto-loaded context and project state.

### Let Claude Hold You Accountable

This repo ships a `workflow-accountability` rule in `claude-pack/rules/` that auto-loads every session. It tells Claude to:

- Flag when you're about to implement a non-trivial feature without written requirements
- Check `plan.md` for progress before resuming multi-session work
- Suggest `/_my_audit_implementation` after completing a plan
- Proactively suggest `/_my_wrap_up` when a session is winding down

It nudges, not blocks -- Claude will suggest the right practice but won't refuse to proceed if you want to skip it. If you find it too aggressive or too passive, edit `claude-pack/rules/workflow-accountability.md` to match your preferences. The rule is symlinked globally, so changes apply to all projects immediately.

### Spec-Driven Development

The spec is your contract. Without `spec.md`, code review devolves into "looks good to me." With it, you get traceability:

> FR-1: System SHALL parse JSONL transcripts -> `analyzer.py:45-67`, VERIFIED
> FR-2: System SHALL classify tool_use events -> `classifier.py:12-89`, VERIFIED
> FR-3: System SHOULD support incremental indexing -> Not found, GAP

That traceability is what `/_my_audit_implementation` checks against. It's only possible because the spec and plan exist as persistent artifacts.

### Check Off Plan Phases As You Go

When you finish Phase 2 of `plan.md`, mark it complete in the file:

```markdown
## Phase 2: Core Implementation

- [x] Create `src/parser.py` with `parse_transcript()` function
- [x] Add error handling for malformed JSONL lines
- [x] Write tests for happy path and edge cases

### Phase 2 Completion
**Completed:** 2026-02-16
**Actual Changes:** Created parser.py (145 lines), added 8 tests
**Issues:** None
**Deviations:** Added streaming support not in original design (approved by user)
```

The next session reads `plan.md` to know where to resume. If phases aren't checked off, it doesn't know what's done.

### Wrap Up Every Session

`/_my_wrap_up` takes 30 seconds. It saves the next session 10+ minutes of re-orientation. This is especially critical for multi-day features where you might not touch the code for a week.

What it updates:
- `CURRENT_WORK.md` -- moves completed items, updates active status, adjusts priorities
- `MEMORY.md` -- distills gotchas, patterns, and decisions into auto-loaded memory
- Relevant docs -- if behavior changed, docs stay current

### Use Research Docs for Future-You

When you spend 20 minutes exploring a codebase area, `/_my_research` turns that exploration into a document with `file:line` references, architecture insights, and feasibility assessments. Next month when you need to touch that code again, you read the research instead of re-exploring from scratch.

Research docs are especially valuable for:
- External API integrations (rate limits, auth patterns, quirks)
- Complex subsystems with non-obvious control flow
- Areas where you made decisions based on investigation

### One Feature = One Directory

`.project/active/{feature-name}/` keeps spec, design, plan, and review together. When you need to understand the full picture of a feature, it's one `ls`:

```
.project/active/security-analyzer/
├── spec.md
├── design.md
├── plan.md
└── code_review-2026-02-15-1430.md
```

Everything about the feature -- what it is, how it's built, where implementation stands, whether it passes review -- lives in one place.

---

## Individual Developer Focus

This system is designed primarily for solo developers working with Claude Code.

**You are both the PM and the engineer.** That's exactly it. The spec/design/plan pipeline replaces the conversations you'd have with a team. Instead of discussing requirements with a product manager, you write them in `spec.md`. Instead of whiteboarding architecture with a colleague, you produce `design.md`. The artifacts are the conversation, preserved for your future self.

**Ad hoc requirements docs are encouraged.** Not everything needs to go through `/_my_spec`. If you have a quick user story, a set of requirements for a small feature, or acceptance criteria you want to capture, just write them -- either in `.project/` alongside your other artifacts, or in the repo root where they're close to the code. The point is to write things down, not to follow a specific format. A `REQUIREMENTS.md` in the repo root that says "the CLI should support --verbose and --json flags" is better than nothing.

**`/_my_project_manage` replaces Jira/Linear.** Your backlog, epics, active work, and completion tracking live in `.project/`. Status reports, decomposition, and closure are all handled by one command. No context-switching to a separate tool.

**Session continuity matters more for solo work.** There's no teammate to ask "where did we leave off?" The only record of yesterday's decisions is what you persisted. `/_my_wrap_up` is the difference between a productive morning and 20 minutes of archaeology.

**The artifacts scale to teams.** If you start collaborating, the specs, designs, and research docs become communication tools. A new contributor can read `spec.md` and `design.md` to understand what's being built and why, without needing a walkthrough from you. The artifacts you wrote for yourself become onboarding material.

---

## Quick Reference

### Essential Commands

| Command | Purpose | Artifact |
|---------|---------|----------|
| `/_my_spec` | Define requirements and acceptance criteria | `spec.md` |
| `/_my_design` | Technical architecture and design decisions | `design.md` |
| `/_my_plan` | Phased implementation with test-first approach | `plan.md` |
| `/_my_implement` | Execute plan with progress tracking | Code + updated `plan.md` |
| `/_my_audit_implementation` | Verify implementation against plan | Structured report |
| `/_my_wrap_up` | End-of-session context persistence | Updated `CURRENT_WORK.md`, `MEMORY.md` |
| `/_my_research` | Deep codebase exploration | `.project/research/*.md` |
| `/_my_project_manage` | Status, decomposition, closure, backlog | `.project/reports/*.md` |
| `/_my_project_find` | Quick context lookups | Console output |

### Situational Commands

| Command | Use When |
|---------|----------|
| `/_my_quick_edit` | Change is too small for full pipeline but needs some structure |
| `/_my_code_quality` | Need automated quality checks (lint, test, format) |
| `/_my_concept` | Building a concept document for the Ralph Loop pipeline |
| `/_my_review_design` | Design involves multiple components or integration points |
| `/_my_recall` | Need to search many past conversation transcripts |
| `/_my_git_manage` | Worktrees, or keeping `.project/` out of a shared repo |

### Redundant Commands

| Command | Replaced By |
|---------|-------------|
| `/_my_code_review` | `/_my_audit_implementation` (more practical) |
| `/_my_capture` | `/_my_wrap_up` (for most use cases) |
| `/_my_memorize` | `/_my_wrap_up` (for most use cases) |
| `/_my_review_compact` | `/_my_wrap_up` (proactive, not reactive) |
