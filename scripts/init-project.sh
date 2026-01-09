#!/bin/bash
# Agentic Project Initialization
# Copies .project/ to target project, optionally vendors .claude/
#
# Usage:
#   ./init-project.sh [--no-track] [--include-claude] [--source <path>] [--dry-run]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
DRY_RUN=false
NO_TRACK=false
INCLUDE_CLAUDE=false
SOURCE_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --no-track) NO_TRACK=true; shift ;;
        --include-claude) INCLUDE_CLAUDE=true; shift ;;
        --source) SOURCE_DIR="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --dry-run        Show what would be done without making changes"
            echo "  --no-track       Add .project to .gitignore (don't track in git)"
            echo "  --include-claude Copy claude-pack/ to .claude/ (vendor commands)"
            echo "  --source <path>  Override source location"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Note: --no-track and --include-claude cannot be used together."
            exit 0
            ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# Mutual exclusion check
if [ "$NO_TRACK" = true ] && [ "$INCLUDE_CLAUDE" = true ]; then
    echo -e "${RED}Error: --no-track and --include-claude cannot be used together.${NC}"
    echo ""
    echo "Rationale: When vendoring commands with --include-claude, the .claude/"
    echo "directory should be tracked in git so the project is self-contained."
    echo ""
    echo "Choose one:"
    echo "  --no-track      : Use global ~/.claude/ commands, don't track .project/"
    echo "  --include-claude: Vendor commands into project, track everything"
    exit 1
fi

# Determine source directory
if [ -z "$SOURCE_DIR" ]; then
    # Try reading from global setup metadata
    if [ -f "$HOME/.claude/.agentic-pack-source" ]; then
        SOURCE_DIR=$(cat "$HOME/.claude/.agentic-pack-source")
    else
        # Try script directory
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -d "$SCRIPT_DIR/../project-pack" ]; then
            SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
        fi
    fi
fi

if [ -z "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR/project-pack" ]; then
    echo -e "${RED}Error: Cannot determine source location.${NC}"
    echo ""
    echo "Options:"
    echo "  1. Run setup-global.sh first (stores source location)"
    echo "  2. Use --source <path> to specify the agentic-project-init location"
    exit 1
fi

PROJECT_PACK="$SOURCE_DIR/project-pack"
CLAUDE_PACK="$SOURCE_DIR/claude-pack"

echo -e "${GREEN}Agentic Project Initialization${NC}"
echo "==============================="
[ "$DRY_RUN" = true ] && echo -e "${YELLOW}[DRY RUN MODE]${NC}"
echo ""

# Function to add to gitignore
add_to_gitignore() {
    local pattern="$1"
    local gitignore=".gitignore"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would add '$pattern' to .gitignore${NC}"
        return
    fi

    touch "$gitignore"
    if ! grep -qxF "$pattern" "$gitignore"; then
        echo "$pattern" >> "$gitignore"
        echo -e "${GREEN}  ✓ Added '$pattern' to .gitignore${NC}"
    else
        echo -e "${YELLOW}  ⚠ '$pattern' already in .gitignore${NC}"
    fi
}

# Copy .project/ with merge strategy
echo "Setting up .project/..."

