# Spec: Design Command Improvements

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-04-13 12:52 PDT
**Complexity:** MEDIUM
**Branch:** better-design-review

---

## Business Goals

### Why This Matters

The `_my_design` command is the highest-leverage prompt in the workflow. A bad design cascades into a bad plan and broken implementation. Currently the command consistently produces implementation dumps — lists of components with full code — rather than actual conceptual designs. The agent does not think through abstractions or articulate what the system IS before diving into parts lists. The result is "AI slop": components duct-taped together that might technically meet the spec but lack coherent conceptual thinking and are frequently broken.

The design review command (`_my_review_design`) already knows what bad designs look like — premature abstraction, wrong level of abstraction, unnecessary complexity — but the design command doesn't avoid those same mistakes. The review catches problems that the design prompt actively causes.

### Success Criteria

- [ ] Design documents articulate a clear conceptual model before describing components
- [ ] Designs justify their abstractions (each one earns its existence)
- [ ] Design documents stay at the right level of detail — concepts and architecture, not implementation code
- [ ] The agent self-evaluates design quality before presenting to the user
- [ ] Designs are noticeably simpler and more coherent than current outputs

### Priority

High — core workflow quality fix. Subsumes BL-004 ("Update /spec and /design to enforce codebase discovery") from the backlog.

---

## Problem Statement

### Current State

The `_my_design` command (`claude-pack/commands/_my_design.md`) follows a SETUP -> RESEARCH -> REFINE -> REFLECT cycle, but:

1. **No conceptual thinking phase.** REFINE goes directly to "Draft/update Proposed Design section" with bullets about components. The agent never articulates what the system IS.

2. **Template rewards enumeration.** The expected output structure asks for "detailed component sections with: Purpose, location, functions/classes, Dependencies, data flows, Implementation notes with file:line references." This produces shopping lists, not designs.

3. **Code examples dominate.** Despite a one-liner saying "code examples are secondary," the template asks for implementation notes and usage examples. Real outputs contain 700+ lines of bash scripts in the "Proposed Design" section.

4. **REFLECT rewards completeness, not quality.** OUTCOME (c) requires "All components have sufficient technical detail for implementation." This pushes toward MORE detail, not BETTER thinking. No criteria ask "is this too complex?" or "could this be simpler?"

5. **No simplicity or abstraction quality checks anywhere.** The agent is never asked whether its abstractions are justified, whether a component could be removed, or whether the complexity matches the problem.

6. **No self-review.** The agent proceeds straight from the REFLECT cycle to finalization without ever re-reading its own document critically.

Evidence from real outputs:
- `simplified-setup-system/design.md`: 1005 lines, ~700 of which are complete bash scripts. Five "components" that are just five scripts with full implementations.
- `hook-path-resolution/design.md`: Five "components" that are really just code diffs for each file.
- `ralph-resilience/design.md`: The best output — actually has a conceptual insight ("three orthogonal concerns") — but still drifts into excessive implementation detail.

### Desired Outcome

The design command produces documents that:
- Lead with a clear conceptual model in plain language
- Describe architecture as relationships between parts, not code listings
- Justify each abstraction and design decision with rationale
- Stay at the design level, deferring implementation detail to the plan phase
- Self-evaluate quality before presenting to the user

---

## Scope

### In Scope

All changes are to a single file: `claude-pack/commands/_my_design.md`

1. Add a mandatory "Core Concept" phase to the design process
2. Add simplicity and abstraction quality criteria to the REFLECT step
3. Restructure the design document template
4. Add explicit anti-patterns section
5. Add a distinct self-review gate (new stage) before finalization
6. Add a code-cap rule

### Out of Scope

- Changes to `_my_review_design.md` (already effective)
- Changes to `_my_spec.md`, `_my_plan.md`, or `_my_implement.md`
- Rewriting existing design documents
- Changes to the `.project/` directory structure or templates
- Adding new tools or subagents

