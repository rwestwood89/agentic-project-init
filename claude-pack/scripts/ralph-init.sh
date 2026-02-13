#!/bin/bash
set -euo pipefail

# =============================================================================
# ralph-init.sh — Automated Ralph Wiggum Loop Setup
# =============================================================================
#
# Usage: ./ralph-init.sh <project_name> <concept_file> [options]
#        ./ralph-init.sh <project_name> --design <design_file> [options]
#
# Example:
#   ./ralph-init.sh comment-system ./CONCEPT.md
#   ./ralph-init.sh comment-system ./CONCEPT.md --model opus
#   ./ralph-init.sh comment-system --design ./DESIGN.md
#   ./ralph-init.sh comment-system --design ./draft.md --review-design
#   ./ralph-init.sh comment-system ./CONCEPT.md --stage specs,agents
#
# Prerequisites:
#   - Must be run from within a git repository
#   - Claude CLI installed and configured
#   - UV installed (for Python projects)
#
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

MODEL="${RALPH_MODEL:-sonnet}"
DESIGN_MODEL="${RALPH_DESIGN_MODEL:-sonnet}"  # Can use opus for design phase
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NAME=""  # Set after PROJECT_NAME is parsed
PROMPTS_DIR=""   # Override prompt file location
STAGE_FILTER=false
STAGES=""
DESIGN_FILE=""
REVIEW_DESIGN=false
SPEC_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valid stage names for --stage flag
VALID_STAGES="worktree,dirs,design,review,refine,specs,agents,prompts,scaffold"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

log_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

log_info() {
    echo -e "${YELLOW}  → $1${NC}"
}

log_error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
    exit 1
}

log_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Format step header: "[stage_name]" when --stage is active, "Step N/M:" otherwise
step_header() {
    local stage_name="$1"
    local step_num="$2"
    local total="$3"
    local description="$4"
    if [[ "$STAGE_FILTER" = true ]]; then
        echo "[$stage_name] $description"
    else
        echo "Step $step_num/$total: $description"
    fi
}

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

# Check if step 6 (specs) can be skipped (multiple output files)
resume_step6() {
    [[ "$RESUME" != true ]] && return 1
    local count
    count=$(find specs -maxdepth 1 -name '*.md' ! -name '_raw_output.md' ! -name '_raw_output_attempt1.md' -size +0c 2>/dev/null | wc -l)
    [[ "$count" -gt 0 ]] || return 1
    SPEC_COUNT=$count
    log_timestamp "SKIP  Step 6: Specification files — $count specs already exist"
    log_info "[SKIPPED] Step 6: Specification files — $count specs already exist"
    return 0
}

