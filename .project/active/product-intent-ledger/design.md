# Design: Product Intent Ledger

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-09 20:22 PDT
**Branch:** anchor-on-the-point (item branch TBD)
**Commit at draft:** fc48123

## Overview

A second append-only ledger in `.project/` — sibling to `.project/adr/` — that records the
product's major *implemented promises* with a derived current index, plus the smallest read and
write touch points to make cold agents and the product-lens actually use it.

## Related Artifacts

- **Spec:** `.project/active/product-intent-ledger/spec.md`
- **Concept:** `.project/concepts/product-intent-ledger.md`
- **Research:** `.project/research/20260803-210317_pipeline-product-truth-control-review.md`
- **Product-lens ledger:** `.project/active/product-intent-ledger/product-lens.md`
- No epic; single scoped item per concept decomposition guidance.

## The Point

Agents reliably learn *what work is active* but not *what the product is for*. The owner's
recurring redirection is "reminders of what the point of our code is" (**[OWNER-VERBATIM]**,
concept Owner's Words), and the product-lens re-derives the product's point from scattered
sources on every run, with no stable collection of the major promises last recorded as
implemented. The obligation: give cold coding agents and product-lens agents one sparse,
durable, current orientation surface for implemented product promises — serving both equally
(**[OWNER-VERBATIM]** "yes, should serve both equally") — without adding ceremony, mandatory
evidence, or a completeness gate (**[OWNER-VERBATIM]** "please don't make this too mechanical /
unnecessary ceremony"). Grade: owner-originated, absorbed through the concept's Owner's Words.

## Research Findings

- **The ADR convention already solved this feature's hard mechanical problems.** Append-only
  numbered entries, script-managed status flips as the only mutation, generated `INDEX.md`,
  lazy bootstrap, a density bar, honest absence, cross-seam placement
  (`project-pack/adr/README.md`, `project-pack/scripts/adr.sh`). Engine mechanics: project-root
  discovery (`adr.sh:14-21`), awk frontmatter read/write (`:28-46`), id allocation with a
  parallel-session collision guard (`:95-108`), index regeneration active-first (`:60-92`).
  Test harness precedent: `scripts/test_adr.sh` (sandbox `mktemp -d` + `git init`, 87 lines).
- **`_my_close` already carries the write-side pattern**: scan for candidates (Step 2.4,
  `_my_close.md:29`) → confirm with owner (Step 3, `:43`) → file before archiving (Step 4b,
  `:58-63`). ADR 0002's Why explains the placement: a write duty attached to an optional stage
  is skipped forever; close is the non-skippable gate.
- **Read-side surfaces**: `claude-pack/rules/context-loading.md:5-7` is the always-on
  session-start read list (ships to Codex automatically via `AGENTS.md`). The product-lens
  SOURCES definition lives at `claude-pack/scripts/product-lens.md:22-23` with five inline
  call-site strings (`_my_epic_plan.md:54`, `_my_spec.md:144`, `_my_design_review.md:42`,
  `_my_audit.md:40` and `:188`).
- **Distribution**: `.project/` conventions reach projects (both harnesses) via
  `scripts/init-project.sh` — new directory must join the merge list (`:189`) and fresh list
  (`:204`). `build-codex-pack.sh` needs **zero** changes: rules auto-ship, command bodies
  auto-ship, and `product-lens.md` is already in the hardcoded copy loop.
- **ADR constraints on this design**: 0001 (`[OWNER]`, active) — no hand-maintained
  current-state doc; derived index; script-only mutations. 0002/0005/0006 (ratified, live) — the
  pipeline touch-point map is a recorded decision; extending it silently is the exact failure
  the anchor-on-the-point audit BLOCKed. This design's touch points must be filed as a new ADR
  at acceptance.
- **Research warning to honor** (`20260803-210317...md` §"Alternatives Considered"): salience
  without authority-discipline just transmits a bad frame better. Hence: entry summaries are
  discovery, cited sources are authority, and the lens keeps deriving its own oracle.

## Core Concept

The product-intent ledger is the decision-records pattern instantiated for a second register.
ADRs answer "what did we decide and why"; the product ledger answers "what does the product
promise, as implemented, and where does that promise's authority live." Same machinery —
immutable numbered entries, a small script that owns ids and status flips, a generated
active-first index, lazy bootstrap, a density-bar README — different content contract: each
entry is a plain-language **Promise** (the owner's restate-and-summarize requirement), an
**Authority** section citing the durable sources that make it a promise (or carrying a
first-capture owner quote), and proportional, optional **Evidence** that the behavior exists.
The wiring is deliberately minimal: one always-on rule line makes cold agents skim the index at
session start; the product-lens SOURCES list gains the ledger as an index-first discovery
surface (summaries are never oracle material — the lens follows citations); and `_my_close`'s
existing scan→confirm→file beat gains a promise scan beside its decision scan. The key insight:
this feature needs no new machinery, only a second instance of proven machinery plus three
small touch points — anything more would violate the owner's no-ceremony constraint.

## Key Bets

- **B1. A sparse index behind an always-on rule line is enough to change cold-agent behavior.**
  Agents will skim `.project/product/INDEX.md` when the context-loading rule says to, and a
  screenful of promise one-liners orients them. *If false → the ledger is another unread doc;
  owner redirection continues; SC1/SC8 fail regardless of how good the entries are.*
- **B2. Product promises change by discrete supersession, not continuous drift.** The ADR
  lifecycle (append-only + supersede/amend) fits how major promises actually evolve. *If false —
  promises mutate frequently and partially — the machinery forces awkward supersession chains,
  recording feels like ceremony, and agents stop filing; SC6 dies.*
- **B3. A judgment-led density bar, enforced only by README guidance plus the close-time
  confirm step, keeps the ledger sparse.** *If false → inventory bloat, the owner's stated
  failure mode ("that would get unmanageable"), and trust collapse — agents stop reading it,
  which also kills B1.*
- **B4. Discovery and authority can stay separate in practice.** Lens agents given an
  index-first discovery surface will still derive oracles from cited sources, not from entry
  summaries. *If false → summaries become oracle material and the ledger launders inferred
  intent into product truth — the exact wrong-oracle institutionalization the research
  documented.*

## Key Decisions

- **D1. Location: `.project/product/`, entries `NNNN-slug.md`, generated `INDEX.md`, convention
  `README.md`.** Mirrors `.project/adr/` exactly; "product" matches product-lens/product-intent
  vocabulary. *Rejected: a subtype inside `.project/adr/` (concept ratified keeping promises
  distinct from architectural decisions; also mixes registers in one index); `.project/promises/`
  (vocabulary drift from "product-lens"/"product truth").*
- **D2. Standalone `product.sh`, derived from `adr.sh`, not a shared engine.** A conscious,
  bounded duplication (~120 shared engine lines). *Rejected: refactoring `adr.sh` into a
  parameterized ledger engine with two thin wrappers — cleaner in one repo, but scripts are
  copied per-project by `init-project.sh`, so the sync boundary is already broken in the wild;
  the refactor touches a certified feature for modest gain; and the skeletons genuinely differ
  (fields, body sections, index line). Smell 1 is acknowledged and accepted: both scripts are
  small, stable, and an Implementation Note requires engine bug fixes to be applied to both.*
- **D3. Entry contract** (answers spec OQ "entry format"): frontmatter `id, title, date, owner,
  status (active|amended|superseded), amended_by, superseded_by, supersedes, provenance,
  surfaces, checked`; body sections **Promise** (required, 1–3 sentences, the title is its
  one-liner) · **Authority** (required — graded citations, or a first-capture
  `[OWNER-VERBATIM]` quote with date/context) · **Evidence** (optional, proportional — paths,
  test names, or "exercised manually <date>") · **Scope** (optional, one or two sentences for
  partial rollout / flags — never a catalog). `provenance` grades the summary itself
  (capture-fidelity: a summary never inherits its citation's authority). *Rejected: mandatory
  Evidence (owner: tests nice-to-have); a structured applicability taxonomy (form-filling).*
- **D4. `checked` is a second permitted script-managed frontmatter mutation:
  `product.sh check <id> [ref]` stamps date + git ref.** This carries SC5 (honest recorded
  state) without re-filing: "I looked; the promise still holds as of <date>/<sha>" is one cheap
  command; if it doesn't hold, the honest move is supersede or surface. *Rejected: `checked` in
  the immutable body (can't update honestly); hand-edited frontmatter (ADR 0001 invariant:
  script-only mutations); no checked field at all (index can't say when a promise was last real,
  violating SC5).*
- **D5. Session-start read = one addition to `context-loading.md`'s "Before Starting
  Non-Trivial Work" list**: skim `.project/product/INDEX.md` if present, open only relevant
  entries; absence is honest. Auto-ships to Codex via `AGENTS.md`. `_my_status` and
  `_my_project_find` gain pointer lines as secondary orientation surfaces. *Rejected: a new
  rule file (rule budget discipline; context-loading already owns session-start reads); a
  mandatory "product orientation" output section in commands (read enforcement by required
  output is the ADR-0002 pattern, but applying it here would be the ceremony the owner
  rejected).*
- **D6. Lens wiring: edit the shared SOURCES definition (`product-lens.md:22-23`) plus the five
  call-site strings, adding `.project/product/` as an index-first discovery surface with an
  explicit "summaries are discovery, citations are authority" clause.** *Rejected: centralizing
  SOURCES so call sites defer to the spec — attractive (kills the five-edit problem) but changes
  certified call-site behavior structurally for a cosmetic gain; noted as a candidate future
  cleanup, decision record not warranted.*
- **D7. Write touch point: extend `_my_close`'s existing three-beat.** Step 2 gains a promise
  scan beside the decision scan (inputs: `audit.md`'s The Point / Product Judgment, the spec's
  Success Criteria, plan deviation notes; bar: `.project/product/README.md` density standard);
  Step 3's confirm adds "Promises to record — or none" (zero is the common case); Step 4b files
  via `product.sh new` (or `supersede`/`amend` on material change) before archiving. Close
  proceeds on "none" — not a gate. First-capture path: the lens's can't-find disposition
  ("write the point down") gains the ledger as a named home. *Rejected: a touch point in
  `_my_quick_edit` (density bar essentially never crossed by quick edits; pure ceremony); a
  wrap-up write duty (ADR 0002's Why: optionality defeats the control); a new pipeline stage
  (the research explicitly rejects more stages).*
- **D8. Multi-repo promises inherit the ADR cross-seam rule verbatim** (ruling entry in the
  repo that must uphold the promise; pointer entry locally; surface the gap if unreachable).
  *Rejected: a shared cross-repo registry (new infrastructure, no owner ask).*
- **D9. Touch points are filed as a new ADR at design acceptance** (the product-ledger
  touch-point map: reads at session start + lens SOURCES, write at close), amending nothing —
  0002/0005 govern *decision-record* touch points; this is a parallel map for a new artifact,
  recorded so the next auditor finds it deliberate. *Rejected: silent extension (the exact
  premise-conflict failure the anchor-on-the-point audit BLOCKed).*

## Architecture

Three planes around one data directory:

- **Data plane** — `.project/product/`: `README.md` (convention: what a promise is, density
  standard, register boundary vs ADRs, cross-seam rule, honest absence), `NNNN-slug.md` entries
  (immutable bodies), `INDEX.md` (generated, active-first), plus `.project/scripts/product.sh`
  (subcommands `new`, `supersede`, `amend`, `check`, `index`). Lazy bootstrap: the directory is
  created on first `new`; no seeded INDEX.
- **Read plane** — two consumers, one surface. Cold agents: `context-loading.md` sends every
  session (both harnesses) to skim `INDEX.md` and open only relevant entries. Product-lens: the
  SOURCES definition names the ledger index-first — locate applicable promises via `INDEX.md`,
  open entries, then follow each entry's **Authority** citations and derive the oracle from
  those sources at their own grade. The entry summary itself enters grading only at its own
  `provenance`.
- **Write plane** — normal path: `_my_close` scan→confirm→file, before archive so source
  artifacts still sit at `active/` paths for citation. Change path: material promise change =
  `supersede` (or `amend`), stamped at the same close beat. Maintenance path: `check` stamps
  re-verification. First-capture path: owner states a promise with no durable home (chat, or a
  lens can't-find) → entry whose Authority is the `[OWNER-VERBATIM]` quote itself.
- **Distribution** — `project-pack/product/README.md` + `project-pack/scripts/product.sh` seed
  new projects; `init-project.sh` dir lists gain `product` (merge `:189`, fresh `:204`). Codex:
  nothing new to register — rules and command bodies auto-ship; `product-lens.md` is already in
  the copy loop.

Data flow, end to end: implementation completes → close scans audit/spec for a promise that
crosses the bar → owner confirms → `product.sh new` files entry citing the spec/concept →
`INDEX.md` regenerates → next cold session skims the index and opens the entry before touching
that surface → a later lens run discovers the promise there, follows its citations, derives its
oracle → a later material change supersedes the entry, and the index shows the successor.

## Required Invariants

- Entry bodies are immutable after filing; the only mutations are script-managed frontmatter
  changes: status flips (`supersede`/`amend`) and the `checked` stamp.
- `INDEX.md` is derived state — regenerable from entries alone, never hand-edited.
- Only implemented, reasonably-checked behavior appears as an active entry; proposed behavior
  never enters the index.
- Every entry's Authority section cites at least one durable source or carries a first-capture
  owner quote; Evidence never substitutes for Authority.
- The entry `provenance` grades the summary; cited sources keep their own grades; the lens
  derives oracles from cited sources, not summaries.
- An absent or empty `.project/product/` is never an error — agents fall back to README, docs,
  ADRs, concepts (honest absence).
- Superseded entries remain readable; the index lists them below active entries with their
  successor id.
- No stage gates on the ledger: close, audit, and pre_pr all proceed when the answer is "no
  promises to record."

## Component Overview

- `project-pack/product/README.md` — the convention document: promise definition, density
  standard (major use case / public surface / cross-cutting contract + could-a-cold-agent-miss-it),
  register boundary (promise = what the product guarantees and why; decision = chosen mechanism
  → ADR), entry format, cross-seam rule, honest absence.
- `project-pack/scripts/product.sh` — id allocation, skeleton, status flips, `check` stamp,
  index regeneration. Derived from `adr.sh`; same root-discovery and frontmatter mechanics.
- `scripts/test_product.sh` — sandbox test in the `test_adr.sh` pattern: bootstrap, `new`,
  collision guard, `supersede`, `amend`, `check`, index idempotence + hand-edit discard.
- `claude-pack/rules/context-loading.md` — one list item: session-start index skim.
- `claude-pack/scripts/product-lens.md` — SOURCES definition + can't-find disposition naming
  the ledger as a first-capture home.
- Five lens call sites (`_my_epic_plan`, `_my_spec`, `_my_design_review`, `_my_audit` ×2) — add
  `.project/product/` to their SOURCES strings.
- `claude-pack/commands/_my_close.md` — promise scan / confirm bullet / file step beside the
  existing ADR beats.
- `claude-pack/commands/_my_status.md`, `_my_project_find.md` — pointer lines.
- `scripts/init-project.sh` — `product` in both dir lists.
- Docs: `README.md` (folder map), `docs/guide.md`, `project-pack/README.md` Key Files /
  Folder Structure.

## Non-Goals

- No backfill of this or any existing project (owner). Validation fixtures live in sandboxes.
- No ledger touch point in `_my_quick_edit`, `_my_wrap_up`, or any new pipeline stage.
- No mandatory evidence, test links, or completeness/certification gate (owner).
- No automatic drift detection; `checked` is honest state, not proof (concept SC5's own limit).
- No shared ledger engine refactor of `adr.sh` (D2) and no SOURCES centralization (D6) — both
  noted as possible future cleanups, not this item.

## Implementation Notes

- **Engine duplication discipline (D2):** a bug found in shared engine logic (root discovery,
  frontmatter awk, collision guard, index regen) must be fixed in both `adr.sh` and
  `product.sh` in the same change.
- **Skeleton frontmatter** (script-written, flat key/value like ADR):

  ```yaml
  id, title, date, owner, status, amended_by, superseded_by,
  supersedes, provenance, surfaces, checked
  ```

  `checked` format: `2026-08-09 @ <short-sha>` (ref optional). Index line:
  `- 0001 · <title> · surfaces: … · checked: <date>`.
- **Title = promise one-liner.** README must say so with a good/bad pair (bad: "CLI flags";
  good: "One modeled source produces one public input") — the index is only as orienting as
  its titles.
- **Register boundary wording matters.** The close-step scan must ask two separate questions
  ("decisions made during implementation?" → ADR; "product promise implemented that a cold
  agent could miss or undo?" → ledger) — not one merged question, or agents will file one
  register and skip the other.
- **Lens edit is surgical.** Add the ledger to SOURCES as *discovery-first*; do not touch the
  grading ladder (§2) — entry citations already grade through existing rows (concept
  `[OWNER-VERBATIM]`, live ADRs, spec `[NEED]`, aspirational docs). A first-capture entry's
  owner quote grades as owner-verbatim; say that in one clause, not a new ladder row.
- **`context-loading.md` counts against no budget but ships to every session of every project —
  keep the addition to ~2 lines.**
- **Order the close beats:** promise scan shares Step 2.4's read of `audit.md`/`plan.md`; file
  ADRs and promises in the same Step 4b window (before `git mv`), citing `active/` paths that
  the archive then moves — cite the post-close `completed/{date}_{item}/` path for spec
  citations (precedent: ADR 0007's mechanical consequence for pre_pr ledger reads).

## Potential Risks

- **Register confusion** (promise filed as ADR or vice versa) — mitigated by the README
  boundary paragraph and the two-question close scan; the confirm step gives the owner a veto.
- **Bloat / density erosion** (B3) — mitigated by README density bar with good/bad examples and
  zero-is-common framing in close; if it fails anyway, pruning = supersession, which the
  machinery supports.
- **Summary-as-oracle laundering** (B4) — mitigated by the SOURCES clause and the invariant;
  observable in the validation lens run.
- **Stale `checked` dates eroding trust** — mitigated by making the stamp one command and by
  README framing staleness as honest state ("orientation, not proof"), per concept SC5.
- **Citation paths move at close** (spec cited at `active/`, archived to `completed/`) —
  mitigated by the Implementation Note (cite post-close paths at close time); residual risk
  accepted: paths are best-effort, drift is honest (spec OQ resolved: no path-maintenance gate).

## Integration Strategy

Ships as one work item on one branch: project-pack convention + script + tests, then the
claude-pack read/write touch edits, then docs, then `init-project.sh` seeding, then Codex dist
rebuild (mechanical). This repo re-initializes (`init-project.sh` merge path) to receive
`.project/product/` + `product.sh` for dogfooding, but files no real entries in this item
(backfill non-goal; validation uses sandboxes). Existing pipelines are untouched except the
named touch points; nothing gates on the ledger, so partial adoption degrades to today's
behavior exactly (honest absence).

## Validation Approach

- **Script mechanics:** `scripts/test_product.sh` green (bootstrap, new, collision, supersede,
  amend, check, index idempotence, hand-edit discard, error cases).
- **SC8 fresh-agent exercises** (sandbox project with 2–3 fixture entries, one superseded):
  relevant task → agent finds the active entry and follows its authority source; unrelated
  local task → agent reports no ledger match and proceeds; superseded promise → agent uses the
  successor. Run with fresh Claude sessions; Codex parity = the same files ship (init-project
  output) + the rule text present in generated `AGENTS.md`, with a live Codex exercise if the
  CLI is available.
- **Lens consumption:** one product-lens run in the fixture sandbox; expected: the lens's
  written point cites the entry's *cited source* (not the entry summary) as its source — B4's
  observable.
- **Suite:** existing tests stay green (`test_adr.sh`, `test_docs.sh`, pipeline-sync,
  global-setup); `test_docs.sh` may need its catalog/pointer checks extended if docs sections
  are added.

## Next-Stage Handoff

- **Fixed:** D1–D9; the entry contract's required/optional sections; invariants; the
  no-gate rule.
- **Open for plan:** exact README prose; skeleton wording; index header line; which fixture
  promises the sandbox uses; whether `test_docs.sh` needs new checks.
- **De-risk first:** B1/B4 are the live-behavior bets — build the sandbox fixture and run the
  fresh-agent + lens exercises before polishing docs. B2/B3 are only observable over time;
  the design accepts them on the strength of the ADR precedent.
- **At acceptance:** file the D9 ADR (product-ledger touch-point map, provenance
  `[AGENT] (ratified by owner, <date>)`).

---
Next Step: After approval → `/_my_plan` (multi-file, multi-surface — skip `/_my_implement`-direct).
