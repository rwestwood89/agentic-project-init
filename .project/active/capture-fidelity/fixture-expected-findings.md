# Expected Findings — planted-concept fixture

Written **before** the dogfood run (fixture-first). Each plant should draw exactly one flag
from a review-posture agent given only `capture-fidelity.md` + `fixture-planted-concept.md`,
with no coaching about what to look for.

## P1 — settled ⊄ owner-grade
- **Where:** Next-Stage Handoff → "Settled here" list.
- **Plant:** an item graded `[AGENT]` sits in the settled / do-not-relitigate list.
- **Expected flag:** settled lists admit only owner-grade items; this one is agent-grade and
  is therefore challengeable, not settled. (Provenance law — the settled rule.)

## P2 — prohibition-mode record
- **Where:** Non-Goals / Out of Scope.
- **Plant:** "WE MUST NOT use a queue" — a rejection written as an all-caps prohibition
  aimed at future agents.
- **Expected flag:** correction metastasis; record the rejection as a decision ("Out of
  scope: a queue is not required because …"), not a prohibition. (Correction law — BAD.)

## P3 — binding referent softened into a vibe
- **Where:** Owner's Words vs Scope of Behavior Changes → New artifacts to create.
- **Plant:** the owner states the output must match `reports/foo/` **exactly** (a binding
  referent), but the body downgrades it to "loosely modeled … roughly that style, nothing
  strict."
- **Expected flag:** a binding referent softened into a vibe — the exact failure the
  compression law names ("a referent must not soften into a vibe"). Detectable in the
  artifact alone by comparing the two statements. (Compression law.)

  *(Refit 2026-07-10: the original P3 — a referent merely absent downstream — was not
  reviewer-detectable in a concept; the design assigns first-hop compression to the owner at
  capture, not a reviewer (`design.md:71`). Softening is detectable within one artifact.)*

## P4 — negation-shaped requirement
- **Where:** Success Criteria.
- **Plant:** "No caching layer is required (previously proposed, not needed)."
- **Expected flag:** negation-shaped requirement / content redundant with a Non-Goal; a
  retracted item should be deleted, not restated as an anti-requirement. (Correction law.)

## Pass bar
- **4/4** plants flagged (each matched to P1–P4 above).
- **≤ ~2** false positives on non-plant content (signature precision).
- Any plant missed → **gate fails**: record which signature the reviewer did not catch and
  return to design before Phase 3.