# Validate that generation output is actual content, not a conversational summary
# Args: $1=output, $2=min_lines (default 20)
# Returns: 0 (valid) or 1 (summary detected)
validate_generation() {
    local output="$1"
    local min_lines="${2:-20}"

    local line_count
    line_count=$(echo "$output" | wc -l)

    if [[ "$line_count" -lt "$min_lines" ]]; then
        log_info "Validation FAIL: output too short ($line_count lines, minimum $min_lines)" >&2
        return 1
    fi

    # Check if first non-empty line looks like conversational preamble
    local first_line
    first_line=$(echo "$output" | sed '/^[[:space:]]*$/d' | head -1)

    if [[ "$first_line" =~ ^(I\'ve\ |I\ have\ |Here\'s\ |Here\ are|Here\ is|Below\ |The\ following\ |Sure|Let\ me|Certainly|Of\ course) ]]; then
        log_info "Validation FAIL: conversational preamble detected: '${first_line:0:60}...'" >&2
        return 1
    fi

    # Catch "The <noun> is ready/complete/done" — meta-commentary about content
    if [[ "$first_line" =~ ^The\ .+\ (is\ ready|is\ complete|is\ done|has\ been) ]]; then
        log_info "Validation FAIL: meta-commentary detected: '${first_line:0:60}...'" >&2
        return 1
    fi

    # Catch "Summary of" at start
    if [[ "$first_line" =~ ^Summary\ (of|:) ]]; then
        log_info "Validation FAIL: summary header detected: '${first_line:0:60}...'" >&2
        return 1
    fi

    # Check for tool-use artifacts anywhere in output (Claude asking for permissions)
    if echo "$output" | grep -qiE '(please approve|file write permission|approve the|permission to write|ready to write)'; then
        log_info "Validation FAIL: tool-use artifact detected (Claude asked for permissions instead of producing content)" >&2
        return 1
    fi

    return 0
}

# Re-generate when output was a summary instead of actual content
# Args: $1=raw_output, $2=original_prompt, $3=model
fixup_generate() {
    local raw_output="$1"
    local original_prompt="$2"
    local model="$3"

    local line_count
    line_count=$(echo "$raw_output" | wc -l)
    local first_line
    first_line=$(echo "$raw_output" | sed '/^[[:space:]]*$/d' | head -1)

    local fixup_prompt
    fixup_prompt="Your previous response was a conversational summary (${line_count} lines starting with: '${first_line:0:80}'). That is NOT what was requested. Output the COMPLETE content as specified in the original prompt. Start DIRECTLY with the content — no introductory text, no explanations, no preamble.

---

ORIGINAL PROMPT:

${original_prompt}"

    log_info "Fix-up: re-generating with explicit content instruction" >&2
    local output
    output=$(echo "$fixup_prompt" | claude -p --model "$model" --output-format text)
    echo "$output"
}

# Run claude headless and capture output, with validation + fix-up
# Args: $1=prompt, $2=description, $3=min_lines (optional, default 20)
claude_generate() {
    local prompt="$1"
    local description="$2"
    local min_lines="${3:-20}"

    log_info "Generating: $description" >&2
    local output
    output=$(echo "$prompt" | claude -p --model "$MODEL" --output-format text)

    if [[ -z "$output" ]]; then
        log_error "Generation failed (empty output): $description. Re-run with --resume to retry."
    fi

    if ! validate_generation "$output" "$min_lines"; then
        log_info "Attempting fix-up for: $description" >&2
        output=$(fixup_generate "$output" "$prompt" "$MODEL")

        if [[ -z "$output" ]]; then
            log_error "Fix-up generation failed (empty output): $description. Re-run with --resume to retry."
        fi

        if ! validate_generation "$output" "$min_lines"; then
            log_info "Warning: fix-up output still looks like a summary, proceeding anyway" >&2
        fi
    fi

    echo "$output"
}

# Run claude headless with design model, with validation + fix-up
# Args: $1=prompt, $2=description, $3=min_lines (optional, default 20)
claude_generate_design() {
    local prompt="$1"
    local description="$2"
    local min_lines="${3:-20}"

    log_info "Generating: $description (using $DESIGN_MODEL)" >&2
    local output
    output=$(echo "$prompt" | claude -p --model "$DESIGN_MODEL" --output-format text)

    if [[ -z "$output" ]]; then
        log_error "Generation failed (empty output): $description. Re-run with --resume to retry."
    fi

    if ! validate_generation "$output" "$min_lines"; then
        log_info "Attempting fix-up for: $description" >&2
        output=$(fixup_generate "$output" "$prompt" "$DESIGN_MODEL")

        if [[ -z "$output" ]]; then
            log_error "Fix-up generation failed (empty output): $description. Re-run with --resume to retry."
        fi

        if ! validate_generation "$output" "$min_lines"; then
            log_info "Warning: fix-up output still looks like a summary, proceeding anyway" >&2
        fi
    fi

    echo "$output"
}

# -----------------------------------------------------------------------------
# Prompt Resolution
# -----------------------------------------------------------------------------

# Resolve prompt file path using search order:
# 1. --prompts-dir <path> (CLI flag)
# 2. prompts/ in current directory (per-project override)
# 3. $SCRIPT_DIR/../prompts/ralph/ (default)
resolve_prompt() {
    local filename="$1"
    if [[ -n "$PROMPTS_DIR" ]] && [[ -f "$PROMPTS_DIR/$filename" ]]; then
        echo "$PROMPTS_DIR/$filename"
        return
    fi
    if [[ -f "prompts/$filename" ]]; then
        echo "prompts/$filename"
        return
    fi
    local default_path="$SCRIPT_DIR/../prompts/ralph/$filename"
    if [[ -f "$default_path" ]]; then
        echo "$default_path"
        return
    fi
    log_error "Prompt file not found: $filename (searched: ${PROMPTS_DIR:+$PROMPTS_DIR, }prompts/, $SCRIPT_DIR/../prompts/ralph/)"
}

# Load prompt file content
load_prompt() {
    local filename="$1"
    local path
    path=$(resolve_prompt "$filename")
    cat "$path"
}

# -----------------------------------------------------------------------------
# Stage Filtering
# -----------------------------------------------------------------------------

# Check if a stage should run (always true when --stage is not used)
should_run_stage() {
    local stage="$1"
    [[ "$STAGE_FILTER" = false ]] && return 0
    echo ",$STAGES," | grep -q ",$stage,"
}

# -----------------------------------------------------------------------------
# Argument Parsing
# -----------------------------------------------------------------------------

usage() {
    cat << EOF
Usage: $(basename "$0") <project_name> <concept_file> [options]
       $(basename "$0") <project_name> --design <design_file> [options]

Arguments:
  project_name    Name for the Ralph project (e.g., comment-system)
  concept_file    Path to markdown file describing project OUTCOMES

Options:
  --stage <stages>          Comma-separated stages to run (default: all)
                            Valid: worktree,dirs,design,review,refine,specs,agents,prompts,scaffold
  --design <file>           Use existing design document (skip design/review/refine)
  --review-design           With --design: run review+refine on provided design
  --prompts-dir <path>      Override prompt/template files directory
  --model <model>           Model for generation (default: sonnet)
  --design-model <model>    Model for design phase (default: sonnet)
  --resume                  Resume a previously failed run
  --help                    Show this help message

Environment Variables:
  RALPH_MODEL             Default model for file generation
  RALPH_DESIGN_MODEL      Model for design document generation

Example:
  $(basename "$0") comment-system ./CONCEPT.md
  $(basename "$0") auth-system ./auth-concept.md --design-model opus
  $(basename "$0") comment-system --design ./DESIGN.md
  $(basename "$0") comment-system --design ./draft.md --review-design
  $(basename "$0") comment-system ./CONCEPT.md --stage specs,agents,prompts
EOF
    exit 0
}

# Parse arguments
PROJECT_NAME=""
CONCEPT_FILE=""
RESUME=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --design-model)
            DESIGN_MODEL="$2"
            shift 2
            ;;
        --prompts-dir)
            PROMPTS_DIR="$2"
            [[ ! -d "$PROMPTS_DIR" ]] && log_error "Prompts directory not found: $PROMPTS_DIR"
            shift 2
            ;;
        --stage)
            STAGE_FILTER=true
            STAGES="$2"
            shift 2
            ;;
        --design)
            DESIGN_FILE="$2"
            shift 2
            ;;
        --review-design)
            REVIEW_DESIGN=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        --resume)
            RESUME=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            ;;
        *)
            if [[ -z "$PROJECT_NAME" ]]; then
                PROJECT_NAME="$1"
            elif [[ -z "$CONCEPT_FILE" ]]; then
                CONCEPT_FILE="$1"
            else
                log_error "Too many arguments"
            fi
            shift
            ;;
    esac
