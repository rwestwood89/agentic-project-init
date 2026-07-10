# Design: Capture Fidelity

**Status:** Reviewed — revisions incorporated (see `design-review.md` Resolutions)
**Owner:** Reid W
**Created:** 2026-07-10 09:32
**Branch:** main (implementation on a feature branch)
**Base commit:** b79c40c

## Overview

One always-loaded rule states four laws of chat→artifact→artifact capture (provenance,
compression, correction, surfacing); eight existing commands get minimal touches that
apply the laws at their natural pressure points. No new stages, no new tooling.

## Related Artifacts

- **Spec:** `.project/active/capture-fidelity/spec.md` (reviewed; resolutions incorporated)
- **Spec review:** `.project/active/capture-fidelity/spec-review.md`
- **Design review:** `.project/active/capture-fidelity/design-review.md` (verdict
  Revise; all resolutions incorporated 2026-07-10)
- **Forensic source:** references listed in the spec's Related Artifacts

## Research Findings

All findings from direct reads this session (files cited at current `main`, b79c40c):

- **The spec tag vocabulary is a fused axis.** `[HARD]/[NEED]/[INFERRED]`
  (`_my_spec.md:91-100`) each already imply a provenance: HARD → forced by reality
  (code/physics), NEED → the stakeholder, INFERRED → the agent. The missing value is
  "absorbed from an upstream artifact, never independently validated" — the grade that
  let inherited machinery masquerade as `[HARD]` in the traced failure.
- **Shaping artifacts have no tag vocabulary at all.** The concept template's "Settled
  here" (`_my_concept.md:203`) and Non-Goals carry untagged assertions; this is where
  provenance flattening happened.
- **The reviews already reach for these checks informally.** `spec_review` asks "is
  anything stated as settled that the user never actually decided?"
  (`_my_spec_review.md:67`, `:259`) but has no structure to check it against.
  `design_review` Dimension 1 checks spec compliance (`_my_design_review.md:61-68`);
  Dimension 7 hunts hidden bets (`:114-121`).
- **Single-source precedent exists.** `pipeline.md` keeps the stage map in one place,
  other docs point at it, and `scripts/test_pipeline_sync.sh` guards the one permitted
  duplicate. `working-voice.md` is referenced by path from commands
  (`_my_spec.md:39`, `_my_spec_review.md:79`) — the pattern this rule reuses.
- **Rules load via `claude-pack/rules/` → `~/.claude/` symlinks** (`setup-global.sh`);
  the Codex layer ships commands only (`CLAUDE.md`, Codex section) — consistent with
  the spec's Non-Goal (references degrade gracefully).
- **Orchestrate's flattening lives in two lines:** step 1 "Orient" (`_my_orchestrate.md:43`)
  has no alignment exchange, and "How to work" says "make the most defensible call,
  record it loudly, and keep going. Don't stop and wait" (`:63-64`).
- **Audit's output template** has a Certification section (`_my_audit.md:101-104`) with
  no scope statement; the epic scope has an intent check (`:135`) the item scope lacks.

## Core Concept

The system is a **provenance-and-fidelity contract between pipeline stages**, stated
once in an always-loaded rule and enforced at the four points where artifacts change
hands. The key insight: authority comes from source, not from being written down — so
every device that *captures* marks who decided, every device that *absorbs* preserves
the marks, every device that *checks* verifies the marks where they are checkable, and
every device that *certifies* states its own scope. The laws are register-aware:
shaping artifacts (concepts, settled lists) speak **provenance** (who decided); specs
speak **force** (what kind of claim), whose vocabulary carries provenance once
`[NEED]` is sharpened to owner-stated (D2). The rule is the single live statement;
commands reference it by path, exactly as they already do for `working-voice.md`
(the owner's contrast pair also sits frozen in this feature's spec — a record, not a
second live copy).

Enforcement reach is uneven, and stated plainly: **provenance** is structurally
checkable at review; **correction** is semi-checkable (static signatures, best
effort); **surfacing** leaves checkable artifacts only when performed — its omission
is invisible; **first-hop compression** (conversation → concept) has exactly one
checker, the owner at capture, which is what the verbatim section is for. The design
concentrates the checks where checking is real and claims nothing more.

## Key Bets

- **B1.** With `[NEED]` sharpened to owner-stated by construction (D2), the force
  vocabulary carries provenance (HARD→reality-with-citation, NEED→owner,
  INFERRED→agent, INHERITED→prior artifact) — one new tag and one sharpened
  definition, not a second axis. *If false — agents keep writing inferred needs as
  `[NEED]` despite the definition — provenance re-flattens one hop after capture, or
  dual tagging returns and the vocabulary turns to soup.*
