# Current Work

**Last Updated**: 2026-07-01

---

## Active Work

*(none)*

---

## Recently Completed

### 2026-07-01: Epic WORKFLOW-V2 — Workflow v2 Redesign (certified, archived)
- Pipeline redesign: new bridge command (`epic_plan`), certification step (`audit`), archive command (`close`), consolidated pre-PR gate, Required Reading traceability from concepts through implementation.
- 9 items: epic template foundation, epic_plan, pipeline Required Reading, audit certification, close, pre_pr, status, design_review rename, cross-reference cleanup + Codex rebuild.
- All 6 epic success criteria verified. Retired 5 old commands, created 6 new ones, modified 3 pipeline commands.

### 2026-06-25: agent-working-voice rule (merged, PR #21)
- Global working-voice rule + reader-comprehension checks in spec/design reviewers; 2 surgical prompt fixes.
- Full pipeline run: spec → design → plan → implement, with user checkpoints on the rule and pilot rewrites.
- Two feedback memories saved: plain-writing voice, and dislike of the Q&A tool for complex decisions.
- Merged to `main` via PR #21; Codex dist rebuilt and committed (`aa652a9`).

### 2026-06-25: /_my_handoff command (committed `22e4437`)
- New command: writes a handoff doc to the OS temp dir for a fresh agent (focus, references to read, key discoveries, suggested skills).
- Spec at `.project/active/handoff-command/spec.md`; Codex skill + description added; pushed to `main`.

### 2026-04-18: CLAUDE.md created
- Added CLAUDE.md with architecture overview, key commands, session workflow
- Documents the meta-project nature (building commands while using them)
- Highlights that `setup-global.sh` must run after adding new commands

### 2026-02-11: Security Analyzer (branch: `security-analyzer`)
- Two scripts in `claude-pack/hooks/` for transcript security analysis
- All 6 checks pass against real data (943 transcripts, 14.6K findings)
- Not yet PR'd -- iteration-ready on branch

### 2026-02-07: Session context boot sequence (PRs #4, #5, #6)
- Added `/_my_wrap_up` command — end-of-session context persistence
- Added `context-loading.md` rule — auto-loaded rule that tells Claude to read CURRENT_WORK.md before starting non-trivial work
- Added "Session Start" section to `claude-md-checklist.md`
- Added `docs/working-with-claude.md` — practical guide for working with the toolkit
- Fixed concurrent session bug — wrap-up now uses conversation context as primary source, git as cross-validation
- Split original PR #3 into #4 (guide doc) + #5 (boot sequence feature) + #6 (concurrent fix)
- All merged to upstream `rwestwood89/agentic-project-init`

### 2025-12-30: codebase-organization
- Established `claude-pack/` and `project-pack/` structure
- Set up symlinks for development workflow

### 2025-12-30: init-project.sh improvements
- Added `.project/` merge strategy for existing projects
- Added CLAUDE.md check with `/init` suggestion

---

## Up Next

1. Finalize production guide and PR to upstream
2. Iterate on security-analyzer: tune rules, reduce false positives, PR when ready

---

## Session Notes

### 2026-06-25
- Diagnosed the voice problem as two axes: clarity/structure (partly handled) and texture/voice (the real gap). Settled a three-register model; this work owns only the *working voice* (chat + internal artifacts), not external explainers, not a command's task stance, not artifact structure.
- Core bet: the agent mirrors the register of its own prompts — so the lever was rewriting dense prompts, not just adding a rule. Pilots showed the prompts were already mostly good, which reframed the win toward the rule + review check.
- Rule grew real teeth from live user examples: a "precision is the work behind the voice" section, and "decompose into points; avoid block text" (a console wall-of-text was the trigger).
- `dist/codex/` deliberately excluded from the commit — the local rebuild entangled unrelated `handoff` WIP and `my-design` staleness.

### 2026-04-18
- Created `/_my_concept_design` command based on user feedback about `/_my_concept` being too spec-like for architecture work
- Good example: `echo-workspace/.project/concepts/20260417_forecast-handling-pattern.md` — clear design principles, invariants, vocabulary
- Bad example: `echo-workspace/.project/concepts/20260417_dispatch-guidance-restart.md` — too implementation-heavy, obscures decisions
- Key insight: design concepts should make decisions explicit, not bury them in details
- Gotcha: new commands need `setup-global.sh` to create symlinks in `~/.claude/commands/`

### 2026-02-16
- Wrote production codebase guide with collaborator feedback loop
- Created workflow-accountability rule for auto-loaded process enforcement
- Cherry-picked guide commit from security-analyzer to clean production-guide branch
- Accidentally pushed security-analyzer to remote, deleted it, pushed production-guide instead

### 2026-02-07
- Reviewed PR as upstream maintainer, identified `working-with-claude.md` scope issue
- Concurrent session safety: git log can't distinguish which session made which commits — conversation context is the right source of truth
- PR splitting workflow: create base branch from main, cherry-pick feature changes on top