copy_project_pack() {
    if [ -d ".project" ]; then
        echo -e "${YELLOW}  .project/ exists, merging missing components...${NC}"

        # Copy missing top-level items
        for item in "$PROJECT_PACK"/*; do
            basename=$(basename "$item")
            target=".project/$basename"

            if [ ! -e "$target" ]; then
                if [ "$DRY_RUN" = true ]; then
                    echo -e "${BLUE}[DRY RUN] Would copy: $basename${NC}"
                else
                    if [ -d "$item" ]; then
                        cp -r "$item" "$target"
                    else
                        cp "$item" "$target"
                    fi
                    echo -e "${GREEN}  ✓ Added: $basename${NC}"
                fi
            fi
        done

        # Ensure required subdirectories exist
        for dir in research reports memories active completed backlog; do
            if [ ! -d ".project/$dir" ]; then
                if [ "$DRY_RUN" = true ]; then
                    echo -e "${BLUE}[DRY RUN] Would create: .project/$dir/${NC}"
                else
                    mkdir -p ".project/$dir"
                    echo -e "${GREEN}  ✓ Created: $dir/${NC}"
                fi
            fi
        done
    else
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN] Would copy project-pack/ to .project/${NC}"
        else
            cp -r "$PROJECT_PACK" .project
            mkdir -p .project/research .project/reports .project/memories
            echo -e "${GREEN}  ✓ Created .project/${NC}"
        fi
    fi
}
copy_project_pack

# Handle --no-track
if [ "$NO_TRACK" = true ]; then
    echo ""
    echo "Configuring no-track mode..."
    add_to_gitignore ".project"
fi

# Handle --include-claude
if [ "$INCLUDE_CLAUDE" = true ]; then
    echo ""
    echo "Vendoring claude-pack to .claude/..."

    copy_claude_pack() {
        # Create directory structure
        for subdir in commands agents hooks skills rules; do
            if [ "$DRY_RUN" = true ]; then
                echo -e "${BLUE}[DRY RUN] Would create: .claude/$subdir/${NC}"
            else
                mkdir -p ".claude/$subdir"
            fi
        done

        # Copy files (skip existing)
        for subdir in commands agents hooks skills rules; do
            src_dir="$CLAUDE_PACK/$subdir"
            [ -d "$src_dir" ] || continue

            for file in "$src_dir"/*; do
                [ -e "$file" ] || continue
                filename=$(basename "$file")
                target=".claude/$subdir/$filename"

                if [ -e "$target" ]; then
                    if [ "$DRY_RUN" = true ]; then
                        echo -e "${YELLOW}[DRY RUN] Would skip (exists): $subdir/$filename${NC}"
                    else
                        echo -e "${YELLOW}  ⚠ Exists: $subdir/$filename${NC}"
                    fi
                else
                    if [ "$DRY_RUN" = true ]; then
                        echo -e "${GREEN}[DRY RUN] Would copy: $subdir/$filename${NC}"
                    else
                        cp "$file" "$target"
                        echo -e "${GREEN}  ✓ $subdir/$filename${NC}"
                    fi
                fi
            done
        done

        # Configure local settings.json
        local settings_file=".claude/settings.json"
        local hook_config='{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/precompact-capture.sh"
          }
        ]
      }
    ]
  }
}'

        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN] Would configure .claude/settings.json${NC}"
        else
            if [ -f "$settings_file" ]; then
                if command -v jq &> /dev/null; then
                    cp "$settings_file" "$settings_file.bak"
                    jq -s '.[0] * .[1]' "$settings_file" <(echo "$hook_config") > "$settings_file.tmp"
                    mv "$settings_file.tmp" "$settings_file"
                    echo -e "${GREEN}  ✓ Merged hooks into settings.json${NC}"
                else
                    echo -e "${YELLOW}  ⚠ jq not found - please manually configure hooks${NC}"
                fi
            else
                echo "$hook_config" > "$settings_file"
                echo -e "${GREEN}  ✓ Created settings.json${NC}"
            fi
        fi

        # Write marker file for uninstall detection
        if [ "$DRY_RUN" != true ]; then
            echo "vendored" > ".claude/.agentic-pack-vendored"
        fi
    }
    copy_claude_pack
fi

# Success message
echo ""
echo -e "${GREEN}✓ Project initialization complete!${NC}"
echo ""
echo "Next steps:"
if [ "$INCLUDE_CLAUDE" = true ]; then
    echo "1. Commit changes: git add .claude .project && git commit -m 'Add agentic templates'"
    echo "2. Restart Claude Code to pick up commands"
    echo "3. Commands available as /_my_<command>"
else
    echo "1. Commit changes: git add .project && git commit -m 'Add project management'"
    echo "2. Commands are available globally as /_my_<command>"
fi

# Check for CLAUDE.md
if [ ! -f "CLAUDE.md" ]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Tip: No CLAUDE.md found.${NC}"
    echo "For best results, create a CLAUDE.md describing your project."
    echo -e "Run ${GREEN}/init${NC} in Claude Code to generate one interactively."
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi
