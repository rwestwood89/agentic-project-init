# Implementation Plan: Spike and Learning-Test Commands

**Status:** Complete (all 4 phases)
**Created:** 2026-07-02
**Last Updated:** 2026-07-02

## Source Documents
- **Spec:** `.project/active/spike-and-learning-test-commands/spec.md`
- **Design:** `.project/active/spike-and-learning-test-commands/design.md` ← component details, decisions, wiring anchors, findings-doc shape

> **Note on "test-first" for this feature.** The deliverables are markdown command files and
> build-config edits — there is no unit-test suite to write first. The equivalent of a test here
> is a **validation check**: does the command resolve, does the Codex build emit valid YAML, do
> the docs agree, and — the real proof — does an end-to-end dry run produce a reproducible living
> findings doc that closes the loop. Each phase leads with the check it must satisfy.

## Implementation Strategy

**Phasing Rationale:** Prove the shared discipline on one command end-to-end (Phase 1) before
replicating it (Phase 2), then wire references into the pipeline once the commands exist
(Phase 3), then expose to Codex and document (Phase 4). Ordering is strict: each phase depends
on the previous.

**Critical Path:** `_my_spike.md` + install → live dry run → `_my_learning_test.md` → pipeline
wiring → Codex build + docs.

**First Proof Point:** Phase 1's live dry run on the subagent-invocation spike already queued
under `workflow-orchestrator` (see `.project/CURRENT_WORK.md`). It exercises the reproducible
living doc, summary-on-top, and the close-the-loop back-reference on a genuine unknown.

**Overall Validation Approach:**
- Each phase leads with the validation check it must pass.
- The close-the-loop heuristic (`design.md#next-stage-handoff`, "de-risk first") is proven live
  in Phase 1 before Phase 2 copies it.
- Phase 4 verifies README + CLAUDE.md + Codex config all list both commands.

---

## Phase 1: Author `/_my_spike` and prove the pattern end-to-end

### Goal
Write the spike command and prove the shared four-part discipline (`design.md#core-concept`)
works on a real unknown, before it gets replicated into a second command.

### Assumption Under Test
That the close-the-loop instruction — "identify the triggering artifact from context, else ask"
(`design.md#implementation-notes`) — is reliable in practice, and that the findings-doc shape
produces a genuinely reproducible living document.

### Validation Check (Define This First)
```
Dry run: invoke /_my_spike on the workflow-orchestrator subagent-invocation unknown.
Expect:
  - creates active/spike-{topic}/ (no work-item folder in play) with scripts + findings doc
  - findings doc has a Summary-of-Findings section ON TOP, written last
  - the log is reproducible (steps recorded, re-runnable)
  - a back-reference to the findings doc is written into the triggering upstream doc
```

### Changes Required

**See `design.md` for:** command structure (`design.md#component-overview`), findings-doc shape
and close-the-loop instruction (`design.md#implementation-notes`), invariants
(`design.md#required-invariants`).

#### 1. Spike command file
**File:** `claude-pack/commands/_my_spike.md` (NEW)
- [x] Header: Purpose / Input / Output, following the `_my_*` convention (model on `_my_quick_edit.md`)
- [x] Overview opens with the one-line spike-vs-learning-test contrast (mitigates B1, `design.md#key-bets`)
- [x] Staged process: (1) understand the question → (2) locate/create home folder (work-item folder else `active/spike-{topic}/`) → (3) probe with reproducible scratch scripts + living findings doc → (4) write summary on top → (5) close the loop
- [x] Carry the reference voice verbatim in intent: "probe how this can work — take your time, try different approaches"; "document findings as you go, everything reproducible"; "just before finishing, write a summary at the top"
- [x] Related Commands footer cross-links `/_my_learning_test` and `/_my_research`
- [x] `**Last Updated**` line

#### 2. Install
**File:** `~/.claude/commands/_my_spike.md` (symlink, via script)
- [x] Run `./scripts/setup-global.sh` (`[HARD]`, spec) — command won't resolve in other sessions otherwise

### Validation (How to Verify This Phase)
**Automated / mechanical:**
- [x] `readlink ~/.claude/commands/_my_spike.md` points into `claude-pack/`
- [x] `/_my_spike` resolves in a fresh session

