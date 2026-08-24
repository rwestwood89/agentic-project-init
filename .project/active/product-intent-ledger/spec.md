# Spec: Product Intent Ledger

**Status:** Remediated (2026-08-12), pending re-audit
**Owner:** Reid W
**Created:** 2026-08-09 20:13
**Complexity:** MEDIUM
**Branch:** TBD (spec drafted on `anchor-on-the-point`)

---

## Problem

The harness reliably tells a new agent what work is active (`CURRENT_WORK.md`), but not what
the product is for. Product intent accumulates across concepts, product designs, specs, README
files, ADRs, and tests — artifacts written for different moments and purposes. A cold agent must
reconstruct the product's point from them before it can judge a change correctly. The practical
symptom is repeated owner redirection — **[OWNER-VERBATIM]** "generally I find most of my
redirection for agents tend to be reminders of what the point of our code is" (concept, Owner's
Words).

The product-lens exposes the same gap from the other side: it searches durable sources fresh on
every run (`claude-pack/scripts/product-lens.md` §1), so there is no stable collection of the
major promises last recorded as implemented — the same product point can be rediscovered with
different emphasis, or not found at all.

Code and tests remain the right source for local behavior. What is missing is a sparse, durable
orientation surface for the implemented promises that define the product: major use cases,
public surfaces, and cross-cutting contracts.

## Success Criteria

Absorbed from the concept's success criteria; provenance noted per item — "(owner)" is
owner-stated, "(ratified)" is agent-derived and ratified by owner 2026-08-09.

- [x] **One orientation surface** (ratified) — a cold agent starts from one current index,
  can state the product's broad purpose, find any major implemented promise relevant to its
  task, and follow references for detail.
- [ ] **One discovery surface for both consumers** (ratified) — ordinary coding agents and
  product-lens agents locate the same recorded promises; the lens still follows provenance and
  independently derives its oracle from the cited authority.
- [ ] **Direct but traceable entries** (owner) — each current entry summarizes the promise in
  its own words and links to the sources that establish its authority and the evidence that
  shows it is implemented.
- [x] **Sparse by design** (owner) — routine features, local implementation behavior, and facts
  obvious from one code path stay in code and tests, not the ledger.
- [ ] **Honest recorded state** (agent) — each active entry says where or when the promise was
  last reasonably checked as implemented. The index is orientation, not proof against drift.
- [ ] **Honest change history** (ratified) — when a promise materially changes or disappears,
  cold agents see the new current meaning while the earlier record remains traceable.
- [x] **Proportionate upkeep** (owner) — no new certification sequence, mandatory test link, or
  completeness gate.
- [ ] **Observable orientation** (agent) — fresh-agent exercises pass in all three scenarios:
  given a relevant task the agent finds the applicable active entry and follows its authority
  source; given an unrelated local task it correctly reports no ledger match; given a superseded
  promise it ignores the old entry in favor of the current meaning. A product-lens run consumes
  the index for discovery. The same current view is reachable by Claude and Codex agents.

## Known Requirements

- **[NEED]** The current collection covers **implemented behavior only** — **[OWNER-VERBATIM]**
  "let's just focus on implemented." Proposed or planned behavior never enters the current index.
- **[NEED]** **Sparse by standard, not inventory** — **[OWNER-VERBATIM]** "this shouldn't be
  every tiny feature. that would get unmanageable; the code is the source of truth for every
  little thing. We should come up with a standard; e.g. major use case, surface, etc." The
  density standard: record a promise when it is a major use case, public surface, or
  cross-cutting contract *and* a cold agent changing related code could reasonably miss or undo
  it (cross-cutting-contract clause agent-derived, ratified 2026-08-09). A judgment standard,
  not a checklist.
- **[NEED]** **Entries restate; references trace** — **[OWNER-VERBATIM]** "I think they should
  restate / summarize. References are for traceability and more detail."
- **[NEED]** **No mechanical ceremony** — **[OWNER-VERBATIM]** "please don't make this too
  mechanical / unnecessary ceremony. just implementation evidence, tests are nice to have."
  Evidence is proportional to the promise; tests are optional.
- **[NEED]** **Serves both consumers equally** — **[OWNER-VERBATIM]** "yes, should serve both
  equally" (coding agents and product-lens agents).
- **[NEED]** **First capture allowed, expected rare** — a ledger entry may be the first durable
  capture of an owner-stated promise, preserving the owner's exact words (`[OWNER-VERBATIM]`
  discipline, as concepts use). Decided by owner in this spec session (2026-08-09), with the
  note that it should be rare: "at the very least we have a spec for a work item" — the normal
  entry cites an existing artifact. This gives the product-lens's "can't-find → write the point
  down" disposition (`product-lens.md` §1.4) a concrete home.
- **[INFERRED]** **Append-only history, derived current view** — entries are immutable records;
  a derived index presents only the active promises. Material changes are an explicit lifecycle
  transition (successor or equivalent), never a silent rewrite. (Agent-derived in the concept,
  ratified by owner 2026-08-09.)
