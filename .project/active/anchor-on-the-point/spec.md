# Spec: Anchor the Pipeline on the Point

**Status:** Remediation v3 applied — pending re-audit (2026-08-05)
**Owner:** Reid W
**Created:** 2026-08-05 14:21:17 PDT
**Complexity:** HIGH
**Branch:** anchor-on-the-point

---

## Problem

The pipeline is meant to make agent-built code trustworthy by carrying the reason for the
work through independent stages and checking the result. In practice, each stage mainly
checks the artifact one hop upstream. If one agent narrows the product's point, later
stages can produce internally consistent specs, designs, tests, and audits for the wrong
work.

The sysml-codegen fan-out incident is the evidentiary bar. The pipeline encountered a
violation of the repository's central source-identity promise, reclassified it as expected
mechanism behavior, encoded it in green tests, certified it, and later normalized a
consumer workaround. The product's point lost to the coherence of the artifact chain.

The pipeline reinforces this failure by removing the full problem from downstream
artifacts, rewarding complete templates over holistic judgment, and letting mechanism
categories make a product contradiction look locally valid. Existing surfacing prose did
not stop the incident because no independent evaluator re-derived the point and no loud
product judgment outranked the green rubric.

## Success Criteria

- [ ] **[INHERITED]** A reader can trace work from shaping through design, planning,
  review, and audit and find the original problem stated legibly at each decision-bearing
  hop, rather than only a pointer or the previous artifact's narrowed account.
- [x] **[INHERITED]** Independent product checks detect both directions of drift: work
  that contradicts the product's point and work that omits an obligation the point
  requires.
- [x] **[INHERITED]** A review or audit can judge that the work is wrong even when every
  conventional rubric item is green, and every fired structural smell is raised into that
  judgment rather than buried in checklist detail.
- [x] **[INHERITED]** An adversarial pipeline fixture reproducing the fusion-tea failure
  shape is stopped independently by the product check and by the duplicate-selecting-test
  smell, despite green local tests and a plausible inherited explanation.
- [x] **[INFERRED]** *(Agent recommendation ratified by owner, 2026-08-05.)* A repository
  with no durable statement of its product point produces a visible finding that requires
  disposition instead of a fabricated or silently inherited oracle.

## Known Requirements

- **[NEED]** This work replaces the `product-truth-gates` direction; the two are not
  parallel active solutions. (Owner, 2026-08-05.)
- **[INHERITED]** The full problem must remain present and legible in downstream pipeline
  artifacts. A link alone is not an adequate replacement for the problem statement.
  (`.project/concepts/anchor-on-the-point.md`, “The fix,” move 1.)
- **[INHERITED]** Carrying the problem must modify the existing stage artifacts rather
  than introduce a separate problem artifact. (`.project/concepts/anchor-on-the-point.md`,
  “The fix,” move 1.)
- **[INHERITED]** A single-job product-lens agent must independently derive the product's
  point and compare the current work against it at `epic_plan`, `spec`, and
  `design_review`. (`.project/concepts/anchor-on-the-point.md`, “The fix,” move 2.)
- **[INFERRED]** *(Agent recommendation ratified by owner, 2026-08-05.)* `audit`, rather
  than `pre-pr`, owns the implementation-level product-lens pass and loud product
  judgment.
- **[INHERITED]** The product lens must report both commissions and omissions: what the
  work does against product intent and what it fails to do despite product intent.
  (`.project/concepts/anchor-on-the-point.md`, “The fix,” move 2.)
- **[INHERITED]** Every product-lens finding must state the source and its authority so an
  agent inference cannot acquire the force of an owner decision or hard external
  constraint. (`.project/concepts/anchor-on-the-point.md`, “The fix,” move 2.)
- **[INFERRED]** *(Agent recommendation ratified by owner, 2026-08-05.)* The lens must
  discover and grade existing product sources such as the README, product documentation,
  and ADRs. It must not depend on a newly required canonical product-truth document.
- **[INFERRED]** *(Agent recommendation ratified by owner, 2026-08-05.)* An unresolved
  owner-backed or hard-source contradiction blocks the current stage. Lower-authority
  findings require a visible disposition and may proceed.
- **[INHERITED]** Review and certification artifacts must lead with a holistic answer to
  “is this the right piece of work?” That answer can control the verdict even when the
  detailed rubric passes. (`.project/concepts/anchor-on-the-point.md`, “The fix,” move 3.)
- **[INHERITED]** The existing review and audit rubrics remain in place, with the seven
  structural smells from the source concept added as mechanical tripwires at the design
  or code/test layer identified there. Any smell that fires must escalate into the
  holistic judgment. (`.project/concepts/anchor-on-the-point.md`, “The seven smells.”)
- **[INHERITED]** The fusion-tea failure is the acceptance referent. The check must resist
  a locally coherent mechanism distinction, green preservation evidence, a test that
  selects one duplicate, and a consumer-side workaround. (`.project/concepts/anchor-on-the-point.md`,
  “The test: would this have caught fusion-tea?”)

## Non-Goals

- **[INHERITED]** Adding another generic review stage.
- **[INHERITED]** Adding another always-on prose rule as the primary control.
- **[INHERITED]** Replacing the existing provenance vocabulary or pipeline with a new
  taxonomy.
- **[INHERITED]** A broad teardown of existing artifact slots or jargon. Targeted trimming
  may be designed where it directly improves the signal of the problem statement or loud
  judgment.
- **[INHERITED]** Guaranteeing that an agent will never miss a bug. This work prevents one
  missed or normalized product contradiction from silently becoming the downstream
  contract.

## Open Questions / Deferred to design

- What durable record carries findings, dispositions, blocking state, source authority,
  and the exact artifact revision checked?
- How does a product-lens invocation remain independent of the immediate artifact's frame
  while receiving enough information to evaluate the actual work?
- Which source qualities distinguish owner-backed or hard product truth from an
  aspirational document or an agent inference?
- How should the lens make the product point falsifiable for shaping and other non-code
  work where no executable test exists?
- How do `epic_plan`, `spec`, `design_review`, and `audit` consume and propagate findings
  without turning the result into another large template?
- Does the existing decision-record mechanism store any accepted change in product intent
  or invariant ownership, and if so, what link is required from a finding?
- Which existing slots or instructions should be trimmed or reworded beyond reversing the
  plan's anti-restatement rule and adding the missing design problem statement?

---

## Related Artifacts

- **Source concept:** `.project/concepts/anchor-on-the-point.md`
- **Research:** `.project/research/20260803-210317_pipeline-product-truth-control-review.md`
- **Forensic referents:**
  - `/home/reid/1cfe/sysml-codegen/.project/research/20260803-202453_backtracking-fanout-forensics.md`
  - `/home/reid/1cfe/sysml-codegen/.project/research/20260803-203011_entry-surface-fanout-forensics.md`
- **Design:** `.project/active/anchor-on-the-point/design.md`

---

**Next Steps:** After approval, proceed to `my-design`.
