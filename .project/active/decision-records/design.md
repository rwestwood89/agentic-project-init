# Design: Decision Records (`.project/adr/`)

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-19 18:11
**Branch:** main

## Overview

An append-only, high-density log of load-bearing decisions in `.project/adr/`, with a
helper script owning the deterministic operations and four touch points wiring it into the
pipeline: two reads (concept-design, design) and two writes (design acceptance, close).

## Related Artifacts

- **Spec:** `.project/active/decision-records/spec.md`
- **Rules:** `claude-pack/rules/capture-fidelity.md` (provenance grades, settled rule,
  compression law for pointer entries)
- **Origin:** constraint-execution post-mortem, 2026-07-19 (see spec Related Artifacts)

## Research Findings

- `init-project.sh` copies `project-pack/` file-by-file with a merge strategy — missing
  files are added to existing projects on re-run, user data never overwritten
  (`scripts/init-project.sh:172-190`); required subdirs are ensured at `:189-199`. So a
  README seeded in `project-pack/adr/` reaches existing repos with zero migration steps.
- Script precedent: `project-pack/scripts/get-metadata.sh` — plain bash, installed to
  `.project/scripts/`, invoked by commands via relative path. `adr.sh` follows it.
- `_my_close` is deliberately a non-judging archivist (`_my_close.md:9`) with a
  confirmation gate at Step 3 — the write-back check slots into its existing
  gather/confirm flow without changing its character.
- `_my_concept_design` Stage 1 already mandates a codebase exploration subagent and
  recursive reading of referenced docs — the ADR sweep extends an existing mandatory step
  rather than adding a new one.
- `_my_design` Stage 1 Setup already reads CLAUDE.md, spec, and Required Reading — the
  index skim is one more read in an existing list.
- `_my_wrap_up` is session-scoped and optional; `_my_close` is the mandatory last gate per
  item. Write point 2 goes to close (see D6).

## Core Concept

The record is a per-repo, append-only log of decisions — not descriptions. Each entry is a
dated `NNNN-slug.md` file whose YAML frontmatter carries the machine-readable metadata
(number, date, status, provenance, seams) and whose body carries the judgment content
(decision, why, invariants established, rejected alternatives). `INDEX.md` is a generated
artifact rebuilt from frontmatter, so it can never disagree with the entries. A ~50-line
bash script owns everything deterministic — number allocation, skeleton creation, status
flips, index regeneration, lazy bootstrap — leaving agents only the judgment.

