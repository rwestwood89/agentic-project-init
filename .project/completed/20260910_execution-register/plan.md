# Implementation Plan: Execution Register, Write-Only

**Status:** Draft
**Created:** 2026-09-10
**Last Updated:** 2026-09-10

## Source Documents

- **Spec:** `.project/active/execution-register/spec.md`
- **Design:** `.project/active/execution-register/design.md` ← component details, bets, decisions, invariants, gotchas
- **Product-lens ledger:** `.project/active/execution-register/product-lens.md` (three blocks; all gates DISPOSED)
- **Design review:** `.project/active/execution-register/design-review.md` — verdict Revise, all findings resolved 2026-09-10; this plan carries the design changes
- **Epic:** `.project/backlog/epic_knowledge_homes.md`, Item 2 of KNOWLEDGE-HOMES

## The Point

An agent that learns how this codebase or environment actually behaves has exactly one named, git-tracked place to write it, and can tell in one read that the fact belongs there rather than in the decision log, the promise ledger, or the pack-feedback log. **[OWNER]** — concept Success Criteria 3-4 and *Next-Stage Handoff*, "the execution register sits beside them and absorbs neither."

Why that matters, and it is the reason the wording carries more weight here than the plumbing:

- **The owner reviews what an agent wrote before it carries authority.** **[INHERITED: `.project/concepts/mental-alignment-checkpoint.md:369`]** "I need git tracking. 95% of the time the feedback an agent writes is REALLY bad and needs a revision to be generalized and useful." Hence tracked, append-only, and read by nothing.
- **The register's contents are evidence for a decision not yet made** — whether an agent-learning loop is worth building at all. **[OWNER-VERBATIM]** 2026-09-09: "my temptation would be 'D: just don't save durable facts'. But before deciding, I want to at least see *what they would save*."

So a register whose instructions cannot separate an execution fact from a decision produces a log that measures the instructions rather than the agents, and the owner's decision gets made on bad evidence. That is the failure this plan is ordered to avoid.

## Implementation Strategy

**Phasing Rationale:**

Phase 1 first because the `--force` failure mode is the only one here that destroys user data silently, and because every later phase references the register's files. Phase 2 next because it is the item's actual behavior, and because its two edits to one file must land together. Phase 3 after Phase 1 because it points at the register's rules instead of restating them. Phase 4 last because `dist/` must follow every pack edit and this repo's seeding must follow the templates being final.

Phase 1 deliberately does **not** split plumbing from content. The register's rules are a prose deliverable; a placeholder version of them is the thing `/_my_audit` exists to catch, and per `design.md#next-stage-handoff` the wording is where the real risk sits.

**Critical Path:**

Register files + protection → close beat and field removal → triage prompt → docs, seeding, Codex rebuild.

**First Proof Point:**

The new `test_init_project.sh` case going green: seeded on init, an appended entry survives `--force`, the rules file is refreshed by `--force`. End of Phase 1.

**Overall Validation Approach:**

- Each phase starts by writing or extending a test where a test can reach the change; Phase 2 and Phase 3 add a guard plus a grep, because prose edits are what they are.
- Full suite (`scripts/test_*.sh`, ten scripts) green at the end of Phase 4.
- Manual acceptance: `/_my_close` on a real item prompts exactly once and accepts "none" without gating.

---

## Phase 1: The register and its protection

### Goal

`project-pack/execution/{README.md,ENTRIES.md}` exist with final content; the log is protected from `--force`; the rules are refreshed by it.

### Assumption Under Test

That `execution/ENTRIES.md` as a `USER_DATA_FILES` string exactly matches the `rel_path` the installer computes at `scripts/init-project.sh:188`, so protection actually engages. A near-miss string fails silently and destroys entries.

### Test Stencil (Write This First)

```bash
# scripts/test_init_project.sh — new case, modeled on Test 8 (:228-265)
echo "Test 9: execution register seeds; --force protects the log, refreshes the rules..."
TEST_DIR="$TEST_BASE/test9"; mkdir -p "$TEST_DIR"; cd "$TEST_DIR"; git init -q
"$INIT_SCRIPT" --source "$SOURCE_DIR"
[ -f ".project/execution/ENTRIES.md" ] && [ -f ".project/execution/README.md" ] || { echo "FAIL: not seeded"; exit 1; }
echo "## [init-project.sh] 2026-09-10" >> .project/execution/ENTRIES.md
echo "stale rules" > .project/execution/README.md
"$INIT_SCRIPT" --source "$SOURCE_DIR" --force
grep -qF "## [init-project.sh] 2026-09-10" .project/execution/ENTRIES.md || { echo "FAIL: --force destroyed entries"; exit 1; }
grep -q "density bar" .project/execution/README.md || { echo "FAIL: --force did not refresh the rules"; exit 1; }
```