done

# Validate --stage names
if [[ "$STAGE_FILTER" = true ]]; then
    IFS=',' read -ra STAGE_ARRAY <<< "$STAGES"
    for stage in "${STAGE_ARRAY[@]}"; do
        if ! echo ",$VALID_STAGES," | grep -q ",$stage,"; then
            log_error "Unknown stage: $stage (valid: $VALID_STAGES)"
        fi
    done
fi

# Validate --review-design requires --design
if [[ "$REVIEW_DESIGN" = true ]] && [[ -z "$DESIGN_FILE" ]]; then
    log_error "--review-design requires --design <file>"
fi

# Validate arguments
[[ -z "$PROJECT_NAME" ]] && log_error "Missing project_name argument. Run with --help for usage."
PACKAGE_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')

# Validate we're in a git repo
git rev-parse --git-dir > /dev/null 2>&1 || log_error "Not in a git repository"

# Validate --design file exists
if [[ -n "$DESIGN_FILE" ]] && [[ ! -f "$DESIGN_FILE" ]]; then
    log_error "Design file not found: $DESIGN_FILE"
fi

# -----------------------------------------------------------------------------
# Determine Paths
# -----------------------------------------------------------------------------

REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_NAME=$(basename "$REPO_ROOT")
WORKTREE_NAME="${BASE_NAME}_${PROJECT_NAME}"
WORKTREE_PATH="$(dirname "$REPO_ROOT")/$WORKTREE_NAME"
BRANCH_NAME="ralph/$PROJECT_NAME"

# Read concept file (optional on --resume or --design if design steps are already done)
CONCEPT_CONTENT=""
if [[ -n "$CONCEPT_FILE" ]] && [[ -f "$CONCEPT_FILE" ]]; then
    CONCEPT_CONTENT=$(cat "$CONCEPT_FILE")
elif [[ "$RESUME" = true ]]; then
    log_info "Concept file not available — OK for resume if design steps are complete"
elif [[ -n "$DESIGN_FILE" ]]; then
    log_info "Concept file not provided — using --design mode"
