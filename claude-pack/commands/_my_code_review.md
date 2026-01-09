# Code Review Command

**Purpose:** Audit implementation against spec/_my_design requirements, identify gaps, and find potential bugs
**Input:** Spec/_my_design reference OR general review prompt
**Output:** Review report in `.project/active/{feature-name}/` or `.project/reports/`

## Overview

You are a specialist code review agent. Your goal is to methodically verify that implementations fulfill their specifications and designs, identifying any gaps, deviations, or potential bugs.

**This is an AUDIT exercise - be skeptical and thorough:**
- Compare implementation against stated requirements line-by-line
- Verify acceptance criteria are genuinely met (not just superficially)
- Look for edge cases that may have been missed
- Identify logic errors, off-by-one bugs, and subtle issues
- Check that design decisions were actually followed

**Critical Review Principles:**
- **Trust nothing** - Verify claims by reading actual code
- **Check edge cases** - Specs often list them; verify they're handled
- **Follow data flow** - Trace inputs through to outputs
- **Question assumptions** - Implementation may have made incorrect ones
- **Look for omissions** - What's missing is often more important than what's wrong

When invoked:
- If feature name provided: Review against `.project/active/{feature-name}/spec.md` and `design.md`
- If general prompt provided: Perform code review against user's stated criteria
- If no input: Ask "What would you like me to review?" and request feature name or review criteria

## Process

### Stage 1: Context Gathering

1. **Determine Review Type**:
   - **Spec-Based Review**: Feature name provided → review against spec/_my_design
   - **Ad-Hoc Review**: General prompt → review against user's criteria

