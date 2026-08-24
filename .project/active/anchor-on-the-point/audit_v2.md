# Audit v2: Anchor the Pipeline on the Point

**Verdict:** Needs Work
**Audited:** 2026-08-05
**Branch:** anchor-on-the-point
**Commit:** 823cd21 + worktree
**Prior audit:** `.project/active/anchor-on-the-point/audit.md`

---

## The Point

The pipeline exists to identify and stop wrong work before a chain of internally consistent
artifacts, green tests, and reviews turns it into the accepted contract. The original failure was
not a missing checklist item. One agent narrowed the product obligation, every later stage trusted
that narrowed account, and the pipeline certified a violation of the repository's central promise.

This work must therefore keep the full problem legible at each decision-bearing hop, independently
re-derive product obligations from graded sources, and make a contradiction or structural smell
control the verdict even when the ordinary rubric is green.

## Summary

The remediation closed most findings from the first audit. The concrete ADR 0002 conflict is now
recorded through ADR 0003, missing ledgers fail closed, the fixture and smell numbering agree, and
the review/audit templates now carry the point and make escalation control the verdict.

Certification still fails. The plan template does not structurally carry the problem, amended ADRs
are incorrectly treated as dead, epic findings can drift or lose authority when copied to items,
epic-scope audit skips the independent lens, and a later ordinary `CLEAR` can mask an earlier
unresolved `BLOCK`.

## Product Judgment

**This remains the right work, but the control is not yet safe to trust.** The fresh product-lens
run is recorded at `product-lens.md` under `audit_v2` with `Gate: BLOCKED`. Smell 1 fires because an
epic finding is represented both in the epic and in copied item ledgers
(`_my_epic_plan.md:53`, `_my_spec.md:154-157`). Smell 3 also remains undispositioned because ADR
0003 preserves the old “exactly four touch points” statement by assigning the new ADR reads and
writes to a special product-lens category (`.project/adr/0003-product-lens-touch-points.md:27-44`).
Under the implemented rule, either undispositioned smell forbids certification.

## Findings

### Plan completion

- **Phase 2 is incomplete: the plan still drops the problem.** `_my_plan` tells the writer to carry
  it (`claude-pack/commands/_my_plan.md:15-19`), but the output skeleton goes from Source Documents
  directly to Implementation Strategy with no Problem or The Point field
  (`claude-pack/commands/_my_plan.md:108-123`). This item's plan demonstrates the failure: its
  opening states phasing and mechanism but not the original pipeline problem
  (`.project/active/anchor-on-the-point/plan.md:7-32`).
- **Phase 5's ship-gate proof is incomplete.** The ledger format permits a later block with
  `Gate: CLEAR`, while pre-PR checks only that the latest gate is not blocked
  (`claude-pack/scripts/product-lens.md:90-106`, `claude-pack/commands/_my_pre_pr.md:37`). No rule
  requires that later block to cite and validly resolve every earlier `BLOCK`. Close has the same
  gap (`claude-pack/commands/_my_close.md:44`).
- The intended-contract-change path is verified by ADR 0003, the amendment of ADR 0002, and the
  appended disposition block. The complete live command-level BLOCK → disposition → pass walk
  remains unchecked as the owner recorded in the plan (`plan.md:380-382`).

### Spec conformance

- **SC1 — gap.** Design, design-review, and audit now have explicit full-point slots
  (`_my_design.md:294-299`, `_my_design_review.md:180-188`, `_my_audit.md:103-120`). Plan does not,
  so the required shaping → design → plan → review → audit trace still breaks at planning
  (`spec.md:32-34`).
- **SC2 — verified for item work and the fixture.** The oracle-first protocol checks both
  commission and omission (`claude-pack/scripts/product-lens.md:29-44`), and the fixture contains
  both forms (`fixture-expected-findings.md:24-43`).
- **SC3 — verified.** Design review forces Rework and audit forbids Certify when the lens or a
  smell controls the judgment (`_my_design_review.md:47-53`, `_my_audit.md:113-120`).
