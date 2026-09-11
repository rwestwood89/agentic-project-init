# Implementation Plan: Session Bookkeeping

**Status:** In Progress
**Created:** 2026-09-10
**Last Updated:** 2026-09-10
**Branch:** mental-model-reviewer

## Source Documents

- **Spec:** `.project/active/session-bookkeeping/spec.md`
- **Design:** `.project/active/session-bookkeeping/design.md` ← component detail, bets, decisions, invariants, gotchas
- **Review:** `.project/active/session-bookkeeping/design-review.md`, dispositions in `.project/active/session-bookkeeping/product-lens.md`
- **Epic:** `.project/backlog/epic_knowledge_homes.md` — Item 3 of KNOWLEDGE-HOMES

## The Point

Session end must write cheap records and never curated documents, and a cold agent's boot read must still show current work plus what just shipped, at a cost that does not grow with the archive. **[OWNER]** — concept Success Criteria 5, 6 and 7. The reasons are stated verbatim: documents valued for staying tight are damaged by session-summary edits, while "feedback" and "changelog" are cheap record; and completion history stays at boot because **[OWNER-VERBATIM]** "reading it gives a better picture of the state of things. Knowing we just edited something or closed out an epic could be super helpful context."

This is the last of three items. Item 1 removed the untracked homes, Item 2 built the one that was missing, and this item is where the every-session command stops pointing at the wrong homes and starts feeding the boot read that makes the loop visible. The epic's obligation in one line: every place an agent is told to write knowledge points at a tracked file that exists.

## Implementation Strategy

**Phasing rationale.** The item is almost entirely prose edits, so grep can verify nearly all of it. The exception is whether a real session runs the new boot read and comes away oriented — design bet B2, the one claim no test reaches. Phase 1 therefore does the read side alone and stops to prove it, before any of the write-side work depends on it.

**Critical path.** Read side → wrap-up rewrite → cleanup sweep → Codex rebuild → behavioral pass. Phases 1 and 2 are the only ones with judgment in them; 3 and 4 are mechanical; 5 is acceptance.

**First proof point.** End of Phase 1: with the history sections gone, a fresh session boots and names the most recent completed work from the bounded read alone.

**Overall validation.** Each phase writes its own guard and makes it pass inside that phase, so the suite is never left red between phases. `./scripts/test_docs.sh` is the home for every new guard — it already carries the ADR 0008 touch-point guards this work extends (`scripts/test_docs.sh:80-92`).

---

## Phase 1: The read side

### Goal

Cut `CURRENT_WORK.md` to current state, wire the bounded CHANGELOG read into session boot, and state the ordering contract the read now depends on.

### Assumption Under Test

Bet B2 (`design.md#key-bets`): a session actually runs a read instruction in `context-loading.md`, so removing the history sections trades a section for an equivalent read rather than for nothing.

### Test Stencil (Write This First)

```bash
# scripts/test_docs.sh — beside the ADR 0008 guards at :89-92
check_wired 'completed/CHANGELOG.md' 'claude-pack/rules/context-loading.md' \
    'session-start rule reads the newest completions'
check_wired '## \\\[\[0-9\]' 'claude-pack/rules/context-loading.md' \
    'boot read anchors on a dated heading, so placeholders are skipped'

# negative sweep, beside the retired-name check at :58
if grep -rn 'Recently Completed\|Session Notes' "$SOURCE_DIR/claude-pack" "$SOURCE_DIR/project-pack" >/dev/null 2>&1; then
    echo -e "${RED}FAIL: a pack surface still names a deleted CURRENT_WORK.md section${NC}"; FAIL=1
else
    echo -e "${GREEN}PASS: no pack surface names a deleted CURRENT_WORK.md section${NC}"
fi

# reader behavior: the template must yield nothing
[ -z "$(awk '/^## \[[0-9]/{n++; p=1} n>5{exit} /^### Deliverables/{p=0} /^---$/{p=0} p' \
    "$SOURCE_DIR/project-pack/completed/CHANGELOG.md")" ] || { echo FAIL; FAIL=1; }
```

### Changes Required

