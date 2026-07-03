# Spec: `/_my_pre_pr` Command

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** MEDIUM
**Branch:** workflow-v2

---

## Problem

Code quality checks are split across two commands (`_my_code_review` at 467 lines, `_my_code_quality` at 244 lines) that overlap in scope and conflate two different jobs. `_my_code_review` mixes spec/design conformance with code quality checks. `_my_code_quality` runs automated tools but is positioned as a work-item step rather than a PR-level activity.

With the v2 pipeline, spec/design conformance moves to `/_my_audit`. What remains — running the project's quality checks and getting clean code to PR — belongs in a single pre-PR gate that operates on whatever is about to be committed, independent of work-item boundaries.

The command also lacks a PR submission step. After checks pass, the user has to manually compose and submit the PR. The pre-PR command should carry through from scoping to submission.

## Success Criteria

- [ ] `/_my_pre_pr` reviews the git state, scopes the PR with the user, runs project-defined quality checks, and offers to submit the PR
- [ ] Quality checks are defined by the project (via CLAUDE.md), not hardcoded in the command
- [ ] No spec/design conformance logic — purely code quality and mechanical checks
- [ ] Low-risk issues are fixed directly; medium/high-risk issues are worked through with the user before submission

## Known Requirements

### PR scoping

- **[HARD]** Starts by reviewing git history and diff to understand what will be in the PR — commits, changed files, scope of changes.
- **[NEED]** Follows up with the user if the scope is unclear: are all these commits intended for this PR? Should anything be excluded? Is the branch targeting the right base?

### Quality checks

- **[HARD]** The project defines its own checks. The command reads CLAUDE.md (or equivalent project config) to discover what test, lint, format, and type-check commands to run. The command does not prescribe specific tools.
- **[NEED]** Reasonable fallback for Python repos when no checks are specified: `pytest` for tests, `ruff check` for linting, `ruff format --check` for formatting. Other ecosystems get a best-effort attempt to discover tooling.
- **[HARD]** No spec/design conformance checking. That is `/_my_audit`. Pre-PR does not read spec.md, design.md, or plan.md.
- **[NEED]** Flags surface-level pattern violations that automated tools may miss: obvious code smells, debug artifacts left in code, files that look like secrets (.env, credentials).

### Fix and resolve

- **[NEED]** Fixes low-risk issues directly: formatting, import sorting, simple lint auto-fixes. These don't change behavior.
- **[NEED]** Works with the user to close medium and high-risk issues: test failures, type errors, pattern violations that require judgment. This is interactive — not just a report the user reads later.

### PR submission

- **[NEED]** After checks pass (or the user decides remaining issues are acceptable), offers to submit the PR.
- **[HARD]** Follows the project's CLAUDE.md conventions for PR submission, including Claude attribution (e.g., `Co-Authored-By` trailers, PR body conventions).

### Output

- **[HARD]** No written artifact in a work-item directory. Output is conversational.
- **[INFERRED]** When everything passes cleanly, a short confirmation is sufficient. No verbose report for a clean run.

## Non-Goals

- Spec/design conformance checking. That is `/_my_audit`.
- Architectural slop detection (god functions, policy in utilities, failure honesty). That is `/_my_audit`'s code integrity section.
- Producing a persistent review artifact. Pre-PR is ephemeral — its job is done when the PR ships.
- Deciding what goes in the PR. The user decides scope; the command confirms and executes.

## Open Questions / Deferred to design

- **Diff scope for pattern checks.** Automated tools (tests, lint) run against the full codebase. But should the manual pattern-violation scan focus only on changed files? Defer to design.
- **Handling projects with no CLAUDE.md.** Should pre-PR attempt to discover tooling by inspecting pyproject.toml, package.json, Makefile, etc.? Or just report that no checks are configured? Defer to design.
- **PR template and body generation.** How much of the PR description should the command auto-generate? Should it pull from spec/audit summaries, or is that over-coupling with the work-item pipeline? Defer to design.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_workflow_v2.md` (Item 6)
- **Commands being consolidated:** `claude-pack/commands/_my_code_review.md`, `claude-pack/commands/_my_code_quality.md`
- **Audit command (boundary reference):** `claude-pack/commands/_my_audit.md` (lines 46-65, code integrity section)
- **Design:** `.project/active/pre-pr-command/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
