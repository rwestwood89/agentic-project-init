# Design: Mental Alignment Checkpoint

**Status:** Proposed after review
**Owner:** Project owner
**Created:** 2026-08-09
**Source:** `.project/concepts/mental-alignment-checkpoint.md`
**Review:** `.project/concepts/mental-alignment-checkpoint-design-review.md`

## Overview

The mental-alignment checkpoint is an on-demand, visual explanation built around an owner's question. It reconnects product intent, proposed structure, and relevant code reality without asking the owner to reread the full artifact chain.

Each checkpoint produces a mental model first, then visibly separate tensions and spot checks. It helps the owner judge the work without becoming governing truth.

## Problem

The workflow preserves product, architecture, planning, and implementation decisions in detailed artifacts. Those artifacts serve fidelity and auditability, but their combined volume makes it unrealistic for the owner to maintain a current understanding of a substantial system.

No owner-facing surface currently rebuilds that understanding around a concrete question. A summary of the artifact chain would still inherit any premise the chain got wrong. Product drift, weak architecture, and small implementation problems can therefore escape human spot checks and grow.

The missing capability is explanation for human judgment, not another evaluator or shorter governing artifacts. It must connect intent, proposal, and reality while keeping its own interpretation visibly subordinate to the evidence.

## Goals

- Let the owner recover a useful system mental model from a focused question.
- Separate explanation from concerns, uncertainty, and suggested spot checks.
- Connect intended behavior, proposed structure, and relevant current behavior when the question needs them.
- Preserve the authority, force, and provenance of the evidence being explained.
- Keep generation optional while offering it at the two owner-facing approval boundaries.
- Support local feedback and deliberate promotion of reusable lessons.

## Non-Goals

- Generate checkpoints automatically or during headless orchestration.
- Require fixed visuals or a fixed source checklist.
- Replace reviews, audits, product checks, research, or their governing artifacts.
- Maintain a living explainer or project-status dashboard.
- Build a general learning system for other workflow skills.

## Design Principles

### 1. The Question Controls the Context

The explanation follows the owner's question, using the smallest body of evidence that explains the surrounding system and stating important gaps. Broad questions are narrowed or answered with an explicit coverage boundary instead of recreating the artifact chain.

### 2. Understanding Comes Before Critique

The first layer teaches the mental model. Concerns and spot checks stay in a visibly separate layer so agent judgment cannot masquerade as system truth.

### 3. A Snapshot Explains; It Does Not Govern

Claims remain attributable to their evidence and moment in time. A checkpoint may expose a conflict, but it cannot settle one, alter its sources, or outrank them.

### 4. Keep Each Promise Whole

Safety, traceability, and completeness form one promise about the explanation. Splitting that promise across stages makes failure ownership ambiguous.

### 5. Learning Requires an Explicit Choice

Feedback stays local by default. A reusable lesson changes shared behavior only through an explicit, owner-visible choice.

## Architectural Bets

- **[OWNER]** Add a separate comprehension surface rather than compress the governing artifacts; the two outputs serve different readers and jobs.
- **[AGENT] (ratified by owner, 2026-08-09)** Reuse the pack's existing command-to-one-job-subagent pattern. Do not introduce a coordinator component, custom agent protocol, or new runtime.
- **[AGENT] (ratified by owner, 2026-08-09)** Keep dated runs and their feedback together under one dedicated project-local convention so attribution does not split across homes.
- **[AGENT] (ratified by owner, 2026-08-09)** Keep feedback local and make promotion an explicit source edit. Do not add automatic learning, scoring, or synchronization.

## ADR Candidates

None — no decision crosses the ADR density bar. The checkpoint is not a mandatory ADR-reading stage, the command/subagent split is an existing pack pattern, and authored-source ownership already belongs to repository structure documentation.

## Core Model

*The register shifts here. The concepts below map the intended design to current pack patterns.*

### Shared Checkpoint Command

An intended shared command accepts the question and optional starting context, starts a `general-purpose` subagent with the complete builder contract, and relays the returned path and compact summary. It does not author or validate HTML, record feedback as part of generation, resolve source conflicts, or promote lessons.

The current pack already turns shared command sources into Claude commands and Codex skills. Product-lens call sites already use the same direct delegation pattern.

### HTML Builder Contract

An intended instruction document in the shared scripts owns one job: discover relevant context and produce one safe, traceable, two-layer checkpoint report or report failure. It chooses the visual form, reuses relevant `.project/research/` findings, verifies current-behavior claims against code when needed, and returns little.

It does not edit evidence, feedback, decision records, or shared instructions. No caller duplicates its output guarantees.

### Project File Conventions

Intended runs live as new files under `.project/mental-alignment/runs/`; feedback lives at `.project/mental-alignment/feedback.md` and names the run it evaluates. These are file conventions, not a component or service. Nothing current is relocated because the capability does not exist yet.