- **[INHERITED: `.project/adr/0001-decision-records-convention.md`]** **No hand-maintained
  current-state document** — the owner rejected that maintenance model for decision records;
  the current index must be derived from the entries, not maintained by hand.
- **[INHERITED: concept §Honest Absence]** An absent or empty ledger means "no major promises
  recorded," never an error. Agents continue through README, docs, ADRs, and owner-grade
  concept sources.
- **[INFERRED]** **Lens discovery order** — the product-lens uses the index to locate applicable
  promises, then follows each entry's provenance to its cited authority before deriving its
  oracle. A summary carries its own provenance and never inherits its citation's authority
  (capture-fidelity). (Agent-graded in the concept, not individually ratified.)
- **[INFERRED]** **Authority before entry** — every entry rests on a durable authority source
  (spec, concept, ADR, docs, or a first-capture owner quote). Implementation evidence
  establishes that the behavior *exists*; it never creates product *authority*. When no durable
  source exists and the owner has not stated the promise, the agent surfaces the gap rather
  than inferring product intent from code. (Agent-derived in concept §5 Lightweight Capture,
  ratified by owner 2026-08-09.)
- **[INFERRED]** **Distribution reachability** — a mechanically verifiable constraint of the
  current build/install code, line refs as of 2026-08-09: `.project/` conventions reach
  projects (Claude and Codex alike) only through `scripts/init-project.sh`, so a new
  `.project/` directory must be added to both seeding lists (`init-project.sh:189` merge path,
  `:204` fresh path). Codex receives harness *instructions* only via rules auto-shipped into
  `AGENTS.md` or via command bodies; a new shared script spec needs two hardcoded edits in
  `build-codex-pack.sh` (`:375-380` copy loop, `:137-138` path rewrite).

## Non-Goals

All owner-stated in the concept:

- A complete feature inventory. Detailed product behavior stays in code and tests.
- Mandatory test links, a certification sequence, or a completeness gate.
- Backfilling existing projects.
- Replacing README files, concepts, product designs, specs, ADRs, or tests — those remain the
  sources of detail, authority, and evidence (ratified).
- Duplicating architectural or implementation decisions as product promises — those stay in
  ADRs and design artifacts (ratified).

## Open Questions / Deferred to design

- **Entry format** — the minimum fields for promise, applicability, provenance, lifecycle, and
  evidence without form-filling. Constraint from requirements: judgment-led, restate-plus-cite.
- **Index shape** — how the index helps agents select by use case or surface while staying
  compact. The ADR `INDEX.md` generator (`project-pack/scripts/adr.sh:82-92`, lazy bootstrap)
  is the local precedent.
- **Lifecycle mechanics** — whether statuses are script-managed (mirroring `adr.sh`
  new/supersede/amend/index) or convention-only. Constraint: derived index, append-only, and no
  ceremony beyond what history-preservation needs.
- **Completion touch point placement** — where the "does this cross the density bar?" moment
  attaches. Exploration found `_my_close` is the natural candidate (it already carries the ADR
  three-beat: scan at Step 2.4, confirm at Step 3, file at 4b before archiving —
  `claude-pack/commands/_my_close.md:29,43,58`), with `_my_audit` as the evidence source. Not
  a shipping gate either way (owner).
- **Session-start wiring** — how startup guidance (`claude-pack/rules/context-loading.md`) and
  orientation commands (`_my_status`, `_my_project_find`) point at the index; neither mentions
  even the ADR index today.
- **SOURCES wiring for the lens** — each call site defines SOURCES inline (5 sites); the
  cleanest single edit is the shared definition at `product-lens.md:22-23`. Design decides
  whether to centralize.
- **Evidence path drift** — how evidence references stay useful when code/test paths move,
  without a path-maintenance gate (owner constraint). "Last checked where/when" semantics from
  Success Criteria bound this.
- **Partial rollout / feature flags** — how an entry describes limited applicability without
  becoming an implementation catalog.
- **Multi-repo promises** — where a promise lives when several repos must uphold it. The ADR
  cross-seam rule (ruling entry in the upholding repo, pointer entry locally —
  `project-pack/adr/README.md:72-79`) is the natural precedent.
- **Validation fixtures** — whether the observable-orientation exercises run against seeded
  fixture entries or real dogfood entries in this repo. Plan-level.

---

## Related Artifacts

- **Concept:** `.project/concepts/product-intent-ledger.md` (primary input; carries the owner
  verbatims and ratified decisions absorbed above)
- **Research:** `.project/research/20260803-210317_pipeline-product-truth-control-review.md`
- **Product-lens ledger:** `.project/active/product-intent-ledger/product-lens.md`
- **Design:** `.project/active/product-intent-ledger/design.md` (to be created)

No epic — the concept's decomposition guidance treats this as one scoped work item.

---

**Next Steps:** After approval, proceed to `/_my_design` (a `/_my_spec_review` in a fresh
session is available first if wanted).
