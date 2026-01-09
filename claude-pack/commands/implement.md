# Implement Command

**Purpose:** Execute approved implementation plan with understanding and validation
**Input:** `.project/active/{feature-name}/plan.md` (plus design.md, spec.md)
**Output:** Code changes, updated plan with progress

## Overview

Execute implementation according to approved plan with careful validation and progress tracking.

**CRITICAL: Do NOT blindly follow the plan.** Before implementing, you MUST thoroughly understand:
- The design rationale (WHY things are structured this way)
- The spec requirements (WHAT outcomes are expected)
- The codebase context (HOW this integrates with existing code)

When invoked:
- If feature name provided: proceed to implementation
- If no feature: ask "Which feature should I implement?" and request feature name

## Process

### Stage 0: Understanding Before Action

**This stage is MANDATORY. Do not skip to implementation.**

1. **Read Design Document**: `.project/active/{feature-name}/design.md` FULLY
   - Understand the architecture and component relationships
   - Understand WHY decisions were made (check Design Decisions section)
   - Note the integration points and patterns to follow

2. **Read Spec Document**: `.project/active/{feature-name}/spec.md` FULLY
   - Understand the business goals and success criteria
   - Note all requirements (distinguish user-provided vs inferred)
   - Understand acceptance criteria

3. **Offer Codebase Exploration**:
   ```
   Before I begin implementing, would you like me to explore any parts of
   the codebase to deepen my understanding?

   I can investigate:
   - Existing patterns similar to what we're building
   - Integration points mentioned in the design
   - Test patterns to follow

   Or say "proceed" to start implementation.
   ```

   If user requests exploration, use `Task` tool with `subagent_type=Explore`.

### Stage 1: Plan Analysis & Scope Confirmation

1. **Read Plan**: `.project/active/{feature-name}/plan.md` FULLY
2. **Check Progress**: Look for existing checkmarks
3. **Confirm Scope** - ALWAYS ask unless user specified:
   ```
   I've read the plan. Please choose execution approach:

   **Available Phases:**
   - Phase 1: [What it accomplishes]
   - Phase 2: [What it accomplishes]

   Choose:
   1. **One-by-one** (implement one phase, get approval, proceed)
   2. **Multiple phases** (specify which phases)
   3. **All phases** (implement all without stopping)

   Default: one-by-one for safety
   ```
   If you see boxes checked, confirm where you should pick up implementation.

4. **Create TodoWrite** - Mirror plan with individual tasks

### Stage 2: Sequential Implementation

1. **Start with Tests** - Implement test stencil first if provided
2. **Execute Changes** - Use Read, Edit, Write tools systematically
3. **Think Critically** - As you implement, continuously ask:
   - Does this serve the business goals in the spec?
   - Does this follow the design rationale?
   - Am I catching edge cases the plan might have missed?
4. **Verify Each Change** - Test as you go
5. **Update Progress** - Check off in TodoWrite and plan
6. **Handle Deviations** - Present clearly:
   ```
   Issue in Phase [N]:
   Expected: [plan says]
   Found: [actual]
   Impact: [why matters]

   How should I proceed?
   ```

### Stage 3: Phase Completion & Validation

1. **Run Automated Verification**:
   - Run tests per CLAUDE.md and project conventions
   - Run linting/quality checks per project conventions
   - Verify integration with existing code

2. **MANDATORY: Update Plan Document**:
   Add to plan under "Implementation Notes":
   ```markdown
   ### Phase [N] Completion
   **Completed:** [Date/Time]
   **Changes Made:**
   - Created `path/to/new_file.ext` with main_function()
   - Modified `path/to/existing.ext:45` to add parameter
   - Added tests in `tests/test_feature.ext`

   **Issues Encountered:**
   - [Issue and how it was resolved]

   **Deviations from Plan:**
   - [What changed and why]
   ```

3. **MANDATORY: Synchronize Status**:
   - Mark spec status: "Implementation In Progress" or "Complete"
   - Update epic if relevant
   - Update CURRENT_WORK.md if it exists

4. **Checkpoint with User** if failures or deviations

## Guidelines

### ENVIRONMENT (CRITICAL)
- ALWAYS read CLAUDE.md for environment and command conventions FIRST
- Follow project-specific setup, test, and quality check commands
- Do not assume any particular language or framework

### CODE QUALITY (CRITICAL - NEVER VIOLATE)
**NEVER write:**
- Mock tests that don't validate real behavior
- `skip`, `pass`, `TODO` without failing loudly
- Stub functions with hardcoded returns
- Code allowing silent failures

**ALWAYS ensure:**
- Tests validate actual functionality
- Incomplete code raises errors or fails explicitly
- Test assertions check real behavior
- Failures are immediate and obvious

### UNDERSTANDING (CRITICAL - BL-001)
**NEVER:**
- Blindly follow the plan without understanding rationale
- Implement without reading design.md and spec.md
- Skip the codebase exploration offer

**ALWAYS:**
- Understand WHY before implementing WHAT
- Adapt when implementation reveals plan issues
- Think critically about edge cases as you code

### MANDATORY Progress Tracking
**You MUST:**
- Check off completed items in plan immediately
- Add detailed implementation notes to plan
- Document deviations, issues, solutions
- Update TodoWrite list
- Update status in linked spec/design/epic

**FAILURE TO TRACK IS UNACCEPTABLE**

### Implementation Standards
- Follow plan's intent, adapt to reality
- Implement phase fully before next
- Start with tests when provided
- Think critically about file creation (avoid if possible)
- Verify work in broader codebase context

### Error Handling
- STOP immediately if reality differs significantly from plan
- NEVER dismiss issues or skip validations without approval
- Document issues in implementation notes
- Get approval before significant deviations

---

**Related Commands:**
- Before implement: `/design` then `/plan`
- After implement: Manual verification; quality checks; `/project-manage` to complete

**Last Updated**: 2025-12-31