**Manual (the proof point):**
- [x] Run the dry run above (target substituted — see Phase 1 Completion) on a real unknown
- [x] Verify all four expectations in the Validation Check block hold
- [x] If the close-the-loop step stumbles, fix the instruction wording NOW (before Phase 2 copies it)

**What We Know Works After This Phase:**
The spike command and the full shared discipline, proven on a real unknown.

---

## Phase 2: Author `/_my_learning_test`

### Goal
Replicate the proven discipline with learning-test framing and its distinct output rules.

### Assumption Under Test
That the same findings-doc discipline transfers cleanly to the "discover a surface" intent,
with tests as the durable artifact.

### Validation Check (Define This First)
```
Read-through: the command must make the agent
  - locate the repo's real test directory (never hardcode, never .project/) — D4
  - write real tests there
  - write the findings doc to .project/research/{ts}_{topic}.md — D3
  - close the loop into the upstream doc
```

### Changes Required
**See `design.md` for:** D3/D4 output split (`design.md#key-decisions`), shared discipline
(`design.md#core-concept`).

**File:** `claude-pack/commands/_my_learning_test.md` (NEW)
- [x] Same staged shape as `_my_spike.md`, reusing the wording proven in Phase 1
- [x] Overview opens with the contrast (fuzzy surface → learning test; known goal → spike)
- [x] Output rules: tests in repo's test dir (agent locates it, prompt says so explicitly); findings doc in `.project/research/`
- [x] Related Commands footer cross-links `/_my_spike` and `/_my_research`
- [x] Run `./scripts/setup-global.sh` to symlink

### Validation
**Automated:**
- [x] `/_my_learning_test` resolves in a fresh session
**Manual:**
- [x] Read-through confirms the four points in the Validation Check block
- [x] Confirm no hardcoded test path and no `.project/` test location

**What We Know Works After This Phase:**
Both commands exist and are installed; their output rules differ correctly.

---

## Phase 3: Wire the pipeline (soft suggestions)

### Goal
Add soft-suggestion blocks so agents reach for the right technique at the right moment, and
cross-link with `/_my_research`.

### Assumption Under Test
That a short suggestion at an anchor agents already read is enough to surface the technique
without becoming a gate (B2, `design.md#key-bets`).

### Validation Check (Define This First)
```
Re-read each edited command. Each suggestion must:
  - be SOFT (offers, never halts the pipeline) — invariant
  - sit at the named anchor, not a new section
  - distinguish the two techniques (clear goal → spike; fuzzy surface → learning test)
```

### Changes Required
**See `design.md#component-overview`** (modified-files list) and **`design.md#research-findings`**
(the exact anchor in each file).

- [x] `claude-pack/commands/_my_concept_design.md` — at the "First risk to de-risk" handoff bullet (`_my_concept_design.md:326`)
- [x] `claude-pack/commands/_my_spec.md` — extend "Offer research, don't guess" (Stage 2 questioning loop) to offer a spike/learning test for behavioral unknowns
- [x] `claude-pack/commands/_my_design.md` — at REFLECT / Key Bets: suggest a spike to validate a cheap-to-test bet (placed on the REFLECT "Assumptions" question)
- [x] `claude-pack/commands/_my_epic_plan.md` — Stage 3: surface a de-risking spike as a candidate early backlog item
- [x] `claude-pack/commands/_my_research.md` — Related Commands: cross-reference (read-only vs write-to-learn)

**Added per user request (orchestration awareness):**
- [x] `claude-pack/commands/_my_orchestrate.md` — "How to work": insert a de-risking `spike`/`learning_test` stage via the helper when a bet is shaky (soft, judgment call).
- [x] `claude-pack/commands/_my_pipeline.md` — "How to read it" bullet + a "De-risking (optional, any stage)" Guide subsection listing both commands. Shape line untouched.
- [x] `claude-pack/scripts/orchestrate-stage.sh` — extended the default-`bypassPermissions` case to `spike|learning_test` so the orchestrator can run them headlessly (they execute probe/test code, like `implement`/`pre_pr`).

### Validation
**Manual:**
- [x] Re-read all files; each edit passes the three points in the Validation Check block (soft; at the anchor; distinguishes the two techniques)
- [x] No edit changes existing command behavior beyond adding the optional suggestion
- [x] `scripts/test_pipeline_sync.sh` passes (shape line untouched)
- [x] `orchestrate-stage.sh run spike --dry-run` composes `/_my_spike …` with `bypassPermissions`

