# Audit: Anchor the Pipeline on the Point

**Verdict:** Needs Work
**Audited:** 2026-08-05
**Branch:** anchor-on-the-point
**Commit:** 823cd21 (dirty worktree)

---

## Summary

The shared lens, four Claude call sites, problem-carrying edits, smells, and ship-gate prompts are present, and fresh fixture runs verified commission, omission, duplicate-selection, and can't-find behavior. The work cannot be certified because the product lens found an unresolved owner-grade decision-record obligation, and the implementation still has gaps in problem carriage, ledger propagation, distribution reachability, and fail-closed enforcement.

## Product Judgment

**This is the right problem, but not yet the right completed work.** The audit lens recorded `Gate: BLOCKED` in `product-lens.md:12`: this feature changes the recorded pipeline touch-point contract without superseding or amending it, contrary to the owner-grade append-only decision rule (`.project/adr/0001-decision-records-convention.md:17`) and active ADR 0002 (`.project/adr/0002-adr-touch-points.md:17`). The implementation also trips the manual-synchronization and special-category smells because epic findings use a separate storage route that item ship gates do not read (`claude-pack/commands/_my_epic_plan.md:53`, `claude-pack/commands/_my_pre_pr.md:37`). An unresolved owner-grade block forbids certification regardless of the rubric below.

## Findings

### Plan completion

- **Phase 1 — substantially verified.** Both fixture files and the shared spec exist. Fresh uncoached runs caught the owner-grade commission, the positive omission, the duplicate-selecting-test smell, and the can't-find control without adopting the inherited workaround. `scripts/test_global_setup.sh` also passed and showed `product-lens.md` installed globally. The answer key nevertheless drifts from its input: it claims five tests and a non-shared route test (`fixture-expected-findings.md:19`, `fixture-expected-findings.md:59`), while the packet contains three tests and its route-B test uses the same shared `gain` source (`fixture-planted-input.md:62`). Align the fixture and answer key so the retained test oracle is exact.
- **Phase 2 — partial.** The design and plan edits are present (`claude-pack/commands/_my_design.md:294`, `claude-pack/commands/_my_plan.md:15`). The design requires the spec Problem to remain full and graded (`design.md:205`), but the spec template still gives the Problem no provenance instruction (`claude-pack/commands/_my_spec.md:76`). Add the missing grading requirement and exercise the generated design/spec artifacts before marking the remaining dry-run checks.
- **Phase 3 — partial.** All early call-site text exists, but the epic run writes its ledger block only into the epic (`claude-pack/commands/_my_epic_plan.md:53`); later gates read only per-item ledgers (`claude-pack/commands/_my_pre_pr.md:37`, `claude-pack/commands/_my_close.md:44`). Make an epic BLOCK reach every downstream consumer before treating the accumulating-ledger phase as complete.
- **Phase 4 — behavior verified with a limit.** A fresh prompt-level run returned Rework at design review and Needs Work at audit despite otherwise-green local checks. The audit instructions say any fired smell controls the verdict (`claude-pack/commands/_my_audit.md:44`), but the audit template forbids certification only for a “fired-and-unescalated” smell (`claude-pack/commands/_my_audit.md:109`). Remove that contradiction so escalation cannot be mistaken for resolution.
- **Phase 5 — partial.** Fresh prompt-level evaluation honored an existing BLOCK at design review, audit, pre-PR, and close; `test_adr.sh` passed 25/25, and the pipeline-sync/docs/global-setup checks passed. No live intended-contract-change transition, ADR supersession, vendored installation, Codex run, or BLOCK→disposition→clear end-to-end path was verified.

### Spec conformance

