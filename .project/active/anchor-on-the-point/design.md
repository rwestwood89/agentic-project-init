# Design: Anchor the Pipeline on the Point

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-05 14:39:58 PDT
**Branch:** decision-records
**Commit at start:** 823cd21

---

## Overview

Add a second line of ground truth beside the artifact chain: a single-job product-lens
subagent that re-derives the product's point from primary sources and checks the actual
work against it at the four stages where scope narrows, with findings recorded in a durable
per-item ledger, and the review and certification stages reordered to lead with a loud
holistic judgment that can outrank a green rubric.

## Related Artifacts

- **Spec:** `.project/active/anchor-on-the-point/spec.md`
- **Source concept:** `.project/concepts/anchor-on-the-point.md`
- **Research:** `.project/research/20260803-210317_pipeline-product-truth-control-review.md`
- **Decision records:** `.project/adr/0001` (append-only convention); `.project/adr/0002`
  (decision-record touch points — **amended by 0005**); `.project/adr/0005` (product-lens
  touch-point map + its liveness-vs-authority grading; supersedes 0003→0004, which first mis-framed
  the touch-point count as a special category and then conflated ADR liveness with authority). This
  design adds product-lens reads of `.project/adr/` at four sites plus a contract-change ADR-filing
  path; 0005 records that plainly and amends 0002. Seams: `claude-pack/commands`, `project-pack`.

## Research Findings

The pipeline commands live in `claude-pack/commands/`; templates in `project-pack/`. The
map below drives the design (line numbers are current-file locations).

- **epic_plan** (`_my_epic_plan.md`, 57 lines) spawns no subagents. Per-item work happens
  in Stage 2's decomposition table (34-44) and Stage 3's item writing (46-55), which
  already reasons per-item (Required Reading line 50, De-risking line 52).
- **spec** (`_my_spec.md`) captures the problem in one `## Problem` section (76-80); grades
  requirements in Known Requirements (91-104) using capture-fidelity vocabulary; already
  spawns `Task`/`Explore` conditionally (line 30).
- **design** (`_my_design.md`) has **no problem/point slot** — confirmed. Core Concept
  (122-133) is the natural attach point. Reads the ADR index at setup (78), files ADRs
  after approval (276-281). The anti-pattern list forbids "restating the spec in prose"
  (369) — a constraint the new slot must be worded around.
- **design_review** (`_my_design_review.md`) **already leads with a loud holistic gate**:
  Stage 0 "Fundamental Assessment" (35-52) can halt and recommend Rework before the rubric.
  Eight scored dimensions follow (54-131); Dimension 1 already imports a capture-fidelity
  provenance check (69). Verdict Approve/Revise/Rework (246).
- **audit** (`_my_audit.md`) checks four areas (37-66): plan, spec, design, code integrity.
  Code integrity holds the slop-detection list where a "duplicate-selecting test" smell
  belongs (48-54, "copy-paste siblings" line 54 is its nearest sibling). Verdict is a bare
  `Certify | Needs Work` header (74) — **no loud-judgment gate above it.**
- **plan** (`_my_plan.md`) is ordered to delete the problem: "Do NOT restate business
  context from the spec... link instead" (18-19) and "replace that text with a reference"
  (287).
- **Subagent precedent:** `_my_concept.md:102` spawns `general-purpose` to apply an
  evaluative lens (not just search) — the exact shape the product-lens needs.
  `_my_recall.md:38` shows a reusable "Subagent Prompt Template" section is an accepted
  pattern. No custom subagent types exist yet.
- **adr.sh** supports `new`/`supersede`/`amend`/`index`; entries are append-only with a
  density bar. Transient per-run findings fail that bar; only a cross-seam
  intended-contract-change belongs in an ADR.
- **Fixture precedent:** `.project/active/capture-fidelity/fixture-planted-concept.md` +
  `fixture-expected-findings.md` — a planted-defect input plus a fixture-first answer key
  with per-plant Where/Plant/Expected-flag blocks, a numeric pass bar, and a
  gate-fail-returns-to-design rule.

## Core Concept

