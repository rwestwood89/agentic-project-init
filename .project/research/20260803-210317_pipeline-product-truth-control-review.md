---
date: 2026-08-03T21:03:17-07:00
researcher: Codex
topic: "Why the artifact pipeline can certify work that violates the product's purpose"
tags: [research, pipeline, product-invariants, semantic-assurance, audit, agent-workflow]
status: complete
last_updated: 2026-08-03
---

# Research: Why the Pipeline Can Certify the Wrong Product

**Date:** 2026-08-03 (PDT)
**Researcher:** Codex
**Research Type:** Workflow / artifact authority / semantic assurance

## Research Question

Why did a long agent pipeline containing research, design, design review, implementation,
tests, audits, and PR review fail to stop when the code contradicted the central purpose of
the product? What must change in the pipeline so a local explanation, green test, or inherited
workaround cannot silently replace the product contract?

The owner supplied two forensic reports as the evidentiary referents for this review:

- **[REFERENT]** `/home/reid/1cfe/sysml-codegen/.project/research/20260803-202453_backtracking-fanout-forensics.md`
- **[REFERENT]** `/home/reid/1cfe/sysml-codegen/.project/research/20260803-203011_entry-surface-fanout-forensics.md`

## Executive Verdict

- **[AGENT] The pipeline preserves artifact lineage better than product truth.** It can tell
  a later agent what an earlier artifact said. It does not keep the product's governing
  invariant authoritative when a local spec, mechanism taxonomy, fixture, or green test
  contradicts it.
- **[AGENT] The fan-out defect was institutionalized as the test oracle.** The repository
  observed the contradiction, reclassified it, encoded the reclassification in tests, and
  certified the resulting internally consistent story. This is stronger than a missing-test
  diagnosis; it is wrong-oracle institutionalization
  (`20260803-202453_backtracking-fanout-forensics.md:58-75`).
- **[AGENT] The current controls mostly check fidelity to the inherited frame.** Fresh
  sessions, provenance tags, durable decisions, and more review stages do not create an
  independent oracle. They make a bad frame easier to transmit and audit.
- **[AGENT] Several current instructions actively help normalize bugs.** One command says
  that when a design concept and code disagree, “the document is wrong, not the code” and
  must be patched to reality (`claude-pack/commands/_my_concept_design.md:395-408`). Another
  rule discourages re-research once behavior is documented
  (`claude-pack/rules/context-loading.md:15-20`).
- **[AGENT] The repair is not another stage.** The pipeline needs a small governing product
  contract, direct invariant-to-proof traceability, a durable blocked state for contradictory
  evidence, and review evidence derived independently from primary product meaning.

## What Actually Failed

### 1. The product purpose never became the controlling oracle

The second RCA identifies the gap precisely. “One modeled source produces one public input”
was the library's constitutive purpose, but it was never made a checkable requirement for the
failing calculation path. A mechanism-specific fallback requirement controlled instead, so a
large verification matrix passed while the first customer sweep violated the product's point
(`20260803-203011_entry-surface-fanout-forensics.md:30-38,199-208`).

The pipeline has several places for goals and invariants, but no stable product-invariant ID
must survive from shaping into proof:

```text
owner purpose
  -> concept success criterion
  -> spec outcome
  -> design invariant
  -> plan test oracle
  -> implementation evidence
  -> audit certification
```

Each arrow is currently a prose translation. No downstream stage must prove that the claim at
the right still means the claim at the left.

### 2. The strongest goal-bearing fields bypass provenance

Capture Fidelity grades Owner's Words, Non-Goals, requirements, and settled lists. The
concept's Success Criteria, “Constraint to preserve downstream,” and assumptions remain
ungraded (`claude-pack/commands/_my_concept.md:132-155,191-216`). The Capture Fidelity
implementation explicitly accepted ungraded Success Criteria because its design scoped
concept grading to Settled and Non-Goals
(`.project/active/capture-fidelity/plan.md:257-263`).

Those ungraded criteria then become primary input to the spec
(`claude-pack/commands/_my_spec.md:27-30`), remain untagged in the spec
(`claude-pack/commands/_my_spec.md:82-90`), and become mandatory design objectives
(`claude-pack/commands/_my_design.md:70-73`). An agent-created local objective can therefore
become the strongest downstream contract while every existing provenance check passes.

