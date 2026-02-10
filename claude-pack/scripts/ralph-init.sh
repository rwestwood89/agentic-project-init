#!/bin/bash
set -euo pipefail

# =============================================================================
# ralph-init.sh — Automated Ralph Wiggum Loop Setup
# =============================================================================
#
# Usage: ./ralph-init.sh <project_name> <concept_file> [--model <model>]
#
# Example:
#   ./ralph-init.sh comment-system ./CONCEPT.md
#   ./ralph-init.sh comment-system ./CONCEPT.md --model opus
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
# Argument Parsing
# -----------------------------------------------------------------------------

usage() {
    cat << EOF
Usage: $(basename "$0") <project_name> <concept_file> [options]

Arguments:
  project_name    Name for the Ralph project (e.g., comment-system)
  concept_file    Path to markdown file describing project OUTCOMES

Options:
  --model <model>         Model for generation (default: sonnet)
  --design-model <model>  Model for design phase (default: sonnet, consider opus)
  --resume                Resume a previously failed run (skips completed steps)
  --help                  Show this help message

Environment Variables:
  RALPH_MODEL             Default model for file generation
  RALPH_DESIGN_MODEL      Model for design document generation

Example:
  $(basename "$0") comment-system ./CONCEPT.md
  $(basename "$0") auth-system ./auth-concept.md --design-model opus
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

# Validate arguments
[[ -z "$PROJECT_NAME" ]] && log_error "Missing project_name argument. Run with --help for usage."
PACKAGE_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')

# Validate we're in a git repo
git rev-parse --git-dir > /dev/null 2>&1 || log_error "Not in a git repository"

# -----------------------------------------------------------------------------
# Determine Paths
# -----------------------------------------------------------------------------

REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_NAME=$(basename "$REPO_ROOT")
WORKTREE_NAME="${BASE_NAME}_${PROJECT_NAME}"
WORKTREE_PATH="$(dirname "$REPO_ROOT")/$WORKTREE_NAME"
BRANCH_NAME="ralph/$PROJECT_NAME"

# Read concept file (optional on --resume if design steps are already done)
CONCEPT_CONTENT=""
if [[ -n "$CONCEPT_FILE" ]] && [[ -f "$CONCEPT_FILE" ]]; then
    CONCEPT_CONTENT=$(cat "$CONCEPT_FILE")
elif [[ "$RESUME" = true ]]; then
    log_info "Concept file not available — OK for resume if design steps are complete"
else
    [[ -z "$CONCEPT_FILE" ]] && log_error "Missing concept_file argument. Run with --help for usage."
    log_error "Concept file not found: $CONCEPT_FILE"
fi

echo -e "\n${GREEN}Ralph Init — Automated Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Project:    $PROJECT_NAME"
echo "  Base Repo:  $BASE_NAME"
echo "  Worktree:   $WORKTREE_PATH"
echo "  Branch:     $BRANCH_NAME"
echo "  Model:      $MODEL (design: $DESIGN_MODEL)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# -----------------------------------------------------------------------------
# Step 1: Create Worktree
# -----------------------------------------------------------------------------

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

# Save concept file into worktree for traceability
if [[ -n "$CONCEPT_CONTENT" ]]; then
    echo "$CONCEPT_CONTENT" > CONCEPT.md
    log_info "Saved concept file as CONCEPT.md"
elif [[ "$RESUME" = true ]] && [[ -f "CONCEPT.md" ]]; then
    CONCEPT_CONTENT=$(cat CONCEPT.md)
    log_info "Loaded concept from existing CONCEPT.md"
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

# -----------------------------------------------------------------------------
# Step 2: Create Directory Structure
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 2 "Directory structure" "specs/" "src/" "tests/"; then
    :
else

log_step "Step 2/10: Creating directory structure"
log_timestamp "START Step 2: Creating directory structure"

mkdir -p specs
mkdir -p src
mkdir -p tests

log_info "Created: specs/, src/, tests/"
log_timestamp "END   Step 2: Success"

fi

# -----------------------------------------------------------------------------
# Step 3: Generate Design Document from Concept (3-turn: design → review → refine)
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 3 "Initial design" "DESIGN_v1.md"; then
    DESIGN_DOC=$(cat DESIGN_v1.md)
else

log_step "Step 3/10: Generating initial design document"
log_timestamp "START Step 3: Generating initial design document"

DESIGN_PROMPT=$(cat << 'PROMPT_END'
I have a project concept focused on OUTCOMES. I need you to create a 
detailed DESIGN DOCUMENT that specifies the architecture and implementation
approach. This design will be used to generate specifications for an
automated coding agent (Ralph Wiggum loop).

Create a design document that includes:

## 1. Overview
- One paragraph summary of what this system does
- Primary use cases (3-5 bullet points)

## 2. Data Model
- Core entities and their relationships
- Schema definitions (use TypeScript interfaces or JSON Schema style)
- Storage format decisions (files, database, etc.)

## 3. Architecture
- Component breakdown (what are the major pieces?)
- How components interact (data flow)
- Key interfaces between components

## 4. Core Algorithms
- Any non-trivial logic that needs careful implementation
- Edge cases that must be handled
- Performance considerations

## 5. External Interfaces
- CLI commands (if applicable)
- API endpoints or MCP tools (if applicable)
- File formats for input/output

## 6. Constraints & Invariants
- Rules that must NEVER be violated
- Security considerations
- Determinism requirements

## 7. Phasing (optional)
- If this is a multi-phase project, what's in Phase 1 vs later?
- What can be deferred?

Keep the design:
- Concrete enough that a coding agent can implement it
- Abstract enough that implementation details are left to the agent
- Focused on WHAT and WHY, not line-by-line HOW

YOUR ENTIRE RESPONSE IS THE OUTPUT FILE. Start directly with the markdown
content (e.g., "# Design Document ..."). Do not summarize, describe, or
comment on the document — just produce it. No preamble, no explanation.

---

PROJECT CONCEPT:

PROMPT_END
)

DESIGN_DOC=$(claude_generate_design "${DESIGN_PROMPT}${CONCEPT_CONTENT}" "Initial design")
echo "$DESIGN_DOC" > DESIGN_v1.md

log_info "Generated: DESIGN_v1.md"
log_timestamp "END   Step 3: Success"

fi

# -----------------------------------------------------------------------------
# Step 3b: Design Review
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 4 "Design review" "DESIGN_REVIEW.md"; then
    DESIGN_REVIEW=$(cat DESIGN_REVIEW.md)
else

log_step "Step 4/10: Reviewing design (critic agent)"
log_timestamp "START Step 4: Reviewing design (critic agent)"

REVIEW_PROMPT=$(cat << 'PROMPT_END'
You are a design review specialist. Your goal is to critically evaluate this 
design document to catch issues before implementation begins.

**This is a CRITICAL REVIEW - be skeptical and thorough:**
- Verify the design actually satisfies the concept/requirements
- Challenge architectural decisions and abstractions
- Look for ambiguity, duplication, and hidden complexity
- Identify missing pieces that will cause problems during implementation

## Review Process

Evaluate the design along each dimension below. For each dimension, provide:
- **Assessment**: Pass / Concerns / Fail
- **Findings**: Specific observations with references to design sections
- **Recommendations**: Concrete suggestions if issues found

### Dimension 1: Concept Compliance

Does the design meet the stated outcomes?

- Does every outcome in the concept have a corresponding design element?
- Are edge cases accounted for?
- Does the design serve the stated goals?

### Dimension 2: Abstraction Quality

Are abstractions clean and maintainable?

- Are abstractions at the right level (not too general, not too specific)?
- Is the component hierarchy logical and easy to understand?
- Are responsibilities clearly separated?
- Would a developer understand the design quickly?

### Dimension 3: Duplication Avoidance

Does it avoid unnecessary duplication?

- Are there opportunities to consolidate similar components?
- Does it create parallel structures that will drift over time?
- Are there redundant data representations?

### Dimension 4: Data Structure Clarity

Are data structures explicit and intuitive?

- Are data classes well-defined with clear fields and types?
- Are there ambiguous objects (e.g., generic dicts, untyped maps)?
- Is the data flow explicit and traceable?
- Are schemas/interfaces clearly specified?

### Dimension 5: Interface Completeness

Are external interfaces well-defined?

- Are all CLI commands/API endpoints explicitly declared?
- Are input/output formats unambiguous?
- Are error cases handled?
- Could ambiguous interfaces lead to misuse?

### Dimension 6: Implementability

Can this actually be built as specified?

- Are there circular dependencies?
- Are there missing components that other components depend on?
- Is the phasing realistic (Phase 1 actually standalone)?
- Are there implicit assumptions that should be explicit?

## Output Format

```markdown
# Design Review

## Dimensional Assessment

### 1. Concept Compliance
**Assessment:** [Pass / Concerns / Fail]
[Specific findings]

### 2. Abstraction Quality
**Assessment:** [Pass / Concerns / Fail]
[Specific findings]

### 3. Duplication Avoidance
**Assessment:** [Pass / Concerns / Fail]
[Specific findings]

### 4. Data Structure Clarity
**Assessment:** [Pass / Concerns / Fail]
[Specific findings]

### 5. Interface Completeness
**Assessment:** [Pass / Concerns / Fail]
[Specific findings]

### 6. Implementability
**Assessment:** [Pass / Concerns / Fail]
[Specific findings]

---

## Issues by Severity

### Critical (Must address before implementation)
- [Issue]: [Description] — [Which dimension]

### Major (Should address)
- [Issue]: [Description] — [Which dimension]

### Minor (Consider addressing)
- [Issue]: [Description] — [Which dimension]

---

## Specific Recommendations

1. [Most important fix with concrete suggestion]
2. [Second priority]
3. [Additional suggestions]

---

**Overall:** [Approve / Revise / Rework]
```

Be specific. Reference exact sections. Every issue should have a suggested resolution.

YOUR ENTIRE RESPONSE IS THE OUTPUT FILE. Start directly with "# Design Review".
Do not summarize, describe, or comment on the review — just produce it.
No preamble, no explanation.

---

CONCEPT:

PROMPT_END
)

REVIEW_INPUT="${REVIEW_PROMPT}${CONCEPT_CONTENT}

---

DESIGN DOCUMENT TO REVIEW:

${DESIGN_DOC}"

DESIGN_REVIEW=$(claude_generate_design "$REVIEW_INPUT" "Design review")
echo "$DESIGN_REVIEW" > DESIGN_REVIEW.md

log_info "Generated: DESIGN_REVIEW.md"
log_timestamp "END   Step 4: Success"

fi

# -----------------------------------------------------------------------------
# Step 3c: Refine Design Based on Review
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 5 "Refined design" "DESIGN.md"; then
    DESIGN_DOC=$(cat DESIGN.md)
else

log_step "Step 5/10: Refining design based on review"
log_timestamp "START Step 5: Refining design based on review"

REFINE_PROMPT=$(cat << 'PROMPT_END'
Below is an initial design document (V1) and a critical review of that design.
Produce a REFINED DESIGN (V2) that addresses the review findings.

Instructions:
1. Read the review carefully — especially Critical and Major issues
2. Address each issue explicitly in the refined design
3. Keep what works — don't rewrite sections that passed review
4. For each significant change, add a brief note explaining the change

At the end of the refined design, include a section:

## Changes from V1

- [Change 1]: [Why — which review issue it addresses]
- [Change 2]: [Why]
- ...

YOUR ENTIRE RESPONSE IS THE OUTPUT FILE. Start directly with the markdown
content (e.g., "# Design Document ..."). Do not summarize, describe, or
comment on the document — just produce it. No preamble, no explanation.

---

ORIGINAL CONCEPT:

PROMPT_END
)

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

# -----------------------------------------------------------------------------
# Step 4: Generate Specs from Design
# -----------------------------------------------------------------------------

if resume_step6; then
    :
else

log_step "Step 6/10: Generating specification files"
log_timestamp "START Step 6: Generating specification files"

SPECS_PROMPT=$(cat << 'PROMPT_END'
I'm setting up a Ralph Wiggum loop to build this system. Ralph loops work by 
having an AI agent iterate in a bash loop, each iteration getting fresh context. 
The agent reads specs, picks a task from an implementation plan, implements it, 
runs tests, commits, and exits.

Break this design into individual specification files for a `specs/` directory. 
Each spec should cover ONE topic of concern — a distinct capability area that 
can be described in one sentence without using "and" to conjoin unrelated things.

For EACH spec file, use this exact format:

```markdown specs/[filename].md
# [Topic Name]

## Purpose
[One sentence describing what this component does]

## Requirements
[Behavioral outcomes as bullet points - what observable results indicate success?]

## Acceptance Criteria
[Specific, testable conditions using Given/When/Then or similar]

## Interfaces
[How this connects to other components - inputs, outputs, data formats]
[Reference other spec files by name where relevant]

## Constraints
[Non-negotiable rules - what must NEVER happen?]

## Out of Scope
[What this spec explicitly does NOT cover]
```

Important:
- Use the EXACT format above with ```markdown specs/filename.md as the code fence
- Each spec should be 50-150 lines
- Order specs by dependency (foundational first)
- Acceptance criteria should be machine-verifiable where possible
- Think about what tests would catch bad implementations

CRITICAL FORMAT REQUIREMENT:
Your output will be parsed by a machine. The parser scans for lines matching
exactly: ```markdown specs/FILENAME.md  (opening fence with path)
and extracts content until the next ``` (closing fence).

If the parser finds ZERO matching fences, the entire step FAILS.
Common mistakes that cause FAIL:
- Writing a prose summary like "I've created 16 specification files..."
- Using ```md instead of ```markdown
- Omitting the specs/ path prefix
- Adding extra text before the first fenced block

Start DIRECTLY with the first ```markdown specs/... fenced block.
Do NOT include any introductory text, summary, or explanation before or between spec blocks.

---

DESIGN DOCUMENT:

PROMPT_END
)

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

# -----------------------------------------------------------------------------
# Step 5: Generate AGENTS.md
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 7 "AGENTS.md" "AGENTS.md"; then
    :
else

log_step "Step 7/10: Generating AGENTS.md"
log_timestamp "START Step 7: Generating AGENTS.md"

AGENTS_PROMPT=$(cat << 'PROMPT_END'
Generate an AGENTS.md file for a Ralph Wiggum loop. This is the operational 
guide loaded into EVERY iteration. It must be:

- BRIEF (~60 lines max). Every token costs context in every iteration.
- OPERATIONAL ONLY. No status, no progress, no changelogs.
- Focused on HOW TO BUILD AND TEST.

The project uses:
- Python with UV for package management
- pytest for testing
- ruff for linting  
- mypy for type checking

Include ONLY these sections:

## Build & Run
[Exact commands to install deps and run the project]

## Validation
[Exact commands for tests, typecheck, lint - these are the backpressure]

## Codebase Patterns
[Key conventions: project structure, imports, error handling]
[Any critical rules from the design constraints]

## Known Gotchas
[Common agent pitfalls for this specific project]

YOUR ENTIRE RESPONSE IS THE OUTPUT FILE. Start directly with the markdown
content (e.g., "## Build & Run"). Do not summarize, describe, or comment
on the document — just produce it. No preamble, no explanation.

---

DESIGN DOCUMENT:

PROMPT_END
)

AGENTS_OUTPUT=$(claude_generate "${AGENTS_PROMPT}${DESIGN_DOC}" "AGENTS.md")
echo "$AGENTS_OUTPUT" > AGENTS.md

log_info "Generated: AGENTS.md"
log_timestamp "END   Step 7: Success"

fi

# -----------------------------------------------------------------------------
# Step 6: Write PROMPT_plan.md (hard-coded template)
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 8 "PROMPT_plan.md" "PROMPT_plan.md"; then
    :
else

log_step "Step 8/10: Writing PROMPT_plan.md"
log_timestamp "START Step 8: Writing PROMPT_plan.md"

cat << 'PROMPT_PLAN' > PROMPT_plan.md
You are a PLANNING agent in a Ralph Wiggum loop. No code edits, no commits.

## Process

1. **Study all specs** — launch parallel subagents to study each file in specs/
2. **Study existing code** — search src/ to understand what's already built
3. **Study IMPLEMENTATION_PLAN.md** if it exists — note completed vs pending tasks
4. **Gap analysis** — compare spec requirements against current codebase
   - Don't assume not implemented — always search first (Glob, Grep, Read)
   - Use Ultrathink for cross-spec dependency analysis
5. **Produce IMPLEMENTATION_PLAN.md** — create or update with prioritized tasks

## Task Format (markdown bullets, not JSON)

- **Task name** [spec-NNN]
  - What: concrete deliverable (~5 files max, one iteration)
  - Why: which spec requirement(s) it satisfies
  - Verified by: what backpressure proves it works (test, mypy, ruff)
  - Depends on: prerequisite tasks if any

## Rules

- PLANNING ONLY — no implementation, no file edits, no commits
- Prioritize: critical path first, dependencies before dependents
- Size tasks for ONE iteration (completable in a single agent run)
- IMPLEMENTATION_PLAN.md lives at repository root, not in subdirectories
PROMPT_PLAN

log_info "Written: PROMPT_plan.md"
log_timestamp "END   Step 8: Success"

fi

# -----------------------------------------------------------------------------
# Step 7: Write PROMPT_build.md (hard-coded template)
# -----------------------------------------------------------------------------

if [[ "$RESUME" = true ]] && step_complete 9 "PROMPT_build.md" "PROMPT_build.md"; then
    :
else

log_step "Step 9/10: Writing PROMPT_build.md"
log_timestamp "START Step 9: Writing PROMPT_build.md"

cat << PROMPT_BUILD > PROMPT_build.md
You are a BUILD agent in a Ralph Wiggum loop. Complete exactly ONE task per iteration.

## Workflow

1. **Study** specs/* for requirements and constraints
2. **Study** IMPLEMENTATION_PLAN.md — pick the highest-priority incomplete task
3. **Search** the codebase before assuming anything is missing (Glob, Grep, Read)
4. **Implement** the task completely — no TODOs, no placeholders, no stubs
5. **Test** — write tests that validate behavior against spec requirements
6. **Validate**
   - \`uv run pytest tests/\` — all tests must pass
   - \`uv run mypy src/\` — no type errors
   - \`uv run ruff check src/ tests/ && uv run ruff format src/ tests/\`
7. **Update IMPLEMENTATION_PLAN.md** — mark task [DONE], add discoveries/blockers
8. **Commit** — \`git add -A && git commit -m "descriptive message"\`

## Guardrails (ascending criticality)

- 999: Capture the why in docs and tests
- 9999: Single sources of truth — no migrations, no adapters
- 99999: Implement completely. No placeholders, no stubs.
- 999999: Keep IMPLEMENTATION_PLAN.md current with learnings
- 9999999: AGENTS.md is operational ONLY — no status, no progress, no checklists
- 99999999: For bugs found, resolve or document in IMPLEMENTATION_PLAN.md
- 999999999: Clean completed items from IMPLEMENTATION_PLAN.md periodically
- 9999999999: Don't assume not implemented — always search first
- 99999999999: NEVER put implementation status in AGENTS.md — that goes in IMPLEMENTATION_PLAN.md

## What goes where

- **IMPLEMENTATION_PLAN.md** (root): task status, progress, blockers, discoveries
- **AGENTS.md**: operational guide ONLY (build commands, gotchas, conventions) — NEVER status

## Environment

- Python with UV — \`uv run pytest\`, \`uv run mypy src/\`, \`uv run ruff check/format\`
- Source: src/${PACKAGE_NAME}/
- Tests: tests/
PROMPT_BUILD

log_info "Written: PROMPT_build.md"
log_timestamp "END   Step 9: Success"

fi

# -----------------------------------------------------------------------------
# Step 8: Create Loop Script and Scaffold
# -----------------------------------------------------------------------------

log_step "Step 10/10: Creating loop.sh and project scaffold"
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

# Commit all changes
git add -A
if ! git diff --cached --quiet 2>/dev/null; then
    if [[ "$RESUME" = true ]] && git log --oneline -1 2>/dev/null | grep -q "ralph-init: scaffold"; then
        git commit --amend -m "ralph-init: scaffold for $PROJECT_NAME (resumed)

Generated by ralph-init.sh:
- DESIGN_v1.md: Initial design from concept
- DESIGN_REVIEW.md: Critical review of initial design
- DESIGN.md: Refined design (addresses review)
- specs/: Individual specifications
- AGENTS.md: Operational guide
- PROMPT_plan.md: Planning mode prompt
- PROMPT_build.md: Building mode prompt
- loop.sh: Ralph loop script
- Python project scaffold
"
    else
        git commit -m "ralph-init: scaffold for $PROJECT_NAME

Generated by ralph-init.sh:
- DESIGN_v1.md: Initial design from concept
- DESIGN_REVIEW.md: Critical review of initial design
- DESIGN.md: Refined design (addresses review)
- specs/: Individual specifications
- AGENTS.md: Operational guide
- PROMPT_plan.md: Planning mode prompt
- PROMPT_build.md: Building mode prompt
- loop.sh: Ralph loop script
- Python project scaffold
"
    fi
    log_info "Created initial commit"
else
    log_info "No new changes to commit"
fi
log_timestamp "END   Step 10: Success"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Ralph setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "Generated files:"
echo "  📄 DESIGN_v1.md        — Initial design (pre-review)"
echo "  📄 DESIGN_REVIEW.md    — Critical review of initial design"
echo "  📄 DESIGN.md           — Refined design (addresses review)"
echo "  📁 specs/              — $SPEC_COUNT specification files"
echo "  📄 AGENTS.md           — Operational guide"
echo "  📄 PROMPT_plan.md      — Planning mode prompt"
echo "  📄 PROMPT_build.md     — Building mode prompt"
echo "  📄 loop.sh             — Ralph loop script"
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
