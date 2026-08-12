# Concept: Product Intent Ledger

**Created:** 2026-08-09
**Status:** Draft

---

## Problem Statement

The harness reliably tells a new agent what work is active, but it does not reliably tell the
agent what the product is for or which product promises matter. Product intent accumulates in
concepts, product designs, specs, README files, ADRs, tests, and completed work. Those artifacts
were written for different moments and purposes. A cold agent must reconstruct the product's
point from them before it can judge a change correctly.

The product-lens exposes the same gap. It searches durable sources and independently re-derives
a governing obligation for each run, but there is no stable collection of the major promises last
recorded as implemented. The same product point can therefore be rediscovered with different
emphasis, or not found at all.

The practical symptom is repeated owner redirection. Agents can often explain what the code does
while losing why it exists. Code and tests remain the right source for local behavior. What is
missing is a sparse, durable orientation surface for the implemented promises that define the
product at the level of major use cases, public surfaces, and cross-cutting contracts.

## Owner's Words

- **[OWNER-VERBATIM]** "I'm not sure how agents reliably get introduced to the product intent
  and requirements of a project."
- **[OWNER-VERBATIM]** "What's funny is we faced a similar question for design decisions, and
  landed on keeping an ADR ledger. Which I think is a super useful way to formalize decisions."
- **[OWNER-VERBATIM]** "the \"product truth\" mainly; but generally I find most of my
  redirection for agents tend to be reminders of what the point of our code is"
- **[OWNER-VERBATIM]** "yes, should serve both equally"
- **[OWNER-VERBATIM]** "I think they should restate / summarize. References are for traceability
  and more detail"
- **[OWNER-VERBATIM]** "let's just focus on implemented"
- **[OWNER-VERBATIM]** "this shouldn't be every tiny feature. that would get unmanageable; the
  code is the source of truth for every little thing. We should come up with a standard; e.g.
  major use case, surface, etc."
- **[OWNER-VERBATIM]** "please don't make this too mechanical / unnecessary ceremony. just
  implementation evidence, tests are nice to have"

## Success Criteria

When this work is complete:

1. **[AGENT] (ratified by owner, 2026-08-09) One orientation surface** — a cold agent can start
   from one current index, state the product's broad purpose, identify any major implemented
   promise relevant to its task, and follow references for detail.
2. **[AGENT] (ratified by owner, 2026-08-09) One discovery surface for both consumers** —
   ordinary coding agents and product-lens agents locate the same recorded promises. The lens
   still follows provenance and independently derives its oracle from the cited authority.
3. **[OWNER] Direct but traceable entries** — each current entry summarizes the product promise
   in its own words and links to the sources that establish its authority and the evidence that
   shows it is implemented.
4. **[OWNER] Sparse by design** — routine features, local implementation behavior, and facts
   obvious from one code path remain in code and tests rather than accumulating in the ledger.
5. **[AGENT] Honest recorded state** — each active entry says where or when the promise was last
   reasonably checked as implemented. The index is orientation, not mechanical proof that every
   branch still upholds every recorded promise.
6. **[AGENT] (ratified by owner, 2026-08-09) Honest change history** — when a recorded promise
   materially changes or disappears, cold agents see the new current meaning while the earlier
   record remains traceable.
7. **[OWNER] Proportionate upkeep** — recording product intent does not require a new
   certification sequence, mandatory test link, or completeness gate.
8. **[AGENT] Observable orientation** — in fresh-agent exercises covering a relevant task, an
   unrelated local task, and a superseded promise, the agent finds the applicable active entry,
   follows its authority source, ignores the superseded entry, and correctly reports no ledger
   match for the unrelated task.

---

## Why This Shape

- **Key bet:** **[OWNER]** An ADR-like ledger with an index can make major product intent durable
  and findable across sessions.
- **Why this shape is promising:** **[AGENT] (ratified by owner, 2026-08-09)** A dedicated
  product-intent ledger keeps product promises distinct from architectural decisions. Immutable
  historical entries plus a derived current index preserve change history without maintaining a
  second hand-written current-state document.
- **Constraint to preserve downstream:** **[OWNER]** The ledger stays useful through judgment
  and exclusion. It is not an inventory of everything the code can do.

---

## User Stories

### Starting Work

**US-1: Understand the product before editing**
As a cold coding agent, I can skim the current product-intent index and open only the entries
relevant to my task, so that I understand the point of the code before changing it.

**US-2: Know when no major promise applies**
As a coding agent doing local mechanical work, I can determine that no indexed product promise
applies and proceed without loading the ledger's full history.