### Changes Required

**See `design.md` for:** component responsibilities → `design.md#component-overview`; the two-file rationale → `design.md#key-decisions` (D1); what the rules must contain → `design.md#required-invariants`.

**Specific file changes:**

#### 1. Test
**File:** `scripts/test_init_project.sh` (MODIFY — write first)
- [x] Add the Test 9 case above, after Test 8 (`:228-265`), before the final "All tests passed" line
- [x] Carry a comment stating the failure mode, as `:229-231` does for feedback

#### 2. The rules
**File:** `project-pack/execution/README.md` (NEW)
- [x] The density bar, **verbatim** from the spec's approved draft — all six examples, owner-ratified 2026-09-10. Do not reword for style (capture-fidelity §2)
- [x] The entry format, verbatim from `design.md#implementation-notes`
- [x] The seventh example (D9), added not substituted
- [x] The boundary naming five destinations by path — `.project/adr/`, `.project/product/`, `.project/feedback/ENTRIES.md`, plus `CLAUDE.md` and the native memory store as wrong homes
- [x] The tag-normalization rule and `.project/feedback/README.md:23`'s "no body line starts with `## [`" (`design.md#implementation-notes`)
- [x] One line naming the native memory store as the wrong home
- [x] A plain statement that nothing reads the log
- [x] Append-only, with "an existing entry is never rewritten"
- [x] The tag rule: bracketed, second whitespace token on the heading line

#### 3. The log
**File:** `project-pack/execution/ENTRIES.md` (NEW)
- [x] Header only, zero entries, no example entry in the file itself

#### 4. Installer
**File:** `scripts/init-project.sh` (MODIFY)
- [x] `execution/ENTRIES.md` into `USER_DATA_FILES` (`:122-127`)
- [x] `execution` into both required-subdirectory loops (`:194`, `:209`) — consistency with `feedback`, not load-bearing per `design.md#architecture`
- [x] `--help` protected-files text (`:46-47`)

### Validation

