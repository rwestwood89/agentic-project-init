# Implementation Plan: Product Intent Ledger

**Status:** Remediated (2026-08-12), pending re-audit
**Created:** 2026-08-09
**Last Updated:** 2026-08-12

## Source Documents
- **Spec:** `.project/active/product-intent-ledger/spec.md`
- **Design:** `.project/active/product-intent-ledger/design.md` ← component details, decisions (D1–D9), bets (B1–B4), invariants
- **Product-lens ledger:** `.project/active/product-intent-ledger/product-lens.md`

## The Point

Agents reliably learn *what work is active* but not *what the product is for*. The owner's
recurring redirection is "reminders of what the point of our code is," and the product-lens
re-derives the product's point from scattered sources on every run with no stable collection of
the major promises last recorded as implemented. This work gives cold coding agents and
product-lens agents one sparse, durable, current orientation surface for implemented product
promises — serving both equally — without ceremony, mandatory evidence, or a completeness gate
(owner-originated, via the concept's Owner's Words). The ledger is orientation, not proof;
sparse by judgment, not inventory; and nothing anywhere gates on it.

## Implementation Strategy

**Phasing Rationale:** Foundation (engine + convention) → touch-point text → behavioral
de-risk → docs/distribution. The design's live-behavior bets (B1: agents actually read the
index; B4: the lens derives oracles from citations, not summaries) can only be exercised once
the rule and SOURCES text exist, so the behavioral exercises come immediately after the text
edits and *before* documentation polish — if B1/B4 fail, we change wording, not docs.

**Critical Path:** `product.sh` + README convention → touch-point edits → sandbox fixture →
fresh-agent + lens exercises.

**First Proof Point:** `scripts/test_product.sh` green (Phase 1) — engine + `check` subcommand
work. First *behavioral* proof: Phase 3's relevant-task exercise.

**Overall Validation Approach:** each phase gates on the full repo suite
(`test_adr.sh`, `test_docs.sh`, pipeline-sync, global-setup, codex checks), not just its own
tests; Phase 3 validates live behavior against written pass criteria.

---

## Phase 1: Ledger engine + convention (foundation)

### Goal
The data plane exists and is seeded: convention README, `product.sh`, its test file, and
`init-project.sh` seeding. Everything downstream points at real entries and a real index.

