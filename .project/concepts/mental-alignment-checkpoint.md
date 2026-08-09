# Concept: Mental Alignment Checkpoint

**Created:** 2026-08-09
**Status:** Draft

---

## Problem Statement

The workflow preserves product, architecture, scoping, and implementation decisions in durable
artifacts. For substantial work, that record expands across concepts, product designs,
concept-designs and their reviews, epics, item specs and designs, plans, ADRs, product-lens
ledgers, audits, and code. The owner cannot realistically read every artifact in full. Catching up
later means reconstructing one system from five to ten documents written at different levels and
times.

This creates a human-control gap. The pipeline has specialized agents that check product purpose,
architecture, or implementation, but it has no single surface that helps the owner recover the
whole mental model. The owner therefore loses the ability to spot product drift, reject
architectural slop, and notice small code-level issues before they magnify.

A summary of the artifacts alone would not close the gap. It could faithfully visualize a bad
premise that every upstream artifact shares. The checkpoint must put intended product behavior,
the proposed system, and relevant code reality into the same understandable context while keeping
its own interpretation visibly separate from source authority.

## Owner's Words

- **[OWNER-VERBATIM]** "The artifacts tend to get long and detailed, so in reality I am not going to be able to review each one."
- **[OWNER-VERBATIM]** "then yes actually putting the artifacts in context and understanding the whole system is the pain point."
- **[OWNER-VERBATIM]** "I would say \"mental alignment\"."
- **[OWNER-VERBATIM]** "Misalignment in what the product should be doing"
- **[OWNER-VERBATIM]** "Bad decisions on architecture; slop"
- **[OWNER-VERBATIM]** "Me losing a conceptual understanding of how the codebase works, meaning small issues can magnify to big ones because I cannot do reviews and spot checks"
- **[OWNER-VERBATIM]** "maybe it should only be done upon request. A sort of \"mental alignment checkpoint\" where the agent goes and builds this artifact to put whatever the question is in context of the whole system."
- **[OWNER-VERBATIM]** "Important: I expect this to evolve -- a lot of what \"good\" looks like is very particular."
- **[OWNER-VERBATIM]** "We may want to think through the feedback mechanism (agent is sitting in a particular project, but feedback needs to land in a shared location)"
- **[OWNER-VERBATIM]** "we also should not be that strict about the \"sources\" -- leave flexibility for the agent to construct the relevant context"
- **[OWNER-VERBATIM] [EXAMPLE]** "data models"
- **[OWNER-VERBATIM] [EXAMPLE]** "data flows"
- **[OWNER-VERBATIM] [EXAMPLE]** "mock-ups"
- **[OWNER-VERBATIM] [EXAMPLE]** "call out the major principles and design invariants"

## Success Criteria

When this work is complete:

1. **[OWNER] On-demand recovery** — The owner can ask a question about a project, epic, item,
   subsystem, or artifact and receive a committed HTML checkpoint under `.project/` that puts the
   question in its relevant system context.
2. **[OWNER] Two distinct layers** — Every checkpoint separates the explanatory mental model from agent
   concerns, uncertainties, and suggested spot checks. A concern cannot appear as settled system
   truth merely because it is rendered in the explainer.
3. **[AGENT] Grounded synthesis** — The checkpoint connects intended product behavior, relevant
   workflow artifacts, and current code or tests. It inspects code when explaining current
   behavior or evaluating claims about existing seams; otherwise it states that code was not
   inspected. Material disagreements are surfaced rather than silently reconciled.
4. **[OWNER] Question-led context** — The checkpoint agent may discover and select the context needed to
   answer the question. It records the material evidence it used and important limits without
   following a fixed source checklist.
5. **[AGENT] Reviewable decision points** — At concept-design, the HTML exposes the proposed system
   shape, responsibilities, and important invariants when relevant. At epic-plan, it exposes item
   boundaries, dependencies, and cross-item obligations when relevant. Each appears before the
   corresponding owner approval.
6. **[AGENT] Demonstrable comprehension** — On representative questions, the owner can use the
   checkpoint to identify intended product behavior, current and proposed system relationships,
   important ownership or invariants, and the highest-leverage tensions without first reading the
   full artifact chain. Evaluation measures comprehension, not adherence to one layout.
7. **[AGENT] (ratified by owner, 2026-08-09) Durable learning** — Each run can receive owner feedback in a fixed project-local file.
   Reusable lessons can be selected for explicit, reviewable promotion into the shared skill while
   project-specific preferences stay local.
8. **[AGENT] Safe committed output** — Generated HTML is safe to commit and open. It excludes
   secrets and credentials, unsafe active content, and undisclosed remote resources.
9. **[OWNER] No new ceremony** — No checkpoint is generated by default. Only concept-design and epic-plan
   actively suggest one; the owner may invoke it anywhere else without other stages advertising it.

---

## Why This Shape

