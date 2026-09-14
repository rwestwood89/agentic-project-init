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

assert_eq() {
    local expected="$1" actual="$2" label="$3"
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}PASS: $label${NC}"
    else
        echo -e "${RED}FAIL: $label - expected '$expected', got '$actual'${NC}"
        exit 1
    fi
}

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
for dir in commands agents skills rules; do
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

# The pack registers no hooks, so a fresh install must not write settings.json at all
if [ -f "$TEST_HOME/.claude/settings.json" ]; then
    echo -e "${RED}FAIL: fresh install created settings.json${NC}"
    cat "$TEST_HOME/.claude/settings.json"
    exit 1
fi
echo -e "${GREEN}PASS: fresh install leaves settings.json alone${NC}"

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

if [ ! -L "$TEST_HOME/.claude/skills/_my_mental_model_v2" ]; then
    echo -e "${RED}FAIL: V2 mental-model skill symlink not created${NC}"
    exit 1
fi
V2_SKILL_TARGET=$(readlink "$TEST_HOME/.claude/skills/_my_mental_model_v2")
if [[ ! "$V2_SKILL_TARGET" == *"claude-pack/skills/_my_mental_model_v2" ]]; then
    echo -e "${RED}FAIL: V2 mental-model skill points to wrong source: $V2_SKILL_TARGET${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: V2 mental-model command installed separately${NC}"
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

# A prior release installed hook symlinks. The hooks directory is no longer created, but an
# upgrade must still sweep pack-owned links left by that release.
mkdir -p "$TEST_HOME/.claude/hooks"
ln -s "$(dirname "$SCRIPT_DIR")/claude-pack/hooks/precompact-capture.sh" "$TEST_HOME/.claude/hooks/precompact-capture.sh"
"$SETUP_SCRIPT" > /dev/null
if [ -L "$TEST_HOME/.claude/hooks/precompact-capture.sh" ]; then
    echo -e "${RED}FAIL: Legacy hook symlink survived setup${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Legacy hook symlink removed during setup${NC}"
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

# Test 5: Legacy PreCompact hook cleanup
# The pack used to register a PreCompact hook pointing at precompact-capture.sh. That script
# no longer ships, so installs that ran before it was removed keep firing a dangling hook.
# Case 4 is the reason the filter matches the script name and not the hooks directory.
echo "Test 5: Legacy PreCompact hook cleanup..."
source "$SCRIPT_DIR/lib/settings-hooks.sh"

FIXTURES="$TEST_HOME/fixtures"
mkdir -p "$FIXTURES"

# Case 1: pack PreCompact removed, user PreToolUse untouched, unrelated keys intact
cat > "$FIXTURES/case1.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [{"matcher":"Read|Edit","hooks":[{"type":"command","command":"/home/u/.claude/hooks/auto-approve-paths.sh"}]}],
    "PreCompact": [{"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"}]}]
  },
  "model": "claude-opus-5"
}
JSON
cleanup_legacy_hooks "$FIXTURES/case1.json" > /dev/null
assert_eq "absent" "$(jq -r '.hooks.PreCompact // "absent"' "$FIXTURES/case1.json")" \
    "Case 1: pack PreCompact removed"
assert_eq "/home/u/.claude/hooks/auto-approve-paths.sh" \
    "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$FIXTURES/case1.json")" \
    "Case 1: user PreToolUse untouched"
assert_eq "claude-opus-5" "$(jq -r '.model' "$FIXTURES/case1.json")" \
    "Case 1: unrelated keys intact"

# Case 2: pack hook was the only hook -> .hooks key removed entirely, file still valid JSON
cat > "$FIXTURES/case2.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [{"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"}]}]
  },
  "model": "claude-opus-5"
}
JSON
cleanup_legacy_hooks "$FIXTURES/case2.json" > /dev/null
assert_eq "absent" "$(jq -r '.hooks // "absent"' "$FIXTURES/case2.json")" \
    "Case 2: emptied hooks object removed"
assert_eq "claude-opus-5" "$(jq -r '.model' "$FIXTURES/case2.json")" \
    "Case 2: rest of the file intact"

# Case 3: no hooks at all -> no-op, file unchanged byte-for-byte and no backup written
cat > "$FIXTURES/case3.json" <<'JSON'
{
  "model": "claude-opus-5"
}
JSON
cp "$FIXTURES/case3.json" "$FIXTURES/case3.expected"
cleanup_legacy_hooks "$FIXTURES/case3.json" > /dev/null
if cmp -s "$FIXTURES/case3.json" "$FIXTURES/case3.expected"; then
    echo -e "${GREEN}PASS: Case 3: settings without hooks unchanged byte-for-byte${NC}"
else
    echo -e "${RED}FAIL: Case 3: settings without hooks were rewritten${NC}"
    exit 1
fi
if [ -f "$FIXTURES/case3.json.bak" ]; then
    echo -e "${RED}FAIL: Case 3: backup written for a no-op${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Case 3: no backup written for a no-op${NC}"