else
    [[ -z "$CONCEPT_FILE" ]] && log_error "Missing concept_file argument. Run with --help for usage."
    log_error "Concept file not found: $CONCEPT_FILE"
fi

# Read design file if provided
DESIGN_INPUT_CONTENT=""
if [[ -n "$DESIGN_FILE" ]]; then
    DESIGN_INPUT_CONTENT=$(cat "$DESIGN_FILE")
fi

echo -e "\n${GREEN}Ralph Init — Automated Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Project:    $PROJECT_NAME"
echo "  Base Repo:  $BASE_NAME"
echo "  Worktree:   $WORKTREE_PATH"
echo "  Branch:     $BRANCH_NAME"
echo "  Model:      $MODEL (design: $DESIGN_MODEL)"
[[ "$STAGE_FILTER" = true ]] && echo "  Stages:     $STAGES"
[[ -n "$DESIGN_FILE" ]] && echo "  Design:     $DESIGN_FILE${REVIEW_DESIGN:+ (with review)}"
[[ -n "$PROMPTS_DIR" ]] && echo "  Prompts:    $PROMPTS_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# -----------------------------------------------------------------------------
# Step 1: Create Worktree
# -----------------------------------------------------------------------------

if should_run_stage "worktree"; then

if [[ -d "$WORKTREE_PATH" ]]; then
    # Worktree already exists — enter it
    log_step "$(step_header worktree 1 10 "Entering existing worktree")"
    cd "$WORKTREE_PATH"
    log_info "Entered existing worktree: $WORKTREE_PATH"
elif git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    # Branch exists but worktree dir doesn't — attach worktree to existing branch
    log_step "$(step_header worktree 1 10 "Creating git worktree (existing branch)")"
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    cd "$WORKTREE_PATH"
    log_info "Created worktree at $WORKTREE_PATH (attached to existing branch $BRANCH_NAME)"
else
    # Fresh start — create branch and worktree
    log_step "$(step_header worktree 1 10 "Creating git worktree")"
    git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
    cd "$WORKTREE_PATH"
    log_info "Created worktree at $WORKTREE_PATH"
fi

else
    # Worktree stage skipped — enter existing worktree if it exists
    if [[ -d "$WORKTREE_PATH" ]]; then
        cd "$WORKTREE_PATH"
        log_info "Entered existing worktree: $WORKTREE_PATH"
    fi
fi

# Save concept file into worktree for traceability
if [[ -n "$CONCEPT_CONTENT" ]]; then
    echo "$CONCEPT_CONTENT" > CONCEPT.md
    log_info "Saved concept file as CONCEPT.md"
elif [[ "$RESUME" = true ]] && [[ -f "CONCEPT.md" ]]; then
    CONCEPT_CONTENT=$(cat CONCEPT.md)
    log_info "Loaded concept from existing CONCEPT.md"
fi

# Handle --design file: copy into worktree
DESIGN_DOC=""
if [[ -n "$DESIGN_INPUT_CONTENT" ]]; then
    if [[ "$REVIEW_DESIGN" = true ]]; then
        echo "$DESIGN_INPUT_CONTENT" > DESIGN_v1.md
        DESIGN_DOC="$DESIGN_INPUT_CONTENT"
        log_info "Copied design file to DESIGN_v1.md (will review+refine)"
    else
        echo "$DESIGN_INPUT_CONTENT" > DESIGN.md
        DESIGN_DOC="$DESIGN_INPUT_CONTENT"
        log_info "Copied design file to DESIGN.md (skipping design/review/refine)"
    fi
fi

# -----------------------------------------------------------------------------
# Logging Setup (after worktree exists)
# -----------------------------------------------------------------------------

LOG_FILE="ralph-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log_timestamp "Ralph Init started"
log_timestamp "Project: $PROJECT_NAME | Model: $MODEL | Design Model: $DESIGN_MODEL"
log_timestamp "Worktree: $WORKTREE_PATH | Branch: $BRANCH_NAME"
[[ "$RESUME" = true ]] && log_timestamp "Mode: RESUME"
[[ "$STAGE_FILTER" = true ]] && log_timestamp "Stages: $STAGES"
[[ -n "$DESIGN_FILE" ]] && log_timestamp "Design input: $DESIGN_FILE (review: $REVIEW_DESIGN)"

# -----------------------------------------------------------------------------
# Step 2: Create Directory Structure
# -----------------------------------------------------------------------------

if should_run_stage "dirs"; then

