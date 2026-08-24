# Implementation Plan: Anchor the Pipeline on the Point

**Status:** Remediation v3 applied — pending re-audit (2026-08-05)
**Created:** 2026-08-05
**Last Updated:** 2026-08-05

## Source Documents
- **Spec:** `.project/active/anchor-on-the-point/spec.md`
- **Design:** `.project/active/anchor-on-the-point/design.md` ← component details, decisions, invariants, risks
- **Concept:** `.project/concepts/anchor-on-the-point.md` (the seven smells, the fusion-tea test)

## The Point

The pipeline exists to make agent-built code trustworthy by carrying *why* the work is being done
through independent stages and stopping work that violates it. Today each stage checks only the
artifact one hop upstream, so if one agent narrows the product's point, every later stage serves the
narrowed version — the sysml-codegen fan-out incident, where a green-tested violation of the repo's
central source-identity promise was certified. This work adds a second, independent line of ground
truth (the product-lens), carries the full problem legibly at every hop, and lets a loud product
judgment outrank a green rubric. That obligation — *stop the wrong work, don't just check the last
artifact* — is what every phase below serves.

## Implementation Strategy

**Phasing rationale.** The design's top instruction is de-risk first: prove the lens stops the
fusion-tea shape *before* editing six commands (`design.md#validation-approach`,
`design.md#next-stage-handoff`). Phase 1 builds the lens spec and the fixture and validates the
load-bearing bets B1/B2/B4 (`design.md#key-bets`). Everything after is integration, ordered so
each command file is touched exactly once (the two verdict stages carry lens + judgment + smells
together, Phase 4).

**Critical path.** Phase 1 (shared spec + fixture proves the bet) → Phase 4 (verdict stages
consume the spec) → Phase 5 (end-to-end block survives to the ship gates). Phases 2 and 3 are
independent of each other and of 4; the linear order 1→5 is the safe build.

**First proof point.** Phase 1: the fixture is stopped two independent ways — the `[HARD]`-graded
product-lens DON'T finding (⇒ BLOCK) and the duplicate-selecting-test smell escalating into the
judgment — despite green tests, a plausible inherited explanation, and a consumer workaround.

**Validation approach.** "Tests" in this repo are adversarial fixtures run through real subagents
against an answer key written first (the capture-fidelity precedent,
`.project/active/capture-fidelity/fixture-*.md`), plus prompt-edit inspection and dry runs. There
is no unit-test framework for prompt edits; the fixture is the real gate.

---

## Phase 1: Lens spec + fixture — prove the bet

### Goal
Build the shared product-lens spec and the fusion-tea fixture, and prove the lens stops the shape
two independent ways with no coaching. This collapses the whole design's core uncertainty before
any command is edited.