Provenance also answers the wrong question by itself. “Who said this?” does not answer:

- Is this a normative product requirement or an observation of current behavior?
- Was the behavior directly exercised, inferred from code, or carried from another artifact?
- What exact claim does the evidence prove, and over what scope?

### 3. Current behavior is treated as truth when it should be evidence

The clearest example is in concept design. The command requires code verification on every
self-review iteration. When the design and code disagree, it says the document is wrong, not
the code, and instructs the agent to patch the document to match current behavior
(`claude-pack/commands/_my_concept_design.md:395-408`).

That instruction cannot distinguish three materially different cases:

1. the document is stale;
2. the implementation is defective;
3. the product contract intentionally changed.

It resolves all three as case 1. In this incident, that is the exact wrong move.

The same command says that when a cited document answers a question, the agent must not
re-derive the answer from code (`_my_concept_design.md:127-138`). The context-loading rule
similarly says not to re-research documented behavior (`context-loading.md:15-20`). Those are
reasonable cost controls for stable mechanics. Applied to surprising claims or workarounds
that contradict a platform promise, they become epistemic deference rules.

### 4. Research can launder a workaround into established fact

Research artifacts are stamped `status: complete`. Findings and recommendations require
citations, but individual claims carry no evidence status or provenance grade
(`claude-pack/commands/_my_research.md:46-104,124-128`). Later sessions are told to reuse
research rather than repeat it.

The July 25 research followed this path. It observed the exact shared-source fan-out, named
the inconsistent sweep hazard, and recommended a consumer-side expansion workaround. The next
agent inherited “known hazard + prescribed workaround” instead of “platform contract failure”
(`20260803-202453_backtracking-fanout-forensics.md:337-348`).

This is not fixed by citing the research accurately. The research framing itself was wrong.

### 5. Mechanism names replaced modeled meaning

The design separated virtual-binding rewrite behavior from source-qualified-name convergence.
Once those categories existed, agents asked which mechanism owned the case instead of whether
two consumers originated from one modeled source. The tests could then prove both convergence
and fan-out because each assertion was scoped to a different route
(`20260803-202453_backtracking-fanout-forensics.md:221-289`).

The implementation encountered the contradiction directly. The spec required collapse to one
key and escalation of a mechanism gap. The plan found duplicate keys, reclassified the source as
“not cross-part fan-out,” perturbed only one duplicate, and continued. The audit checked the
selected duplicate's arithmetic rather than the contradicted topology
(`20260803-202453_backtracking-fanout-forensics.md:291-320`).

The local mechanism story was coherent. The product story was false.

### 6. Green tests became a stronger oracle than the source model

Five focused tests simultaneously proved the intended invariant and its opposite. Each test was
real. The suite was green because the tests covered separate mechanism routes and used their
current output as expected behavior (`20260803-202453_backtracking-fanout-forensics.md:241-289`).

The plan command intensifies this risk:

- it says “Tests define success criteria” (`claude-pack/commands/_my_plan.md:294-298`);
- its existing-code example starts by pinning current behavior before changing it
  (`_my_plan.md:373-383`);
- its standard proof is local test + full-suite green
  (`_my_plan.md:147-204`).

Tests should be evidence for a product contract. Here they became the contract.

The refactor reviews had the same problem. Byte identity and old/new parity proved faithful
preservation of existing output. Since the defect predated the refactors, those gates embalmed it
(`20260803-203011_entry-surface-fanout-forensics.md:45-51,209-216`). A preservation test can
prove stability. It cannot prove correctness.

### 7. Reviews are fresh, but their oracle is inherited

Spec review is the strongest existing independent gate. It reads dependencies, checks code-facing
claims, and can stop at a failed reality check
(`claude-pack/commands/_my_spec_review.md:130-146`). But it is only independent inside the frame it
was given. If the governing source was omitted or the research already normalized the behavior,
the review receives the same wrong premise.

Design review is narrower. Its mandatory inputs are the design, spec, and current code
(`claude-pack/commands/_my_design_review.md:35-42`). It does not have to derive expected behavior
from the primary product model before reading the author's rationale. A fresh session removes
shared chat context; it does not remove documentary anchoring.

The autonomous orchestrator makes this more pronounced. It sends each stage an
orchestrator-selected slice of “relevant intent,” then works mainly from the stage's final summary
(`claude-pack/commands/_my_orchestrate.md:57-77`; `claude-pack/scripts/orchestrate-stage.sh:67-77`).
The stage does not necessarily receive the governing concept or primary referent directly.