if [[ "$RESUME" = true ]] && step_complete 2 "Directory structure" "specs/" "src/" "tests/"; then
    :
else

log_step "$(step_header dirs 2 10 "Creating directory structure")"
log_timestamp "START Step 2: Creating directory structure"

mkdir -p specs
mkdir -p src
mkdir -p tests

log_info "Created: specs/, src/, tests/"
log_timestamp "END   Step 2: Success"

fi

fi  # dirs stage

# -----------------------------------------------------------------------------
# Step 3: Generate Design Document from Concept (3-turn: design → review → refine)
# -----------------------------------------------------------------------------

if should_run_stage "design"; then

if [[ -n "$DESIGN_FILE" ]]; then
    log_info "[design] Skipped — using provided design file"
elif [[ "$RESUME" = true ]] && step_complete 3 "Initial design" "DESIGN_v1.md"; then
    DESIGN_DOC=$(cat DESIGN_v1.md)
else

log_step "$(step_header design 3 10 "Generating initial design document")"
log_timestamp "START Step 3: Generating initial design document"

DESIGN_PROMPT=$(load_prompt "design.prompt.md")
DESIGN_DOC=$(claude_generate_design "${DESIGN_PROMPT}${CONCEPT_CONTENT}" "Initial design")
echo "$DESIGN_DOC" > DESIGN_v1.md

log_info "Generated: DESIGN_v1.md"
log_timestamp "END   Step 3: Success"

fi

fi  # design stage

# -----------------------------------------------------------------------------
# Step 3b: Design Review
# -----------------------------------------------------------------------------

if should_run_stage "review"; then

if [[ -n "$DESIGN_FILE" ]] && [[ "$REVIEW_DESIGN" != true ]]; then
    log_info "[review] Skipped — using provided design file"
elif [[ "$RESUME" = true ]] && step_complete 4 "Design review" "DESIGN_REVIEW.md"; then
    DESIGN_REVIEW=$(cat DESIGN_REVIEW.md)
else

# Prerequisite: load DESIGN_v1.md if not in memory
if [[ -z "$DESIGN_DOC" ]] && [[ -f "DESIGN_v1.md" ]]; then
    DESIGN_DOC=$(cat DESIGN_v1.md)
    log_info "Loaded DESIGN_v1.md from disk"
elif [[ -z "$DESIGN_DOC" ]]; then
    log_error "review stage requires DESIGN_v1.md but it does not exist. Run the design stage first."
fi

log_step "$(step_header review 4 10 "Reviewing design (critic agent)")"
log_timestamp "START Step 4: Reviewing design (critic agent)"

REVIEW_PROMPT=$(load_prompt "review.prompt.md")

REVIEW_INPUT="${REVIEW_PROMPT}${CONCEPT_CONTENT}

---

DESIGN DOCUMENT TO REVIEW:

${DESIGN_DOC}"

DESIGN_REVIEW=$(claude_generate_design "$REVIEW_INPUT" "Design review")
echo "$DESIGN_REVIEW" > DESIGN_REVIEW.md

log_info "Generated: DESIGN_REVIEW.md"
log_timestamp "END   Step 4: Success"

fi

fi  # review stage

# -----------------------------------------------------------------------------
# Step 3c: Refine Design Based on Review
# -----------------------------------------------------------------------------

if should_run_stage "refine"; then

if [[ -n "$DESIGN_FILE" ]] && [[ "$REVIEW_DESIGN" != true ]]; then
    log_info "[refine] Skipped — using provided design file"
elif [[ "$RESUME" = true ]] && step_complete 5 "Refined design" "DESIGN.md"; then
    DESIGN_DOC=$(cat DESIGN.md)
else

# Prerequisite: load DESIGN_v1.md if not in memory
if [[ -z "$DESIGN_DOC" ]] && [[ -f "DESIGN_v1.md" ]]; then
    DESIGN_DOC=$(cat DESIGN_v1.md)
    log_info "Loaded DESIGN_v1.md from disk"
elif [[ -z "$DESIGN_DOC" ]]; then
    log_error "refine stage requires DESIGN_v1.md but it does not exist. Run the design stage first."
fi

# Prerequisite: load DESIGN_REVIEW.md if not in memory
if [[ -z "${DESIGN_REVIEW:-}" ]] && [[ -f "DESIGN_REVIEW.md" ]]; then
    DESIGN_REVIEW=$(cat DESIGN_REVIEW.md)
    log_info "Loaded DESIGN_REVIEW.md from disk"
