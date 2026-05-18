---
date: 2026-04-19T08:15:14-0700
researcher: Codex
topic: "Artifact pipeline alignment review for my_* commands"
tags: [research, prompts, workflow, artifacts, alignment]
status: complete
last_updated: 2026-04-19
---

# Research: Artifact Pipeline Alignment Review For `my_*` Commands

**Date**: 2026-04-19 08:15 PDT
**Researcher**: Codex
**Research Type**: Workflow / Prompt / Artifact Quality

## Research Question

How well do the current `my_*` commands and `EPIC_GUIDE.md` serve their intended stage in the workflow, specifically:

1. mental alignment with the human user
2. cumulative context and instruction for a fresh downstream agent

And what prompt changes would improve those artifacts?

## Summary

- The strongest artifact in the current pipeline is `/_my_concept_design` because it makes the stage contract explicit, enforces cold readability, separates conceptual from code-level detail, and includes a concrete self-review rubric ([claude-pack/commands/_my_concept_design.md:9](claude-pack/commands/_my_concept_design.md#L9), [claude-pack/commands/_my_concept_design.md:29](claude-pack/commands/_my_concept_design.md#L29), [claude-pack/commands/_my_concept_design.md:285](claude-pack/commands/_my_concept_design.md#L285), [claude-pack/commands/_my_concept_design.md:376](claude-pack/commands/_my_concept_design.md#L376)).
- `/_my_design` has moved meaningfully in the right direction by adding a required core concept, simplicity checks, anti-patterns, and a self-review gate, but it still carries enough template mass to drift back toward long, implementation-adjacent documents ([claude-pack/commands/_my_design.md:115](claude-pack/commands/_my_design.md#L115), [claude-pack/commands/_my_design.md:143](claude-pack/commands/_my_design.md#L143), [claude-pack/commands/_my_design.md:213](claude-pack/commands/_my_design.md#L213), [claude-pack/commands/_my_design.md:256](claude-pack/commands/_my_design.md#L256)).
- The weakest artifacts against the stated goal of "mental alignment" are `/_my_spec` and `/_my_plan`. Both contain good intent, but their templates bias toward exhaustive structure and checklists over context-setting and decision compression ([claude-pack/commands/_my_spec.md:55](claude-pack/commands/_my_spec.md#L55), [claude-pack/commands/_my_spec.md:121](claude-pack/commands/_my_spec.md#L121), [claude-pack/commands/_my_plan.md:90](claude-pack/commands/_my_plan.md#L90), [claude-pack/commands/_my_plan.md:123](claude-pack/commands/_my_plan.md#L123)).
- `EPIC_GUIDE.md` is strategically valuable because it teaches decomposition discipline, but its backlog item template is heavy enough to encourage mini-specs inside the epic instead of crisp strategic chunking ([.project/EPIC_GUIDE.md:42](.project/EPIC_GUIDE.md#L42), [.project/EPIC_GUIDE.md:119](.project/EPIC_GUIDE.md#L119), [.project/EPIC_GUIDE.md:162](.project/EPIC_GUIDE.md#L162)).
- `/_my_implement` is acceptable as machinery, but it should be treated as an execution control command, not a core slop-guard artifact. Its biggest improvement opportunity is reducing procedural drag while preserving deviation tracking ([claude-pack/commands/_my_implement.md:22](claude-pack/commands/_my_implement.md#L22), [claude-pack/commands/_my_implement.md:55](claude-pack/commands/_my_implement.md#L55), [claude-pack/commands/_my_implement.md:101](claude-pack/commands/_my_implement.md#L101)).

## Stage Model

The cleanest way to evaluate these commands is to treat each stage as reducing a different kind of ambiguity.

| Stage | Core question | Human-alignment job | Agent-context job |
|---|---|---|---|
| `my_concept` | What are we trying to achieve? | Make the product/feature legible and desirable | Preserve problem framing, success shape, and scope boundaries |
| `my_concept_design` | What is the right high-level structure? | Make architectural bets critiqueable | Preserve abstractions, invariants, vocabulary, and rejected directions |
| `EPIC_GUIDE.md` | How should a large initiative be chunked? | Make sequencing and work boundaries intelligible | Preserve decomposition rationale and critical path |
| `my_spec` | What exactly is this work item responsible for? | Make scope, success criteria, and rationale explicit | Preserve requirements, constraints, and why they exist |
| `my_design` | How should this scope land in the real codebase? | Make strategy, abstractions, and tradeoffs reviewable | Preserve implementation strategy and codebase grounding |
| `my_plan` | In what order should we execute and validate? | Make phasing and risk handling clear | Preserve sequence, validation gates, and failure assumptions |
| `my_implement` | How do we execute without losing alignment? | Keep the user informed of meaningful deviations | Preserve completion evidence, deviations, and remaining risk |

## Artifact Rubric

I recommend evaluating every artifact against the same rubric, with different weight by stage.

### 1. Stage Fidelity

Does the artifact stay at the altitude of its stage, or does it leak into adjacent stages?

- A concept should not read like a spec.
- A concept design should not read like a plan.
- A plan should not read like an implementation diary.

### 2. Context First

Does the artifact make the reader understand the problem, motivation, and "why now" before it dives into detail?

This is the main missing property in several current artifacts.

### 3. Decision Clarity

Can a reader quickly answer:

- what are the key bets?
- what alternatives were not chosen?
- what is intentionally out of scope?

### 4. Cold-Start Handoff Quality

Could a fresh agent begin the next stage from the artifact alone, without chat history?

This is the "full trace" requirement.

### 5. Proportionality

Does the size and structure of the artifact match the complexity of the problem?

If the artifact feels longer than the underlying decision, it is probably compensating for weak framing with excess detail.

### 6. Compression Without Loss

Does the artifact preserve the important things while discarding noise?

The best artifacts are not merely complete. They are selective.

### 7. Boundary Clarity

Is it obvious what this artifact settles, what it leaves open, and what the next stage is expected to decide?

### 8. Grounding

Is the artifact grounded in the real project or codebase rather than imagined structure?

## Suggested Scoring Scale

- **Strong**: materially supports both human alignment and downstream agent execution
- **Mixed**: useful, but leaks or bloats enough that alignment quality degrades
- **Weak**: often produces artifacts that are formally complete but strategically unclear

## Detailed Findings

### `/_my_concept`

**Stage intent**

`/_my_concept` is trying to establish the feature/product shape before implementation detail. The strongest parts are its explicit user-driven posture, its progressive levels of discussion, and its refusal to jump straight to drafting ([claude-pack/commands/_my_concept.md:9](claude-pack/commands/_my_concept.md#L9), [claude-pack/commands/_my_concept.md:42](claude-pack/commands/_my_concept.md#L42), [claude-pack/commands/_my_concept.md:84](claude-pack/commands/_my_concept.md#L84)).

**Assessment**

- Human alignment: **Strong**
- Agent context: **Strong**
- Overall: **Strong, with some leakage**

**Why it works**

- It is explicitly about understanding the problem and solution space, not deciding the solution ([claude-pack/commands/_my_concept.md:11](claude-pack/commands/_my_concept.md#L11)).
- It forces a top-down progression: problem first, then broad approach, then fit in the codebase ([claude-pack/commands/_my_concept.md:50](claude-pack/commands/_my_concept.md#L50), [claude-pack/commands/_my_concept.md:59](claude-pack/commands/_my_concept.md#L59), [claude-pack/commands/_my_concept.md:68](claude-pack/commands/_my_concept.md#L68)).
- It keeps the output bounded at 300 lines, which is a real anti-slop mechanism ([claude-pack/commands/_my_concept.md:21](claude-pack/commands/_my_concept.md#L21), [claude-pack/commands/_my_concept.md:196](claude-pack/commands/_my_concept.md#L196)).

**Where it still slips**

- The document template includes `Scope of Behavior Changes` and `Decomposition Guidance`, which nudges the artifact downstream into workflow planning earlier than necessary ([claude-pack/commands/_my_concept.md:160](claude-pack/commands/_my_concept.md#L160), [claude-pack/commands/_my_concept.md:191](claude-pack/commands/_my_concept.md#L191)).
- There is no explicit "key bets" or "why this concept is the right shape" section. That makes the handoff to concept design or spec weaker than it could be.

**Recommendation**

- Keep the interactive structure.
- Add a short required section near the top: `Why This Shape`.
- Demote `Scope of Behavior Changes` and `Decomposition Guidance` to a short closing section or optional appendix.
- Add a standardized `Settled / Unsettled` handoff block.

### `/_my_concept_design`

**Stage intent**

This is the cleanest articulation of a stage contract in the current pipeline. It explicitly exists to describe architecture, patterns, and responsibilities at a critiqueable level, and not implementation, spec, or execution ([claude-pack/commands/_my_concept_design.md:9](claude-pack/commands/_my_concept_design.md#L9), [claude-pack/commands/_my_concept_design.md:17](claude-pack/commands/_my_concept_design.md#L17)).

**Assessment**

- Human alignment: **Strong**
- Agent context: **Strong**
- Overall: **Strongest artifact in the set**

**Why it works**

- It makes the intended reading experience explicit: cold-readable, conceptual upfront, specific downstream, and critiqueable ([claude-pack/commands/_my_concept_design.md:11](claude-pack/commands/_my_concept_design.md#L11)).
- The two-register rule is exactly the right mechanism for preventing context collapse into identifiers and implementation detail ([claude-pack/commands/_my_concept_design.md:29](claude-pack/commands/_my_concept_design.md#L29), [claude-pack/commands/_my_concept_design.md:37](claude-pack/commands/_my_concept_design.md#L37)).
- It explicitly prioritizes decision clarity and minimality ([claude-pack/commands/_my_concept_design.md:31](claude-pack/commands/_my_concept_design.md#L31), [claude-pack/commands/_my_concept_design.md:35](claude-pack/commands/_my_concept_design.md#L35)).
- The self-review loop is unusually strong: codebase verification, gap detection, standalone quality, and readability checks are all first-class ([claude-pack/commands/_my_concept_design.md:291](claude-pack/commands/_my_concept_design.md#L291), [claude-pack/commands/_my_concept_design.md:321](claude-pack/commands/_my_concept_design.md#L321), [claude-pack/commands/_my_concept_design.md:326](claude-pack/commands/_my_concept_design.md#L326)).
- The rubric is aligned with your stated objective: cold-reader test, explicit bets, conceptual integrity, proportionality ([claude-pack/commands/_my_concept_design.md:380](claude-pack/commands/_my_concept_design.md#L380), [claude-pack/commands/_my_concept_design.md:395](claude-pack/commands/_my_concept_design.md#L395), [claude-pack/commands/_my_concept_design.md:425](claude-pack/commands/_my_concept_design.md#L425)).

**Residual weakness**

- The prompt is long and rigorous enough that some agents may over-invest in satisfying the rubric mechanically.
- There is no single standardized `Architectural Bets` section, even though the command clearly wants that outcome.
- I could not find a local example artifact generated by this command in this repo, so this assessment is based on prompt quality rather than a repo-local output sample.

**Recommendation**

- Keep the command largely as-is.
- Add a required `Architectural Bets` section near the top.
- Add a `What Spec Must Decide Next` closing block.
- Consider compressing the self-review checklist into 8-10 top-level checks, with the longer rubric retained as a reference appendix.

### `EPIC_GUIDE.md`

**Stage intent**

The guide is trying to turn large work into sane backlog items. Its best contribution is decomposition discipline: right-sizing, task-type cohesion, and anti-patterns ([.project/EPIC_GUIDE.md:42](.project/EPIC_GUIDE.md#L42), [.project/EPIC_GUIDE.md:63](.project/EPIC_GUIDE.md#L63), [.project/EPIC_GUIDE.md:241](.project/EPIC_GUIDE.md#L241)).

**Assessment**

- Human alignment: **Mixed**
- Agent context: **Mixed**
- Overall: **Useful, but too operational in the item template**

**Why it works**

- It correctly emphasizes not over-planning too early ([.project/EPIC_GUIDE.md:13](.project/EPIC_GUIDE.md#L13), [.project/EPIC_GUIDE.md:18](.project/EPIC_GUIDE.md#L18)).
- The Goldilocks and task-type heuristics are strong and concrete ([.project/EPIC_GUIDE.md:42](.project/EPIC_GUIDE.md#L42), [.project/EPIC_GUIDE.md:63](.project/EPIC_GUIDE.md#L63)).
- It correctly frames backlog items as the unit that should go through spec → design → plan → execute ([.project/EPIC_GUIDE.md:32](.project/EPIC_GUIDE.md#L32), [.project/EPIC_GUIDE.md:79](.project/EPIC_GUIDE.md#L79)).

**Where it hurts alignment**

- The backlog item template is already very close to a mini-spec: current state, scoped components, out of scope, success criteria, effort accounting, deliverables, dependencies ([.project/EPIC_GUIDE.md:162](.project/EPIC_GUIDE.md#L162)).
- The guide emphasizes planning overhead and effort heuristics heavily ([.project/EPIC_GUIDE.md:91](.project/EPIC_GUIDE.md#L91)), which is useful, but it can crowd out the more important strategic question: why is this decomposition smart?
- The completed epic example in `.project/completed/20251230_epic_init_strategy.md` shows the good part of the guide, but also shows how quickly epic items become very detailed before spec time ([.project/completed/20251230_epic_init_strategy.md:37](.project/completed/20251230_epic_init_strategy.md#L37)).

**Recommendation**

- Add an `Epic Strategy` section before backlog items:
  - value delivery path
  - critical path
  - main decomposition logic
  - what makes these chunks independent
- Lighten the backlog item template.
  Suggested required fields:
  - objective
  - why this is a single work item
  - dependencies
  - done state
  - out of scope
- Add an explicit rule: `Do not turn backlog items into mini-specs.`

### `/_my_spec`

**Stage intent**

The spec stage should define scope and success criteria for a work item, including why those requirements exist. The command has strong user-capture behavior, but the document template still tends toward legalistic requirement dumping ([claude-pack/commands/_my_spec.md:9](claude-pack/commands/_my_spec.md#L9), [claude-pack/commands/_my_spec.md:55](claude-pack/commands/_my_spec.md#L55), [claude-pack/commands/_my_spec.md:121](claude-pack/commands/_my_spec.md#L121)).

**Assessment**

- Human alignment: **Mixed**
- Agent context: **Strong**
- Overall: **Mixed**

**Why it works**

- The scoping conversation is good. `What I Heard You Say`, business goals, scope, exclusions, and questions all support alignment before drafting ([claude-pack/commands/_my_spec.md:59](claude-pack/commands/_my_spec.md#L59)).
- It distinguishes user-provided requirements from inferred ones, which is very useful for downstream agents ([claude-pack/commands/_my_spec.md:48](claude-pack/commands/_my_spec.md#L48), [claude-pack/commands/_my_spec.md:182](claude-pack/commands/_my_spec.md#L182)).
- It explicitly warns against sneaking design decisions into the spec ([claude-pack/commands/_my_spec.md:234](claude-pack/commands/_my_spec.md#L234), [claude-pack/commands/_my_spec.md:238](claude-pack/commands/_my_spec.md#L238)).

**Why it underperforms against your stated goal**

- The command introduces RFC 2119 terminology very early ([claude-pack/commands/_my_spec.md:17](claude-pack/commands/_my_spec.md#L17)). That pushes the voice toward compliance language instead of alignment language.
- The final template puts heavy weight on numbered `FR-*` requirements and acceptance criteria ([claude-pack/commands/_my_spec.md:178](claude-pack/commands/_my_spec.md#L178), [claude-pack/commands/_my_spec.md:194](claude-pack/commands/_my_spec.md#L194)).
- In practice, this tends to produce long documents. `.project/active/simplified-setup-system/spec.md` is 399 lines, with the requirements section beginning at line 123 and acceptance criteria at line 300 ([.project/active/simplified-setup-system/spec.md:123](.project/active/simplified-setup-system/spec.md#L123), [.project/active/simplified-setup-system/spec.md:300](.project/active/simplified-setup-system/spec.md#L300)).
- The artifact does preserve detail well for a fresh agent, but the rationale and hierarchy of importance are easy to lose inside the enumeration.

**Recommendation**

- Make plain-language framing mandatory before any FR list:
  - `Feature In One Paragraph`
  - `Why These Requirements Exist`
  - `What Would Make This Spec Wrong`
- Keep requirements, but group them by workflow or decision area rather than flat enumeration whenever possible.
- Treat RFC 2119 as optional style guidance, not the document's organizing principle.
- Add a hard preference for `Top 5-10 scope-critical requirements`, then optional appendix if more detail is needed.
- Add `Settled Decisions`, `Open Questions`, and `Escalations for Design`.

### `/_my_design`

**Stage intent**

This stage should translate approved scope into a real codebase strategy and make the implementation approach critiqueable. The current prompt is meaningfully better than the older outputs in this repo and is now much closer to the intent of `my_concept_design` at work-item scale ([claude-pack/commands/_my_design.md:11](claude-pack/commands/_my_design.md#L11), [claude-pack/commands/_my_design.md:115](claude-pack/commands/_my_design.md#L115)).

**Assessment**

- Human alignment: **Good**
- Agent context: **Good**
- Overall: **Good, but still vulnerable to bloat**

**Why it works**

- It now requires a `Core Concept` before parts enumeration ([claude-pack/commands/_my_design.md:115](claude-pack/commands/_my_design.md#L115)).
- The reflection step explicitly asks about simplicity, abstraction quality, right-problem, and proportionality ([claude-pack/commands/_my_design.md:145](claude-pack/commands/_my_design.md#L145)).
- The self-review gate is strong and clearly imported from the design-review mindset ([claude-pack/commands/_my_design.md:213](claude-pack/commands/_my_design.md#L213)).
- The anti-patterns section is exactly the right kind of pressure against slop ([claude-pack/commands/_my_design.md:303](claude-pack/commands/_my_design.md#L303)).

**Where it still leaks**

- The final structure is still large: research findings, core concept, architecture, key decisions, component overview, implementation notes, potential risks, integration strategy, validation approach ([claude-pack/commands/_my_design.md:256](claude-pack/commands/_my_design.md#L256)).
- There is no hard output-length constraint like the one in `/_my_concept` or `/_my_concept_design`.
- Older design outputs show the failure mode vividly:
  - `.project/active/simplified-setup-system/design.md` is 1004 lines and contains repeated `Implementation Details` sections ([.project/active/simplified-setup-system/design.md:233](.project/active/simplified-setup-system/design.md#L233), [.project/active/simplified-setup-system/design.md:451](.project/active/simplified-setup-system/design.md#L451), [.project/active/simplified-setup-system/design.md:707](.project/active/simplified-setup-system/design.md#L707), [.project/active/simplified-setup-system/design.md:801](.project/active/simplified-setup-system/design.md#L801)).
  - `.project/active/hook-path-resolution/design.md` is 439 lines and still takes a componentized, implementation-adjacent shape ([.project/active/hook-path-resolution/design.md:68](.project/active/hook-path-resolution/design.md#L68), [.project/active/hook-path-resolution/design.md:100](.project/active/hook-path-resolution/design.md#L100)).
  - `.project/active/ralph-resilience/design.md` is conceptually stronger because it leads with "three orthogonal concerns," but it still ends up at 519 lines ([.project/active/ralph-resilience/design.md:95](.project/active/ralph-resilience/design.md#L95)).

**Recommendation**

- Add a hard main-document target, for example `prefer <=300 lines; >350 requires appendix`.
- Add a required `Design In Five Bullets` or `Key Bets` section near the top.
- Make `Implementation Notes` aggressively short:
  - constraints
  - non-obvious gotchas
  - patterns to preserve
- Move detailed codebase evidence to an appendix or referenced research doc when needed.
- Add an explicit rule: `If you are listing components before the reader knows the strategy, stop and rewrite.`

### `/_my_plan`

**Stage intent**

The plan stage should stage execution, de-risk the work, and define validation. The command says this clearly, but the template over-specifies the document and tends to create large mechanical plans ([claude-pack/commands/_my_plan.md:9](claude-pack/commands/_my_plan.md#L9), [claude-pack/commands/_my_plan.md:15](claude-pack/commands/_my_plan.md#L15)).

**Assessment**

- Human alignment: **Mixed to weak**
- Agent context: **Good**
- Overall: **Mixed**

**Why it works**

- It correctly emphasizes phase ordering, de-risking, test-first, and continuous validation ([claude-pack/commands/_my_plan.md:11](claude-pack/commands/_my_plan.md#L11), [claude-pack/commands/_my_plan.md:47](claude-pack/commands/_my_plan.md#L47)).
- It also correctly tries to avoid duplication with the design document ([claude-pack/commands/_my_plan.md:15](claude-pack/commands/_my_plan.md#L15)).

**Why it underperforms**

- The required per-phase structure is rigid and verbose: test stencil, changes required, validation, and "what we know works" for every phase ([claude-pack/commands/_my_plan.md:92](claude-pack/commands/_my_plan.md#L92), [claude-pack/commands/_my_plan.md:123](claude-pack/commands/_my_plan.md#L123)).
- The template still encourages file-by-file action checklists even while claiming to avoid duplication ([claude-pack/commands/_my_plan.md:145](claude-pack/commands/_my_plan.md#L145)).
- The example output in `.project/active/simplified-setup-system/plan.md` is 518 lines, with five repeated phases before implementation even starts ([.project/active/simplified-setup-system/plan.md:23](.project/active/simplified-setup-system/plan.md#L23), [.project/active/simplified-setup-system/plan.md:427](.project/active/simplified-setup-system/plan.md#L427)).
- This makes the artifact useful as a checklist, but weak as a mental-alignment artifact. The reader must wade through a lot of mechanics to understand the actual sequence strategy.

**Recommendation**

- Change the per-phase template to:
  - goal
  - why now
  - key actions
  - exit checks
  - risk or assumption under test
- Make `Test Stencil` optional, used only when a phase's test shape is non-obvious or high-risk.
- Ban exhaustive file-by-file checklists unless the phase is especially coordination-sensitive.
- Add a one-screen summary at the top:
  - critical path
  - highest-risk assumptions
  - first proof point
  - rollback or fallback path
- Add a line/bullet budget per phase.

### `/_my_implement`

**Stage intent**

This command is not primarily a slop-guard artifact generator. It is an execution controller with progress tracking, validation, and deviation handling. Judged as machinery, it is reasonable. Judged as a mental-alignment artifact producer, it is secondary by design ([claude-pack/commands/_my_implement.md:3](claude-pack/commands/_my_implement.md#L3), [claude-pack/commands/_my_implement.md:9](claude-pack/commands/_my_implement.md#L9)).

**Assessment**

- Human alignment: **Adequate**
- Agent context: **Adequate**
- Overall: **Acceptable machinery**

**What it gets right**

- It requires understanding before action ([claude-pack/commands/_my_implement.md:22](claude-pack/commands/_my_implement.md#L22)).
- It explicitly warns against blind plan-following ([claude-pack/commands/_my_implement.md:11](claude-pack/commands/_my_implement.md#L11)).
- It requires implementation notes and status synchronization, which is good for preserving trace ([claude-pack/commands/_my_implement.md:101](claude-pack/commands/_my_implement.md#L101), [claude-pack/commands/_my_implement.md:118](claude-pack/commands/_my_implement.md#L118)).

**What makes it heavier than needed**

- It always offers extra codebase exploration, even when the user already wants execution and the earlier artifacts should have resolved ambiguity ([claude-pack/commands/_my_implement.md:36](claude-pack/commands/_my_implement.md#L36)).
- It always asks for phase execution style unless the user specified otherwise ([claude-pack/commands/_my_implement.md:55](claude-pack/commands/_my_implement.md#L55)).
- The tone of the tracking guidance is strong, but it risks optimizing for compliance theater over useful execution notes ([claude-pack/commands/_my_implement.md:156](claude-pack/commands/_my_implement.md#L156)).

**Recommendation**

- Keep the understanding and deviation requirements.
- Make the exploration offer conditional: only if there is genuine ambiguity.
- Make phase-choice confirmation conditional: skip it if the user clearly asked for "implement all" or "pick up where you left off."
- Standardize implementation notes into a compact execution journal:
  - completed
  - deviations
  - validation performed
  - remaining risk

## Cross-Cutting Recommendations

### 1. Add A Standard Stage Contract To Every Command

At the top of each command, add a short block:

- `This artifact is for...`
- `This artifact is not for...`
- `A good artifact lets a cold reader...`

`/_my_concept_design` already does this well. Several other commands do not.

### 2. Standardize A Top-Level Alignment Snapshot

Every artifact from concept through plan should begin with a short, mandatory summary block:

- `Why this exists`
- `What this artifact settles`
- `What remains open`
- `What the next stage should decide`

This would do more for mental alignment than adding more sections further down.

### 3. Add Explicit Output Budgets

Line caps are one of the strongest anti-slop controls in the current system.

- `my_concept`: keep current cap
- `my_concept_design`: keep current cap
- `my_spec`: add preferred cap
- `my_design`: add preferred cap
- `my_plan`: add preferred cap

Without hard pressure, verbose templates will fill themselves.

### 4. Prefer Main Doc + Appendix Over Unbounded Main Docs

When detailed evidence or file-by-file analysis is needed, keep it in:

- research docs
- appendix sections
- referenced artifacts

The main artifact should optimize for comprehension and decision-making.

### 5. Add A Standard `Settled / Unsettled / Rejected` Block

This is the missing trace primitive.

Every major artifact should end with:

- `Settled in this artifact`
- `Explicitly not chosen`
- `Questions for next stage`

That would materially improve both human review and fresh-agent continuity.

### 6. Evaluate Artifacts Against One Unified Slop-Guard Checklist

For any artifact, ask:

1. Can a cold reader explain the problem after the first screen?
2. Can they name the key bets?
3. Can they say what is out of scope?
4. Can a fresh agent continue without chat history?
5. Is any large chunk of the artifact obviously from the wrong stage?
6. Is the artifact shorter than the thing it is trying to explain?

If any answer is no, the artifact should be revised.

## Overall Assessment

The direction of travel is good. The repo clearly contains evidence that you already identified the core failure mode: older prompts rewarded exhaustive detail without enough context or conceptual compression. `/_my_concept_design` fixes this most directly by making cold readability and decision clarity the point of the artifact, not just a nice-to-have.

The main remaining work is to push that same philosophy down the rest of the pipeline:

- `my_concept`: keep it problem-first, but tighten the handoff
- `EPIC_GUIDE`: keep it strategic, not pseudo-spec-heavy
- `my_spec`: keep the requirement traceability, but foreground rationale
- `my_design`: keep the improved conceptual core, but cap document sprawl
- `my_plan`: strip it down to sequencing, risk, and validation
- `my_implement`: treat it as machinery and optimize for concise execution trace

The central lesson is simple:

**A good artifact is not the one that says the most. It is the one that lets the next reader recover the intended mental model fastest and safest.**

## Open Questions

- Whether `/_my_spec` should remain RFC-2119 flavored at all, or whether that should become an opt-in mode for high-rigor environments.
- Whether `/_my_design` and `/_my_concept_design` should share a common "bets / invariants / non-goals / next-stage handoff" skeleton to make the pipeline feel more uniform.
- Whether `/_my_plan` should produce two artifacts:
  - a short alignment plan for humans
  - a separate execution checklist for the implementing agent