**The pipeline loses the point because each stage's ground truth is the artifact one hop
upstream.** This design adds a second line of ground truth that runs *beside* the artifact
chain rather than as another link in it: a single-job **product-lens subagent**.

At the four stages where scope narrows — `epic_plan`, `spec`, `design_review`, `audit` — the
lens re-derives the product's point from primary sources it discovers and grades itself
(README, `docs/`, `.project/adr`, owner-verbatim in the concept) — **never from the upstream
artifact's account** — and checks the actual work against it in **both directions**: does the
work contradict the point (a DON'T), and does it omit an obligation the point requires (a DO).

Its findings accumulate in one append-only per-item **ledger**, each finding graded by the
authority of its source and bound to the artifact revision it checked. Enforcement is tiered:
a finding backed by owner or `[HARD]` authority leaves the stage **blocked**; a lower-authority
finding requires a **visible disposition** but may proceed; and the lens **failing to locate any
durable point** is itself a finding requiring disposition — turning the capture gap from silent
to loud.

On top of this, the two stages that render a verdict lead with **one loud holistic judgment** —
*is this the right piece of work?* — that can carry the verdict even when every rubric item is
green. The **seven structural smells** become mechanical tripwires under that judgment, and any
smell that fires **must escalate** into it.

**Why this is the right shape, not just a working one.** The disease is single-point-of-failure:
one agent narrows the point at hop N and every later stage faithfully serves the narrowed version.
A second, independent line of ground truth is the direct antidote — the same "no single point of
failure" logic that justifies having stages at all. It is explicitly **not another review stage**
(which would be another inheritor of the narrowed frame), and **not another always-on rule** (the
Surfacing law already is one, and it did not fire).

**It composes with existing pieces rather than adding parallel machinery:**
- Finding authority reuses the **capture-fidelity provenance grades** — no new taxonomy.
- The one durable case (an accepted change to product intent) files a **decision record** via
  the existing `adr.sh` — no new durable store.
- The loud judgment in `design_review` **strengthens the existing Stage 0 gate** rather than
  inventing one; `audit` gains the gate it lacks.
- It points the pipeline's existing "code is truth, patch the doc" muscle
  (`concept_design`) at the product's purpose instead.

## Key Bets

- **B1. An independent re-derivation from primary source catches point-narrowing that a
  one-hop check cannot.** *If false → the lens inherits the same narrowed frame and adds
  nothing; the whole design is theater.* This is the load-bearing bet.
- **B2. A single-job subagent with no rubric to fill and no test to pass will not rationalize
  a contradiction away** the way an in-stage check does. *If false → the lens normalizes the
  finding like every stage in the incident did, and the finding is as corruptible as the
  artifact.*
- **B3. Real repos carry enough durable product truth in README/docs/ADRs to re-derive the
  point — or the can't-find alarm adequately handles its absence.** *If false → the lens has
  no oracle and either fabricates one (manufactured authority) or blocks everything (unusable
  friction).*
- **B4. A loud holistic judgment placed above the rubric, backed by a durable block state,
  actually controls the verdict** rather than being ignored under schedule pressure the way
  the Surfacing rule was. *If false → "outrank the green rubric" fails and the pipeline still
  cannot give the guarantee it claims.* This is the concept's named crux (Q1); it is a bet,
  not a settled fact, and is surfaced as the top risk.

## Key Decisions

- **D1. One shared product-lens spec, invoked as a subagent from each call site.** *Rejected:
  inline instructions per stage (the "fourteen edited instruction lists competing for
  attention" failure the concept names). One mechanism, one place to maintain.*
- **D2. A dedicated append-only per-item ledger for findings.** *Rejected: a findings section
  inside each stage artifact — it fragments findings across artifacts and re-creates the very
  one-hop blindness this design fights. Only a single accumulating ledger lets a later stage
  see every prior finding, and lets `pre_pr`/`close` read one gate state.* The ledger carries
  findings, not the problem statement, so it does not conflict with the requirement that the
  *problem* stay in existing artifacts (see Architecture).
- **D3. Finding authority reuses the capture-fidelity provenance grades.** *Rejected: a new
  source-grading vocabulary — a non-goal, and jargon is the medium of the disease.*
- **D4. Only an "intended contract change" disposition files a decision record (via
  `adr.sh`); every other finding lives only in the ledger.** *Rejected: an ADR per finding —
  it fails the density bar and becomes rubber-stampable paperwork.*
- **D5. Tiered enforcement — owner/`[HARD]` contradiction blocks; lower-authority disposes and
  proceeds; can't-find disposes and proceeds.** *Rejected: block on every finding — unusable
  friction the owner did not ask for. This tiering was ratified in the spec.*
- **D6. `audit` owns the implementation-level lens and loud judgment; `pre_pr` does not run the
  lens but must honor an unresolved block.** *Rejected: the concept's original `pre_pr` site —
  `audit` is the certification gate that already re-inspects code; `pre_pr` is a consolidation
  gate. Ratified in the spec.*
- **D7. The lens is a `general-purpose` subagent driven by the shared spec, not a new custom
  subagent type.** *Rejected: a bespoke agent type — no such infra exists; `_my_concept.md:102`
  shows general-purpose-as-lens is the established precedent.*

## Architecture

**The integration matrix.** Six existing commands change; two new files are added. Read this
table as the whole design in one view:

| Stage | Runs lens | Loud judgment leads | Seven smells | Carries the problem |
|---|---|---|---|---|
| `epic_plan` | yes (over the decomposition) | — | — | — |
| `spec` | yes | — | — | full graded Problem (already has slot) |
| `design` | — | — | — | **new "The Point" slot** |
| `design_review` | yes | **strengthen Stage 0** | design-level (2) | — |
| `plan` | — | — | — | **reverse anti-restatement** |
| `audit` | yes | **add product judgment** | code/test-level (5) | — |
| `pre_pr`, `close` | — (honor block only) | — | — | — |

**The two ground-truth lines.** The artifact chain (spec → design → plan → code) is unchanged.
Beside it runs the lens line: at each of its four sites the lens reads *sources* and *work*,
writes a dated block to the ledger, and sets a gate state. The stage's own verdict must respect
that gate.

**Data flow of one lens run:**

1. The call site spawns the lens with two clearly separated inputs: **SOURCES** (paths to
   discover and grade — README, `docs/`, `.project/adr`, concept owner-verbatim) and **WORK**
   (the concrete artifact/output under evaluation, framed as *a claim to test*, not truth).
2. The lens derives the point and a **falsifier** from sources *first* and writes them down,
   *before* reading the work. It never treats the upstream stage artifact's framing as the
   point. (Oracle-first — the research's core move.)
3. The lens emits findings (DO / DON'T), each with source + provenance grade, plus a can't-find
   finding if no durable point was located.
4. The call site appends the run to the ledger and sets the gate: **BLOCKED** (owner/`[HARD]`
   contradiction unresolved), **DISPOSED** (lower-authority or can't-find finding with a
   recorded disposition), or **CLEAR**.

**The ledger** (`.project/active/{item}/product-lens.md`) is append-only working state, a log
not a template. One block per run:

```
## <stage> — <date> — rev <git-sha | artifact path>
Point (re-derived): <one line>   [source: <path>, grade: <OWNER|HARD|INHERITED|AGENT>]
Falsifier: <observable that would show the point violated>
Findings:
- [DON'T] <work contradicts point> — <source> (<grade>) — disposition: BLOCK | <ref>
- [DO]    <work omits required obligation> — <source> (<grade>) — disposition: <ref>
Gate: CLEAR | DISPOSED (<who/when>) | BLOCKED (<finding>)
```

Each stage artifact carries only a **one-line pointer** to its latest ledger verdict, so no
artifact bloats. `pre_pr` and `close` read the ledger's latest gate and fail while any BLOCK
is unresolved — this is the consumer-side enforcement that converts an incorruptible *finding*
into a blocking *state* (partial answer to the crux; see Risks).

**Move 1 — carrying the problem — is separate from the ledger.** The full problem stays legible
*in the existing artifacts*: `spec`'s Problem section stays full and graded, `design` gains a
"The Point" slot, `plan`'s anti-restatement rule is reversed so the problem rides into the plan.
The ledger holds *findings about* the work, not the problem statement — the spec's own open Q1
asks for exactly this durable findings record, so the two concerns do not collide.

**The shared spec** (`claude-pack/commands/product-lens.md`, not a slash command, not a rule)
is the single home for four referenced sections: (§1) the lens subagent job and its oracle-first
protocol, (§2) the source-authority grading ladder mapped onto provenance grades, (§3) the ledger
format, (§4) the seven smells. Call sites reference the sections they need.

**The seven smells** split by layer, as the concept dictates: the two design-level smells (a
consumer compensates for a platform guarantee; a change of who owns an invariant) go into
`design_review`'s dimensions; the five code/test-level smells — including "a test passes only by
selecting one duplicate" (verbatim smell six) — go into `audit`'s code-integrity checks
(`_my_audit.md:48-54`). Any fired smell escalates into the leading judgment.

## Required Invariants

- **Independence.** The lens derives the point from primary sources before reading the work,
  and never treats the upstream stage artifact as the point.
- **No manufactured authority.** Every finding cites a source and its provenance grade. No
  ungraded finding.
- **Enforcement.** An unresolved owner/`[HARD]`-grade contradiction leaves Gate: BLOCKED;
  `pre_pr` and `close` fail while any BLOCK is unresolved.
- **Absence is loud.** Can't-find produces a finding requiring disposition — never a fabricated
  or silently inherited oracle.
- **Escalation.** Any fired smell appears in the leading judgment, not only in rubric detail.
- **Append-only ledger.** A gate state changes only via a new dated block with a disposition,
  never by editing a prior block (mirrors the ADR append-only discipline).

## Component Overview

- **`claude-pack/commands/product-lens.md`** *(new)* — the shared lens spec: job, grading
  ladder, ledger format, seven smells.
- **`.project/active/{item}/product-lens.md`** *(new, per item)* — the append-only ledger.
- **`_my_epic_plan.md`** — run the lens over the decomposition (Stage 2/3); record its verdict
  in the epic artifact, inherited by items.
- **`_my_spec.md`** — run the lens; keep the Problem section full and graded; append ledger.
- **`_my_design.md`** — add "The Point" slot (worded to carry, not restate-as-filler); no lens.
- **`_my_plan.md`** — reverse the anti-restatement rule (18-19, 287); carry the problem.
- **`_my_design_review.md`** — fold lens findings + design-level smells into Stage 0's holistic
  judgment; run the lens; append ledger.
- **`_my_audit.md`** — add a loud product judgment above the verdict; add code/test smells incl.
  duplicate-selecting-test; run the lens; append ledger.
- **`_my_pre_pr.md`, `_my_close.md`** — read the ledger; fail on an unresolved BLOCK.
- **ADR link** — an "intended contract change" disposition files an entry via `adr.sh`; the
  ledger finding cites the entry id.
- **Fixture pair** *(new)* — `fixture-planted-*.md` + `fixture-expected-findings.md`,
  fusion-tea-shaped (see Validation).
- **Installer** — `setup-global.sh` must ship `product-lens.md` so call sites can reach it.

## Non-Goals

- No mechanical/CI enforcement of the block — enforcement is agent-honored (named as residual
  risk). No new custom subagent-type infrastructure.
- No broad teardown of slots or jargon; only the two targeted trims (design slot, plan reversal)
  plus the design_review judgment reorder.
- Does not replace capture-fidelity, the provenance vocabulary, the ADR mechanism, or any
  existing stage artifact.
- No new canonical product-truth document is required (the lens scavenges and grades).
- Does not guarantee an agent never misses a bug — it stops one missed contradiction from
  silently becoming the downstream contract.

## Implementation Notes

- **Wording of "The Point" slot** must dodge `_my_design.md:369` ("restating the spec in prose"
  is an anti-pattern). Frame it as *the obligation the design must serve*, carried and gradable,
  not a prose recap.
- **Naming:** newer commands use the `Agent` tool, older ones say `Task`; both with
  `subagent_type`. Match the file you edit.
- **Grading ladder → block rule:** contradiction against `[OWNER]`/`[HARD]` source ⇒ BLOCK;
  against `[INHERITED]`/aspirational/lens-`[INFERRED]` ⇒ DISPOSED-and-proceed; can't-find ⇒
  DISPOSED-and-proceed (write-the-point-down is the usual disposition).
- **Build the fixture before editing prompts** (research recommendation #3; capture-fidelity
  precedent) — it is the only check on B1/B4.

## Potential Risks

- **The crux (B4 / concept Q1): the block is agent-honored, not mechanical.** A determined agent
  could hand-edit the ledger to CLEAR, or dispose falsely. Mitigation: append-only discipline,
  the pointer in each artifact, and the fixture proving the path — but the residual risk is real
  and must be stated at acceptance, not papered over. This is the one risk that can sink the work.
- **Independence leak.** The lens still receives the work; framing alone may not stop it
  absorbing the narrowed frame. Mitigation: oracle-first ordering + subagent context boundary;
  the fixture tests exactly this.
- **Can't-find friction.** Repos with legitimately thin product docs trip the alarm often.
  Mitigation: dispose-and-proceed, not block.
- **Reachability.** The shared spec must be installed and resolvable across arbitrary project
  dirs the way rules are; broken path = silent no-op. Verify in the installer.
- **Cost at four sites**, especially per-decomposition at `epic_plan`. Mitigation: one lens run
  per stage, small return payload (grounding without the flood).

## Integration Strategy

This is cross-cutting pipeline work, decomposable as an epic after design approval (the research
says the same). It changes six commands, adds one shared spec, one per-item ledger convention,
and one fixture pair, and touches the installer. It rides on `decision-records` (already on this
branch) for the one durable case. It does not merge or replace any stage. Existing runs without
the shared spec installed degrade to today's behavior (the lens is a no-op if unreachable) — so
rollout is install-gated, not flag-day.

## Validation Approach

The acceptance referent is the fusion-tea failure shape. Build a fixture pair mirroring
capture-fidelity's:

- **`fixture-planted-input.md`** — a work artifact where one modeled source fans out to multiple
  consumers, local tests are green, a prior research note calls the contradiction a known hazard,
  a mechanism distinction plausibly explains the output, and a consumer-side workaround is
  proposed. The item is *completable* by accepting the inherited frame.
- **`fixture-expected-findings.md`** (written first) — the answer key. Pass bar: the shape is
  stopped **two independent ways** — (a) the product-lens DON'T finding (generated output
  contradicts "one source, one parameter"), graded owner/`[HARD]`, ⇒ BLOCK; and (b) the
  duplicate-selecting-test smell firing in `audit` and escalating into the loud judgment —
  *despite* green tests and the plausible inherited explanation. A gate-fail rule returns to
  design if either path misses.

Also verify: the DO direction (a design that never wires the inputs together is caught as an
omission, not just an active break); can't-find produces a disposition-requiring finding; and a
lower-authority finding proceeds with a visible disposition rather than blocking.

## Next-Stage Handoff

**Fixed (treat as settled):** the four run-sites (epic_plan, spec, design_review, audit); reuse
of provenance grades for finding authority; ADR only for an intended-contract-change disposition;
loud judgment via strengthening design_review Stage 0 and adding an audit judgment; the
append-only ledger; tiered enforcement; the lens as a general-purpose subagent on a shared spec.

**Open (plan decides):** the exact install path/wiring of the shared spec; whether the
`epic_plan` lens runs once over the decomposition or lightly per item; the ledger file naming at
the epic tier (epic artifact section vs sibling file); precise wording of each prompt edit.

**De-risk first:** build the fixture pair and confirm both stop-paths *before* editing any
prompt. B1 (independent re-derivation catches narrowing) and B4 (the block actually controls the
verdict) are the bets that decide whether this works; the fixture is the only thing that tests
them. If the fixture can't be stopped two independent ways, surface that plainly rather than
shipping a fix that repeats the failure.

---
Next Step: After approval → `/_my_plan` (this is epic-sized; likely `/_my_epic_plan` first).
