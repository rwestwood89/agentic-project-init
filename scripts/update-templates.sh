#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SUBMODULE_PATH="claude-templates"

echo -e "${BLUE}Claude Agentic Templates Update${NC}"
echo "================================"
echo ""

# Check if submodule exists
if [ ! -d "$SUBMODULE_PATH" ]; then
    echo -e "${RED}Error: Submodule not found at $SUBMODULE_PATH${NC}"
    echo "Have you run init-project.sh yet?"
    exit 1
fi

# Check for uncommitted changes in submodule
cd "$SUBMODULE_PATH"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes in $SUBMODULE_PATH${NC}"
    echo -e "${YELLOW}These changes may be lost when updating.${NC}"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 1
    fi
fi

# Show current version
echo "Current version:"
git log -1 --oneline
echo ""

# Fetch and update
echo "Fetching latest changes..."
git fetch origin

# Show what will be updated
echo ""
echo "Changes to be pulled:"
git log HEAD..origin/main --oneline --decorate

echo ""
read -p "Pull these changes? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 1
fi

# Pull changes
git pull origin main

cd ..

echo ""
echo -e "${GREEN}✓ Templates updated successfully!${NC}"
echo ""
echo "Updated version:"
cd "$SUBMODULE_PATH"
git log -1 --oneline
cd ..

echo ""
echo -e "${YELLOW}Important:${NC}"
echo "1. Review the changes in $SUBMODULE_PATH/"
echo "2. Restart Claude Code to pick up updated commands, skills, and agents"
echo "3. Commit the submodule update: git add $SUBMODULE_PATH && git commit -m 'Update Claude templates'"
echo ""
