> **SUPERSEDED 2026-08-20 — do not treat anything here as current.**
>
> Part of the v1 design chain for the mental-alignment checkpoint, archived after the concept was overhauled on
> 2026-08-19 and 2026-08-20. See `design-revised.md` in this folder for the list of claims that are now wrong.
>
> **Live concept:** `.project/concepts/mental-alignment-checkpoint.md`

# Concept-Design Review: Mental Alignment Checkpoint

**Concept:** `.project/concepts/mental-alignment-checkpoint-design.md`
**Review File:** `.project/concepts/mental-alignment-checkpoint-design-review.md`
**Date:** 2026-08-09

## Fundamental Assessment

**Judgment:** Concerns

### Are we actually solving the right problem?

Yes. The semantic gap is real and owner-stated: the workflow produces durable artifacts
faster than the owner can read them, so human judgment loses its footing — product drift,
architectural slop, and small code issues escape spot checks. The missing capability is an
explanatory surface, not another certifier. The design serves exactly that: on-demand,
question-led reconstruction, with explanation visibly separated from agent judgment, and
no new authority created.

One classic challenge was considered and rejected: "fix the artifacts upstream instead of
adding a downstream reconstruction layer." The artifacts are long because they serve
agent-to-agent fidelity (capture-fidelity provenance, auditability); compressing them for
owner readability would degrade their actual job. A separate comprehension surface is the
repair at the right layer, and the owner settled this shape (`[OWNER]` key bet in the
parent concept's Why This Shape).

### Architecture verdict

The system shape is right: one thin public entry, one one-job builder contract holding the
large context budget, append-only runs as working evidence under ADR-0001's snapshot
philosophy, feedback local until explicit promotion, and only two optional stage offers.
Every one of those follows an owner-settled item or a sound precedent (the product-lens
call-site pattern).

The concerns are inflation and one ownership defect, not wrong shape:

1. The design promotes the pack's default calling convention (a command spawns a
   subagent with a complete contract file) into a named "coordinator" component with its
   own ADR candidate. That manufactures architecture out of the pattern every
   subagent-spawning command already uses.