- **Key bet:** **[OWNER]** A question-led, visual reconstruction of the relevant system will restore
  enough of the owner's mental model to make product, architecture, and code spot checks practical.
- **Why this shape is promising:** **[OWNER]** On-demand generation avoids adding another artifact
  to every pipeline run. A specialized subagent can spend the large context and HTML-generation
  budget without flooding the main agent's working context.
- **Constraint to preserve downstream:** **[AGENT] (ratified by owner, 2026-08-09)** The HTML is a
  committed contextual snapshot, not governing truth. It must preserve source authority,
  distinguish fact from agent judgment, and expose material uncertainty.

---

## User Stories

The following stories are **[AGENT]** synthesis of the owner-originated outcomes above.

### Recovering the system

**US-1: Catch up without reading the whole chain**
As the owner, I can ask how a feature or subsystem works and receive one visual explanation that
connects the relevant product intent, decisions, artifacts, and code, so I can re-enter the work
without reading five to ten documents first.

**US-2: Ask a focused system question**
As the owner, I can name the question I am trying to answer and let the agent construct the
relevant context, so the checkpoint explains the surrounding system without forcing every run
through the same template or source list.

### Exercising judgment

**US-3: Separate understanding from criticism**
As the owner, I can first understand the agent's model of the system and then inspect a separate
set of tensions and spot checks, so I can distinguish explanation from critique.

**US-4: Challenge architecture before acceptance**
As the owner reviewing a concept-design, I can see its boundaries, responsibilities, invariants,
important flows, relevant code reality, and unresolved review concerns together, so I can catch
slop before accepting the system shape.

**US-5: Challenge epic decomposition before approval**
As the owner reviewing an epic proposal, I can see how shaping intent maps into item boundaries,
dependencies, and cross-item proof obligations, so I can spot gaps or bad seams before approving
the decomposition.

### Improving the checkpoint

**US-6: Leave grounded feedback**
As the owner, I can record what a checkpoint clarified, obscured, or failed to answer beside the
run that produced it, so later work has concrete evidence about what good looks like.

**US-7: Promote only reusable lessons**
As the owner, I can deliberately promote a selected feedback lesson into the shared skill without
turning every project preference into a universal instruction.

---

## Key Concepts

### 1. Question-Led Checkpoint

The invocation starts with what the owner is trying to understand or review. A project, epic,
item, artifact, or subsystem may be provided as a starting point, but that starting point is a
seed rather than a hard boundary. The checkpoint agent follows the evidence and expands its scope
only as far as needed to answer the question. It builds the smallest useful model, states the
boundary it covered, and narrows the question or discloses partial coverage when the full scope
would recreate the artifact overload.

### 2. Flexible Context Construction

The agent uses judgment to select relevant project documentation, concepts, product designs,
reviews, epics, item artifacts, ADRs, code, tests, history, or other available evidence. Relevance
and the owner's question control the search. The artifact identifies material evidence and gaps;
it does not imply completeness by displaying a long mandatory source inventory. It links to
supporting depth instead of embedding it when the detail is not needed for orientation.

### 3. Two-Layer HTML

The first layer teaches the mental model. The second layer highlights product drift,
architectural slop, disagreements, uncertainty, and valuable spot checks. The agent chooses the
visual forms that fit the question. Data models, flows, mockups, principles, and invariants are
examples of useful representations, not required sections. A concise orientation comes before
optional supporting depth.

### 4. Committed Snapshot, Not Parallel Authority

Each committed HTML reflects the evidence available when it was generated. It is not maintained
as a second canonical model. Later runs regenerate from current evidence, and feedback stays
attributable to the version it reviewed. Important claims remain traceable, and owner-originated
decisions do not lose their provenance when compressed or visualized.

### 5. Local Feedback, Selective Promotion

Feedback stays attached to the project and checkpoint run where it was learned. It records the
question, what helped, what misled, what remained unclear, and whether the lesson appears local or
reusable. Promotion into the shared skill is a separate owner-visible act. Promotion preserves
the feedback's origin instead of silently converting an agent inference into a settled rule.

---

## Scope of Behavior Changes

### New artifacts and capabilities

- **[OWNER]** An on-demand mental-alignment capability whose main agent delegates HTML construction
  to a specialized subagent.
- **[OWNER]** Committed checkpoint HTML and feedback under `.project/`.
- **[AGENT] (ratified by owner, 2026-08-09)** A dedicated
  `.project/mental-alignment/runs/` location and `.project/mental-alignment/feedback.md` feedback
  ledger.
- **[AGENT] (ratified by owner, 2026-08-09)** An explicit path for selecting project feedback and
  promoting reusable lessons into the shared skill.
- **[INHERITED: docs/STRUCTURE.md]** Claude and Codex distributions must continue to derive from
  shared authored sources rather than hand-edited generated output.

### Existing artifacts to modify