### 8. Work-item audit certifies the narrowed chain

Work-item audit reads plan, spec, design, and the parent epic. It checks the implementation against
those local artifacts (`claude-pack/commands/_my_audit.md:23-44`). It does not require the item's
Required Reading or original shaping sources.

Only epic audit returns to Source Documents, and it does so after trusting the item audits rather
than re-auditing their code (`_my_audit.md:122-141`). This creates a closed laundering loop:

```text
narrowed spec -> coherent design -> matching implementation -> green local tests
       -> item Certify -> epic sees certified items -> shaping-intent summary check
```

The Epic Guide claims that audit reads Required Reading
(`project-pack/EPIC_GUIDE.md:60-68`). The audit command does not implement that promise. The
plan and implement commands do not read Required Reading either.

### 9. Workarounds have a sanctioned promotion path

The close command scans implementation notes for workarounds and presents them as candidate
decision records (`claude-pack/commands/_my_close.md:23-46`). The ADR convention says a consumer
workaround should produce a ruling in the repo that must uphold it
(`project-pack/adr/README.md:72-79`).

That is useful only after the observation is classified. There is no mandatory first question:
does the workaround manually maintain an invariant the upstream platform already promises?

Without that question, a platform bug can become a durable active decision. The July workaround
never even reached close; it was normalized earlier in research. Close-time capture is therefore a
backup control, not a discovery control.

### 10. The existing stop rule is behaviorally invisible

Capture Fidelity law 4 already says not to resolve a product-goal or premise conflict silently
(`claude-pack/rules/capture-fidelity.md:56-61`). Its own design and review explicitly concede the
problem: omitted surfacing leaves no artifact, so no reviewer can detect it
(`.project/active/capture-fidelity/design.md:68-73`;
`.project/active/capture-fidelity/design-review.md:111-119,150-154`).

The audit certified the presence of the prompt devices, not future compliance, and listed their
behavioral efficacy as unverified (`.project/active/capture-fidelity/audit.md:42-45,104-110`).

The rule has correct stop semantics. It lacks a state transition that downstream stages must see.

## Pipeline Review by Control Type

| Control | What it proves today | What it does not prove |
|---|---|---|
| Provenance tags | Who originated selected decision-carrying statements | Whether a behavior claim is true; whether ungraded success criteria preserve owner intent |
| Required Reading | Some upstream paths remain discoverable | That every stage reads them; that their framing is correct |
| Fresh reviews | Reviewer lacks the author's conversational context | Reviewer has an independent product oracle |
| Design invariants | The design states local rules it intends to preserve | The rules are the governing product invariants or span all routes |
| Test-first planning | A test exists before each implementation slice | The test oracle comes from product meaning rather than current output |
| Full-suite green | Current expected behavior remains internally consistent | The behavior is semantically correct |
| Byte parity | A refactor preserved output | The preserved output was correct |
| Item audit | Code matches the local artifact chain | The local chain still matches the product purpose |
| Epic audit | Certified items appear to add up to shaping intent | Each item's code satisfies the original invariant |
| ADRs | Decisions and reasoning survive sessions | A workaround was classified as a defect before becoming policy |
| “Not checked” | Certification scope is stated | Claims are prevented from expanding beyond the tested scope later |

## Controls Already Worth Keeping

The pipeline does not need to be thrown away. Several pieces have the correct shape:

- Capture Fidelity's owner-originated/ratified distinction and premise-conflict stop
  (`capture-fidelity.md:26-34,56-61`).
- Spec review's reality-check short circuit (`_my_spec_review.md:130-146`).
- Concept design's boundary invariants, route-equivalence questions, System Confidence, and proof
  obligations (`_my_concept_design.md:284-344,524-527`).
- The template Epic Guide's functional slices, composition ownership, and deliberate combination
  coverage (`project-pack/EPIC_GUIDE.md:86-108,197-207,231-238,409-414`).
- Implementation's stop-on-significant-deviation behavior (`_my_implement.md:64-82,217-221`).
- Audit scope honesty (`_my_audit.md:102-113`).
- ADR reasoning, provenance, seams, and supersession (`project-pack/adr/README.md:31-69`).

