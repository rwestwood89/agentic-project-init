# Current Work

**Last Updated**: 2026-08-05

---

## Active Work

### anchor-on-the-point — keep the pipeline anchored to product purpose
- Replaces the earlier `product-truth-gates` direction by owner decision (2026-08-05).
- **Implemented on branch `anchor-on-the-point`** (spec → design → plan → implement in one session). Second line of ground truth beside the artifact chain: a single-job product-lens subagent (shared spec `claude-pack/scripts/product-lens.md`) re-derives the product's point at 4 narrowing sites (epic_plan, spec, design_review, audit), records findings in an append-only per-item ledger (`.project/active/{item}/product-lens.md`), graded by source authority (reuses capture-fidelity provenance); design_review + audit lead with a loud "is this the right piece of work?" that outranks a green rubric; the seven smells are tripwires split design/code by layer; pre_pr + close honor an unresolved BLOCK; move 1 carries the problem (design "The Point" slot, plan anti-restatement reversed).
- **Phase-1 gate passed decisively:** fresh uncoached lens stopped a fusion-tea fixture two independent ways (product-check BLOCK + duplicate-selecting-test smell), zero FPs, and the can't-find control refused to fabricate an oracle. Repo suite green (adr 25/25, pipeline-sync, docs).
- **Audited Needs Work then remediated (2026-08-05, pending re-audit):** fresh-session audit BLOCKED the ledger because the touch points changed ADR 0002's map without the record ADR 0001 requires — the feature catching its own author silently resolving a premise conflict. Remediation (owner-directed): filed ADR 0003 + amended 0002; ledger now DISPOSED. Also fixed fail-closed ledger reads, epic→item propagation (D2), audit escalation≠resolution, spec Problem grading, problem carriage at review/audit (SC1), status-aware ADR clearing, canonical smell numbering, fixture drift; retired `product-truth-gates.md` (owner quotes moved to the concept). Deferred by scope: vendored/Codex reachability + a live command-level e2e. Repo suite green; fixture re-run reconfirmed. Next: fresh-session re-audit.
- **v3 review → remediation v3 applied (2026-08-05, pending re-audit):** v3 found three fail-open paths + two grading gaps, all fixed: `_my_spec` records the parent epic unconditionally (`Epic: <id>`) and pre_pr/close/audit always read the epic's live gate (late epic BLOCKs now reach existing items); item audit scans every ledger block (can't certify over an older BLOCK); epic-scope close reads the epic's own gate directly; lens §2 separates ADR liveness (status) from authority (only `[OWNER]` provenance BLOCKs — `[AGENT](ratified)` no longer laundered to owner-grade), recorded by **ADR 0005** superseding 0004; lens §3 gives findings stable IDs + structured `Resolves:` records. Suite green; diff clean. ADR chain: 0005 active, 0002 amended, 0003→0004→0005 superseded. **Codex build wired** (`build-codex-pack.sh` copies the shared spec into `dist/codex/scripts` + rewrites the path to `$HOME/.codex/scripts/product-lens.md`; dist rebuilt). Committed on branch; global + Codex installed. Still deferred: vendored/copy-install project reachability (DEFER-F1b) + live command-level e2e (DEFER-F2). Next: fresh-session re-audit (v4).
- **Prior — re-audit v2 Needs Work → remediation v2 applied (2026-08-05):** v2 found five subtler blockers, two of them my own prior fixes backfiring. All closed: plan template gains a structural `## The Point` (SC1); amended ADRs now bind (only `superseded` stops binding); epic→item is a grade-preserving *reference* not a copy (kills smell 1) with ship gates + epic audit reading the epic's live gate; epic-scope audit now runs the lens; resolution-by-citation so a later CLEAR can't mask an earlier BLOCK; and ADR 0003's special-category framing (smell 3) superseded by **ADR 0004** (states the map is extended, amends 0002). Ledger `remediation v2` block disposes the audit_v2 BLOCK by citation → DISPOSED. Suite green (adr 25/25, pipeline-sync, docs, global-setup); `git diff --check` clean. Still owner-deferred: vendored/Codex reachability + live command-level e2e. Next: fresh-session re-audit (v3).
- Artifacts: `.project/concepts/anchor-on-the-point.md`; `.project/active/anchor-on-the-point/{spec,design,plan,audit,audit_v2,product-lens}.md` + `fixture-{planted-input,expected-findings}.md`; research `20260803-210317_...md`.

