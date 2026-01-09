#!/bin/bash
# Verification script - run after renaming
# test_rename.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_PACK="$SOURCE_DIR/claude-pack"

echo "Verifying command renaming..."
echo ""

# Check all commands have _my_ prefix
echo "Checking command files..."
FAIL=0
for f in "$CLAUDE_PACK"/commands/*.md; do
    basename=$(basename "$f")
    if [[ ! "$basename" =~ ^_my_ ]]; then
        echo -e "${RED}FAIL: $basename missing _my_ prefix${NC}"
        FAIL=1
    fi
done
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}PASS: All commands have _my_ prefix${NC}"
else
    exit 1
fi

echo ""

# Check no old-style references remain in command files
echo "Checking cross-references in commands..."
# Look for /command patterns that are NOT preceded by _my_
# Exclude lines that are comments (start with #) or are in code blocks
OLD_REFS=$(grep -rE "/(research|spec|design|plan|implement|code-review|code-quality|git-manage|project-manage|project-find|quick-edit|capture|recall|memorize|review-compact)([^_a-zA-Z]|$)" "$CLAUDE_PACK/commands/" --include="*.md" 2>/dev/null | grep -v "_my_" | grep -v "^[^:]*:#" || true)

if [ -n "$OLD_REFS" ]; then
    echo -e "${RED}FAIL: Found old-style references:${NC}"
    echo "$OLD_REFS"
    exit 1
fi
echo -e "${GREEN}PASS: No old-style references found in commands${NC}"

echo ""

# Check hook files
echo "Checking hook files..."
# Look for /memorize as a command reference (with backticks, quotes, or word boundary), not "memorized" as a word
HOOK_REFS=$(grep -E '`/memorize`|"/memorize"|/memorize[^a-zA-Z]' "$CLAUDE_PACK/hooks/"* 2>/dev/null | grep -v "_my_" || true)
if [ -n "$HOOK_REFS" ]; then
    echo -e "${RED}FAIL: Found old-style /memorize references in hooks:${NC}"
    echo "$HOOK_REFS"
    exit 1
fi
echo -e "${GREEN}PASS: Hook files updated${NC}"

echo ""

# Check documentation
echo "Checking documentation files..."
DOC_REFS=$(grep -rE "/(research|spec|design|plan|implement|code-review|code-quality|git-manage|project-manage|project-find|quick-edit|capture|recall|memorize|review-compact)([^_a-zA-Z]|$)" "$CLAUDE_PACK/claude-md-checklist.md" "$CLAUDE_PACK/agents/" --include="*.md" 2>/dev/null | grep -v "_my_" | grep -v "^[^:]*:#" || true)
if [ -n "$DOC_REFS" ]; then
    echo -e "${RED}FAIL: Found old-style references in documentation:${NC}"
    echo "$DOC_REFS"
    exit 1
fi
echo -e "${GREEN}PASS: Documentation files updated${NC}"

echo ""

# List all command files
echo "Command files:"
ls -1 "$CLAUDE_PACK/commands/"

echo ""
echo -e "${GREEN}All verifications passed!${NC}"
