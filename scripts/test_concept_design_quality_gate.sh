#!/bin/bash
# Structural checks for the concept-design architectural quality gate.
# These checks prove the command and pipeline wiring exist. They do not claim
# that a prompt-driven reviewer will always make the right architectural call.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
AUTHOR="$ROOT/claude-pack/commands/_my_concept_design.md"
REVIEW="$ROOT/claude-pack/commands/_my_concept_design_review.md"
PIPELINE="$ROOT/claude-pack/commands/_my_pipeline.md"
RULE="$ROOT/claude-pack/rules/pipeline.md"
CONFIG="$ROOT/codex-overrides/config.sh"
CODEX_HELPER="$ROOT/codex-overrides/scripts/orchestrate-stage-codex.sh"
README="$ROOT/README.md"
GUIDE="$ROOT/docs/guide.md"
GENERATED_REVIEW="$ROOT/dist/codex/skills/my-concept-design-review/SKILL.md"

fail() { echo -e "${RED}FAIL: $1${NC}"; exit 1; }
pass() { echo -e "${GREEN}PASS: $1${NC}"; }

contains() {
  local file="$1"
  local pattern="$2"
  grep -qF -- "$pattern" "$file" || fail "expected '$pattern' in $file"
}

does_not_contain() {
  local file="$1"
  local pattern="$2"
  if grep -qF -- "$pattern" "$file"; then
    fail "unexpected '$pattern' in $file"
  fi
}

[ -f "$REVIEW" ] || fail "concept-design review command missing"

contains "$AUTHOR" '## ADR Candidates'
contains "$AUTHOR" 'Current code is evidence, not authority'
contains "$AUTHOR" '/_my_concept_design_review'
does_not_contain "$AUTHOR" 'The document is wrong, not the code'
does_not_contain "$AUTHOR" 'Invariants match reality'
pass "concept-design exposes decisions and hands off to review"

contains "$REVIEW" 'Are we actually solving the right problem?'
contains "$REVIEW" 'architecture quality'
contains "$REVIEW" 'fresh subagent in the ponytail role'
contains "$REVIEW" 'written challenge'
contains "$REVIEW" 'ultra'
contains "$REVIEW" 'do not edit the concept'
pass "review command carries the architectural and ponytail gates"

contains "$PIPELINE" '`concept_design` → `concept_design_review`'
contains "$RULE" '`concept_design` → `concept_design_review`'
contains "$CONFIG" '["concept-design-review"]='
contains "$CODEX_HELPER" 'concept_design_review|concept-design-review'
pass "pipeline and Codex source wiring present"

contains "$README" '/_my_concept_design_review'
contains "$GUIDE" '/_my_concept_design_review'
pass "user-facing command docs present"

[ -f "$GENERATED_REVIEW" ] || fail "generated Codex concept-design review skill missing"
contains "$GENERATED_REVIEW" '$HOME/.agents/skills/my-ponytail/SKILL.md'
if grep -qF 'claude-pack/commands`my-ponytail`' "$GENERATED_REVIEW"; then
  fail "generated ponytail source reference is malformed"
fi
pass "generated Codex review resolves the ponytail role"

echo ""
echo -e "${GREEN}Concept-design quality-gate structural checks passed.${NC}"
