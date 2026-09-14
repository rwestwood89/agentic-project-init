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
RETIRED="_my_code_review _my_code_quality _my_project_manage _my_audit_implementation _my_review_design _my_capture _my_memorize _my_recall _my_review_compact"
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

# No pack surface names a CURRENT_WORK.md section that no longer exists. Deleting a
# section while a command still writes to it is the orphaning class this guard catches:
# `Recently Completed` had two writers, and `Session Notes` had none but shipped anyway.
ORPHANED_SECTIONS="$(grep -rn 'Recently Completed\|Session Notes' \
    "$SOURCE_DIR/claude-pack" "$SOURCE_DIR/project-pack" 2>/dev/null || true)"
if [ -z "$ORPHANED_SECTIONS" ]; then
    echo -e "${GREEN}PASS: no pack surface names a deleted CURRENT_WORK.md section${NC}"
else
    echo -e "${RED}FAIL: a pack surface still names a deleted CURRENT_WORK.md section${NC}"
    echo "$ORPHANED_SECTIONS"
    FAIL=1
fi

if grep -qi 'memory storage structure' "$SOURCE_DIR/docs/STRUCTURE.md"; then
    echo -e "${RED}FAIL: docs/STRUCTURE.md still advertises memory storage${NC}"
    FAIL=1
else
    echo -e "${GREEN}PASS: docs do not advertise memory storage${NC}"
fi

# The same bounded read, run against the shipped template: a freshly initialized project
# must surface no completions at all. This is what the `[0-9]` anchor buys — a bracketed
# placeholder heading is not a dated entry, in a new project or an old one.
TEMPLATE_BOOT_READ="$(awk '/^## \[[0-9]/{n++; p=1} n>5{exit} /^### Deliverables/{p=0} /^---$/{p=0} p' \
    "$SOURCE_DIR/project-pack/completed/CHANGELOG.md")"
if [ -z "$TEMPLATE_BOOT_READ" ]; then
    echo -e "${GREEN}PASS: the boot read surfaces nothing from a fresh project's CHANGELOG${NC}"
else
    echo -e "${RED}FAIL: the boot read surfaces a placeholder from the CHANGELOG template${NC}"
    echo "$TEMPLATE_BOOT_READ"
    FAIL=1
fi

# A freshly initialized project ships no placeholder a whole-file reader could mistake
# for a completion. The boot read is protected by its `[0-9]` anchor; this protects the
# human and the two on-demand readers, `_my_status` and `_my_project_find`.
if grep -q '^## \[YYYY-MM-DD\]' "$SOURCE_DIR/project-pack/completed/CHANGELOG.md"; then
    echo -e "${RED}FAIL: the CHANGELOG template still ships a placeholder entry${NC}"
    FAIL=1
else
    echo -e "${GREEN}PASS: the CHANGELOG template ships no placeholder entry${NC}"
fi

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
