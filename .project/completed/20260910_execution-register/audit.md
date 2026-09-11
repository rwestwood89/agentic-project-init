# Audit: Execution Register, Write-Only

**Verdict:** Certify (resolved 2026-09-11 — see Resolution below)
**Audited:** 2026-09-10
**Branch:** mental-model-reviewer
**Commit:** 78ea3b5

---

## The Point

An agent that learns how this codebase or environment behaves needs one git-tracked, append-only home for that fact, distinct from decisions, product promises, and corrections to pack prompts. The register ships with a write prompt and no reader so the owner can review what agents choose to save before deciding whether a read path is worth building.

## Summary

The register seeds correctly, survives `--force`, ships empty, reaches the generated Codex skill, and removes the old CHANGELOG field. It cannot be certified because the shipped rules add the owner-forbidden reader, the routing boundary is duplicated across three surfaces, the close wiring test cannot prove the prompt exists or is unique, the required grep fails, and the real close acceptance has not run.

## Product Judgment

This is the right piece of work, but the implementation is not the write-only experiment the owner authorized. The product-lens ledger gate is **BLOCKED** by `audit-F1`: `project-pack/execution/README.md:53-61` gives agents an exact command for retrieving accumulated entries despite the owner-grade no-reader decision. Smell 1 fires because the routing boundary is manually duplicated, and smell 6 fires because the test can pass through duplicate non-prompt references; both remain unresolved and independently forbid certification.

## Findings

### Plan completion

- Phase 1's register, installer protection, documentation test, and focused seed/refresh behavior are verified. The cold-read check remains open, and the fresh-target dry run at `scripts/init-project.sh:208-214` reports only the whole `project-pack/` copy rather than showing the register being added as `plan.md:116` requires.
- Phase 2's field removal and consolidated close scan are present, but its final acceptance is incomplete: the required grep still matches `claude-pack/commands/_my_close.md:114` and `dist/codex/skills/my-close/SKILL.md:121`. Remove or reword those two footer references so the stated command returns no output.
- Phase 3 is incomplete. `project-pack/TRIAGE_MEMORIES.md:19-25` restates the boundary that `plan.md:230` says to reference without restating, and `project-pack/TRIAGE_MEMORIES.md:21` does not carry the designed direct rule that a memory with no reconstructable ADR **Why** becomes a pack-repo ticket. Point the prompt to the canonical boundary and state the missing transition.
- Phase 4's docs, generated Codex surface, live seeding, empty logs, nine safe test scripts, and `git diff --check` are verified. `plan.md:298`'s old tracked-backup blocker is gone, but the literal full suite was not completed in this sandbox; `test_init_project.sh` reaches Test 7 and attempts to write the real home metadata before Test 9. The real-item close acceptance at `plan.md:304` remains open.

### Spec conformance

- SC1 — **Not verified.** Static text contains one consolidated scan, but no real `/_my_close` run proves exactly one prompt, acceptance of “none,” or a conforming write (`plan.md:304`). Add a customer-shaped acceptance check or record the required real run.
- SC2 — **Not met.** The “Reading entries back” section and `awk` command at `project-pack/execution/README.md:53-61` hand an agent the existing contents. Remove that section from the template and live copy, then append a ledger resolution for `audit-F1`.
- SC3 — **Verified.** The density bar, worked good/bad examples, and native-store warning are present at `project-pack/execution/README.md:7-27`.
- SC4 — **Verified.** The log is protected while the rules and triage prompt refresh; the implementation is at `scripts/init-project.sh:122-129,189-214` and passed a focused fresh-init/`--force` fixture.
- SC5 — **Verified.** Test 9 covers seed, log preservation, rules refresh, and triage refresh at `scripts/test_init_project.sh:335-389`; the behavior also passed independently in a scratch repo.
- SC6 — **Not met.** The exact required grep returns the footer matches at `claude-pack/commands/_my_close.md:114` and `dist/codex/skills/my-close/SKILL.md:121`.
- SC7 — **Verified.** `project-pack/execution/ENTRIES.md:1-7` and `.project/execution/ENTRIES.md:1-7` are identical header-only logs with zero entries.
- SC8 — **Verified at the criterion level.** The generic prompt is seeded by the recursive copy, is direct-reference only, identifies the pack-repo ticket case, and requires `Source:` on every triage-filed entry (`project-pack/TRIAGE_MEMORIES.md:3-5,29-43`). The stricter design rule for missing ADR **Why** is a separate conformance gap above.
- Tagged requirements — Both `[HARD]` installer requirements are met (`scripts/init-project.sh:122-129` plus Test 9). The ship-empty, field-removal, close-beat, project-pack delivery, generic triage, ticket, and append-only `[NEED]`s are mechanically present; the exact close behavior remains unverified. The `[INFERRED]` no-reader requirement fails. The remaining layout, example, warning, scan/confirm/write, tag, live-copy, docs, protected-CHANGELOG, and Codex-build requirements are met.