**See `design.md` for:** the read order and why it is that order → `design.md#architecture`; the one-liner and its three load-bearing details → `design.md#implementation-notes`; the ordering contract → `design.md#required-invariants`; D1 and D7 → `design.md#key-decisions`.

- [x] `scripts/test_docs.sh` — add the three guards above (write first; they fail until the edits below land)
- [x] `claude-pack/rules/context-loading.md` — add the bounded CHANGELOG read as read 3, after the product-ledger skim at `:6-7` (ADR 0008 pins that order); correct `:5`'s description of what `CURRENT_WORK.md` holds
- [x] `.project/CURRENT_WORK.md` — delete `Recently Completed` and `Session Notes`
- [x] `project-pack/CURRENT_WORK.md` — delete `Recently Completed` (`:30`), `Session Notes` (`:47`), and the orphaned "Any notable learnings" bullet (`:35`); add the newest-first line to nothing here — that belongs to the CHANGELOG template in Phase 3
- [x] `claude-pack/commands/_my_wrap_up.md:31` — remove the `Recently Completed` move only. The rest of the file is Phase 2
- [x] `claude-pack/commands/_my_close.md:83` — remove the `Recently Completed` write; add the clause naming newest-first insertion. Its four CHANGELOG fields are untouched

### Validation

**Automated:**
- [x] `./scripts/test_docs.sh` → passes, including all three new guards
- [x] `grep -rn "Recently Completed\|Session Notes" claude-pack/ project-pack/` → no output
- [x] Run the one-liner against `.project/completed/CHANGELOG.md` → 5 entries, no `### Deliverables` line
- [x] `./scripts/test_pipeline_sync.sh` → passes (the rule file changed)

**Manual — this is the phase's point:**
- [ ] Start a fresh session in this repo and ask it what shipped most recently
- [ ] Verify it answers from the boot read, without browsing item folders under `completed/` and without `git log`
- [ ] Verify `.project/CURRENT_WORK.md` reads as current state only

**What We Know Works After This Phase:** the boot read delivers recent completions at a fixed cost, and B2 is answered for real rather than assumed.

---

## Phase 2: Wrap-up's rewrite

### Goal

Rewrite `_my_wrap_up.md` into a writer of records: five steps, no `docs/`, no unasked commit, both record beats behind one confirmation.

### Assumption Under Test

Bet B4 (`design.md#key-bets`): asking the session directly reaches execution facts that close's artifact scan cannot. The beat has to exist before that can be observed at all.

### Test Stencil (Write This First)

```bash
# scripts/test_docs.sh
check_wired 'execution/ENTRIES.md' 'claude-pack/commands/_my_wrap_up.md' \
    'wrap-up prompts an execution note into the register'
check_wired 'completed/CHANGELOG.md' 'claude-pack/commands/_my_wrap_up.md' \
    'wrap-up writes a light completion entry'

WRAPUP="$SOURCE_DIR/claude-pack/commands/_my_wrap_up.md"
grep -q 'git commit' "$WRAPUP" && { echo "FAIL: wrap-up still commits"; FAIL=1; }
grep -qE '^\s*-?\s*\*\*Architecture changes\*\*|docs/architecture' "$WRAPUP" && { echo "FAIL: wrap-up still writes docs"; FAIL=1; }
```

### Changes Required

**See `design.md` for:** the five steps and what each writes → `design.md#architecture`; D2, D3, D4 → `design.md#key-decisions`; the light entry's shape → `design.md#implementation-notes`.

- [x] `scripts/test_docs.sh` — add the four assertions above
- [x] `claude-pack/commands/_my_wrap_up.md` — rewrite:
  - Purpose line and *Why This Exists* (`:3`, `:14`) stop routing learnings at `CLAUDE.md` and `.claude/rules/` and name the three record homes instead
  - Step 2 narrowed to active-item status, unfinished items, and Up Next; entries keep appending, per owner decision
  - Step 3 proposes both records and **waits**; a fact `close` already filed this session is skipped; "nothing to record" is a normal outcome that leaves no trace
  - Step 4 writes what was confirmed — light entry at the **top** of the CHANGELOG, execution note at the **end** of `ENTRIES.md`
  - Step 5 stages, shows what is staged, reports. No commit
  - Old Step 3 (docs) deleted; `--quick` redefined as steps 1, 2, 5

### Validation

**Automated:**
- [x] `./scripts/test_docs.sh` → passes
- [x] `grep -n "git commit\|docs/architecture\|docs/operations" claude-pack/commands/_my_wrap_up.md` → no output

**Manual:**
- [x] Read the rewritten command end to end as a fresh implementer would; confirm the wait in step 3 is unmissable and that step 4 says *top* for the CHANGELOG and *end* for the register

**What We Know Works After This Phase:** the command instructs the behavior the spec requires. Whether an agent follows it is Phase 5.

---

## Phase 3: Register README and the doc sweep

### Goal

Stop the register claiming close is its only trigger, remove the template placeholder, and fix the five stale descriptions of what `CURRENT_WORK.md` holds.

### Assumption Under Test

None. This is mechanical cleanup; it is separate only so Phases 1 and 2 stay reviewable.

### Test Stencil (Write This First)

```bash
# scripts/test_docs.sh
for f in .project/execution/README.md project-pack/execution/README.md; do
    grep -q 'Nothing else triggers it' "$SOURCE_DIR/$f" && { echo "FAIL: $f still says close is the only trigger"; FAIL=1; }
done
grep -q 'YYYY-MM-DD' "$SOURCE_DIR/project-pack/completed/CHANGELOG.md" && { echo "FAIL: template placeholder entry survives"; FAIL=1; }
```

### Changes Required

**See `design.md#component-overview`** for the full file list and `design.md#key-decisions` D6, D7.

- [x] `scripts/test_docs.sh` — add the assertions above
- [x] `.project/execution/README.md:5` and `project-pack/execution/README.md:5` — name both triggers. Edit both copies directly rather than editing the template and re-seeding: `--force` in this repo also refreshes unrelated stale files, which a one-line change does not justify
- [x] `project-pack/completed/CHANGELOG.md` — remove the placeholder entry; add the newest-first line to the file header
- [x] `claude-pack/commands/_my_status.md:16`, `claude-pack/claude-md-checklist.md:14`, `project-pack/README.md:57`, `docs/guide.md:136` — correct what `CURRENT_WORK.md` holds and what wrap-up does

### Validation

**Automated:**
- [x] `./scripts/test_docs.sh` → passes
- [x] `./scripts/test_init_project.sh` → passes; a fresh init yields a two-section `CURRENT_WORK.md` and a CHANGELOG with no placeholder

**Manual:**
- [x] Run the one-liner against a freshly initialized project's CHANGELOG → no output

**What We Know Works After This Phase:** no pack surface describes the old shape, and a new project's boot read starts clean.

---

## Phase 4: Codex and the full suite

### Goal

Get the new wrap-up to Codex and prove nothing else regressed.

### Assumption Under Test

That deleting the repo's only prompt prefix changes nothing beyond removing the dead restriction (`design.md#key-decisions` D5).

### Test Stencil (Write This First)

```bash
# after the rebuild
grep -q 'Codex compatibility mode' dist/codex/skills/my-wrap-up/SKILL.md && { echo "FAIL: prefix block survives"; exit 1; }
grep -q 'execution/ENTRIES.md' dist/codex/skills/my-wrap-up/SKILL.md || { echo "FAIL: record beat missing from Codex skill"; exit 1; }
```

### Changes Required

**See `design.md#implementation-notes`** — rebuild, never hand-edit `dist/`.

- [x] Delete `codex-overrides/prompt-prefixes/wrap-up.md` (the directory becomes empty; `scripts/build-codex-pack.sh:418-420` already handles absence)
- [x] `codex-overrides/config.sh:43` — reword the wrap-up description; it currently promises "related docs"
- [x] `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy`

### Validation

**Automated:**
- [x] Both stencil assertions pass against the rebuilt `SKILL.md`
- [x] All ten test scripts pass: `test_adr test_codex_orchestrator_pack test_concept_design_quality_gate test_docs test_global_setup test_init_project test_pipeline_sync test_product test_rename test_uninstall`
- [x] `git diff --check` clean

