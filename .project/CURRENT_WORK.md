# Current Work

**Last Updated**: 2026-06-25

---

## Active Work

### `agent-working-voice` (branch `agent-working-voice`, committed `ddb7e7d`, not PR'd)
- **Status:** Implementation complete and installed locally; pending PR.
- **What:** One global rule for the agent's working voice (`claude-pack/rules/working-voice.md`) plus a reader-comprehension check in the two artifact reviewers.
- **Why it matters:** The model's default voice (dense, jargon-laden, block text) was the upstream bottleneck — bad voice compounds through spec→design→plan. The rule owns *how prose reads*; it does not touch a command's task stance or artifact structure.
- **Shipped:** the rule (auto-loads + propagates to Codex); pilot voice fixes to `_my_implement.md` and `_my_concept_design.md`; Lens 5 in `_my_spec_review.md` and Dimension 8 in `_my_review_design.md`.
- **Key finding:** the command prompts were in better shape than the audit claimed — real levers are the rule + the review check, not heavy prompt surgery.
- **Next steps:** open PR; rebuild and commit `dist/codex/` *after* the unrelated `handoff` WIP is resolved (the current rebuild entangles a `my-handoff` skill and `my-design` staleness, so dist was left out of `ddb7e7d`).

(`/_my_concept_design` from the prior session is now merged via PR #20.)

---

## Recently Completed

### 2026-06-25: agent-working-voice rule (branch, committed `ddb7e7d`)
- Global working-voice rule + reader-comprehension checks in spec/design reviewers; 2 surgical prompt fixes.
- Full pipeline run: spec → design → plan → implement, with user checkpoints on the rule and pilot rewrites.
- Two feedback memories saved: plain-writing voice, and dislike of the Q&A tool for complex decisions.

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

1. PR the `agent-working-voice` branch; rebuild and commit `dist/codex/` once the `handoff` WIP is sorted out
2. Resolve the pending `handoff` WIP (`_my_handoff.md`, `.project/active/handoff-command/`) — unrelated, currently riding in the working tree
3. Finalize production guide and PR to upstream
4. Iterate on security-analyzer: tune rules, reduce false positives, PR when ready

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