The touch points follow one principle: **a read is enforced by an output that depends on
it; a write is attached to a gate the item cannot skip.** Concept-design must produce a
Prior Art section (can't be filled without reading); design must cite entries in its
research; design acceptance and item close are the two gates every substantial item passes,
so they carry the writes. Nothing else changes — audit, orchestrate, spec, epic-plan are
untouched, and orchestrated runs inherit the touch points for free because orchestrate
invokes these same commands.

## Key Bets

- **B1.** Agents consult a record only when a required output depends on it; exhortation
  alone changes nothing. *If false → the Prior Art section is ceremony and a lighter
  "please read" note would have sufficed — but the post-mortem evidence (maintained,
  ignored reference docs) says otherwise.*
- **B2.** Agents can apply the density bar — distinguishing load-bearing decisions from
  routine ones — well enough that the log stays high-signal. *If false → `adr/` silts up
  into `.project/`-grade sediment, index reads get expensive, and the record loses the
  trust that makes agents read it.*
- **B3.** A decision, unlike a description, stays true until explicitly superseded — so
  status flips are sufficient freshness maintenance. *If false → agents apply stale
  entries and we're back to rot, just slower.*
- **B4.** Repos on both sides of a seam run agentic-project-init, so the cross-seam
  placement rule always has a destination. *If false → the fallback (pointer entry
  locally + surface to owner) becomes the common path and upholding repos stay ignorant.*

## Key Decisions

- **D1.** `INDEX.md` is generated from entry frontmatter, never hand-edited. *Rejected:
  hand-maintained index (drifts from entries; two homes for one fact).*
- **D2.** The script is the only allocator of numbers and executor of status flips.
  *Rejected: agent-by-hand (duplicate numbers across parallel sessions, forgotten
  supersession marks — exactly the mechanical drift the post-mortem showed).*
- **D3.** Write points at design acceptance and close only. *Rejected: audit/orchestrate
  touch points (audit stays an evaluator per spec non-goal; orchestrate inherits
  everything through the stages it runs).*
- **D4.** Read mechanics differ by stage: concept-design uses its existing research
  subagent to sweep repo-official docs + the index and pull relevant full entries; design
  reads `INDEX.md` directly, pulling entries only on seam overlap. *Rejected: subagent
  sweep everywhere (token waste — the index is one small file).*
- **D5.** Seeding: `project-pack/adr/README.md` ships via the installer's merge copy;
  `adr.sh new` lazily bootstraps the directory and index anywhere they're absent.
  *Rejected: per-repo migration step (friction, and the merge copy already exists).*
- **D6.** `_my_close` carries the close-time write-back; `_my_wrap_up` is untouched.
  Close is the mandatory per-item gate with an existing confirm step; wrap-up is optional
  and session-scoped, so a write duty there can be skipped indefinitely. *Rejected:
  wrap_up (optionality defeats the control).* — resolves the spec's first deferred question.
- **D7.** The convention doc lives at `project-pack/adr/README.md`, so it lands inside
  every repo's `.project/adr/` and is self-carrying — an agent in a consumer repo reads
  the rules where the entries live. *Rejected: doc in agentic-project-init only (consumer
  repos would depend on pack access at read time).*
- **D8.** The entry skeleton has exactly two homes with one authority: `adr.sh new` emits
  it; the README explains field semantics. No third template file. *Rejected: separate
  `_template.md` (three copies to keep aligned).*
- **D9.** A decision is filed once, at the stage where it was settled; later stages cite
  the entry rather than re-filing. Concept-design acceptance files shaping-tier
  decisions; item-design acceptance files only decisions the design itself settled.
  *Rejected: file-at-every-stage (duplicate entries for one decision — the exact
  restatement drift this system exists to kill).*

## Architecture

### The touch-point map

```
                        .project/adr/  (per repo)
                        NNNN-slug.md entries + generated INDEX.md
                              ▲                    ▲
        reads                 │                    │              writes
  ┌───────────────────────────┤                    ├───────────────────────────┐
  │                           │                    │                           │
R1 concept_design Stage 1     │              W1 design acceptance              │
  subagent sweep:             │                after user approval of a        │
  repo-official docs          │                concept-design or design:       │
  + INDEX.md → pull           │                `adr.sh new` per settled        │
  relevant entries;           │                load-bearing decision           │
  output: Prior Art           │                (zero entries is the            │
  section (required)          │                common case — density bar)      │
  │                           │                    │                           │
R2 design Stage 1 Setup       │              W2 close Step 2/3                 │
  direct read of INDEX.md;    │                scan plan deviations, audit     │
  pull entries on seam        │                findings for emergent           │
  overlap; cite in Research   │                decisions; file entries —       │
  Findings; conflict ⇒        │                cross-seam rule applies;        │
  surfacing duty              │                shown in the confirm gate       │
  └───────────────────────────┴────────────────────┴───────────────────────────┘

  Untouched: _my_spec, _my_audit, _my_epic_plan, _my_orchestrate, _my_wrap_up.
  Orchestrated runs hit R1/R2/W1/W2 through the stages orchestrate invokes.
```

### Flows

**R1 — concept-design reads history.** Stage 1's existing exploration step gains a second
target: the research subagent inspects (a) the repo's official documentation wherever its
norms put it (docs/, ADRs, README — discovered, not assumed) and (b)
`.project/adr/INDEX.md`, returning the full text of entries relevant to the design area.
The output template gains a **Prior Art** section in the lower half: entries built on,
entries this design proposes to supersede, or an explicit "none relevant — index checked
(N entries)." The rubric gains one check. Absent/empty directory reads as "no prior
decisions," never an error.

**R2 — design skims the index.** Stage 1 Setup adds `INDEX.md` to its read list. Entries
whose `seams` overlap the item's area get read in full and cited in Research Findings.
If a design decision would contradict an active entry, that is a premise conflict:
surface it (capture-fidelity law 4) — either the entry gets superseded at W1 with the
owner's involvement per its provenance grade, or the design changes. Never both silent.

**W1 — acceptance files the settled decisions.** When the user approves a concept-design
or design, the authoring command asks: which decisions in this document pass the density
bar (would a future agent re-derive the wrong thing without a record)? For each: `adr.sh
new <slug>`, fill body, set provenance from how the decision was actually made
([OWNER]/[AGENT] per capture-fidelity), list seams. If the design supersedes an existing
entry (declared in Prior Art): `adr.sh supersede <old> <new>`. Per D9, file only
decisions this stage settled.

**W2 — close files what emerged.** Between gathering state and the confirm gate, close
scans plan.md deviation notes and audit.md findings for decisions made *during*
implementation: discovered constraints, deviations from design, workarounds against
another component or repo's behavior. Candidates appear in the Step 3 confirmation
("decisions to record: …" or "none found"), and approved ones are filed before archiving.
**Cross-seam rule:** a workaround against another repo's behavior files the ruling entry
in the repo that must uphold it (all pack repos have `.project/adr/` or `adr.sh`
bootstraps it); the discovering repo files a pointer entry citing it. If the upholding
repo is unreachable, file the pointer locally and surface to the owner.

### Entry format

```yaml
---
id: 0007
title: Late-fill entry injection is a supported evaluator capability
date: 2026-07-19
status: active            # active | amended | superseded
amended_by: []            # entry ids
superseded_by: null       # entry id
provenance: "[OWNER]"     # [OWNER] | [AGENT] (ratified …) | [INHERITED: src]
seams: [sysml-codegen/generation, fusion-tea]
supersedes: null          # entry id this entry replaces
promoted_to: null         # optional path in repo-official docs
---
```

Body sections: **Decision** (1–3 sentences) · **Why** (the reasoning a future challenge
re-derives against — required, not optional) · **Invariants established** (the
load-bearing list, may be empty) · **Rejected alternatives** (one-liners, phrased as
decision records per capture-fidelity law 3). A **pointer entry** replaces the body with
a one-line citation of the upstream repo + entry id — it never restates the decision.

### Script interface

```
adr.sh new <slug> [--title "…"]     # bootstrap dir if absent; allocate next id
                                    #   (scan files; on collision take next free);
                                    #   stamp date/owner via git; write skeleton;
                                    #   regenerate INDEX.md; print path
adr.sh supersede <old-id> <new-id>  # flip old entry frontmatter; regenerate index
adr.sh amend <old-id> <new-id>      # append to amended_by; regenerate index
adr.sh index                        # regenerate INDEX.md from frontmatter
```

`INDEX.md` line: `NNNN · title · seams · status[ → NNNN]` — one line per entry, active
entries first, generated banner at top ("generated by adr.sh — do not hand-edit").

## Required Invariants

- An entry's body is immutable after filing; only frontmatter status fields
  (`status`, `amended_by`, `superseded_by`, `promoted_to`) ever change, and only via the
  script.
- Every id is unique within a repo and allocated only by `adr.sh new`.
- `INDEX.md` is always regenerable from entries alone — it carries no information of its
  own and is never hand-edited.
- A supersede/amend is an atomic pair: the new entry exists before the old entry's flip,
  and both happen in one script invocation.
- Every entry records its Why; a challenge to an `[AGENT]` entry re-derives against it,
  a challenge to `[OWNER]` goes to the owner (capture-fidelity settled rule).
- Read touch points degrade to "no prior decisions" when the directory is absent or
  empty — never an error, never a blocked stage.
- One decision, one entry (D9): later artifacts cite, never restate or re-file.
- Pointer entries contain a citation only.

## Component Overview

| # | Component | Location | Responsibility |
|---|-----------|----------|----------------|
| 1 | Convention doc | `project-pack/adr/README.md` | Density bar, lifecycle, template field semantics, cross-seam rule, "durable unlike the rest of `.project/`" |
| 2 | Helper script | `project-pack/scripts/adr.sh` | All deterministic ops (see interface) |
| 3 | Installer touch | `scripts/init-project.sh` | Add `adr` to required-subdir loop (~`:190`); merge copy delivers README |
| 4 | R1 + W1 (shaping) | `claude-pack/commands/_my_concept_design.md` | Sweep both doc sources; Prior Art section + rubric check; acceptance write-back |
| 5 | R2 + W1 (item) | `claude-pack/commands/_my_design.md` | Index skim in Setup; cite entries; acceptance write-back per D9 |
| 6 | W2 | `claude-pack/commands/_my_close.md` | Emergent-decision scan + confirm-gate line + filing before archive |
| 7 | Dist | `scripts/build-codex-pack.sh` (run, not edited) | Mirror command edits to Codex pack |

## Non-Goals

- No current-state register or living architecture doc (owner-verbatim in spec).
- No touch points in audit, orchestrate, spec, epic-plan, wrap-up.
- No backfill of historical decisions; no governance of repo-official docs.
- No cross-repo index or aggregation — each repo's record stands alone; seams are
  connected by pointer entries, not tooling.

## Implementation Notes

- `adr.sh` follows `get-metadata.sh` conventions: plain bash, no dependencies beyond git
  and coreutils. Frontmatter parsing by `sed`/`awk` line matching, not a YAML library —
  the schema is flat key/value + one flow list, keep it that way.
- Command edits are surgical, matching this session's System Confidence edits in style:
  extend existing steps, don't add stages.
- Add `test_adr.sh` beside the existing `test_*.sh` scripts: bootstrap in a temp dir,
  allocate twice, supersede, verify index regeneration idempotent, verify collision
  retry.
- The README's density bar carries the entry test verbatim from the spec ("would a future
  agent re-derive the wrong thing or relitigate?") plus a short good/bad entry pair.

## Potential Risks

- **Silting (B2).** Mitigation: density bar with examples in README; Prior Art reviews
  naturally expose low-value entries; superseding junk entries is cheap.
- **Prior Art becomes rote** ("none relevant" without reading). Mitigation: the section
  requires the entry count ("index checked (N entries)") — a falsifiable claim; reviewers
  spot-check.
- **Cross-repo write friction** (W2 in another repo's tree). Mitigation: all target repos
  share the convention; the fallback (local pointer + surface) is explicit, not silent.
- **Frontmatter drift from hand edits.** Mitigation: `adr.sh index` is idempotent and
  cheap; the generated banner deters hand-editing; test covers regeneration.

## Integration Strategy

Ships entirely inside existing distribution channels: installer merge copy (new projects
and re-runs), `update-templates.sh` (consumer refresh), `build-codex-pack.sh` (Codex
mirror). Orchestrated pipelines pick up all four touch points with zero orchestrate
changes. First real exercise: the constraint-execution lifecycle work in sysml-codegen —
its owner-ratified lifecycle contract is a natural entry 0001 there, and this repo can
dogfood by filing this design's own decisions at W1 (resolves the spec's third deferred
question: yes, at implementation time).

## Validation Approach

- `test_adr.sh` covers the script invariants (allocation, collision, flips, idempotent
  regeneration, bootstrap).
- Manual flow rehearsal: run `_my_concept_design` Stage 1 against a repo with a seeded
  entry and confirm the Prior Art section cites it; run `_my_close` on an item whose
  plan.md contains a deviation note and confirm the confirm-gate lists it.
- Spec success criteria map 1:1 to components 1–7; check each at audit.

## Next-Stage Handoff

**Fixed:** the touch-point map (R1/R2/W1/W2 and nothing else), entry format, script
interface, D1–D9.
**Open for plan:** exact wording of command edits; README prose; `INDEX.md` cosmetic
format; test_adr.sh case list.
**First risk:** none behavioral — no spike needed; the only unfamiliar surface is
frontmatter handling in bash, which test_adr.sh pins.

---
Next Step: After approval → `/_my_plan` or `/_my_implement`