**What We Know Works After This Phase:**
The pipeline points at the new commands at the right moments, softly.

---

## Phase 4: Codex exposure and documentation

### Goal
Expose both commands as Codex skills and document them.

### Assumption Under Test
That both commands are Codex-portable (no Claude-only dependency), so they belong in
`COMMAND_SKILL_DESCRIPTIONS`, not the exclusion list (D5, `design.md#key-decisions`).

### Validation Check (Define This First)
```
After build + install:
  - dist/codex/skills/my-spike/SKILL.md and my-learning-test/SKILL.md exist
  - each SKILL.md YAML description is plain prose, NOT starting with * or ** (CLAUDE.md gotcha)
  - README table + CLAUDE.md + config.sh all list both commands
```

### Changes Required
**See `design.md#implementation-notes`** (Codex description rules) and **`CLAUDE.md`**
"Codex Compatibility Layer".

- [x] `codex-overrides/config.sh` — add `["spike"]="..."` and `["learning-test"]="..."` to `COMMAND_SKILL_DESCRIPTIONS` (plain prose, pattern `"<action>. Use when <trigger>."`)
- [x] Run `./scripts/build-codex-pack.sh`
- [x] Run `./scripts/setup-codex.sh --copy`
- [x] `README.md` — add two rows to the Command Reference table; note when to reach for each
- [x] `CLAUDE.md` — document both commands and the spike-vs-learning-test distinction where commands/architecture are described

### Validation
**Automated:**
- [x] `ls dist/codex/skills/my-spike/SKILL.md dist/codex/skills/my-learning-test/SKILL.md` succeeds
- [x] Neither SKILL.md description line starts with `*` (grep check)
- [x] `setup-codex.sh --copy` completes without YAML parse errors
**Manual:**
- [x] README table, CLAUDE.md, and `config.sh` all list both commands consistently

**What We Know Works After This Phase:**
Both commands are usable from Codex and documented; the toolkit is internally consistent.

---

## Environment Setup

**See CLAUDE.md for full environment rules.** Key commands: `./scripts/setup-global.sh`,
`./scripts/build-codex-pack.sh`, `./scripts/setup-codex.sh --copy`.

## Risk Management

**See `design.md#potential-risks` for detailed risk analysis.**

**Phase-Specific Mitigations:**
- **Phase 1:** the live dry run is the mitigation for the close-the-loop reliability risk (B3) —
  fix wording before it propagates.
- **Phase 2:** reuse Phase 1's proven wording to avoid re-introducing the same risk.
- **Phase 3:** place suggestions at existing anchors (not new sections) so they aren't skipped (B2).
- **Phase 4:** the plain-prose description rule avoids the known YAML-parse crash; grep guards it.

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION - Leave empty now]

### Phase 1 Completion
**Completed:** 2026-07-03

**Actual Changes:**
- Created `claude-pack/commands/_my_spike.md` — full staged command (understand → locate/create
  home folder → probe reproducibly with living findings doc → summary-on-top → close the loop),
  header + Related Commands footer + invariants, carrying the reference voice.
- Installed via `./scripts/setup-global.sh`; `readlink ~/.claude/commands/_my_spike.md` → points
  into `claude-pack/`; command resolves as a skill.
- Ran the live dry run (see below). Produced `active/spike-and-learning-test-commands/findings.md`
  and `probe_yaml_description.py` (spike artifacts), and closed the loop into `design.md`.
- Refined `_my_spike.md` Stage 5 wording after the dry run (see Deviations).

**Dry run (target substituted):** The plan's original target (workflow-orchestrator
subagent-invocation spike) no longer exists — we're on `main`/new branch and CURRENT_WORK.md has
no such item. Substituted a genuine in-repo unknown: *does a Codex skill description starting
with `*` break the SKILL.md YAML, and does the build catch it?* This de-risks Phase 4.
- Result: **assumption confirmed** — leading `*`/`**` breaks YAML (alias reference); the build
  emits the description raw and unquoted (`build-codex-pack.sh:250`) and does not catch it.
- Bonus finding: a mid-value colon is **safe** (three shipped descriptions contain them and load
  in Codex) — so the Phase 4 rule is narrow: don't *start* a description with `*`/`**`.