### decision-records — `.project/adr/` append-only decision log + pipeline touch points
- From the constraint-execution post-mortem (2026-07-19): durable, high-density record of load-bearing decisions; read at concept-design/design, written at design acceptance and close.
- **Implemented on branch `decision-records`** (with the post-mortem's System Confidence / EPIC_GUIDE slicing changes): `adr.sh` + convention README in project-pack, installer seeding, touch points in `_my_concept_design`/`_my_design`/`_my_close`, `test_adr.sh` 25/25 green, dogfood entries 0001–0002 filed here.
- **Certified (2026-07-19, `audit.md`)** — spec criteria 2–6 verified; criterion 1's surfaced seeding discrepancy resolved by owner (2026-07-22): amended the spec parenthetical to match approved design D5 (lazy `INDEX.md` bootstrap, no installer-seeded placeholder), criterion 1 now marked. Minor non-blocking notes remain: slug validation and self-supersede guard in `adr.sh`. Committed and PR'd.

### capture-fidelity — provenance, compression, and correction laws for the pipeline
- From forensics on the echo-workspace band-study failure: one always-loaded rule (provenance grading, compression protection, correction discipline, surfacing duty) + minimal touches to concept/spec/reviews/orchestrate/audit/handoff.
- **All 5 phases implemented on branch `capture-fidelity`.** Rule `claude-pack/rules/capture-fidelity.md` (40 lines) + 8 command touches; installed globally + Codex rebuilt. Phase-2 gate passed 4/4 (through real `spec_review`, 0 FPs) after refitting plant P3.
- **Audited: Certify (2026-07-10, `audit.md`); committed with refinements; merged origin/main. Next: PR.**
- Key calls during implement: P3 fixture was mis-specified for a concept hop (first-hop compression is owner-checked, not reviewer-checked — `design.md:71`), refit to a "softened referent" plant; audit + handoff deliberately don't reference the rule (their behaviors aren't among the four laws); rule content ships to Codex via `AGENTS.md`, not a separate file.
- Artifacts: `.project/active/capture-fidelity/{spec,spec-review,design,design-review,plan,audit}.md` + `fixture-{planted-concept,expected-findings}.md`

### capture-fidelity-refinements — second-layer fixes from the first pipeline run under the new laws
- Origination-vs-ratification provenance, fresh-session reviews, minted-provenance approval presentations, declared template adaptation, durable orchestrate briefs.
- **Implemented directly on owner instruction (owner curated the diff); committed alongside the parent item.**
- Spec: `.project/active/capture-fidelity-refinements/spec.md`

### codex-orchestrator-fork — Codex-native autonomous pipeline orchestration
- Spec, design, spike, and implementation plan drafted. Phases 1-5 are implemented and validated: Codex helper dry-run and real execution paths, generated script install lane, full `my-orchestrate` replacement, Codex `AGENTS.md` transforms, generated-product tests, installer dry-run, and project checks are in place. Optional live smoke was not run.
- Artifacts: `.project/active/codex-orchestrator-fork/{spec,design,spike-findings,plan}.md`

---

## Recently Completed

### 2026-07-06: spike-and-learning-test-commands — hands-on de-risking commands (certified, archived)
- Two new commands: `/_my_spike` (confirm a known assumption, throwaway probe + findings doc) and
  `/_my_learning_test` (map an unfamiliar surface, findings doc + real kept tests) — write-code-to-learn
  siblings of read-only `/_my_research`, sharing one discipline (reproducible, living doc,
  summary-on-top, close the loop).
- Soft de-risking suggestions wired into `concept_design`/`spec`/`design`/`epic_plan`/`research`;
  orchestration awareness in `_my_orchestrate`/`_my_pipeline`/`orchestrate-stage.sh`
  (`bypassPermissions` for headless runs). Codex-exposed; documented in README + CLAUDE.md.
- Audit verdict Certify (all 9 spec criteria). Archived to
  `.project/completed/20260706_spike-and-learning-test-commands/`.

### 2026-07: workflow-orchestrator — autonomous pipeline orchestrator (merged, PR #25)
- High-judgment agent (Fable) drives the v2 pipeline end to end via opus subagents, fully autonomous, Claude-only.
- Helper `orchestrate-stage.sh` + uniform preamble; command `_my_orchestrate.md`. Merged to `main`.

### 2026-07: pipeline-guide — canonical shipped pipeline overview (merged)
- Canonical `/_my_pipeline` command + always-on shape rule; other docs point here instead of restating the flow. Merged to `main` (`46020d8`).


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
