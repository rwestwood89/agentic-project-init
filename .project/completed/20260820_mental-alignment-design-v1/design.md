> **SUPERSEDED 2026-08-20 — do not treat anything here as current.**
>
> Part of the v1 design chain for the mental-alignment checkpoint, archived after the concept was overhauled on
> 2026-08-19 and 2026-08-20. See `design-revised.md` in this folder for the list of claims that are now wrong.
>
> **Live concept:** `.project/concepts/mental-alignment-checkpoint.md`

# Design: Mental Alignment Checkpoint

**Status:** Proposed
**Owner:** Project owner
**Created:** 2026-08-09

## Overview

The mental-alignment checkpoint is an on-demand review surface built around an owner's question. It produces a visual HTML explanation with two layers: a mental model first, then tensions and useful spot checks.

One public coordinator delegates HTML construction to one specialized builder. This keeps the main interaction small while giving the builder enough context and output budget to explain the system well.

## Problem

The workflow records product, architecture, planning, and implementation decisions in durable artifacts. The owner cannot read them all closely enough to maintain a current mental model of a substantial system.

No review surface currently reconstructs product intent, proposed structure, and relevant code reality around the question being asked. Product drift, weak architecture, and small implementation problems can therefore escape spot checks and grow.

The missing capability is an explanatory checkpoint for human judgment. It must improve understanding without becoming another source of truth or automatic pipeline ceremony.

## Goals

- Let the owner recover a useful system mental model from a focused question.
- Separate explanation from concerns, uncertainty, and suggested spot checks.
- Connect intended behavior, proposed structure, and relevant code reality when relevant.
- Preserve the authority and provenance of the evidence being explained.
- Keep generation optional while offering it at the two chosen approval boundaries.
- Support local feedback and deliberate promotion of reusable lessons.

## Non-Goals

- Generate checkpoints automatically.
- Require fixed visuals or a fixed source checklist.
- Replace reviews, audits, product checks, or their governing artifacts.
- Maintain a living explainer or project-status dashboard.
- Build a general learning system for other workflow skills.

## Design Principles

### 1. The Question Controls the Context

The builder follows the owner's question, using the smallest body of evidence that can explain the surrounding system and stating important gaps.

### 2. Understanding Comes Before Critique

The first layer teaches the mental model. Concerns and spot checks stay in a visibly separate layer so agent judgment cannot masquerade as system truth.

### 3. A Snapshot Explains; It Does Not Govern

Claims remain attributable to their evidence and moment in time. A checkpoint may expose a conflict, but it cannot settle one or outrank its sources.

### 4. Learning Requires an Explicit Choice

Feedback stays local by default. A reusable lesson changes shared behavior only through an owner-visible promotion.

## Architectural Bets

- Use one public coordinator command and one plain, one-job builder contract. This reuses the existing cross-runtime command pattern instead of adding a runtime, installer path, or custom-agent protocol.
- Create a new static HTML snapshot for each run and keep feedback separately. Do not maintain a synchronized explainer.
- Promote feedback through a deliberate edit to shared authored instructions. Do not add automatic learning, scoring, or synchronization.

## ADR Candidates

### The checkpoint is a read-only decision-record touch point

- **Proposed decision:** A checkpoint may read relevant governing decisions but never creates, amends, or supersedes them. Its output remains working evidence under ADR-0001.
- **Why it may need a record:** This adds a formal reader to the touch-point map extended by ADR-0005 and ADR-0006; omitting it would make the recorded map false.
- **Affected seams:** Project records, decision records, concept-design review, and epic planning.
- **Provenance:** `[AGENT]`
- **Alternative rejected:** Treat decision-record discovery as an unrecorded special case.

### One coordinator delegates to one builder contract