### Interactive Stage Offers

Concept-design review offers a checkpoint after presenting findings and before owner resolution. Epic planning offers one after presenting decomposition and before owner approval. When the existing `NON-INTERACTIVE` stage marker is present, the offer is suppressed; the stage neither stops nor lets an orchestrator decide for the owner. Declining an interactive offer changes nothing.

## Diagram

```text
owner question or interactive offer
              |
              v
       shared command -> builder contract -> new HTML report
                                             |
owner feedback ------------------------------+-> local feedback entry
                                                    |
explicit promotion request -> reachable authored source, or stop locally
```

## Prior Art

- **Concept: Mental Alignment Checkpoint** supplies the owner-settled purpose, medium, delegation, two layers, flexible context, and optional boundaries.
- **ADR-0001** distinguishes durable decisions from ordinary `.project/` working evidence. Reports and feedback remain working evidence.
- **ADR-0002**, as amended by **ADR-0005**, records enforced ADR touch points. Flexible checkpoint discovery is not a new mandatory read and therefore does not amend that map.
- **ADR-0006** supplies the narrow read-without-writing precedent: concept-design review may consult relevant decisions but cannot file or alter them. The checkpoint follows that boundary without becoming a review stage.
- **Product-lens** (`claude-pack/scripts/product-lens.md`) supplies the direct command-to-one-job-subagent precedent; **Research** (`claude-pack/commands/_my_research.md`) supplies reusable investigations; **Repository Structure** (`docs/STRUCTURE.md`) owns authored versus generated distribution; **Reports** (`project-pack/reports/README.md`) confirms that generated snapshots are working evidence rather than governing truth.

The ADR index was checked in full: 7 entries, 5 live and 2 superseded. No live entry is contradicted or proposed for supersession.

## Required Invariants

### Invocation and Route Boundaries

- **Current:** No checkpoint command, builder, report convention, feedback path, or stage offer exists.
- **Intended:** Generation follows direct owner invocation or owner acceptance of an interactive stage offer.
- **Intended:** Direct invocation and both offers reach the same shared command and builder contract.
- **Intended:** A stage carrying the existing `NON-INTERACTIVE` marker suppresses its offer without stopping or delegating the choice; headless orchestration never generates a checkpoint on the owner's behalf.
- **Intended:** Concept-design and epic-plan discovery include an existing shaping product-design sibling among candidate inputs without making it mandatory; this is a small rider repair at those discovery owners.

### Builder Output Contract

- **Intended:** The builder writes exactly one new report on success and never overwrites an earlier report.
- **Intended:** A report records its question, time, scope, material evidence, limits, and whether code was inspected.
- **Intended:** A report separates explanation from concerns and labels current, intended, and proposed behavior when they coexist.
- **Intended:** Claims preserve source provenance and force; disagreements remain visible and dependent conclusions stay parked.
- **Intended:** Successful HTML contains only static HTML/CSS and inert inline visuals. Scripts, event handlers, forms, embedded active content, and remote URLs cause failure.
- **Intended:** Evidence values are summarized rather than copied. Credential-like assignments, tokens, and private-key material are redacted; an unredacted match in the output causes failure.
- **Intended:** The builder returns either the path, coverage boundary, material limits, and concerns without restating the report, or failure. The command relays that result without a second output check.

### Evidence, Feedback, and Promotion

- **Current:** Research can hold reusable investigations, `.project/reports/` holds generated snapshots, and shared authored sources feed both runtime distributions.
- **Intended:** When discovered research covers a claim within the report's stated scope, the builder cites it instead of repeating it and rechecks only current-behavior claims the answer depends on.
- **Intended:** Feedback names its report and cannot change shared behavior merely because it was recorded.
- **Intended:** Promotion requires a reachable authored pack root resolved from the current authored repository or installation source metadata; otherwise it stops locally.
- **Intended:** Generated, installed, and vendored copies are evidence, not promotion targets. If authored source is unavailable, the lesson remains local and promotion stops.
- **Intended:** The checkpoint may read relevant live decisions but cannot file, amend, supersede, or resolve them.

## How It Works

### Direct Checkpoint

Today the owner reconstructs the system from existing evidence or asks for an agent-facing research report. In the proposed flow, the shared command hands the owner's question to the builder. The builder reuses existing research, follows other relevant evidence, writes one owner-facing report, and returns its result. Research remains the durable investigation route; the checkpoint explains that evidence for human judgment.

### Interactive Review-Boundary Offer

Today concept-design review and epic planning proceed from presentation to owner action. Each proposed interactive flow adds one optional offer at its chosen boundary. Acceptance routes to the direct flow; refusal resumes the stage. A `NON-INTERACTIVE` stage suppresses the offer and continues, so neither Claude nor Codex orchestration answers for the owner. The shaping product-design discovery mismatch is repaired in the two stage inputs as a rider, not an epic item.