### Edge Cases & Considerations

- Simple features (e.g., add-ralph) may need less conceptual framing than complex features. The prompt should adapt to complexity rather than imposing heavy ceremony on trivial tasks.
- The self-review gate should not cause the agent to loop indefinitely. It should be a single-pass critical read, not another iterative cycle.
- Some designs legitimately need code snippets (e.g., interface definitions, data structure schemas). The code cap should limit quantity and type, not ban code entirely.

---

## Requirements

### Functional Requirements

#### FR-1: Mandatory "Core Concept" Phase

> From user's analysis and request

1. **FR-1.1**: The design process MUST include a "Core Concept" step that occurs AFTER research and BEFORE component/architecture enumeration.
2. **FR-1.2**: In this step, the agent MUST articulate:
   - A plain-language description (one paragraph) of what the system IS and how it works conceptually
   - The key insight or principle that makes the design work
   - Why this approach is the right one, not just a working one
3. **FR-1.3**: The agent MUST NOT begin describing components, architecture details, or implementation until the Core Concept is articulated.
4. **FR-1.4**: The Core Concept MUST be written into the design document as the first substantive section (after Overview and Related Artifacts).

#### FR-2: Simplicity Gate in REFLECT

> From user's analysis and request

1. **FR-2.1**: The REFLECT step MUST include simplicity and abstraction quality questions as first-class evaluation criteria.
2. **FR-2.2**: The following questions (or equivalent) MUST be added to REFLECT:
   - "Could this be done with fewer moving parts? What is the minimum viable design?"
   - "For each new abstraction (component, module, class, interface): what happens if I just don't have it? Would inline/direct code be clearer?"
   - "Am I solving the spec's actual problem, or a more 'interesting' adjacent problem?"
   - "Does the complexity of this design match the complexity of the problem? A simple problem SHOULD have a simple design."
3. **FR-2.3**: The OUTCOME (c) exit criteria MUST be updated to include simplicity/abstraction quality alongside completeness. A design that is complete but over-engineered MUST NOT pass.
4. **FR-2.4**: The existing OUTCOME (c) criterion "All components have sufficient technical detail for implementation" SHOULD be softened or removed, as it drives toward implementation-level detail in the design.

#### FR-3: Restructured Design Document Template

> From user's analysis and request

1. **FR-3.1**: The design document template MUST be restructured to separate conceptual design from implementation guidance.
2. **FR-3.2**: The new template structure MUST include these sections in this order:
   - **Core Concept** — Plain-language description of the approach, key insight, why this is right
   - **Architecture** — How parts relate to each other; focused on relationships, data flows, and boundaries, not code
   - **Key Decisions** — Major design choices with rationale, trade-offs, and alternatives considered
   - **Component Overview** — Brief description of each part without implementation detail
   - **Implementation Notes** — Short section with only critical gotchas, patterns to follow, and constraints for the plan phase
3. **FR-3.3**: The old monolithic "Proposed Design" section (which encouraged component enumeration with full code) MUST be replaced by this structure.
3. **FR-3.4**: The "Research Findings" section SHOULD be retained as-is (it works well).
4. **FR-3.5**: The "Potential Risks," "Integration Strategy," and "Validation Approach" sections SHOULD be retained in finalization.

#### FR-4: Explicit Anti-Patterns

> From user's analysis; sourced from `_my_review_design.md` failure modes

1. **FR-4.1**: The design command MUST include an explicit anti-patterns section that the agent is instructed to avoid.
2. **FR-4.2**: The anti-patterns MUST include at minimum:
   - Don't enumerate components without a unifying concept — if you can't explain the design in one paragraph, it's not ready
   - Don't write implementation code in the design — save it for the plan
   - Don't introduce abstractions that don't earn their existence — for each one, articulate what would break without it
   - Don't produce more components than the problem actually needs
   - Don't confuse "technically works" with "good design" — ask "would I want to maintain this?"
   - Don't solve a more "interesting" adjacent problem instead of the actual spec