- **Proposed decision:** A cross-runtime public command coordinates the checkpoint and delegates only HTML construction to a one-job builder contract.
- **Why it may need a record:** The roles could be merged later, refilling main-agent context or splitting behavior by runtime.
- **Affected seams:** Shared command sources, Claude, Codex, and subagent execution.
- **Provenance:** `[AGENT] (ratified by owner, 2026-08-09)`
- **Alternative rejected:** A native skill or custom agent as the public cross-runtime surface.

### Promotion changes only shared authored instructions

- **Proposed decision:** Reusable feedback changes a resolved shared source or remains a local candidate; it never edits generated, installed, or vendored copies as shared behavior.
- **Why it may need a record:** Claude, Codex, and vendored installs expose different copies, so a future agent could promote into the wrong owner.
- **Affected seams:** Project feedback, shared pack source, Claude, Codex, and vendored projects.
- **Provenance:** `[AGENT] (ratified by owner, 2026-08-09)`
- **Alternative rejected:** Edit whichever checkpoint instruction file is locally available.

## Core Model

### Checkpoint Coordinator

An intended public command that accepts the question and optional starting context. It starts the builder, checks the result, handles explicit feedback requests, and returns a path plus a compact summary. It does not normally author HTML or resolve source conflicts.

The current pack already distributes shared command sources to Claude and Codex. The coordinator extends that pattern.

### HTML Builder Contract

An intended plain instruction document given to a general-purpose subagent for one job: discover relevant context and write one checkpoint. It owns synthesis, visual choice, and the two-layer presentation. It does not edit evidence, record feedback, or change shared instructions.

The current product-lens builder proves the pack can pass a complete contract to a subagent and receive a compact result.

### Project Record

An intended collection of append-only HTML runs at `.project/mental-alignment/runs/` and one ledger at `.project/mental-alignment/feedback.md`. It is working evidence under the current project-record convention, not a decision register.

### Stage Offers

Two intended prompts route into the coordinator. Concept-design review offers one after presenting findings and before owner resolution. Epic planning offers one after presenting the decomposition and before owner approval. Their existing input-discovery boundaries also surface relevant shaping product design without making it mandatory. Declining changes nothing.

## Diagram

```text
question or stage offer -> coordinator -> builder -> new HTML run
                              |
owner feedback -> project ledger -> explicit promotion -> shared checkpoint instructions
```

## Prior Art

- **Concept: Mental Alignment Checkpoint** supplies the approved scope and behavior this architecture serves.
- **ADR-0001** makes decision records the home for load-bearing decisions. Checkpoints and feedback remain working evidence.
- **ADR-0002**, as amended by **ADR-0005**, defines the base touch-point map; **ADR-0006** extends ADR-0005 for concept-design review. The checkpoint adds another read-only contact, so acceptance must amend ADR-0005's current map rather than add it silently.

No active decision is proposed for supersession.

## Required Invariants

### Invocation and Boundaries

- **Current:** The workflow does not generate or offer this checkpoint.
- **Intended:** Generation follows direct owner invocation or acceptance of one of the two stage offers.
- **Intended:** Every entry route uses the same coordinator and builder contract.
- **Intended:** The builder reads evidence but writes only one new run; it never edits its sources.
- **Intended:** The builder returns only the path and a compact account of coverage, limits, and concerns.
- **Intended:** Concept-design and epic-plan discovery surface relevant shaping product design without requiring it.

### Artifact Meaning and Safety

- **Intended:** A run records its question, time, scope, material evidence, limits, and whether code was inspected.
- **Intended:** A run separates explanation from concerns and labels current, intended, and proposed behavior when they coexist.
- **Intended:** Regeneration creates a new run and never overwrites an old one.
- **Intended:** HTML is self-contained and static: no scripts, event handlers, remote resources, tracking, credentials, or secrets.

### Authority and Feedback

- **Current:** Shared authored sources feed both runtimes: Claude normally links them; Codex generates and installs copies.
- **Intended:** Claims preserve source provenance and force; disagreements stay visible.
- **Intended:** Feedback names its run and has no effect on shared behavior merely because it was recorded.
- **Intended:** Promotion requires owner review and changes only shared authored instructions, never generated, installed, or vendored copies.
- **Intended:** If that source is unavailable, promotion remains a local candidate and stops.
- **Intended:** The checkpoint may read relevant live decisions but cannot file or alter them.