- **[OWNER]** Concept-design actively offers the checkpoint at its review boundary.
- **[OWNER]** Epic-plan actively offers the checkpoint at its decomposition boundary.
- **[AGENT] (ratified by owner, 2026-08-09)** The exact offer points are after independent
  concept-design review but before owner resolution/final acceptance, and before owner approval of
  the proposed epic decomposition.
- **[AGENT] (ratified by owner, 2026-08-09)** Shaping-tier product design becomes discoverable to
  concept-design and epic-plan when relevant, correcting the current mismatch without making it a
  mandatory source. The mismatch is visible between the promised shaping flow in
  `claude-pack/commands/_my_product_design.md:137` and the discovery contracts in
  `claude-pack/commands/_my_concept_design.md:140` and `claude-pack/commands/_my_epic_plan.md:18`.
- **[AGENT]** Command catalogs, runtime distribution, and focused workflow checks change only as
  needed to expose and preserve the capability. Other pipeline stages do not gain checkpoint
  prompts.

### Behavior changes by workflow stage

- **Any time:** The owner may invoke a checkpoint with a question and optional starting context.
- **Concept-design:** Before final decisions harden, the stage offers to build a checkpoint from
  the question-relevant system, proposal, review, and code context.
- **Epic-plan:** Before decomposition approval, the stage offers to visualize the proposed item map
  in its shaping and system context.
- **Feedback:** After reviewing a run, the owner can record local feedback and later select a
  reusable lesson for shared promotion.

---

## Non-Goals / Out of Scope

- **[OWNER]** Default or automatic generation across the pipeline is out of scope because the
  checkpoint is an owner-requested mental-alignment tool.
- **[OWNER]** A mandatory catalog of visuals is out of scope; the named representations are
  illustrative examples.
- **[OWNER]** A strict source allowlist is out of scope; the agent constructs the relevant context
  for the question.
- **[AGENT]** Replacing concept-design review, product-lens checks, design review, or audit is out of
  scope because the checkpoint serves owner comprehension rather than certification.
- **[AGENT]** A continuously synchronized living explainer is deferred; committed runs are
  point-in-time snapshots so they do not become a parallel model that must stay current.
- **[AGENT]** A general-purpose continual-learning framework for every skill is deferred; this work
  owns only the feedback and promotion behavior needed to evolve this checkpoint.
- **[AGENT]** Project status dashboards are separate; this surface explains system meaning rather
  than backlog or phase status.

---

## Assumptions & Prerequisites

- `.project/` is tracked and can hold committed HTML and feedback records.
- The subagent can inspect the files and code needed for the question and write within the project.
- The shared pack remains the authored home for cross-project behavior; runtime-specific generated
  copies are refreshed from it.
- A checkpoint may be useful even when it finds incomplete or conflicting context, provided the
  limitation is visible rather than filled with invented certainty.

## Open Questions

1. What command and skill name should expose the checkpoint?
2. What minimum run metadata makes a committed HTML snapshot traceable without turning the output
   into a rigid report template?
3. How should feedback entries be selected and promoted when the shared pack source is unavailable,
   vendored, or installed differently between Claude and Codex?
4. Should regeneration create a new linked file or update a stable path while retaining versioned
   evidence and feedback attribution?
5. What representative fixtures will test product misalignment, architectural slop, flexible
   context discovery, and visual comprehension without reducing quality to one preferred layout?

---

## Next-Stage Handoff

**Settled here:**

- **[OWNER]** The output medium is HTML.
- **[OWNER]** The checkpoint is on demand. The main agent delegates construction to a specialized
  subagent, which writes the HTML directly and returns a compact summary.
- **[OWNER]** The HTML has a mental-model layer and a separate tensions/spot-checks layer.
- **[OWNER]** Visual forms are selected to fit the question; the examples do not define a required
  template.
- **[OWNER]** Only concept-design and epic-plan actively suggest the checkpoint.
- **[OWNER]** HTML runs and feedback are committed beneath `.project/`.
- **[OWNER]** Context construction stays flexible rather than following a strict source list.
- **[OWNER]** Project-local feedback is part of the initial scope.

**Ratified agent recommendation:**

- **[AGENT] (ratified by owner, 2026-08-09)** Reusable feedback is promoted selectively through an
  explicit, reviewable path rather than flowing automatically into the shared skill.

**Needs spec next:**

- Define the invocation, output, run-history, feedback, and promotion behaviors precisely.
- Define how source authority, agent judgment, uncertainty, and snapshot age remain legible in HTML.
- Define the two suggestion interactions without making the checkpoint automatic.
- Define cross-runtime availability and how shared promotion behaves when source access differs.
- Define observable quality fixtures and acceptance checks for a medium whose best form depends on
  the question.

**Decomposition guidance:**

- This likely warrants an epic because the core checkpoint, project-local learning loop, workflow
  touch points, shared promotion, and Claude/Codex distribution can be verified independently.
- Keep the first usable slice narrow: one on-demand checkpoint, committed output, and grounded
  feedback on real concept-design and epic-plan examples before generalizing the visual repertoire.
