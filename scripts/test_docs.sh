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

echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All documentation checks passed!${NC}"
else
    echo -e "${RED}Some documentation checks failed${NC}"
    exit 1
fi
