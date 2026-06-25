# Implementation Plan: Agent Working Voice

**Status:** Complete
**Created:** 2026-06-23
**Last Updated:** 2026-06-23

## Source Documents
- **Spec:** `.project/active/agent-working-voice/spec.md`
- **Design:** `.project/active/agent-working-voice/design.md` ← component details, the rewrite principle, Decision B, risks

## Implementation Strategy

This feature edits prose and prompts, not code. The test-first structure is adapted: each phase defines what good looks like and how it's verified (read / diff / build), not a unit-test stencil.

**Phasing rationale:** Write the rule first, because every prompt rewrite imitates it. Then pilot one rewrite to prove the rule works as a rewrite guide before applying it five times. Then do the rest, add the review checks, and install.

**Critical path:** rule → pilot rewrite → remaining rewrites + pointers → review checks → install.

**First proof point:** the rule itself, read and approved by the user at the end of Phase 1.

**Validation approach:** each phase verified by reading the artifact against the rule, diffing for meaning/stance/structure drift, and (Phase 5) running the build and install clean.

---

## Phase 1: Write the voice rule

### Goal
Create `claude-pack/rules/working-voice.md` per `design.md#architecture`. Everything downstream imitates it, so it comes first.

### Assumption Under Test
That the voice the user wants can be written down as a short, example-driven rule that obeys itself.

### What Good Looks Like (write to this)
- Sections: scope line; the method; presenting a decision as a worked good-vs-bad example; texture / anti-tells with short before/afters.
- Short. Length is itself a voice failure.
- The rule reads in the voice it defines — a skeptical first-time reader finds nothing in it that violates its own method.
- Covers the points in `/tmp/claude-writing-feedback.md` (the content source).
- Format matches the existing `claude-pack/rules/*.md` files (H1 title, `##` sections, prose + bullets).

### Changes Required
**See `design.md#architecture`** for the rule's section structure and `design.md#key-bets--decisions` for the rewrite principle and the decision-as-example framing.

- [x] Create `claude-pack/rules/working-voice.md` with the four sections above.
- [x] Draw before/after examples from the feedback doc and the over-flagged audit findings.

### Validation
- [x] Read the rule cold as a skeptical reviewer; flag any sentence that breaks its own method, and fix.
- [x] Cross-check against `/tmp/claude-writing-feedback.md` — each failure mode it names is addressed.
- [x] **Checkpoint: present the rule to the user. Do not start Phase 2 until they approve it.** — Approved 2026-06-23.

**What We Know Works After This Phase:**
There is one agreed source of truth for the working voice, and it passes its own bar.

---

## Phase 2: Pilot one prompt rewrite

### Goal
Rewrite the single worst-offender prompt block using the rule as the guide. Prove the method before applying it five times.

### Assumption Under Test
That the rule works as a rewrite guide — that applying it makes a prompt plainer without changing the instruction's meaning, the command's stance toward its job, or its structure.

### What Good Looks Like
- Target: the worst offender from `design.md#research-findings` — `_my_concept_design.md`'s "What You MUST NOT Do" block (~lines 368-391) or `_my_implement.md`'s "ABSTRACTION QUALITY" / "FAIL LOUDLY" blocks (~lines 122-177). Pick one, rewrite that block only.
- The rewrite breaks jargon and stacked ideas into simple ideas, one at a time, in logical order. It does not add padding; blunt instructions stay blunt.
- Diff shows register changed and meaning/stance/structure did not.

### Changes Required
- [x] Pick the pilot block and rewrite it in place per the rule's method. — Did two: `_my_implement.md` ABSTRACTION QUALITY block, `_my_concept_design.md` "spec-register" bullet.

### Validation
- [x] Diff the block: confirm the instruction's meaning is intact, the command's stance is intact, and no structural rule moved.
- [x] **Checkpoint: show the user the diff and confirm the rewrite method before Phase 3.** — Confirmed 2026-06-23.

**What We Know Works After This Phase:**
The rule works as a rewrite guide, and the user agreed with how the rewrites read. **Key finding:** both pilots showed the audit over-flagged the prompts. Genuine voice problems are surgical (undefined coined terms, em-dash splices, stacked clauses), not file-wide rewrites. Phase 3 recalibrated below: read each flagged file, fix only genuine offenders, preserve good blunt prose, bring all diffs at once (no per-file checkpoint).

