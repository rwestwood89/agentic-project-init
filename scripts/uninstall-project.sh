#!/bin/bash
# Agentic Project Uninstall
# Removes .project/ and optionally vendored .claude/ from a project
#
# Usage:
#   ./uninstall-project.sh [--force]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--force]"
            echo ""
            echo "Options:"
            echo "  --force    Skip confirmation prompts"
            echo "  -h, --help Show this help message"
            exit 0
            ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${GREEN}Agentic Project Uninstall${NC}"
echo "========================="
echo ""

# Check for .project/
if [ ! -d ".project" ]; then
    echo -e "${YELLOW}No .project/ directory found in current directory.${NC}"
    exit 0
fi

# Check for vendored .claude/
HAS_VENDORED=false
if [ -f ".claude/.agentic-pack-vendored" ]; then
    HAS_VENDORED=true
fi

# Confirmation
if [ "$FORCE" != true ]; then
    echo "This will remove:"
    echo "  - .project/ directory and all contents"
    if [ "$HAS_VENDORED" = true ]; then
        echo "  - Vendored agentic-pack content from .claude/"
    fi
    echo ""
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Remove .project/
echo "Removing .project/..."
rm -rf .project
echo -e "${GREEN}  ✓ Removed .project/${NC}"

# Remove from .gitignore
if [ -f ".gitignore" ]; then
    if grep -qxF ".project" .gitignore; then
        # Create temp file without .project line
        grep -vxF ".project" .gitignore > .gitignore.tmp || true
        mv .gitignore.tmp .gitignore
        echo -e "${GREEN}  ✓ Removed .project from .gitignore${NC}"
    fi
fi

# Handle vendored .claude/
if [ "$HAS_VENDORED" = true ]; then
    echo ""
    echo "Removing vendored .claude/ content..."

    # Remove known vendored files (preserve user files)

    # Remove _my_* commands
    if [ -d ".claude/commands" ]; then
        for f in .claude/commands/_my_*.md; do
            [ -f "$f" ] && rm "$f" && echo -e "${GREEN}  ✓ Removed: commands/$(basename "$f")${NC}"
        done
    fi

    # Remove known agent files
    if [ -d ".claude/agents" ]; then
        for f in recall.md example-agent.md; do
            [ -f ".claude/agents/$f" ] && rm ".claude/agents/$f" && echo -e "${GREEN}  ✓ Removed: agents/$f${NC}"
        done
    fi

    # Remove known hook files
    if [ -d ".claude/hooks" ]; then
        for f in precompact-capture.sh capture.sh parse-transcript.py query-transcript.py; do
            [ -f ".claude/hooks/$f" ] && rm ".claude/hooks/$f" && echo -e "${GREEN}  ✓ Removed: hooks/$f${NC}"
        done
    fi

    # Remove known skill files
    if [ -d ".claude/skills" ]; then
        for f in example-skill.md; do
            [ -f ".claude/skills/$f" ] && rm ".claude/skills/$f" && echo -e "${GREEN}  ✓ Removed: skills/$f${NC}"
        done
    fi

    # Remove known rule files
    if [ -d ".claude/rules" ]; then
        for f in example-rules.md; do
            [ -f ".claude/rules/$f" ] && rm ".claude/rules/$f" && echo -e "${GREEN}  ✓ Removed: rules/$f${NC}"
        done
    fi

    # Remove marker file
    rm -f .claude/.agentic-pack-vendored
    echo -e "${GREEN}  ✓ Removed vendor marker${NC}"

    # Remove settings.json backup if it exists
    rm -f .claude/settings.json.bak

    # Note about preserved files
    echo ""
    echo -e "${YELLOW}Note: User-created files in .claude/ were preserved.${NC}"
fi

echo ""
echo -e "${GREEN}✓ Uninstall complete!${NC}"
