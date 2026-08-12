# Product-Lens Ledger: product-intent-ledger

Append-only. See `claude-pack/scripts/product-lens.md` §3 for format.

## spec — 2026-08-09 — rev .project/active/product-intent-ledger/spec.md (uncommitted draft)
Point (re-derived): The ledger is a sparse, judgment-led, append-only record of *implemented*
product promises with a derived current index, serving cold coding agents and product-lens
agents equally; entries summarize directly and cite authority; it imposes no mechanical
ceremony, mandatory test links, certification sequence, completeness gate, or hand-maintained
current-state document.   [source: .project/concepts/product-intent-ledger.md (Owner's Words +
[OWNER] criteria 3/4/7) and .project/adr/0001 (live, [OWNER]); docs/guide.md corroborates
(aspirational), grade: owner/HARD]
Falsifier: the spec would require a mandatory per-item ledger step or completeness/certification
gate, mandate test evidence, admit unimplemented behavior into the current index, require a
hand-maintained current-state view, or serve only one of the two consumer types.
Findings:
- spec-F1 [DON'T] The "Distribution reachability" requirement is graded [HARD] (owner-grade,
  settled-eligible, BLOCK-capable) but is an agent-derived reading of current code
  (init-project.sh seeding lists, build-codex-pack.sh edit points) — an inferred constraint
  wearing owner authority; per the provenance ladder an inference is [INFERRED], never
  owner-grade, and the embedded line numbers will drift while carrying settled force —
  claude-pack/rules/capture-fidelity.md Law 1 (INHERITED) — disposition: DISPOSE-and-proceed;
  regrade to [INFERRED] (verifiable mechanical constraint), or cite an owner statement if one
  exists.
- spec-F2 [DO]   The spec omits the ratified obligation that implementation evidence cannot
  create product authority: when no durable authority source exists, the agent surfaces the gap
  rather than inferring product intent from code (concept §5 Lightweight Capture). The
  "First capture" [NEED] covers only the owner-stated case; the no-authority case is uncovered,
  leaving room for code-derived "promises" to enter the ledger — concept §5, [AGENT] (ratified
  by owner, 2026-08-09) + capture-fidelity Law 1 (agent/ratified) — disposition:
  DISPOSE-and-proceed; add an [INFERRED]-absorbed requirement that an entry requires a durable
  authority source, and evidence alone never qualifies.
Gate: DISPOSED (spec-F1, spec-F2)

## spec (dispositions applied) — 2026-08-09 — rev .project/active/product-intent-ledger/spec.md
Resolves:
- spec-F1: FIXED — authority: INHERITED (capture-fidelity Law 1) — basis: requirement regraded [HARD] → [INFERRED], marked as mechanically verifiable with line refs dated.
- spec-F2: FIXED — authority: agent/ratified (concept §5) — basis: added "Authority before entry" requirement — evidence establishes existence, never authority; no durable source → surface the gap.
Gate: CLEAR

## audit — 2026-08-12 — rev fc48123
Point (re-derived): Cold coding agents and product-lens agents must share one compact index of
sparse, implemented promises; each entry summarizes its promise directly and traces authority,
without adding a completeness or certification gate.   [source:
.project/concepts/product-intent-ledger.md Owner's Words + [OWNER] criteria 3/4/7, grade: owner]
Falsifier: In an initialized project, either consumer cannot identify and explain the current
relevant promise from the index and cited authority, or absent entries, optional evidence, or
"none to record" blocks progress.
Findings:
- audit-F1 [DON'T] The cross-seam convention creates a special local "pointer entry" that must
  never restate the promise, directly contradicting the owner's requirement that entries summarize
  the promise and use references for traceability/detail; **Smell 3: A special category exempts a
  case whose user-visible meaning is unchanged** fires —
  .project/concepts/product-intent-ledger.md Owner's Words + criterion 3 (owner) — falsifier:
  initialize a consumer repo with only the prescribed pointer entry and ask a cold agent to state
  the upstream promise while the upstream repo is unavailable; the local orientation surface
  contains no promise to state — disposition: BLOCK
- audit-F2 [DO] The lifecycle has no no-successor withdrawal transition: `supersede` requires a
  new active entry, so a promise that disappears must remain stale or be replaced by an active
  tombstone that is not an implemented promise — .project/concepts/product-intent-ledger.md
  criterion 6 (agent/ratified), constrained by the [OWNER] implemented-only collection —
  falsifier: remove an implemented promise without replacement using only documented `product.sh`
  operations; either the old promise stays current or a negative record enters the active index —
  disposition: DISPOSE-and-proceed; add an explicit withdrawal path that preserves history while
  removing the promise from the current collection
- audit-F3 [DON'T] Shared ledger-engine behavior must be manually synchronized between `adr.sh`
  and `product.sh`, while the exact second product-script copy is outside `scripts/test_product.sh`;
  **Smell 1: Two representations must be manually kept synchronized** and **Smell 6: A test passes
  only because it selects one duplicate** fire — evaluator inference from the owner's
  proportionate-upkeep/no-ceremony constraint ([AGENT]/[INFERRED]) — falsifier: change
  `.project/scripts/product.sh` or land a shared engine fix in only one ledger script;
  `scripts/test_product.sh` remains green while repo or ledger behavior diverges — disposition:
  DISPOSE-and-proceed only after the audit explicitly accepts or removes the bounded duplication
  and covers exact-copy drift
Smells: Smell 3 fires on audit-F1; Smells 1 and 6 fire on audit-F3; each must escalate into the
audit's leading judgment.
Gate: BLOCKED (audit-F1)

## implement (audit remediation) — 2026-08-12 — rev working tree (uncommitted, anchor-on-the-point)
Resolves:
- audit-F1: FIXED — authority: owner (disposition 2026-08-12) — basis: owner chose the
  restate-at-index-granularity synthesis over full local restatement (which would duplicate
  promise text across repos with no sync — smell 1) and over ratifying the exception: a pointer
  entry's title now restates the promise's one-liner so the local index orients a cold agent;
  its body remains a single citation of the upstream repo and entry id; the full restatement
  lives only in the ruling entry (`project-pack/product/README.md` cross-seam section).
- audit-F2: INTENDED-CHANGE — authority: owner (disposition 2026-08-12) — basis: owner rejects
  a no-successor withdrawal path: in practice a promise never simply vanishes — removal comes
  with modification or replacement functionality, so supersession by the successor entry is the
  lifecycle, and D3's status set is unchanged.
- audit-F3: FIXED — authority: design D2 ([AGENT], ratified at design acceptance) — basis: the
  bounded `adr.sh`/`product.sh` duplication was explicitly weighed and accepted in D2 with the
  fix-in-both discipline as the recorded mitigation; this remediation exercised that discipline
  (lock, set_field strictness, entry_file ambiguity, lifecycle guards landed in both scripts in
  one change, with concurrency tests in both suites), and the repo's `.project/scripts/` copies
  were refreshed and diff-verified identical to `project-pack/`.
Gate: CLEAR (pending re-audit confirmation)