### Checking Product Alignment

**US-3: Re-derive from shared discovery**
As a product-lens agent, I can use the current product-intent index to find applicable promises
and their authority sources, so that I can independently derive an oracle from the same product
meaning a cold coding agent received.

**US-4: Trace authority and evidence**
As an agent investigating a promise, I can follow its source and implementation-evidence links,
so that I can distinguish product intent from a summary, implementation claim, or green test.

### Keeping the Record Current

**US-5: Record an important implemented promise**
As an agent completing meaningful implementation work, I can record a provenance-backed major
product promise when it crosses the density bar, without adding ceremony when it does not.

**US-6: Change a promise honestly**
As an agent changing or removing a recorded promise, I can make the new current meaning visible
without erasing the earlier record.

---

## Key Concepts

### 1. Product Promise

**[AGENT] (ratified by owner, 2026-08-09)** A product promise is a plain-language statement of
implemented product meaning. It describes why a major use case or surface exists, or what must
remain true across multiple parts of the product. It does not catalog its internal mechanism.

### 2. Density Standard

**[AGENT] (ratified by owner, 2026-08-09)** Record an implemented behavior when it is a real
product promise — a major use case, public surface, or cross-cutting contract — and a cold agent
changing related code could reasonably miss or undo it. Skip routine features, implementation
choices, and facts obvious from one local code path.

This is a judgment standard, not a checklist. Its purpose is to keep the index small enough that
agents trust and read it.

### 3. Current Index and Historical Ledger

**[AGENT] (ratified by owner, 2026-08-09)** Entries preserve what was recorded and why. A derived
index presents only the active promises last recorded as implemented, including where or when
their implementation was checked. Material changes create a successor or equivalent explicit
lifecycle transition rather than silently rewriting history.

**[AGENT]** The index cannot prove that unrelated later work never caused drift without the
completeness gate the owner rejected. An agent changing a related surface uses the record as
orientation, checks whether the promise still holds, and records a change when needed.

### 4. Summary, Authority, and Evidence

**[OWNER]** An entry restates or summarizes the promise directly. References carry traceability
and detail.

**[INHERITED: `claude-pack/rules/capture-fidelity.md`]** The promise's authority still comes from
its cited source and preserved provenance. Implementation evidence supports the claim that the
behavior exists; it does not manufacture authority. Evidence is proportional to the behavior.
Tests are useful when they exist, but they are not required. A summary carries its own provenance
and never inherits a citation's authority merely by restating it.

### 5. Lightweight Capture

**[AGENT] (ratified by owner, 2026-08-09)** The normal capture moment is after a meaningful
behavior has been implemented and reasonably checked. The agent asks whether a provenance-backed
promise crosses the density standard. If it does, the record is created or updated. If it does
not, work continues without a ledger ritual. Implementation evidence can establish that behavior
exists; it cannot create product authority. When no durable authority source exists, the agent
surfaces the gap rather than inferring product intent from code. Existing completion workflows may
catch an important promise that was missed, but the ledger is not a shipping gate.

### 6. Honest Absence

**[AGENT]** An absent or empty ledger means no major promises have been recorded there. It does
not mean the product has no purpose or governing obligations. Agents continue through README,
docs, ADRs, and owner-grade concept sources without error.

---

## Scope of Behavior Changes

### New artifacts to create

- **[AGENT] (ratified by owner, 2026-08-09)** A dedicated, ADR-like product-intent ledger for
  major implemented promises.
- **[OWNER]** A compact index that lets agents find current promises quickly.
- **[AGENT] (ratified by owner, 2026-08-09)** A convention for recording, changing, and locating
  entries while preserving source authority and history.

### Existing artifacts to modify

- **[AGENT] (ratified by owner, 2026-08-09)** Agent startup guidance recognizes the
  product-intent index as the broad product-orientation source alongside active-work context.
- **[AGENT]** The shared product-lens source protocol uses the index for discovery, then follows
  entry provenance and cited authority before deriving its oracle.
- **[AGENT] (ratified by owner, 2026-08-09)** Completion guidance gives agents a lightweight
  opportunity to record or update a ledger-worthy promise after implementation.
- **[AGENT]** Project templates and user documentation explain the ledger's purpose and density
  standard.

### Behavior changes by workflow stage

- **[AGENT] Session start:** skim the current index; open relevant entries only. An absent or
  empty index is honest absence, not proof that the product has no purpose.
- **[AGENT] Shaping and implementation:** existing entries inform work, but proposed behavior does
  not enter the current index.
