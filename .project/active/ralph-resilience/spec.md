# Spec: Ralph Init Resilience — Logging, Error Handling, and Resume

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-02-08
**Complexity:** MEDIUM
**Branch:** dev

---

## Business Goals

### Why This Matters
Ralph calls the Claude API ~5 times per run, each costing time and tokens. A silent mid-run failure wastes those calls and leaves the user with an incomplete scaffold they must manually debug and finish. The current script has no persistent record of what happened, no way to know which step failed, and no way to pick up where it left off.

### Success Criteria

- [ ] When a step fails, the user knows exactly which step failed and why
- [ ] After a failure, re-running the script skips already-completed steps
- [ ] A log file exists in the worktree with step-by-step execution history
- [ ] No more silent failures — every failure path either exits loudly or is explicitly handled

### Priority
Active — directly blocks confident use of Ralph Loop.

---

## Problem Statement

### Current State
`ralph-init.sh` has several failure modes that are invisible to the user:

1. **Silent spec parsing failure**: The AWK regex at line 521 expects the exact pattern `` ```markdown specs/NAME.md `` but Claude's output may include trailing whitespace, carriage returns, or slightly different fence formatting. When the regex doesn't match, zero spec files are created. The script warns but continues to steps 7-10.

2. **Suppressed stderr**: Both `claude_generate` (line 60) and `claude_generate_design` (line 68) redirect stderr to `/dev/null` via `2>/dev/null`. If the Claude CLI fails (auth error, timeout, rate limit), the user sees nothing.

3. **No persistent logging**: All output goes to stdout. If the terminal scrolls past or the user runs in background, diagnostic information is lost.

4. **No resume capability**: If the script fails at step 7, steps 3-6 (4 Claude API calls) must be re-run. Each call takes 30-120 seconds and costs tokens.

### Desired Outcome
A ralph-init.sh that fails loudly with clear diagnostics, maintains a persistent log, and can resume from the last successful step.

---

## Scope

### In Scope
1. Fix known silent failure paths in error handling
2. Add structured logging to a persistent file in the worktree
3. Add step-completion tracking and resume capability
4. Fix the AWK spec-parsing regex to be more tolerant
5. Add validation checks after each Claude generation step

### Out of Scope
- Rewriting Claude prompt engineering or spec output format
- Adding automated tests for ralph-init.sh
- Changing the overall multi-step architecture (10-step pipeline stays)
- Adding retry logic for Claude API failures (detect + resume, not auto-retry)
- Adding a second/fallback spec parser

### Edge Cases & Considerations
- Resume after worktree already exists: the script currently calls `log_error` (exits) if the worktree exists. Resume MUST handle this case — if the worktree exists AND was created by a previous ralph-init run, resume into it.
- Partial file writes: a step that started but didn't finish may leave a truncated file. Resume should detect this (e.g., empty or suspiciously small files) and re-run that step.
- `set -euo pipefail` interaction: the resume/logging mechanisms must not introduce new silent failure paths through these strict mode settings.
- Log file should not be committed in the initial scaffold commit — add to `.gitignore`.

---

## Requirements

### Functional Requirements

#### Error Handling (Fix Silent Failures)

1. **FR-1**: The AWK spec-parsing regex MUST tolerate trailing whitespace and `\r` in fence lines. It SHOULD also tolerate minor variations like extra spaces between ```` ``` ```` and `markdown`.

2. **FR-2**: After the AWK parsing block, the script MUST validate that at least one non-empty spec file was created in `specs/`. If zero specs exist, the script MUST exit with `log_error` (not just `log_info` warning).

3. **FR-3**: The `claude_generate` and `claude_generate_design` functions MUST NOT suppress stderr with `2>/dev/null`. Stderr from the `claude` CLI MUST be visible to the user AND captured in the log file.

4. **FR-4**: After each `claude_generate` / `claude_generate_design` call, the script MUST validate that the output is non-empty. If empty, it MUST exit with a clear error message identifying which step failed and suggesting `--resume` to retry.

5. **FR-5**: [INFERRED] Each step that produces a file (steps 3-10) SHOULD validate the output file exists and is non-empty before marking the step complete.

#### Structured Logging

6. **FR-6**: The script MUST write a persistent log file to `ralph-init.log` in the worktree directory.

7. **FR-7**: The log file MUST include for each step: step number, step name, start timestamp, end timestamp, and outcome (success/failure/skipped).

