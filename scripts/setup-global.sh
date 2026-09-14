#!/bin/bash
# Agentic Pack Global Setup
# Installs commands, agents, skills, and rules to ~/.claude/
#
# Usage:
#   ./setup-global.sh [--dry-run]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Determine script location (source repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"  # Parent of scripts/
CLAUDE_PACK="$SOURCE_DIR/claude-pack"

# shellcheck source=lib/settings-hooks.sh
source "$SCRIPT_DIR/lib/settings-hooks.sh"

# Version from git or file
VERSION=$(git -C "$SOURCE_DIR" describe --tags 2>/dev/null || git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --dry-run  Show what would be done without making changes"
            echo "  -h, --help Show this help message"
            exit 0
            ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# Target directory
TARGET_DIR="$HOME/.claude"

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ "$DRY_RUN" = true ]; then
        if [ -e "$target" ]; then
            echo -e "${YELLOW}[DRY RUN] Would skip (exists): $name${NC}"
        else
            echo -e "${GREEN}[DRY RUN] Would create: $target → $source${NC}"
        fi
        return
    fi

    if [ -L "$target" ]; then
        echo -e "${YELLOW}  ⚠ Symlink already exists: $name${NC}"
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}  ⚠ File exists (not symlink): $name${NC}"
    else
        ln -s "$source" "$target"
        echo -e "${GREEN}  ✓ $name${NC}"
    fi
}

# Create directory structure
create_dir() {
    local dir="$1"
    if [ "$DRY_RUN" = true ]; then
        if [ ! -d "$dir" ]; then
            echo -e "${BLUE}[DRY RUN] Would create: $dir${NC}"
        fi
        return 0
    fi
    mkdir -p "$dir"
}

# Remove symlinks we installed whose pack source no longer exists — a deleted or renamed command,
# agent, rule, script, or skill. ADR 0009 promises more command→skill migrations, so removals and
# renames are a recurring event rather than a one-off. Only symlinks pointing into this repo's
# claude-pack/ are touched; anything the user put there themselves is left alone.
sweep_dead_symlinks() {
    local subdir entry link_target

    for subdir in commands agents hooks skills rules scripts; do
        [ -d "$TARGET_DIR/$subdir" ] || continue
        for entry in "$TARGET_DIR/$subdir"/*; do
            if [ ! -L "$entry" ]; then
                continue
            fi
            link_target="$(readlink "$entry")"
            case "$link_target" in
                "$CLAUDE_PACK"/*) ;;
                *) continue ;;
            esac
            if [ -e "$entry" ]; then
                continue
            fi
            if [ "$DRY_RUN" = true ]; then
                echo -e "${YELLOW}[DRY RUN] Would remove dead symlink: $subdir/$(basename "$entry")${NC}"
            else
                rm "$entry"
                echo -e "${GREEN}  ✓ Removed dead symlink: $subdir/$(basename "$entry")${NC}"
            fi
        done
    done
}

# Main execution
echo -e "${GREEN}Agentic Pack Global Setup${NC}"
echo "========================="
[ "$DRY_RUN" = true ] && echo -e "${YELLOW}[DRY RUN MODE]${NC}"
echo ""

# Verify source exists
if [ ! -d "$CLAUDE_PACK" ]; then
    echo -e "${RED}Error: claude-pack not found at $CLAUDE_PACK${NC}"
    exit 1
fi

# Create directories
for subdir in commands agents skills rules scripts; do
    create_dir "$TARGET_DIR/$subdir"
done

# Symlink commands
echo "Setting up commands..."
for file in "$CLAUDE_PACK"/commands/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    create_symlink "$file" "$TARGET_DIR/commands/$filename" "$filename"
done

# Symlink agents
echo ""
echo "Setting up agents..."
for file in "$CLAUDE_PACK"/agents/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    create_symlink "$file" "$TARGET_DIR/agents/$filename" "$filename"
done

# Symlink skills
echo ""
echo "Setting up skills..."
if [ -d "$CLAUDE_PACK/skills" ]; then
    # Files and directories both: Claude Code only registers directory skills
    # (skills/<name>/SKILL.md); flat .md files are legacy.
    for file in "$CLAUDE_PACK"/skills/*; do
        [ -f "$file" ] || [ -d "$file" ] || continue
        filename=$(basename "$file")
        create_symlink "$file" "$TARGET_DIR/skills/$filename" "$filename"
    done
fi

# Symlink rules
echo ""
echo "Setting up rules..."
if [ -d "$CLAUDE_PACK/rules" ]; then
    for file in "$CLAUDE_PACK"/rules/*.md; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        create_symlink "$file" "$TARGET_DIR/rules/$filename" "$filename"
    done
fi

# Symlink scripts
echo ""
echo "Setting up scripts..."
if [ -d "$CLAUDE_PACK/scripts" ]; then
    for file in "$CLAUDE_PACK"/scripts/*; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        create_symlink "$file" "$TARGET_DIR/scripts/$filename" "$filename"
    done
fi

# Sweep symlinks whose pack source is gone
echo ""
echo "Removing dead symlinks..."
sweep_dead_symlinks

# Strip a PreCompact registration an earlier version of the pack wrote. The script it
# points at no longer ships, so an install that ran before it was removed keeps firing a
# dangling hook. See .project/active/retire-hidden-memories/spec.md.
echo ""
echo "Removing legacy hook registration..."
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY RUN] Would remove any pack-written PreCompact hook from $TARGET_DIR/settings.json${NC}"
else
    cleanup_legacy_hooks "$TARGET_DIR/settings.json"
fi

# Write metadata files
echo ""
echo "Writing metadata..."
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY RUN] Would write: .agentic-pack-source = $SOURCE_DIR${NC}"
    echo -e "${BLUE}[DRY RUN] Would write: .agentic-pack-version = $VERSION${NC}"
else
    echo "$SOURCE_DIR" > "$TARGET_DIR/.agentic-pack-source"
    echo "$VERSION" > "$TARGET_DIR/.agentic-pack-version"
    echo -e "${GREEN}  ✓ Source: $SOURCE_DIR${NC}"
    echo -e "${GREEN}  ✓ Version: $VERSION${NC}"
fi

# Next steps
echo ""
echo -e "${GREEN}✓ Global setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code to pick up new commands"
echo "2. Run 'init-project.sh' in each project that needs .project/"
echo ""
echo "Commands will be available as /_my_<command> (e.g., /_my_research)"
echo ""
echo "Ralph Loop (autonomous project scaffolding):"
echo "  ~/.claude/scripts/ralph-init.sh <project_name> <concept_file>"
echo "  Run from any git repo with a concept markdown file."
echo ""
echo "To update later, run: cd $SOURCE_DIR && git pull"