### Assumption Under Test
B1 (independent re-derivation from source catches point-narrowing), B2 (a single-job subagent
won't rationalize the finding away), B4 (the finding fires loudly enough to control a verdict).
See `design.md#key-bets`.

### Test Stencil (Write This First — the answer key)
```
# fixture-expected-findings.md — written BEFORE the fixture and the spec
Plant P1 [DON'T]: generated output gives one modeled source two independent params.
  Expected: product-lens DON'T finding, source = model identity guarantee (grade [HARD]) → BLOCK.
Plant P2 [DO]:   design never wires the shared inputs together.
  Expected: product-lens DO/omission finding (not only an active-break finding).
Plant P3 [smell]: acceptance test passes only by selecting one duplicate (lcoe_calc__gain).
  Expected: smell six fires in audit → escalates into the loud judgment.
Plant P4 [can't-find control]: strip the durable point → expect a disposition-requiring finding,
  not a fabricated oracle.
Pass bar: P1 AND P3 both stop the item independently; P2 caught as omission; P4 → disposition.
  ≤ ~2 false positives. Any plant missed → gate fails, return to design.
```

### Changes Required
**See `design.md#architecture`** (the shared spec's four sections, the ledger format, oracle-first
data flow) and **`design.md#component-overview`**.

- [x] `.project/active/anchor-on-the-point/fixture-expected-findings.md` (NEW — write first)
- [x] `.project/active/anchor-on-the-point/fixture-planted-input.md` (NEW — fusion-tea shape per
      `design.md#validation-approach`: shared-source fan-out, green tests, prior "known hazard"
      note, plausible mechanism distinction, proposed consumer workaround, completable by
      accepting the inherited frame)
- [x] `claude-pack/commands/product-lens.md` (NEW — the shared spec): §1 lens job + oracle-first
      protocol, §2 source-authority grading ladder mapped onto capture-fidelity provenance grades
      (`design.md#key-decisions` D3), §3 ledger format, §4 seven smells split by layer
- [x] `claude-pack/scripts/setup-global.sh` — ship `product-lens.md` so call sites can reach it
      (`design.md#potential-risks`, reachability)

### Validation
**Automated / fixture:**
- [x] Spawn the lens (`general-purpose` + the shared spec) against `fixture-planted-input.md`, no
      coaching → P1 produces a `[HARD]` DON'T finding ⇒ BLOCK; P2 produces an omission finding
- [x] Feed the fixture's acceptance test to the smell checklist → P3 (duplicate-selecting-test)
      fires and is marked escalate-into-judgment
- [x] Strip the durable point (P4) → lens returns a can't-find, disposition-requiring finding
- [x] Confirm ≤ ~2 false positives against the answer key

**Manual:**
- [x] Verify `setup-global.sh` places/symlinks `product-lens.md` where an installed command
      resolves it (dry run the installer)

**What We Know Works After This Phase:**
The lens independently catches the fusion-tea shape both directions and the smell fires — the
design's core bet holds. If it does not, STOP and surface (per `design.md#next-stage-handoff`).

---

## Phase 2: Carry the problem (move 1)

### Goal
Stop the pipeline from dropping the problem: `design` gains a slot for it, `plan` stops deleting
it, `spec` keeps it full and graded.

### Assumption Under Test
That "The Point" slot can be worded to carry the obligation without tripping `_my_design.md`'s
own anti-restatement anti-pattern (line 369) — see `design.md#implementation-notes`.

### Test Stencil (Write This First)
```
# Inspection assertions (dry-run a toy item through each edited command)
design.md output: has a "The Point" section stating the obligation the design must serve,
  graded, NOT a prose recap of the spec.
plan.md output:   restates the problem; the old "replace that text with a reference" is gone.
spec.md output:   Problem section present, full, and provenance-graded (unchanged behavior, verified).
```

### Changes Required
- [x] `claude-pack/commands/_my_design.md` — add "The Point" slot to the section scaffold (near
      Core Concept, ~line 89/122) and to the expected-document template (~line 288); word it per
      `design.md#implementation-notes` to dodge the line-369 anti-pattern
- [x] `claude-pack/commands/_my_plan.md` — reverse the anti-restatement rule at lines 18-19 and
      287 (and supporting 284/286) so the plan carries the problem; keep the *design-detail*
      no-duplication intent intact (only the business-context/problem deletion is reversed)
- [x] `claude-pack/commands/_my_spec.md` — confirm/adjust so the Problem section (76-80) stays
      full and graded; light edit only

### Validation
**Manual:**
- [ ] Dry-run `_my_design` on a toy item → "The Point" appears, is an obligation not a recap
- [x] Read edited `_my_plan.md` → problem-carry instruction present, deletion instruction gone,
      design-detail dedup rule still intact
- [x] Re-read `_my_spec.md` Problem section → still full + graded

**What We Know Works After This Phase:**
The problem statement survives design and plan instead of being stripped to a pointer.

---

## Phase 3: Wire the lens into the non-verdict sites + ledger convention

### Goal
Run the lens at `epic_plan` and `spec`, and establish the per-item append-only ledger that all
four sites write to.

### Assumption Under Test
That a lens call slots into these commands without turning the artifact into "another large
template" (`spec.md` open Q, `design.md#key-decisions` D2).

### Test Stencil (Write This First)
```
# Dry-run assertions
epic_plan: lens runs over the decomposition; verdict recorded in the epic artifact (inherited by items).
spec:      lens runs; a ledger block is appended to .project/active/{item}/product-lens.md;
           the spec carries a one-line verdict pointer, not an embedded findings dump.
```

### Changes Required
**See `design.md#architecture`** (integration matrix; ledger format; the one-line pointer rule).

- [x] `claude-pack/commands/_my_epic_plan.md` — run the lens over the decomposition (Stage 2/3,
      ~lines 34-55); record its verdict in the epic artifact
- [x] `claude-pack/commands/_my_spec.md` — spawn the lens; append a ledger block; add the
      one-line verdict pointer to the spec
- [x] Ledger convention: the format lives in `product-lens.md` §3 (Phase 1); these call sites are
      its first writers. Nothing new to create — just wire the append.

### Validation
**Manual:**
- [ ] Dry-run `_my_spec` on a toy item → ledger file created/appended; verdict pointer in spec
- [ ] Dry-run `_my_epic_plan` on a toy epic → decomposition-level verdict recorded
- [x] Confirm neither artifact bloats (one-line pointer, not embedded findings)

**What We Know Works After This Phase:**
The two early narrowing sites re-derive the point and leave a durable, non-bloating record.

---

## Phase 4: The two verdict stages — lens + loud judgment + smells

### Goal
Make `design_review` and `audit` lead with the loud "is this the right piece of work?" judgment,
run the lens, and carry their half of the seven smells — each file touched once.

### Assumption Under Test
That the loud judgment can be layered on `design_review`'s existing Stage 0 gate (35-52) and added
above `audit`'s bare verdict (74) so a fired smell or `[HARD]` finding controls the verdict even
when the rubric is green (`design.md#architecture`, move 3).

### Test Stencil (Write This First)
```
# Fixture-driven (reuse Phase 1 fixture)
design_review on the fixture design: Stage 0 leads with the product judgment; design-level smells
  (consumer-compensates-for-platform-guarantee; invariant-ownership-change) fire and escalate;
  lens BLOCK sets Gate: BLOCKED. Verdict = Rework despite a green rubric.
audit on the fixture implementation: loud product judgment above the verdict; duplicate-selecting-test
  smell fires and escalates; verdict = Needs Work despite green local tests.
```

### Changes Required
**See `design.md#architecture`** (smell split by layer) and **`design.md#required-invariants`**
(escalation invariant).

- [x] `claude-pack/commands/_my_design_review.md` — fold lens findings + the two design-level
      smells into Stage 0's holistic judgment (35-52); spawn the lens; append ledger; add verdict
      pointer. Add the two smells as tripwires that must escalate into Stage 0.
- [x] `claude-pack/commands/_my_audit.md` — add a loud product judgment above the verdict (74);
      spawn the lens; append ledger; add the five code/test smells to the code-integrity checks
      (48-66), including the duplicate-selecting-test smell (verbatim smell six)
- [x] Verify each fired smell is instructed to escalate into the leading judgment, not sit in
      rubric detail (`design.md#required-invariants`)

### Validation
**Fixture:**
- [x] Run `design_review` against the fixture → Rework via the judgment, smells escalated, Gate
      BLOCKED, despite green rubric
- [x] Run `audit` against the fixture → Needs Work via the judgment, duplicate-selecting-test smell
      escalated, despite green tests

**What We Know Works After This Phase:**
Both verdict stages stop the fusion-tea shape through the loud judgment, two independent ways.

---

## Phase 5: Enforcement + decision-record link + end-to-end

### Goal
Convert the incorruptible finding into a blocking state the ship gates honor; link an accepted
contract change to an ADR; run the full fixture through the wired stages end to end.

### Assumption Under Test
B4's mitigation: an unresolved BLOCK survives to `pre_pr`/`close` and stops the ship
(`design.md#potential-risks`, the crux). And that only an "intended contract change" disposition
files an ADR (`design.md#key-decisions` D4).

### Test Stencil (Write This First)
```
pre_pr / close on an item with Gate: BLOCKED in product-lens.md → gate FAILS, names the finding.
Intended-contract-change disposition → files an entry via adr.sh; ledger finding cites the entry id.
End-to-end: fixture item runs design_review + audit → BLOCK set → pre_pr refuses → resolve via
  disposition (or ADR) → gate clears.
```

### Changes Required
- [x] `claude-pack/commands/_my_pre_pr.md` — read the ledger; fail on any unresolved BLOCK
- [x] `claude-pack/commands/_my_close.md` — same honor-the-block check; route an
      intended-contract-change disposition to `adr.sh new` and require the ledger to cite the id
- [x] Confirm no ADR is filed for any lower-authority or can't-find disposition (density bar,
      `design.md#key-decisions` D4)

### Validation
**Fixture / end-to-end:**
- [x] Item with an unresolved BLOCK → `pre_pr` fails and names the finding; `close` refuses
- [x] Dispose an intended-contract-change → `adr.sh` entry created, ledger cites id, gate clears
- [ ] Full fixture walk: design_review + audit BLOCK → pre_pr refuses → disposition clears →
      pre_pr passes
- [x] Regression: run the existing `test_adr.sh` → still green (adr.sh untouched except new call site)

**What We Know Works After This Phase:**
The block is durable and honored to the ship gates; the one durable disposition reuses the ADR
mechanism without over-filing.

---

## Environment Setup

**See CLAUDE.md.** New/edited command prompts must be re-installed via
`claude-pack/scripts/setup-global.sh` to take effect in `~/.claude/`; Codex dist rebuild is a
separate step, done at close, not per phase (see prior-work note in `CURRENT_WORK.md` about
excluding `dist/codex/` from feature commits).

## Risk Management

**See `design.md#potential-risks` for the full analysis.**

**Phase-specific mitigations:**
- **Phase 1** — if the fixture can't be stopped two ways, the core bet (B1/B4) is false: STOP and
  surface, do not proceed to wire commands.
- **Phase 1/3** — reachability of the shared spec across project dirs: verified in the installer
  dry run before any command depends on it.
