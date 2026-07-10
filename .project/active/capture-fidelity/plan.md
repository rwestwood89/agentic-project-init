# Implementation Plan: Capture Fidelity

**Status:** Complete — all 5 phases (implementation done; not yet audited/PR'd)
**Created:** 2026-07-10
**Last Updated:** 2026-07-10

## Source Documents
- **Spec:** `.project/active/capture-fidelity/spec.md`
- **Design:** `.project/active/capture-fidelity/design.md` ← component details, tag
  ontology (D2 table), touch placements, invariants

## Implementation Strategy

**Phasing Rationale:** Vocabulary foundations first (everything references them), then
the planted-violation dogfood as a hard gate on the design's riskiest bet (B2 — static
signatures are detectable), then the checkers protected by that fixture, then the
behavior changes, then install/distribution.

**Critical Path:** rule → fixture gate → review touches → orchestrate → install.

**First Proof Point:** Phase 2 — four plants, four findings, from a review-posture
agent given only the rule and the fixture.

**Validation adaptation:** This is prompt-text work; "test-first" means fixture-first.
The fixture and its expected findings are written before the checkers they validate.
All validation is manual/subagent-driven except the structural greps.

---

## Phase 1: Vocabulary foundations — rule + capture/absorb touches

### Goal
The four laws exist in their single home; the first capture device (`_my_concept`) and
the absorb vocabulary (`_my_spec`) apply them.

### Assumption Under Test
The four laws + tag table + the owner's contrast pair fit in ~40 substantive lines
with no failure-specific content (Required Invariants, design.md).

### Fixture Stencil (write the shape first)
Rule outline to hold to — if a section outgrows this, stop and cut:

```
# Capture Fidelity  (header states the ≤~40-line budget as its own invariant)
Scope: decision-carrying items only; enforcement is structural and limited (2 lines)
1. Provenance — grades, register table, the settled rule, absorb mapping (~12 lines)
2. Compression — payload survives verbatim/by-path, force stated, unclear → ask (~6)
3. Correction — shrink-or-amend; BAD/GOOD pair verbatim; one-line decision records (~10)
4. Surfacing — triggers / response / never silent (~6)
```

### Changes Required

**See `design.md#component-overview` for placement detail; `design.md#key-decisions`
D2 for the tag table and absorb mapping (copy the table into the rule, it lives there).**

- [x] **`claude-pack/rules/capture-fidelity.md` (NEW)** — the four laws per the
      outline above. The BAD/GOOD pair verbatim from `spec.md` (binding).
- [x] **`claude-pack/commands/_my_concept.md`** — Owner's Words section
      (optional-but-default when sourced from live conversation); provenance grades on
      "Settled here" (`:203`) and Non-Goals; one guideline line each for payload force
      markers and correction discipline, referencing the rule by path.
- [x] **`claude-pack/commands/_my_spec.md`** — `[INHERITED]` in the Known Requirements
      block (`:91-100`); `[NEED]` definition sharpened to owner-stated (`:97`); Stage 4
      checklist gains "inherited cites source" (`:127-133`).

### Validation
- [x] Rule ≤ ~40 substantive lines (count, excluding blank/header) — exactly 40
- [x] Laws' text appears in exactly one file: `grep -rl "shrink or amend" claude-pack/` → rule only
- [x] Both touched commands reference the rule by path; neither restates a law
- [x] Read-through: no failure-specific content in the rule (generalization bar)

**What We Know Works:** the vocabulary exists, fits budget, single-sourced.

---

## Phase 2: Planted-violation dogfood — the gate

### Goal
Prove B2: the static signatures are detectable by a review-posture agent given only
the rule and a violating artifact. **If this fails, stop — the enforcement story needs
rework before six more files change** (`design.md#next-stage-handoff`).

### Assumption Under Test
B2 (`design.md#key-bets`).

### Fixture Stencil (write expected findings first)
`.project/active/capture-fidelity/fixture-planted-concept.md` — a short synthetic
concept containing exactly these plants, each with its expected finding recorded in a
sibling `fixture-expected-findings.md` before the run:

```
P1: settled list contains an [AGENT]-graded item        → flag: settled ⊄ owner-grade
P2: "WE MUST NOT use a queue" prohibition               → flag: prohibition-mode record
P3: verbatim section names referent `reports/foo/` that
    never appears in deliverables/handoff               → flag: owner referent dropped
P4: requirement reading "No caching layer is required
    (previously proposed, not needed)"                  → flag: negation-shaped req
```

