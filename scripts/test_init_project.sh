#!/bin/bash
# Test script for init-project.sh
# Tests basic init, --no-track, --include-claude, and mutual exclusion

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
INIT_SCRIPT="$SCRIPT_DIR/init-project.sh"

echo "Testing init-project.sh"
echo "======================="
echo ""

# Check init script exists
if [ ! -f "$INIT_SCRIPT" ]; then
    echo -e "${RED}FAIL: init-project.sh not found at $INIT_SCRIPT${NC}"
    exit 1
fi

# Create temp directory for tests
TEST_BASE=$(mktemp -d)
cleanup() {
    rm -rf "$TEST_BASE"
}
trap cleanup EXIT

echo "Using test directory: $TEST_BASE"
echo ""

# Test 1: Dry run
echo "Test 1: Dry run mode..."
TEST_DIR="$TEST_BASE/test1"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

DRY_OUTPUT=$("$INIT_SCRIPT" --source "$SOURCE_DIR" --dry-run 2>&1)
if echo "$DRY_OUTPUT" | grep -q "DRY RUN"; then
    echo -e "${GREEN}PASS: Dry run mode works${NC}"
else
    echo -e "${RED}FAIL: Dry run not detected in output${NC}"
    echo "$DRY_OUTPUT"
    exit 1
fi

# Verify nothing was created in dry run
if [ -d ".project" ]; then
    echo -e "${RED}FAIL: Dry run created .project/${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Dry run didn't create anything${NC}"
echo ""

# Test 2: Basic init
echo "Test 2: Basic init..."
TEST_DIR="$TEST_BASE/test2"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

"$INIT_SCRIPT" --source "$SOURCE_DIR"

# Check .project created
if [ ! -d ".project" ]; then
    echo -e "${RED}FAIL: .project not created${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: .project created${NC}"

# Check required subdirectories
for dir in research reports memories active completed backlog; do
    if [ ! -d ".project/$dir" ]; then
        echo -e "${RED}FAIL: .project/$dir not created${NC}"
        exit 1
    fi
done
echo -e "${GREEN}PASS: All subdirectories created${NC}"

# Check README.md copied
if [ ! -f ".project/README.md" ]; then
    echo -e "${RED}FAIL: .project/README.md not copied${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: README.md copied${NC}"
echo ""

# Test 3: --no-track flag
echo "Test 3: --no-track flag..."
TEST_DIR="$TEST_BASE/test3"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

"$INIT_SCRIPT" --source "$SOURCE_DIR" --no-track

# Check .gitignore updated
if [ ! -f ".gitignore" ]; then
    echo -e "${RED}FAIL: .gitignore not created${NC}"
    exit 1
fi

if ! grep -qxF ".project" .gitignore; then
    echo -e "${RED}FAIL: .project not added to .gitignore${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: --no-track adds .project to .gitignore${NC}"
echo ""

# Test 4: --include-claude flag
echo "Test 4: --include-claude flag..."
TEST_DIR="$TEST_BASE/test4"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

"$INIT_SCRIPT" --source "$SOURCE_DIR" --include-claude

# Check .claude created with files (not symlinks)
if [ ! -d ".claude/commands" ]; then
    echo -e "${RED}FAIL: .claude/commands not created${NC}"
    exit 1
fi

# Verify files are copies, not symlinks
if [ -L ".claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: .claude/commands/_my_research.md is a symlink (should be copy)${NC}"
    exit 1
fi

if [ ! -f ".claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: .claude/commands/_my_research.md not copied${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: --include-claude copies files (not symlinks)${NC}"

# Check vendor marker
if [ ! -f ".claude/.agentic-pack-vendored" ]; then
    echo -e "${RED}FAIL: .agentic-pack-vendored marker not created${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Vendor marker created${NC}"

# Check settings.json created
if [ ! -f ".claude/settings.json" ]; then
    echo -e "${RED}FAIL: .claude/settings.json not created${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: settings.json created${NC}"
echo ""

# Test 5: Mutual exclusion
echo "Test 5: Mutual exclusion (--no-track + --include-claude)..."
TEST_DIR="$TEST_BASE/test5"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

MUTUAL_OUTPUT=$("$INIT_SCRIPT" --source "$SOURCE_DIR" --no-track --include-claude 2>&1) || true
if echo "$MUTUAL_OUTPUT" | grep -q "cannot be used together"; then
    echo -e "${GREEN}PASS: Mutual exclusion error shown${NC}"
else
    echo -e "${RED}FAIL: No mutual exclusion error${NC}"
    echo "$MUTUAL_OUTPUT"
    exit 1
fi
echo ""

# Test 6: Merge strategy (existing .project/)
echo "Test 6: Merge strategy..."
TEST_DIR="$TEST_BASE/test6"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

# Create partial .project/
mkdir -p .project
echo "existing content" > .project/README.md
mkdir -p .project/research

"$INIT_SCRIPT" --source "$SOURCE_DIR"

# Check existing content preserved
CONTENT=$(cat .project/README.md)
if [ "$CONTENT" = "existing content" ]; then
    echo -e "${GREEN}PASS: Existing content preserved${NC}"
else
    echo -e "${RED}FAIL: Existing content was overwritten${NC}"
    exit 1
fi

# Check missing directories added
if [ ! -d ".project/memories" ]; then
    echo -e "${RED}FAIL: Missing directories not added${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Missing components added${NC}"
echo ""

# Test 7: Source auto-detection (from metadata)
echo "Test 7: Source auto-detection..."
TEST_DIR="$TEST_BASE/test7"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

# Create fake global setup metadata
mkdir -p "$HOME/.claude"
echo "$SOURCE_DIR" > "$HOME/.claude/.agentic-pack-source"

# Run without --source
"$INIT_SCRIPT"

if [ -d ".project" ]; then
    echo -e "${GREEN}PASS: Source auto-detected from metadata${NC}"
else
    echo -e "${RED}FAIL: Source auto-detection failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}All tests passed!${NC}"
