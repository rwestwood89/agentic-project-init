# Spec: Decision Records (`.project/adr/`)

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-19 18:11
**Complexity:** MEDIUM
**Branch:** main

---

## Problem

The pipeline produces decisions faster than it preserves them. Load-bearing architectural
decisions — and the contracts and invariants they establish, especially across large seams
(major components, repos) — live scattered across completed specs, designs, remediation
epics, and chat history. `.project/` is treated as ephemeral and is too low-density to
serve as a record. Repo-official docs rot: a doc describing how the system works starts
decaying silently the day it is written.

The cost is concrete. The constraint-execution post-mortem (2026-07-19) traced a week of
remediation passes to knowledge that existed but had no durable, findable home: a consumer
repo discovered an integration constraint and the ruling never landed where the upholding
repo would read it; invariants were restated in several artifacts and drifted into
contradiction; new design work did not reliably read what earlier work had settled.

The insight that shapes the fix: **descriptions rot, decisions don't.** A dated "we decided
X because Y" stays true forever as a historical fact; the worst that happens is
supersession, which — unlike staleness — is markable. So the record is an append-only log
of decisions, not a maintained description of the system.

## Success Criteria

- [ ] A `project-pack/` convention doc defines `.project/adr/`: the written entry template
      (YAML frontmatter + body fields), the append-only + status-flip lifecycle, the
      density bar, provenance grading, and the cross-seam placement rule. New projects get
      the directory (seeded `INDEX.md` + README) from `init-project.sh`; existing projects
      bootstrap lazily via the helper script on first write.
- [ ] The helper script ships in `project-pack/scripts/` and is the only way numbers are
      allocated and statuses flipped; `INDEX.md` is regenerated, never hand-edited.
- [ ] `/_my_concept_design` Stage 1 sweeps both places — the repo's official documentation
      (wherever its norms put it) and `.project/adr/INDEX.md` — via research subagents, and
      the output document carries a Prior Art note naming the entries it builds on or
      proposes to supersede (explicitly empty when none exist).
- [ ] `/_my_design` skims `INDEX.md` so items that enter the pipeline at spec/design — never
      passing through concept-design — still hit the record.
- [ ] Accepting a design produces entries for its settled, load-bearing decisions; closing
      an item produces entries for decisions that emerged during implementation (deviations,
      discovered constraints, consumer workarounds), filed per the placement rule.
- [ ] All touched commands degrade gracefully when `.project/adr/` is absent or empty, and
      the Codex dist pack is rebuilt.

## Known Requirements

*(Provenance: owner-stated items tagged [NEED]; agent-proposed items ratified by owner
2026-07-19 tagged [INFERRED] per the absorb mapping in
`claude-pack/rules/capture-fidelity.md`.)*

- **[HARD]** The mechanism may depend only on `.project/` layout. agentic-project-init is
  installed across many repos with differing documentation norms and owns no other
  convention; anything keyed to a specific repo's docs layout breaks elsewhere.
- **[NEED]** The record lives at `.project/adr/`, distinguished from the rest of
  `.project/` by convention: durable and high-density, capturing intent beyond what is
  obvious from the code, restricted to load-bearing decisions and the contracts/invariants
  they establish across major seams.
- **[NEED]** Append-only strategy: new entries may amend or supersede old decisions; old
  entries are never rewritten.
- **[NEED]** The concept-design stage reviews history before designing: research subagents
  inspect both the repo's official documentation and the internal record.
- **[NEED]** Entries may optionally be promoted to repo-official docs when warranted; the
  record does not attempt to govern or replace those docs.
- **[INFERRED]** The single permitted mutation is a status flip: a superseded or amended
  entry (or its index line) is marked `superseded-by NNNN` / `amended-by NNNN`, because an
  old entry that doesn't know it is dead will be faithfully applied by a future agent.
- **[INFERRED]** Density bar as an entry test: an entry exists only if, without it, a
  future agent would plausibly re-derive the wrong thing or relitigate the decision.
- **[INFERRED]** Each entry records its reasoning (the *why*), not only the conclusion —
  the amendment discipline depends on re-deriving against recorded reasoning.
- **[NEED]** The entry template is written out for agents in the convention doc — the
  field semantics (decision, why, invariants established, seams, rejected alternatives,
  provenance grade) are judgment content agents must apply themselves.
- **[INFERRED]** Structure: `NNNN-slug.md` entries with YAML frontmatter for metadata
  (number, date, status, provenance, seams); `INDEX.md` is a generated artifact rebuilt
  from entry frontmatter, so the index can never disagree with the entries.
- **[INFERRED]** A helper script in `project-pack/scripts/` (installed to
  `.project/scripts/`) owns the deterministic operations: `adr new <slug>` allocates the
  next number, stamps date/owner, writes the skeleton, bootstraps the directory if absent,
  and regenerates the index; `adr supersede|amend <old> <new>` flips the old entry's
  frontmatter status and regenerates. Numbering and status flips never happen by hand.
- **[INFERRED]** Read enforcement is structural, not exhortative: the concept-design
  output requires a Prior Art section that cannot be filled without reading the index; an
  empty section is an explicit, falsifiable claim that nothing relevant exists.
- **[INFERRED]** Cross-seam placement rule: a decision lives in the repo that must uphold
  it, not the repo that discovered it; a dependent repo files a pointer entry citing it.
- **[INFERRED]** Write points: design acceptance (settled load-bearing decisions) and item
  close (emergent decisions, including workarounds against another repo's behavior —
  close-time write-back is the control that catches trapped consumer knowledge).
- **[INHERITED: claude-pack/rules/capture-fidelity.md]** Entries carry provenance grades
  (`[OWNER]` / `[AGENT]` / `[INHERITED: src]`), and amendment care follows the settled
  rule: owner-graded entries change by asking the owner; agent-graded entries by
  re-deriving against their recorded reasoning.

## Non-Goals

- **No current-state register or living architecture doc.** Owner-verbatim: "I don't want
  to get caught up trying to keep some 'docs' fully up to date — waste of tokens and will
  never actually work." Reconstructions of current truth (e.g. a lifecycle contract) are
  themselves dated entries, superseded when they drift — never maintained in place.
- No new audit-style command; `/_my_audit` and `/_my_orchestrate` are untouched in this item.
- No backfill of historical decisions in existing repos; the record starts from adoption.
- No governance of repo-official documentation; promotion is optional and one-way.

## Open Questions / Deferred to design

- Whether `/_my_wrap_up` also prompts the close-time write-back, or `/_my_close` alone
  carries it.
- Exact entry template fields (header metadata, seam tags, rejected-alternatives line) and
  the INDEX.md line format.
- Whether this repo seeds its own `.project/adr/0001` with this very decision (dogfooding).
- Whether `/_my_epic_plan` or `/_my_audit` gain read points later — revisit after first
  real use, not now.

---

## Related Artifacts

- **Source discussion:** constraint-execution post-mortem, this session (2026-07-19) —
  key evidence in `/home/reid/1cfe/sysml-codegen/.project/backlog/epic_constraint_execution_lifecycle_remediation.md`
  and the superseded remediation epics beside it
- **Rules:** `claude-pack/rules/capture-fidelity.md` (provenance vocabulary, settled rule)
- **Touched commands:** `claude-pack/commands/_my_concept_design.md`,
  `claude-pack/commands/_my_design.md`, `claude-pack/commands/_my_close.md`
- **Installer:** `scripts/init-project.sh` (standard-dirs creation, ~line 204),
  `scripts/build-codex-pack.sh` (dist rebuild)
- **Design:** `.project/active/decision-records/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
