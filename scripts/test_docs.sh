#!/bin/bash
# Verify documentation completeness

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
README="$SOURCE_DIR/README.md"

echo "Verifying documentation completeness..."
echo ""

FAIL=0

# Check README has required sections
check_section() {
    local pattern="$1"
    local description="$2"

    if grep -q -- "$pattern" "$README"; then
        echo -e "${GREEN}PASS: $description${NC}"
    else
        echo -e "${RED}FAIL: $description${NC}"
        FAIL=1
    fi
}

check_section "setup-global.sh" "setup-global.sh documented"
check_section "init-project.sh" "init-project.sh documented"
check_section "uninstall-global.sh" "uninstall-global.sh documented"
check_section "uninstall-project.sh" "uninstall-project.sh documented"
check_section "_my_" "_my_ prefix documented"
check_section "Migration" "Migration guide present"
check_section "--dry-run" "--dry-run option documented"
check_section "--include-claude" "--include-claude option documented"
check_section "--no-track" "--no-track option documented"
check_section "Command Reference" "Command reference section present"

# Catalog completeness: every shipped command appears in the README Command Reference.
# _my_example_command is a scaffold template, not a shipped command.
MISSING=""
for f in "$SOURCE_DIR"/claude-pack/commands/_my_*.md; do
    name="$(basename "$f" .md)"
    [ "$name" = "_my_example_command" ] && continue
    grep -qw -- "$name" "$README" || MISSING="$MISSING $name"
done
if [ -z "$MISSING" ]; then
    echo -e "${GREEN}PASS: every shipped command listed in README${NC}"
else
    echo -e "${RED}FAIL: commands missing from README:$MISSING${NC}"
    FAIL=1
fi

# No retired command names in the README catalog
RETIRED="_my_code_review _my_code_quality _my_project_manage _my_audit_implementation _my_review_design"
FOUND_RETIRED=""
for name in $RETIRED; do
    grep -qw -- "$name" "$README" && FOUND_RETIRED="$FOUND_RETIRED $name"
done
if [ -z "$FOUND_RETIRED" ]; then
    echo -e "${GREEN}PASS: no retired command names in README${NC}"
else
    echo -e "${RED}FAIL: retired command names in README:$FOUND_RETIRED${NC}"
    FAIL=1
fi

# Product-ledger touch points stay wired (ADR 0008): the read rule, the lens discovery
# surface, and the close write beat are prose lines a doc overhaul could silently drop.
check_wired() {
    local pattern="$1" file="$2" description="$3"
    if grep -q -- "$pattern" "$SOURCE_DIR/$file"; then
        echo -e "${GREEN}PASS: $description${NC}"
    else
        echo -e "${RED}FAIL: $description${NC}"
        FAIL=1
    fi
}
check_wired "product/INDEX.md" "claude-pack/rules/context-loading.md" "session-start rule reads the promise index"
check_wired ".project/product/" "claude-pack/scripts/product-lens.md" "lens SOURCES include the promise ledger"
check_wired "product.sh" "claude-pack/commands/_my_close.md" "close files promise entries via product.sh"

# No pipeline-shape restatements outside the canonical pair
# (claude-pack/rules/pipeline.md + claude-pack/commands/_my_pipeline.md, guarded by
# test_pipeline_sync.sh). Human-facing docs must defer to /_my_pipeline, not restate
# the stage sequence — a stage name joined to another by an arrow is the drift signature.
# Exception: docs/guide.md carries the work-item flow by owner decision (2026-08-08);
# keep its flow line consistent with /_my_pipeline when either changes.
STAGE='(research|concept|concept_design|epic_plan|spec|spec_review|product[_-]design|design|design_review|plan|implement|audit|pre_pr|close|execute)'
RESTATEMENTS="$(grep -rniE "${STAGE}\`?[[:space:]]*(→|->)[[:space:]]*\`?/?(_my_)?${STAGE}" \
    "$SOURCE_DIR/README.md" "$SOURCE_DIR/docs" "$SOURCE_DIR/project-pack" 2>/dev/null \
    | grep -v "docs/guide.md" || true)"
if [ -z "$RESTATEMENTS" ]; then
    echo -e "${GREEN}PASS: no stage-sequence restatements outside the canonical pair${NC}"
else
    echo -e "${RED}FAIL: stage-sequence restatements found (defer to /_my_pipeline instead):${NC}"
    echo "$RESTATEMENTS"
    FAIL=1
fi

echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All documentation checks passed!${NC}"
else
    echo -e "${RED}Some documentation checks failed${NC}"
    exit 1
fi
