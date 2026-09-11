# Epic: Agent Knowledge Homes

**Epic ID**: KNOWLEDGE-HOMES
**Status**: Complete
**Priority**: P1
**Created**: 2026-09-09
**Estimated Effort**: 2.5-4 days

---

## Executive Summary

Retire the pack's hidden memory and transcript machinery, give execution facts a single tracked home that ships write-only as a deliberate test, and reshape session bookkeeping so `CURRENT_WORK.md` holds only current state while recent history reaches the agent through a bounded read. The epic removes four dead or misdirecting always-on references, deletes an entire subsystem that 1M context windows made obsolete, and produces the evidence needed to decide whether an agent-learning loop is worth building at all.

**Critical Success Factor**: after this epic, every place an agent is told to write knowledge points at a tracked file that exists, and the execution register's contents answer whether agents save anything worth reading.

---

## Source Documents

- `.project/concepts/agent-knowledge-and-enforcement.md` — concept (owner decisions resolved 2026-09-09)
- `.project/research/20260818-151200_anchor-on-the-point-inventory.md` — research (rule enforcement inventory; hook options; feeds the deferred thread)
- `.project/adr/0001-decision-records-convention.md` — decision record (the current-state-doc rejection this epic works with rather than against)
- `.project/adr/0002-adr-touch-points.md`, `.project/adr/0008-product-ledger-touch-points.md` — decision records (the wrap-up write-duty rejection this epic deliberately departs from)
- `.project/completed/20260826_feedback-capture-file/spec.md` — spec (the adjacent register's scope and its reserved read-back step)

---

## Why This Epic?

**Current State**:

- Two hidden memory stores. The native one is untracked; `.project/memories/` is gitignored, empty, and served by the pack's only wired hook. Its pack-prompt corrections are dispositioned in place rather than migrated, two of them as direct pack edits, and the remaining symlink fact already exists in CLAUDE.md (`.project/completed/20260910_retire-hidden-memories/spec.md`, *Why nothing migrates*).
- An entire subsystem serving them: four commands, one agent, two Python tools, two hook scripts, both PreCompact registrations, and a `.hook-paths.json` indirection. It exists to compensate for running out of context and disliking autocompaction — a problem 1M context windows and better compaction removed.
- Four always-on or command references point at things that do not exist or never did: `context-loading.md:9` (auto-memory), `_my_implement.md:152` and `_my_audit.md:92` (a `feedback_*` naming convention never used), and `_my_wrap_up.md:37-54` (a "Recent Decisions" section that is not in the file it targets).
- `example-rules.md` — 31 lines of template boilerplate, never edited, auto-loaded into every session and every Codex run.
- `CURRENT_WORK.md` mixes current state with append-only history. 227 lines, "Recently Completed" reaching back to 2025-12-30, trimmed exactly once in eight months by a wrap-up acting without instruction.
- No home for a fact an agent learned by doing. Three slots gesture at it — wrap-up's auto-memory step, CHANGELOG's `Lessons Learned` field, and the template's "Any notable learnings" bullet — and all three are unowned and unread.

**Future State**:

- Nothing agent-written lives outside git. The four hidden feedback entries are dispositioned in place rather than migrated, two of them as direct pack edits (`.project/completed/20260910_retire-hidden-memories/spec.md`, *Why nothing migrates*).
- The pack has no hooks and no Python. A clean slate for the deferred enforcement thread.
- Execution facts have one named home, shipping write-only with instructions and no reader, so its contents decide whether a read path is ever built.
- `CURRENT_WORK.md` holds Active Work and Up Next. Nothing in it accumulates, so no retention rule is needed; recent completions reach the agent through a bounded read of the newest CHANGELOG entries.
- `wrap_up` writes records and never documents, and does not commit unasked.

---

## Success Criteria

- [x] No pack instruction points at either memory store, and `.project/memories/` and its gitignore line are gone.
- [x] The pack contains no hooks, no hook registrations, and no Python tooling; current installers create none, while setup, update, and uninstall remove exact legacy pack assets without removing user-owned files.
- [x] `.project/feedback/ENTRIES.md` is unchanged, and the two hidden corrections that were still live are fixed directly in `_my_handoff.md` and `working-voice.md` (`.project/completed/20260910_retire-hidden-memories/spec.md`, *Why nothing migrates*).
- [x] `example-rules.md` is absent from `claude-pack/rules/`, `~/.claude/rules/`, and the generated `dist/codex/AGENTS.md`.
- [x] An agent that learns something durable has one named place to write it, is prompted to do so at `close` and at `wrap_up`, and is handed no existing entries.
- [x] `CURRENT_WORK.md` and its template hold only Active Work and Up Next, in the live file and in `project-pack/`.
- [x] Session boot shows recent completions at a cost that does not grow with the archive.
- [x] `wrap_up` touches no file under `docs/` and makes no commit without being asked.
- [x] Every affected reference in `README.md`, `docs/guide.md`, and the Codex build is updated, and the affected test scripts pass — `test_global_setup.sh`, `test_rename.sh`, `test_init_project.sh`, `test_docs.sh`, `test_uninstall.sh`, and `test_codex_orchestrator_pack.sh`.
- [x] The user's own `PreToolUse` hook in `~/.claude/settings.json` is present and unmodified after the pack's hooks are removed.

---

## Epic Strategy

**Value Delivery Path**:

- Removing dead machinery comes first and delivers value alone: four misdirecting references stop misdirecting, one rule file stops costing every session, and a whole subsystem stops needing maintenance. Nothing downstream depends on this being right, which makes it the safest place to start.
- The register ships next, because it is the only item that produces new evidence rather than removing old cost. The sooner it is writing, the sooner its contents can answer the question the epic exists to answer.
- Session bookkeeping lands last, because it is the one item that needs both — the memory step gone, and the register in place to be written to.

**Critical Path**:

- Item 1 → Item 2 → Item 3, strictly sequential. All three touch `_my_wrap_up.md`, so ordering them avoids three items editing one file.

**Decomposition Logic**:

- The cut lines follow what can be proven. Item 1 is proven by absence — a grep for the removed names returns nothing and the installers are clean. Item 2 is proven by an agent writing an entry when prompted. Item 3 is proven by a session booting from the new shape and a wrap-up writing the right records.
- `example-rules.md` folds into Item 1 rather than standing alone. On its own it is a 20-minute deletion, which the guide's micro-task anti-pattern rules out; it belongs with the other dead-content removal because it shares the same verification — rebuild the Codex pack, re-run the installer, run the doc tests.
- Composition is not a separate item. The composed behavior — a session boots, works, records, and the next session boots correctly — is Item 3's done state, because Item 3 is the item that closes the loop.
- What stays vague until spec time: the register's density bar and entry format, where its instructions physically live so an agent meets them with no read path, the bound on the history read, and how a reader distinguishes the two CHANGELOG entry weights.

---

## Backlog Items

### Item 1: Retire dead pack content ✅

**Type**: Implementation
**Effort**: 1-1.5 days (spec 1h, design 1h, plan 1h, execute 5-7h) — revised upward 2026-09-09 after the product-lens found ~32 stale documentation lines across three files, against the two the estimate originally assumed
**Dependencies**: None
**Required Reading**:
- `.project/concepts/agent-knowledge-and-enforcement.md` — carries the owner decisions, the reason the transcript stack is obsolete, and what the five hidden entries actually contain

**Objective**: Delete the memory and transcript subsystem, `example-rules.md`, and every reference to them. The four hidden feedback entries are dispositioned in place rather than migrated, two of them as direct pack edits (`.project/completed/20260910_retire-hidden-memories/spec.md`, *Why nothing migrates*).

**Why This Is One Work Item**:
- Every deletion here shares one verification cycle: rebuild the Codex pack, re-run the installer, sweep for orphaned references, run the affected tests. Splitting them means paying that cycle three times.
- The four stale references are not separable from the deletions that make them stale. A reference to auto-memory is only wrong once auto-memory is gone.
- `example-rules.md` is a 20-minute deletion on its own, which the guide's micro-task anti-pattern rules out. It belongs here because it is the same kind of change — dead always-on content — verified the same way.

**In Scope (High Level)**:
- Delete the commands, agent, hooks, and Python tooling: `_my_capture`, `_my_memorize`, `_my_recall`, `_my_review_compact`, the `recall` agent, `capture.sh`, `precompact-capture.sh`, `parse-transcript.py`, `query-transcript.py`.
- Remove both PreCompact registrations, `.hook-paths.json`, and all hook install/uninstall logic across `setup-global.sh`, `init-project.sh`, `uninstall-global.sh`, and `uninstall-project.sh`.
- Delete `.project/memories/` (and the `project-pack/memories/` template), its `.gitignore` line, and `memories/index.json` from the `USER_DATA_FILES` list.
- Delete `claude-pack/rules/example-rules.md` and its installed symlink.
- Update the stale references: `context-loading.md:9`, `_my_implement.md:152`, `_my_audit.md:92`, the `_my_wrap_up.md` auto-memory step, and `docs/guide.md:136`. In `context-loading.md`, the product-ledger skim at `:6-7` **survives** — ADR 0008 places that read in this file as a recorded invariant.
- Sweep the documentation that presents the subsystem as shipped, not just the two lines first identified. Verified counts, 2026-09-09: 16 keyword lines in `README.md` (including the whole "Hook Not Running" troubleshooting section at `:408-421`, well beyond the `:137` legacy section), 10 in `docs/STRUCTURE.md` (the `hooks/`, `agents/`, and `memories/` entries in both directory trees, plus the "What Ships" list), and 6 in `CLAUDE.md`. This is a distributable template — a new user follows README's install and troubleshooting text.
- Delete the now-empty `claude-pack/hooks/` directory and the `.claude/hooks -> ../claude-pack/hooks` symlink, which dangles once its four files are gone.
- Shrink the three Codex exclusion lists in `codex-overrides/config.sh` and remove the dead hook-translation path in `build-codex-pack.sh`.
- Fix the two still-live corrections directly in the pack instead of migrating them: `_my_handoff.md` gains a pause-and-wait-for-instruction step, `working-voice.md` gains a line on presenting a decision in prose rather than through the multiple-choice question tool (`.project/completed/20260910_retire-hidden-memories/spec.md`, *Why nothing migrates*).
- Sweep `scripts/test_*.sh` for hook and memory assertions. `test_global_setup.sh` and `test_rename.sh` mention hooks today; `test_init_project.sh` covers the user-data list; `test_docs.sh` carries wired-guards for doc mentions; `test_codex_orchestrator_pack.sh` asserts against `dist/`.

**Non-Goals / Out of Scope**:
- **The user's own `PreToolUse` hook.** `~/.claude/settings.json` carries `auto-approve-paths.sh`, which is not pack content and must survive untouched. The existing uninstaller is surgical, but `setup-global.sh` merges hook config with a shallow `jq '.[0] * .[1]'` that replaces the whole `.hooks` object — the kind of merge that eats a neighbour.
- Any change to `_my_wrap_up.md` beyond removing the auto-memory step. Its final shape is Item 3.
- Creating the execution register, or deciding where execution facts go. That is Item 2.
- Preserving conversation history in any form. Owner-stated and accepted.

**Success / Done State**:
- [x] A grep of executable and shipped product surfaces for the removed command, hook, agent, and script names returns nothing except targeted legacy-cleanup code and its tests. Durable `.project/` records remain historical evidence and are excluded.
- [x] `grep -in "hook\|memories\|recall\|transcript\|auto-memory" README.md docs/STRUCTURE.md CLAUDE.md docs/guide.md` returns no line presenting any of them as a shipped component, and `ls -L .claude/hooks` fails because the symlink is gone rather than dangling.
- [x] `context-loading.md` still sends every session to skim the product ledger, per ADR 0008.
- [x] `setup-global.sh` and `init-project.sh` install no hooks against a fresh target, both uninstallers run clean, and the user's `PreToolUse` entry is still present and unmodified in `~/.claude/settings.json` afterwards.
- [x] `dist/codex/AGENTS.md` has no `example-rules` section, and the Codex exclusion lists no longer name deleted files.
- [x] `.project/feedback/ENTRIES.md` is unchanged, `_my_handoff.md` and `working-voice.md` carry the two still-live corrections, and the native memory directory is no longer written by any pack instruction.
- [x] The affected test scripts pass.

**Deliverables**:
- `.project/completed/20260910_retire-hidden-memories/spec.md`
- `.project/completed/20260910_retire-hidden-memories/plan.md`
- Two pack edits carrying the still-live corrections: `claude-pack/commands/_my_handoff.md` and `claude-pack/rules/working-voice.md`

**Location**: `.project/completed/20260910_retire-hidden-memories/`

---

### Item 2: Execution register, write-only ✅

**Type**: Implementation
**Effort**: 0.5-1 day (spec 1-2h, design 1h, plan 1h, execute 2-3h)
**Dependencies**: Item 1
**Required Reading**:
- `.project/concepts/agent-knowledge-and-enforcement.md` — the write-only rationale, the candidate density bar, the four-way division of responsibilities, and the 95% constraint
- `.project/feedback/README.md` — the shape precedent: a register with rules, a log, and no reader
- `.project/completed/20260826_feedback-capture-file/spec.md` — what the adjacent register deliberately left out, and the reserved read-back step

**Objective**: Give execution facts one tracked home that ships with instructions and no reader, and prompt the write at `close`.

**Why This Is One Work Item**:
- The register and its first write beat are one behavior. A register nothing writes to is not testable, and a beat with no register to write to is broken.
- Seeding through `project-pack/` and protecting the log from `--force` are the same change as creating it — the filename becomes a contract the moment the protection list names it.

**In Scope (High Level)**:
- The register: a directory with a README stating what belongs there, the density bar, the entry format, and plainly that nothing reads it.
- The write beat in `_my_close.md`, beside the existing ADR and promise scans.
- **Remove the `Lessons Learned` field entirely** (owner, 2026-09-09: "remove this. I do not want this at all"). It is the second home the product-lens blocked on. Three places: the instruction at `claude-pack/commands/_my_close.md:98`, the example entry in `project-pack/completed/CHANGELOG.md:19`, and the five live sections in `.project/completed/CHANGELOG.md`. The Codex copy at `dist/codex/skills/my-close/SKILL.md:105` follows from a rebuild.
- The live sections are stripped and nothing migrates into the register. **Amended 2026-09-10, owner: "ok yeah option 1, ship empty."** The log ships empty so every entry it holds was agent-chosen. The clause "nothing real is deleted without a home" is discharged, not waived: the one section meeting the density bar is already recorded at `scripts/test_init_project.sh:229-231`, two are the literal `[TODO: Add lessons learned]`, two are below-bar taste notes (`.project/completed/20260910_execution-register/spec.md`).
- A prompt the owner can take to any repo to triage that repo's native memory entries into `.project/` homes, filing each as a decision, promise, pack-prompt correction, or execution fact, and raising a ticket in this repo for anything important that fits no home. **Added 2026-09-10, owner.** Its delivery form is a design call.
- Seeding in `project-pack/` and `init-project.sh`, with the log added to `USER_DATA_FILES` so `--force` never clobbers it.
- Test coverage for seeding and user-data protection.

**Non-Goals / Out of Scope**:
- **Any read or discovery path.** Owner decision: the write ships alone so its contents can decide whether a reader is worth building.
- The `wrap_up` write beat. Item 3 owns every change to that file.
- Ids, a lifecycle script, or a generated index. The inherited standard for the adjacent register was a file with a header; revisit only if the test earns it.
- Agent-backfilled entries. The template and this repo's log ship empty and no agent seeds them. **Amended 2026-09-10, owner:** the owner-run triage is a deliberate exception and files owner-reviewed facts into other repos' logs; a provenance line on each triage-filed entry is what keeps the result readable.

**Success / Done State**:
- [x] An agent running `/_my_close` on a real item is prompted for an execution note and produces a conforming entry, or records that there was nothing to save.
- [x] Nothing in the pack hands an agent the register's existing contents.
- [x] `init-project.sh` seeds the register in a fresh project, and `--force` leaves an existing log untouched.
- [x] `test_init_project.sh` covers both the seeding and the protection.
- [x] `grep -rn "Lessons Learned" claude-pack/ project-pack/completed/ dist/ .project/completed/CHANGELOG.md` returns nothing, and running `/_my_close` prompts for a learning exactly once. **Corrected 2026-09-10:** scoped to `project-pack/completed/` — over all of `project-pack/` this could never pass, since `project-pack/epic_template.md:144` carries an epic-retrospective section Item 3 keeps.

**Deliverables**:
- `.project/completed/20260910_execution-register/spec.md`
- `.project/completed/20260910_execution-register/design.md`
- `.project/completed/20260910_execution-register/plan.md`
- `.project/completed/20260910_execution-register/product-lens.md`
- The register directory in `project-pack/` and `.project/`
- `project-pack/TRIAGE_MEMORIES.md` → seeded to `.project/TRIAGE_MEMORIES.md` — the per-repo memory-triage prompt (added 2026-09-10, owner; generic template, direct reference, not a command or skill)

**Location**: `.project/completed/20260910_execution-register/`

---

### Item 3: Session bookkeeping ✅

**Type**: Implementation
**Effort**: 1-1.5 days (spec 2h, design 2h, plan 1h, execute 4-6h)
**Dependencies**: Items 1 and 2
**Required Reading**:
- `.project/concepts/agent-knowledge-and-enforcement.md` — wrap-up's final shape, the cheap-records-versus-tight-documents test, and the bound-the-read decision
- `.project/adr/0001-decision-records-convention.md` — the current-state-doc rejection this item works with rather than against
- `.project/adr/0002-adr-touch-points.md` and `.project/adr/0008-product-ledger-touch-points.md` — the wrap-up write-duty rejection this item departs from, and the concept's reviewer note explaining why

**Objective**: Make session end write records and never documents, cut `CURRENT_WORK.md` to current state, and give session boot recent history at a cost that does not grow with the archive.

**Why This Is One Work Item**:
- This is one behavior end-to-end: what a session writes when it finishes, and what the next session reads when it starts. Splitting the write side from the read side leaves the read side unprovable.
- One item owns `_my_wrap_up.md`'s final shape. Three items each editing that file is worse than one item landing it once.
- The CHANGELOG's new lighter entry weight exists only because wrap-up writes it. The two cannot be spec'd apart.

**In Scope (High Level)**:
- `_my_wrap_up.md`'s final shape: the docs step deleted, the `CURRENT_WORK.md` step narrowed, a light CHANGELOG entry added for work that skipped `close`, the execution-note beat added, and the commit changed to stage-and-show.
- `CURRENT_WORK.md` and `project-pack/CURRENT_WORK.md` cut to Active Work and Up Next, including the orphaned "Any notable learnings" bullet.
- The session-start read in `context-loading.md` extended to the newest CHANGELOG entries, bounded so the cost does not grow with the file. The product-ledger skim at `:6-7` survives and the CHANGELOG read goes after it, so the ledger read does not start reading as optional — ADR 0008 governs that line.
- Sizing input carried from the product-lens (epic_plan-F4): CHANGELOG holds 5 entries against 13 completed items, and its entries run ~20 lines to the old section's ~4-6. A small N covers fewer completions than the section it replaces. Size N against that, or have `close` write a headline the boot read takes instead. **Settled 2026-09-10, owner:** the boot read takes the newest 5 entries, heading through `Summary`, skipping `Deliverables` — about 25 lines. `close`'s entry is unchanged, so the headline alternative is not taken. The coverage residual is stated in the spec rather than closed.
- The two CHANGELOG entry weights, and how a reader tells them apart.
- Codex rebuild for the wrap-up skill, and its description override if the scope change makes the current one wrong.

**Non-Goals / Out of Scope**:
- A retention or pruning rule. The bound sits at the read, so nothing accumulates and nothing needs pruning.
- Backfilling the nine completed entries with no CHANGELOG counterpart. Owner-stated: eight months old and reachable from git log and `completed/`.
- Any change to what `close` writes to CHANGELOG beyond the field Item 2 removed. Its structured entry keeps Type, Duration, Summary, and Deliverables.
- The `## Lessons Learned (Post-Completion)` section in `epic_template.md`. Different artifact, different purpose — an epic-level retrospective, not close's per-item CHANGELOG field. The owner's removal was aimed at the CHANGELOG field.
- Editing the archived `20260701_close-command/` spec and design, which record the original decision to use a placeholder. Those are immutable historical entries.
- Touching `docs/` from wrap-up, in any form. That is the point of the item.

**Success / Done State**:
- [x] A session boots from the new shape, does work, runs wrap-up, and the next session sees current work plus recent completions — the composed behavior this epic is parts of. **Mechanism verified 2026-09-11:** the bounded read returns the newest five entries including both written at close-out. A cold-session observation was not run; see `audit.md` *Not exercised*.
- [x] `wrap_up` writes no file under `docs/` and makes no commit without being asked.
- [x] Work that finishes without going through `close` appears in the boot history, in the lighter entry shape. Exercised 2026-09-11 by the gates-to-flags entry.
- [x] `CURRENT_WORK.md` and its template contain no history section — `Recently Completed` and `Session Notes` are gone from both. **Amended 2026-09-10, owner:** Active Work's growth, in item count and in entry depth, is out of scope and stays unbounded (`.project/completed/20260911_session-bookkeeping/spec.md` Non-Goals). As originally worded this checkbox could not be honestly ticked.
- [x] The history read's cost is bounded and stated, and does not change as `completed/CHANGELOG.md` grows.

**Deliverables**:
- `.project/completed/20260911_session-bookkeeping/spec.md`
- `.project/completed/20260911_session-bookkeeping/design.md`
- `.project/completed/20260911_session-bookkeeping/plan.md`
- Rewritten `_my_wrap_up.md`, reshaped `CURRENT_WORK.md` and template, updated `context-loading.md`

**Location**: `.project/completed/20260911_session-bookkeeping/`

---

## Product-Lens

```
## epic_plan — 2026-09-09 — rev .project/backlog/epic_knowledge_homes.md @ 78ea3b5

Point (re-derived): Each class of agent-written knowledge has exactly one named, git-tracked
home, and a cold agent's boot read still shows current work plus what just shipped at a bound
that does not grow with the archive.
  [source: .project/concepts/agent-knowledge-and-enforcement.md — Owner's Words + Success
   Criteria 1-8, decisions 2026-09-09; grade: owner]
  [secondary: docs/guide.md "Why this exists" / "Between sessions" (INHERITED);
   .project/adr/0008 + 0002 (agent/ratified)]

Falsifier: after the epic, one command prompts an agent to record a learning in two different
places; or a fresh session's boot read cannot name the most recent completed work without
opening completed/ or git log; or README/docs still present hooks, memories, or the recall
agent as shipped components.

Findings:

- epic_plan-F1 [DO] The epic names three abandoned learning slots as the problem, closes two,
  and explicitly rules the third out of scope — so `/_my_close` ends up prompting for an
  execution note (Item 2) while the same command still auto-populates
  `**Lessons Learned**: [TODO: Add lessons learned]` (claude-pack/commands/_my_close.md:98),
  kept unchanged by Item 3's non-goal. Two homes, one subject, one command, one run. Same
  subject confirmed against live data: the newest CHANGELOG entry's Lessons Learned is
  "Separate refreshable instructions from append-only user data when `--force` updates
  templates" — an execution fact by the concept's own test. Aggravated by Item 3 wiring the
  newest CHANGELOG entries into the boot read while two live entries carry the literal
  `[TODO: Add lessons learned]` (.project/completed/CHANGELOG.md:44, :68).
  — source: concept Success Criterion 3 ("one named place"), US-2 ("so I do not file it in
    three places or none"), Key Concept 1, Problem Statement's indictment of
    _my_close.md:98 (owner) — disposition: BLOCK
  Falsifier: run `/_my_close` after the epic; the agent is asked for a learning twice, and
  `grep -n "Lessons Learned" claude-pack/commands/_my_close.md` still returns the TODO default.
  DISPOSITIONED 2026-09-09, owner: "remove this. I do not want this at all." The field is
  deleted outright — not reduced to a pointer, and not kept in place of the register's close
  beat. Claimed by Item 2, which already edits _my_close.md. Item 3's non-goal reworded. Live
  section content that meets the register's density bar migrates before the sections are
  stripped. RESOLVED.

- epic_plan-F2 [DO] Item 1 deletes hooks, the transcript tooling, the recall agent, and the
  memory stores, but named only `README.md:137` and `docs/guide.md:136` as doc updates.
  `docs/STRUCTURE.md` and `CLAUDE.md` were in no item's scope, and both present the removed
  subsystem as shipped. `claude-pack/hooks/` itself and the `.claude/hooks -> ../claude-pack/hooks`
  symlink were also unnamed, and the symlink dangles after Item 1. This is a distributable
  template — a new user follows README's install and troubleshooting text to a hook that no
  longer exists.
  — source: README "What's Included" / "Project Structure After Init" / Troubleshooting,
    docs/STRUCTURE.md "What Ships" (INHERITED/aspirational) — disposition: DISPOSE-and-proceed
  Verified 2026-09-09: 16 keyword lines in README.md, 10 in docs/STRUCTURE.md, 6 in CLAUDE.md,
  plus the auto-memory references. Item 1 scope and estimate corrected; done state now greps
  all three files. RESOLVED.

- epic_plan-F3 [DO] Items 1 and 3 both edit `context-loading.md`'s session-start list, and
  neither said the product-ledger skim at :6-7 survives. ADR 0008 places that read in exactly
  this file as a recorded invariant. The epic cited 0008 twice but only for the wrap-up
  write-duty departure.
  — source: .project/adr/0008-product-ledger-touch-points.md, status active, provenance
    "[AGENT] (ratified by owner, 2026-08-09)" (agent/ratified) — disposition: DISPOSE-and-proceed
  Resolved 2026-09-09: both items now state the ledger skim survives, and Item 3 places the
  CHANGELOG read after it. RESOLVED.

- epic_plan-F4 [DO] Premise conflict, surfaced not resolved (capture-fidelity §4). Item 3
  deletes Recently Completed while its replacement is measurably thinner at the moment of the
  cut: CHANGELOG holds 5 entries against 13 completed items (nine have no counterpart; backfill
  is owner-excluded), and its entries run ~20 lines to the old section's ~4-6, so a small N
  covers fewer completions than today. The owner authorized both halves, but the owner's reason
  for the section is owner-verbatim: "reading it gives a better picture of the state of things."
  Declining to create new records and destroying existing ones are different acts.
  — source: concept criterion 6 mechanism vs. owner-verbatim reason; counts measured
    (AGENT/INFERRED) — disposition: DISPOSE-and-proceed, surface to owner at spec time
  Carried into Item 3's spec as a named sizing input. OPEN by design.

Smells fired:
- Smell 1 — two representations must be manually kept synchronized. The execution register and
  the CHANGELOG Lessons Learned field become two homes for one subject, written by one command
  in one run, with nothing keeping them consistent. Fires on epic_plan-F1.
- Smell 5 — a compatibility requirement preserves behavior that contradicts the reason the
  product exists. Item 3's "Its structured entry stays as it is" is that requirement seen from
  the other side. Same defect as F1.

Checked, no finding: removing the transcript and memory tooling costs the product nothing the
SOURCES promise. The one user-visible capability lost is "salvaging content after an unexpected
compaction" (README:139), disposed twice at owner grade. Giving wrap_up a write duty against
ADR 0002/0008's rationale is likewise dispositioned: owner agreed 2026-09-09 and waived a new ADR.

Gate: BLOCKED (epic_plan-F1) → CLEAR (F1 dispositioned by owner 2026-09-09)
```

**Gate status: CLEAR.** F1 was dispositioned at owner grade — the `Lessons Learned` field is removed outright, and Item 2 claims the fix. F2 and F3 were resolved by correcting item scope. F4 stays open by design and is carried into Item 3's spec as a named sizing input, per capture-fidelity's surfacing law. `_my_spec` carries F4 into Item 3's per-item ledger.

---

## Dependencies

**External**: none.

**Internal**:

- `EPIC-003` (Skills as Continual Learning Mechanism, P2, Backlog) — **[OWNER] 2026-09-09: EPIC-003 stays open, and this epic is its first slice.** EPIC-003 targets the same problem with a read-write learning loop, retrospectives, and hook-based session-end capture. This epic delivers the write half; the loop stays parked behind what the register's contents show. EPIC-003's note about integrating with `/capture` and `/memorize` is dead — this epic deletes both.
- `AOP-005` (Force contemplation on outcomes, P0, Backlog) — **[OWNER] 2026-09-09: this epic runs first, then AOP-005.** AOP-005 already holds the hook-plus-subagent mechanism work, including the three implementation options and the state-file activation pattern. The concept's fifth thread is the same mechanism aimed at a different rule, so it is tracked there rather than duplicated here. This epic leaves the pack with zero hooks, which is the clean slate AOP-005 starts from.

**Item Dependency Graph**:

```
Item 1 (no dependencies)
  └─> Item 2 (depends on Item 1)
        └─> Item 3 (depends on Items 1 and 2)
```

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| The register stays empty because nothing told agents it exists, not because nothing was worth saving | High | The write beats sit at `close` and `wrap_up`, the trigger design that produced 12 ADR entries; owner-stated that the test needs instructions, just not a read path |
| The register fills with junk that has to be read to be judged | Med | Owner review before any entry carries authority; the 95% rule is a recorded constraint, and a junk-filled register is itself a valid test result |
| A test confined to this repo measures the wrong thing — a meta-project generates few execution facts | High | Register ships in `project-pack/`, so it reaches every initialized project; owner-stated that this repo's usage is not a good indicator |
| Removing hooks and installers breaks the installer scripts or leaves orphaned settings entries | Med | Both uninstallers are surgical today and must stay consistent; `test_init_project.sh` and `test_docs.sh` cover the seams |
| Removing the pack's hooks clobbers the user's own `PreToolUse` hook in `~/.claude/settings.json` | High | `auto-approve-paths.sh` is not pack content and serves the teasp and Julia workspaces. The uninstaller is surgical, but `setup-global.sh` merges with a shallow `jq '.[0] * .[1]'` that replaces the whole `.hooks` object. Item 1's done state asserts the entry survives |
| Deleting the transcript tooling loses access to old conversation history | Low | Owner-stated and accepted: never really used, and 1M context plus better compaction removed the need |
| Bounding the history read by lines truncates an entry mid-sentence, or by entries costs more than it buys | Med | Spec decides entries-versus-lines; CHANGELOG entries run ~20 lines against ~4-6 for the old ones, so N stays small or `close` writes a headline |

---

## Timeline

**Total Effort**: 2.5-4 days

| Item | Effort | Dependencies |
|------|--------|--------------|
| Item 1: Retire dead pack content | 1-1.5 days | None |
| Item 2: Execution register, write-only | 0.5-1 day | Item 1 |
| Item 3: Session bookkeeping | 1-1.5 days | Items 1, 2 |

No parallelism is available. All three items touch `_my_wrap_up.md` or its immediate neighbours, so the path is strictly sequential.

---

## Lessons Learned (Post-Completion)

**What Went Well**:
- All three items delivered what they set out to. The subsystem is gone, the register ships and is protected, and session bookkeeping works end to end.
- The bounded boot read proved itself at close-out: writing the two final entries and running the `awk` returned them at the top of the excerpt.

**What Could Improve**:
- The pipeline's own machinery cost more than the work did. Two mechanisms were responsible: tests that grep command prompt files to prove an instruction exists, and the product-lens `BLOCK` gate treated as a hard stop on close, PR, and certification. The first cannot work — reword a prompt line and the grep either breaks for nothing or passes while the instruction is gone. The second let a stale review note lock an item whose code was already correct. Both were removed on 2026-09-11: six assertions deleted from `test_docs.sh`, and the gate changed from a stop to a flag in `_my_close`, `_my_pre_pr`, and `_my_audit`.
- Every item in this epic got flagged by an audit, and most findings were about the paperwork rather than the product. An epic about simplifying prompts nearly failed to close on its own ceremony.

**Surprises**:
- Item 2's audit said Needs Work and its ledger said BLOCKED while the code had already been fixed. Nobody updated the records, and the gate that was supposed to catch a real problem instead blocked a finished one.

---

**Last Updated**: 2026-09-11
**Next Action**: None. All three items are closed. The branch is `knowledge-homes`; test before PR.
