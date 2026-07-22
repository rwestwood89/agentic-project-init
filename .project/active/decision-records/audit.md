# Audit: Decision Records (`.project/adr/`)

**Verdict:** Certify
**Audited:** 2026-07-19
**Branch:** decision-records
**Commit:** bfb0b00

---

## Summary

The implementation delivers the design faithfully: `adr.sh` owns every deterministic
operation (verified by 25/25 passing tests plus a live idempotency check), the convention
README carries the density bar, lifecycle, and cross-seam rule, and all four touch points
(R1/R2/W1/W2) landed as surgical extensions of existing command steps. One spec/design
wording conflict is surfaced below (installer seeding of `INDEX.md`); it is an artifact
discrepancy, not a functional gap. No plan.md exists for this item, so there is no
plan-completion area — the audit ran against spec and design directly.

## Findings

### Plan completion

No plan.md — item went design → implement in one session. Skipped.

### Spec conformance

Success criteria:

1. **Convention doc + seeding — met with one surfaced discrepancy.**
   `project-pack/adr/README.md` defines the template, append-only + status-flip lifecycle,
   density bar (verbatim from spec, with the required good/bad pair), provenance grading,
   and cross-seam rule. `init-project.sh:189` adds `adr` to the required-subdir loop and
   the merge copy delivers the README; `adr.sh new` lazily bootstraps elsewhere
   (`adr.sh:121,60`). **Discrepancy:** the criterion's parenthetical says new projects get
   a *seeded `INDEX.md`* from the installer. They don't — `project-pack/adr/` ships only
   the README, and the index first appears on the first `adr.sh` run. The approved design
   (D5) deliberately chose lazy index bootstrap, and the reads degrade gracefully without
   it, but the spec line was never amended. Per capture-fidelity law 4 this is surfaced,
   not resolved: either amend the spec parenthetical to match D5, or seed a placeholder
   index in `project-pack/adr/`. Owner call; checkbox left unmarked.
2. **Helper script sole allocator — verified.** `project-pack/scripts/adr.sh` implements
   `new`/`supersede`/`amend`/`index` exactly per the design interface; numbering
   (`adr.sh:95-108`, collision-guarded), status flips (`:162-196`), and index generation
   (`:59-93`, generated banner at `:85`) all live in the script. README states the
   never-by-hand rule (`README.md:43-47`); both command write-backs say "don't hand-mint
   ids." `test_adr.sh`: 25/25 pass, including hand-edit-discard and idempotency; live
   regeneration against this repo's real entries produced zero drift.
3. **Concept-design sweep — verified.** The sweep sits inside the mandatory
   Explore-subagent step (`_my_concept_design.md:111-120`), targets both repo-official
   docs (discovered, not assumed) and `INDEX.md`, and feeds a required Prior Art section
   (`:273-281`) with the falsifiable "index checked (N entries)" form; rubric gains the
   matching check (`:505`).
4. **Design skim — verified.** `_my_design.md:78` adds the index to Stage 1 Setup,
   full-reads on seam overlap, cites in Research Findings, and names the contradiction
   case a premise conflict with an explicit surfacing duty.
5. **Write points — verified.** Concept-design acceptance write-back at
   `_my_concept_design.md:444-451`; design acceptance at `_my_design.md:276-282`
   (scoped per D9 to design-settled decisions); close gains the emergent-decision scan
   (`_my_close.md:29`), the confirm-gate "Decisions to record" line with cross-seam
   placement (`:42`), and filing before archive (`:56-62`). Dogfooded: entries 0001–0002
   filed in this repo at W1.
6. **Graceful degradation + dist — verified.** All three commands state absent/empty reads
   as "no prior decisions, never an error"; missing-script case degrades to "note the
   gap." Codex dist rebuilt — `my-concept-design`, `my-design`, `my-close` SKILL.md files
   carry the same edits; manifest updated.

Tagged requirements: all `[HARD]`/`[NEED]`/`[INFERRED]`/`[INHERITED]` items traced and
met — `.project/`-only dependency, append-only with script-owned status flips, template
semantics in the convention doc, generated index, density bar, required Why, cross-seam
placement with pointer entries, provenance grades with the settled-rule amendment care
(`README.md:49-52`).

Non-goals respected: the commit touches only the three named commands — audit,
orchestrate, spec, epic-plan, wrap-up untouched; no current-state register anywhere; the
two seeded entries are this item's own W1 dogfooding (sanctioned by the design's
Integration Strategy), not backfill.

### Design conformance

Implementation follows the design: touch-point map exact (R1/R2/W1/W2, nothing else),
script interface verbatim, D1–D9 all honored. Required invariants hold in code: supersede
resolves the new entry before flipping the old (`adr.sh:166-167` — atomic pair), amend
never downgrades `superseded` (`:191`), bodies untouched by flips (test line 59), index
derived-only. Two additive deviations, both harmless: the skeleton stamps an `owner:`
field the design's example lacked (documented in the README table), and the index line
format differs cosmetically (design explicitly left it open for implementation).

### Code integrity

Minor findings, none blocking:

- `adr.sh:111` — `cmd_new` doesn't validate the slug. A slug with a space yields
  `0001-foo bar.md` (breaks the `NNNN-slug` convention); a slash fails mid-write after
  the id scan. Should reject slugs not matching `^[a-z0-9][a-z0-9-]*$`.
- `adr.sh:162` — `supersede <id> <id>` self-supersession isn't guarded; an entry can be
  marked superseded by itself. Should error when old-id equals new-id.
- `adr.sh:130` — titles are written unquoted, so a title containing ": " (entry 0002 has
  one) is invalid strict YAML. The script's own parser handles it, and the design mandates
  line-matching over YAML libraries, so this only matters if an external YAML tool ever
  reads frontmatter. Note, not a defect.

Failure honesty is good: `set -euo pipefail`, loud errors on unknown ids and missing
`.project/`, no silent fallbacks; the only default (`owner: unknown` without git config)
is reasonable.

---

## Certification

Checked: all 6 spec success criteria against the code (criteria 2–6 verified, criterion 1
verified except the seeded-`INDEX.md` parenthetical — surfaced above), all tagged
requirements, all 4 non-goals, design D1–D9, required invariants, script behavior via
`test_adr.sh` (25/25) plus live idempotency regeneration, Codex dist content spot-checks,
executable bits, and project-pack ↔ `.project` copy consistency.

Marked: spec criteria 2–6. Criterion 1 left unmarked pending the owner's call on the
seeding discrepancy (amend the spec line to match design D5, or seed a placeholder index
in `project-pack/adr/`).

**Resolution (2026-07-22):** owner chose to amend the spec parenthetical to match design
D5 (lazy `INDEX.md` bootstrap; the index is a generated artifact `adr.sh` owns, so it is
never seeded as a static placeholder). No code change — the shipped behavior already
matched D5. Criterion 1 now marked in `spec.md`.

**Not checked:** the manual flow rehearsals named in the design's Validation Approach —
no live `_my_concept_design` Stage 1 run against a seeded repo, and no live `_my_close`
run exercising the emergent-decision scan; the command-prompt wording is verified as
written, not as executed by an agent. Cross-repo W2 filing (writing into another repo's
`.project/adr/`) is untested anywhere. `update-templates.sh` consumer refresh was not
exercised. No epic parent exists, so no epic-level checks.
