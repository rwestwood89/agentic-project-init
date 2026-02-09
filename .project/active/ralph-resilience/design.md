# Design: Ralph Init Resilience — Logging, Error Handling, and Resume

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-02-08
**Branch:** dev

## Overview

Make `ralph-init.sh` fail loudly, log persistently, and resume from the last successful step. Three interlocking changes to one file: fix silent error paths, add dual-output logging, and add file-based resume detection.

## Related Artifacts

- **Spec:** `.project/active/ralph-resilience/spec.md`
- **Source Script:** `claude-pack/scripts/ralph-init.sh`
- **Parent Feature:** `.project/active/add-ralph/`

## Research Findings

### Existing Script Structure

The script has a clear 10-step pipeline (ralph-init.sh:166-811):

| Step | Lines | Claude API? | Output File(s) | Current Error Handling |
|------|-------|-------------|-----------------|----------------------|
| 1 | 166-175 | No | worktree dir | `log_error` if exists |
| 2 | 181-187 | No | `specs/`, `src/`, `tests/` | None (mkdir -p) |
| 3 | 193-253 | Yes (`claude_generate_design`) | `DESIGN_v1.md` | stderr suppressed |
| 4 | 259-407 | Yes (`claude_generate_design`) | `DESIGN_REVIEW.md` | stderr suppressed |
| 5 | 413-461 | Yes (`claude_generate_design`) | `DESIGN.md` | stderr suppressed |
| 6 | 467-545 | Yes (`claude_generate`) | `specs/*.md` | AWK silently fails, warns but continues |
| 7 | 551-594 | Yes (`claude_generate`) | `AGENTS.md` | stderr suppressed |
| 8 | 600-633 | No (prompt only) | `PROMPT_plan.md` | stderr suppressed |
| 9 | 639-677 | No (prompt only) | `PROMPT_build.md` | stderr suppressed |
| 10 | 683-811 | No | `loop.sh`, `pyproject.toml`, scaffold | None |

Note: Steps 8-9 DO call `claude_generate` (which calls `claude -p`), so they are API calls.

### Silent Failure Root Causes

**1. AWK regex mismatch (ralph-init.sh:522)**

