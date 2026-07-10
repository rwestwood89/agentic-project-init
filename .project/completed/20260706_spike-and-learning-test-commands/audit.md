# Audit: Spike and Learning-Test Commands

**Verdict:** Certify
**Audited:** 2026-07-06
**Branch:** `main` (working tree, uncommitted — see note below)
**Commit:** b79c40c (base; feature changes not yet committed)

---

## Summary

The work delivers everything the spec asked for, and the delivery matches the design's decisions
without silent drift. Both commands exist, are installed, carry the shared four-part discipline,
and the spike side was proven live on a real unknown (the Codex YAML hazard, `findings.md`).
All mechanical validations re-ran clean during this audit. Two minor housekeeping notes below;
neither blocks certification.

**State note:** all changes are uncommitted in the working tree on `main`. The local branch
`spike-and-learning-test-commands` exists but has no commits — CURRENT_WORK.md's "Branch:" line
overstates the state. `/_my_pre_pr` needs to commit onto the branch before the PR.

## Findings

### Plan completion

All 4 phases verified complete.

- **Phase 1:** `claude-pack/commands/_my_spike.md` has the full staged process, header, invariants,
  reference voice, and Related Commands footer. Symlink re-verified
  (`readlink ~/.claude/commands/_my_spike.md` → `claude-pack/`). The live dry run's artifacts exist
  (`findings.md`, `probe_yaml_description.py`), the findings doc has summary-on-top and a
  reproducible log, and the loop was closed into `design.md:251` at the specific bullet the spike
  resolved. The target substitution (orchestrator spike → Codex YAML hazard) is documented and was
  a better target — it de-risked this feature's own Phase 4.
- **Phase 2:** `claude-pack/commands/_my_learning_test.md` re-read against the plan's four-point
  check: locates the repo's real test dir with no hardcoded path (`_my_learning_test.md:34-45`),
  tests never under `.project/`, findings doc at
  `.project/research/{YYYYMMDD-HHMMSS}_{topic-kebab-case}.md` — exactly `_my_research`'s convention
  (`_my_research.md:5`) — and Stage 5 closes the loop. Symlink verified.
- **Phase 3:** all 8 edits inspected in the diff. Each is soft (offers, never gates: "Still an
  offer, never a gate", "judgment call, not a required step", "optional tools, not pipeline
  stages"), sits at the named anchor, and distinguishes clear-goal-spike from
  fuzzy-surface-learning-test. `test_pipeline_sync.sh` re-run: passes, shape line untouched.
  `orchestrate-stage.sh run spike --dry-run` re-run: composes `/_my_spike …` with
  `--permission-mode bypassPermissions`.
- **Phase 4:** both description keys present in `codex-overrides/config.sh:35,45`, plain prose, no
  leading `*`. Both SKILL.md files exist in `dist/codex/skills/` and are installed to
  `~/.agents/skills/` with the `Generated from` marker. Strict PyYAML parse of both frontmatters:
  clean. README table rows and the CLAUDE.md "De-risking" section present and consistent.

### Spec conformance

All 9 success criteria verified met:

- Spike command exists, symlinked, resolves — verified above.
- Learning-test command exists, symlinked, resolves — verified above.
- Spike output placement (work-item folder when in play, else `active/spike-{topic}/`) —
  `_my_spike.md:31-38`; the work-item branch was exercised live.
- Learning-test output split (real tests in repo's test dir, agent locates, no hardcoded path,
  never `.project/`) — `_my_learning_test.md:34-45` and the Required Invariants block.
- Close the loop, both commands — Stage 5 in both, backed by a Required Invariant; proven live for
  spike (`design.md:251`).
- Use case unmistakable — both Overviews open with the contrast and point at the sibling.
- Pipeline suggestions at the right moments — `_my_concept_design.md` (First risk to de-risk),
  `_my_spec.md` (Offer research, don't guess), `_my_design.md` (REFLECT/Assumptions).
- CLAUDE.md + README document both and when to reach for each.
- Codex-exposed: keys added, built, installed.

Tagged requirements: both `[HARD]`s satisfied (setup-global.sh ran; description overrides + build +
install done). All four `[NEED]`s met. Both `[INFERRED]`s delivered (conventions followed;
epic_plan + research wiring in).

Non-goals respected: pipeline shape untouched (sync test passes), no test-layout prescription, no
runtime machinery. The orchestration wiring (orchestrate/pipeline/`orchestrate-stage.sh`) is a
scope addition beyond the spec, made at the user's explicit request and documented as a Phase 3
deviation — not a silent scope creep. The `bypassPermissions` default for spike/learning_test is
consistent with the existing implement/pre_pr precedent and was flagged to the user.

### Design conformance

Implementation follows the design. D1–D6 all held: two separate files, spike co-location,
findings→research + tests→repo split, no hardcoded test path, Codex-included, soft wiring at the
named anchors. All six Required Invariants appear verbatim as "Required Invariants (never
violate)" blocks in both commands.

One documented refinement, not a silent deviation: the design's fixed close-the-loop mapping
(doc type → links section) proved too rigid in the dry run; the commands now prefer the in-context
spot with the fixed mapping as fallback (`_my_spike.md:82-88`). Recorded in the plan's Phase 1
deviations and improved before Phase 2 copied it — exactly the sequencing the plan required.

### Code integrity

The deliverables are markdown prompts plus a one-line shell case extension; no slop or
failure-honesty issues. Two minor findings:

1. **`**Last Updated**` footers not bumped in the modified commands.** None of the seven edited
   command files updated their footer date (e.g. `claude-pack/commands/_my_research.md:170` still
   says 2025-12-31 after this change). Cosmetic; fix opportunistically in pre_pr.
2. **Work uncommitted on `main`.** The feature branch exists but is empty; everything sits in the
   working tree. Not an implementation defect, but pre_pr must commit onto the branch first, and
   CURRENT_WORK.md's branch claim was ahead of reality until then.

The spike's own open follow-up (the build silently corrupts a leading-`&` description and
validates nothing — `build-codex-pack.sh:250`) is correctly scoped out and recorded in
`findings.md` for whoever hardens the build.

---

## Certification

Checked: all 4 plan phases against their validation blocks (mechanical checks re-run, not taken on
trust), all 9 spec success criteria, all tagged requirements and non-goals, design decisions
D1–D6 and all Required Invariants, and the integrity of the edited files.

Marked: all 9 spec success criteria `[x]`. Plan checkboxes were already complete and verified
accurate. No epic (standalone item). CURRENT_WORK.md updated to certified.

Nothing left open for certification. The two minor findings above are pre_pr housekeeping, not
gaps.