- **B2.** Correction-metastasis has static signatures a reviewer can detect in the
  artifact alone (prohibition-mode phrasing, negation-shaped requirements, content
  redundant with a Non-Goal). *If false → the correction law regresses to write-time
  best-effort, which has demonstrably failed.*
- **B3.** A ~40-line always-loaded rule, paired with structural checks where checking
  is real (provenance at review; correction via static signatures) and honest
  best-effort elsewhere (surfacing, first-hop compression), changes capture behavior
  where per-project memories did not — because the checkable violations become
  objects rather than attitude lapses. *If false → the laws are ignored like the
  memories were, and the rule is dead weight in every context window.*
- **B4.** One synchronous checkpoint at launch does not erode orchestrate's value —
  the owner is present by construction and the exchange is bounded. *If false → owners
  skip the checkpoint or stop using orchestrate, and front-loading silently dies.*

## Key Decisions

- **D1 — New rule file `claude-pack/rules/capture-fidelity.md`, not an extension of
  `working-voice.md`.** Working-voice governs how prose reads; this governs what
  artifacts may claim. *Rejected: extending working-voice (couples two unrelated
  concerns; working-voice is already at a good size and scope).*
- **D2 — Register mapping resolves the two-axis ontology (spec Open Question 1).**
  Shaping artifacts (concepts, epics, settled lists, orchestrate briefs) tag
  **provenance**: `[OWNER-VERBATIM]` (quote required), `[OWNER]`, `[AGENT]`,
  `[INHERITED: source]`. Specs keep the **force** vocabulary and add one tag:
  `[INHERITED]` (absorbed from an upstream artifact, source cited). Designs are
  untouched — Bets/Decisions are agent-grade by construction. The settled rule binds
  per register: in shaping artifacts, settled lists admit only `[OWNER*]` items; in
  specs, settled eligibility is `[HARD]` (settled by the world, citation checkable)
  and `[NEED]` (settled by the owner) — never `[INFERRED]`/`[INHERITED]`. Two
  sharpenings make this hold (design-review C1): `[NEED]` means an outcome a
  stakeholder actually stated — an inferred outcome is `[INFERRED]`; and the
  concept→spec **absorb mapping** is defined, because that hop is where the traced
  failure flattened provenance: `[OWNER-VERBATIM]` → `[NEED]` carrying the quote or a
  path-cite to the concept's Owner's-Words section (verbatim protection rides the
  compression law — no new spec tag); `[OWNER]` → `[NEED]`; `[AGENT]` → `[INFERRED]`;
  `[INHERITED: src]` → `[INHERITED]`, source carried.

  | register | vocabulary | settled-eligible |
  |---|---|---|
  | shaping (concept, epic, settled lists) | `[OWNER-VERBATIM]` `[OWNER]` `[AGENT]` `[INHERITED: src]` | owner grades only |
  | spec (requirements) | `[HARD]` `[NEED]` `[INFERRED]` `[INHERITED]` | `[HARD]`, `[NEED]` |
  | payload (any artifact) | `[EXAMPLE]` / `[REFERENT]`, or force stated in words | n/a — force must be stated |
  | design | Bets / Decisions (agent-grade by construction) | n/a |

  *Rejected: dual tags on every line (soup — the exact outcome review L2-2 warned
  against); provenance-only everywhere (loses `[HARD]`'s teeth, the force distinction
  specs already rely on); a spec-level verbatim tag (the quote-or-path convention
  carries it without vocabulary growth).*
- **D3 — Reviews are the checkers; no new gate anywhere.** The structural checks land
  inside existing review lenses/dimensions. *Rejected: a concept_review stage (owner
  is the in-session reviewer; rejected at spec) and a standalone lint script (the
  signatures are judgment calls — prohibition-mode vs a legitimate Non-Goal — not
  regex-safe).*
- **D4 — Orchestrate: an "Align" exchange appended to Orient, plus a tier table
  replacing the "defensible call" line.** The checkpoint is one message-and-reply at
  launch; the tier rule distinguishes execution details (decide, record, go) /
  owner-reserved gates (park the branch, continue non-dependent work, hard-halt only
  when everything remaining depends on an answer) / premise surprises (surfacing duty).
  *Rejected: a separate checkpoint stage command (heavier than the behavior it adds);
  keeping "don't stop and wait" with exceptions bolted on (the flat rule is the bug).*
