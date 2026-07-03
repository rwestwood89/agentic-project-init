#!/bin/bash
# Verify the pipeline shape line stays identical between the always-on rule
# (claude-pack/rules/pipeline.md) and the canonical command
# (claude-pack/commands/_my_pipeline.md). Both carry the same one-line stage
# shape, marked with `<!-- pipeline-shape -->`; this asserts they match so the
# two can't drift apart.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
RULE="$SOURCE_DIR/claude-pack/rules/pipeline.md"
CMD="$SOURCE_DIR/claude-pack/commands/_my_pipeline.md"

MARKER="<!-- pipeline-shape -->"

echo "Verifying pipeline shape is in sync..."
echo ""

fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# Extract the first non-empty line after the marker.
shape_after_marker() {
    local file="$1"
    awk -v m="$MARKER" '
        found && NF { print; exit }
        index($0, m) { found=1 }
    ' "$file"
}

[ -f "$RULE" ] || fail "rule not found: $RULE"
[ -f "$CMD" ]  || fail "command not found: $CMD"

grep -qF "$MARKER" "$RULE" || fail "marker '$MARKER' missing from rule: $RULE"
grep -qF "$MARKER" "$CMD"  || fail "marker '$MARKER' missing from command: $CMD"

rule_shape="$(shape_after_marker "$RULE")"
cmd_shape="$(shape_after_marker "$CMD")"

[ -n "$rule_shape" ] || fail "no shape line after marker in rule"
[ -n "$cmd_shape" ]  || fail "no shape line after marker in command"

if [ "$rule_shape" != "$cmd_shape" ]; then
    echo -e "${RED}✗ pipeline shape differs between rule and command${NC}"
    echo "  rule:    $rule_shape"
    echo "  command: $cmd_shape"
    exit 1
fi

echo -e "${GREEN}✓ pipeline shape in sync${NC}"
echo "  $rule_shape"
