# Design Review: Capture Fidelity

**Design:** `.project/active/capture-fidelity/design.md`
**Spec:** `.project/active/capture-fidelity/spec.md`
**Review File:** `.project/active/capture-fidelity/design-review.md`
**Date:** 2026-07-10

---

## Fundamental Assessment

**Sound.** The approach is right, and notably it is the *minimal* right thing: one always-loaded
rule stating four laws, plus eight small command references — no new stages, no tooling, no new
patterns. It reuses two proven precedents (the `working-voice.md` reference-by-path pattern and the
`pipeline.md` single-source convention). The usual design-review failure mode (premature abstraction,
over-engineering) is absent here. If anything the risk runs the other way: the design bets that a
lightweight rule changes behavior where per-project memories did not (B3), and that is genuinely
uncertain. So the review below does not argue the design is too heavy. It argues that the enforcement
story is sold slightly harder than the mechanism delivers, and that the concept→spec hop — the exact
place the traced failure happened — has an undefined provenance mapping.

Proceeding to the dimensional review.

---

## Dimensional Review

### 1. Spec Compliance
**Assessment:** Concerns

Every one of the eight success criteria maps to a design element — I walked them one by one and all
are covered (rule, provenance grading, concept capture, correction, orchestrate front-load+tiers,
audit scope, review checks, handoff marking). The mid-run tier language in D4 matches the spec's
resolved L2-1 wording exactly.

The concern is one internal contradiction the touch list misses. `_my_orchestrate.md:9` reads
"No user checkpoints — you're handed an objective and run to the end." D4 adds an "Align" exchange —
a synchronous message-and-reply at launch. That is a user checkpoint. The Component Overview lists
the Step-1 Align edit and the `:63-64` tier replacement but does not list reconciling line 9. Left
as written, the command will assert "no user checkpoints" one line above a mandatory launch
checkpoint. See M1.

### 2. Pattern Consistency
**Assessment:** Pass

The rule-by-path reference reuses the `working-voice.md` pattern the commands already use
(`_my_spec.md:39`, `_my_spec_review.md:79`). The single-source discipline mirrors `pipeline.md`.
D6's choice to skip a sync test is correctly reasoned — `pipeline.md` needs `test_pipeline_sync.sh`
because it deliberately duplicates the stage line; this rule duplicates nothing structural, so there
is nothing to assert. One small caveat under Data Structure (the BAD/GOOD pair does appear in two
files) but it is harmless. No new patterns are invented where old ones fit.

### 3. Abstraction Quality
**Assessment:** Concerns

The register split (D2) — shaping artifacts speak provenance, specs speak force — is the right core
abstraction, and choosing it over dual-tagging-everything is well justified. But the design defines
**two vocabularies and never defines the translation between them**, and the translation point is the
concept→spec absorb hop, which is exactly where the traced failure's provenance flattening occurred.

- A concept's `[OWNER]` ground rule becomes… what in the spec? Presumably `[NEED]`. `[AGENT]` →
  `[INFERRED]`. `[INHERITED]` → `[INHERITED]`. The design leaves this implicit.
- `[OWNER-VERBATIM]` has **no** spec-level equivalent. The force vocabulary has no verbatim grade.
  So the single strongest provenance grade, and the "quotes exist where verbatim is claimed" check
  that keys on it, silently evaporate the moment a spec absorbs a concept.

This is the C1 finding. The abstraction is sound; the seam between its two halves is undefined.

### 4. Duplication Avoidance
**Assessment:** Pass