### Assumption Under Test
The adr.sh machinery transfers cleanly to the promise register, including the new `check`
subcommand (design.md#key-decisions D4) — the one engine extension beyond copying.

### Test Stencil (Write This First)
```bash
# scripts/test_product.sh — sandbox pattern from scripts/test_adr.sh (mktemp -d, git init, check helper)
path=$(product.sh new one-source --title "One modeled source produces one public input")
check "lazy bootstrap"   test -f .project/product/INDEX.md
check "status active"    grep -q '^status: active' "$path"
check "checked stamp"    product.sh check 0001 && grep -q "^checked: $TODAY" "$path"
check "supersede flips"  product.sh supersede 0001 0002 && grep -q '^superseded_by: 0002' "$path"
check "index active-first + hand-edit discard"  # per test_adr.sh:73-79 pattern
check "no-authority guard is README-level, not script-level"  # script never blocks: no gates
```

### Changes Required

**See `design.md` for:** entry contract → `design.md#key-decisions` (D3, D4) · script
responsibilities → `design.md#component-overview` · invariants → `design.md#required-invariants`
· skeleton/index formats → `design.md#implementation-notes`.

- [x] `scripts/test_product.sh` (NEW, write first) — mirror `scripts/test_adr.sh` coverage:
      bootstrap, new + collision guard, supersede, amend, `check` stamp (date + optional ref),
      index idempotence/hand-edit discard/active-first ordering, error cases. Audit gap
      (sequential-only collision test) closed 2026-08-12: 8-way parallel `new` test + atomic
      lock in both scripts (see Audit Remediation below).
- [x] `project-pack/scripts/product.sh` (NEW) — derived from `project-pack/scripts/adr.sh`;
      subcommands `new`, `supersede`, `amend`, `check <id> [ref]`, `index`; frontmatter and
      body skeleton per D3; index line per `design.md#implementation-notes`.
- [x] `project-pack/product/README.md` (NEW) — convention doc: promise definition, density bar
      with good/bad title pair, register boundary vs ADRs, entry format, first-capture rule
      (owner quote as Authority), cross-seam rule (D8), honest absence, "orientation not proof."
- [x] `scripts/init-project.sh:189` and `:204` — add `product` to merge + fresh dir lists.

### Validation
**Automated:**
- [x] `scripts/test_product.sh` → all green (36/36)
- [x] `scripts/test_adr.sh` → still green (no accidental shared-file coupling)
- [x] Fresh `init-project.sh` run in a temp dir → `.project/product/` exists, `product.sh`
      copied and executable

**Manual:**
- [x] Read a generated entry skeleton → sections Promise / Authority / Evidence / Scope
      present; frontmatter matches D3
- [x] `product.sh` with no args → usage text names all five subcommands

**What We Know Works After This Phase:** the ledger's mechanics — filing, lifecycle, checked
stamps, derived index, seeding.

---

## Phase 2: Read/write touch points

### Goal
The wiring text exists: D9 ADR filed, session-start rule line, lens SOURCES, close beats,
pointer lines.

### Assumption Under Test
The edits fit inside certified command/rule text without tripping drift guards
(`test_docs.sh` no-restatement + catalog checks, pipeline-sync) and without touching the lens
grading ladder (§2).

### Test Stencil (Write This First)
```bash
# Presence greps — run before and after edits (extend test_docs.sh only if Phase 4 decides to)
grep -q 'product/INDEX.md' claude-pack/rules/context-loading.md
grep -q '\.project/product/' claude-pack/scripts/product-lens.md          # SOURCES definition
grep -q 'write the point down' claude-pack/scripts/product-lens.md        # can't-find names ledger home
for f in _my_epic_plan _my_spec _my_design_review _my_audit; do
  grep -q '\.project/product/' "claude-pack/commands/$f.md"; done         # 5 call-site strings (audit ×2)
grep -q 'product.sh new' claude-pack/commands/_my_close.md                # file beat
```

### Changes Required

**See `design.md` for:** touch-point decisions → `design.md#key-decisions` (D5, D6, D7, D9) ·
edit discipline → `design.md#implementation-notes` (lens edit surgical; rule addition ~2 lines;
two-question close scan).

- [x] File D9 ADR via `.project/scripts/adr.sh new product-ledger-touch-points` — the
      product-ledger touch-point map (reads: session start + lens SOURCES; write: close);
      provenance `[AGENT] (ratified by owner, 2026-08-09)`; amends nothing (parallel map).
      → filed as **ADR 0008**.
- [x] `claude-pack/rules/context-loading.md` — ~2 lines in "Before Starting Non-Trivial Work":
      skim `.project/product/INDEX.md` if present, open relevant entries; absence is honest.
- [x] `claude-pack/scripts/product-lens.md:22-23` — add `.project/product/` to SOURCES,
      index-first, with "summaries are discovery, citations are authority" clause; §1.4
      can't-find disposition names the ledger (first-capture entry) as a home. §2 untouched.
- [x] Five call-site SOURCES strings: `_my_epic_plan.md:54`, `_my_spec.md:144`,
      `_my_design_review.md:42`, `_my_audit.md:40`, `_my_audit.md:188`.
- [x] `claude-pack/commands/_my_close.md` — promise beats beside ADR beats: scan (Step 2.4
      area, `:29`; separate question from the decision scan), confirm bullet (`:43`,
      "Promises to record — or none"), file step (`:58-63`, `product.sh new|supersede|amend`
      before `git mv`; cite post-close `completed/` paths).
- [x] `claude-pack/commands/_my_status.md:16-20`, `_my_project_find.md` path menu — pointer
      lines for `.project/product/INDEX.md`.

### Validation
**Automated:**
- [x] Presence greps above → all hit (11/11)
- [x] Full suite: `test_docs.sh`, `test_adr.sh`, `test_product.sh`, pipeline-sync,
      global-setup (+ init-project, codex-orchestrator, concept-design-gate) → green

**Manual:**
- [x] Diff review: `product-lens.md` §2 grading ladder byte-identical (diff vs HEAD);
      no stage gained a gate on the ledger; close proceeds on "none"
- [x] Read the close diff as a cold implementer: decision question (Step 2.4) and promise
      question (Step 2.5) are separate and answerable

**What We Know Works After This Phase:** every consumer's text names the ledger; the map is on
record (ADR); no drift guard or certified behavior broken.

---

## Phase 3: Behavioral de-risk (B1/B4, spec SC8)

### Goal
Exercise the design's live-behavior bets before any doc polish: do fresh agents orient from the
index, and does the lens keep authority separate from discovery?

### Assumption Under Test
B1 (a sparse index behind an always-on rule line changes cold-agent behavior) and B4 (lens
derives oracles from cited sources, not entry summaries) — `design.md#key-bets`.

### Test Stencil (Write This First)
```markdown
# fixture-{sandbox,expected-findings}.md in .project/active/product-intent-ledger/
Sandbox: init-project.sh into a temp project with a toy codebase; file 3 entries via product.sh:
  0001 active (promise touching surface A), 0002 superseded → 0003 (successor promise, surface B).
Pass criteria (written BEFORE running, anchor-on-the-point fixture pattern):
  E1 relevant task on surface A  → agent opens 0001, names its cited authority (not just the summary)
  E2 unrelated local task        → agent reports no ledger match, proceeds without loading history
  E3 task on surface B           → agent uses 0003; never applies 0002
  E4 lens run on surface-A work  → written point cites 0001's *cited source* as its source path
  E5 Codex parity                → sandbox files identical; rule text present in generated AGENTS.md;
                                   live codex run of E1 if CLI available, else reachability fallback
```

### Changes Required
- [x] Write `fixture-sandbox.md` + `fixture-expected-findings.md` (scenario prompts + pass
      criteria above, concretized)
- [x] Build the sandbox project; file the three fixture entries via `product.sh`
- [x] Run E1–E3 as fresh, uncoached Claude sessions; record transcripts/outcomes against
      criteria
- [x] Run E4 (product-lens subagent per `product-lens.md`); record which source its point cites
- [x] Run E5 parity check (live Codex if available; else the design's reachability fallback)

### Validation
**Automated:** none beyond entry filing (behavioral phase).
**Manual:**
- [ ] E1–E5 outcomes recorded against pre-written criteria; all five PASS, no FAIL to analyze.
      Audit gap: E3 hand-mutated script-managed state, E4's raw verdict was not retained, and the
      retained E5 output does not meet the pre-written authority-source naming bar.
- [x] On B1 failure → revise `context-loading.md` wording (not more machinery), rerun E1–E3
      — not needed (B1 confirmed 4 ways: E1, E2 no-FP, E3, E5 live Codex)
- [x] On B4 failure → sharpen the SOURCES discovery/authority clause, rerun E4
      — not needed (lens oracle came from the cited source at its own grade)

**What We Know Works After This Phase:** the feature's actual point — orientation and
oracle-independence behavior — not just artifact presence. Spec SC8 evidence in hand.

---

## Phase 4: Docs, distribution, dogfood

### Goal
The convention is findable by humans and ships everywhere; this repo carries the ledger
directory for future dogfooding.

### Assumption Under Test
None substantive — mechanical closure. (Residual: `test_docs.sh` catalog guards accept the new
doc mentions.)

### Test Stencil (Write This First)
```bash
grep -q 'product' project-pack/README.md          # Key Files / Folder Structure
grep -q 'product' docs/guide.md                   # orientation mention
grep -qi 'product' README.md                      # folder map
bash scripts/test_docs.sh                         # guards still green
```

### Changes Required
- [x] `project-pack/README.md` Key Files + Folder Structure; `README.md` folder map;
      `docs/guide.md` — brief, question-driven mention (where do agents learn the product's
      point?); no flow restatement (drift-guard rule)
- [x] Extend `scripts/test_docs.sh` only if a cheap drift guard is warranted (decide here)
      → decided **yes**: three `check_wired` presence checks (rule reads index, lens SOURCES
      include ledger, close files via product.sh), citing ADR 0008
- [x] `scripts/build-codex-pack.sh` → rebuild `dist/codex/` (zero script changes expected —
      verify rule + command content arrived in `AGENTS.md`/skills)
- [x] Re-run `scripts/init-project.sh` on this repo (merge path) → `.project/product/` +
      `.project/scripts/product.sh` present; file **no** entries (backfill non-goal)
- [x] Refresh global Claude install (`setup-global.sh`) and Codex install per repo convention

### Validation
**Automated:**
- [x] Full suite green: `test_product.sh`, `test_adr.sh`, `test_docs.sh`, pipeline-sync,
      global-setup, codex checks (8/8, incl. init-project + concept-design-gate)
**Manual:**
- [x] `dist/codex/AGENTS.md` contains the context-loading addition (sanitized —
      "saved project context" replaces auto-memory phrasing, INDEX-skim line intact)
- [x] This repo: `.project/product/` exists and is empty except README; `git status` diff
      reviewed (`git diff --check` clean)

**What We Know Works After This Phase:** a new or existing project receives the ledger by
init/re-init; Codex sessions receive the same instructions; docs point at the convention
without restating it.

---

## Environment Setup

Bash + git only; test scripts are self-contained sandboxes (`mktemp -d`). Repo suite commands
per `scripts/*.sh`. No CLAUDE.md in this repo — README + `docs/guide.md` are canonical.

## Risk Management

**See `design.md#potential-risks`.**

**Phase-Specific Mitigations:**
- **Phase 1**: engine drift discipline — any shared-logic fix lands in both `adr.sh` and
  `product.sh` (`design.md#implementation-notes`).
- **Phase 2**: full suite as the phase gate, not targeted greps alone; §2 byte-identity check.
- **Phase 3**: pass criteria written before runs; failures change wording, never add machinery
  or gates.
- **Phase 4**: docs mentions kept pointer-shaped to stay clear of no-restatement guards.

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
**Completed:** 2026-08-09
**Actual Changes:**
- Created `scripts/test_product.sh` (36 checks: bootstrap, allocation, collision guard,
  supersede, amend, `check` with/without ref, index idempotence + hand-edit discard +
  active-first, skeleton sections, usage, error cases)
- Created `project-pack/scripts/product.sh` — derived from `adr.sh`; D3 frontmatter
  (`surfaces` instead of `seams`; `checked` added, initialized to filing date); `check <id>
  [ref]` subcommand; index line `- NNNN · title · surfaces: … · checked: <date>`
  (superseded entries show `superseded → NNNN` instead of checked)
- Created `project-pack/product/README.md` — all planned sections
- `scripts/init-project.sh` — `product` added to merge dir list and fresh `mkdir -p` list
**Issues:** none
**Deviations:**
- `checked` initialized to filing date on `new` (not null): filing at close means the
  promise was just verified implemented, and the index line stays uniform (SC5)
- Full suite run beyond the plan's list: init-project, codex-orchestrator,
  concept-design-gate tests also green

### Phase 2 Completion
**Completed:** 2026-08-09
**Actual Changes:**
- ADR 0008 filed (`product-ledger-touch-points`), provenance
  `[AGENT] (ratified by owner, 2026-08-09)`, seams `[claude-pack, project-pack, product-lens]`
- `context-loading.md` — new list item 2 (index skim, ~2 lines), later items renumbered
- `product-lens.md` — SOURCES gains `.project/product/` index-first with the
  discovery-vs-authority clause + first-capture grading clause; §1.4 can't-find names the
  ledger as home; §2 untouched (byte-identical)
- Five call-site SOURCES strings updated (`.project/product/` index-first); `_my_audit.md:188`
  epic-scope string had no parenthetical list — gained the full one
- `_my_close.md` — Step 2 item 5 (promise scan, separate question), Step 3 "Promises to
  record — or none" bullet, Step 4b renamed "File decision records and promise entries" with
  `product.sh` filing + post-close `completed/` citation paths; Last Updated line refreshed
- `_my_status.md` read list + `_my_project_find.md` context topic — INDEX pointer lines
**Issues:** none — no drift guard tripped
**Deviations:** none material (audit epic-scope SOURCES string expanded to the standard
parenthetical, per the plan's intent that all five sites name the ledger)

### Phase 3 Completion
**Completed:** 2026-08-09
**Actual Changes:**
- `fixture-sandbox.md` + `fixture-expected-findings.md` written (criteria before runs);
  sensorpipe sandbox built in session scratchpad via fresh `init-project.sh`; entries
  0001 (active, report), 0002→0003 (superseded chain, units) filed via `product.sh`
- E1–E3 fresh `claude -p` sessions, E4 lens subagent, E5 Codex parity (AGENTS.md grep +
  live `codex exec`) — **all five PASS**; outcomes recorded in
  `fixture-expected-findings.md`
**Issues:**
- E3's headless session couldn't run `product.sh` (permission mode) and hand-replicated its
  output, disclosed; environment artifact, not a design/wording failure
**Deviations:**
- Codex pack rebuild + `setup-codex.sh` install pulled forward from Phase 4 as an E5
  prerequisite (live Codex reads `~/.codex/AGENTS.md` copies); Phase 4 re-verifies after
  doc edits

### Phase 4 Completion
**Completed:** 2026-08-09
**Actual Changes:**
- `project-pack/README.md` — Key Files rows (`product/INDEX.md`, `adr/INDEX.md`) + Folder
  Structure lines (`adr/`, `product/`, scripts note)
- `README.md` — both folder maps gain `product/` (and `adr/`, previously missing)
- `docs/guide.md` — new "Where agents learn what the product is for" section after the ADR
  section; close bullet mentions promise filing
- `scripts/test_docs.sh` — three `check_wired` guards for the ADR-0008 touch points
- `dist/codex/` rebuilt; `setup-global.sh` + `setup-codex.sh` refreshed; repo re-initialized
  (merge path) → `.project/product/` (README only) + `.project/scripts/product.sh`
**Issues:** none
**Deviations:**
- Root README + project-pack README folder maps also gained the missing `adr/` line —
  showing `product/` while omitting its sibling register would have made the maps misleading
- Repo re-init also seeded template `reports/` dir + `research/README.md` (standard
  merge-path behavior, kept)

### Audit Remediation (2026-08-12)
**Completed:** 2026-08-12, per owner dispositions of the same day
**Actual Changes:**
- **Engine, both scripts per D2** (`product.sh` + `adr.sh`, repo `.project/scripts/` copies
  refreshed and diff-verified): atomic id allocation (mkdir lock, bounded wait, EXIT-trap
  release); `set_field` fails loudly when the field is absent; `entry_file` rejects ambiguous
  (duplicate) ids; `supersede` rejects self-supersession and re-supersession (no successor-link
  overwrite); `amend` rejects self-amendment.
- **`checked` policy moved out of `new`**: skeleton writes `checked: null`; the close filing
  beat stamps `product.sh check <id>` after the entry is filled (`_my_close.md` 4b); README
  Lifecycle documents it.
- **Cross-seam rule reworked per owner disposition (audit-F1)**: pointer-entry title restates
  the promise one-liner; body stays a one-line upstream citation.
- **No withdrawal path per owner disposition (audit-F2)**: supersession covers disappearance;
  D3 status set unchanged.
- **Tests**: `test_product.sh` 36→46 (concurrency ×3, lifecycle guards ×4, malformed-entry ×2,
  checked-null ×2 adjusted); `test_adr.sh` 25→32 (lifecycle guards ×4, concurrency ×3).
- **Evidence**: E4 raw lens verdict preserved verbatim in `fixture-transcripts.md`; E3 rerun
  with script execution permitted (clean PASS, proper `product.sh` usage); E5 rerun graded
  strictly (Codex named `docs/report-contract.md` by path; full transcript captured).
- Ledger: audit-F1 resolved by owner disposition, audit-F2 INTENDED-CHANGE (owner), audit-F3
  disposed citing D2's recorded acceptance; gate CLEAR pending re-audit.
**Issues:** none
**Deviations:** none — owner explicitly bounded scope ("keep it simple"): no retire status,
no pointer-entry full restatement, no copy-drift machinery beyond refreshing the repo copies.

---

**Status progression:** Draft → In Progress → Needs Work → Remediated (pending re-audit)