- **D5 — Payload force markers are `[EXAMPLE]` / `[REFERENT]`, prose equivalents
  allowed.** An owner-given example is marked as illustrating the kind; a referent as
  the bar to match. The rule defines the distinction; artifacts may express it as a tag
  or in words ("match this" / "for flavor, not form"). *Rejected: mandatory tag form
  (over-formal for conversational capture; the distinction matters, the syntax doesn't).*
- **D6 — No sync test for the rule.** Nothing is duplicated (unlike `pipeline.md`'s
  shape line), so there is nothing to assert in sync; the "reference, don't restate"
  convention plus review checks carry it. *Rejected: a grep-based guard script (guards
  against a failure the architecture already prevents).*

## Architecture

One rule, four kinds of pressure points. Data flows left to right; the marks are made
once and preserved:

- **Capture** (conversation → artifact): `_my_concept` — verbatim intent, provenance
  grades on settled/non-goals, payload carried with force markers.
- **Absorb** (artifact → artifact): `_my_spec` (`[INHERITED]` tag), `_my_design`
  (upstream `[AGENT]`/`[INHERITED]` items are challengeable; conflicts invoke the
  surfacing duty).
- **Check** (artifact → verdict): `_my_spec_review` Lens 1 and `_my_design_review`
  Dimension 1 verify structure — settled ⊆ owner-grade, quotes exist where verbatim is
  claimed, inherited cites source, owner referents present with their force stated
  (statedness is structural; force *correctness* is judgment), correction static
  signatures flagged. Git diffs of `.project/` artifacts are the secondary check when a
  review has reason to inspect how a correction landed.
- **Certify / hand off**: `_my_audit` states scope ("Not checked:"); `_my_handoff`
  marks claims verified vs carried; `_my_orchestrate` front-loads alignment and tiers
  mid-run decisions.

The rule file is the only place the laws are stated. Every command touch is a
reference plus the minimum local wording to anchor it (target: 1–10 lines per file;
orchestrate is the stated exception at ~25).

## Required Invariants

- The four laws exist in exactly one file; no command restates them.
- The owner's BAD/GOOD contrast pair appears verbatim in the rule (binding, per spec).
- Settled / do-not-relitigate lists in committed artifacts contain only owner-grade
  items. (Orchestrate stage briefs are ephemeral stdin — the same discipline applies
  there as a behavioral instruction in the command, not a checkable invariant.)
- Existing tag semantics are unchanged: `[HARD]/[NEED]/[INFERRED]` mean what they mean
  today; `[INHERITED]` is added, nothing redefined.
- The rule stays ≤ ~40 lines of substance and contains no failure-specific checks
  (the spec's generalization bar).
- Provenance tags apply to decision-carrying items only (settled lists, requirements,
  ground rules, non-goals) — never to ordinary prose.

## Component Overview

- **`claude-pack/rules/capture-fidelity.md` (NEW).** The four laws: Provenance
  (grades, register mapping, the settled rule), Compression (owner payload survives
  verbatim/by path at the owner's emphasis, force marked, unclear → ask), Correction
  (shrink-or-amend; the BAD/GOOD pair; one-line decision records in designated homes;
  no emphasis inflation), Surfacing (triggers / response / never silent). Plus a
  two-line scope note (tags on decision-carrying items only; enforcement is structural
  and honest about its limits).
- **`_my_concept.md` (TOUCH).** Template: optional-but-default "Owner's Words"
  (verbatim) section when sourced from live conversation; provenance grades in
  "Settled here" and Non-Goals; one guideline line each for payload force markers and
  correction discipline, referencing the rule.
- **`_my_spec.md` (TOUCH).** `[INHERITED]` added to the Known Requirements block;
  `[NEED]`'s definition sharpened to owner-stated by construction (an inferred outcome
  is `[INFERRED]`); the Stage 4 checklist gains "inherited cites source." The absorb
  mapping itself lives in the rule, not here.
- **`_my_spec_review.md` (TOUCH).** Lens 1 gains the structural checks; the existing
  `:67` "settled that the user never decided" line is harmonized to point at the
  structure instead of intuition.
- **`_my_design.md` (TOUCH).** Stage 1 Required-Reading bullet: upstream
  `[AGENT]`/`[INHERITED]` items are challengeable; conflicts with owner-grade intent
  invoke the surfacing duty.
- **`_my_design_review.md` (TOUCH).** Dimension 1 gains one structural-check bullet.
- **`_my_orchestrate.md` (TOUCH — the stated budget exception, ~25 lines).** Step 1
  gains the Align exchange (meaning of work, reserved gates, provenance gaps,
  cross-document conflicts, suspect-`[HARD]` challenges — "do you literally want X,
  or are you solving for Y?"); the `:63-64` line is replaced by the three-tier rule;
  line 9's "No user checkpoints — you're handed an objective and run to the end" is
  reconciled ("one checkpoint at launch; after that, you run to the end"); stage
  briefs carry provenance grades on any settled item they pass down.
- **`_my_audit.md` (TOUCH).** Certification section gains a required "Not checked:"
  line; one guideline line on scope honesty.
- **`_my_handoff.md` (TOUCH).** Instruction 2 gains claim-status marking (verified
  this session vs carried from elsewhere).

## Non-Goals

Carried from the spec (see its Non-Goals — not restated here): no concept-review
stage, no mandatory exemplars, no notification feature, no Codex representation, no
pipeline-shape changes. Design adds one: **no enforcement tooling** (lint scripts,
hooks) — the checkers are the existing reviews.

## Implementation Notes

- Follow the `working-voice.md` teaching pattern in the rule: state the law plainly,
  then the one contrast pair. Resist adding examples beyond the owner's pair.
- `_my_orchestrate.md` edit order matters: the Align exchange references reserved
  gates that the tier rule consumes — keep the vocabulary identical in both places.
- After command edits: `./scripts/setup-global.sh`, then
  `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`. No
  `COMMAND_SKILL_DESCRIPTIONS` changes (no new commands, no purpose-line changes).
- The rule's provenance-grade names should read naturally inline:
  `[OWNER]`, `[OWNER-VERBATIM]`, `[AGENT]`, `[INHERITED: path-or-name]`.
- Concept template change is additive — existing concepts in the wild stay valid;
  the grades apply to concepts written after this ships.

## Potential Risks

- **Tag cargo-culting** — agents tag prose, or deference-tag everything `[OWNER]`.
  Mitigation: the scope note (decision-carrying items only), `[OWNER-VERBATIM]`
  requiring a quote, and the owner's scan being directed at exactly the owner-tagged
  claims. Residual: a fluent misparaphrase tagged `[OWNER]` survives if the owner
  skims — irreducible, stated in the spec.
- **Static-signature false positives** — legitimate Non-Goals or design
  rejected-alternatives flagged as metastasis. Mitigation: the signature is
  prohibition-*mode* ("WE MUST NOT") and redundancy, not any negation; the reviews
  frame findings as questions, not verdicts.
- **Rule creep** — future corrections land as additions to the rule, re-running the
  ratchet on the anti-ratchet device. Mitigation: the ≤ ~40-line invariant is stated
  in the rule's own header as a hard budget.
- **Orchestrate Align skipped in practice** — a concept that says "ready, no review
  needed" tempts the orchestrator to skip. Mitigation: Align is a numbered step of
  Running the pipeline, not advice; its output (reserved gates) is consumed by the
  tier rule, so skipping it visibly breaks the tiers.

## Integration Strategy

Ships as one branch touching `claude-pack/` only; `.project/` artifacts in target
projects are unaffected until agents write new ones. Interactive flows change
minimally (a spec session gains one tag; a concept session gains a verbatim section).
The largest behavioral change is orchestrate's launch exchange, which its next live
drive exercises (the workflow-orchestrator item's Phase 4 dogfood is the natural
vehicle — see CURRENT_WORK.md).

## Validation Approach

1. **Planted-violation dogfood.** A synthetic concept containing one agent-grade item
   in a settled list, one WE-MUST-NOT prohibition, one dropped owner referent, and one
   negation-shaped requirement; run `/_my_spec` + `/_my_spec_review` against it and
   confirm all four are flagged. This validates B2 directly.
2. **This feature's own artifacts** are the second dogfood: the spec already carries
   provenance annotations; the reviews of the implementation should check them.
3. **Structural greps:** the laws' text appears only in the rule file; every touched
   command references it by path.
4. **Codex rebuild** passes and skips the rule cleanly (commands-only pipeline).
5. **Line budget check:** rule ≤ ~40 substantive lines.

## Next-Stage Handoff

- **Fixed:** the register mapping (D2), reviews-as-checkers (D3), the orchestrate
  Align + tiers shape (D4), the rule as sole statement of the laws.
- **Open for the plan:** exact wording of every touch (the plan should draft each
  file's diff in place, honoring the 1–10-line budget per file); ordering (rule first,
  then capture devices, then checkers, then orchestrate).
- **De-risk first:** write the rule file and the `_my_concept` touch, then run
  validation 1 (planted violations) before touching the reviews — if the signatures
  aren't detectable, B2 fails and the enforcement story needs rework before the rest
  lands.

---
Next Step: Design review complete (verdict Revise; all resolutions incorporated) → `/_my_plan`.
