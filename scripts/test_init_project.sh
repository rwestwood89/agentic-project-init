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

# Git is the backup. A tracked script backup is a second shipped implementation.
TRACKED_BACKUPS=""
while read -r path; do
    [ -e "$SOURCE_DIR/$path" ] || continue
    TRACKED_BACKUPS="${TRACKED_BACKUPS}${path}"$'\n'
done < <(git -C "$SOURCE_DIR" ls-files 'scripts/*.bak' 'scripts/*.old' 'scripts/*~')
if [ -n "$TRACKED_BACKUPS" ]; then
    echo -e "${RED}FAIL: tracked script backups found:${NC}"
    echo "$TRACKED_BACKUPS"
    exit 1
fi
echo -e "${GREEN}PASS: no tracked script backups${NC}"

# Check every tracked executable, not only the initializer this test invokes.
RETIRED_PRODUCERS=""
while read -r mode _ _ path; do
    [ "$mode" = "100755" ] || continue
    [ -f "$SOURCE_DIR/$path" ] || continue
    case "$path" in scripts/test_*.sh) continue ;; esac
    matches=$(grep -nE 'claude-pack/hooks|create_symlink.*\.claude/hooks|for dir in .*memories|mkdir -p .*\.project/memories' "$SOURCE_DIR/$path" || true)
    [ -z "$matches" ] || RETIRED_PRODUCERS="${RETIRED_PRODUCERS}${path}:${matches}"$'\n'
done < <(git -C "$SOURCE_DIR" ls-files -s scripts)
if [ -n "$RETIRED_PRODUCERS" ]; then
    echo -e "${RED}FAIL: tracked executables still create retired surfaces:${NC}"
    printf '%s' "$RETIRED_PRODUCERS"
    exit 1
fi
echo -e "${GREEN}PASS: tracked executables do not create retired surfaces${NC}"

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
for dir in research reports active completed backlog; do
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

# The pack registers no hooks, so vendoring must not write .claude/settings.json at all
if [ -f ".claude/settings.json" ]; then
    echo -e "${RED}FAIL: vendoring created .claude/settings.json${NC}"
    cat ".claude/settings.json"
    exit 1
fi
echo -e "${GREEN}PASS: vendoring leaves settings.json alone${NC}"

# A rerun upgrades the complete old vendored surface from the owner-approved retirement scope.
RETIRED_VENDORED_PATHS=(
    "commands/_my_capture.md"
    "commands/_my_memorize.md"
    "commands/_my_recall.md"
    "commands/_my_review_compact.md"
    "agents/recall.md"
    "rules/example-rules.md"
    "hooks/capture.sh"
    "hooks/precompact-capture.sh"
    "hooks/parse-transcript.py"
    "hooks/query-transcript.py"
)
for retired_path in "${RETIRED_VENDORED_PATHS[@]}"; do
    mkdir -p ".claude/$(dirname "$retired_path")"
    printf '%s\n' 'legacy pack content' > ".claude/$retired_path"
done
printf '%s\n' 'user hook' > .claude/hooks/my-own-hook.sh
printf '%s\n' 'user command' > .claude/commands/_my_custom.md
cat > .claude/settings.json <<'JSON'
{"hooks":{"PreCompact":[{"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"},{"type":"command","command":"/home/u/.claude/hooks/my-own-precompact.sh"}]}]}}
JSON

"$INIT_SCRIPT" --source "$SOURCE_DIR" --include-claude > /dev/null

for retired_path in "${RETIRED_VENDORED_PATHS[@]}"; do
    if [ -e ".claude/$retired_path" ]; then
        echo -e "${RED}FAIL: vendored upgrade kept retired file: .claude/$retired_path${NC}"
        exit 1
    fi
done
if [ ! -f .claude/hooks/my-own-hook.sh ] || [ ! -f .claude/commands/_my_custom.md ]; then
    echo -e "${RED}FAIL: vendored upgrade removed a user file${NC}"
    exit 1
fi
if [ "$(jq -r '.hooks.PreCompact[0].hooks | length' .claude/settings.json)" != "1" ] || \
   [ "$(jq -r '.hooks.PreCompact[0].hooks[0].command' .claude/settings.json)" != "/home/u/.claude/hooks/my-own-precompact.sh" ]; then
    echo -e "${RED}FAIL: vendored upgrade did not preserve the mixed-entry user hook${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: vendored upgrade removes retired files and preserves user state${NC}"
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

