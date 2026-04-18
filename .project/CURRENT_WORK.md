# Current Work

**Last Updated**: 2026-04-18

---

## Active Work

### `/_my_concept_design` command (staged, not committed)
- **Status:** Complete, needs commit and push
- **What:** New command for high-level design concepts — architecture, patterns, responsibilities. Fills gap between `/_my_concept` (problem/scope) and `/_my_spec` (detailed requirements).
- **Key features:**
  - Decision clarity as primary core value ("what bets are we making?")
  - Design Concept Rubric: 22 items across 6 categories for self-review
  - Iterative self-review loop that patches document until all checks pass
  - 250-line limit forces design discipline
- **Template sections:** Overview, Problem, Goals/Non-Goals, Design Principles, Core Model, Required Invariants, How It Works, Edge Cases and Failure Modes, Vocabulary, Validation Strategy, Summary
- **Next steps:** Commit, push, run `setup-global.sh` to create symlink

---

## Recently Completed

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
3. Consider whether EPIC-002 (migrate commands from artifacts) is still relevant or superseded

---

## Session Notes

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
