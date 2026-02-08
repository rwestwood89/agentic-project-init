#!/bin/bash
# Agentic Pack Global Setup
# Installs commands, agents, hooks, skills, and rules to ~/.claude/
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
    else
        mkdir -p "$dir"
    fi
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
for subdir in commands agents hooks skills rules scripts; do
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

# Symlink hooks
echo ""
echo "Setting up hooks..."

# Migrate existing auto-approve.sh (old hardcoded version -> new symlinked version)
existing_hook="$TARGET_DIR/hooks/auto-approve.sh"
if [ -f "$existing_hook" ] && [ ! -L "$existing_hook" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] Would back up existing auto-approve.sh -> auto-approve.sh.bak${NC}"
    else
        cp "$existing_hook" "${existing_hook}.bak"
        rm "$existing_hook"
        echo -e "${YELLOW}  ⚠ Backed up existing auto-approve.sh -> auto-approve.sh.bak${NC}"
        echo -e "${YELLOW}    (Old hardcoded hook replaced with config-driven version)${NC}"
    fi
fi

for file in "$CLAUDE_PACK"/hooks/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    # Skip default config template (copied, not symlinked)
    [[ "$filename" == *.default.json ]] && continue
    create_symlink "$file" "$TARGET_DIR/hooks/$filename" "$filename"
done

# Copy default config if not exists (user-specific data, not symlinked)
config_source="$CLAUDE_PACK/hooks/allowed-tools.default.json"
config_target="$TARGET_DIR/hooks/allowed-tools.json"
if [ -f "$config_source" ]; then
    if [ "$DRY_RUN" = true ]; then
        if [ -e "$config_target" ]; then
            echo -e "${YELLOW}[DRY RUN] Would skip (exists): allowed-tools.json${NC}"
        else
            echo -e "${GREEN}[DRY RUN] Would copy default config: allowed-tools.json${NC}"
        fi
    elif [ ! -e "$config_target" ]; then
        cp "$config_source" "$config_target"
        echo -e "${GREEN}  ✓ allowed-tools.json (default config)${NC}"
    else
        echo -e "${YELLOW}  ⚠ allowed-tools.json already exists (preserved)${NC}"
    fi
fi

# Symlink skills
echo ""
echo "Setting up skills..."
if [ -d "$CLAUDE_PACK/skills" ]; then
    for file in "$CLAUDE_PACK"/skills/*; do
        [ -f "$file" ] || continue
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

# Configure settings.json (hook configuration)
echo ""
echo "Configuring hooks..."
configure_hooks() {
    local settings_file="$TARGET_DIR/settings.json"
    local hook_path="$TARGET_DIR/hooks/precompact-capture.sh"
    local auto_approve_path="$TARGET_DIR/hooks/auto-approve.sh"

    # Hook configuration — includes ALL hook types (shallow merge replaces entire hooks object)
    local hook_config='{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "'"$hook_path"'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$auto_approve_path"'",
            "timeout": 60
          }
        ]
      }
    ]
  }
}'

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would configure hooks in $settings_file${NC}"
        return
    fi

    if [ -f "$settings_file" ]; then
        # Merge with existing - use jq if available
        if command -v jq &> /dev/null; then
            # Backup existing
            cp "$settings_file" "$settings_file.bak"
            # Merge configurations
            jq -s '.[0] * .[1]' "$settings_file" <(echo "$hook_config") > "$settings_file.tmp"
            mv "$settings_file.tmp" "$settings_file"
            echo -e "${GREEN}  ✓ Merged hooks into existing settings.json${NC}"
        else
            echo -e "${YELLOW}  ⚠ jq not found - please manually add hook configuration${NC}"
            echo -e "${YELLOW}    Add PreCompact hook pointing to: $hook_path${NC}"
        fi
    else
        echo "$hook_config" > "$settings_file"
        echo -e "${GREEN}  ✓ Created settings.json with hook configuration${NC}"
    fi
}
configure_hooks

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

# Write hook paths config
write_hook_paths() {
    local config_file="$TARGET_DIR/.hook-paths.json"
    local hooks_dir="$CLAUDE_PACK/hooks"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would write hook paths to $config_file${NC}"
        return
    fi

    cat > "$config_file" << EOF
{
  "version": 1,
  "resolved_at": "$(date -Iseconds)",
  "source": "$SOURCE_DIR",
  "hooks": {
    "query-transcript": "$hooks_dir/query-transcript.py",
    "parse-transcript": "$hooks_dir/parse-transcript.py",
    "capture": "$hooks_dir/capture.sh",
    "precompact-capture": "$hooks_dir/precompact-capture.sh",
    "auto-approve": "$hooks_dir/auto-approve.sh",
    "review-prompt": "$hooks_dir/review-prompt.md",
    "review-schema": "$hooks_dir/review-schema.json"
  }
}
EOF
    echo -e "${GREEN}  ✓ Hook paths: $config_file${NC}"
}
write_hook_paths

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