elif [[ -z "${DESIGN_REVIEW:-}" ]]; then
    log_error "refine stage requires DESIGN_REVIEW.md but it does not exist. Run the review stage first."
fi

log_step "$(step_header refine 5 10 "Refining design based on review")"
log_timestamp "START Step 5: Refining design based on review"

REFINE_PROMPT=$(load_prompt "refine.prompt.md")

REFINE_INPUT="${REFINE_PROMPT}${CONCEPT_CONTENT}

---

ORIGINAL DESIGN (V1):

${DESIGN_DOC}

---

DESIGN REVIEW:

${DESIGN_REVIEW}"

DESIGN_DOC=$(claude_generate_design "$REFINE_INPUT" "Refined design")
echo "$DESIGN_DOC" > DESIGN.md

log_info "Generated: DESIGN.md (refined)"
log_timestamp "END   Step 5: Success"

fi

fi  # refine stage

# -----------------------------------------------------------------------------
# Step 4: Generate Specs from Design
# -----------------------------------------------------------------------------

if should_run_stage "specs"; then

# Prerequisite: load DESIGN.md if not in memory
if [[ -z "$DESIGN_DOC" ]] && [[ -f "DESIGN.md" ]]; then
    DESIGN_DOC=$(cat DESIGN.md)
    log_info "Loaded DESIGN.md from disk"
elif [[ -z "$DESIGN_DOC" ]]; then
    log_error "specs stage requires DESIGN.md but it does not exist. Run the design stages first."
fi

if resume_step6; then
    :
else

log_step "$(step_header specs 6 10 "Generating specification files")"
log_timestamp "START Step 6: Generating specification files"

SPECS_PROMPT=$(load_prompt "specs.prompt.md")
SPECS_FULL_PROMPT="${SPECS_PROMPT}${DESIGN_DOC}"
SPECS_OUTPUT=$(claude_generate "$SPECS_FULL_PROMPT" "Specification files")

# Spec-specific validation using validate-specs-output.sh
SPEC_VALIDATION=$(echo "$SPECS_OUTPUT" | "$SCRIPT_DIR/validate-specs-output.sh" 2>&1) || true

if [[ "$SPEC_VALIDATION" == PASS:* ]]; then
    log_info "Spec validation: $SPEC_VALIDATION" >&2
else
    # First attempt failed — save raw output and retry with fix-up
    log_info "Spec validation failed: $SPEC_VALIDATION" >&2
    echo "$SPECS_OUTPUT" > specs/_raw_output_attempt1.md
    log_info "Raw output saved to specs/_raw_output_attempt1.md" >&2

    SPEC_FIXUP_PROMPT="Your previous response FAILED machine validation:

${SPEC_VALIDATION}

The parser requires EXACTLY this format for each spec:

