#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-git@github.com:yourusername/claude-agentic-templates.git}"
SUBMODULE_PATH="claude-templates"

echo -e "${GREEN}Claude Agentic Project Initialization${NC}"
echo "========================================"
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo -e "${RED}Error: Not in a git repository. Please run 'git init' first.${NC}"
    exit 1
fi

# Check if submodule already exists
if [ -d "$SUBMODULE_PATH" ]; then
    echo -e "${YELLOW}Note: $SUBMODULE_PATH already exists. Skipping submodule creation.${NC}"
else
    echo "Adding template repository as git submodule..."
    git submodule add "$TEMPLATE_REPO_URL" "$SUBMODULE_PATH"
    git submodule update --init --recursive
    echo -e "${GREEN}✓ Submodule added${NC}"
fi

echo ""
echo "Creating symlinks for .claude/..."

# Create .claude directory if it doesn't exist
mkdir -p .claude

# Function to create symlink with safety checks
create_symlink() {
    local source=$1
    local target=$2
    local name=$3

    if [ -L "$target" ]; then
        echo -e "${YELLOW}  ⚠ Symlink already exists: $target${NC}"
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}  ⚠ Path already exists (not a symlink): $target${NC}"
        echo -e "    ${YELLOW}Please manually merge or remove it before running this script.${NC}"
    else
        ln -s "$source" "$target"
        echo -e "${GREEN}  ✓ $name${NC}"
    fi
}

# Create symlinks for .claude subdirectories
create_symlink "../$SUBMODULE_PATH/claude-pack/commands" ".claude/commands" "commands"
create_symlink "../$SUBMODULE_PATH/claude-pack/hooks" ".claude/hooks" "hooks"
create_symlink "../$SUBMODULE_PATH/claude-pack/agents" ".claude/agents" "agents"
create_symlink "../$SUBMODULE_PATH/claude-pack/skills" ".claude/skills" "skills"
create_symlink "../$SUBMODULE_PATH/claude-pack/rules" ".claude/rules" "rules"

echo ""
echo "Setting up .project/..."

# Handle .project/ directory with merge strategy
if [ -d ".project" ]; then
    echo -e "${YELLOW}  .project/ already exists. Checking for missing components...${NC}"

    TEMPLATE_PROJECT="$SUBMODULE_PATH/project-pack"
    MERGED=0

    # Merge strategy: copy missing directories and files
    for item in "$TEMPLATE_PROJECT"/*; do
        basename=$(basename "$item")
        target=".project/$basename"

        if [ ! -e "$target" ]; then
            if [ -d "$item" ]; then
                cp -r "$item" "$target"
                echo -e "${GREEN}  ✓ Added missing directory: $basename/${NC}"
            else
                cp "$item" "$target"
                echo -e "${GREEN}  ✓ Added missing file: $basename${NC}"
            fi
            MERGED=1
        fi
    done

    # Ensure required subdirectories exist
    for dir in research reports memories; do
        if [ ! -d ".project/$dir" ]; then
            mkdir -p ".project/$dir"
            echo -e "${GREEN}  ✓ Created missing directory: $dir/${NC}"
            MERGED=1
        fi
    done

    if [ $MERGED -eq 0 ]; then
        echo -e "${BLUE}  All components present, nothing to merge.${NC}"
    fi
else
    cp -r "$SUBMODULE_PATH/project-pack" .project
    mkdir -p .project/research
    mkdir -p .project/reports
    echo -e "${GREEN}  ✓ Created .project/${NC}"
fi

echo ""
echo -e "${GREEN}✓ Initialization complete!${NC}"
echo ""

# Check for CLAUDE.md and provide guidance
if [ ! -f "CLAUDE.md" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}No CLAUDE.md found.${NC}"
    echo ""
    echo "For best results with Claude Code, create a CLAUDE.md file that describes"
    echo "your project's architecture, commands, and conventions."
    echo ""
    echo -e "Start Claude Code and run ${GREEN}/init${NC} to generate one interactively."
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

echo "Next steps:"
echo "1. Commit the changes: git add . && git commit -m 'Add Claude agentic templates'"
echo "2. Restart Claude Code to pick up new commands, skills, and agents"
if [ ! -f "CLAUDE.md" ]; then
    echo -e "3. Run ${GREEN}/init${NC} in Claude Code to generate your CLAUDE.md"
fi
echo ""
echo "To sync template updates in the future, run:"
echo "  ./scripts/update-templates.sh"
echo ""