2. Output-invariant ownership is duplicated: the builder contract promises "safe,
   traceable, two-layer, or report failure," while the coordinator also "checks the
   result" and must suppress unsafe runs. Two owners of one guarantee is the design's own
   smell 2 (consumer compensating for a producer's claimed guarantee).
3. Three ADR candidates where roughly one and a half are warranted (see candidate
   assessment).

These are fixable in the document without changing the capability.

## Ponytail Challenge

Verbatim subagent result (ultra intensity, architecture-adapted):

> **Scope note:** The capability itself is owner-settled (HTML, on-demand, delegation to a
> subagent, two layers, two stage offers, committed runs, local feedback — Next-Stage
> Handoff, `mental-alignment-checkpoint.md`). I challenge the design's machinery for
> serving that, not the decisions.
>
> **1. Does this proposed machinery need to exist at all?** The core does. The pack has no
> owner-comprehension surface, and the owner settled the shape. What does not need to
> exist:
> - **The "coordinator" as an architectural component.** The design names a `coordinator`
>   with its own duty list — "starts the builder, checks the result, handles explicit
>   feedback requests" (Core Model) — and files an ADR candidate for the
>   coordinator/builder split. But this is just the pack's default calling convention: a
>   command file spawns a `general-purpose` subagent whose entire instruction set is one
>   contract file. Product-lens already works exactly this way with **no coordinator at
>   all** — call sites spawn the subagent directly (`claude-pack/scripts/product-lens.md`,
>   header). The "coordinator" is a command. Naming it a component and recording the split
>   as an ADR manufactures architecture out of the calling convention every
>   subagent-spawning command in the pack already uses.
> - **ADR candidate 2** ("One coordinator delegates to one builder contract"). Its stated
>   justification — "the roles could be merged later" — is defense against a hypothetical
>   future mistake. The command file itself documents the delegation. YAGNI; drop it.
> - **ADR candidate 3** ("Promotion changes only shared authored instructions"). This
>   restates an invariant that already has an owner: `docs/STRUCTURE.md` ("Never edit
>   dist/codex by hand; edit claude-pack") — which the concept itself already carries as
>   `[INHERITED: docs/STRUCTURE.md]`. Filing it again as a project ADR creates two
>   representations of one rule that must stay synchronized (the design's own smell 1).
>   Drop it; cite STRUCTURE.md from the command.
> - **ADR candidate 1** (read-only touch point) is the only one with a live question, and
>   even it is doubtful. The touch-point map (ADR-0002, as amended by 0005/0006) records
>   **enforced** contacts: reads enforced by an output that depends on them, writes
>   attached to gates (0002, Why). The checkpoint is not a stage; it has no required ADR
>   read — the owner explicitly settled flexible context with no source list. An optional
>   reader is not a touch point, so omitting it does not "make the recorded map false." At
>   most this is a one-line 0005 amendment at acceptance; more likely nothing.
>
> **2. What existing machinery can be deleted instead of accommodated?** Nothing is
> deleted, and one existing route goes unmentioned. `_my_research` is already a
> question-led, flexible-source, committed-under-`.project/` investigation surface. The
> checkpoint differs where the owner said it should (HTML, two layers, owner-comprehension
> audience) — but the design adds a second question-led route without stating its relation
> to the first. System Confidence covers route agreement between the checkpoint's own
> entry points but not between checkpoint and research. Say in one line when each is the
> right tool, or let a checkpoint run cite prior `.project/research/` instead of
> re-deriving — otherwise this is another route to "understand this area" with no
> equivalence claim.
>
> Also: the product-design discoverability fix (Stage Offers, last sentence) is a
> separable one-line edit to two discovery contracts (`_my_concept_design.md:137-148`,
> `_my_epic_plan.md:16`). It is ratified into scope, fine — but it should not become an
> epic item; it is a quick edit riding along.
>
> **3. Is the invariant repaired at its real owner, or compensated downstream?** Mostly
> the right owner, with one real violation:
> - **HTML safety and two-layer structure belong to the builder contract** — and the
>   design says so under Required Invariants. But the coordinator also "checks the result"
>   and must "not report a successful run" on unsafe HTML (Core Model; Edge Cases). That
>   is a consumer compensating for a guarantee the producer's contract claims to own — the
>   design's own smell 2. Either the builder contract owns "safe, traceable, two-layer, or
>   report failure" and the coordinator merely relays success/failure, or the coordinator
>   owns validation and the contract doesn't promise it. Pick one owner. The unspecified
>   "check" is duplicated ownership.
> - The product-design mismatch fix lands at the real owner (the two stages' discovery
>   instructions), not in the checkpoint. Good.
> - Promotion targeting authored source, not generated copies, keeps the invariant at its
>   existing owner (STRUCTURE.md). Right repair — it just doesn't need a new ADR to say so.
>
> **4. Which abstraction, adapter, representation, or compatibility path can be removed?**
> - The `coordinator` **vocabulary**. The pack already has words for this: a command and a
>   subagent contract. A coined component name for the default pattern is comprehension tax.
> - **Two of three ADR candidates** (see 1).
> - The coordinator's **bundled feedback/promotion duties**. Recording feedback is
>   appending a block to `.project/mental-alignment/feedback.md` — a file convention, not
>   an operation a component must "handle." Promotion is an ordinary owner-reviewed edit
>   to pack source, governed by the existing authored-source rule. Both need a paragraph
>   of instructions, not coordinator responsibilities. As written, one command owns three
>   jobs (generate, record feedback, promote); the builder contract's one-job discipline
>   (`product-lens.md` §1: "You have exactly one job") is the precedent the design cites
>   and then doesn't follow for its own front door.
>
> **5. What is the smallest architecture that solves the semantic problem?** Five things,
> no new components beyond two files:
> 1. One command (`_my_checkpoint` or similar): take the question, spawn a
>    `general-purpose` subagent with the builder contract, return path + the builder's
>    summary. Product-lens call-site pattern, verbatim.
> 2. One builder contract in `claude-pack/scripts/`, owning discovery, two-layer HTML,
>    safety, run metadata, and failure reporting — the single owner of every output
>    invariant.
> 3. Two one-line offers: `_my_concept_design_review.md` Stage 5 (after findings, before
>    resolution) and `_my_epic_plan.md` Stage 2 approval point. Plus the one-line
>    product-design discovery fix in both stages' input sections.
> 4. `.project/mental-alignment/runs/` + `feedback.md` as file conventions defined inside
>    the two files above — data, not components.
> 5. Promotion as one paragraph: "on explicit request, draft the edit against the shared
>    authored source; if unavailable, record the candidate locally and stop" — resting on
>    STRUCTURE.md, no new decision record.
>
> Zero to one ADRs (a minimal 0005 amendment only if the owner wants the map to name the
> checkpoint's stage-boundary contact), not three. No preservation-evidence defect is
> being hidden — this is a greenfield capability; the one known defect (product-design
> discoverability) is fixed at its owner, not papered over.
>
> **6. Verdict: CHALLENGE.** The design's substance is right — the intended behavior,
> invariants, and offer points serve the owner's settled scope — but it inflates the
> pack's proven two-file pattern into named architecture: a "coordinator" component with
> duplicated invariant ownership (result-checking the builder contract already owes) and
> three ADR candidates of which two record no decision — one restates the default calling
> convention, the other restates STRUCTURE.md's inherited authored-source rule. Strip the
> coordinator to a plain command, give every output invariant one owner (the builder
> contract), and drop ADR candidates 2 and 3; what remains is the same capability with
> roughly half the ceremony.

### Disposition

Point by point:

- **Coordinator-as-component + bundled duties (challenge 1, 4): Accepted.** The
  product-lens precedent shows call sites spawning the builder directly with no named
  middle component. The design's own Vocabulary already admits the coordinator "is the
  public command." Deflate it: describe a plain command that spawns the builder, and treat
  the runs directory and feedback ledger as file conventions the two documents define, not
  operations a component "handles." The capability is unchanged.
- **Drop ADR candidate 2 (challenge 1): Accepted.** The load-bearing half of that decision
  — delegation to a specialized subagent so the main agent's context stays small — is
  already `[OWNER]`-settled and durably recorded in the parent concept's Next-Stage
  Handoff. The remaining half (cross-runtime command rather than native skill or custom
  agent) is the pack's default pattern, and the candidate's own rationale ("roles could be
  merged later") is defense against a hypothetical. It fails ADR-0001's density bar. The
  decision stands in Architectural Bets; no record is filed.
- **Drop ADR candidate 3 (challenge 1): Rejected in part, reshape instead.** The smell-1
  restatement risk is real, but the candidate is not only a restatement.
  `docs/STRUCTURE.md` governs an agent sitting in this repo; it does not reach an agent
  running the checkpoint in a vendored or copy-installed target project, which is exactly
  where a promotion request will arrive with only generated or installed copies in view.
  The fail-closed rule — promote only into reachable shared authored source, otherwise
  record a local candidate and stop — answers the parent concept's open question 3 and is
  a cross-seam decision STRUCTURE.md does not own. Reshape the candidate to center that
  fail-closed cross-project behavior and cite STRUCTURE.md as the `[INHERITED]` base
  instead of restating its rule.
- **Doubt on ADR candidate 1 (challenge 1): Rejected with evidence.** ADR-0006 is the
  direct precedent: a read-only contact by a review procedure, recorded as its own entry
  amending ADR-0005's map. This project's history shows why: the anchor-on-the-point audit
  BLOCKED its own feature for changing the touch-point map without the record ADR-0001
  requires (`CURRENT_WORK.md`, 2026-08-05). The candidate's load-bearing half is also the
  write prohibition — a surface that exposes decision conflicts must never file, amend, or
  supersede records. Keep the candidate; reshape it to lead with the write prohibition.
- **Single owner for output invariants (challenge 3): Accepted.** The builder contract
  owns "safe, traceable, two-layer snapshot or report failure"; the command relays the
  builder's success or failure and adds no second validation duty. The design must say
  this in one place and remove the coordinator's "checks the result" duty.
- **Checkpoint vs `_my_research` relation (challenge 2): Accepted, minor.** One line
  settles it: research produces an agent-facing investigation record; the checkpoint
  produces an owner-facing explanation, and a checkpoint run cites existing
  `.project/research/` findings instead of re-deriving them.
- **Product-design discoverability fix as a rider (challenge 2): Accepted as
  decomposition guidance.** It is a ratified in-scope repair at the right owner; note in
  the handoff that it is a small rider edit, not an epic item.

## Dimensional Review

### 1. Semantic Model — Pass

The architecture represents the domain meaning directly: explanation and critique are
separate layers, a run is dated working evidence, claims keep provenance and force, and
conflicts are shown rather than reconciled. No mechanism category exempts a meaningful
case, and no preservation evidence protects a defect — the capability is greenfield, and
the one known defect it touches (shaping product-design discoverability) is repaired at
its owner.

### 2. Responsibility and Invariant Ownership — Concerns

Promotion targeting only shared authored source keeps that invariant at its existing
owner. Snapshot-not-authority is owned by the run's format and metadata. The defect: the
builder contract and the coordinator both own the output guarantee (safety, layering,
failure reporting) — accepted ponytail challenge, must be resolved to one owner.

### 3. Simplification and Deletion — Concerns

Nothing is retired, which is acceptable for a new capability, but the proposal adds more
naming and record ceremony than the capability needs: a component name for the default
calling convention and two ADR candidates that mostly re-record existing decisions. The
relation to the existing question-led route (`_my_research`) goes unstated. The
append-only-runs choice is genuinely simplifying — it resolves the parent concept's open
question 4 in the direction ADR-0001 already committed to (dated snapshots over maintained
state) and avoids a synchronized living explainer.

### 4. Abstraction Quality — Concerns

The builder contract is the right abstraction at the right level, with a proven precedent
(`claude-pack/scripts/product-lens.md`). The "coordinator" is an unnecessary abstraction:
one existing pattern (a command) expresses it more clearly. The vocabulary section defines
`coordinator` honestly as "the public command," which confirms the component framing adds
nothing.

### 5. System Confidence — Pass

Seam obligations are explicit: same contract from every entry route, builder returns one
safe snapshot or reports failure, both stage offers behave identically after reaching the
entry point. The unowned proofs are named and assigned to the epic: comprehension
efficacy, Claude/Codex equivalence, promotion fail-closed. One small gap (minor issue
below): no equivalence note for the checkpoint-vs-research overlap.

### 6. Decisions and ADR Candidates — Concerns

The load-bearing decisions are explicit (Architectural Bets) and reasoned. The candidate
set needs pruning: one keep-with-reshape, one reshape, one drop — see the candidate
assessment. Conflict handling with the live record is correct and shows the right lesson:
Prior Art states that acceptance must amend ADR-0005's map rather than add the reader
silently, and no live decision is contradicted.

### 7. Comprehension — Pass

A cold reader gets the problem, the shape, and why it is small. The two-register
discipline holds. The one comprehension tax is the coined `coordinator`, which dissolves
once the design says "command."

## Issues by Severity

### Critical

- None.

### Major

1. **One owner for the output guarantee.** The builder contract owns "safe, traceable,
   two-layer snapshot, or report failure." Remove the coordinator's "checks the result"
   duty (or explicitly move validation to the command and strip the promise from the
   contract — but the builder-owns-it direction matches the product-lens precedent).
   (Core Model, System Confidence, Edge Cases.)
2. **Deflate the coordinator to a plain command.** Describe the public surface as a
   cross-runtime command that spawns the builder — the pack's existing pattern — and treat
   the runs directory and feedback ledger as file conventions, not component operations.
3. **Drop ADR candidate 2; reshape candidates 1 and 3** per the candidate assessment
   below.

### Minor

4. **State the relation to `_my_research`** in one line, and have the builder cite
   existing `.project/research/` findings rather than re-derive them.
5. **Mark the product-design discoverability fix as a rider edit** in the handoff so epic
   planning doesn't inflate it into an item.

## ADR Candidate Assessment

- **The checkpoint is a read-only decision-record touch point: keep, reshape.** Lead with
  the write prohibition (a conflict-surfacing artifact must never file or alter records);
  the map amendment follows the ADR-0006 pattern (new entry that amends 0005's map).
  Provenance `[AGENT]` is honest and matches 0006.
- **One coordinator delegates to one builder contract: drop.** The owner-settled half
  (delegation to a specialized subagent) is durably recorded in the parent concept with
  `[OWNER]` provenance; filing it under `[AGENT] (ratified)` would degrade that grade. The
  agent-chosen half (cross-runtime command as the surface) is the pack default and fails
  the density bar. The decision itself stands in Architectural Bets.
- **Promotion changes only shared authored instructions: reshape.** Center the new
  decision — fail-closed promotion from any project context, targeting only reachable
  shared authored source, stopping locally otherwise — and cite `docs/STRUCTURE.md` as the
  `[INHERITED]` base instead of restating its rule, so there is one representation of the
  authored-source invariant.

## Resolutions

**[OWNER] (2026-08-09):** The owner accepted the ponytail challenge in full and directed
maximal simplification: "simplify the fuck out of it, just follow all the same patterns we
are using." This overrides the review's two partial rejections (keeping ADR candidate 1
and reshaping candidate 3). The binding direction for the revised concept is the
ponytail's smallest architecture (challenge point 5):

1. One plain cross-runtime command: take the question, spawn a `general-purpose` subagent
   with the builder contract, return the path and the builder's summary. No named
   "coordinator" component.
2. One builder contract in `claude-pack/scripts/`, sole owner of every output invariant:
   discovery, two-layer HTML, safety, run metadata, failure reporting.
3. Two one-line stage offers plus the one-line product-design discovery fix, edited in
   place at the two stages.
4. `.project/mental-alignment/runs/` and `feedback.md` as file conventions defined inside
   the two files above — data, not components.
5. Promotion as one paragraph resting on `docs/STRUCTURE.md`: on explicit request, draft
   the edit against the shared authored source; if unavailable, record the candidate
   locally and stop.

**ADR candidates: all three dropped as standalone records.** The fail-closed promotion
behavior and the read-only/no-filing behavior survive as command/contract text, not
records.

**One sliver left to the author at acceptance (agent recommendation, strikeable):** the
ponytail allowed "zero to one ADRs" — the one being a one-line amendment to ADR-0005's
touch-point map noting the checkpoint's read-only contact. Recommended, because this
project previously took an audit BLOCK for changing the map without a record; it is one
line, not a new entry.

## Verdict

**Revise.**

The fundamental shape is sound and serves every owner-settled item; nothing here reopens
the capability. The owner resolved the findings by accepting the ponytail challenge in
full (see Resolutions): the revised concept must follow the ponytail's smallest
architecture — a plain command, a builder contract that solely owns the output
invariants, file conventions instead of component operations, promotion as one paragraph,
and no standalone ADR candidates. The capability, boundaries, and offers all stand.