### Changes Required
- [x] Write `fixture-expected-findings.md` (the four expected flags, above)
- [x] Write `fixture-planted-concept.md` (plausible enough that the plants aren't the
      only content — ~40 lines, one plant per section, no hints)
- [x] Run: fresh review-posture subagent, context = the new rule + the fixture, task =
      "review this concept for capture-fidelity violations." No other coaching.

### Validation
- [x] 4/4 plants flagged (P1–P4 each matched to an expected finding) — see gate result:
      3/4 on the first run (P3 was mis-specified for a concept hop), 4/4 after refitting
      P3 as a softening plant and re-running through the real `spec_review` (Phase 3).
- [x] No more than ~2 false positives (1 borderline on run 1; 0 on the Phase-3 re-run)
- [x] **Gate:** passed. P3 miss traced to a fixture defect, not enforcement (owner call:
      proceed, refit P3). B2 (correction static signatures) validated by P2 + P4.

**What We Know Works:** the signatures are real; baking them into reviewers is worth it.

---

## Phase 3: The checkers — review touches

### Goal
The structural checks land in the review commands; the dogfood passes through the
*real* commands.

### Assumption Under Test
The checks integrate into existing lenses/dimensions without rubric bloat
(spec success criterion: "without gaining failure-specific rubric items").

### Changes Required
**See `design.md#architecture` (Check bullet) for the exact check list.**

- [x] **`_my_spec_review.md`** — Lens 1 gains the structural checks (settled ⊆
      owner-grade; quotes exist where verbatim claimed; inherited cites source; owner
      referents present with force stated; correction static signatures). Harmonized
      `:67` ("stated as settled that the user never actually decided") to point at the
      structure. References the rule by path.
- [x] **`_my_design_review.md`** — Dimension 1 gains one structural-check bullet
      (`:61-68`); references the rule by path.
- [x] **`_my_design.md`** — Stage 1 Required-Reading bullet (`:76`): upstream
      `[INFERRED]`/`[INHERITED]` items are challengeable; conflicts with owner-grade
      intent invoke the surfacing duty.

### Validation
- [x] Re-run the Phase-2 dogfood as a `/_my_spec_review`-prompted subagent against the
      fixture → **4/4 flagged** (L1-1..L1-4), 0 false positives
- [x] Diff check: each review file's touch ≤ ~10 lines (numstat: 2/1/2 lines)
- [x] Read-through: checks read as structure, not as a band-study checklist

**What We Know Works:** the reviews enforce what the rule declares.

---

## Phase 4: Behavior changes — orchestrate + audit + handoff

### Goal
The front-loading + tier behavior, audit scope honesty, and handoff claim marking.

### Assumption Under Test
Orchestrate stays internally consistent after the largest touch (the Align exchange's
"reserved gates" vocabulary is consumed verbatim by the tier rule).

### Changes Required
**See `design.md#component-overview` for full wording requirements.**

- [x] **`_my_orchestrate.md`** (the ~25-line stated exception) —
      - [x] line 9: "No user checkpoints..." → "One checkpoint at launch (Align);
            after that, you run to the end."
      - [x] Step 1 gains the Align exchange (meaning of work, reserved gates,
            provenance gaps, cross-document conflicts, suspect-`[HARD]` challenges)
      - [x] `:63-64` replaced by the three-tier rule (execution details / reserved
            gates → park branch, continue non-dependent, hard-halt only when all
            remaining work depends / premise surprises → surfacing duty)
      - [x] stage briefs carry provenance grades on settled items they pass down
- [x] **`_my_audit.md`** — Certification section (`:101-104`) gains required
      "**Not checked:**" line; one scope-honesty guideline line.
- [x] **`_my_handoff.md`** — instruction 2: claims marked verified-this-session vs
      carried-from-elsewhere.

### Validation
- [x] Orchestrate full read-through: no contradiction with the Align exchange anywhere
      in the file; "reserved gate(s)" wording shared by Align and the tier rule
- [x] Orchestrate touch ≤ ~25 lines net (+23 / −5, net +18)
- [x] Audit template renders with the new line; audit/handoff touches ≤ ~10 lines each
      (audit +5 / −1, handoff +3)

**What We Know Works:** all eight touches in place, each internally consistent.

