#!/bin/bash
# Test script for uninstall-global.sh and uninstall-project.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing uninstall scripts"
echo "========================="
echo ""

# Create temp directory for tests
TEST_BASE=$(mktemp -d)
REAL_HOME="$HOME"

cleanup() {
    export HOME="$REAL_HOME"
    rm -rf "$TEST_BASE"
}
trap cleanup EXIT

echo "Using test directory: $TEST_BASE"
echo ""

# ============================================
# Test Global Uninstall
# ============================================

echo "=== Testing uninstall-global.sh ==="
echo ""

# Setup: Create temp HOME and install
TEST_HOME="$TEST_BASE/home1"
mkdir -p "$TEST_HOME"
export HOME="$TEST_HOME"

# Run global setup first
echo "Setting up for global uninstall test..."
"$SCRIPT_DIR/setup-global.sh" > /dev/null 2>&1

# Verify setup worked
if [ ! -L "$TEST_HOME/.claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: Setup didn't create symlinks${NC}"
    exit 1
fi

# Add a user-created file that should be preserved
echo "user content" > "$TEST_HOME/.claude/commands/my_custom.md"

# Seed the two legacy surfaces the uninstaller must clean without touching the user's hook.
mkdir -p "$TEST_HOME/.claude/hooks"
ln -s "$SOURCE_DIR/claude-pack/hooks/precompact-capture.sh" "$TEST_HOME/.claude/hooks/precompact-capture.sh"
cat > "$TEST_HOME/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [
      {"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"}]},
      {"matcher":"manual","hooks":[{"type":"command","command":"/home/u/.claude/hooks/my-own-precompact.sh"}]}
    ]
  }
}
JSON

# Test 1: Global uninstall removes symlinks
echo "Test 1: Global uninstall removes symlinks..."
"$SCRIPT_DIR/uninstall-global.sh"

if [ -L "$TEST_HOME/.claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: Symlink not removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Symlinks removed${NC}"
if [ -L "$TEST_HOME/.claude/hooks/precompact-capture.sh" ]; then
    echo -e "${RED}FAIL: Legacy hook symlink not removed${NC}"
    exit 1
fi
if [ "$(jq -r '.hooks.PreCompact | length' "$TEST_HOME/.claude/settings.json")" != "1" ] || \
   [ "$(jq -r '.hooks.PreCompact[0].hooks[0].command' "$TEST_HOME/.claude/settings.json")" != "/home/u/.claude/hooks/my-own-precompact.sh" ]; then
    echo -e "${RED}FAIL: User PreCompact hook was not preserved exactly${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Legacy hook state removed and user hook preserved${NC}"

# Test 2: User files preserved
echo "Test 2: User files preserved..."
if [ ! -f "$TEST_HOME/.claude/commands/my_custom.md" ]; then
    echo -e "${RED}FAIL: User file was deleted${NC}"
    exit 1
fi
CONTENT=$(cat "$TEST_HOME/.claude/commands/my_custom.md")
if [ "$CONTENT" != "user content" ]; then
    echo -e "${RED}FAIL: User file content changed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: User files preserved${NC}"

# Test 3: Metadata files removed
echo "Test 3: Metadata files removed..."
if [ -f "$TEST_HOME/.claude/.agentic-pack-source" ]; then
    echo -e "${RED}FAIL: .agentic-pack-source not removed${NC}"
    exit 1
fi
if [ -f "$TEST_HOME/.claude/.agentic-pack-version" ]; then
    echo -e "${RED}FAIL: .agentic-pack-version not removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Metadata files removed${NC}"

# Test 4: Missing optional install directories do not abort cleanup
echo "Test 4: Missing install directories are harmless..."
PARTIAL_HOME="$TEST_BASE/partial-home"
mkdir -p "$PARTIAL_HOME/.claude"
printf '%s\n' "$SOURCE_DIR" > "$PARTIAL_HOME/.claude/.agentic-pack-source"
cat > "$PARTIAL_HOME/.claude/settings.json" <<'JSON'
{"hooks":{"PreCompact":[{"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"}]}]}}
JSON
HOME="$PARTIAL_HOME" "$SCRIPT_DIR/uninstall-global.sh" > /dev/null
if [ -f "$PARTIAL_HOME/.claude/.agentic-pack-source" ] || jq -e '.hooks.PreCompact' "$PARTIAL_HOME/.claude/settings.json" > /dev/null 2>&1; then
    echo -e "${RED}FAIL: Partial install cleanup aborted${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Partial install cleanup completed${NC}"

# Test 5: Running uninstall again (no installation)
echo "Test 5: Uninstall when not installed..."
export HOME="$TEST_HOME"
UNINSTALL_OUTPUT=$("$SCRIPT_DIR/uninstall-global.sh" 2>&1) || true
if echo "$UNINSTALL_OUTPUT" | grep -q "No agentic-pack installation found"; then
    echo -e "${GREEN}PASS: Detects no installation${NC}"
else
    echo -e "${YELLOW}WARN: Unexpected output on second uninstall${NC}"
fi

echo ""

# ============================================
# Test Project Uninstall
# ============================================

echo "=== Testing uninstall-project.sh ==="
echo ""

# Reset HOME for project tests
export HOME="$REAL_HOME"

# Test 6: Basic project uninstall
echo "Test 6: Basic project uninstall..."
TEST_DIR="$TEST_BASE/project1"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

# Initialize project
"$SCRIPT_DIR/init-project.sh" --source "$SOURCE_DIR" > /dev/null 2>&1

# Verify .project exists
if [ ! -d ".project" ]; then
    echo -e "${RED}FAIL: Setup didn't create .project${NC}"
    exit 1