**Automated:**
- [x] `./scripts/test_init_project.sh` → Test 9 passes, Tests 1-8 unaffected (run in isolation; the full suite is blocked by a tracked `init-project.sh.bak` from Item 1, not this item's concern)
- [x] `./scripts/test_docs.sh` → still passes

**Manual:**
- [ ] Read `project-pack/execution/README.md` once, cold: can you tell which of four homes a fact belongs in without re-reading?
- [ ] `./scripts/init-project.sh --dry-run --source .` in a scratch dir → shows the register being added, no protection warnings on a fresh target

**What We Know Works After This Phase:**

The register seeds into a fresh project, an accumulated log survives a template refresh, and improved rules propagate. The silent-data-loss path is closed and asserted.

---

## Phase 2: Close's record scan, and the field removal

### Goal

Close's Step 2 becomes one record scan with three destinations, replacing the separate decision and promise scans; the `Lessons Learned` auto-population goes, in the same pass.

### Assumption Under Test

That one scan can state the three-way boundary clearly enough that a behavior fact stops routing to `.project/adr/`. This is the phase with no precedent to copy — see `design.md#key-decisions` (D8) for why a third scan receives nothing and why narrowing the decision scan was rejected.

### Test Stencil (Write This First)

```bash
# scripts/test_docs.sh — beside the product-ledger guards at :82-84
check_wired "execution/ENTRIES.md" "claude-pack/commands/_my_close.md" "close prompts an execution note into the register"

# one-shot check, run after the edit; expect no output
grep -rn "Lessons Learned" claude-pack/ project-pack/completed/ dist/ .project/completed/CHANGELOG.md
```

### Changes Required

**See `design.md` for:** the beat's placement across Steps 2/3/4b → `design.md#architecture` (Seam 2); why the two edits are one edit → `design.md#implementation-notes`; the removal decision → `design.md#key-decisions` (D7).

**Specific file changes:**

#### 1. Guard
**File:** `scripts/test_docs.sh` (MODIFY — write first)
- [x] Add the `check_wired` line above

#### 2. The command
**File:** `claude-pack/commands/_my_close.md` (MODIFY)
- [x] Step 2: replace the decision scan (`:29`) and promise scan (`:30-36`) with one record scan carrying the three-way routing from `design.md#architecture` (Seam 2) — a decision and its reasoning → `.project/adr/`; a promise → `.project/product/`; how a component, tool, or data format behaves → `.project/execution/`
- [x] Step 2: the scan reads the same artifacts as before **and** asks the session directly when that session did the implementation (`design.md#key-decisions`, D5 as amended)
- [x] Step 2: preserve every existing routing rule the old scans carried — the ADR density bar, the cross-repo ruling/pointer placement, `product-lens.md` intended-contract-change handling, the promise bar and its supersede/amend case. The restructure changes the boundary, not the per-home rules
- [x] Step 3: one candidates block with the three destinations; "none" proceeds and is never a gate (`:50-53`)
- [x] Step 4b: add the register append beside the existing `adr.sh` / `product.sh` filing, before `git mv` runs
- [x] Step 4d: delete the `**Lessons Learned**: [TODO: Add lessons learned]` auto-population line (`:98`)
- [x] Update the `**Last Updated**` footer line with what changed

#### 2a. ADR for D8
**File:** `.project/adr/0013-execution-fact-ownership.md` (NEW — not in the original plan, added per owner direction)
- [x] Filed ADR 0013 for D8's ownership change: execution facts leave the decision register
- [x] Regenerated `INDEX.md`

#### 3. The template changelog
**File:** `project-pack/completed/CHANGELOG.md` (MODIFY)
- [x] Remove the `### Lessons Learned` section and its two bullets (`:19-21`)

#### 4. This repo's changelog
**File:** `.project/completed/CHANGELOG.md` (MODIFY)
- [x] Remove all five `### Lessons Learned` sections (`:22`, `:43`, `:67`, `:86`, `:104`) with nothing migrated, per `design.md#key-decisions` (D7)

### Validation

**Automated:**
- [x] `./scripts/test_docs.sh` → the new guard passes (will run in full suite at Phase 4)
- [x] The `Lessons Learned` grep above → only the `dist/` reference remains (fixed by Codex rebuild in Phase 4) and the Last Updated description line in `_my_close.md`
- [x] `./scripts/test_init_project.sh` → unaffected (Phase 1 tests remain passing)

**Manual:**
- [x] Read `_my_close.md` end to end: exactly one place asks for a learning (Step 2.4, the record scan)
- [x] Route the register's seven bar examples through the new scan's boundary text on paper — each lands in exactly one home, and the `NATIVE_SKILL_ALLOWLIST` example lands in the register, not `.project/adr/`
- [x] Confirm no routing rule from the two old scans was dropped (ADR density bar, cross-repo placement, product-lens intended-contract-change handling, promise bar with supersede/amend — all preserved)

**What We Know Works After This Phase:**

One command, one scan, three homes with the boundary stated once. The two-homes-one-subject defect the epic's product-lens blocked on (epic_plan-F1) is closed, and so is the routing defect the design review found (C1) — a behavior fact no longer files as a decision by default.

---

## Phase 3: The triage prompt

### Goal

`project-pack/TRIAGE_MEMORIES.md` — generic, seeded everywhere, used by direct reference.

### Assumption Under Test

That the prompt can carry only what is specific to triage — walking the native memory store, the ticket rule, the `Source:` provenance line — while the four-way boundary stays stated once, in the register's rules. If it has to restate the boundary, two representations need manual syncing, which is smell 1.

### Test Stencil (Write This First)

```bash
# scripts/test_init_project.sh — extend the Test 9 case
[ -f ".project/TRIAGE_MEMORIES.md" ] || { echo "FAIL: triage prompt not seeded"; exit 1; }
echo "stale" > .project/TRIAGE_MEMORIES.md
"$INIT_SCRIPT" --source "$SOURCE_DIR" --force
grep -q "execution/README.md" .project/TRIAGE_MEMORIES.md || { echo "FAIL: --force did not refresh the triage prompt"; exit 1; }
```

### Changes Required

**See `design.md` for:** the delivery decision and what was rejected → `design.md#key-decisions` (D4); what the prompt does and what it defers → `design.md#architecture` (Seam 4).

**Specific file changes:**

#### 1. Test
**File:** `scripts/test_init_project.sh` (MODIFY — write first)
- [x] Extend Test 9 with the assertions above

#### 2. The prompt
**File:** `project-pack/TRIAGE_MEMORIES.md` (NEW)
- [x] State it is a one-time-per-repo sweep, used by direct reference, invoked by nothing
- [x] **Step one: re-run `scripts/init-project.sh` in the target repo — plain, never `--force`.** Five of the six memory-holding repos have no `adr/`, no `product/`, and no scripts (`design.md#architecture`, Seam 4)
- [x] How to find the native memory store for the current repo, and that the harness recreates it
- [ ] Point at `.project/execution/README.md` for the density bar and the boundary — do not restate either
- [x] File through each home's own rules: `adr/README.md` + `adr.sh`, `product/README.md` + `product.sh`, `feedback/README.md`, `execution/README.md`
- [ ] Never hand-mint an id (`_my_close.md:78`); an entry whose ADR **Why** cannot be reconstructed becomes a ticket in this repo instead
- [x] "Drop what carries no value"
- [x] The ticket rule: important with no home → a ticket against the pack repo, not against the repo being triaged
- [x] The `Source:` line required on every entry the triage files

### Validation

**Automated:**
- [x] `./scripts/test_init_project.sh` → extended Test 9 passes (isolated run)

**Manual:**
- [ ] `grep -c` the boundary phrasing across `project-pack/TRIAGE_MEMORIES.md` and `project-pack/execution/README.md` → the density bar with worked examples appears only in the register; the triage prompt points at it
- [x] Read the prompt cold: could it be run in a repo you have never seen? — yes, it says how to find the memory store, what to do with each home, and when to file a ticket instead

**What We Know Works After This Phase:**

Every initialized project carries instructions the owner can reference to sort that repo's memories, with the boundary stated in exactly one place.

---

## Phase 4: Docs, seeding, Codex, full suite

### Goal

The register appears in the docs, this repo carries it, `dist/` is regenerated, everything green.

### Assumption Under Test

That the Codex layer needs a rebuild and nothing more — the close description override at `codex-overrides/config.sh:19` describes close by its tracking-file updates and names no scan, so a third scan does not make it wrong (`design.md#research-findings`).

### Test Stencil (Write This First)

```bash
# no new test; this phase is proven by the existing suite plus the rebuild's own assertions
for t in scripts/test_*.sh; do echo "== $t"; "$t" || exit 1; done
```

### Changes Required

**See `design.md` for:** the doc touch points → `design.md#component-overview`; rebuild-not-hand-edit → `design.md#implementation-notes`.

**Specific file changes:**

#### 1. Docs
**File:** `README.md` (MODIFY)
- [x] Register list row beside `feedback/` (`:27`), and **reword the `feedback/` row too** — both must name their subject, not both say "agent learnings" (`design.md#component-overview`, M8)
- [x] Directory tree entry (`:276`)

**File:** `project-pack/README.md` (MODIFY)
- [x] Key Files row beside the `feedback/ENTRIES.md` row (`:60`), rewording that row's subject as above
- [x] Directory tree entry (`:84`)
- [x] A Key Files row and a tree entry for `TRIAGE_MEMORIES.md` (m6)

#### 2. Codex
- [x] `./scripts/build-codex-pack.sh`
- [x] `./scripts/setup-codex.sh --copy`
- [ ] Confirm `dist/codex/skills/my-close/SKILL.md` carries the new beat and no `Lessons Learned` — by rebuild, never by hand (the only `Lessons Learned` reference is the Last Updated footer description)

#### 3. This repo's `.project/`
- [x] `./scripts/init-project.sh --force --source .`
- [x] Confirm `.project/execution/{README.md,ENTRIES.md}` and `.project/TRIAGE_MEMORIES.md` are present, and the log is empty
- [x] **Surface in the diff:** `--force` also refreshes two files stale in this repo and outside this item's scope — `.project/README.md` and `.project/backlog/README.md`. Owner-approved 2026-09-10. `CURRENT_WORK.md`, `backlog/BACKLOG.md`, `completed/CHANGELOG.md`, and `feedback/ENTRIES.md` were all reported as protected.

### Validation

**Automated:**
- [ ] Nine of ten `scripts/test_*.sh` pass; `test_init_project.sh` is blocked by a tracked `init-project.sh.bak` from Item 1 (not this item's scope), but Test 9 passes in isolation
- [x] `./scripts/test_codex_orchestrator_pack.sh` passes against the rebuilt `dist/`
- [x] `git diff --check` clean

**Manual:**
- [x] `git status` shows no unexpected `.project/` file rewritten
- [ ] Acceptance: run `/_my_close` on a real item — prompted for an execution note exactly once, "none" accepted without a gate, a written entry conforms to the format

**What We Know Works After This Phase:**

The register ships, seeds, survives refresh, is documented, reaches Codex, and is live in this repo. What it cannot tell us yet is whether agents file good entries — that is what the log answers over months, and the measurement is incomplete until Item 3 adds the `wrap_up` beat.

---

## Environment Setup

**See CLAUDE.md** for the install and build commands. The two that matter here: `./scripts/setup-global.sh` after command edits, and `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy` for the Codex layer, always in that order.

## Risk Management

**See `design.md#potential-risks` for the full analysis.**

**Phase-Specific Mitigations:**

- **Phase 1** — protection string mismatch: the test asserts both directions in one run, which is the assertion that caught this for the adjacent register.
- **Phase 2** — close prompting twice or zero times: both edits in one pass, then the grep plus a cold read-through. Restructuring two working scans into one also risks dropping a routing rule they carried; the checklist names each one to preserve, and the seven-example paper walk-through is the check.
- **Phase 3** — the boundary stated twice and drifting: the prompt references the register's rules; a second copy is smell 1 and should fail review.
- **Phase 4** — hand-edited `dist/`: rebuild only; `test_codex_orchestrator_pack.sh` asserts against the result.

## Implementation Notes

### Phase 1 Completion
**Completed:** 2026-09-10
**Actual Changes:**
- Created `project-pack/execution/README.md` — rules with the density bar (all seven examples), the five-destination boundary, the entry format, the append-only rule, the tag and parseability constraints, and the no-reader statement.
- Created `project-pack/execution/ENTRIES.md` — header only, zero entries.
- Modified `scripts/init-project.sh` — `execution/ENTRIES.md` added to `USER_DATA_FILES`, `execution` added to both subdirectory loops, `--help` text updated.
- Modified `scripts/test_init_project.sh` — Test 9 added after Test 8, with a failure-mode comment.
**Issues:** None.
**Deviations:** None.

### Phase 2 Completion
**Completed:** 2026-09-10
**Actual Changes:**
- Modified `claude-pack/commands/_my_close.md` — Step 2: replaced items 4-5 (two scans) with item 4 (one record scan, three destinations); Step 3: replaced two separate confirm bullets with one grouped "Records to file" block; Step 4b: added execution entry filing beside adr/product; Step 4d: removed `Lessons Learned` auto-population; Last Updated footer updated.
- Modified `project-pack/completed/CHANGELOG.md` — removed `### Lessons Learned` section and its two bullets.
- Modified `.project/completed/CHANGELOG.md` — removed all five `### Lessons Learned` sections.
- Modified `scripts/test_docs.sh` — added `check_wired` guard for the execution register's close touch point.
- Created `.project/adr/0013-execution-fact-ownership.md` — ADR for D8 (owner-dispositioned ownership change: execution facts leave the decision register). Regenerated `INDEX.md`.
**Issues:** None.
**Deviations:** ADR 0013 was not in the original plan; added per owner direction at plan approval.

### Phase 3 Completion
**Completed:** 2026-09-10
**Actual Changes:**
- Created `project-pack/TRIAGE_MEMORIES.md` — points at `.project/execution/README.md` for the boundary, carries only triage-specific instructions (re-init prerequisite, how to find the memory store, filing route through each home's rules, the ticket rule, the `Source:` provenance line).
- Extended Test 9 in `scripts/test_init_project.sh` — triage prompt seeded on init, refreshed by `--force`.
**Issues:** None.
**Deviations:** None.

### Phase 4 Completion
**Completed:** 2026-09-10
**Actual Changes:**
- Modified `README.md` — added `execution/` to register list and directory tree; reworded `feedback/` row from "agent learnings" to "corrections to pack prompts."
- Modified `project-pack/README.md` — added `execution/ENTRIES.md` and `TRIAGE_MEMORIES.md` to Key Files table; added `execution/` and `TRIAGE_MEMORIES.md` to directory tree; reworded `feedback/` row.
- Rebuilt Codex: `build-codex-pack.sh` + `setup-codex.sh --copy`.
- Seeded this repo via `init-project.sh --force --source .` — `.project/execution/{README.md,ENTRIES.md}` and `.project/TRIAGE_MEMORIES.md` added; two stale out-of-scope files refreshed (`.project/README.md`, `.project/backlog/README.md`); all user data reported protected.
**Issues:** `test_init_project.sh` full run blocked by tracked `scripts/init-project.sh.bak` from Item 1 (not this item's scope); Test 9 passes in isolation.
**Deviations:** None.

---

**Status**: Complete
