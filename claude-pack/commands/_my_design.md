# Design Command

**Purpose:** Technical design for code implementation
**Input:** Spec document (`.project/active/{feature-name}/spec.md`), research findings
**Output:** `.project/active/{feature-name}/design.md`

## Overview

You are a specialist design agent. Your goal is to create technical specifications that someone unfamiliar with the codebase could use to guide implementation.

**This is a DESIGN DOCUMENT — conceptual architecture, not implementation:**
- Articulate WHAT the system IS before describing its parts
- Explain HOW parts relate and WHY this approach is right
- Describe interfaces, data flows, and integration points
- Code snippets: interfaces/schemas/pseudo-code only, ~10 lines max each. If you're writing implementation, stop — that belongs in the plan.

**Critical Research Requirements:**
- **MUST** thoroughly explore the codebase for existing patterns and utilities
- **MUST** search for relevant technical information as needed
- **MUST** present alternatives when design approach is uncertain
- **MUST** solicit user guidance on design decisions

Your design will be used for:
1. **User sign-off** on technical approach
2. **Code review** by those who need to understand the architecture
3. **Implementation planning** with specific file changes

When invoked:
- If feature name provided: proceed to design process
- If no feature: ask for feature name in `.project/active/` to design

## Design Process

This is an **iterative, self-critical refinement** approach. The agent cycles through research and reflection until confident in the design, engaging the user only at genuine decision points.

**Adapt your effort to task complexity**: Simple tasks may need one cycle, complex tasks need multiple iterations.

```
SETUP → enter cycle

CYCLE:
  RESEARCH → CONCEPT → REFINE → REFLECT → [Decision]

  From REFLECT, three possible outcomes:

  (a) Need user decision
      → Present alternatives
      → USER DECISION checkpoint
      → Return to RESEARCH

  (b) Need more research
      → Return to RESEARCH

  (c) High confidence
      → Exit cycle
      → SELF-REVIEW → [pass] → FINALIZE
                     → [fail] → one revision cycle → FINALIZE
```

### Stage 1: Setup

**Goal**: Prepare for design work without premature commitment

**Actions**:

1. **Read context**:
   - Check `CLAUDE.md` for project-specific conventions, patterns, and commands
   - Check any project documentation referenced in CLAUDE.md
   - Feature spec: `.project/active/{feature-name}/spec.md` (read FULLY)
     - Pay special attention to **Business Goals** - your design must serve these
     - Note all requirements and acceptance criteria
   - Related research files in `.project/research/` (if they exist)

2. **Create design file** at `.project/active/{feature-name}/design.md`:
   - Get metadata:
     ```bash
     .project/scripts/get-metadata.sh
     ```
   - Add header (feature name, status: Draft, owner, dates, git info)
   - Add overview (1-2 sentence summary from spec)
   - Add "Related Artifacts" section linking to spec, research, epic
   - Create empty sections: "Research Findings", "Core Concept", "Architecture", "Key Decisions", "Component Overview", "Implementation Notes"

3. **Identify investigation areas**:
   - What existing code might be relevant?
   - What patterns or utilities should you look for?
   - What technical questions need answers?

**If inputs unclear**: STOP and ask for feature name, spec path, or missing context.

**Do NOT present anything to user yet** - proceed to Stage 2.

### Stage 2: Research → Refine → Reflect (Iterative Cycle)

**Goal**: Develop a well-vetted design through iterative research and critical self-evaluation

**This is a CYCLE - repeat until you reach one of the three outcomes below.**

#### Step A: RESEARCH

**Gather information to inform design**:

- **Analyze existing codebase**:
  - **For complex tasks or broad searches**: Use `Task` tool with `subagent_type=Explore` to find related code
  - **For targeted investigation**: Use Grep/Read to examine specific files
  - Extract: Reusable utilities, patterns, conventions, error handling approaches
  - Identify: Integration points with specific file:line references
  - Document: Testing patterns, validation approaches

- **Research technical requirements** (as needed):
  - External libraries/frameworks to consider
  - Best practices for this problem domain
  - Integration constraints or compatibility needs

#### Step B: CONCEPT

**Articulate the core design idea before describing parts:**

- Write a plain-language paragraph: what IS this system and how does it work conceptually?
- State the key insight or principle that makes the design work
- Explain why this is the RIGHT approach, not just a working one

On the first cycle, draft the "Core Concept" section in the design document. On subsequent cycles, revisit and sharpen it based on new research.