- **Phase 4** — independence leak (lens absorbs the narrowed frame): the fixture's plausible
  inherited explanation is the direct test; oracle-first ordering in the spec is the mitigation.
- **Phase 5** — the block is agent-honored, not mechanical: named as residual risk at close; the
  append-only ledger discipline and the ship-gate honor-check are the available controls.

## Implementation Notes

### Phase 1 Completion — the gate
**Completed:** 2026-08-05
**Actual changes:**
- `claude-pack/scripts/product-lens.md` (NEW) — the shared lens spec (§1 job + oracle-first, §2
  grading ladder mapped to capture-fidelity provenance, §3 ledger format, §4 seven smells).
- `.project/active/anchor-on-the-point/fixture-expected-findings.md` (answer key, written first).
- `.project/active/anchor-on-the-point/fixture-planted-input.md` (fusion-tea shape, self-contained).
**Gate result — PASS, decisively.** Two fresh, uncoached `general-purpose` subagents ran the spec
against the fixture:
- Full-fixture run: P1 (DON'T) caught verbatim, graded owner/`[HARD]` via ADR 0007 → BLOCK; P2 (DO
  omission) caught explicitly; P3 (smell 6, duplicate-selecting test) fired + flagged escalate.
  Zero false positives (the `to_watts` helper and scoped units test drew nothing). It discarded the
  "different category" framing and the inherited "known hazard" label — the two things the incident
  turned on. **Stopped two independent ways, as the spec demands.**
- Can't-find control run (sources stripped): returned a can't-find finding, refused to fabricate an
  oracle, refused to adopt the WORK's inherited framing → DISPOSE-and-proceed (write the point
  down). Exactly the spec's INFERRED criterion.
This validates B1 (independent re-derivation catches narrowing), B2 (single-job agent discards the
plausible framing instead of rationalizing), and the finding-side of B4.
**Deviations:**
- Shared spec homed at `claude-pack/scripts/product-lens.md`, **not** an installer edit. The
  existing `setup-global.sh` scripts glob (line 149) already symlinks every `.md` there into
  `~/.claude/scripts/` — precedent: `orchestrate-preamble.md`. So no installer change was needed;
  reachability at `~/.claude/scripts/product-lens.md` is confirmed by that live precedent.
