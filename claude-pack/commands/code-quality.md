# Code Quality Check Command

**Purpose:** Run comprehensive code quality checks and fix issues systematically
**Input:** Current codebase state
**Output:** All tests passing, no quality issues, or documented fixes in `.project/active/`

## Overview

Run automated testing and quality checks, then fix issues systematically. Low-risk issues are fixed directly; medium/high-risk issues are documented for approval before implementation.

**Before starting:** Read CLAUDE.md for project-specific test, lint, and quality commands.

## Process

### Stage 0: Manual Inspection

If requested by the user, use a THOROUGH and DEEP manual inspection of the completion of the work item. Carefully consider potential risks and corner cases. Closely check the completed work against the `plan.md` document. Categorize any issues or potential concerns for Stage 2.

If the user requested a deep review, file a report: `.project/active/{feature-name}/{YYYY-MM-DD-HH-MM}-quality-report.md` with status report, assessment, and actionable recommendations.

### Stage 1: Run All Quality Checks

Execute all checks per CLAUDE.md and collect results:

1. **Testing:**
   - Run project test suite (e.g., `pytest`, `npm test`, `cargo test`)
   - Collect: test failures, error messages, tracebacks

2. **Code Formatting:**
   - Run formatter (e.g., `ruff format`, `prettier`, `rustfmt`)
   - Note: any files that were reformatted

3. **Linting:**
   - Run linter (e.g., `ruff check`, `eslint`, `clippy`)
   - Collect: all violations with file:line references

4. **Type Checking** (if applicable):
   - Run type checker (e.g., `mypy`, `tsc`, `pyright`)
   - Collect: all type errors with file:line references

5. **Project-Specific Checks:**
   - Run any additional checks specified in CLAUDE.md
   - Collect results and violations

### Stage 2: Categorize Issues

Group all issues by risk level:

**Low Risk (Fix Directly):**
- Formatting changes from auto-formatter
- Simple linting fixes: unused imports, undefined names in obvious contexts
- Simple type hints: obvious return types, clear parameter types
- Docstring/comment formatting

**Medium Risk (Document for Approval):**
- Test failures where fix is clear but touches business logic
- Type errors requiring interface changes
- Linting issues requiring refactoring

**High Risk (Document for Approval):**
- Test failures with unclear root cause
- Type errors indicating architectural issues
- Breaking changes to public APIs
- Complex refactoring needs

### Stage 3: Fix Low-Risk Issues

For all low-risk issues:
1. Make the fix directly
2. Verify the fix resolves the issue
3. Report what was fixed

### Stage 4: Document Medium/High-Risk Issues

If any medium or high-risk issues exist:

1. **Create Documentation File:**
   - File: `.project/active/{feature-name}/{YYYY-MM-DD-HHMM}-quality-fixes.md`

2. **Document Each Issue:**
   ```markdown
   # Code Quality Fixes - {Date}

   ## Summary
   - Total Issues: {N}
   - Tests Failing: {N}
   - Type Errors: {N}
   - Linting Issues: {N}

   ## Issues and Proposed Fixes

   ### Issue 1: [Brief Description]
   **Risk Level:** Medium/High
   **Location:** `file/path.ext:123`
   **Issue:**
   ```
   [Full error message or description]
   ```

   **Root Cause:**
   [Analysis of why this is happening]

   **Proposed Fix:**
   - [ ] Step 1: [Specific change needed]
   - [ ] Step 2: [Specific change needed]
   - [ ] Verify: [How to verify the fix]

   **Impact:**
   [What this fix affects, potential side effects]

   **Alternative Approaches:**
   [If applicable, other ways to solve this]

   ---

   ### Issue 2: [Brief Description]
   ...
   ```

3. **Notify User:**
   ```
   Found {N} medium/high-risk issues requiring approval.

   I've documented all issues in:
   .project/active/{feature-name}/{timestamp}-quality-fixes.md

   Please review the proposed fixes and let me know:
   1. If you approve the approach for each issue
   2. If you'd like me to try alternative approaches
   3. If any issues should be deferred

   Once approved, I'll work through them systematically.
   ```

4. **Wait for User Approval**

### Stage 5: Systematic Fix Implementation

Once user approves:

1. **Work Through Each Issue:**
   - Implement fix according to approved approach
   - Check off boxes as completed
   - Add `**UPDATE**` comments after each issue

2. **Verify Each Fix:**
   ```markdown
   ### Issue 1: [Brief Description]
   ...
   - [x] Step 1: Modified `file.ext:123` to use correct type
   - [x] Step 2: Updated tests to match new signature
   - [x] Verify: Ran tests - PASSED

   **UPDATE:** Fix completed successfully. Error resolved, all tests passing.
   ```

3. **Handle Unexpected Results:**
   If a fix doesn't work as expected:
   ```markdown
   **UPDATE:** Initial fix did not resolve the issue.

   **What Happened:**
   [Describe what went wrong]

   **New Analysis:**
   [Updated understanding of the problem]

   **Revised Approach:**
   - [ ] New Step 1: [Revised approach]
   - [ ] New Step 2: [Revised approach]

   Awaiting approval to proceed with revised approach.
   ```

   Then notify user and wait for approval before continuing.

4. **Final Verification:**
   After all fixes, re-run all checks from Stage 1 and confirm all passing.

### Stage 6: Completion Report

Provide summary:
```
Code Quality Check Complete!

- All tests passing ({N} tests)
- No formatting issues
- No linting issues ({N} files checked)
- No type errors
- All project-specific checks passed

Fixes Applied:
- Low risk: {N} issues fixed directly
- Medium/high risk: {N} issues fixed after approval

Documentation: .project/active/{feature-name}/{timestamp}-quality-fixes.md
```

## Risk Assessment Guidelines

**Consider Low Risk if:**
- Change is purely syntactic (formatting, import order)
- Fix is obvious and doesn't change behavior
- Affects only test code (not production)
- No logic changes required

**Consider Medium Risk if:**
- Changes production code logic
- Requires interface modifications
- Affects multiple files
- May have performance implications

**Consider High Risk if:**
- Root cause is unclear
- Fix requires architectural changes
- Breaking changes to APIs
- Multiple interconnected issues
- Potential for cascading failures

## Critical Rules

**ALWAYS:**
- Read CLAUDE.md for project-specific commands first
- Run ALL checks before starting fixes
- Categorize ALL issues before fixing any
- Document medium/high-risk issues BEFORE fixing
- Verify EACH fix individually
- Re-run full suite after all fixes

**NEVER:**
- Skip documenting medium/high-risk issues
- Proceed with unapproved high-risk fixes
- Batch fixes without individual verification
- Dismiss test failures as "flaky"
- Make changes that mask problems instead of fixing them

## Related Commands

- Before quality check → `/implement` (complete feature first)
- After quality check → Commit clean code, create PR
- If major issues found → `/design` or `/plan` (may need design changes)

**Last Updated:** 2025-12-31