### Design conformance

- The two-file register, user-data asymmetry, one record scan, three destinations, empty log, entry shape, docs, ADR 0013, and generated Codex surface follow the design.
- The no-reader invariant is violated by `project-pack/execution/README.md:53-61` and `.project/execution/README.md:53-61`. Delete the retrieval section; wording that nothing reads the log “automatically” is weaker than the design's “nothing reads the file back at any point” (`design.md:109,114`).
- D8's duplication-avoidance rationale is not delivered. The boundary appears in `claude-pack/commands/_my_close.md:29-34`, `project-pack/execution/README.md:21-27`, and `project-pack/TRIAGE_MEMORIES.md:19-25`, while `design.md:74,97` says consolidation avoids manually synchronized copies. Consolidate the routing authority or add an explicit synchronization control and document the deviation.
- Seam 4 requires no reconstructable ADR **Why** to route directly to a ticket (`design.md:105`). The prompt only says the note is not a decision record (`project-pack/TRIAGE_MEMORIES.md:21`) and leaves the ticket consequence implicit behind the later no-home rule at `:31`. State the direct route.

### Code integrity

- **Smell 1 fires:** three prose boundary representations must be kept synchronized, and they already name different destination sets (`claude-pack/commands/_my_close.md:29-34`, `project-pack/execution/README.md:21-27`, `project-pack/TRIAGE_MEMORIES.md:19-25`).
- **Smell 6 fires:** `scripts/test_docs.sh:92` uses `grep -q` for any `execution/ENTRIES.md` occurrence. Confirmation and filing references at `claude-pack/commands/_my_close.md:48,69` keep it green even if the actual prompt at `:32` is removed. Replace it with a structurally scoped or customer-shaped assertion that proves the scan prompt and rejects duplicates.
- No god function, implicit mode, parameter sprawl, leaky helper, deep nesting, broad exception fallback, compatibility shim, optional-parameter escape hatch, or smells 3-5 were introduced by this item.

---

## Certification

Verified and marked spec SC3, SC4, SC5, SC7, and SC8; marked the corresponding epic seed/protection and test-coverage boxes. Marked the completed `test_docs.sh` and `git diff --check` plan validations, and reopened plan claims contradicted by the implementation. Certification remains open pending resolution of `audit-F1` through `audit-F3`, the failing exact grep, the missing ADR-Why-to-ticket instruction, and real close acceptance.

**Not checked:** A live `/_my_close` run on a real item; a complete literal `for t in scripts/test_*.sh` run including all of `test_init_project.sh`; behavior of the installed Claude command outside the repository; long-term entry quality or whether Item 3's later `wrap_up` beat completes the experiment.

---

## Resolution — 2026-09-11

Re-checked against the code. The three findings above are closed:

- **audit-F1 (no reader) — fixed.** The "Reading entries back" section and its `awk` command are gone from `project-pack/execution/README.md` and `.project/execution/README.md`. Nothing in the pack reads the log back; both logs are header-only with zero entries.
- **audit-F2 (duplicated routing boundary) — fixed.** `project-pack/TRIAGE_MEMORIES.md:19` now points at the canonical boundary in `execution/README.md` instead of restating it, and `:21` states the ADR-Why-to-ticket route directly.
- **audit-F3 (weak close-beat test) — withdrawn, not fixed.** The finding was correct: `test_docs.sh` greped `_my_close.md` for a string that appears three times, so it could not prove the prompt existed. The remedy chosen was to delete that test and its five siblings rather than write a better grep. Greping a prompt file to prove an instruction exists does not work — reword the line and the check either breaks for nothing or passes while the instruction is gone. Owner decision, 2026-09-11.

The verdict was flipped from Needs Work to Certify on that basis.