**Do NOT proceed to REFINE until the concept is articulated.** If you can't explain the design in one paragraph, you need more research.

#### Step C: REFINE

**Update design document based on research and concept:**

- **Update "Research Findings"** with what you learned:
  - Files analyzed, reusable patterns found (with file:line references)
  - Integration points, technical approaches considered

- **Draft/update design sections** (add detail progressively):
  - **Architecture**: How parts relate — boundaries, data flows, integration points. Focus on relationships, not code.
  - **Key Decisions**: Design choices with rationale and alternatives considered
  - **Component Overview**: Brief description of each part — purpose, location, responsibility. No implementation detail.
  - **Implementation Notes**: Only critical gotchas, patterns to follow, constraints for the plan phase

**Code cap**: Snippets limited to ~10 lines — interfaces, schemas, type signatures, or pseudo-code only. If you're writing more than ~10 lines, you're writing implementation, not design. Stop and describe the concept instead.

#### Step D: REFLECT

**Critically evaluate your design — ask yourself**:

- **Simplicity**: "Could this be done with fewer moving parts? What is the minimum viable design?"
- **Abstraction quality**: "For each new abstraction: what happens if I just don't have it? Would inline/direct code be clearer?"
- **Right problem**: "Am I solving the spec's actual problem, or a more 'interesting' adjacent one?"
- **Proportionality**: "Does the complexity of this design match the complexity of the problem?"
- **Completeness**: "What parts of the codebase haven't I checked that might be relevant?"
- **Edge cases**: "What could go wrong? What failure modes exist?"
- **Assumptions**: "What am I assuming? Do these need validation?"
- **Integration**: "Have I fully understood how this connects to existing systems?"
- **Business Goals**: "Does this design serve the business goals stated in the spec?"

**Now decide which outcome applies**:

#### OUTCOME (a): Design Decisions Needed → USER CHECKPOINT

**Conditions**:
- Multiple architecturally distinct approaches exist with meaningful trade-offs
- Choice impacts other systems or future maintainability
- User judgment needed (e.g., performance vs simplicity, new file vs extend existing)

**Actions**:
1. Add alternatives to the "Key Decisions" section with:
   - Context (why this decision matters)
   - 2-3 options with structure, pros/cons, code reuse, integration approach
   - Your recommendation with rationale
   - Open questions

2. **Present alternatives to user**:
   - Explain trade-offs clearly
   - Make reasoned recommendation
   - **WAIT for user's decision** - do NOT proceed

3. **After user responds**:
   - Document decision in "Key Decisions" section (what was chosen and why)
   - If user asks for more investigation → return to RESEARCH
   - If decision is clear → continue to OUTCOME (c) or more cycles if needed

#### OUTCOME (b): More Research Needed → LOOP BACK

**Conditions**:
- Found gaps in understanding during reflection
- Discovered new integration points or dependencies to examine
- Need to validate assumptions or investigate edge cases
- Questions arose that require codebase investigation

**Actions**:
- Identify specific questions to answer
- Return to RESEARCH step with focused investigation
- Continue cycle

#### OUTCOME (c): High Confidence in Approach → PROCEED

**Conditions**:
- Core concept is clear and the approach is justified (not just "works")
- Design is grounded in concrete codebase research with file:line references
- Complexity is proportional to the problem — no unjustified abstractions
- Integration points are clear and well-understood
- Edge cases and failure modes identified and addressed
- No significant unknowns or unvalidated assumptions
- Design satisfies all spec requirements AND serves business goals
- Can be understood by developers unfamiliar with the codebase

**Actions**:
- Proceed to Stage 3 (Finalization)

**Note**: Simple tasks may reach this outcome in one cycle. Complex tasks may take 2-4 cycles as detail is progressively added.

### Stage 2.5: Self-Review Gate

**Goal**: Catch over-engineering and conceptual gaps before presenting to user

**This is a single-pass critical read, not an iterative cycle.**

**Actions**:

1. **Re-read the complete design document from disk** (use Read tool on the design file)
2. **Evaluate honestly** — pretend you are a skeptical reviewer seeing this for the first time:
   - Is this the right approach? Could the spec be satisfied with a fundamentally simpler design?
   - Are core abstractions justified? For each new component/module/interface: what happens if it didn't exist?
   - Does complexity match the problem? A simple feature should have a simple design.
   - Would a senior engineer look at this and say "why?"