**Manual:**
- [x] Read the rebuilt `dist/codex/skills/my-wrap-up/SKILL.md` once; confirm the YAML frontmatter parsed and no prefix block remains

**What We Know Works After This Phase:** both runtimes carry the new command and the pack is internally consistent.

---

## Phase 5: The behavioral pass

### Goal

Prove the composed behavior the epic asks for, which no grep reaches.

### Assumption Under Test

The whole item: bets B1, B2, B3 and B4 together (`design.md#key-bets`).

### Test Stencil

None. This phase is observation, and writing a test for it would be pretending.

### Changes Required

- [ ] None expected. Anything found here comes back as a fix in the owning phase, recorded under *Implementation Notes*

### Validation

**Split by what contamination actually blocks.** Boxes 1 and 2 test the command's own behavior and need only a real invocation, which the implementing session can supply. Boxes 3 and 4 test whether a *cold* agent recovers the history from the boot read; this session holds the CHANGELOG in context, so its answers there would be contaminated. An earlier version of this note called all four the owner's, which was too broad.

**Manual — the acceptance criteria:**
- [x] Run `/_my_wrap_up` on a real session. Confirm it proposes rather than writes, waits for confirmation, touches no file under `docs/`, and leaves changes staged without committing — **run 2026-09-10 by the owner in the implementing session.** Step 3 produced no candidates and said so rather than padding either register; no file under `docs/` was touched; the only write was `CURRENT_WORK.md`, staged and left uncommitted. The propose-and-wait beat was therefore exercised only on its empty path — the confirmation wait itself is still unobserved, and needs a session that has a real candidate.
- [ ] Confirm the light CHANGELOG entry it wrote is at the **top** of the file — not exercised by the 2026-09-10 run, which correctly produced no entry: this session's work is a tracked item and reaches the CHANGELOG through `close`.
- [ ] Start a fresh session. Confirm its boot read names the most recent completed work, including that light entry, from the standard session-start reads alone
- [ ] Confirm the boot excerpt makes clear which entries came from `close` and which from `wrap_up`

**What We Know Works After This Phase:** the epic's falsifier for this item is answered end to end.

---

## Risk Management

**See `design.md#potential-risks`** for the full table.

**Phase-specific:**
- **Phase 1** — the read is skipped despite the rule. This is the phase's own proof point, deliberately placed first so a negative result is cheap. If it fails, stop: the remaining phases rest on it and the fallback is a conversation with the owner, not a workaround.
- **Phase 1** — the section is deleted while a writer still points at it. Both writers are edited in this same phase for exactly that reason.
- **Phase 2** — the rewrite drifts into `_my_close.md`. Phase 2 touches no other command.
- **Phase 4** — a rebuild overwrites hand edits to `dist/`. Never hand-edit; the build wipes `dist/` first.

## Post-Implementation

- [ ] `/_my_audit` on the item
- [ ] File the decision record recording that the CHANGELOG's entry format is now a read contract, if the owner agreed at design acceptance (`design.md#next-stage-handoff`) — `.project/scripts/adr.sh new <slug>`, never hand-minted
- [ ] `/_my_close`, then `/_my_pre_pr` once the epic's items ship together

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion

**Completed:** 2026-09-10