- All four Validation-Check expectations held (folder+scripts+doc; summary-on-top written last;
  reproducible log; back-reference into the triggering doc).

**Issues:** None blocking.

**Deviations:**
- Dry-run target substituted (original no longer exists) — see above.
- Spike artifacts landed in the work-item folder (a work item *was* in play), not a new
  `active/spike-{topic}/`. This is the correct branch of Stage 2, not a deviation from the design.
- Refined Stage 5 close-the-loop wording: the fixed "design → Related Artifacts" mapping was too
  rigid; the useful placement was at the specific bullet the spike resolved. Command now says to
  prefer the in-context spot, falling back to the links section. Fixed before Phase 2 copies it.

### Phase 2 Completion
**Completed:** 2026-07-06

**Actual Changes:**
- Created `claude-pack/commands/_my_learning_test.md` — same staged shape as `_my_spike.md`,
  reusing the Phase-1-proven wording (including the refined Stage 5 in-context back-reference).
  Output rules differ per D3/D4: real tests in the repo's own test dir (agent locates it, Stage 2
  says so explicitly, no hardcoded path, never `.project/`); findings doc in
  `.project/research/{ts}_{topic}.md`.
- Installed via `./scripts/setup-global.sh`; symlink points into `claude-pack/`; resolves as a skill.

**Validation:** Read-through confirms all four Validation-Check points (locate real test dir;
write real tests there; findings doc in `.project/research/`; close the loop). No hardcoded test
path; no `.project/` test location.

**Issues:** None.

**Deviations:** None.

### Phase 3 Completion
**Completed:** 2026-07-06

**Actual Changes:**
- Five planned soft-suggestion edits at their named anchors (see checklist above), each
  distinguishing spike (clear goal → throwaway) from learning-test (fuzzy surface → kept tests),
  each an offer that never halts the pipeline.
- **Scope addition (user request):** wired orchestration awareness. `_my_orchestrate.md` now tells
  the orchestrator to insert a de-risking `spike`/`learning_test` stage via the helper when a bet
  is shaky; `_my_pipeline.md` lists both as optional any-stage de-risking tools;
  `orchestrate-stage.sh` gives them `bypassPermissions` by default (they execute code, like
  `implement`/`pre_pr`). The helper already ran any `/_my_*`, so no other mechanism change was needed.

**Validation:**
- Re-read every edit: soft, at the anchor, distinguishes the two techniques; no existing behavior
  changed beyond the added suggestion.
- `scripts/test_pipeline_sync.sh` passes (shape line untouched).
- `orchestrate-stage.sh run spike --dry-run` composes `/_my_spike …` + preamble with
  `permission-mode bypassPermissions`.

**Issues:** None.

**Deviations:** Extended scope beyond the plan's five files to three orchestration files, at the
user's explicit request. The `bypassPermissions` default for spike/learning_test is a security-
relevant change to local orchestration tooling — consistent with the existing implement/pre_pr
default, flagged to the user.

### Phase 4 Completion
**Completed:** 2026-07-06

**Actual Changes:**
- `codex-overrides/config.sh` — added `["spike"]` and `["learning-test"]` description keys,
  plain prose, `"<action>. Use when <trigger>."`, no leading `*`.
- Ran `build-codex-pack.sh` (25 command skills included) and `setup-codex.sh --copy` (26 installed,
  no YAML parse errors). Both `my-spike/SKILL.md` and `my-learning-test/SKILL.md` built + installed
  to `dist/codex/` and `~/.agents/skills/`.
- `README.md` — two rows after `/_my_research`, distinguishing spike (known assumption, throwaway)
  from learning test (unfamiliar surface, kept tests).
- `CLAUDE.md` — new "De-risking: spike vs learning test" subsection covering both commands, their
  output split, the shared discipline, and the soft pipeline/orchestrate wiring.

**Validation:**
- Both SKILL.md files exist; grep guard finds no leading-`*` description.
- Strict PyYAML parse (the Phase-1 spike's own check, reused): both new skills parse cleanly. The
  3 pre-existing failures (`status`, `pipeline`, `audit`) are the colon-containing descriptions the
  spike already proved are safe in Codex — left untouched, out of scope.
- config.sh, README, CLAUDE.md all list both commands consistently.

**Issues:** None.

**Deviations:** None.

---

**Status**: Draft → In Progress → **Complete**