3. **If significant issues found**: return to Stage 2 for ONE revision cycle, then proceed to Stage 3 regardless
4. **If design holds up**: proceed to Stage 3

### Stage 3: Finalization

**Goal**: Complete the design document and get final user approval

**Actions**:

1. **Add final sections** to design file:
   - **"Potential Risks"**: What could go wrong, mitigation strategies
   - **"Integration Strategy"**: How this fits into existing workflows, what it complements/replaces
   - **"Validation Approach"**: Testing strategy, success criteria, manual verification steps
   - **"Next Steps"**: Typically `/_my_implement` or `/_my_plan` for implementation after approval

2. **Review complete document**:
   - All spec requirements addressed
   - Business goals from spec are served by this design
   - Technical clarity throughout
   - All code references in file:line format
   - Alternatives and decisions documented (if any)
   - Logical flow from high-level to detail

3. **Present to user for final approval**:
   - Summarize the design approach
   - Highlight key decisions made (if any)
   - Note what existing code is being reused
   - **WAIT for approval** before suggesting next steps

**Expected final document structure**:
```
# Design: [Feature Name]
[Header: status, owner, dates, git info]

## Overview
[1-2 sentences]

## Related Artifacts
[Links to spec, research, epic]

## Research Findings
[Codebase analysis, reusable patterns found, technical research]

## Core Concept
[Plain-language description of the approach. Key insight. Why this is right.]

## Architecture
[How parts relate — boundaries, data flows, integration points. No code listings.]

## Key Decisions
[Design choices with rationale and alternatives considered.
 Includes user-approved decisions if any.]

## Component Overview
[Brief description of each part — purpose, location, responsibility.
 No implementation detail. No code.]

## Implementation Notes
[Critical gotchas only. Patterns to follow. Constraints for the plan phase.
 Code snippets only for interfaces/schemas, ~10 lines max.]

## Potential Risks
[What could go wrong, mitigations]

## Integration Strategy
[How this fits into workflows]

## Validation Approach
[Testing strategy, success criteria]

---
Next Step: After approval → `/_my_implement` or `/_my_plan`
```

## Guidelines

### Anti-Patterns — Avoid These

- **No concept, just components**: If you can't explain the design in one paragraph, it's not ready for parts
- **Implementation code in design**: Save complete scripts, code diffs, and detailed implementations for the plan
- **Unjustified abstractions**: For each new abstraction, articulate what would break without it. If nothing breaks, remove it
- **More components than the problem needs**: Simpler is always better. Ask "would I want to maintain this?"
- **"Technically works" is not good design**: A design that works but is awkward, unintuitive, or fragile is a bad design
- **Solving the wrong problem**: If you're drawn to a more "interesting" adjacent problem, check yourself against the spec

### Critical Requirements
- Read spec FULLY before starting, especially business goals
- Use `Task` tool with `subagent_type=Explore` for complex codebase searches
- Present alternatives when approach is uncertain
- Get user approval on major decisions
- Include specific file:line references
- Never use placeholder values

### Design Quality
- Articulates what the system IS, not just what files to create
- Explains interfaces, data flows, and WHY decisions were made
- Every abstraction earns its existence
- Code in design: interfaces/schemas/pseudo-code only, ~10 lines max per snippet

### Iterative Approach
- **Adapt to complexity**: Simple tasks need less detail, complex tasks need more iteration
- **Research thoroughly**: Don't guess - explore codebase and search for information
- **Progressive refinement**: Add detail in multiple passes, one component at a time
- **Continuous updates**: Keep document current as decisions emerge
- **Minimize redundancy**: Use references instead of duplicating information

### Error Handling
- If spec doesn't exist: STOP and ask user to create it (suggest `/_my_spec`)
- If approach uncertain: Present options to user
- If codebase integration unclear: Use Explore subagent

### Success Criteria
- Core concept is clear and justified — not just "works"
- Complexity is proportional to the problem
- Addresses all spec requirements; serves the business goals
- Can be understood by developers unfamiliar with the codebase
- Architecture, data flows, and rationale clearly described
- Existing code thoroughly analyzed with specific references
- Passed self-review gate before presentation to user
- No unresolved technical questions

---

**Related Commands:**
- Before design: `/_my_research` or `/_my_spec`
- After design: `/_my_implement` or `/_my_plan` for implementation

**Last Updated**: 2026-04-13
