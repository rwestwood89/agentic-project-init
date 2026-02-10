#!/bin/bash
set -euo pipefail

# =============================================================================
# validate-specs-output.sh — Validate fenced spec blocks in Claude output
# =============================================================================
#
# Usage: validate-specs-output.sh [file]
#        cat output.md | validate-specs-output.sh
#
# Checks for properly formatted ```markdown specs/FILENAME.md fenced blocks.
#
# Exit codes:
#   0 — PASS: valid spec blocks found
#   1 — FAIL: validation errors detected
# =============================================================================

# Read input from file arg or stdin
if [[ $# -ge 1 ]] && [[ -f "$1" ]]; then
    INPUT=$(cat "$1")
else
    INPUT=$(cat)
fi

if [[ -z "$INPUT" ]]; then
    echo "FAIL: empty input"
    exit 1
fi

# Pattern for opening fence: ```markdown specs/FILENAME.md
FENCE_PATTERN='^ *```markdown specs/[^ ]+\.md[[:space:]]*$'

# Count opening fences
OPENING_COUNT=$(echo "$INPUT" | grep -cE "$FENCE_PATTERN" || true)

if [[ "$OPENING_COUNT" -eq 0 ]]; then
    # Diagnose the problem
    TOTAL_LINES=$(echo "$INPUT" | wc -l)
    FIRST_LINE=$(echo "$INPUT" | sed '/^[[:space:]]*$/d' | head -1)

    # Check if it's a prose/summary response
    if [[ "$FIRST_LINE" =~ ^(I\'ve\ |I\ have\ |Here\ are|Here\ is|Below\ |The\ following\ |Sure|Let\ me|Certainly|Of\ course) ]]; then
        echo "FAIL: prose/summary response detected (no fenced spec blocks)"
        echo "  First line: '${FIRST_LINE:0:80}'"
        echo "  Total lines: $TOTAL_LINES"
        exit 1
    fi

    # Check if there are fences but wrong format
    WRONG_FENCES=$(echo "$INPUT" | grep -cE '^ *```' || true)
    if [[ "$WRONG_FENCES" -gt 0 ]]; then
        # Show what fence formats were found
        echo "FAIL: found $WRONG_FENCES code fences but none match required format"
        echo "  Required: \`\`\`markdown specs/FILENAME.md"
        echo "  Found fences:"
        echo "$INPUT" | grep -E '^ *```' | head -5 | while read -r line; do
            echo "    $line"
        done
        exit 1
    fi

    echo "FAIL: no fenced spec blocks found in output ($TOTAL_LINES lines)"
    echo "  First line: '${FIRST_LINE:0:80}'"
    exit 1
fi

# Parse and validate each block
SPEC_NAMES=()
ERRORS=()
BLOCK_NUM=0
IN_BLOCK=false
BLOCK_CONTENT_LINES=0
CURRENT_SPEC=""

while IFS= read -r line; do
    if [[ "$IN_BLOCK" = false ]]; then
        if [[ "$line" =~ ^[[:space:]]*\`\`\`markdown[[:space:]]+(specs/[^[:space:]]+\.md) ]]; then
            IN_BLOCK=true
            BLOCK_NUM=$((BLOCK_NUM + 1))
            CURRENT_SPEC="${BASH_REMATCH[1]}"
            BLOCK_CONTENT_LINES=0
        fi
    else
        if [[ "$line" =~ ^[[:space:]]*\`\`\`[[:space:]]*$ ]]; then
            # Closing fence
            IN_BLOCK=false
            if [[ "$BLOCK_CONTENT_LINES" -lt 3 ]]; then
                ERRORS+=("Block $BLOCK_NUM ($CURRENT_SPEC): only $BLOCK_CONTENT_LINES content lines (minimum 3)")
            else
                SPEC_NAMES+=("$CURRENT_SPEC")
            fi
        else
            BLOCK_CONTENT_LINES=$((BLOCK_CONTENT_LINES + 1))
        fi
    fi
done <<< "$INPUT"

# Check for unclosed block
if [[ "$IN_BLOCK" = true ]]; then
    ERRORS+=("Block $BLOCK_NUM ($CURRENT_SPEC): unclosed fence (no closing \`\`\`)")
fi

# Report results
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "FAIL: ${#ERRORS[@]} validation error(s) in $BLOCK_NUM block(s)"
    for err in "${ERRORS[@]}"; do
        echo "  - $err"
    done
    if [[ ${#SPEC_NAMES[@]} -gt 0 ]]; then
        echo "  Valid blocks: ${SPEC_NAMES[*]}"
    fi
    exit 1
fi

if [[ ${#SPEC_NAMES[@]} -eq 0 ]]; then
    echo "FAIL: no valid spec blocks found (all blocks had errors)"
    exit 1
fi

echo "PASS: ${#SPEC_NAMES[@]} spec blocks found: ${SPEC_NAMES[*]}"
exit 0
