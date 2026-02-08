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

# Run claude headless and capture output
claude_generate() {
    local prompt="$1"
    local description="$2"
    
    log_info "Generating: $description"
    echo "$prompt" | claude -p --model "$MODEL" --output-format text 2>/dev/null
}

claude_generate_design() {
    local prompt="$1"
    local description="$2"
    
    log_info "Generating: $description (using $DESIGN_MODEL)"
    echo "$prompt" | claude -p --model "$DESIGN_MODEL" --output-format text 2>/dev/null
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
[[ -z "$CONCEPT_FILE" ]] && log_error "Missing concept_file argument. Run with --help for usage."
[[ ! -f "$CONCEPT_FILE" ]] && log_error "Concept file not found: $CONCEPT_FILE"

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

# Read concept file
CONCEPT_CONTENT=$(cat "$CONCEPT_FILE")

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

log_step "Step 1/8: Creating git worktree"

if [[ -d "$WORKTREE_PATH" ]]; then
    log_error "Worktree already exists: $WORKTREE_PATH"
fi

git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
cd "$WORKTREE_PATH"

log_info "Created worktree at $WORKTREE_PATH"

# -----------------------------------------------------------------------------
# Step 2: Create Directory Structure
# -----------------------------------------------------------------------------

log_step "Step 2/8: Creating directory structure"

mkdir -p specs
mkdir -p src
mkdir -p tests

log_info "Created: specs/, src/, tests/"

# -----------------------------------------------------------------------------
# Step 3: Generate Design Document from Concept (3-turn: design → review → refine)
# -----------------------------------------------------------------------------

log_step "Step 3/10: Generating initial design document"

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

Output the design as a single markdown document.

---

PROJECT CONCEPT:

PROMPT_END
)

DESIGN_DOC=$(claude_generate_design "${DESIGN_PROMPT}${CONCEPT_CONTENT}" "Initial design")
echo "$DESIGN_DOC" > DESIGN_v1.md

log_info "Generated: DESIGN_v1.md"

# -----------------------------------------------------------------------------
# Step 3b: Design Review
# -----------------------------------------------------------------------------

log_step "Step 4/10: Reviewing design (critic agent)"

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

# -----------------------------------------------------------------------------
# Step 3c: Refine Design Based on Review
# -----------------------------------------------------------------------------

log_step "Step 5/10: Refining design based on review"

REFINE_PROMPT=$(cat << 'PROMPT_END'
You previously created a design document. A critical review has identified 
issues that need to be addressed before implementation.

Your task: Produce a REFINED DESIGN that addresses the review findings.

Instructions:
1. Read the review carefully — especially Critical and Major issues
2. Address each issue explicitly in your refined design
3. Keep what works — don't rewrite sections that passed review
4. For each significant change, add a brief note explaining the change

At the end of the refined design, include a section:

## Changes from V1

- [Change 1]: [Why — which review issue it addresses]
- [Change 2]: [Why]
- ...

Output the complete refined design document (not just the changes).

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

# -----------------------------------------------------------------------------
# Step 4: Generate Specs from Design
# -----------------------------------------------------------------------------

log_step "Step 6/10: Generating specification files"

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

---

DESIGN DOCUMENT:

PROMPT_END
)

SPECS_OUTPUT=$(claude_generate "${SPECS_PROMPT}${DESIGN_DOC}" "Specification files")

