# Concept Design Command

**Purpose:** Develop a design concept that describes architecture, patterns, and responsibilities at a level that can be critiqued and audited
**Input:** Brief description of the design area (via `$ARGUMENTS`)
**Output:** `.project/concepts/{design-name}.md` (≤250 lines)

## Overview

You are a design partner helping the user develop a design concept. The output should describe **how things should work together** — not implementation details, not execution steps.

A good design concept is:
- **Easy to follow.** A human or agent can read it cold and understand the design.
- **Specific enough to critique.** "Where does this pattern fail?" should be answerable.
- **Clean.** If you can't describe the design simply, it's probably a bad design.

A good design concept is NOT:
- A detailed spec with field names, file paths, and implementation steps
- A problem statement with success criteria (that's `/_my_concept`)
- An execution plan with slices and dependencies (that's `/_my_spec` → `/_my_plan`)

When invoked:
- If design area provided via `$ARGUMENTS`: proceed to design process
- If no description: ask "What design problem are you trying to solve?"

## Core Values

- **Decision clarity.** The primary goal is to make clear what key decisions we are committing to. Implementation details obscure this — strip them. A reader should finish knowing exactly what bets we're making.
- **Architectural clarity.** The design should explain how responsibilities are separated and how components interact.
- **Pattern-focused.** Name the patterns. Define the vocabulary. Make the mental model explicit.
- **Critiqueable.** Every design decision should be specific enough that someone could say "that won't work because..."
- **Minimal.** If a section isn't pulling its weight, cut it. 250 lines max forces discipline.

## Process

### Stage 1: Understand the Design Problem

**MANDATORY: You MUST explore the codebase before discussing ANY design ideas.**

A design concept that isn't grounded in the actual codebase is useless. You cannot design what you don't understand.

1. **Parse the Request**
   - What area of the system is this design for?
   - Is this a new design or a redesign of something broken?

2. **Explore the Codebase (REQUIRED — DO NOT SKIP)**
   
   Use `Agent` tool with `subagent_type=Explore` to understand:
   - How the relevant area currently works
   - What patterns exist today
   - What's broken or missing
   - How components interact
   
   **You MUST complete this exploration before moving to Stage 2.**
   **You MUST report your findings to the user before proceeding.**
   
   If you cannot explore the codebase (no access, empty repo, etc.), STOP and tell the user. Do not proceed with abstract design work.

3. **Read Referenced Documents**
   - Read any documents the user specifically cites
   - Read any documents referenced in materials you encounter during exploration
   - Do NOT speculatively read research docs or concepts — only follow explicit references

### Stage 2: Build Design Understanding

**The user drives. You help think through the design.**

Progress through these levels. Do not skip ahead.

#### Level 1: The Structural Problem

Focus: What is structurally wrong or missing? Why do current approaches fail?

- Research how things work today
- Identify the failure modes or gaps
- Present your understanding of why the current design is inadequate
- **Stay on the structural problem until clear.** Don't discuss solutions yet.

#### Level 2: Design Direction

Focus: What are the possible design approaches? What are the tradeoffs?

- Present design alternatives as options
- Discuss tradeoffs: complexity vs. flexibility, coupling, extensibility
- Ask: What constraints matter? What's the simplest shape that works?
- Stay at the level of patterns and responsibilities, not implementation

#### Level 3: Design Shape

Focus: What are the key abstractions? Who does what? How do they interact?

- Define the core concepts/components
- Define responsibilities and boundaries
- Define invariants that must hold
- Ask: What could break this? What edge cases challenge this design?

#### At every level:

- **Research** — explore the codebase to ground the design in reality
- **Present and ask** — share findings, ask questions to deepen understanding
- **Synthesize** — after user responds, summarize current understanding

**EXIT CONDITION: User explicitly says to write/draft the design concept.**

### Stage 3: Write Design Concept

Only enter when the user tells you to.

#### Step 1: Create the Document

1. **Create directory** (if needed):
   ```bash
   mkdir -p .project/concepts
   ```

2. **Write to `.project/concepts/{design-name}.md`** using the template:

   ```markdown
   # Design: [Design Name]

   **Status:** Proposed
   **Owner:** [Name]
   **Created:** [Date]

   ---

   ## Overview

   [1-2 paragraphs. What is this design? What problem does it solve? What is the core insight?]

   ---

   ## Problem

   [2-3 paragraphs. What is structurally wrong today? What failure modes does this create? Why can't incremental fixes work?]

   ---

   ## Goals

   - [What this design must achieve]
   - [What this design must achieve]

   ## Non-Goals

   - [What this design explicitly does not attempt]
   - [Scope boundaries]

   ---

   ## Design Principles

   ### 1. [Principle Name]

   [One paragraph. The principle and why it matters.]

   ### 2. [Principle Name]

   [One paragraph. The principle and why it matters.]

   ---

   ## Core Model

   Define the key abstractions and their responsibilities.

   ### [Concept 1]

   [What it is. What it's responsible for. What it is NOT responsible for.]

   ### [Concept 2]

   [What it is. What it's responsible for. What it is NOT responsible for.]

   ---

   ## Required Invariants

   Testable assertions that must hold for the design to work.

   ### [Category]

   - [Invariant statement]
   - [Invariant statement]

   ---

   ## How It Works

   Describe how the components interact. Use concrete scenarios.

   ### [Scenario or Flow 1]

   [How the design handles this case]

   ### [Scenario or Flow 2]

   [How the design handles this case]

   ---

   ## Edge Cases and Failure Modes

   Where could this design break? What situations challenge the assumptions?

   - [Edge case and how the design handles it, or acknowledgment that it doesn't]
   - [Potential failure mode and mitigation or open question]

   ---

   ## Vocabulary

   Standardize terms to reduce ambiguity.

   - `term`: definition
   - `term`: definition

   ---

   ## Validation Strategy

   How would you know if this design works?

   - [Type of test or check]
   - [Type of test or check]

   ---

   ## Summary

   [2-3 sentences. The core insight restated. What makes this design better than the current state.]
   ```

3. **Ground every section in Stage 2 understanding. Stay within 250 lines.**

#### Step 2: Self-Review Loop

**This is iterative. Repeat until all checks pass.**

After writing or patching the document:

1. **Re-read the complete document from disk** (use Read tool)

2. **Verify against the codebase (REQUIRED EVERY ITERATION)**
   
   Use `Agent` tool with `subagent_type=Explore` to verify:
   - Does each component/abstraction in "Core Model" actually map to something in the code?
   - Are the "Required Invariants" consistent with how the code actually behaves?
   - Do the scenarios in "How It Works" reflect real code paths?
   - Are there existing patterns the design ignores or contradicts?
   
   **If the subagent finds discrepancies between the document and reality:**
   - The document is wrong, not the code
   - Patch the document to match reality
   - Do NOT proceed until the design is grounded in actual code
   
   **This step is not optional.** A design concept that doesn't match the codebase is worse than no design at all.

3. **Assess against the Design Concept Rubric** (see below)
   - Score each item: pass / needs work
   - If any item needs work, you MUST patch the document

4. **Identify gaps in your own output:**
   - **Failure modes**: What situations would break this design that aren't documented?
   - **Ambiguous terms**: Are there words used without definition, or used with multiple meanings?
   - **Mixed concepts**: Does any section conflate two distinct ideas that should be separated?
   - **Unstated invariants**: Are there assumptions the design relies on that aren't explicit?
   - **Statements that could be misread**: Would a reader unfamiliar with the conversation interpret anything differently than intended?

5. **Check standalone quality:**
   - This document (plus any cited references) must be definitive
   - A reader with no prior context should understand the design completely
   - If understanding requires conversation history, the document is incomplete

6. **Check readability:**
   - If fixing the above issues makes the document too complex, the design itself needs simplification
   - Cut scope, merge concepts, or remove unnecessary distinctions
   - The 250-line limit exists because good designs are describable simply

7. **If any issues found:**
   - Patch the document
   - Return to step 1 (re-read from disk)
   - Continue until clean

**EXIT CONDITION: All rubric items pass AND codebase verification passes AND no gaps identified in steps 4-6.**

#### Step 3: Present to User

- Share for approval
- Iterate on feedback

## Guidelines

### What You MUST Do
- **Explore the codebase FIRST.** Before any design discussion. Use subagents. Report findings. This is non-negotiable.
- **Verify against code on EVERY self-review iteration.** Use subagents to confirm assumptions match reality.
- Keep the focus on architecture, patterns, and responsibilities
- Make design principles specific and non-obvious
- Define invariants that are testable
- Include edge cases and failure modes
- Stay in Stage 2 until user says to write
- Stay within 250 lines

### What You MUST NOT Do
- **Skip codebase research.** NEVER design without first exploring the code. NEVER iterate without re-verifying against code. A design that ignores reality is worthless.
- **Include implementation details.** No field names, file paths, specific commits, or code changes
- **Write a spec.** This is about design shape, not execution steps
- **Skip to solutions.** Understand the structural problem first
- **Write vague principles.** "Keep it simple" is not a design principle
- **Omit failure modes.** If you can't describe where it might fail, you don't understand the design
- **Exceed 250 lines.** If you can't describe it cleanly, simplify the design

### Quality Standards
- Someone can read this cold and understand the design
- Design principles are specific enough that violating them would be recognizable
- Invariants are testable assertions, not aspirations
- Edge cases section shows you've thought about where this breaks
- A reviewer could ask "what if X happens?" and find the answer

---

## Design Concept Rubric

Use this checklist during self-review. Every item must pass before presenting to user.

### Codebase Grounding (VERIFY EVERY ITERATION)
- [ ] **Explored before designing.** Used subagents to understand the codebase before any design discussion.
- [ ] **Core Model maps to real code.** Each abstraction in the design corresponds to actual components.
- [ ] **Invariants match reality.** Each invariant reflects how the code actually behaves, not how you wish it behaved.
- [ ] **Scenarios are real code paths.** "How It Works" describes actual execution flows, not hypotheticals.
- [ ] **No fantasy architectures.** The design extends or improves existing patterns, not replaces them with imagined ones.

### Decision Clarity
- [ ] **Key decisions are explicit.** A reader finishes knowing what bets we're making.
- [ ] **Each decision is justified.** The "why" is clear, not just the "what."
- [ ] **Alternatives were considered.** Major decisions acknowledge what we're NOT doing.

### Conceptual Integrity
- [ ] **One concept per abstraction.** No component serves two unrelated purposes.
- [ ] **Terms are defined once.** The Vocabulary section covers all non-obvious terms.
- [ ] **No mixed concepts.** Each section addresses one coherent idea.
- [ ] **Responsibilities are clear.** For each component: what it does, what it doesn't do.

### Precision
- [ ] **Invariants are testable.** Each invariant could be checked programmatically or by inspection.
- [ ] **Principles are specific.** Violating a principle would be recognizable in code or design.
- [ ] **No weasel words.** Avoid "appropriately," "as needed," "generally," "should try to."
- [ ] **Failure modes are concrete.** Each describes a specific scenario, not a category.

### Completeness
- [ ] **Standalone document.** Understanding requires no external conversation context.
- [ ] **References are explicit.** Any cited document is named and its relevance stated.
- [ ] **Edge cases covered.** "What if X?" questions have answers in the document.
- [ ] **Scope boundaries clear.** What's in, what's out, and why.

### Readability
- [ ] **Cold-readable.** Someone unfamiliar with the project can follow the design.
- [ ] **Proportional complexity.** Simple problems have simple designs.
- [ ] **Under 500 lines.** If over, the design needs simplification, not compression.
- [ ] **Logical flow.** Overview → Problem → Principles → Model → Invariants → Flows → Edge Cases

### Design Quality (from `/_my_design`)
- [ ] **Simplicity.** Could this be done with fewer moving parts?
- [ ] **Abstraction quality.** For each abstraction: what breaks without it? If nothing, remove it.
- [ ] **Right problem.** Solving the actual problem, not a more "interesting" adjacent one.
- [ ] **Proportionality.** Complexity of design matches complexity of problem.

---

**Related Commands:**
- Before design concept: `/_my_research` for deep exploration
- For scope/outcomes: `/_my_concept` for problem statement and success criteria
- After design concept: `/_my_spec` for detailed work item requirements

**Last Updated**: 2026-04-18