fi

# Uninstall with --force
"$SCRIPT_DIR/uninstall-project.sh" --force

if [ -d ".project" ]; then
    echo -e "${RED}FAIL: .project not removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: .project removed${NC}"

# Test 7: Uninstall with --no-track (removes from .gitignore)
echo "Test 7: Uninstall cleans .gitignore..."
TEST_DIR="$TEST_BASE/project2"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

# Initialize with --no-track
"$SCRIPT_DIR/init-project.sh" --source "$SOURCE_DIR" --no-track > /dev/null 2>&1

# Verify .gitignore has .project
if ! grep -qxF ".project" .gitignore; then
    echo -e "${RED}FAIL: .project not in .gitignore after init${NC}"
    exit 1
fi

# Uninstall
"$SCRIPT_DIR/uninstall-project.sh" --force

# Verify .gitignore cleaned
if grep -qxF ".project" .gitignore 2>/dev/null; then
    echo -e "${RED}FAIL: .project not removed from .gitignore${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: .gitignore cleaned${NC}"

# Test 8: Uninstall vendored .claude/
echo "Test 8: Uninstall vendored .claude/..."
TEST_DIR="$TEST_BASE/project3"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

# Initialize with --include-claude
"$SCRIPT_DIR/init-project.sh" --source "$SOURCE_DIR" --include-claude > /dev/null 2>&1

# Verify vendored content exists
if [ ! -f ".claude/.agentic-pack-vendored" ]; then
    echo -e "${RED}FAIL: Vendor marker not created${NC}"
    exit 1
fi

# Add a user command inside the pack's namespace; name alone does not make it pack-owned.
echo "user claude content" > ".claude/commands/_my_custom.md"

# Add files written by the retired vendored pack plus a user hook that must survive.
mkdir -p .claude/hooks .claude/agents .claude/rules
printf 'legacy pack agent\n' > .claude/agents/recall.md
printf 'legacy pack rule\n' > .claude/rules/example-rules.md
for legacy_hook in capture.sh precompact-capture.sh parse-transcript.py query-transcript.py; do
    printf 'legacy pack hook\n' > ".claude/hooks/$legacy_hook"
done
printf 'user hook\n' > .claude/hooks/my-own-hook.sh
for legacy_command in _my_capture.md _my_memorize.md _my_recall.md _my_review_compact.md; do
    printf 'legacy pack command\n' > ".claude/commands/$legacy_command"
done
cat > .claude/settings.json <<'JSON'
{
  "hooks": {
    "PreCompact": [{"matcher":"auto","hooks":[
      {"type":"command","command":".claude/hooks/precompact-capture.sh"},
      {"type":"command","command":".claude/hooks/my-own-precompact.sh"}
    ]}]
  },
  "model": "user-choice"
}
JSON

# Uninstall with --force (should remove vendored content)
"$SCRIPT_DIR/uninstall-project.sh" --force

# Verify .project removed
if [ -d ".project" ]; then
    echo -e "${RED}FAIL: .project not removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: .project removed${NC}"

# Verify vendored commands removed
if [ -f ".claude/commands/_my_research.md" ]; then
    echo -e "${RED}FAIL: Vendored command not removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Vendored commands removed${NC}"

for retired_path in \
    .claude/commands/_my_capture.md \
    .claude/commands/_my_memorize.md \
    .claude/commands/_my_recall.md \
    .claude/commands/_my_review_compact.md \
    .claude/agents/recall.md \
    .claude/rules/example-rules.md \
    .claude/hooks/capture.sh \
    .claude/hooks/precompact-capture.sh \
    .claude/hooks/parse-transcript.py \
    .claude/hooks/query-transcript.py; do
    if [ -e "$retired_path" ]; then
        echo -e "${RED}FAIL: Retired vendored file survived: $retired_path${NC}"
        exit 1
    fi
done
if [ ! -f .claude/hooks/my-own-hook.sh ]; then
    echo -e "${RED}FAIL: User hook was removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Retired vendored files removed and user hook preserved${NC}"

if [ "$(jq -r '.hooks.PreCompact[0].hooks | length' .claude/settings.json)" != "1" ] || \
   [ "$(jq -r '.hooks.PreCompact[0].hooks[0].command' .claude/settings.json)" != ".claude/hooks/my-own-precompact.sh" ] || \
   [ "$(jq -r '.model' .claude/settings.json)" != "user-choice" ]; then
    echo -e "${RED}FAIL: Project uninstall left the retired hook registration or changed user settings${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Project hook registration removed and user settings preserved${NC}"

# User preservation is part of the uninstall contract, not a warning.
if [ ! -f ".claude/commands/_my_custom.md" ]; then
    echo -e "${RED}FAIL: User-authored _my_ command was removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: User files in .claude preserved${NC}"

# Verify vendor marker removed
if [ -f ".claude/.agentic-pack-vendored" ]; then
    echo -e "${RED}FAIL: Vendor marker not removed${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Vendor marker removed${NC}"

# Test 9: Uninstall when no .project exists
echo "Test 9: Uninstall when nothing to uninstall..."
TEST_DIR="$TEST_BASE/project4"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

UNINSTALL_OUTPUT=$("$SCRIPT_DIR/uninstall-project.sh" --force 2>&1)
if echo "$UNINSTALL_OUTPUT" | grep -q "No .project"; then
    echo -e "${GREEN}PASS: Detects no .project${NC}"
else
    echo -e "${YELLOW}WARN: Unexpected output${NC}"
fi

echo ""
echo -e "${GREEN}All tests passed!${NC}"