These mechanisms are currently disconnected. The solution should make them one controlling chain.

## High-Level Solution Proposal

### A. Establish a governing product contract

**[AGENT]** Each repository should define a small core set of product-level invariants in semantic
language. Every substantial effort inherits that set automatically, then may add item-specific
invariants or prove a core invariant inapplicable. It does not select the core set from scratch.

Each governing invariant needs:

- a stable identifier;
- owner-originated or `[HARD]` authority;
- the primary source or referent;
- explicit supported scope;
- one observable falsifier that preserves every seam and topology condition the invariant names.

Use the existing append-only ADR mechanism for durable invariant decisions, then let an epic or
standalone item reference the applicable IDs. This avoids a new maintained current-state architecture
document, preserving ADR 0001's owner decision against one
(`.project/adr/0001-decision-records-convention.md:15-38`).

### B. Make invariants proof obligations across every hop

**[AGENT]** Every applicable invariant should have a direct trace:

| Stage | Required contribution |
|---|---|
| Epic/item | Names the governing invariant IDs and owns composition where needed |
| Spec | States the observable outcome without narrowing the invariant |
| Design | Names boundary obligations and routes that must be equivalent |
| Plan | Defines an independent semantic test, not only a baseline test |
| Implement | Records the evidence and any conflicting observation |
| Review | Derives the expected result from the invariant before reading the author's explanation |
| Audit | Re-runs or inspects the semantic proof and limits certification to its exercised scope |

A stage may declare an invariant not applicable. It may not silently redefine it. Narrowing or
superseding an owner-grade invariant requires an explicit owner-visible amendment. Local mechanism
documents, current code, baselines, and inherited research cannot establish non-applicability.

Every stage should emit a revision-bound contract check containing the expected observation, named
falsifier and result, evidence type and path, and `PASS` / `FAIL` / `NOT CHECKED`. `PASS` must be
evaluator-owned or mechanically derived rather than author self-attestation.

### C. Turn premise conflict into a durable blocked state

**[AGENT]** Replace “remember to surface surprise” with a visible state transition. When current
code, a test, an artifact, or a customer-shaped fixture contradicts a governing invariant, the stage
creates a conflict record and parks dependent conclusions.

The allowed dispositions are:

1. implementation defect;
2. stale or incorrect artifact;
3. intended contract change;
4. invalid input/model outside supported scope.

The agent can gather evidence. It cannot silently choose a disposition that narrows owner-grade
intent. An unresolved applicable conflict must block merge, pre-PR success, close, ADR or policy
promotion, and every product-semantic certification claim. Only isolated diagnostic work may continue.

### D. Make workaround discovery an upstream defect trigger

**[AGENT]** If a consumer-side workaround manually maintains an invariant the source or platform
already declares, it is presumptive evidence of an upstream defect. File the defect when discovered,
including during research. Do not wait for close.

A temporary mitigation can still be chosen. It must link to the surfaced defect, state its limited
life and risk, and remain visibly a mitigation. Its outputs remain tainted and cannot become semantic
evidence until the conflict is resolved. It cannot be recorded as the normal product contract unless
the owner explicitly changes that contract.

### E. Separate semantic evidence from preservation evidence

**[AGENT]** Tests and certifications should name what kind of claim they support:

- **semantic proof:** behavior follows the product/source model;
- **preservation proof:** output is unchanged from a prior implementation;
- **mechanism proof:** one internal route behaves as designed;
- **composition proof:** routes and consumers agree end to end.

Snapshots, byte identity, and old/new parity are preservation evidence only. A broad semantic claim
requires a customer-shaped test, an off-default mutation, and deliberate coverage of the relevant
combination dimensions. A local route test supports only that route.

### F. Make review oracle-first and certification claim-scoped

**[AGENT]** A separate blind review phase should receive only the governing invariant and its primary
source, then persist the expected behavior before author artifacts, test expectations, summaries, or
inherited research framing are exposed. This prevents the author's mechanism vocabulary from defining
the question.

Audit should separately report:

1. artifact/process conformance;
2. implementation conformance;
3. product-semantic claims, their evidence, and exercised scope.

“Certify” should never allow an unexercised prompt device, a green local theorem, or a byte-identical
baseline to read as universal semantic assurance.

## Alternatives Considered

### Add another review stage