---

## Phase 3: Rewrite remaining prompts + add pointers

### Goal
Apply the proven method to the rest of the prompts that read badly, and point existing decision-presentation guidance at the rule.

### Assumption Under Test
None new — this is applying a method already validated in Phase 2.

### Changes Required
**See `design.md#research-findings`** for the file list and `design.md#architecture` for the two edit kinds (voice rewrite; additive pointer).

Voice rewrites (the rest of the offenders):
- [ ] `_my_concept_design.md` (remaining dense prose, if `implement` was the pilot)
- [ ] `_my_implement.md` (if `concept_design` was the pilot)
- [ ] `_my_design.md` (anti-patterns block, ~lines 327-374)
- [ ] `_my_review_design.md` (negation-stacked opening, lines 9-26)
- [ ] `_my_audit_implementation.md` (jargon block, ~lines 30-58)

Additive pointers (one line each, no content removed):
- [ ] `_my_spec_review.md` finding-framing section → reference the rule
- [ ] `_my_quick_edit.md` → reference the rule
- [ ] `_my_code_review.md` presentation step → reference the rule

### Validation
- [ ] Each rewrite diffed for meaning / stance / structure drift.
- [ ] Confirm `_my_concept_design.md` register discipline and any external-explainer guidance are unchanged (`design.md#required-invariants`).

**What We Know Works After This Phase:**
The prompts demonstrate the voice instead of contradicting it, and decision-presentation guidance points at one source.

---

## Phase 4: Add the working-voice check to the review commands

### Goal
Add the comprehension-anchored writing check to the two commands that gate written artifacts.

### Assumption Under Test
That the check can be worded to fire only when voice blocks comprehension, without contradicting existing review guidance.

### Changes Required
**See `design.md#key-bets--decisions`** (Decision B) for placement and bar.

- [x] `_my_spec_review.md`: added **Lens 5: Reader Comprehension**, anchored to the human being ~75% of the audience; explicitly a higher bar than Lens 4 ("you are not flagging awkward sentences"). Updated "Four Lenses"→"Five", Stage 1, and the output template (L5-1).
- [x] `_my_review_design.md`: added **Dimension 8: Reader Comprehension**, tied to the design's mental-alignment purpose; updated the output template and sharpened the "Focus on substance" guideline so comprehension counts as substance.

### Validation
- [x] Both checks fire only on comprehension-blocking voice, never on awkward sentences (stated explicitly in each).
- [x] No contradiction with `spec_review`'s "keep hygiene brief" — Lens 5 is explicitly distinguished from Lens 4.
- [x] Both checks name `claude-pack/rules/working-voice.md` as the standard.
- Note: `_my_review_compact` and `_my_code_review` get no check, per Decision B (they don't gate prose artifacts a human reads; they inherit the voice via the global rule).

**What We Know Works After This Phase:**
Bad voice in an artifact gets caught at review, at the high bar the design set.

---

## Phase 5: Install and propagate

### Goal
Make the rule live in both Claude and Codex.

### Changes Required
- [x] Run `./scripts/setup-global.sh` → symlinked `working-voice.md` into `~/.claude/rules/`.
- [x] Run `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy` — both clean (20 installed, 2 skipped, 0 removed).

### Validation
- [x] `dist/codex/AGENTS.md` contains `## From working-voice.md` with the full rule.
- [x] `~/.claude/rules/working-voice.md` exists and points at the repo.
- [x] Both scripts ran clean. `~/.codex/AGENTS.md` (symlink → dist) carries the rule; both review-command Codex skills carry the Reader Comprehension check.

**What We Know Works After This Phase:**
The rule auto-loads in every Claude session and is folded into the Codex `AGENTS.md`.

---

## Risk Management

**See `design.md#potential-risks`.**

**Phase-specific mitigations:**
- **Phase 1:** rule may not read in its own voice → cold skeptical read + user checkpoint.
- **Phase 2:** a rewrite may soften a deliberately blunt instruction or shift meaning → pilot one block, diff, user checkpoint.
- **Phase 3:** drift across many edits → per-diff review; untouched-files check.
- **Phase 4:** check turns nitpicky → verify the wording holds the comprehension bar.

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
### Phase 2 Completion
### Phase 3 Completion
### Phase 4 Completion
### Phase 5 Completion

---

**Status:** Draft → In Progress → Complete