8. **FR-8**: The log file MUST capture both stdout and stderr from `claude` CLI invocations.

9. **FR-9**: Console output (what the user sees) SHOULD remain concise — the same `log_step` / `log_info` style as today. Verbose detail goes to the log file only.

10. **FR-10**: [INFERRED] `ralph-init.log` MUST be added to the generated `.gitignore` so it is not committed in the initial scaffold commit.

#### Resume Capability

11. **FR-11**: The script MUST accept a `--resume` flag that triggers resume mode.

12. **FR-12**: In resume mode, the script MUST detect the existing worktree (created by a previous run) and `cd` into it instead of creating a new one.

13. **FR-13**: Resume MUST determine which steps are already complete by checking for the existence of their output files:

    | Step | Output File(s) | Skip condition |
    |------|---------------|----------------|
    | 1 (worktree) | worktree directory exists | directory exists |
    | 2 (dirs) | `specs/`, `src/`, `tests/` | all three exist |
    | 3 (initial design) | `DESIGN_v1.md` | file exists and is non-empty |
    | 4 (design review) | `DESIGN_REVIEW.md` | file exists and is non-empty |
    | 5 (refined design) | `DESIGN.md` | file exists and is non-empty |
    | 6 (specs) | `specs/*.md` (at least 1) | at least one non-empty .md file in specs/ |
    | 7 (AGENTS.md) | `AGENTS.md` | file exists and is non-empty |
    | 8 (PROMPT_plan) | `PROMPT_plan.md` | file exists and is non-empty |
    | 9 (PROMPT_build) | `PROMPT_build.md` | file exists and is non-empty |
    | 10 (scaffold) | `loop.sh`, `pyproject.toml` | both exist |

14. **FR-14**: When a step is skipped, the script MUST log `[SKIPPED] Step N: <name> — output already exists` to both console and log file.

15. **FR-15**: When resuming, the script MUST still read previously-generated files as inputs for downstream steps (e.g., read existing `DESIGN.md` to pass as context to step 6 specs generation).

16. **FR-16**: [INFERRED] `--resume` without a prior run (no worktree exists) SHOULD fall back to normal (fresh) mode with a warning.

17. **FR-17**: [INFERRED] The initial commit (step 10) in resume mode SHOULD use `git add -A && git commit --amend` if a previous scaffold commit exists, or create a new commit if not.

### Non-Functional Requirements

- All changes MUST be backward-compatible — running without `--resume` behaves the same as today (except with logging and better error handling)
- The logging mechanism MUST NOT meaningfully slow down execution
- The resume detection MUST be file-based (no external state files beyond the log) — the output files themselves are the checkpoints

---

## Acceptance Criteria

### Error Handling
- [ ] AWK regex matches spec fences with trailing whitespace and `\r`
- [ ] Script exits with clear error if zero specs are parsed (not just a warning)
- [ ] Claude CLI stderr is visible to the user when a generation step fails
- [ ] Script exits with clear error if any `claude_generate` call returns empty output
- [ ] Error messages identify which step failed and suggest `--resume`

### Logging
- [ ] `ralph-init.log` is created in the worktree with step-by-step history
- [ ] Each log entry includes step number, name, timestamps, and outcome
- [ ] `ralph-init.log` is in the generated `.gitignore`
- [ ] Console output remains concise (no regression in user experience)

### Resume
- [ ] `--resume` skips steps whose output files already exist
- [ ] Skipped steps are logged to console and log file
- [ ] `--resume` correctly enters existing worktree instead of failing
- [ ] Previously-generated files are read as context for downstream steps
- [ ] `--resume` with no prior run falls back to fresh mode with warning
- [ ] Full fresh run (no `--resume`) still works identically to today (plus logging)

### Quality & Integration
- [ ] `ralph-init.sh --help` documents `--resume` flag
- [ ] `set -euo pipefail` behavior is preserved — no new silent failure paths
- [ ] Existing step numbering and output style is preserved

---

## Related Artifacts

- **Source Script:** `claude-pack/scripts/ralph-init.sh`
- **Investigation:** Silent failure root cause analysis (AWK regex, stderr suppression, missing exit)
- **Parent Feature:** `.project/active/add-ralph/` (Ralph Loop integration)

---

**Next Steps:** After approval, proceed to `/_my_design`
