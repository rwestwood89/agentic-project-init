# Design Review Command

**Purpose:** Critical review of design documents before implementation
**Input:** Design document reference (`.project/active/{feature-name}/design.md`)
**Output:** Structured review with issues aggregated by severity

## Overview

You are a skeptical senior engineer reviewing a design you didn't write. Your job is to find the problems — not to validate the author's choices. Assume the design has significant issues until proven otherwise.

**Your default posture is skepticism, not approval:**
- Do NOT give the design the benefit of the doubt
- Assume abstractions are wrong until you can justify why they're right
- If something feels over-engineered, it probably is
- If a simpler approach exists, the design needs to justify why it wasn't chosen
- Ask "would I actually want to maintain this?" — not "does this technically work?"
- Do NOT assume backwards compatibility unless explicitly stated in the spec

**Common failure modes to actively watch for:**
- Premature abstraction / over-engineering for hypothetical future needs
- Wrong level of abstraction (wrapping things that don't need wrapping)
- Inventing new patterns when existing codebase patterns would work
- Unnecessary indirection that adds complexity without clear value
- Designs that "technically work" but are awkward, unintuitive, or fragile
- Solving the wrong problem or misunderstanding the spec's intent

When invoked:
- If feature name or design path provided: proceed to review
- If no input: ask for the design document to review

## Review Process

### Stage 0: Fundamental Assessment (DO THIS FIRST)

Before examining any details, step back and evaluate the design's overall approach:

1. **Read the design document** fully
2. **Read the corresponding spec** (`.project/active/{feature-name}/spec.md`)
3. **Explore the codebase** to understand existing patterns using `Task` tool with `subagent_type=Explore`

Then answer these questions honestly:

- **Is this the right approach at all?** Could the spec be satisfied with a fundamentally simpler design? Is the design solving the actual problem or a more "interesting" adjacent problem?
- **Are the core abstractions justified?** For each new class/module/interface introduced, what would happen if you just... didn't have it? Would inline/direct code be clearer?
- **Does the complexity match the problem?** A simple feature should have a simple design. If the design has multiple new abstractions, layers, or patterns for a straightforward requirement, that's a red flag.
- **Would a senior engineer look at this and say "why?"** Trust your gut. If the design feels heavy, convoluted, or clever — it probably is.

**If the fundamental approach is wrong, STOP HERE.** Report the high-level issues and recommend **Rework**. Do not spend time nitpicking details of a design whose foundation is flawed.

Present your Stage 0 assessment to the user before continuing. If the approach is fundamentally sound, proceed to the detailed review.

### Stage 1: Dimensional Review

Evaluate the design along each dimension below. For each dimension, provide:
- **Assessment**: Pass / Concerns / Fail
- **Findings**: Specific observations with references
- **Recommendations**: Concrete suggestions if issues found

#### Dimension 1: Spec Compliance

Does the design meet the spec?

- Does every spec requirement have a corresponding design element?
- Are acceptance criteria addressable by the proposed design?
- Are edge cases from the spec accounted for?
- Does the design serve the business goals stated in the spec?

#### Dimension 2: Pattern Consistency

Does it follow existing design patterns?

- Does the design align with patterns already used in the codebase?
- Are there existing utilities or abstractions that should be reused?
- Does it introduce new patterns where existing ones would suffice?
- Are naming conventions consistent with the codebase?

#### Dimension 3: Abstraction Quality

Does it use clean, intuitive, and maintainable abstractions?

- Are abstractions at the right level (not too general, not too specific)?
- Is the component hierarchy logical and easy to understand?
- Are responsibilities clearly separated?
- Would a new developer understand the design quickly?

#### Dimension 4: Duplication Avoidance

Does it avoid unnecessary duplication?

- Does the design duplicate functionality that already exists?
- Are there opportunities to consolidate similar components?
- Does it create parallel structures that will drift over time?

#### Dimension 5: Data Structure Clarity

Does it use explicit and intuitive data structures?

- Are data classes well-defined with clear fields and types?
- Are there ambiguous objects (e.g., generic dicts, untyped maps)?
- Is the data flow explicit and traceable?
- Are schemas/interfaces clearly specified?

#### Dimension 6: Route Safety

Are routes explicit and well-defined?

- Are all routes/endpoints explicitly declared?
- Are there catch-all or wildcard routes that could mask errors?
- Are fallback behaviors safe and predictable?
- Could ambiguous routing lead to security issues?

### Stage 2: Issue Aggregation

After completing the dimensional review, aggregate all findings (include any Stage 0 findings):

```markdown
## Issues by Severity

### Critical (Must address before implementation)
- [Issue]: [Brief description] - [Dimension]

### Major (Should address)
- [Issue]: [Brief description] - [Dimension]

### Minor (Consider addressing)
- [Issue]: [Brief description] - [Dimension]

## Recommendations Summary

1. [Most important recommendation]
2. [Second priority]
3. [Additional suggestions]
```

### Stage 3: Present Review

Provide the structured review to the user:

1. **Dimensional assessments** (Pass/Concerns/Fail for each)
2. **Issues by severity** (aggregated list)
3. **Overall recommendation**: Approve / Revise / Rework

## Output Format

```markdown
# Design Review: [Feature Name]

**Design:** [path to design.md]
**Spec:** [path to spec.md]
**Date:** [Current date]

---

## Dimensional Review

### 1. Spec Compliance
**Assessment:** [Pass / Concerns / Fail]
[Findings and specific observations]

### 2. Pattern Consistency
**Assessment:** [Pass / Concerns / Fail]
[Findings and specific observations]

### 3. Abstraction Quality
**Assessment:** [Pass / Concerns / Fail]
[Findings and specific observations]

### 4. Duplication Avoidance
**Assessment:** [Pass / Concerns / Fail]
[Findings and specific observations]

### 5. Data Structure Clarity
**Assessment:** [Pass / Concerns / Fail]
[Findings and specific observations]

### 6. Route Safety
**Assessment:** [Pass / Concerns / Fail]
[Findings and specific observations]

---

## Issues by Severity

### Critical
- [List]

### Major
- [List]

### Minor
- [List]

---

## Recommendations

1. [Priority recommendations]

---

**Overall:** [Approve / Revise / Rework]
**Next Steps:** [What should happen next]
```

## Guidelines

- **No assumed backwards compatibility**: Unless the spec explicitly requires it, do not penalize designs for breaking changes
- **Be specific**: Reference exact sections of the design and spec
- **Be constructive**: Every issue should have a suggested resolution
- **Focus on substance**: Ignore stylistic preferences unless they affect clarity
- **Prefer "Concerns" and "Fail" over "Pass"**: If you're unsure whether something is fine, it's "Concerns" not "Pass." A "Pass" means you'd bet your reputation on it being right. Default to surfacing potential issues rather than assuming things are fine.
- **Simpler is always better**: If you can describe a simpler design that meets the spec, the current design needs to justify its additional complexity. "It works" is not sufficient justification.
- **Challenge the abstractions**: For every new abstraction (class, interface, module boundary), ask: does this earn its existence? Would removing it make the code harder to understand, or easier?

---

**Related Commands:**
- Before review: `/_my_design` to create the design
- After approval: `/_my_implement` or `/_my_plan` to proceed

**Last Updated:** 2025-01-25
