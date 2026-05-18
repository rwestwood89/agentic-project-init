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

### 4. Abstraction Quality (slop detection)

Flag these as **design problems to fix now**, not code-review nitpicks to defer. Implementation agents inject slop when the design leaves ambiguity — your job is to catch it before the feature lands.

Red flags to look for:

- **God functions with implicit modes**: one function doing 2+ unrelated jobs selected by a sentinel parameter (e.g., `None`, a flag bool). The telltale: parameters that only matter in some internal branches, or a signature you can't summarize in one sentence without "or".
- **Policy in utilities**: a utility function making decisions about warnings, clipping, fallbacks, defaults, or error handling that should live at the call site where the reader can see the decision.
- **Parameter sprawl**: a function whose parameter list accreted to serve multiple callers with different needs, instead of each caller getting the function it actually needs.
- **Leaky names**: a function name implies a narrow operation but the implementation handles several (e.g., a `splice_*` helper that also seeds cold starts).
- **Deep nesting (3+ levels)**: usually two functions glued together.
- **Copy-paste siblings**: two or three near-identical functions that should be one with the difference extracted.
- **Contract not readable from signature**: a fresh reader cannot guess what the function does from name + parameters + return type alone.

**Check auto-memory** (`feedback_*` entries) for project-specific patterns this reviewer has rejected before. Respect those as hard constraints, not suggestions.

For each finding, name `file:line`, say what's wrong, and say what should be split / moved / renamed. Don't draft the fix — the implementer handles it.

### 5. Failure Honesty (fail-loudly audit)

Fallbacks and defensive defaults are how bad designs survive. A fallback that fires on a condition that *should never happen* is a bug hiding in plain sight. Flag these:

- **Silent fallbacks on invariant violations**: any code path that implies "something upstream broke" but returns a safe default instead of raising. Typical tells: `if plan is None: return cold_start(...)`, `if not results: return []`, `value = lookup(key) or fallback`.
- **`try/except Exception: return default`**: broad excepts that swallow errors into sensible-looking return values. Ask: what specific exception is being handled here, and why is every other exception also OK to ignore?
- **Backwards-compatibility shims with no current caller**: deprecated flags, old signatures preserved "just in case," re-exported removed types, dead branches for legacy callers.
- **Optional parameters papering over missing data**: `foo=None` defaults that let callers skip sending data they should have. If every legitimate caller has the data, the parameter shouldn't be optional.
- **Policy hidden in utilities**: a utility choosing a default on the caller's behalf when the call site should own the decision. `build_executable_snapshot` silently serving a cold-start result when its plan input is missing is the canonical shape.

For every fallback you flag, ask the implementer: **what legitimate scenario does this serve?** If the answer is vague ("defensive," "robustness," "just in case"), the fallback is hiding a bug. Demand that either:
- The fallback is removed and the invariant is raised on, or
- The legitimate scenario is named concretely, and the fallback is moved to the call site as explicit policy — not left buried in a utility.

### 6. Test Coverage
- **Skips**: What tests are skipped? What is the justification for each?
- **Mocks**: What is mocked? Is each mock necessary? What coverage gaps exist that require manual testing in production?

## Output

Provide a structured report:
1. Summary of phases audited
2. Findings per audit question (with file:line references)
3. **Abstraction Quality findings** — called out as their own section, not buried in Fresh Code Review
4. **Failure Honesty findings** — fallbacks and back-compat shims flagged explicitly, with the "what legitimate scenario does this serve?" question answered (or escalated)
5. Issues aggregated by severity (Critical / Major / Minor)
6. List of items requiring manual production testing (due to mocks)

---

**Related Commands:** `/_my_implement` → `/_my_audit_implementation` → `/_my_code_review`