\`\`\`markdown specs/FILENAME.md
# Topic Name
(spec content)
\`\`\`

Start DIRECTLY with the first fenced block. No introductory text.
Reformat the following content into properly fenced spec blocks.

---

RAW OUTPUT TO REFORMAT:

${SPECS_OUTPUT}

---

ORIGINAL PROMPT (for context):

${SPECS_FULL_PROMPT}"

    SPECS_OUTPUT=$(claude_generate "$SPEC_FIXUP_PROMPT" "Specification files (fix-up)")

    SPEC_VALIDATION=$(echo "$SPECS_OUTPUT" | "$SCRIPT_DIR/validate-specs-output.sh" 2>&1) || true

    if [[ "$SPEC_VALIDATION" == PASS:* ]]; then
        log_info "Spec validation (fix-up): $SPEC_VALIDATION" >&2
    else
        echo "$SPECS_OUTPUT" > specs/_raw_output.md
        log_error "Spec validation failed after fix-up: $SPEC_VALIDATION. Raw outputs saved to specs/_raw_output_attempt1.md and specs/_raw_output.md. Re-run with --resume to retry this step."
    fi
fi

# Parse specs from output - look for ```markdown specs/*.md blocks
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

# Count generated specs (use find to avoid pipefail issues with ls)
SPEC_COUNT=$(find specs -maxdepth 1 -name '*.md' ! -name '_raw_output.md' ! -name '_raw_output_attempt1.md' -size +0c 2>/dev/null | wc -l)
log_info "Generated: $SPEC_COUNT spec files in specs/"

# Fail hard if no specs were parsed
if [[ "$SPEC_COUNT" -eq 0 ]]; then
    echo "$SPECS_OUTPUT" > specs/_raw_output.md
    log_error "Failed to parse any specs from Claude output. Raw output saved to specs/_raw_output.md. Re-run with --resume to retry this step."
fi

log_timestamp "END   Step 6: Success"

fi

fi  # specs stage

# -----------------------------------------------------------------------------
# Step 5: Generate AGENTS.md
# -----------------------------------------------------------------------------

if should_run_stage "agents"; then

# Prerequisite: load DESIGN.md if not in memory
if [[ -z "$DESIGN_DOC" ]] && [[ -f "DESIGN.md" ]]; then
    DESIGN_DOC=$(cat DESIGN.md)
    log_info "Loaded DESIGN.md from disk"
elif [[ -z "$DESIGN_DOC" ]]; then
    log_error "agents stage requires DESIGN.md but it does not exist. Run the design stages first."
fi

if [[ "$RESUME" = true ]] && step_complete 7 "AGENTS.md" "AGENTS.md"; then
    :
else

log_step "$(step_header agents 7 10 "Generating AGENTS.md")"
log_timestamp "START Step 7: Generating AGENTS.md"

AGENTS_PROMPT=$(load_prompt "agents.prompt.md")
AGENTS_OUTPUT=$(claude_generate "${AGENTS_PROMPT}${DESIGN_DOC}" "AGENTS.md")
echo "$AGENTS_OUTPUT" > AGENTS.md

log_info "Generated: AGENTS.md"
log_timestamp "END   Step 7: Success"

fi

fi  # agents stage

# -----------------------------------------------------------------------------
# Step 6: Write PROMPT_plan.md and PROMPT_build.md
# -----------------------------------------------------------------------------

if should_run_stage "prompts"; then

# PROMPT_plan.md
if [[ "$RESUME" = true ]] && step_complete 8 "PROMPT_plan.md" "PROMPT_plan.md"; then
    :
else

log_step "$(step_header prompts 8 10 "Writing PROMPT_plan.md")"
log_timestamp "START Step 8: Writing PROMPT_plan.md"

cp "$(resolve_prompt prompt_plan.tpl.md)" PROMPT_plan.md

log_info "Written: PROMPT_plan.md"
log_timestamp "END   Step 8: Success"

fi

# PROMPT_build.md
if [[ "$RESUME" = true ]] && step_complete 9 "PROMPT_build.md" "PROMPT_build.md"; then
    :
else

log_step "$(step_header prompts 9 10 "Writing PROMPT_build.md")"
log_timestamp "START Step 9: Writing PROMPT_build.md"

sed "s|\${PACKAGE_NAME}|$PACKAGE_NAME|g" "$(resolve_prompt prompt_build.tpl.md)" > PROMPT_build.md

log_info "Written: PROMPT_build.md"
log_timestamp "END   Step 9: Success"

fi

fi  # prompts stage

# -----------------------------------------------------------------------------
# Step 8: Create Loop Script and Scaffold
# -----------------------------------------------------------------------------

if should_run_stage "scaffold"; then

log_step "$(step_header scaffold 10 10 "Creating loop.sh and project scaffold")"
log_timestamp "START Step 10: Creating loop.sh and project scaffold"

if [[ "$RESUME" = true ]] && [[ -f "loop.sh" ]] && [[ -f "pyproject.toml" ]]; then
    log_info "[SKIPPED] Scaffold creation — files already exist"
else

# Create loop.sh
cat << 'LOOP_SCRIPT' > loop.sh
#!/bin/bash
# Ralph Wiggum Loop — Fresh context per iteration
# Usage: ./loop.sh [plan] [max_iterations]

if [ "$1" = "plan" ]; then
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=$1
else
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:   $MODE"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ ! -f "$PROMPT_FILE" ] && echo "Error: $PROMPT_FILE not found" && exit 1

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    cat "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --model sonnet \
        --verbose

    git push origin "$CURRENT_BRANCH" 2>/dev/null || \
        git push -u origin "$CURRENT_BRANCH"

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done
LOOP_SCRIPT

chmod +x loop.sh
log_info "Created: loop.sh"

# Create Python project scaffold
cat << 'PYPROJECT' > pyproject.toml
[project]
name = "ralph-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "ruff>=0.4",
    "mypy>=1.10",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.mypy]
python_version = "3.11"
strict = true
PYPROJECT

# Create source package
mkdir -p "src/$PACKAGE_NAME"
echo '"""Ralph project package."""' > "src/$PACKAGE_NAME/__init__.py"

# Create test scaffold
cat << 'CONFTEST' > tests/conftest.py
"""Pytest configuration and fixtures."""
import pytest
CONFTEST

echo '"""Test package."""' > tests/__init__.py

# Create .gitignore
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

log_info "Created: pyproject.toml, src/$PACKAGE_NAME/, tests/"

fi

# Build commit message dynamically based on which files exist
COMMIT_BODY=""
[[ -f "DESIGN_v1.md" ]] && COMMIT_BODY="${COMMIT_BODY}- DESIGN_v1.md: Initial design from concept
"
[[ -f "DESIGN_REVIEW.md" ]] && COMMIT_BODY="${COMMIT_BODY}- DESIGN_REVIEW.md: Critical review of initial design
"
[[ -f "DESIGN.md" ]] && COMMIT_BODY="${COMMIT_BODY}- DESIGN.md: Refined design (addresses review)
"
[[ -d "specs" ]] && [[ "$(find specs -maxdepth 1 -name '*.md' ! -name '_raw_output*' -size +0c 2>/dev/null | wc -l)" -gt 0 ]] && COMMIT_BODY="${COMMIT_BODY}- specs/: Individual specifications
"
[[ -f "AGENTS.md" ]] && COMMIT_BODY="${COMMIT_BODY}- AGENTS.md: Operational guide
"
[[ -f "PROMPT_plan.md" ]] && COMMIT_BODY="${COMMIT_BODY}- PROMPT_plan.md: Planning mode prompt
"
[[ -f "PROMPT_build.md" ]] && COMMIT_BODY="${COMMIT_BODY}- PROMPT_build.md: Building mode prompt
"
[[ -f "loop.sh" ]] && COMMIT_BODY="${COMMIT_BODY}- loop.sh: Ralph loop script
"
[[ -f "pyproject.toml" ]] && COMMIT_BODY="${COMMIT_BODY}- Python project scaffold
"

COMMIT_SUBJECT="ralph-init: scaffold for $PROJECT_NAME"
[[ "$RESUME" = true ]] && COMMIT_SUBJECT="${COMMIT_SUBJECT} (resumed)"

git add -A
if ! git diff --cached --quiet 2>/dev/null; then
    if [[ "$RESUME" = true ]] && git log --oneline -1 2>/dev/null | grep -q "ralph-init: scaffold"; then
        git commit --amend -m "${COMMIT_SUBJECT}

Generated by ralph-init.sh:
${COMMIT_BODY}"
    else
        git commit -m "${COMMIT_SUBJECT}

Generated by ralph-init.sh:
${COMMIT_BODY}"
    fi
    log_info "Created initial commit"
else
    log_info "No new changes to commit"
fi
log_timestamp "END   Step 10: Success"

fi  # scaffold stage

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Ralph setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "Generated files:"
[[ -f "DESIGN_v1.md" ]] && echo "  📄 DESIGN_v1.md        — Initial design (pre-review)"
[[ -f "DESIGN_REVIEW.md" ]] && echo "  📄 DESIGN_REVIEW.md    — Critical review of initial design"
[[ -f "DESIGN.md" ]] && echo "  📄 DESIGN.md           — Refined design (addresses review)"
[[ -d "specs" ]] && [[ "$SPEC_COUNT" -gt 0 ]] && echo "  📁 specs/              — $SPEC_COUNT specification files"
[[ -f "AGENTS.md" ]] && echo "  📄 AGENTS.md           — Operational guide"
[[ -f "PROMPT_plan.md" ]] && echo "  📄 PROMPT_plan.md      — Planning mode prompt"
[[ -f "PROMPT_build.md" ]] && echo "  📄 PROMPT_build.md     — Building mode prompt"
[[ -f "loop.sh" ]] && echo "  📄 loop.sh             — Ralph loop script"
echo ""
echo "Next steps:"
echo ""
echo "  1. Review the design evolution:"
echo "     - DESIGN_v1.md → DESIGN_REVIEW.md → DESIGN.md"
echo "     - Check the 'Changes from V1' section in DESIGN.md"
echo -e "     ${YELLOW}cd $WORKTREE_PATH${NC}"
echo ""
echo "  2. Review specs/ for completeness"
echo ""
echo "  3. Install dev dependencies:"
echo -e "     ${YELLOW}uv sync --extra dev${NC}"
echo ""
echo "  4. Run planning phase (generates IMPLEMENTATION_PLAN.md):"
echo -e "     ${YELLOW}./loop.sh plan 3${NC}"
echo ""
echo "  5. Review the plan, then start building:"
echo -e "     ${YELLOW}./loop.sh 10${NC}"
echo ""
echo "  6. Watch the first few iterations, tune as needed."
echo ""