## How It Works

### Direct Checkpoint

Today the owner reconstructs the system from existing evidence. In the proposed flow, the coordinator delegates a question to the builder. The builder follows relevant evidence and writes one run. The coordinator checks it and returns its path with a short summary. Nothing existing is removed.

### Review-Boundary Offer

Today concept-design review and epic planning proceed directly from presentation to owner action. Each proposed flow adds one optional offer at its chosen boundary. Acceptance routes to the direct flow; refusal resumes the stage. Relevant shaping product design becomes discoverable context, not a required input.

### Feedback and Promotion

Today no checkpoint-specific feedback path exists. The proposed flow records owner-requested feedback against a run. A later explicit request may propose a focused change to shared checkpoint instructions for owner review. There is no background or automatic promotion.

## Edge Cases and Failure Modes

- A question is too broad: narrow it or mark partial coverage rather than recreate the artifact chain.
- Sources disagree: show the conflict and park dependent conclusions.
- Current behavior matters but code cannot be inspected: state the limit instead of inferring fact.
- Project records are not tracked: surface that the committed-output contract cannot be met.
- The builder fails or produces unsafe HTML: do not report a successful run.
- A run is stale: its metadata exposes that fact; regeneration creates a new run.
- Shared authored instructions are unavailable: keep feedback local and stop promotion.

## Vocabulary

- `checkpoint`: one reconstruction of a system around an owner question.
- `run`: the committed HTML snapshot produced by one invocation.
- `coordinator`: the public command that owns delegation, checking, and explicit feedback operations.
- `builder contract`: the complete one-job instructions given to the HTML-writing subagent.
- `promotion`: owner-reviewed transfer of a reusable local lesson into shared authored instructions.

## System Confidence

The coordinator must give the builder the same contract from every entry route. The builder must return one safe, traceable, two-layer snapshot or report failure. Direct invocation and both stage offers must behave the same after reaching the coordinator.

No component check proves that a checkpoint restores owner comprehension or exposes known product and architecture problems. Nor can one runtime's tests prove equivalent Claude and Codex behavior. Promotion must also stop safely when shared authored source is unavailable. These are epic-owned proof obligations.

## Validation Strategy

- Check catalogs and generated distributions for the same coordinator and builder contract in both runtimes.
- Check that the two offers occur at the chosen boundaries and never generate automatically.
- Inspect runs for traceability, layer separation, static local HTML, and absence of obvious secrets.
- Evaluate representative concept-design and epic-plan runs containing known product and architecture tensions.
- Exercise promotion with both available and unavailable shared authored source.

## Next-Stage Handoff

**Settled here:**

- The capability is on demand, question-led, and rendered as two-layer HTML.
- One public coordinator delegates HTML generation to one specialized builder contract.
- Runs are new project-local snapshots; feedback stays local until explicit promotion.
- Only concept-design review and epic planning offer it; it never becomes truth or a gate.

**Spec/design detail still needed next:**

- Choose the command name, run naming convention, minimal metadata form, and feedback entry shape.
- Define a few accessible HTML patterns without making any visual mandatory.

**First risk to de-risk:**

- Use `my-spike` on one real concept-design question to test whether the builder gives useful orientation without copying the artifact chain into HTML.

**Proof obligations:**

- Demonstrate owner comprehension and detection of known tensions on both offered flows.
- Demonstrate equivalent Claude and Codex behavior.
- Demonstrate that promotion edits only available shared authored source and otherwise stops.

## Summary

The design adds one optional capability: a public coordinator delegates one HTML snapshot to a specialized builder and returns a compact result. It preserves source authority, keeps feedback local by default, and adds only two thin offers at the chosen approval points.