# Case 4: a USER PreCompact hook in the same directory survives; only the pack entry goes
cat > "$FIXTURES/case4.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [
      {"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/my-own-precompact.sh"}]},
      {"matcher":"manual","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"}]}
    ]
  }
}
JSON
cleanup_legacy_hooks "$FIXTURES/case4.json" > /dev/null
assert_eq "1" "$(jq -r '.hooks.PreCompact | length' "$FIXTURES/case4.json")" \
    "Case 4: pack entry removed"
assert_eq "/home/u/.claude/hooks/my-own-precompact.sh" \
    "$(jq -r '.hooks.PreCompact[0].hooks[0].command' "$FIXTURES/case4.json")" \
    "Case 4: user PreCompact hook in the same directory survives"

# Case 5: a user-only PreCompact array is a byte-for-byte no-op with no backup or success report
cat > "$FIXTURES/case5.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [{"matcher":"manual","hooks":[{"type":"command","command":"/home/u/.claude/hooks/my-own-precompact.sh"}]}]
  }
}
JSON
cp "$FIXTURES/case5.json" "$FIXTURES/case5.expected"
CASE5_OUTPUT=$(cleanup_legacy_hooks "$FIXTURES/case5.json")
if ! cmp -s "$FIXTURES/case5.json" "$FIXTURES/case5.expected"; then
    echo -e "${RED}FAIL: Case 5: user-only settings were rewritten${NC}"
    exit 1
fi
if [ -f "$FIXTURES/case5.json.bak" ]; then
    echo -e "${RED}FAIL: Case 5: backup written for user-only settings${NC}"
    exit 1
fi
assert_eq "" "$CASE5_OUTPUT" "Case 5: user-only settings produce no removal report"

# Case 6: pack and user commands in the same entry -> only the pack command goes
cat > "$FIXTURES/case6.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [
      {"matcher":"auto","hooks":[
        {"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"},
        {"type":"command","command":"/home/u/.claude/hooks/my-own-precompact.sh"}
      ]}
    ]
  }
}
JSON
cleanup_legacy_hooks "$FIXTURES/case6.json" > /dev/null
assert_eq "1" "$(jq -r '.hooks.PreCompact | length' "$FIXTURES/case6.json")" \
    "Case 6: mixed PreCompact entry survives"
assert_eq "1" "$(jq -r '.hooks.PreCompact[0].hooks | length' "$FIXTURES/case6.json")" \
    "Case 6: only one command removed"
assert_eq "/home/u/.claude/hooks/my-own-precompact.sh" \
    "$(jq -r '.hooks.PreCompact[0].hooks[0].command' "$FIXTURES/case6.json")" \
    "Case 6: user command in mixed entry survives"

# Case 7: malformed settings -> fail visibly without changing the file
printf '%s\n' '{"hooks":' > "$FIXTURES/case7.json"
cp "$FIXTURES/case7.json" "$FIXTURES/case7.expected"
if CASE7_OUTPUT=$(cleanup_legacy_hooks "$FIXTURES/case7.json" 2>&1); then
    echo -e "${RED}FAIL: Case 7: malformed settings reported success${NC}"
    exit 1
fi
if ! cmp -s "$FIXTURES/case7.json" "$FIXTURES/case7.expected"; then
    echo -e "${RED}FAIL: Case 7: malformed settings were changed${NC}"
    exit 1
fi
if ! echo "$CASE7_OUTPUT" | grep -qi 'invalid JSON'; then
    echo -e "${RED}FAIL: Case 7: malformed settings error was not clear${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Case 7: malformed settings fail visibly and remain unchanged${NC}"

# Case 8: a similarly named user hook is not the exact retired command
cat > "$FIXTURES/case8.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [{"matcher":"manual","hooks":[{"type":"command","command":"/home/u/.claude/hooks/my-precompact-capture.sh"}]}]
  }
}
JSON
cp "$FIXTURES/case8.json" "$FIXTURES/case8.expected"
cleanup_legacy_hooks "$FIXTURES/case8.json" > /dev/null
if ! cmp -s "$FIXTURES/case8.json" "$FIXTURES/case8.expected"; then
    echo -e "${RED}FAIL: Case 8: similarly named user hook was changed${NC}"
    exit 1
fi
if [ -f "$FIXTURES/case8.json.bak" ]; then
    echo -e "${RED}FAIL: Case 8: backup written for near-name no-op${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: Case 8: similarly named user hook survives unchanged${NC}"

# Every fixture is still valid JSON
for fixture in "$FIXTURES"/case[1-6].json "$FIXTURES/case8.json"; do
    if ! jq empty "$fixture" 2>/dev/null; then
        echo -e "${RED}FAIL: $(basename "$fixture") is not valid JSON after cleanup${NC}"
        exit 1
    fi
done
echo -e "${GREEN}PASS: All fixtures still valid JSON${NC}"
echo ""

# Count symlinks
SYMLINK_COUNT=$(find "$TEST_HOME/.claude/commands" -type l | wc -l)
echo "Created $SYMLINK_COUNT command symlinks"

echo ""
echo -e "${GREEN}All tests passed!${NC}"