**Changes Made:**
- `scripts/test_docs.sh` — four assertions added (the plan's stencil called it three, but it lists four: two `check_wired` calls, the orphan sweep, and the template reader check). The two `check_wired` calls sit in a new commented block after the ADR 0008 block rather than inside it, since they guard the boot read and not a product-ledger touch point. The orphan sweep sits beside the retired-name check as the plan specified, written in the file's `if`/`else` style so it prints PASS as well as FAIL.
- `claude-pack/rules/context-loading.md:5` — description corrected to "what is active right now and what is up next". `:8` — the bounded CHANGELOG read added as read 3, after the product-ledger skim (ADR 0008); the docs read renumbered to 4.
- `.project/CURRENT_WORK.md` — `Recently Completed` and `Session Notes` deleted. 241 lines → 125.
- `project-pack/CURRENT_WORK.md` — same two sections deleted. 53 lines → 34. The orphaned "Any notable learnings" bullet sat inside `Recently Completed` and went with it.
- `claude-pack/commands/_my_wrap_up.md:31` — the move into `Recently Completed` removed. Nothing else in the file touched.
- `claude-pack/commands/_my_close.md` — the `Recently Completed` write removed from step 4d; the CHANGELOG bullet now names top-of-file insertion and says why (the boot read takes the first five entries).

**Issues Encountered:**
- None. The three guards failed before the edits and pass after, except the template boot-read guard, which passed from the start — the `[0-9]` heading anchor already skips the placeholder heading, which is design D7's claim that the anchor and not the template removal is what protects existing projects.

**Deviations from Plan:**
- The two `check_wired` guards are placed in their own block rather than appended to the ADR 0008 block, so the ADR 0008 comment does not come to describe guards that are not its touch points.
- `context-loading.md:6-7` is still hard-wrapped across two lines, against the markdown-formatting rule. Left alone: rewrapping an ADR-0008-pinned line is churn this item did not ask for.

**Measured:** the bounded read against `.project/completed/CHANGELOG.md` returns 5 entries, 25 non-blank lines, zero `Deliverables` lines — matching the design's arithmetic.

**Left for the owner (cannot be run from inside this session):** the three manual boxes above. A fresh session has to do the boot read cold; this session already holds the CHANGELOG in context, so any answer it gave would be contaminated.

### Phase 2 Completion

**Completed:** 2026-09-10

**Changes Made:**
- `scripts/test_docs.sh` — four assertions added: two `check_wired` guards for the register and CHANGELOG writes, plus negative guards for a re-added commit duty and any path under `docs/`.
- `claude-pack/commands/_my_wrap_up.md` — rewritten, 80 lines → 103. Five steps: review, update `CURRENT_WORK.md`, propose records and wait, write what was confirmed, stage and show. The docs step is gone; the commit step is now stage-and-show. *Why This Exists* names the three record homes. `--quick` is steps 1, 2 and 5, stated at the end of Step 2 where it bites rather than buried in a later step.

**Issues Encountered:**
- The plan's commit guard (`grep -q 'git commit'`) passed against the unmodified file, because the deleted step said "Commit with message:" and never the literal `git commit`. A guard that a known-bad file passes is not a guard. Widened to the three shapes the duty actually takes: the literal command, that phrasing, and a step heading naming it. It then failed before the rewrite and passes after.

**Deviations from Plan:**
- The docs guard is a blanket `grep -q 'docs/'` rather than the plan's `docs/architecture` alternation. It is both stronger and the right shape here: under the correction law the rewritten command carries no compensating prose about the removed duty, so it has no legitimate reason to name a `docs/` path at all.
- The plan's stencil used bare `grep -q … && { …; FAIL=1; }`. Written as `if`/`else` instead, matching the file's existing style, printing PASS as well as FAIL, and avoiding an unguarded non-zero status under the script's `set -e`.

**Verified by reading the command end to end:** Step 3 is headed "Propose Records — and Wait", opens with "Write nothing in this step", and closes with "stop and wait for confirmation. Do not proceed to Step 4 until the user has answered." Step 4 says **top** for the CHANGELOG and **end** for the register, each with its reason. A pack-wide sweep confirms no command routes session learnings at `CLAUDE.md` or `.claude/rules/`; the remaining `CLAUDE.md` mentions are reads for conventions, not writes (spec SC6).

### Phase 3 Completion

**Completed:** 2026-09-10

**Changes Made:**
- `scripts/test_docs.sh` — two guards added: both register READMEs name both triggers, and the CHANGELOG template ships no placeholder entry.
- `.project/execution/README.md:5`, `project-pack/execution/README.md:5` — both now name two triggers and say how each finds candidates: `close` scans an item's artifacts, `wrap_up` asks the session. Both files edited directly rather than re-seeded, per the design's note on `--force`.
- `project-pack/completed/CHANGELOG.md` — placeholder entry removed. Header now states the newest-first ordering and who inserts at the top, plus the entry-format contract the boot read depends on.
- `claude-pack/commands/_my_status.md:16`, `claude-pack/claude-md-checklist.md:14` — `CURRENT_WORK.md` described as "what is active right now and what is up next".
- `project-pack/README.md:57` — the Key Files row rewritten; "single source of truth" is no longer true now that completions live in the CHANGELOG.
- `docs/guide.md:136` — wrap-up's entry rewritten to its new scope (two proposed records, staged not committed), and the boot read described as `CURRENT_WORK.md` plus the newest CHANGELOG entries.

**Issues Encountered:**
- The first version of the placeholder guard grepped for the bare token `YYYY-MM-DD`, which the template's own read-contract sentence legitimately contains. Narrowed to `^## \[YYYY-MM-DD\]`, which is what "a placeholder entry" actually means. Verified it still catches a real placeholder heading in a fixture.

**Deviations from Plan:**
- **One line added beyond the plan.** `project-pack/README.md`'s Key Files table gained a `completed/CHANGELOG.md` row. The table lists every other register, and this item is what turns the CHANGELOG from an archive into a boot-read surface, so a new user reading that table would otherwise not learn it. Trivially revertible if unwanted.
- The CHANGELOG template header carries the entry-format contract as well as the ordering line. The design assigned the format contract to the Required Invariants and the rule file; naming it where entries are hand-written costs one sentence and closes the design's own "awk mis-selects after a format change" risk at the point of edit.

**Manual check run:** a fresh `init-project.sh` in a scratch directory produced a `CURRENT_WORK.md` with exactly `## Active Work` and `## Up Next`, a CHANGELOG with no placeholder, and an empty bounded boot read.

### Owner decision after Phase 4 — staging scope

**2026-09-10.** Running `/_my_wrap_up` on this session exposed it: the command staged only its own two bookkeeping files, printed "Wrap-up complete", and left twenty changed files unmentioned. The concrete risk is a light CHANGELOG entry being committed without the change it describes.

**[OWNER-VERBATIM]** "wrap up should stage ALL changes from the session, and then confirm before committing. that's it"

Applied: `_my_wrap_up.md` Step 5 now stages everything (`git add -A`), shows it, then asks before committing and waits. The spec's `[INHERITED]` stage-and-show line is superseded by this `[NEED]`.

The `test_docs.sh` guard changed with it. It used to forbid any commit; wrap-up may now commit once the user says yes, so it asserts the confirmation gate is present instead. That is a weaker guard — it proves the instruction is written down, not that an agent waits.

### Phase 4 Completion

**Completed:** 2026-09-10

**Changes Made:**
- `codex-overrides/prompt-prefixes/wrap-up.md` deleted. It was the repo's only prompt prefix, so the `prompt-prefixes/` directory is gone with it; the build handles its absence (`scripts/build-codex-pack.sh:418-420`).
- `codex-overrides/config.sh:43` — the wrap-up skill description now names the two records instead of "related docs".
- Rebuilt and installed: `./scripts/build-codex-pack.sh`, then `./scripts/setup-codex.sh --copy`.

**Regenerated:** `dist/codex/AGENTS.md` (the boot read reaches Codex too), `manifest.json`, and the `my-wrap-up`, `my-close`, `my-status`, `my-audit`, `my-handoff`, `my-implement` skills.

**Issues Encountered:**
- `git rm` refused the prefix file because it was already staged; `git rm -f` removed it.
- A scratch `init-project.sh` invocation in Phase 3 was reported as exiting 0 on a bad argument. It exits 1; the 0 came from reading `$?` after a pipe to `tail`. The script fails loudly and correctly.

**Deviations from Plan:** none.

**Validation:** both stencil assertions pass against the rebuilt `SKILL.md` — no `Codex compatibility mode` block, `execution/ENTRIES.md` present. Frontmatter parsed; the description is the reworded one. The installed copies at `~/.agents/skills/` are byte-identical to `dist/`. All ten test scripts pass. `git diff --check` clean. A repo-wide sweep including `dist/` finds no surviving reference to either deleted `CURRENT_WORK.md` section.

### Phase 5 Completion

---

**Status**: Draft → In Progress → Complete
