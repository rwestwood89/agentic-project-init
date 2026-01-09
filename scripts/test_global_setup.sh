#!/bin/bash
# Test script for setup-global.sh
# Tests fresh install, idempotency, and dry-run modes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="$SCRIPT_DIR/setup-global.sh"

echo "Testing setup-global.sh"
echo "======================="
echo ""

# Check setup script exists
if [ ! -f "$SETUP_SCRIPT" ]; then
    echo -e "${RED}FAIL: setup-global.sh not found at $SETUP_SCRIPT${NC}"
    exit 1
fi

# Setup: Create temp HOME directory
TEST_HOME=$(mktemp -d)
REAL_HOME="$HOME"
export HOME="$TEST_HOME"

cleanup() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_HOME"
}
trap cleanup EXIT

echo "Using temporary HOME: $TEST_HOME"
echo ""

# Test 1: Dry run
echo "Test 1: Dry run mode..."
DRY_OUTPUT=$("$SETUP_SCRIPT" --dry-run 2>&1)
if echo "$DRY_OUTPUT" | grep -q "DRY RUN"; then
    echo -e "${GREEN}PASS: Dry run mode works${NC}"
else
    echo -e "${RED}FAIL: Dry run not detected in output${NC}"
    echo "$DRY_OUTPUT"
    exit 1
fi

# Verify nothing was created in dry run
if [ -d "$TEST_HOME/.claude/commands" ]; then
    echo -e "${RED}FAIL: Dry run created directories${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Dry run didn't create anything${NC}"
echo ""

# Test 2: Fresh install
echo "Test 2: Fresh install..."
"$SETUP_SCRIPT"

# Check directories created
for dir in commands agents hooks skills rules; do
    if [ ! -d "$TEST_HOME/.claude/$dir" ]; then
        echo -e "${RED}FAIL: Directory not created: .claude/$dir${NC}"
        exit 1
    fi
done
echo -e "${GREEN}PASS: All directories created${NC}"

# Check symlinks created
if [ ! -L "$TEST_HOME/.claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: Command symlink not created${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Command symlinks created${NC}"

# Check settings.json created
if [ ! -f "$TEST_HOME/.claude/settings.json" ]; then
    echo -e "${RED}FAIL: settings.json not created${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: settings.json created${NC}"

# Check metadata files
if [ ! -f "$TEST_HOME/.claude/.agentic-pack-source" ]; then
    echo -e "${RED}FAIL: .agentic-pack-source not created${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Metadata files created${NC}"

# Verify symlink points to correct location
SYMLINK_TARGET=$(readlink "$TEST_HOME/.claude/commands/_my_research.md")
if [[ ! "$SYMLINK_TARGET" == *"claude-pack/commands/_my_research.md" ]]; then
    echo -e "${RED}FAIL: Symlink points to wrong location: $SYMLINK_TARGET${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Symlinks point to correct source${NC}"
echo ""

# Test 3: Idempotent (run again)
echo "Test 3: Idempotency..."
SECOND_RUN=$("$SETUP_SCRIPT" 2>&1)
if echo "$SECOND_RUN" | grep -q "already exists"; then
    echo -e "${GREEN}PASS: Idempotent - detects existing symlinks${NC}"
else
    echo -e "${YELLOW}WARN: No 'already exists' messages on second run${NC}"
fi

# Verify symlinks still work
if [ ! -L "$TEST_HOME/.claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: Symlinks broken after second run${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Symlinks intact after second run${NC}"
echo ""

# Test 4: Preserves existing files
echo "Test 4: Preserves existing files..."
echo "user content" > "$TEST_HOME/.claude/commands/my_custom_command.md"
"$SETUP_SCRIPT"
if [ -f "$TEST_HOME/.claude/commands/my_custom_command.md" ]; then
    CONTENT=$(cat "$TEST_HOME/.claude/commands/my_custom_command.md")
    if [ "$CONTENT" = "user content" ]; then
        echo -e "${GREEN}PASS: User files preserved${NC}"
    else
        echo -e "${RED}FAIL: User file content changed${NC}"
        exit 1
    fi
else
    echo -e "${RED}FAIL: User file was deleted${NC}"
    exit 1
fi
echo ""

# Count symlinks
SYMLINK_COUNT=$(find "$TEST_HOME/.claude/commands" -type l | wc -l)
echo "Created $SYMLINK_COUNT command symlinks"

echo ""
echo -e "${GREEN}All tests passed!${NC}"