---

## Phase 5: Install + distribution

### Goal
Ship to `~/.claude/` and the Codex pack; final structural verification.

### Changes Required
- [x] `./scripts/setup-global.sh`
- [x] `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`
      (no `COMMAND_SKILL_DESCRIPTIONS` changes — no new/renamed commands)
- [x] Keep `fixture-planted-concept.md` + `fixture-expected-findings.md` in the
      feature folder as the regression fixture (decision per plan approval)

### Validation
- [x] `~/.claude/rules/capture-fidelity.md` symlink resolves → into `claude-pack/rules/`
- [x] Codex build passes (23 command skills). **Correction to the plan's premise:** no
      standalone rule file / `rules/` dir in `dist/codex/` (skills pipeline is
      commands-only, as intended), but the build inlines every `claude-pack/rules/*.md`
      into `AGENTS.md` (`build-codex-pack.sh:324-331`), so the rule's *content* ships to
      Codex via its global-instructions channel — like working-voice, pipeline, etc. This
      is standard behavior and a better outcome than the assumed "cleanly absent": the laws
      reach Codex as always-on instructions, not broken path refs. Satisfies the spec
      Non-Goal (nothing Codex-specific was built).
- [x] Final greps: laws single-sourced (full BAD/GOOD pair only in the rule). **6 of 8**
      touched commands reference the rule — the six that apply one of the four laws.
      `_my_audit` (scope honesty) and `_my_handoff` (claim marking) carry behaviors the
      rule does not state as laws, so they correctly do not reference it (a reference would
      point at a rule that lacks the behavior). Flagged in the Phase-4 report; owner said
      proceed. The plan's "all eight reference the rule" was written before the exact
      four-law set was pinned.
- [x] Rule line budget still holds after all edits — 40 substantive lines.

**What We Know Works:** live in both runtimes' install paths; invariants hold.

---

## Risk Management

**See `design.md#potential-risks`.** Phase-specific:
- **Phase 1:** budget pressure → cut examples, never the laws; the owner's pair is the
  only permitted example.
- **Phase 2:** the gate — bail to design on any missed plant.
- **Phase 4:** orchestrate self-contradiction → the read-through checkbox is the test.

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
**Completed:** 2026-07-10
**Actual Changes:**
- Created `claude-pack/rules/capture-fidelity.md` — four laws (provenance, compression,
  correction, surfacing), the D2 tag table, absorb mapping, and the owner's BAD/GOOD pair
  verbatim. 40 substantive lines. Header states the ≤~40-line budget as its own invariant.
- `_my_concept.md`: added "Owner's Words" (optional-but-default) template section after
  Problem Statement; provenance grades on the Settled-here and Non-Goals template blocks;
  two guideline bullets (payload force markers, correction discipline) referencing the rule.
- `_my_spec.md`: added `[INHERITED]` to the Known Requirements block; sharpened `[NEED]` to
  owner-stated ("inferred → [INFERRED], not [NEED]"); Stage-4 checklist line for
  inherited-cites-source + need-is-owner-stated.

**Issues:** none.
**Deviations:** Owner's Words placed after Problem Statement (not before) so the problem
still leads; verbatim capture reads as the record the derived sections trace to.

### Phase 2 Completion (gate result)
**Completed:** 2026-07-10 — gate decision pending user call (see below).
**Plants flagged:** 3/4 — P1 (settled ⊄ owner-grade), P2 (prohibition-mode), P4
(negation-shaped requirement) all caught cleanly by a fresh general-purpose reviewer given
only the rule + fixture. **P3 (dropped owner referent) not flagged.**
**False positives:** 1 — reviewer flagged the ungraded Success Criteria (agent-invented
"2s / 50k lines" numbers). Borderline: flows from the rule's literal "grade every
decision-carrying item," but the design scopes concept grading to Settled + Non-Goals only
(`design.md:201`), so success-criteria grades aren't required. Within the ≤~2 bar.

**P3 analysis — fixture defect, not an enforcement failure.**
- The design states first-hop compression (chat → concept) has exactly one checker, the
  owner at capture (`design.md:71-72`). A downstream reviewer is explicitly not the checker
  for a dropped referent in a concept.
- My fixture captured the referent correctly in Owner's Words with its force stated
  ("match `reports/foo/` exactly"), so there was nothing to flag — the reviewer even said
  so. Had I dropped it entirely, the referent would be absent from the artifact and a
  reviewer could not know it ever existed. Either way, a concept-level reviewer cannot catch
  this — by design.
