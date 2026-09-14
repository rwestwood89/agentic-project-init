#!/bin/bash
# Remove files copied by retired versions of the vendored Claude pack.

: "${GREEN:=}"
: "${NC:=}"

cleanup_legacy_vendored_files() {
    local claude_dir="$1"
    local relative_path
    local retired_paths=(
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

    for relative_path in "${retired_paths[@]}"; do
        if [ -e "$claude_dir/$relative_path" ] || [ -L "$claude_dir/$relative_path" ]; then
            rm "$claude_dir/$relative_path"
            echo -e "${GREEN}  ✓ Removed retired vendored file: $relative_path${NC}"
        fi
    done
}