**[AGENT] Rejected as the primary solution.** Every downstream stage already encountered enough
evidence to stop. Another reviewer reading the same narrowed artifacts inherits the same oracle. The
RCA reaches the same conclusion (`20260803-202453_backtracking-fanout-forensics.md:467-468`).

### Add only a new always-on “workaround smell” rule

**[AGENT] Insufficient alone.** The existing surfacing law already states the desired behavior, and
its omission is invisible. A sharper rule is useful only when paired with a durable conflict state and
downstream gates.

### Make the full concept mandatory reading everywhere

**[AGENT] Insufficient alone.** This improves salience but not authority or verification. A long
concept can still be summarized incorrectly, and later agents can still rationalize current behavior.
Stable invariant IDs and direct proofs carry less noise and more force.

### Trust stronger models or more agents

**[AGENT] Rejected.** The failure was not lack of reasoning capacity. Agents identified the exact
fan-out and then normalized it. More intelligence inside the same inherited frame increases the
quality of the rationalization, not the independence of the oracle.

## Additional Pipeline Integrity Findings

- The stronger system-confidence slicing rules exist in `project-pack/EPIC_GUIDE.md`, but this
  repo's live `.project/EPIC_GUIDE.md` is stale and lacks them. `_my_epic_plan` reads the live copy.
  Controls added to templates are therefore not automatically controlling in already-initialized
  projects.
- The autonomous orchestrator design named judgment quality as its central bet and said end-to-end
  dogfood was the real test (`.project/active/workflow-orchestrator/design.md:75-88,255-264`). The
  plan's single-item and epic dogfoods remain unchecked
  (`.project/active/workflow-orchestrator/plan.md:158-194`), while CURRENT_WORK says the orchestrator
  merged and drives the pipeline (`.project/CURRENT_WORK.md:45-47`).
- Capture Fidelity Refinements remains a Draft with unchecked success criteria while CURRENT_WORK
  says it was implemented. This is another example of status claims outpacing their evidence
  (`.project/active/capture-fidelity-refinements/spec.md:3,37-58`;
  `.project/CURRENT_WORK.md:21-24`).

## Feasibility Assessment

**[AGENT] Feasible without replacing the pipeline.** The repository already has most primitives:
ADRs for stable decisions, Required Reading, proof obligations, fresh reviews, stop-on-deviation,
scoped audits, and spikes/learning tests. The work is to connect them and change their authority
rules.

This is cross-cutting and cannot be a quick edit. It will touch shaping, research, epic planning,
spec/design review, planning, implementation, audit, pre-PR/close, orchestration, templates, and
pipeline-level regression fixtures. It should be decomposed into an epic after the concept is
approved.

## Recommendations

1. Use the accompanying concept as the owner-reviewable problem and proposal shape.
2. Before implementation, run a design concept focused on the governing-contract representation,
   conflict lifecycle, and claim-scoped audit model.
3. Build one adversarial pipeline fixture before changing prompts: one shared SysML attribute fans out
   to multiple consumers, local code and tests are green, prior research labels the violation a known
   hazard, and entry-key expansion is proposed. The expected result is a surfaced conflict that blocks
   semantic certification and shipping gates.
4. Treat current process certifications narrowly until the live behavioral gates have been
   exercised. Do not infer agent judgment quality from prompt presence or artifact coherence.

## Open Questions

1. Should governing invariant entries be a subtype/field within the existing ADR convention, or a
   separate append-only contract artifact that references ADRs?
2. What is the minimum conflict record that is durable without creating a new bureaucracy?
3. Which stages must block mechanically on an unresolved conflict: plan, implement, pre-PR, close,
   or all four?
4. For standalone items without an epic, where is the governing contract selection recorded?
5. How should existing projects receive updated pipeline templates so a strong control in
   `project-pack/` cannot remain absent from their live `.project/` copy?
6. Which current audit verdicts should be renamed or split to distinguish device presence,
   implementation conformance, and exercised semantic behavior?

## Evidence Scope

This review read both owner-supplied RCA files in full; the current pipeline stage commands from
shaping through close; orchestration and handoff mechanics; Capture Fidelity, Capture Fidelity
Refinements, Audit Certification, Decision Records, workflow-orchestrator artifacts; both live and
template Epic Guides; current decision records; and the prior artifact-pipeline alignment research.

No application code was changed. This document is a pipeline diagnosis and high-level proposal, not
a certification that the proposal works.