#### FR-5: Self-Review Gate Before Finalization

> From user's analysis and request

1. **FR-5.1**: A distinct self-review stage MUST be added between the iterative cycle (Stage 2) and finalization (Stage 3). This is a new stage, not part of REFLECT.
2. **FR-5.2**: In this stage, the agent MUST re-read the complete design document from disk before evaluating.
3. **FR-5.3**: The self-review MUST evaluate the design against these questions (drawn from `_my_review_design` Stage 0):
   - Is this the right approach at all? Could the spec be satisfied with a fundamentally simpler design?
   - Are the core abstractions justified? For each new component/module/interface, what would happen if it didn't exist?
   - Does the complexity match the problem? A simple feature should have a simple design.
   - Would a senior engineer look at this and say "why?"
4. **FR-5.4**: If the self-review identifies significant issues, the agent MUST loop back to the iterative cycle to address them, not proceed to finalization.
5. **FR-5.5**: The self-review SHOULD be a single-pass critical read, not a new iterative cycle. If the design fails self-review, one revision cycle should be attempted before escalating to the user.

#### FR-6: Code Cap Rule

> From user's analysis and request

1. **FR-6.1**: The design command MUST include an explicit rule limiting code in the design document.
2. **FR-6.2**: Code snippets in the design SHOULD be limited to approximately 10 lines per snippet.
3. **FR-6.3**: Permitted code in the design MUST be limited to: interface definitions, data structure schemas, type signatures, and short pseudo-code that clarifies a concept.
4. **FR-6.4**: Full implementations, complete scripts, and detailed code diffs MUST NOT appear in the design document — these belong in the plan or implementation phase.
5. **FR-6.5**: The agent SHOULD be instructed: "If you're writing more than ~10 lines of code in the design, you're writing implementation, not design. Stop and describe the concept instead."

### Non-Functional Requirements

1. **NFR-1**: The revised prompt MUST adapt to task complexity — simple tasks should not require heavy conceptual ceremony. The existing guidance "Adapt your effort to task complexity" SHOULD be retained and reinforced.
2. **NFR-2**: The revised prompt MUST NOT significantly increase the length of the design command file. Concise, pointed instructions are more effective than verbose ones.
3. **NFR-3**: The design process MUST still support user decision checkpoints (OUTCOME a) and iterative research (OUTCOME b) as it does today.

---

## Acceptance Criteria

### Core Functionality

- [ ] Design command includes a mandatory Core Concept phase before component enumeration
- [ ] REFLECT step includes simplicity and abstraction quality criteria
- [ ] Design document template has the new 5-section structure (Core Concept, Architecture, Key Decisions, Component Overview, Implementation Notes)
- [ ] Anti-patterns section is present and includes all items from FR-4.2
- [ ] Self-review gate exists as a distinct stage that re-reads the document from disk
- [ ] Code cap rule is explicitly stated in the prompt

### Quality & Integration

- [ ] Running `/_my_design` on a new feature produces a document with a clear Core Concept section
- [ ] Design documents are noticeably shorter (less code, more concepts) compared to current outputs
- [ ] The self-review gate catches over-engineering before the user sees it
- [ ] Simple tasks still get proportionally simple treatment (no heavy ceremony for trivial features)
- [ ] The design command file remains a reasonable length (not bloated with redundant instructions)

---

## Related Artifacts

- **Design Target:** `claude-pack/commands/_my_design.md` (the file being improved)
- **Reference:** `claude-pack/commands/_my_review_design.md` (source for anti-patterns and self-review criteria)
- **Backlog:** BL-004 in `.project/backlog/BACKLOG.md` (subsumed by this work)
- **Evidence:** Design outputs in `.project/active/simplified-setup-system/design.md`, `.project/active/hook-path-resolution/design.md`, `.project/active/ralph-resilience/design.md`

---

**Next Steps:** After approval, proceed to `/_my_design`