- Noted (not fixed, out of scope): `setup-global.sh --dry-run` exits early under `set -e` because
  `create_dir`'s `[ ! -d ] && echo` returns 1 when the dir exists. Pre-existing; real install
  unaffected.

### Phase 2 Completion — carry the problem (move 1)
**Completed:** 2026-08-05
**Actual changes:**
- `_my_design.md` — added "The Point" to the empty-section list and the template (after Related
  Artifacts), worded as *the obligation the design serves*; carved a matching exception into the
  line-369 anti-restatement anti-pattern so the slot is not self-contradictory.
- `_my_plan.md` — reversed the anti-restatement rule at both locations (Overview + Guidelines):
  the plan now carries the problem; only architecture/mechanism detail is linked away.
**Deviations:** `_my_spec.md` needed no move-1 edit — its `## Problem` section already carries the
full problem in one place. (Its lens wiring is Phase 3.)

### Phase 3 Completion — lens at the non-verdict sites + ledger
**Completed:** 2026-08-05
**Actual changes:**
- `_my_epic_plan.md` — new Stage 3 step runs the lens over the decomposition; verdict recorded in
  the epic file under a Product-Lens heading, inherited by items. Renumbered following steps.
- `_my_spec.md` — Stage 4 runs the lens on the drafted spec; appends the ledger block; one-line
  pointer to Related Artifacts; findings not embedded in the spec body.
- Ledger convention (`.project/active/{item}/product-lens.md`) format lives in the shared spec §3;
  these are its first writers.

### Phase 4 Completion — the two verdict stages
**Completed:** 2026-08-05
**Actual changes:**
- `_my_design_review.md` — Stage 0 now runs the lens (step 4) and checks the two design-level
  smells (step 5); leads with "**is this the right piece of work?**" which an owner/`[HARD]` finding
  or any fired smell controls even when the rubric is green; STOP/Rework condition extended to an
  unresolved BLOCK or a fired smell.
- `_my_audit.md` — Evaluate now leads with the lens run + holistic judgment before the four areas;
  added the five code/test-level smells (duplicate-selecting-test first) to Code integrity with the
  escalation rule; template gains a Product Judgment section; Certify forbidden while the ledger
  gate is BLOCKED.

### Phase 5 Completion — enforcement + ADR link + validation
**Completed:** 2026-08-05
**Actual changes:**
- `_my_pre_pr.md` — Step 2 gains a product-lens gate: an unresolved `Gate: BLOCKED` on any in-scope
  item is a hard stop before submit, framed as honoring a durable state (not a conformance re-check).
- `_my_close.md` — certification warnings honor an unresolved BLOCK; emergent-decision scan routes an
  "intended contract change" (or smell-seven ownership change) disposition to `adr.sh new` with the
  ledger citing the entry id; no other disposition files an ADR.