### Feedback and Promotion

Today no checkpoint-specific learning path exists. On request, the main agent appends feedback that cites a report. A later explicit promotion request proposes a focused change to reachable shared checkpoint instructions for owner review. If it cannot resolve authored source, it records the candidate locally and stops.

## Edge Cases and Failure Modes

- A question is too broad: narrow it or mark partial coverage instead of recreating the artifact chain.
- Sources disagree: show the conflict and park dependent conclusions.
- Current behavior matters but code cannot be inspected: state the limit instead of inferring fact.
- Existing research is relevant but stale: cite it, then verify only the current claims the answer depends on.
- `.project/` is ignored or the report cannot be committed: report failure rather than claim a committed run.
- The builder cannot meet the safety or two-layer contract: return failure; the command must not relabel it as success.
- A report is stale: its metadata exposes the date and scope; regeneration creates a new report.
- Shared authored instructions are unavailable: keep the candidate lesson local and stop promotion.
- The command name could be confused with orchestration's existing launch-time Align checkpoint: choose a distinct public name at spec time.

## Vocabulary

- `checkpoint`: one owner-facing reconstruction of a system around a question.
- `run`: one dated HTML checkpoint report.
- `builder contract`: the complete one-job instructions given to the HTML-writing subagent.
- `research record`: an agent-facing investigation that a checkpoint may cite instead of re-deriving.
- `stage offer`: an optional prompt shown only by an interactive stage at its owner approval boundary.
- `promotion`: an owner-reviewed transfer of a reusable local lesson into reachable shared authored instructions.

## System Confidence

Every entry route must pass the same question and builder contract, and the builder must be the sole owner of success or failure. Interactive Claude and Codex routes must agree, while headless routes must agree that no offer occurs. Reports must preserve the same authority boundaries whether they start from live code, existing research, or workflow artifacts.

No component check proves that a report restores owner comprehension or exposes known product and architecture problems. Nor can one runtime's tests prove Claude/Codex equivalence, a report fixture prove that real secrets never leak, or an available-source promotion test prove fail-closed behavior in vendored and generated installs. Those are epic-owned proof obligations.

## Validation Strategy

- Exercise direct invocation and both interactive offers; verify equivalent builder input and result shape, and verify no headless offer.
- Evaluate representative concept-design and epic-plan questions containing known product and architecture tensions.
- Inspect reports for traceability, layer separation, static local HTML, accessibility basics, and seeded unsafe or secret content.
- Verify existing research is cited and only question-relevant current claims are rechecked.
- Build both runtime distributions and verify the same command and builder contract are reachable.
- Exercise promotion with authored source available, generated or vendored copies visible, and authored source unavailable.

## Next-Stage Handoff

**Settled here from owner-originated source:**

- **[OWNER]** The checkpoint is on demand, question-led, and rendered as HTML.
- **[OWNER]** The main agent delegates construction to a specialized subagent and receives a compact result.
- **[OWNER]** Every report has a mental-model layer and a separate tensions/spot-checks layer.
- **[OWNER]** Context construction stays flexible, and only concept-design review and epic planning actively offer the capability.
- **[OWNER]** Reports and feedback are committed beneath `.project/`; feedback stays project-local by default.

**Ratified or derived design choices:**

- **[AGENT] (ratified by owner, 2026-08-09)** Use one shared command and one builder contract; the builder solely owns output guarantees.
- **[AGENT] (ratified by owner, 2026-08-09)** Keep runs and feedback under `.project/mental-alignment/`; **[AGENT]** suppress stage offers on the existing `NON-INTERACTIVE` marker.
- **[AGENT] (ratified by owner, 2026-08-09)** Promote reusable lessons only through an explicit, reviewable source edit.

**Spec/design detail still needed next:**

- Choose a distinct command name, run naming scheme, minimal metadata form, and feedback entry shape.
- Define accessible HTML patterns without making any visual mandatory.
- Define the shared-script path and generated Codex path rewrite without changing the architecture.

**First risk to de-risk:**

- Use `my-spike` on one real concept-design question to test whether the builder restores orientation without copying the artifact chain into HTML.

**Proof obligations:**

- Demonstrate owner comprehension and detection of known tensions on both offered flows.
- Demonstrate equivalent direct behavior and equivalent headless suppression in Claude and Codex.
- Demonstrate that unsafe or secret-bearing output fails rather than becoming a successful run.
- Demonstrate that promotion changes only reachable authored source and otherwise stops locally.

## Summary

The design adds one shared command and one builder contract, following an existing pack pattern. The builder alone owns a safe, traceable, two-layer report; the rest is file convention and two interactive offers. This keeps the checkpoint optional and subordinate to its evidence while giving the owner one practical surface for recovering system understanding.