# Parse specs from output - look for ```markdown specs/*.md blocks
echo "$SPECS_OUTPUT" | awk '
/^```markdown specs\/[^`]+\.md$/ {
    # Extract filename from the fence line
    match($0, /specs\/[^`]+\.md/)
    filename = substr($0, RSTART, RLENGTH)
    getline  # Skip the fence line
    content = ""
    while (getline > 0 && !/^```$/) {
        content = content $0 "\n"
    }
    print content > filename
    close(filename)
}
'

# Count generated specs
SPEC_COUNT=$(ls -1 specs/*.md 2>/dev/null | wc -l)
log_info "Generated: $SPEC_COUNT spec files in specs/"

# If no specs were parsed, save raw output for debugging
if [[ "$SPEC_COUNT" -eq 0 ]]; then
    echo "$SPECS_OUTPUT" > specs/_raw_output.md
    log_info "Warning: Could not parse specs. Raw output saved to specs/_raw_output.md"
    log_info "You may need to manually extract spec files from the output."
fi

# -----------------------------------------------------------------------------
# Step 5: Generate AGENTS.md
# -----------------------------------------------------------------------------

log_step "Step 7/10: Generating AGENTS.md"

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

Output ONLY the AGENTS.md content, no explanations.

---

DESIGN DOCUMENT:

PROMPT_END
)

AGENTS_OUTPUT=$(claude_generate "${AGENTS_PROMPT}${DESIGN_DOC}" "AGENTS.md")
echo "$AGENTS_OUTPUT" > AGENTS.md

log_info "Generated: AGENTS.md"

# -----------------------------------------------------------------------------
# Step 6: Generate PROMPT_plan.md
# -----------------------------------------------------------------------------

log_step "Step 8/10: Generating PROMPT_plan.md"

PLAN_PROMPT=$(cat << 'PROMPT_END'
Generate a PROMPT_plan.md for a Ralph Wiggum loop. This prompt is piped into 
`claude -p` at the start of each PLANNING iteration.

The agent should:
1. Study all specs in specs/* using parallel subagents
2. Study IMPLEMENTATION_PLAN.md if it exists  
3. Study src/ to understand what's already built
4. Compare specs against current code (gap analysis)
5. Create/update IMPLEMENTATION_PLAN.md with prioritized tasks

Rules:
- PLANNING ONLY. No implementation. No commits.
- Tasks should be sized for ONE iteration (~5 files max)
- Each task references which spec(s) it addresses
- Each task notes what backpressure verifies it
- Use "study" not "read"
- Include "don't assume not implemented — search first" as guardrail
- Use "Ultrathink" for complex analysis
- Markdown bullet points, not JSON
- Project uses Python with UV, pytest, ruff, mypy

The prompt should be ~25-35 lines. Concise and direct.

Output ONLY the prompt content, no explanations or markdown fences.
PROMPT_END
)

PLAN_OUTPUT=$(claude_generate "$PLAN_PROMPT" "PROMPT_plan.md")
echo "$PLAN_OUTPUT" > PROMPT_plan.md

log_info "Generated: PROMPT_plan.md"

# -----------------------------------------------------------------------------
# Step 7: Generate PROMPT_build.md
# -----------------------------------------------------------------------------

log_step "Step 9/10: Generating PROMPT_build.md"

BUILD_PROMPT=$(cat << 'PROMPT_END'
Generate a PROMPT_build.md for a Ralph Wiggum loop. This prompt is piped into 
`claude -p` at the start of each BUILD iteration.

The agent should:
1. Study specs/* for requirements context
2. Study IMPLEMENTATION_PLAN.md to pick the most important remaining task
3. Search the codebase before assuming anything is missing
4. Implement exactly ONE task
5. Run validation (pytest, mypy, ruff)
6. Update IMPLEMENTATION_PLAN.md — mark task done, note discoveries
7. Update AGENTS.md ONLY if operational learnings (keep it brief!)
8. git add -A && git commit with descriptive message

Include these guardrails using 9s numbering (higher = more critical):
- 999: Capture the why in docs and tests
- 9999: Single sources of truth, no migrations/adapters
- 99999: Implement completely. No placeholders, no stubs.
- 999999: Keep IMPLEMENTATION_PLAN.md current with learnings
- 9999999: Update AGENTS.md with operational learnings only, keep brief
- 99999999: For bugs found, resolve or document in IMPLEMENTATION_PLAN.md
- 999999999: Clean completed items from IMPLEMENTATION_PLAN.md periodically
- 9999999999: AGENTS.md is operational only — no status, no progress notes
- 99999999999: Don't assume not implemented — always search first

Project uses Python with UV, pytest, ruff, mypy.

The prompt should be ~35-45 lines. Concise and direct.

Output ONLY the prompt content, no explanations or markdown fences.
PROMPT_END
)

BUILD_OUTPUT=$(claude_generate "$BUILD_PROMPT" "PROMPT_build.md")
echo "$BUILD_OUTPUT" > PROMPT_build.md

log_info "Generated: PROMPT_build.md"

# -----------------------------------------------------------------------------
# Step 8: Create Loop Script and Scaffold
# -----------------------------------------------------------------------------

log_step "Step 10/10: Creating loop.sh and project scaffold"

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
PACKAGE_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')
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
GITIGNORE

log_info "Created: pyproject.toml, src/$PACKAGE_NAME/, tests/"

# Initial commit
git add -A
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

log_info "Created initial commit"

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
echo "     ${YELLOW}cd $WORKTREE_PATH${NC}"
echo ""
echo "  2. Review specs/ for completeness"
echo ""
echo "  3. Install dev dependencies:"
echo "     ${YELLOW}uv sync --extra dev${NC}"
echo ""
echo "  4. Run planning phase (generates IMPLEMENTATION_PLAN.md):"
echo "     ${YELLOW}./loop.sh plan 3${NC}"
echo ""
echo "  5. Review the plan, then start building:"
echo "     ${YELLOW}./loop.sh 10${NC}"
echo ""
echo "  6. Watch the first few iterations, tune as needed."
echo ""
