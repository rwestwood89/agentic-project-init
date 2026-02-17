#!/bin/bash
# File-Native Comment System Setup
# Installs the comment CLI, MCP server, and optionally the VSCode extension.
#
# Usage:
#   ./setup-comments.sh [--dry-run] [--vscode] [--reinstall]

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
COMMENT_SYSTEM="$SOURCE_DIR/comment-system"

# Parse arguments
DRY_RUN=false
INSTALL_VSCODE=false
REINSTALL=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --vscode) INSTALL_VSCODE=true; shift ;;
        --reinstall) REINSTALL=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--vscode] [--reinstall]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be done without making changes"
            echo "  --vscode     Install the VSCode extension"
            echo "  --reinstall  Force reinstall (update to latest version)"
            echo "  -h, --help   Show this help message"
            exit 0
            ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# Main execution
echo -e "${GREEN}File-Native Comment System Setup${NC}"
echo "================================="
[ "$DRY_RUN" = true ] && echo -e "${YELLOW}[DRY RUN MODE]${NC}"
echo ""

# Verify comment-system directory exists
if [ ! -d "$COMMENT_SYSTEM" ]; then
    echo -e "${RED}Error: comment-system not found at $COMMENT_SYSTEM${NC}"
    exit 1
fi

if [ ! -f "$COMMENT_SYSTEM/pyproject.toml" ]; then
    echo -e "${RED}Error: pyproject.toml not found in $COMMENT_SYSTEM${NC}"
    exit 1
fi

# Step 1: Check uv is available
echo "Checking prerequisites..."
if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: uv is not installed.${NC}"
    echo "Install uv: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi
echo -e "${GREEN}  ✓ uv found${NC}"

# Step 2: Install via uv tool install
echo ""
echo "Installing comment system..."
if [ "$DRY_RUN" = true ]; then
    if [ "$REINSTALL" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would run: uv tool install --force $COMMENT_SYSTEM${NC}"
    else
        echo -e "${BLUE}[DRY RUN] Would run: uv tool install $COMMENT_SYSTEM${NC}"
    fi
else
    UV_ARGS=("tool" "install")
    if [ "$REINSTALL" = true ]; then
        UV_ARGS+=("--force")
    fi
    UV_ARGS+=("$COMMENT_SYSTEM")

    if uv "${UV_ARGS[@]}"; then
        echo -e "${GREEN}  ✓ Comment system installed${NC}"
    else
        echo -e "${YELLOW}  ⚠ Install returned non-zero. Trying with --force...${NC}"
        if uv tool install --force "$COMMENT_SYSTEM"; then
            echo -e "${GREEN}  ✓ Comment system installed (forced)${NC}"
        else
            echo -e "${RED}  ✗ Failed to install comment system${NC}"
            exit 1
        fi
    fi
fi

# Step 3: Verify CLI works
echo ""
echo "Verifying installation..."
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY RUN] Would verify: comment --help${NC}"
else
    if command -v comment &> /dev/null; then
        echo -e "${GREEN}  ✓ 'comment' command available${NC}"
    else
        echo -e "${YELLOW}  ⚠ 'comment' not found in PATH${NC}"
        echo "    You may need to add ~/.local/bin to your PATH"
        echo "    Run: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    if command -v comment-mcp &> /dev/null; then
        echo -e "${GREEN}  ✓ 'comment-mcp' command available${NC}"
    else
        echo -e "${YELLOW}  ⚠ 'comment-mcp' not found in PATH${NC}"
    fi
fi

# Step 4: Configure MCP server in ~/.claude/settings.json
echo ""
echo "Configuring MCP server..."
configure_mcp() {
    local settings_file="$HOME/.claude/settings.json"

    # MCP server configuration
    local mcp_config='{
  "mcpServers": {
    "comments": {
      "command": "comment-mcp"
    }
  }
}'

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would add MCP server 'comments' to $settings_file${NC}"
        return
    fi

    # Ensure ~/.claude/ exists
    mkdir -p "$HOME/.claude"

    if [ -f "$settings_file" ]; then
        if command -v jq &> /dev/null; then
            # Check if already configured
            if jq -e '.mcpServers.comments' "$settings_file" > /dev/null 2>&1; then
                echo -e "${YELLOW}  ⚠ MCP server 'comments' already configured${NC}"
                return
            fi
            # Backup and merge
            cp "$settings_file" "$settings_file.bak"
            jq -s '.[0] * .[1]' "$settings_file" <(echo "$mcp_config") > "$settings_file.tmp"
            mv "$settings_file.tmp" "$settings_file"
            echo -e "${GREEN}  ✓ Added MCP server 'comments' to settings.json${NC}"
        else
            echo -e "${YELLOW}  ⚠ jq not found - please manually add MCP configuration${NC}"
            echo "    Add to $settings_file:"
            echo '    "mcpServers": { "comments": { "command": "comment-mcp" } }'
        fi
    else
        echo "$mcp_config" > "$settings_file"
        echo -e "${GREEN}  ✓ Created settings.json with MCP server 'comments'${NC}"
    fi
}
configure_mcp

# Step 5: VSCode extension
echo ""
VSIX_FILE="$COMMENT_SYSTEM/vscode-extension/file-native-comments-0.1.0.vsix"

if [ "$INSTALL_VSCODE" = true ]; then
    echo "Installing VSCode extension..."
    if [ ! -f "$VSIX_FILE" ]; then
        echo -e "${RED}Error: VSCode extension not found at $VSIX_FILE${NC}"
        exit 1
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would run: code --install-extension $VSIX_FILE${NC}"
    else
        if command -v code &> /dev/null; then
            code --install-extension "$VSIX_FILE"
            echo -e "${GREEN}  ✓ VSCode extension installed${NC}"
        else
            echo -e "${YELLOW}  ⚠ 'code' command not found${NC}"
            echo "    Install manually: open VSCode → Extensions → Install from VSIX"
            echo "    File: $VSIX_FILE"
        fi
    fi
else
    echo "VSCode extension (optional):"
    echo "  To install the inline comment UI for VSCode, run:"
    echo "    code --install-extension $VSIX_FILE"
    echo "  Or re-run this script with --vscode"
fi

# Done
echo ""
echo -e "${GREEN}✓ Comment system setup complete!${NC}"
echo ""
echo "Quick start:"
echo "  comment add <file> -L <line> \"Your comment\"    Add a comment"
echo "  comment list [file]                             List comments"
echo "  comment show <id>                               Show thread"
echo "  comment reply <id> \"Reply text\"                 Reply to thread"
echo "  comment resolve <id>                            Resolve thread"
echo ""
echo "MCP tools are available to Claude Code agents automatically."
echo ""
echo "To update later:"
echo "  cd $SOURCE_DIR && git pull"
echo "  $SCRIPT_DIR/setup-comments.sh --reinstall"
