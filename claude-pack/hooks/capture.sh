#!/bin/bash
# Capture a conversation transcript for later review with /_my_memorize
#
# Usage:
#   ./capture.sh <transcript_path> [source]
#   echo '{"transcript_path":...}' | ./capture.sh --stdin
#
# source: "auto" (from PreCompact) or "manual" (from /capture)

set -e

MEMORIES_DIR=".project/memories"
mkdir -p "$MEMORIES_DIR"

# Parse arguments
if [ "$1" == "--stdin" ]; then
    # Called from PreCompact hook - read JSON from stdin
    HOOK_INPUT=$(cat)
    TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')
    SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id')
    TRIGGER=$(echo "$HOOK_INPUT" | jq -r '.trigger')

    # Only capture on auto-compaction
    if [ "$TRIGGER" != "auto" ]; then
        exit 0
    fi

    SOURCE="auto"
else
    # Called directly with path argument
    TRANSCRIPT_PATH="$1"
    SOURCE="${2:-manual}"
    SESSION_ID=$(basename "$TRANSCRIPT_PATH" .jsonl)
fi

# Expand ~ in path
TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"

# Check transcript exists
if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "Error: transcript not found at $TRANSCRIPT_PATH" >&2
    exit 1
fi

# Extract first user message from transcript
FIRST_MESSAGE=$(cat "$TRANSCRIPT_PATH" | jq -r 'select(.type == "user") | .message.content' | head -1 | cut -c1-500)

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create capture file
CAPTURE_FILE="$MEMORIES_DIR/${TIMESTAMP}-capture.md"

cat > "$CAPTURE_FILE" << EOF
# Capture

**Status:** pending
**Timestamp:** $(date -Iseconds)
**Session ID:** $SESSION_ID
**Source:** $SOURCE

## Transcript

\`\`\`
$TRANSCRIPT_PATH
\`\`\`

## First Message

> ${FIRST_MESSAGE}

## Memory

_Not yet processed. Run \`/_my_memorize\` to create memory artifact._
EOF

# Update index.json
INDEX_FILE="$MEMORIES_DIR/index.json"

# Create index if it doesn't exist
if [ ! -f "$INDEX_FILE" ]; then
    echo '{"memories":[],"transcripts":{}}' > "$INDEX_FILE"
fi

# Add to index using jq
TEMP_INDEX=$(mktemp)
jq --arg id "$TIMESTAMP" \
   --arg ts "$(date -Iseconds)" \
   --arg transcript "$TRANSCRIPT_PATH" \
   --arg first_msg "$FIRST_MESSAGE" \
   --arg source "$SOURCE" \
   '.transcripts[$transcript] = {
      "first_message": $first_msg,
      "last_indexed": $ts,
      "capture_id": $id,
      "source": $source,
      "memory_ids": []
    }' "$INDEX_FILE" > "$TEMP_INDEX" && mv "$TEMP_INDEX" "$INDEX_FILE"

echo "$CAPTURE_FILE"