No functional duplication. The one literal duplication — the owner's BAD/GOOD pair living verbatim
in both `spec.md:115` and the new rule — is not drift-prone: the spec freezes once implemented and
the rule is the live device. D6 correctly identifies there is nothing to sync-guard. (Minor: the
design's phrase "Nothing is duplicated" is very slightly overstated; see m4.)

### 5. Data Structure Clarity
**Assessment:** Concerns

The "data structures" here are three tag families: provenance grades (`[OWNER-VERBATIM]`, `[OWNER]`,
`[AGENT]`, `[INHERITED: source]`), force tags (`[HARD]/[NEED]/[INFERRED]` + `[INHERITED]`), and
payload markers (`[EXAMPLE]`/`[REFERENT]`). Two clarity gaps:

- **`[NEED]` does not encode provenance** (B1 asserts it does). Nothing in the tag's definition
  (`_my_spec.md:97`) or the settled rule bars an agent-*inferred* stakeholder need from being written
  as `[NEED]` and then marked settled. The discipline "agent inferences go to `[INFERRED]`" is
  exactly the tagging fidelity that already failed. See C1(a).
- **Payload force is optionally prose** (D5: "prose equivalents allowed") but the reviews are asked
  to check "owner referents survived" structurally (D3). A reviewer can structurally confirm a
  referent *is present* (a path/link), but cannot structurally confirm its *force* was preserved if
  force may be free prose. See m2.

### 6. Route Safety
**Assessment:** Pass

For a prompt system, "routes" are how the rule loads and how references resolve. Loading is verified
(`claude-pack/rules/` → `~/.claude/` symlink via `setup-global.sh`). Dangling references in contexts
without the rule (Codex, fresh clone pre-setup) "degrade gracefully" — identical to how
`working-voice.md` references behave today, an accepted pattern, not a new risk.

### 7. Bets & Decisions Integrity
**Assessment:** Concerns

Decisions D1–D6 each name their rejected alternative with a reason — genuine decisions, honestly
recorded. The bets are mostly real claims about reality with stated failure modes. Two issues:

- **B1 is shakier than stated.** "The existing spec tags carry provenance unambiguously" is true of
  the vocabulary's *intent* but not of what the tags *enforce*. `[NEED]` carries no provenance
  guarantee (C1). B1 conflates "the vocabulary can express provenance" with "the vocabulary carries
  provenance reliably" — and the failure was always a fidelity problem, not an expressiveness one.
- **Hidden bet: two of the four laws are not structurally checkable, but the design leans on B3's
  "violations become checkable objects" as if all four are.** Provenance is checkable (settled ⊆
  owner-grade, source citation). Correction is semi-checkable via static signatures (B2, the design's
  riskiest and best-de-risked bet). But **surfacing** is silent by construction — a reviewer cannot
  see a conflict the agent resolved without surfacing — and **compression at the first hop**
  (conversation → concept) has no reviewer at all, because there is deliberately no concept-review
  stage. That first hop is precisely where the traced failure dropped the owner's exemplar. So the
  Core Concept's "every device that *checks* verifies the marks structurally" overstates the reach of
  checking. See M2.

### 8. Reader Comprehension
**Assessment:** Pass

The design is dense but navigable, and it largely practices `working-voice.md`. A reader can come
away with the model: authority comes from source; mark it at capture, preserve it on absorb, verify
it at review, scope it at certification; shaping artifacts speak provenance, specs speak force. One
thing would help the plan and any later reader: the three tag families are scattered across D2 and
D5 with no single table showing each vocabulary and where it applies. Not blocking; noted with C1
since the missing cross-register mapping is the same gap.

---

## Issues by Severity

### Critical (Must address before implementation)

- **C1 — The force vocabulary does not carry provenance the way B1 claims, and the concept→spec
  absorb hop has no defined provenance mapping.** This is the exact locus of the original failure.
  Two facets:
  - (a) `[NEED]` does not distinguish owner-stated from agent-inferred, and nothing bars a `[NEED]`
    from being marked settled — so an agent inference can re-acquire owner authority at spec level,
    the very flattening this feature exists to stop.
  - (b) `[OWNER-VERBATIM]` and `[OWNER]` have no spec-level equivalents, so verbatim protection and
    the owner-grade distinction (and the review checks that key on them) collapse when a spec absorbs
    a concept.
  — Abstraction Quality / Data Structure / Bets

### Major (Should address)

- **M1 — orchestrate.md:9 ("No user checkpoints — you're handed an objective and run to the end")
  contradicts the new Align exchange, and the touch list omits reconciling it.** — Spec Compliance
- **M2 — Surfacing and first-hop (conversation→concept) compression have no structural checker, yet
  the Core Concept and B3 present checking as covering all four laws.** Scope the claim to where
  checking is real; state the other two as best-effort plainly. — Bets & Decisions

### Minor (Consider addressing)

- **m1** — The orchestrate touch (Align exchange with five probe types + a three-tier table
  replacing two lines) will exceed the design's stated "1–10 lines per file" budget; it is the one
  file that does. Adjust the budget claim or name orchestrate as the exception.
- **m2** — Payload markers `[EXAMPLE]`/`[REFERENT]` are optional-syntax (D5) but the reviews are
  asked to check referent force structurally (D3). Either give force a checkable form or scope the
  review check to "referent present," not "force preserved."
- **m3** — The Required Invariant "settled lists in orchestrate stage briefs contain only owner-grade
  items" applies to ephemeral stdin, not a committed artifact, so it has no checker and no persistent
  home. State it as a behavioral instruction, not an invariant.
- **m4** — The BAD/GOOD pair lives verbatim in both the spec and the rule; "Nothing is duplicated"
  is slightly overstated (harmless — the spec freezes on implementation).

---

## Recommendations

1. **Resolve C1 before the plan.** Add a short cross-register mapping to D2: how each concept
   provenance grade lands as a spec force tag, what happens to `[OWNER-VERBATIM]` at the hop (carry
   the quote into a `[NEED]`? add a verbatim marker to the force register?), and which force tags may
   be marked settled by provenance (today the settled rule names `[INFERRED]`/`[INHERITED]` as
   never-settled but is silent on whether a `[NEED]` of unknown provenance may be). A single tag
   table showing the three families and where each applies would settle this and Dimension 8 at once.
2. **Scope B3 and the Core Concept (M2).** State plainly that provenance is checkable, correction is
   checkable via static signatures (best-effort), and surfacing + first-hop compression are
   write-time best-effort with no reviewer. The spec already concedes enforcement limits; the design
   should inherit that honesty rather than imply full structural coverage.
3. **Add the orchestrate line-9 reconciliation to the touch list (M1)** so the plan does not ship a
   self-contradicting command.
4. Fold the minors into the plan's per-file wording pass.

---

## Resolutions

_Resolved with the owner, 2026-07-10. All incorporated into the design._

- **[C1]** Owner approved the two-part fix. (a) `[NEED]` is sharpened to owner-stated
  by construction — an inferred stakeholder outcome is `[INFERRED]`. Spec-level settled
  eligibility: `[HARD]` (settled by the world, citation checkable) and `[NEED]`
  (settled by the owner); `[INFERRED]`/`[INHERITED]` never. (b) The concept→spec absorb
  mapping is defined in D2, with the quote as the carrier: `[OWNER-VERBATIM]` → `[NEED]`
  carrying the quote or a path-cite to the concept's Owner's-Words section (verbatim
  protection rides the compression law — no new spec tag); `[OWNER]` → `[NEED]`;
  `[AGENT]` → `[INFERRED]`; `[INHERITED: src]` → `[INHERITED]`, source carried. A tag
  table was added to D2 (also settles the Dimension 8 note).
- **[M1]** Accepted. The orchestrate touch now includes reconciling line 9: "one
  checkpoint at launch (Align); after that, you run to the end."
- **[M2]** Accepted. Core Concept and B3 scoped to actual enforcement reach: provenance
  structurally checkable at review; correction semi-checkable (static signatures, best
  effort); surfacing checkable only when performed (its omission is invisible);
  first-hop compression checked by exactly one person — the owner at capture, which is
  what the verbatim section is for.
- **[m1]** Accepted. Orchestrate named as the stated exception to the 1–10-line touch
  budget (~25 lines).
- **[m2]** Accepted. The review check is scoped to "referent present and its force
  stated" — force statedness is structural; force correctness is judgment.
- **[m3]** Accepted. Demoted from a Required Invariant to a behavioral instruction
  inside the orchestrate touch.
- **[m4]** Accepted. "Nothing is duplicated" overstatement struck; the contrast pair's
  frozen spec copy is acknowledged as a record, not a second live statement.

---

**Overall:** Revise
**Next Steps:** Once resolutions are recorded here, re-run `/_my_design` (or return to the
design-agent session) and point it at this review to incorporate. The reviewer does not edit the
design.
