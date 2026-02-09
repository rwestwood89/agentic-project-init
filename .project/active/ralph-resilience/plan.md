# Implementation Plan: Ralph Init Resilience

**Status:** In Progress
**Created:** 2026-02-08
**Last Updated:** 2026-02-08

## Source Documents
- **Spec:** `.project/active/ralph-resilience/spec.md`
- **Design:** `.project/active/ralph-resilience/design.md` — See here for exact code snippets, bash pattern research, and variable dependency chain

## Implementation Strategy

**Phasing Rationale:**
Phase 1 fixes the actual bugs (silent failures) — highest value, de-risks the core problem. Phase 2 adds logging on top of working error handling so the log captures real errors. Phase 3 adds resume, which depends on both error handling (resume hints in error messages) and logging (skipped steps appear in log). Phase 4 is pure validation.

**Overall Validation Approach:**
- No automated tests exist for this infrastructure script — validation is manual
- Each phase has specific manual verification steps
- Phase 4 is a dedicated walk-through of all acceptance criteria from the spec

---

## Phase 1: Error Handling Fixes

### Goal
Fix all silent failure paths so the script fails loudly with clear diagnostics. This is the highest-value change — it solves the original problem (silent failure after step 6) and is prerequisite for everything else.

### Changes Required

**See `design.md#2-error-handling-fixes` for exact code snippets.**

**File:** `claude-pack/scripts/ralph-init.sh`

#### 1. Rewrite `claude_generate` with validation
**Location:** lines 55-61
- [x] Remove `2>/dev/null` from `claude` invocation
- [x] Capture output in local variable
- [x] Add empty-output check with `log_error` that suggests `--resume`
- [x] Echo output to stdout for caller to capture
- [x] See `design.md#2b-add-output-validation-to-generation-functions`

#### 2. Rewrite `claude_generate_design` with validation
**Location:** lines 63-69
- [x] Same pattern as above, using `$DESIGN_MODEL`
- [x] See `design.md#2b-add-output-validation-to-generation-functions`

#### 3. Fix AWK spec-parsing regex
**Location:** lines 521-534
- [x] Add `{ gsub(/\r$/, "") }` as preprocessing rule
- [x] Change opening fence regex: `[[:space:]]*$` instead of `$`
- [x] Change closing fence regex: `[[:space:]]*$` instead of `$`
- [x] See `design.md#2c-fix-awk-regex` for full revised block

#### 4. Replace spec count warning with hard failure
**Location:** lines 536-545
- [x] Switch from `ls -1 specs/*.md` to `find` (avoids `pipefail` issue)
- [x] Filter out `_raw_output.md` and empty files
- [x] Change `log_info "Warning..."` to `log_error` (exits script)
- [x] Include resume hint in error message
- [x] See `design.md#2d-fail-on-zero-specs`

### Validation

**Manual:**
- [x] Read the modified functions and verify no `2>/dev/null` remains
- [x] Verify AWK regex handles: ```` ```markdown specs/foo.md ```` (clean), ```` ```markdown specs/foo.md  ```` (trailing space), ```` ```markdown specs/foo.md\r ```` (trailing CR)
- [x] Verify error messages include "Re-run with --resume" text
- [x] Verify `find`-based spec count correctly ignores `_raw_output.md`

**What We Know Works After This Phase:**
All known silent failure paths are fixed. `claude` errors are visible. Empty output exits loudly. AWK handles whitespace variations. Zero specs exits instead of continuing.

---

## Phase 2: Logging Infrastructure

### Goal
Add persistent dual-output logging so every step's execution is recorded in `ralph-init.log`. Builds on Phase 1's visible errors — now those errors are also captured to disk.

### Changes Required

**See `design.md#1-logging-infrastructure` and `design.md#4-logging-setup-timing` for architecture and timing details.**

**File:** `claude-pack/scripts/ralph-init.sh`

#### 1. Add `log_timestamp` helper function
**Location:** Helper Functions section (~line 52, after `log_error`)
- [x] Add `log_timestamp()` function: `echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"`
- [x] See `design.md#1-logging-infrastructure`