- **SC4 — verified.** The fixture exposes two outputs from one owner-backed source and a green test
  that selects one duplicate (`fixture-planted-input.md:16-29`, `:52-69`). The product rule and
  smell 6 independently force BLOCK and Needs Work (`product-lens.md:65-77`, `:112-129`).
- **SC5 — verified.** Can't-find refuses to manufacture an oracle and requires visible disposition
  (`product-lens.md:42-44`, `:68-80`).
- **Source authority is not yet preserved end to end.** `_my_spec` calls a copied epic finding
  “inherited” without requiring preservation of its original source grade and BLOCK force
  (`_my_spec.md:154-157`). An owner/`[HARD]` epic finding can therefore be downgraded at the hop.
- **The replacement requirement is met.** The earlier proposal file is gone and its owner quotes
  are retained in the replacement concept (`.project/concepts/anchor-on-the-point.md:13-20`).

### Design conformance

- **D1 and D7 — met.** One shared product-lens spec drives general-purpose subagents at the item
  call sites (`claude-pack/scripts/product-lens.md:1-7`).
- **D2 — not met.** The design requires one accumulating per-item ledger. The implementation first
  embeds a verdict in the epic and later copies findings into item ledgers
  (`_my_epic_plan.md:53`, `_my_spec.md:154-157`). A new epic finding or disposition after item
  creation does not reach existing ledgers, so the representations drift.
- **D3 / no-manufactured-authority — not met for amended ADRs.** The lens says only `status:
  active` ADRs bind and an amended entry does not bind (`product-lens.md:65-76`). Project ADR
  semantics say amendment adjusts the old decision without killing it
  (`.project/adr/README.md:31-40`), and ADR 0003 explicitly preserves ADR 0002's core
  (`.project/adr/0003-product-lens-touch-points.md:38-44`). The lens can discard surviving clauses.
- **D4 — met.** Intended contract changes use a new owner-visible ADR plus amendment/supersession;
  ordinary lower-authority dispositions do not file ADRs (`product-lens.md:82-86`).
- **D5 and the enforcement invariant — not met.** Missing ledgers now fail closed, but trusting
  only the latest gate allows an unresolved historical owner/`[HARD]` finding to disappear without
  an authorized disposition.
- **D6 / four run sites — incomplete for epic scope.** Work-item audit runs the lens
  (`_my_audit.md:37-47`), while the separate epic-scope flow can certify without one
  (`_my_audit.md:161-186`). An aggregate omission can therefore escape the independent audit pass.
- **Absence and escalation invariants — met.** Can't-find is loud, and escalation is explicitly not
  resolution (`product-lens.md:72-80`, `:112-115`; `_my_audit.md:113-120`).

### Code integrity

- The fresh lens fired smell 1 and smell 3 as described in Product Judgment. Neither has a recorded
  disposition, so the implemented escalation rule makes them blocking findings.
- The completion note still calls duplicate selection “smell 7,” although the canonical list now
  makes it smell 6 (`plan.md:293-299`, `product-lens.md:117-129`). This is minor tracking drift.
- No placeholder implementation, debug artifact, broad fallback, or unrelated change was found in
  the reviewed prompt and fixture changes. `git diff --check` is clean.

## Certification

**Needs Work.** This pass marks SC3 and SC4 because the command behavior and adversarial fixture
were re-verified. It also marks the intended-contract-change validation in Phase 5. SC1 and the
end-to-end enforcement validations remain open. The latest product-lens gate is BLOCKED.

Validation run: `scripts/test_adr.sh` (25/25), `scripts/test_pipeline_sync.sh`,
`scripts/test_docs.sh`, `scripts/test_global_setup.sh`, and `git diff --check` all passed.

**Not checked:** a live Claude slash-command execution; a live vendored or Codex installation; and
an executable full command-chain test from lens finding through ledger, review/audit verdict,
pre-PR/close refusal, authorized disposition, and final pass. The vendored/Codex and live E2E
limits are owner-deferred; they are not treated as passed.