# Check a directory omitted from the partial fixture was added
if [ ! -d ".project/reports" ]; then
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

# Test 8: --force protects accumulated feedback
# feedback/ENTRIES.md accumulates agent learnings across many sessions and is never
# regenerated. If it drops out of USER_DATA_FILES, --force silently replaces months of
# entries with the empty template.
echo "Test 8: --force protects feedback entries..."
TEST_DIR="$TEST_BASE/test8"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

"$INIT_SCRIPT" --source "$SOURCE_DIR"

if [ ! -f ".project/feedback/ENTRIES.md" ] || [ ! -f ".project/feedback/README.md" ]; then
    echo -e "${RED}FAIL: feedback files not seeded on init${NC}"
    exit 1
fi

# Accumulate an entry, and stale out the instructions file
echo "## [_my_spec] 2026-08-25" >> .project/feedback/ENTRIES.md
echo "stale instructions" > .project/feedback/README.md

"$INIT_SCRIPT" --source "$SOURCE_DIR" --force

if grep -qF "## [_my_spec] 2026-08-25" .project/feedback/ENTRIES.md; then
    echo -e "${GREEN}PASS: --force preserved accumulated feedback entries${NC}"
else
    echo -e "${RED}FAIL: --force destroyed accumulated feedback entries${NC}"
    echo -e "${RED}      feedback/ENTRIES.md must be listed in USER_DATA_FILES in init-project.sh${NC}"
    exit 1
fi

if grep -q "How to Record Feedback" .project/feedback/README.md; then
    echo -e "${GREEN}PASS: --force refreshed the feedback instructions${NC}"
else
    echo -e "${RED}FAIL: --force did not update feedback/README.md${NC}"
    echo -e "${RED}      the instructions file must NOT be user data${NC}"
    exit 1
fi
echo ""

# Test 9: --force protects accumulated execution-register entries
# execution/ENTRIES.md accumulates agent-written execution facts across many sessions
# and is never regenerated. If it drops out of USER_DATA_FILES, --force silently replaces
# months of entries with the empty template.
echo "Test 9: execution register seeds; --force protects the log, refreshes the rules..."
TEST_DIR="$TEST_BASE/test9"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q

"$INIT_SCRIPT" --source "$SOURCE_DIR"

if [ ! -f ".project/execution/ENTRIES.md" ] || [ ! -f ".project/execution/README.md" ]; then
    echo -e "${RED}FAIL: execution register not seeded on init${NC}"
    exit 1
fi

# Accumulate an entry, and stale out the instructions file
echo "## [init-project.sh] 2026-09-10" >> .project/execution/ENTRIES.md
echo "stale rules" > .project/execution/README.md

"$INIT_SCRIPT" --source "$SOURCE_DIR" --force

if grep -qF "## [init-project.sh] 2026-09-10" .project/execution/ENTRIES.md; then
    echo -e "${GREEN}PASS: --force preserved accumulated execution entries${NC}"
else
    echo -e "${RED}FAIL: --force destroyed accumulated execution entries${NC}"
    echo -e "${RED}      execution/ENTRIES.md must be listed in USER_DATA_FILES in init-project.sh${NC}"
    exit 1
fi

if grep -q "density bar" .project/execution/README.md; then
    echo -e "${GREEN}PASS: --force refreshed the execution register rules${NC}"
else
    echo -e "${RED}FAIL: --force did not update execution/README.md${NC}"
    echo -e "${RED}      the instructions file must NOT be user data${NC}"
    exit 1
fi

if [ ! -f ".project/TRIAGE_MEMORIES.md" ]; then
    echo -e "${RED}FAIL: triage prompt not seeded on init${NC}"
    exit 1
fi
echo -e "${GREEN}PASS: triage prompt seeded on init${NC}"

echo "stale" > .project/TRIAGE_MEMORIES.md
"$INIT_SCRIPT" --source "$SOURCE_DIR" --force
if grep -q "execution/README.md" .project/TRIAGE_MEMORIES.md; then
    echo -e "${GREEN}PASS: --force refreshed the triage prompt${NC}"
else
    echo -e "${RED}FAIL: --force did not refresh the triage prompt${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}All tests passed!${NC}"