- **[AGENT] (ratified by owner, 2026-08-09) Implementation completion:** apply the density
  standard with proportionate evidence; record only a provenance-backed promise when the behavior
  merits it.
- **[AGENT] Product-lens checks:** use the index to locate relevant promises, then derive and grade
  obligations from the entries' provenance and cited authority.
- **[AGENT] (ratified by owner, 2026-08-09) Material product change:** make the new current promise
  visible while retaining history.

---

## Non-Goals / Out of Scope

- **[OWNER]** A complete feature inventory is out of scope; detailed product behavior remains in
  the code and its tests.
- **[OWNER]** Mandatory test links or a new certification/completeness gate are out of scope;
  evidence stays proportional to the promise.
- **[OWNER]** Backfilling existing projects is outside this concept.
- **[AGENT] (ratified by owner, 2026-08-09)** The ledger does not replace README files, concepts,
  product designs, specs, ADRs, or tests. Those remain sources of detail, authority, and evidence.
- **[AGENT] (ratified by owner, 2026-08-09)** Architectural and implementation decisions remain
  in ADRs or design artifacts rather than being duplicated as product promises.

---

## Assumptions & Prerequisites

- **[INHERITED: `.project/adr/README.md`]** The existing ADR convention provides a proven local
  pattern for sparse admission, append-only history, lifecycle changes, and a generated index.
- **[INHERITED: `claude-pack/scripts/product-lens.md`]** The product-lens already distinguishes
  source authority from implementation evidence and refuses to treat work or tests as truth.
- **[AGENT] (ratified by owner, 2026-08-09)** "Implemented" means the behavior exists and has been
  reasonably checked on the current branch; it does not require a particular pipeline stage.
- **[AGENT]** The repository can expose the same current product-intent view to both Claude and
  Codex agents.

## Open Questions

1. What minimum entry information lets agents understand the promise, applicability, provenance,
   lifecycle, and implementation evidence without turning the format into a form-filling exercise?
2. How should the index help agents select promises by major use case or surface while remaining
   compact?
3. Which existing completion touch point provides the lightest useful reminder to record a new or
   changed promise?
4. How should evidence references remain useful when code and test paths move, without making path
   maintenance a new gate?
5. What is the leanest way to preserve a summary's own provenance while helping the product-lens
   follow and grade its cited authority?
6. How should entries describe partial rollout or feature-flag applicability without becoming
   implementation catalogs?
7. Where should a product promise live when more than one repository must uphold it?
8. May a ledger entry be the first durable capture of an owner-stated promise, and if so, what
   preserves the owner's exact force?

---

## Next-Stage Handoff

**Settled here:**

- **[OWNER]** The product-intent surface serves cold coding agents and product-lens agents equally.
- **[OWNER]** Entries summarize the product promise directly; references provide traceability and
  detail.
- **[OWNER]** The current collection covers implemented behavior.
- **[OWNER]** The ledger is sparse. Major use cases and public surfaces are candidates; ordinary
  feature detail remains in code.
- **[AGENT] (ratified by owner, 2026-08-09)** Cross-cutting product contracts may also cross the
  density bar when a cold agent could reasonably miss or undo them.
- **[OWNER]** Implementation evidence is proportional, and tests are optional.
- **[OWNER]** The workflow must avoid mechanical ceremony and new completeness gates.

**Needs spec next:**

- Define the lean entry and index contract while preserving the judgment-led density standard.
- Define the smallest read and write touch points for cold starts, product-lens checks, and
  implementation completion.
- Define honest lifecycle behavior for new, changed, and withdrawn promises.
- Define observable validation for Claude/Codex orientation parity and product-lens consumption.

**Decomposition guidance:**

- **[AGENT]** Treat this as one scoped work item unless distribution parity or lifecycle tooling
  proves large enough to require an independently verifiable slice.

---

## Appendix: Current-State Grounding

- **[INHERITED: `claude-pack/rules/context-loading.md:3-7`]** Session startup currently loads
  active-work context and loosely referenced docs, not a dedicated product-purpose source.
- **[INHERITED: `claude-pack/scripts/product-lens.md:20-44`]** The product-lens currently searches
  README, docs, ADRs, and owner-verbatim concept material, then derives a fresh obligation and
  falsifier for every run.
- **[INHERITED: `.project/research/20260803-210317_pipeline-product-truth-control-review.md:28-49`]**
  Prior research found that the pipeline preserves artifact lineage better than product truth.
- **[INHERITED: `.project/adr/0001-decision-records-convention.md:21-37`]** The owner rejected a
  hand-maintained current-state architecture register. Append-only records with a derived index
  avoid that maintenance model.