**Validation:** repo suite green after all edits — `test_adr.sh` 25/25 (ADR mechanism untouched),
`test_pipeline_sync.sh` (shape still in sync), `test_docs.sh`. Lens-wiring grep confirms the engine
in the 4 run-sites, the ledger in all 6 (4 writers + 2 honor-only), "carry the problem" in design +
plan — matching the design's integration matrix exactly.
**Residual gap (honest):** the lens *engine* was validated against the real fixture in Phase 1 (two
independent stop-paths, can't-find control, zero FPs). The stage *wiring* that routes a BLOCK into
Rework / Needs-Work / ship-gate-stop is verified by inspection + the green repo suite, not by a live
command-level end-to-end run. This matches the design's named crux (B4): enforcement is
agent-honored, not mechanical. A full live e2e and the fixture's DO/lower-authority sub-checks are
the first things a fresh-session audit should exercise.

---

### Remediation pass — after audit Needs Work (2026-08-05)
Owner directed: amend ADR 0002, fix correctness + hygiene in one pass; distribution deferred.
- **Blocker cleared.** Filed `.project/adr/0003` (product-lens touch points; `[AGENT]` ratified by
  owner) and `adr.sh amend 0002 0003`. Corrected the design's false "no conflict" claim
  (`design.md:24`). Appended a DISPOSED block to the ledger — no unresolved owner/`[HARD]` remains.
- **Correctness.** Fail-closed ledger reads in `pre_pr` + `close` (missing expected ledger = control
  failure); epic→item propagation so an epic BLOCK reaches ship gates via the per-item ledger (D2);
  audit "escalation ≠ resolution" fix; spec Problem grading; The Point carried into the
  design_review + audit output templates (SC1); status-aware ADR clearing in the lens spec §2.
- **Hygiene.** Smell numbering set to the concept's canonical 1–7 (product-lens §4; close references);
  fixture answer-key aligned to the planted input (three tests, shared route-B); retired
  `product-truth-gates.md` (owner-verbatim quotes preserved in the concept; dangling links removed).
- **Deferred (owner scope):** vendored + Codex distribution reachability; a live command-level
  BLOCK→disposition→CLEAR e2e. Both tracked in the ledger and the audit's Not-checked.
- **Validation:** repo suite green (adr 25/25, pipeline-sync, docs); fixture re-run reconfirmed.

### Remediation v2 — after re-audit v2 Needs Work (2026-08-05)
Five remaining blockers, all closed; two were my own prior fixes backfiring.
- **Plan problem slot (SC1)** — added a structural `## The Point` to the `_my_plan` template and to
  this plan.
- **Amended ADRs treated as dead** — lens §2 now counts a live ADR (`active` *or* `amended`) as
  owner-grade; only `superseded` stops binding.
- **Epic finding drift/authority (D2, smell 1)** — `_my_spec` writes a grade-preserving *reference*
  to the epic finding instead of copying it; `pre_pr`/`close`/epic-audit read the epic's live gate.
- **Epic-scope audit skipped the lens (D6)** — epic scope now runs the lens over the assembled work
  and honors item ledgers + referenced epic findings.
- **Later CLEAR masks earlier BLOCK** — lens §3 requires resolution-by-citation; gates scan every
  block, not just the latest.
- **ADR 0003 special-category framing (smell 3)** — superseded by **ADR 0004**, which states the
  touch-point map is extended and amends 0002. Design references updated.
- Ledger `remediation v2` block disposes the audit_v2 BLOCK by citation → gate DISPOSED.
- **Deferred (owner scope):** vendored/Codex reachability + live command-level e2e.
- **Validation:** adr 25/25, pipeline-sync, docs, global-setup all pass; `git diff --check` clean.

### Remediation v3 — after v3 review found three fail-open paths + two grading gaps (2026-08-05)
- **Late epic BLOCKs missed existing items** → `_my_spec` records `Epic: <id>` unconditionally;
  `_my_pre_pr`/`_my_close`/`_my_audit` always read the epic's live gate for epic items.
- **Item audit could certify over an older BLOCK** → item audit scans every ledger block
  (resolution-by-citation), not just its own run.
- **Epic close skipped the epic's own gate** → epic-scope close reads the epic Product-Lens gate
  directly, independent of item references.
- **Live ADR laundered `[AGENT](ratified)` into owner authority** → lens §2 separates liveness
  (status: `active`/`amended` bind) from authority (only `[OWNER]` provenance BLOCKs). ADR 0004
  superseded by **0005** with the corrected invariant.
- **Ambiguous resolution citations** → lens §3 gives findings stable IDs (`<stage>-F<n>`) and a
  structured `Resolves:` record (id, authority, basis).
- Ledger `remediation v3` block records the fixes and gives the two deferred items stable IDs
  (DEFER-F1 vendored/Codex, DEFER-F2 live e2e).
- **Validation:** adr 25/25, pipeline-sync, docs, global-setup pass; `git diff --check` clean; ADR
  chain 0005 active / 0002 amended / 0003→0004→0005 superseded.

**Status**: … → Remediation v2 → Needs work (v3 review) → **Remediation v3 applied (pending re-audit)**