```awk
/^```markdown specs\/[^`]+\.md$/ {
```

Three failure modes:
- Trailing `\r` from Claude API: line is `` ```markdown specs/foo.md\r `` — `$` doesn't match before `\r`
- Trailing whitespace: `` ```markdown specs/foo.md  `` — `$` requires end-of-line
- Both combined: `` ```markdown specs/foo.md \r ``

The closing fence regex has the same issue (line 528):
```awk
while (getline > 0 && !/^```$/) {
```
If closing `` ``` `` has trailing whitespace/`\r`, content is never terminated.

**2. stderr suppression (ralph-init.sh:60, 68)**

Both generation functions redirect stderr to `/dev/null`:
```bash
echo "$prompt" | claude -p --model "$MODEL" --output-format text 2>/dev/null
```

If `claude` fails (auth error, rate limit, timeout), the user sees nothing. Under `set -euo pipefail`, the non-zero exit code DOES propagate and kills the script — but the error message is lost, so the user sees only the script dying with no explanation.

**3. No validation after generation (all steps)**

After each `claude_generate` call, the output is written to a file without checking if it's empty. Under `set -e`, an API failure exits the script, but a successful API call that returns empty output (e.g., a timeout that returns 0) silently writes an empty file.

**4. SPEC_COUNT=0 continues (ralph-init.sh:541-545)**

```bash
if [[ "$SPEC_COUNT" -eq 0 ]]; then
    echo "$SPECS_OUTPUT" > specs/_raw_output.md
    log_info "Warning: Could not parse specs..."
fi
# Script continues to step 7
```

### Bash Pattern Research

| Pattern | Safety under `set -euo pipefail` | Notes |
|---------|--------------------------------|-------|
| `exec > >(tee log) 2>&1` | Safe | Preferred for dual-output logging |
| `VAR=$(cmd)` | Exits on failure | Good — catches API failures |
| `[[ -s "$file" ]]` | Safe | "exists and non-empty" — ideal for resume checks |
| `echo "$var" \| awk '...'` | Exits if awk fails | `pipefail` catches awk failure |
| `ls pattern 2>/dev/null \| wc -l` | Does NOT exit | `wc` succeeds with 0 — use `find` or glob instead |

## Proposed Design

### Architecture Overview

Three orthogonal concerns, each implementable independently:

```
┌─────────────────────────────────────────────────┐
│                  ralph-init.sh                   │
│                                                  │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐  │
│  │ Logging  │  │  Error    │  │   Resume     │  │
│  │ (tee)    │  │  Handling │  │   (file      │  │
│  │          │  │  (validate│  │    checks)   │  │
│  │ exec >   │  │   + exit) │  │              │  │
│  │ >(tee)   │  │           │  │  [[ -s f ]]  │  │
│  └──────────┘  └───────────┘  └──────────────┘  │
│                                                  │
│  Step 1 → Step 2 → ... → Step 10                │
│  (each step wrapped with resume check +          │
│   validation)                                    │
└─────────────────────────────────────────────────┘
```

### 1. Logging Infrastructure

**Location:** ralph-init.sh, new section after path setup (~line 161), before step 1.

**Mechanism:** `exec > >(tee ...) 2>&1` — all stdout and stderr is tee'd to both console and log file. Zero per-step changes needed for basic logging.

```bash
# -----------------------------------------------------------------------------
# Logging Setup
# -----------------------------------------------------------------------------

LOG_FILE="$WORKTREE_PATH/ralph-init.log"

# Tee all output to log file (console + file)
exec > >(tee -a "$LOG_FILE") 2>&1

log_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}
```

**Per-step structured logging** adds timestamps at start/end of each step. Wrap each step with:

```bash
log_timestamp "START Step 3: Generating initial design document"
# ... existing step code ...
log_timestamp "END   Step 3: Success"
```

The `tee -a` (append mode) is important for resume — if we re-run, the log accumulates entries from both runs.

**Log file location:** `$WORKTREE_PATH/ralph-init.log`. Must be added to the generated `.gitignore` (step 10, line 781).

**Console output:** Unchanged — user sees the same `log_step` / `log_info` output as today. The log file gets the same output PLUS timestamps.

### 2. Error Handling Fixes

#### 2a. Remove stderr suppression

**Files:** ralph-init.sh:60, 68

Replace:
```bash
echo "$prompt" | claude -p --model "$MODEL" --output-format text 2>/dev/null
```

With:
```bash
echo "$prompt" | claude -p --model "$MODEL" --output-format text
```

Stderr from `claude` now flows to the tee'd stderr, appearing on both console and log file. Under `set -e`, a non-zero exit still kills the script — but now the error message is visible.

#### 2b. Add output validation to generation functions

**Files:** ralph-init.sh:55-69

Redesign `claude_generate` and `claude_generate_design` to validate output:

```bash
claude_generate() {
    local prompt="$1"
    local description="$2"

    log_info "Generating: $description"
    local output
    output=$(echo "$prompt" | claude -p --model "$MODEL" --output-format text)

    if [[ -z "$output" ]]; then
        log_error "Generation failed (empty output): $description. Re-run with --resume to retry."
    fi

    echo "$output"
}
```

Same pattern for `claude_generate_design` with `$DESIGN_MODEL`.

This catches two cases:
- `claude` returns non-zero: `set -e` kills script, stderr is visible (from 2a)
- `claude` returns zero but empty output: explicit `log_error` with resume hint

#### 2c. Fix AWK regex

**File:** ralph-init.sh:522, 528

Replace the opening fence regex:
```awk
# Before:
/^```markdown specs\/[^`]+\.md$/ {

# After — tolerate trailing whitespace and \r:
/^```markdown specs\/[^`]+\.md[[:space:]]*$/ {
```

Replace the closing fence regex:
```awk
# Before:
while (getline > 0 && !/^```$/) {

# After — tolerate trailing whitespace and \r:
while (getline > 0 && !/^```[[:space:]]*$/) {
```

Also add `\r` stripping as a preprocessing step before the match, to handle carriage returns embedded in content lines:

```awk
{ gsub(/\r$/, "") }
```

Full revised AWK block:

```awk
echo "$SPECS_OUTPUT" | awk '
{ gsub(/\r$/, "") }
/^```markdown specs\/[^`]+\.md[[:space:]]*$/ {
    match($0, /specs\/[^`]+\.md/)
    filename = substr($0, RSTART, RLENGTH)
    getline
    content = ""
    while (getline > 0 && !/^```[[:space:]]*$/) {
        content = content $0 "\n"
    }
    print content > filename
    close(filename)
}
'
```

#### 2d. Fail on zero specs

**File:** ralph-init.sh:541-545

Replace warning with hard failure:

```bash
# Count generated specs
SPEC_COUNT=$(find specs -maxdepth 1 -name '*.md' ! -name '_raw_output.md' -size +0c 2>/dev/null | wc -l)
log_info "Generated: $SPEC_COUNT spec files in specs/"

if [[ "$SPEC_COUNT" -eq 0 ]]; then
    echo "$SPECS_OUTPUT" > specs/_raw_output.md
    log_error "Failed to parse any specs from Claude output. Raw output saved to specs/_raw_output.md. Re-run with --resume to retry this step."
fi
```

Note: switched from `ls -1 specs/*.md` to `find` — avoids the `pipefail` issue where `ls` returning non-zero would kill the script, and also filters out `_raw_output.md` and empty files.

### 3. Resume Capability

#### 3a. Argument parsing

**File:** ralph-init.sh:99-130

Add `--resume` to the argument parser:

```bash
RESUME=false

# In the case block:
--resume)
    RESUME=true
    shift
    ;;
```

Add to `usage()`:

```bash
  --resume                Resume a previously failed run (skips completed steps)
```

#### 3b. Resume-aware worktree handling

**File:** ralph-init.sh:162-175

Replace the current step 1 with resume-aware logic:

```bash
if [[ "$RESUME" = true ]]; then
    if [[ -d "$WORKTREE_PATH" ]]; then
        log_step "Step 1/10: Entering existing worktree (resume mode)"
        cd "$WORKTREE_PATH"
        log_info "Resumed in $WORKTREE_PATH"
    else
        log_info "No existing worktree found — starting fresh"
        RESUME=false  # Fall back to fresh mode
        log_step "Step 1/10: Creating git worktree"
        git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
        cd "$WORKTREE_PATH"
        log_info "Created worktree at $WORKTREE_PATH"
    fi
else
    log_step "Step 1/10: Creating git worktree"
    if [[ -d "$WORKTREE_PATH" ]]; then
        log_error "Worktree already exists: $WORKTREE_PATH (use --resume to continue a previous run)"
    fi
    git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
    cd "$WORKTREE_PATH"
    log_info "Created worktree at $WORKTREE_PATH"
fi
```

Note: the existing error message is updated to suggest `--resume`.

#### 3c. Step completion check function

**File:** ralph-init.sh, new helper in the Helper Functions section (~line 38)

```bash
# Check if a step's output already exists (for resume)
step_complete() {
    local step_num="$1"
    local step_name="$2"
    shift 2
    # Remaining args are files to check
    for file in "$@"; do
        if ! [[ -s "$file" ]]; then
            return 1
        fi
    done
    log_timestamp "SKIP  Step $step_num: $step_name — output already exists"
    log_info "[SKIPPED] Step $step_num: $step_name — output already exists"
    return 0
}
```

Usage: `[[ "$RESUME" = true ]] && step_complete 3 "Initial design" "DESIGN_v1.md" && skip=true`

#### 3d. Step wrapping pattern

Each step gets wrapped with a resume guard. The pattern for a Claude generation step:

```bash
# Step 3
if [[ "$RESUME" = true ]] && step_complete 3 "Initial design" "DESIGN_v1.md"; then
    DESIGN_DOC=$(cat DESIGN_v1.md)  # Read existing for downstream steps
else
    log_step "Step 3/10: Generating initial design document"
    log_timestamp "START Step 3: Generating initial design document"

    # ... existing prompt setup ...

    DESIGN_DOC=$(claude_generate_design "${DESIGN_PROMPT}${CONCEPT_CONTENT}" "Initial design")
    echo "$DESIGN_DOC" > DESIGN_v1.md
    log_info "Generated: DESIGN_v1.md"

    log_timestamp "END   Step 3: Success"
fi
```

**Critical detail (FR-15):** When a step is skipped, its output variable MUST still be populated by reading the existing file. Steps 4 and 5 depend on `$DESIGN_DOC`. Step 6 depends on `$DESIGN_DOC`. Steps 7-9 depend on `$DESIGN_DOC`.

The variable dependency chain:

```
Step 3 → $DESIGN_DOC (used by steps 4, 5, 6, 7)
Step 4 → $DESIGN_REVIEW (used by step 5)
Step 5 → $DESIGN_DOC (reassigned — used by steps 6, 7)
Step 6 → $SPECS_OUTPUT (only used internally for AWK parsing)
Steps 7-9 → $DESIGN_DOC (from step 5)
```

So when resuming:
- If step 3 is skipped: `DESIGN_DOC=$(cat DESIGN_v1.md)`
- If step 4 is skipped: `DESIGN_REVIEW=$(cat DESIGN_REVIEW.md)`
- If step 5 is skipped: `DESIGN_DOC=$(cat DESIGN.md)` (note: reassigns to refined version)
- If step 6 is skipped: no variable needed (specs are on disk)
- If step 7 is skipped: nothing needed
- If steps 8-9 are skipped: nothing needed

#### 3e. Step 6 (specs) resume check

Step 6 is special — its output is multiple files, not one. The check:

```bash
if [[ "$RESUME" = true ]]; then
    EXISTING_SPECS=$(find specs -maxdepth 1 -name '*.md' ! -name '_raw_output.md' -size +0c 2>/dev/null | wc -l)
    if [[ "$EXISTING_SPECS" -gt 0 ]]; then
        step_complete 6 "Specification files" "specs/"  # always returns true since specs/ exists
        SPEC_COUNT=$EXISTING_SPECS
        # Jump past spec generation
    fi
fi
```

Actually simpler to use the same guard pattern but check differently:

```bash
resume_step6() {
    [[ "$RESUME" != true ]] && return 1
    local count
    count=$(find specs -maxdepth 1 -name '*.md' ! -name '_raw_output.md' -size +0c 2>/dev/null | wc -l)
    [[ "$count" -gt 0 ]] || return 1
    SPEC_COUNT=$count
    log_timestamp "SKIP  Step 6: Specification files — $count specs already exist"
    log_info "[SKIPPED] Step 6: Specification files — $count specs already exist"
    return 0
}
```

#### 3f. Step 10 resume — commit handling (FR-17)

In resume mode, the scaffold files may already exist. The commit logic:

```bash
git add -A
if git rev-parse HEAD >/dev/null 2>&1 && git log --oneline -1 | grep -q "ralph-init: scaffold"; then
    git commit --amend --no-edit -m "ralph-init: scaffold for $PROJECT_NAME (resumed)

Generated by ralph-init.sh:
..."
else
    git commit -m "ralph-init: scaffold for $PROJECT_NAME
..."
fi
```

#### 3g. .gitignore update

**File:** ralph-init.sh:781 (the `.gitignore` heredoc in step 10)

Add `ralph-init.log` to the generated `.gitignore`:

```bash
cat << 'GITIGNORE' > .gitignore
__pycache__/
*.py[cod]
.venv/
.mypy_cache/
.pytest_cache/
.ruff_cache/
*.egg-info/
dist/
build/
.DS_Store
ralph-init.log
GITIGNORE
```

### 4. Logging Setup Timing

One subtlety: the log file lives in the worktree, but the worktree doesn't exist until step 1. The logging setup must happen AFTER step 1 (when we `cd` into the worktree) but BEFORE step 2.

```
Argument parsing & validation  (no logging yet — just console)
Step 1: Create/enter worktree  (no logging yet — just console)
--- LOG INIT ---                (exec > >(tee ralph-init.log) 2>&1)
Step 2-10: All logged           (dual output: console + file)
```

The banner output (lines 153-160) happens before step 1, so it appears on console only. This is fine — the banner just shows config, not diagnostic info. We can echo it into the log file after init:

```bash
# After step 1, before step 2:
LOG_FILE="$WORKTREE_PATH/ralph-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Replay banner into log
log_timestamp "Ralph Init started"
log_timestamp "Project: $PROJECT_NAME | Model: $MODEL | Design Model: $DESIGN_MODEL"
log_timestamp "Worktree: $WORKTREE_PATH | Branch: $BRANCH_NAME"
[[ "$RESUME" = true ]] && log_timestamp "Mode: RESUME"
```

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `exec > >(tee)` changes buffering behavior | Low — tee flushes on newline by default | Console output timing unchanged for line-buffered output |
| `exec > >(tee)` under `set -e` — tee process dies | Medium — script loses logging silently | tee is extremely stable; log file can be checked post-mortem |
| Resume skips a step whose file is corrupted (non-empty but garbage) | Low — user would notice during review | Step validation checks non-empty, not content quality. Manual `--resume` implies user is aware |
| AWK `[[:space:]]` class not available in all awk implementations | Low — GNU awk and mawk both support POSIX classes | Could fall back to `[ \t\r]` if needed, but all Linux systems have POSIX awk |
| Removing `2>/dev/null` shows noisy Claude CLI progress to user | Low — progress output is useful context | If too noisy, could redirect to log only: `2>> "$LOG_FILE"` instead of removing entirely |

## Integration Strategy

All changes are within a single file (`claude-pack/scripts/ralph-init.sh`). No other files are affected.

The changes are additive — existing behavior is preserved when `--resume` is not passed (except: better error messages, visible stderr, and a log file is now always created).

## Validation Approach

### Manual Verification Steps

**Error handling:**
1. Intentionally corrupt the AWK input (add trailing whitespace to fence) → verify it still parses
2. Disconnect network, run ralph-init.sh → verify Claude error is visible on console AND in log
3. If spec generation produces zero specs → verify script exits with clear error

**Logging:**
1. Run full ralph-init.sh → verify `ralph-init.log` exists in worktree
2. Check log has timestamps for each step start/end
3. Verify log is in `.gitignore`
4. Verify console output is unchanged from current behavior

**Resume:**
1. Run ralph-init.sh, kill after step 5 (`kill -9`)
2. Run with `--resume` → verify steps 1-5 show `[SKIPPED]`, steps 6+ execute
3. Run with `--resume` when all steps complete → verify all show `[SKIPPED]`, commit amended
4. Run with `--resume` when no worktree exists → verify falls back to fresh mode

---

**Next Step:** After approval → `/_my_plan` or `/_my_implement`