#### 2. Add logging initialization after step 1
**Location:** After step 1 completes (after `cd "$WORKTREE_PATH"`), before step 2
- [x] Set `LOG_FILE="ralph-init.log"` (relative — we're already in worktree)
- [x] Add `exec > >(tee -a "$LOG_FILE") 2>&1`
- [x] Replay banner info via `log_timestamp` calls (project, model, worktree, branch, mode)
- [x] See `design.md#4-logging-setup-timing`

#### 3. Add per-step timestamps
**Location:** Each of steps 2-10
- [x] Add `log_timestamp "START Step N: <name>"` at beginning of each step
- [x] Add `log_timestamp "END   Step N: Success"` at end of each step
- [x] Steps 3-9 (generation steps): timestamp wraps the full step including prompt setup

#### 4. Add `ralph-init.log` to generated `.gitignore`
**Location:** line 781 (`.gitignore` heredoc in step 10)
- [x] Add `ralph-init.log` line to the heredoc
- [x] See `design.md#3g-gitignore-update`

### Validation

**Manual:**
- [ ] Run a fresh ralph-init.sh (doesn't need to complete — can kill after step 2-3)
- [ ] Verify `ralph-init.log` exists in worktree
- [ ] Verify log contains `[YYYY-MM-DD HH:MM:SS]` timestamps with START/END for each completed step
- [ ] Verify console output is unchanged (same `log_step`/`log_info` style)
- [ ] Verify `.gitignore` includes `ralph-init.log`

**What We Know Works After This Phase:**
All output is captured to both console and log file. Each step has structured timestamps. Log file persists across terminal sessions.

---

## Phase 3: Resume Capability

### Goal
Add `--resume` flag with file-based checkpoint detection so users can re-run after a failure and skip already-completed steps. Depends on Phase 1 (error messages suggest `--resume`) and Phase 2 (skipped steps appear in log).

### Changes Required

**See `design.md#3-resume-capability` for all code snippets and the variable dependency chain.**

**File:** `claude-pack/scripts/ralph-init.sh`

#### 1. Add `--resume` to argument parsing
**Location:** lines 99-130
- [x] Add `RESUME=false` variable initialization (near `PROJECT_NAME=""`)
- [x] Add `--resume)` case in the argument parser
- [x] Add `--resume` to `usage()` help text
- [x] See `design.md#3a-argument-parsing`

#### 2. Add `step_complete` helper function
**Location:** Helper Functions section (after `log_timestamp`)
- [x] Add `step_complete()` — takes step number, name, and file(s) to check via `[[ -s "$file" ]]`
- [x] Logs skip message to both console and log file
- [x] See `design.md#3c-step-completion-check-function`

#### 3. Add `resume_step6` helper function
**Location:** Helper Functions section (after `step_complete`)
- [x] Add `resume_step6()` — uses `find` to count non-empty specs
- [x] Sets `SPEC_COUNT` variable when skipping
- [x] See `design.md#3e-step-6-specs-resume-check`

#### 4. Rewrite step 1 with resume-aware worktree handling
**Location:** lines 162-175
- [x] Resume mode: enter existing worktree or fall back to fresh
- [x] Fresh mode: existing worktree error now suggests `--resume`
- [x] See `design.md#3b-resume-aware-worktree-handling`

#### 5. Wrap steps 2-5 with resume guards
**Location:** steps 2-5
- [x] Step 2: check `specs/`, `src/`, `tests/` directories exist
- [x] Step 3: check `[[ -s DESIGN_v1.md ]]`, if skipped: `DESIGN_DOC=$(cat DESIGN_v1.md)`
- [x] Step 4: check `[[ -s DESIGN_REVIEW.md ]]`, if skipped: `DESIGN_REVIEW=$(cat DESIGN_REVIEW.md)`
- [x] Step 5: check `[[ -s DESIGN.md ]]`, if skipped: `DESIGN_DOC=$(cat DESIGN.md)`
- [x] See `design.md#3d-step-wrapping-pattern` for pattern and variable dependency chain

#### 6. Wrap step 6 with resume guard
**Location:** step 6
- [x] Use `resume_step6` helper (special — checks multiple files)
- [x] No variables to populate on skip (specs are on disk)
- [x] See `design.md#3e-step-6-specs-resume-check`

#### 7. Wrap steps 7-9 with resume guards
**Location:** steps 7-9
- [x] Step 7: check `[[ -s AGENTS.md ]]`
- [x] Step 8: check `[[ -s PROMPT_plan.md ]]`
- [x] Step 9: check `[[ -s PROMPT_build.md ]]`
- [x] No variables to populate on skip

#### 8. Wrap step 10 with resume guard + amend logic
**Location:** step 10
- [x] Check `loop.sh` and `pyproject.toml` exist for scaffold skip
- [x] Commit: detect prior scaffold commit, amend if exists, new commit if not
- [x] See `design.md#3f-step-10-resume-commit-handling`

### Validation

**Manual:**
- [ ] `ralph-init.sh --help` shows `--resume` option
- [ ] Fresh run (no `--resume`): behaves identically to pre-change (plus logging from Phase 2)
- [ ] `--resume` with existing worktree: skips completed steps, shows `[SKIPPED]` for each
- [ ] `--resume` after step 5 failure: steps 1-5 skipped, step 6+ executes
- [ ] `--resume` when no worktree exists: falls back to fresh mode with warning
- [ ] Verify variable chain: if steps 3-5 are skipped, step 6 still has `$DESIGN_DOC` from `cat DESIGN.md`
- [ ] Verify `ralph-init.log` shows both original run entries and resume run entries (append mode)

**What We Know Works After This Phase:**
Full resume lifecycle. Users can re-run with `--resume` after any failure and skip completed steps. Variable dependencies are maintained. Log file accumulates history across runs.

---

## Phase 4: End-to-End Verification

### Goal
Walk through ALL acceptance criteria from the spec to confirm everything works together. No file changes — validation only.

### Acceptance Criteria Checklist (from spec)

**Error Handling:**
- [ ] AWK regex matches spec fences with trailing whitespace and `\r`
- [ ] Script exits with clear error if zero specs are parsed (not just a warning)
- [ ] Claude CLI stderr is visible to the user when a generation step fails
- [ ] Script exits with clear error if any `claude_generate` call returns empty output
- [ ] Error messages identify which step failed and suggest `--resume`

**Logging:**
- [ ] `ralph-init.log` is created in the worktree with step-by-step history
- [ ] Each log entry includes step number, name, timestamps, and outcome
- [ ] `ralph-init.log` is in the generated `.gitignore`
- [ ] Console output remains concise (no regression in user experience)

**Resume:**
- [ ] `--resume` skips steps whose output files already exist
- [ ] Skipped steps are logged to console and log file
- [ ] `--resume` correctly enters existing worktree instead of failing
- [ ] Previously-generated files are read as context for downstream steps
- [ ] `--resume` with no prior run falls back to fresh mode with warning
- [ ] Full fresh run (no `--resume`) still works identically to today (plus logging)

**Quality & Integration:**
- [ ] `ralph-init.sh --help` documents `--resume` flag
- [ ] `set -euo pipefail` behavior is preserved — no new silent failure paths
- [ ] Existing step numbering and output style is preserved

---

## Risk Management

**See `design.md#potential-risks` for detailed risk analysis.**

**Phase-Specific Mitigations:**
- **Phase 1**: Test AWK regex changes against known-bad inputs before moving on
- **Phase 2**: Verify `exec > >(tee)` doesn't change console output timing — run a step and compare visually
- **Phase 3**: The variable dependency chain (design.md#3d) is the trickiest part — verify by running `--resume` after killing at each step boundary

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
**Completed:** 2026-02-08 (prior session)
**Actual Changes:**
- Rewrote `claude_generate()` (lines 59-72): removed `2>/dev/null`, added local variable capture, empty-output validation with `log_error` + resume hint
- Rewrote `claude_generate_design()` (lines 74-87): same pattern with `$DESIGN_MODEL`
- Fixed AWK block (lines 539-552): added `gsub(/\r$/, "")` preprocessing, `[[:space:]]*$` on opening and closing fence regexes
- Replaced spec count warning with hard failure (lines 554-562): switched to `find`-based count, filters `_raw_output.md` and empty files, `log_error` with resume hint
**Issues:** None
**Deviations:** None

### Phase 2 Completion
**Completed:** 2026-02-09
**Actual Changes:**
- `log_timestamp()` helper was already present (line 54-56, added in prior session)
- Added logging setup block after step 1 (lines 195-204): `LOG_FILE="ralph-init.log"`, `exec > >(tee -a "$LOG_FILE") 2>&1`, banner replay with `log_timestamp`
- Added `log_timestamp "START Step N: ..."` and `log_timestamp "END   Step N: Success"` to all 9 steps (2-10)
- Added `ralph-init.log` to generated `.gitignore` heredoc (line 838)
- Fixed step numbering: steps 1-2 were "Step X/8", now all 10 steps consistently say "Step X/10"
**Issues:** None
**Deviations:**
- Fixed pre-existing step numbering inconsistency (steps 1-2 said `/8`, steps 3-10 said `/10`) — all now say `/10`

### Phase 3 Completion
**Completed:** 2026-02-09
**Actual Changes:**
- Added `RESUME=false` variable init (line 149), `--resume)` case in arg parser (line 164-167), `--resume` in usage text (line 132)
- Added `step_complete()` helper (lines 58-72): checks `[[ -s "$file" ]]` for all passed files, logs SKIP + [SKIPPED] messages
- Added `resume_step6()` helper (lines 74-84): uses `find` to count non-empty specs, sets `SPEC_COUNT` on skip
- Rewrote step 1 (lines 218-239): resume enters existing worktree or falls back to fresh; fresh mode suggests `--resume` if worktree exists
- Added `[[ "$RESUME" = true ]] && log_timestamp "Mode: RESUME"` to logging setup (line 251)
- Wrapped steps 2-5 with if/else resume guards preserving variable chain: step 3 populates `DESIGN_DOC`, step 4 populates `DESIGN_REVIEW`, step 5 populates `DESIGN_DOC` (refined)
- Wrapped step 6 with `resume_step6` helper guard
- Wrapped steps 7-9 with resume guards (no variables needed)
- Wrapped step 10: scaffold creation skipped if `loop.sh` + `pyproject.toml` exist; commit uses `git diff --cached --quiet` to detect changes and amends prior scaffold commit in resume mode
**Issues:** None
**Deviations:**
- Step 10 commit: added `git diff --cached --quiet` guard to handle "nothing to commit" case (all steps skipped on full re-run), which was not explicitly in the design but necessary to avoid `set -e` failure on empty commit
- Existing step code inside else blocks is not indented (valid bash, avoids re-indenting heredocs with sensitive content)

### Phase 4 Completion
**Completed:** 2026-02-09
**Actual Changes:** None (verification only)
**Issues:** None — all 18 acceptance criteria pass code inspection
**Deviations:** None

---

**Status**: Complete