- **SC1 — gap.** Spec, design, and plan carry the problem, but the design-review output template carries only a generic Fundamental Assessment (`claude-pack/commands/_my_design_review.md:180`), and audit carries a gate/smell summary rather than the original problem (`claude-pack/commands/_my_audit.md:103`). A reader still cannot find the full problem at every review/certification hop as required by `spec.md:32`.
- **SC2 — verified.** The shared oracle-first protocol requires both DON'T commissions and DO omissions (`claude-pack/scripts/product-lens.md:27`), and a fresh fixture run produced both.
- **SC3 — not certified.** The loud judgments exist, and a fresh run stopped green work, but the audit-template contradiction at `claude-pack/commands/_my_audit.md:109` leaves a fired smell able to read as “escalated” without clearly remaining verdict-controlling.
- **SC4 — not certified.** The fresh fixture run found both stop paths, but the duplicate-smell verdict rule is internally inconsistent and the fixture answer key does not exactly match its input (`fixture-expected-findings.md:19`, `fixture-planted-input.md:62`).
- **SC5 — verified.** A fresh no-sources run produced a visible can't-find finding, refused to fabricate or inherit an oracle, and recommended disposition-and-proceed as specified (`claude-pack/scripts/product-lens.md:42`).
- **Replacement requirement — not met.** The superseded direction remains a full `Status: Draft proposal for owner review` (`.project/concepts/product-truth-gates.md:4`), and the replacement concept still asks whether to reuse it (`.project/concepts/anchor-on-the-point.md:236`). Remove the rejected path rather than leaving two live-looking directions; this is also required by saved project feedback.
- **Lens sites, two-direction checks, source grading, no canonical truth file, and audit ownership — met in the Claude source.** Evidence: `claude-pack/commands/_my_epic_plan.md:53`, `_my_spec.md:139`, `_my_design_review.md:42`, `_my_audit.md:37`, and `claude-pack/scripts/product-lens.md:27`.
- **Tiered enforcement and holistic smell control — partial.** The intended rules are present, but missing ledgers pass silently, epic blocks are not propagated, and audit's template weakens the smell rule (`claude-pack/commands/_my_pre_pr.md:37`, `_my_close.md:44`, `_my_audit.md:109`).
- **Non-goals — respected.** The implementation adds no generic review stage, always-on rule, canonical truth document, new provenance taxonomy, broad template teardown, mechanical CI block, or claim of perfect bug detection.

### Design conformance

- **Decision-record conflict.** The design says its decisions do not contradict ADR 0002 (`design.md:25`), but ADR 0002 explicitly leaves audit, spec, and epic-plan untouched (`.project/adr/0002-adr-touch-points.md:17`). Because ADR 0001 requires load-bearing cross-seam changes to be recorded (`.project/adr/0001-decision-records-convention.md:17`), this implementation must file and link the intended replacement and supersede or amend the active touch-point decision.
- **D2 / accumulating ledger is broken at the epic seam.** D2 requires one accumulating ledger so later gates see every finding (`design.md:131`), while the implementation stores the epic block in the epic artifact and never routes it to the per-item files that pre-PR and close inspect (`claude-pack/commands/_my_epic_plan.md:53`). Use one downstream-visible gate state for epic and item findings.
- **Reachability is incomplete.** Global setup reaches the shared lens through `scripts/setup-global.sh:145`. Self-contained vendoring copies it to `.claude/scripts/`, but every call site hard-codes `~/.claude/scripts/product-lens.md` (`scripts/init-project.sh:223`, `claude-pack/commands/_my_audit.md:39`), contradicting the documented independent vendoring mode (`README.md:284`). The Codex distribution is also stale and its builder does not copy this shared spec (`dist/codex/manifest.json:2`, `scripts/build-codex-pack.sh:360`). Resolve and test every supported distribution surface.
- **ADR clearing is incomplete.** The lens grades ADRs without requiring `status: active` and says a new/superseded ADR can clear a block (`claude-pack/scripts/product-lens.md:65`), while close creates only a new default-`[AGENT]` entry (`claude-pack/commands/_my_close.md:57`, `project-pack/scripts/adr.sh:127`). Require status-aware reads and the correct owner-visible supersession/amendment so conflicting active decisions cannot coexist.
- **Smell references drift.** The source concept calls duplicate selection smell six and ownership change smell seven (`.project/concepts/anchor-on-the-point.md:168`); the shared spec renumbers them seven and two (`claude-pack/scripts/product-lens.md:113`), while close still calls ownership change smell seven (`claude-pack/commands/_my_close.md:29`). Keep one stable numbering scheme or stop using numbers as cross-file identifiers.

### Code integrity

- **Silent fallback on a missing control:** pre-PR and close read `product-lens.md` only “if it exists” (`claude-pack/commands/_my_pre_pr.md:37`, `_my_close.md:44`). A skipped lens or broken install therefore looks clear. Treat the missing expected ledger as a control failure for in-scope audited work.
- **No abstraction slop or placeholder implementation was found.** The integrity concerns are contract drift, optional enforcement inputs, and unsupported distribution paths rather than god functions, broad exception swallowing, or parameter sprawl.

---

## Certification

Recorded the independent audit lens block, verified the shared mechanism and the two fresh fixture controls, ran the repository's ADR, pipeline-sync, docs, and global-setup checks, and marked only the corresponding plan/spec checkboxes. No parent epic exists, so no epic tracking file was changed. The item remains open with **Needs Work**.

**Not checked:** A real Claude slash-command invocation; a live vendored or Codex installation; an owner disposition with ADR supersession/amendment; and a complete persisted BLOCK → disposition → CLEAR run through audit, pre-PR, and close.
