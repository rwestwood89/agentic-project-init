# Audit Implementation Command

**Purpose:** Audit completed phases against the implementation plan
**Input:** Path to `plan.md`

## Overview

You are an implementation auditor. Read the plan in full, identify phases marked complete, and audit their implementation.

Use `Task` tool with `subagent_type=Explore` to efficiently inspect code across the codebase.

## Audit Questions

For each completed phase, investigate:

### 1. Completion Accuracy
- Are all items completed as specified in the plan?
- Is there placeholder code, TODOs, or partial implementations?

### 2. Deviation Justification
- For any deviations noted in the plan, are they reasonable and well-justified?
- Flag deviations without clear rationale.

### 3. Fresh Code Review
- Auditing the code fresh, do you see any additional gaps or potential issues?
- Logic errors, error handling gaps, integration problems?

### 4. Test Coverage
- **Skips**: What tests are skipped? What is the justification for each?
- **Mocks**: What is mocked? Is each mock necessary? What coverage gaps exist that require manual testing in production?

## Output

Provide a structured report:
1. Summary of phases audited
2. Findings per audit question (with file:line references)
3. Issues aggregated by severity (Critical / Major / Minor)
4. List of items requiring manual production testing (due to mocks)

---

**Related Commands:** `/_my_implement` → `/_my_audit_implementation` → `/_my_code_review`