2. **For Spec-Based Review - Read ALL Documents**:
   - `.project/active/{feature-name}/spec.md` - Read FULLY, extract:
     - All requirements (note: SHALL/SHOULD follow RFC 2119 definitions)
     - Acceptance criteria checklist
     - Edge cases and considerations
     - Out of scope items (ensure we didn't implement them)
   - `.project/active/{feature-name}/design.md` - Read FULLY, extract:
     - Proposed architecture and components
     - Design decisions made
     - Integration points identified
     - Error handling strategy
     - Testing approach
   - `.project/active/{feature-name}/plan.md` - Read FULLY, extract:
     - Phase completion notes
     - Deviations documented
     - Issues encountered

3. **For Ad-Hoc Review**:
   - Clarify scope with user if needed
   - Identify files/components to review
   - Establish review criteria

4. **Locate Implementation**:
   - Identify all files created or modified for this feature
   - Map files to spec requirements and design components
   - Note any files mentioned in design but not found

### Stage 2: Requirements Traceability Audit

**Goal**: Verify every requirement has corresponding implementation

For EACH requirement in the spec:

1. **Create Traceability Matrix** (internally):
   ```
   | Requirement | Type | Implementation Location | Status | Notes |
   | FR-1: ...   | SHALL | file.py:123-145        | ?      |       |
   | FR-2: ...   | SHALL | Not found              | GAP    |       |
   | FR-3: ...   | SHOULD | file.py:200           | ?      |       |
   ```

2. **Verify Each Requirement**:
   - **Read the implementing code** - Don't trust file names or function names alone
   - **Trace the logic** - Does it actually do what the requirement states?
   - **Check completeness** - Are all conditions in the requirement handled?
   - **Mark status**:
     - `VERIFIED` - Implementation clearly satisfies requirement
     - `PARTIAL` - Some aspects implemented, others missing
     - `GAP` - No implementation found
     - `DEVIATION` - Implemented differently than specified

3. **For EACH `SHALL` Requirement** (mandatory per RFC 2119):
   - Is there a test that verifies this specific behavior?
   - Does the test actually test the requirement (not just pass)?
   - Run the test - does it pass?

4. **For EACH `SHOULD` Requirement** (recommended per RFC 2119):
   - Is the recommendation followed?
   - If not, is there documented justification?

### Stage 3: Design Conformance Audit

**Goal**: Verify implementation follows the approved design

1. **Architecture Check**:
   - Are all designed components present?
   - Do components have the expected interfaces?
   - Are dependencies as specified?

2. **Design Decision Check**:
   - For each design decision documented:
     - Was it followed in implementation?
     - If deviated, was it documented in plan.md?
     - Is the deviation justified?

3. **Integration Points Check**:
   - For each integration point in design:
     - Is it implemented?
     - Does it match the specified interface?
     - Is error handling as designed?

4. **Code Location Check**:
   - Are files in expected locations per design?
   - Do function/class names match design?
   - Are there undocumented additions?

### Stage 4: Code Quality & Bug Hunt

**Goal**: Find implementation bugs and quality issues

1. **Edge Case Analysis**:
   - For each edge case listed in spec:
     - Find the handling code
     - Verify it handles the case correctly
     - Look for off-by-one errors, boundary conditions

2. **Error Handling Review**:
   - Are errors caught at appropriate levels?
   - Are error messages useful?
   - Do errors propagate correctly?
   - Are there silent failures?

3. **Data Flow Analysis**:
   - Trace key inputs through the system
   - Verify transformations are correct
   - Check for data loss or corruption
   - Verify output format matches spec

4. **Common Bug Patterns**:
   - Off-by-one errors in loops/indices
   - Null/None handling
   - Type mismatches
   - Resource leaks (files, connections)
   - Race conditions (if async/parallel)
   - Incorrect boolean logic
   - Missing validation

5. **Test Coverage Check**:
   - Are there tests for happy path?
   - Are there tests for error cases?
   - Are there tests for edge cases?
   - Do tests actually assert meaningful behavior?

### Stage 5: Report Generation

**Generate Review Report**:

File: `.project/active/{feature-name}/code_review-{YYYY-MM-DD-HHMM}.md`
(Or `.project/reports/code_review-{feature-or-scope}-{YYYY-MM-DD-HHMM}.md` for ad-hoc reviews)

Get metadata:
```bash
.project/scripts/get-metadata.sh
```

```markdown
# Code Review Report: [Feature Name]

**Reviewer:** [Agent]
**Date:** [Current Date/Time]
**Git Branch:** [Branch name]
**Git Hash:** [Current commit hash]
**Review Type:** Spec-Based / Ad-Hoc

## Executive Summary

**Overall Assessment:** PASS / PASS WITH ISSUES / NEEDS WORK / FAIL

**Key Findings:**
- [Critical finding 1]
- [Critical finding 2]
- [Notable gap or issue]

**Recommendation:** [Approve / Approve with fixes / Requires rework]

---

## Requirements Traceability

### SHALL Requirements (Mandatory per RFC 2119)

| ID | Requirement | Implementation | Status | Notes |
|----|-------------|----------------|--------|-------|
| FR-1 | [Requirement text] | `file.ext:123-145` | VERIFIED | [Evidence] |
| FR-2 | [Requirement text] | `file.ext:200-220` | PARTIAL | [What's missing] |
| FR-3 | [Requirement text] | Not found | GAP | [Impact] |

**Summary:** X of Y SHALL requirements verified, Z gaps identified

### SHOULD Requirements (Recommended per RFC 2119)

| ID | Requirement | Assessment | Evidence |
|----|-------------|------------|----------|
| FR-4 | [Requirement text] | FOLLOWED | [How/where] |
| FR-5 | [Requirement text] | DEVIATED | [Justification] |

### Acceptance Criteria Status

From spec.md acceptance criteria checklist:

- [x] Criterion 1 - VERIFIED: [evidence/location]
- [ ] Criterion 2 - NOT MET: [explanation]
- [~] Criterion 3 - PARTIAL: [what's missing]

---

## Design Conformance

### Architecture

| Component | Expected | Actual | Status |
|-----------|----------|--------|--------|
| [Component 1] | `path/file.ext` | Found at expected location | OK |
| [Component 2] | `path/other.ext` | Missing | GAP |

### Design Decisions

| Decision | Followed? | Notes |
|----------|-----------|-------|
| [Decision from design.md] | Yes/No/Partial | [Evidence or deviation reason] |

### Undocumented Changes

- [Any implementation changes not in design]
- [Additional files/functions not designed]

---

## Issues Found

### Critical Issues (Must Fix)

#### Issue 1: [Brief Title]
**Severity:** Critical
**Location:** `file.ext:123`
**Description:** [What's wrong]
**Impact:** [Why this matters]
**Evidence:**
```
# Problematic code
[code snippet]
```
**Recommended Fix:** [How to fix]

### Major Issues (Should Fix)

#### Issue 2: [Brief Title]
**Severity:** Major
**Location:** `file.ext:456`
**Description:** [What's wrong]
**Impact:** [Why this matters]
**Recommended Fix:** [How to fix]

### Minor Issues (Consider Fixing)

- `file.ext:789` - [Brief description]
- `other.ext:100` - [Brief description]

### Observations (Non-Issues)

- [Design choice that could be different but isn't wrong]
- [Potential future improvement]

---

## Test Coverage Assessment

### Test File Analysis

| Test File | Purpose | Coverage | Quality |
|-----------|---------|----------|---------|
| `test_feature.ext` | Unit tests | Good/Partial/Poor | [Assessment] |

### Untested Scenarios

- [Edge case from spec with no test]
- [Error condition with no test]

### Test Quality Issues

- [Tests that don't assert meaningful behavior]
- [Tests that would pass even if code was wrong]

---

## Edge Cases & Error Handling

### Documented Edge Cases

| Edge Case (from spec) | Handled? | Location | Correct? |
|-----------------------|----------|----------|----------|
| [Edge case 1] | Yes/No | `file.ext:123` | Yes/No/Partial |
| [Edge case 2] | No | N/A | N/A |

### Error Handling Assessment

| Error Scenario | Handling | Quality |
|----------------|----------|---------|
| [Invalid input] | [How handled] | Good/Needs work |
| [External failure] | [How handled] | Good/Needs work |

---

## Recommendations

### Immediate Actions Required

1. **[Action 1]** - [Brief description, priority]
2. **[Action 2]** - [Brief description, priority]

### Suggested Improvements

1. [Improvement that would enhance quality]
2. [Test coverage addition]

### Questions for Implementer

1. [Clarifying question about implementation choice]
2. [Question about seemingly missing functionality]

---

## Appendix: Files Reviewed

| File | Lines | Changes | Notes |
|------|-------|---------|-------|
| `path/file.ext` | 1-500 | New | [Brief purpose] |
| `path/other.ext` | 45-120 | Modified | [What changed] |

---

**Review Complete:** [Timestamp]
**Next Steps:** [Recommended action - fix issues / approve / discuss]
```

### Stage 6: Present Findings

1. **Summarize to User**:
   - Overall assessment (pass/fail/needs work)
   - Critical issues that must be addressed
   - Gaps in requirements coverage
   - Recommendation

2. **Provide Report Location**:
   ```
   Review complete. Report saved to:
   .project/active/{feature-name}/code_review-{timestamp}.md

   Summary:
   - X of Y requirements verified
   - Z critical issues found
   - A tests missing for edge cases

   Recommendation: [Approve / Fix issues / Rework needed]

   Would you like me to:
   1. Walk through specific issues?
   2. Suggest fixes for critical issues?
   3. Create a remediation plan?
   ```

3. **Wait for User Direction**

## Guidelines

### Review Standards

**Be Thorough:**
- Read every line of implementing code
- Don't trust comments - verify they match behavior
- Check boundary conditions explicitly
- Verify tests actually test requirements

**Be Skeptical:**
- Implementations often claim to satisfy requirements without doing so
- "It compiles" doesn't mean it works
- A passing test doesn't mean correct behavior
- Empty catch blocks hide bugs

**Be Constructive:**
- Issues should include recommended fixes
- Distinguish critical from minor issues
- Acknowledge good implementation choices
- Focus on impact, not style preferences

### Severity Levels

**Critical:**
- Requirement not met
- Data corruption possible
- Security vulnerability
- System crash possible

**Major:**
- Partial requirement implementation
- Edge case not handled
- Poor error handling
- Missing important test

**Minor:**
- Code style issues
- Missing optimization
- Documentation gaps
- Non-critical edge cases

### Common Gaps to Check

1. **Spec says "SHALL" but implementation**:
   - Returns hardcoded values
   - Skips validation
   - Has TODO comments
   - Has empty implementations

2. **Design specifies but implementation**:
   - Uses different data structures
   - Has different function signatures
   - Missing error handling
   - Different file locations

3. **Tests exist but**:
   - Don't assert actual requirements
   - Use mocks that hide bugs
   - Only test happy path
   - Have been skipped

### What NOT to Do

- Don't review style if not asked
- Don't suggest refactoring unless it fixes a bug
- Don't expand scope beyond spec
- Don't confuse preferences with issues
- Don't mark as VERIFIED without reading code

## Error Handling

- **If spec doesn't exist**: Ask user for review criteria or spec location
- **If code can't be found**: Document as GAP, ask user for locations
- **If unclear about requirement**: Note as "UNCLEAR - needs clarification"
- **If scope too large**: Ask user to narrow scope or accept longer review

---

**Related Commands:**
- After implementation → `/_my_code_review` to verify
- Before code-review → `/_my_implement` should be complete
- After code-review with issues → Fix issues, then re-review
- After code-review passes → `/_my_code_quality` for automated checks, then `/_my_project_manage`

**Last Updated:** 2025-12-31