- P3 also is not part of bet B2. B2 is "correction metastasis has static signatures"
  (`design.md:83`) — that is P2 and P4, both caught. P3 is a compression-law plant that
  belongs at the concept→spec absorb hop (spec_review), not a concept review.

**Bottom line:** B2 is validated. The gate's stated purpose (`design.md#next-stage-handoff`:
"if the signatures aren't detectable, B2 fails") is met — all correction/provenance
signatures were caught with low false positives. The literal 4/4 bar was not met because
P3 was mis-specified for this hop. Decision on whether to (a) proceed to Phase 3 and refit
P3 into a reviewer-detectable form, (b) call it here, or (c) return to design — pending user.

### Phase 3 Completion
**Completed:** 2026-07-10
**Actual Changes:**
- `_my_spec_review.md`: Lens 1 gains one capture-fidelity structural-checks bullet
  (settled ⊆ owner-grade, `[INHERITED]` cites source, verbatim quote appears, referent
  force stated, correction signatures as questions); harmonized the Lens 3 `:67` "settled
  that the user never decided" line to defer to Lens 1's structural check.
- `_my_design_review.md`: Dimension 1 gains one structural-check bullet (design carried
  spec provenance; challengeable item frozen as constraint / owner referent dropped or
  hardened).
- `_my_design.md`: Stage 1 spec-reading note — upstream `[INFERRED]`/`[INHERITED]` items
  are challengeable; conflict with owner-grade intent invokes the surfacing duty. Added
  `[INHERITED]` to the tag list it notes.
- Refit fixture P3 from "referent absent downstream" (not reviewer-detectable in a concept)
  to "binding referent softened into a vibe" (detectable within one artifact); updated
  expected findings.
**Dogfood result:** through the real `_my_spec_review` command posture, 4/4 plants flagged
(L1-1 softening, L1-2 prohibition, L1-3 settled ⊄ owner-grade, L1-4 negation-shaped),
0 false positives. The success-criteria grading seam from Phase 2 did not recur.

### Phase 4 Completion
**Completed:** 2026-07-10
**Actual Changes:**
- `_my_orchestrate.md`: line 9 reconciled to "one checkpoint at launch (Align)"; step 1
  ("Orient, then Align") gains the launch checkpoint covering meaning-of-work, the reserved
  gates, provenance gaps + cross-document conflicts, and suspect-`[HARD]` challenges; the
  old "make the most defensible call … don't stop and wait" line replaced by the three
  tiers (execution detail / reserved gate / premise surprise → surfacing duty); step-3
  overlay now tells the orchestrator to mark provenance on settled items it passes down.
- `_my_audit.md`: Certification template gains a required "**Not checked:**" line; the
  "only mark what you verified" instruction gains a scope-honesty sentence.
- `_my_handoff.md`: instruction 2 gains a claim-status marking bullet (verified this session
  vs carried).
**Note (deliberate):** audit scope-honesty and handoff claim-marking do NOT reference the
capture-fidelity rule — neither is one of the four laws the rule states; they are standalone
behaviors the spec lists separately. Only orchestrate references the rule (its premise-
surprise tier invokes the surfacing duty, which IS a law).
**Deviations:** none. "Last Updated" changelog lines left unbumped across all touched
commands — git history is the record; bumping eight lines would be noise. Flag if you want
them updated.

### Phase 5 Completion
**Completed:** 2026-07-10
**Actual Changes:** ran `setup-global.sh` (rule + updated commands symlinked into
`~/.claude/`); `build-codex-pack.sh` + `setup-codex.sh --copy` (24 installed, 2 skipped by
design). No `COMMAND_SKILL_DESCRIPTIONS` change. Regression fixtures kept in the feature
folder.
**Finding (recorded above):** the rule's content ships to Codex via `AGENTS.md`, not as a
separate file — the plan's "cleanly absent from dist/codex" premise was about the build
mechanism, which inlines all rules into AGENTS.md. Outcome is correct and better than
assumed.
**Deviations:** 6 of 8 commands reference the rule (audit + handoff apply non-law behaviors
— deliberate, flagged). `Last Updated` changelog lines left unbumped across touched files.

---

**Status:** Draft → In Progress → **Complete**
