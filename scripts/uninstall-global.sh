#!/bin/bash
# Agentic Pack Global Uninstall
# Removes symlinks and configuration from ~/.claude/
#
# Usage:
#   ./uninstall-global.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_DIR="$HOME/.claude"
SOURCE_FILE="$TARGET_DIR/.agentic-pack-source"

# Get source directory
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}Error: No agentic-pack installation found.${NC}"
    echo "File not found: $SOURCE_FILE"
    exit 1
fi

SOURCE_DIR=$(cat "$SOURCE_FILE")
REMOVED=0

echo -e "${GREEN}Agentic Pack Global Uninstall${NC}"
echo "=============================="
echo ""

# Remove symlinks that point to our source
remove_symlinks() {
    local dir="$1"
    local subdir="$2"

    [ -d "$dir" ] || return

    for file in "$dir"/*; do
        [ -e "$file" ] || [ -L "$file" ] || continue
        [ -L "$file" ] || continue

        # Check if symlink points to our source
        target=$(readlink "$file")
        if [[ "$target" == "$SOURCE_DIR"* ]]; then
            rm "$file"
            echo -e "${GREEN}  ✓ Removed: $subdir/$(basename "$file")${NC}"
            ((REMOVED++)) || true
        fi
    done
}

echo "Removing symlinks..."
for subdir in commands agents hooks skills rules; do
    remove_symlinks "$TARGET_DIR/$subdir" "$subdir"
done

# Remove hook configuration from settings.json
echo ""
echo "Cleaning settings.json..."
settings_file="$TARGET_DIR/settings.json"
if [ -f "$settings_file" ] && command -v jq &> /dev/null; then
    # Check if PreCompact hooks exist
    if jq -e '.hooks.PreCompact' "$settings_file" > /dev/null 2>&1; then
        # Create backup
        cp "$settings_file" "$settings_file.bak"
        # Remove hook entries that reference our hooks directory
        jq 'if .hooks.PreCompact then .hooks.PreCompact = [.hooks.PreCompact[] | select(.hooks | all(.command | contains("/.claude/hooks/") | not))] else . end | if .hooks.PreCompact == [] then del(.hooks.PreCompact) else . end | if .hooks == {} then del(.hooks) else . end' "$settings_file" > "$settings_file.tmp"
        mv "$settings_file.tmp" "$settings_file"
        echo -e "${GREEN}  ✓ Cleaned hook configuration${NC}"
    else
        echo -e "${YELLOW}  ⚠ No PreCompact hooks found${NC}"
    fi
elif [ -f "$settings_file" ]; then
    echo -e "${YELLOW}  ⚠ jq not found - please manually remove hook configuration${NC}"
else
    echo -e "${YELLOW}  ⚠ No settings.json found${NC}"
fi

# Remove metadata files
echo ""
echo "Removing metadata..."
for file in .agentic-pack-source .agentic-pack-version; do
    if [ -f "$TARGET_DIR/$file" ]; then
        rm "$TARGET_DIR/$file"
        echo -e "${GREEN}  ✓ Removed: $file${NC}"
        ((REMOVED++)) || true
    fi
done

echo ""
echo -e "${GREEN}✓ Uninstall complete!${NC}"
echo "Removed $REMOVED items."
echo ""
echo "Note: Empty directories in ~/.claude/ were preserved."
echo "      User-created files were not removed."
echo ""
echo "Commands will no longer be available after restarting Claude Code."
