# Design: Simplified Setup System

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-01-09 10:19:47 PST
**Branch:** main

---

## Overview

Design a two-tier setup system that enables "clone once, use everywhere" by using file-level symlinks to `~/.claude/` for global configuration and per-project copying for `.project/` state, with `_my_` prefix on commands to avoid naming conflicts.

## Related Artifacts

- **Spec:** `.project/active/simplified-setup-system/spec.md`
- **Research:** `.project/research/20260109-095026_simplified-symlink-setup.md`
- **Research:** `.project/research/20260109-100205_user-level-claude-symlink-alternative.md`
- **Current Script:** `scripts/init-project.sh` (to be replaced)

---

## Research Findings

### Existing Script Patterns

**Current `scripts/init-project.sh` (lines 1-137)**
- Uses colored output with ANSI codes (RED, GREEN, YELLOW, BLUE, NC)
- Uses `set -e` for error handling
- Has `create_symlink()` helper function with safety checks for existing files/symlinks
- Implements merge strategy for existing `.project/` directories
- Provides clear success/skip/warning messages
- Outputs next steps after completion

**Key patterns to reuse:**
- Color definitions: `scripts/init-project.sh:5-9`
- Symlink safety check pattern: `scripts/init-project.sh:42-56`
- Merge strategy for directories: `scripts/init-project.sh:69-103`

### Hook Configuration

**Current `.claude/settings.json` structure:**
```json
{
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
}
```

**Hook path behavior:**
- `precompact-capture.sh` (line 5) uses `$(dirname "$0")` to find sibling scripts
- `capture.sh` (lines 12, 52) uses relative `.project/memories` path - resolves to CWD
- Hooks work correctly when called from any project directory

### Command Cross-References

**Files requiring cross-reference updates:**

| File | Cross-Reference Types |
|------|----------------------|
| `claude-pack/commands/spec.md` | `/design`, `/research`, "Related Commands" |
| `claude-pack/commands/design.md` | `/spec`, `/implement`, `/plan`, `/research`, "Related Commands" |
| `claude-pack/commands/plan.md` | `/design`, `/implement`, "Related Commands" |
| `claude-pack/commands/implement.md` | `/design`, `/plan`, `/project-manage`, "Related Commands" |
| `claude-pack/commands/research.md` | `/spec`, `/design`, "Related Commands" |
| `claude-pack/commands/code-review.md` | `/implement`, `/code-quality`, `/project-manage`, "Related Commands" |
| `claude-pack/commands/code-quality.md` | `/implement`, `/design`, `/plan`, "Related Commands" |
| `claude-pack/commands/quick-edit.md` | `/spec`, `/design`, `/implement`, `/code-review`, "Related Commands" |
| `claude-pack/commands/project-manage.md` | `/spec`, `/project-find`, self-references |
| `claude-pack/commands/project-find.md` | `/project-manage`, self-references |
| `claude-pack/commands/git-manage.md` | `/project-manage`, self-references |
| `claude-pack/commands/capture.md` | `/memorize` |
| `claude-pack/commands/memorize.md` | self-references |
| `claude-pack/commands/recall.md` | self-references |
| `claude-pack/commands/review-compact.md` | self-references |
| `claude-pack/hooks/capture.sh` | `/memorize` reference in output |
| `claude-pack/hooks/query-transcript.py` | `/memorize` reference in error message |
| `claude-pack/claude-md-checklist.md` | `/implement`, `/code-quality`, `/design`, `/research` |
| `claude-pack/agents/recall.md` | Internal references |

### File Structure Analysis

**`claude-pack/` contents:**
- `commands/` - 16 markdown files (all need `_my_` prefix)
- `agents/` - 2 markdown files (`recall.md`, `example-agent.md`) - NO prefix
- `hooks/` - 4 files (2 shell, 2 python) - NO prefix needed
- `skills/` - 1 markdown file (`example-skill.md`) - consider prefix
- `rules/` - 1 markdown file (`example-rules.md`) - consider prefix
- `claude-md-checklist.md` - documentation file

**`project-pack/` contents:**
- Top-level files: `README.md`, `CURRENT_WORK.md`, `EPIC_GUIDE.md`, `epic_template.md`
- Directories: `backlog/`, `active/`, `completed/`, `memories/`, `research/`, `reports/`

---

## Proposed Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    One-Time Global Setup                         │
│                   (setup-global.sh)                              │
├─────────────────────────────────────────────────────────────────┤
│  Source: ~/path/to/agentic-project-init/claude-pack/            │
│                           │                                      │
│                           ▼                                      │
│  Target: ~/.claude/                                              │
│  ├── commands/                                                   │
│  │   ├── _my_research.md → symlink                              │
│  │   ├── _my_spec.md → symlink                                  │
│  │   └── ... (16 commands)                                       │
│  ├── agents/                                                     │
│  │   ├── recall.md → symlink                                    │
│  │   └── example-agent.md → symlink                             │
│  ├── hooks/                                                      │
│  │   ├── precompact-capture.sh → symlink                        │
│  │   ├── capture.sh → symlink                                   │
│  │   └── ... (4 files)                                          │
│  ├── skills/                                                     │
│  │   └── example-skill.md → symlink                             │
│  ├── rules/                                                      │
│  │   └── example-rules.md → symlink                             │
│  ├── settings.json (hooks configuration merged)                  │
│  ├── .agentic-pack-source (source repo path)                    │
│  └── .agentic-pack-version (version tracking)                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Per-Project Setup                             │
│                   (init-project.sh)                              │
├─────────────────────────────────────────────────────────────────┤
│  Default Mode:                                                   │
│  Source: project-pack/ → Copy to → .project/                    │
│                                                                  │
│  --no-track Mode:                                                │
│  Same + add ".project" to .gitignore                            │
│                                                                  │
│  --include-claude Mode:                                          │
│  Same + COPY claude-pack/ → .claude/                            │
│  + configure .claude/settings.json                              │
└─────────────────────────────────────────────────────────────────┘
```

### Component 1: Command Renaming

**Location:** `claude-pack/commands/`

**Rename Script:** One-time manual or scripted rename

```bash
# Rename mapping (hyphens → underscores, add _my_ prefix)
research.md         → _my_research.md
spec.md             → _my_spec.md
design.md           → _my_design.md
plan.md             → _my_plan.md
implement.md        → _my_implement.md
code-review.md      → _my_code_review.md
code-quality.md     → _my_code_quality.md
git-manage.md       → _my_git_manage.md
project-manage.md   → _my_project_manage.md
project-find.md     → _my_project_find.md
quick-edit.md       → _my_quick_edit.md
capture.md          → _my_capture.md
recall.md           → _my_recall.md
memorize.md         → _my_memorize.md
review-compact.md   → _my_review_compact.md
example-command.md  → _my_example_command.md
```

**Cross-Reference Update Pattern:**

Search and replace in all files:
```
/research       → /_my_research
/spec           → /_my_spec
/design         → /_my_design
/plan           → /_my_plan
/implement      → /_my_implement
/code-review    → /_my_code_review
/code-quality   → /_my_code_quality
/git-manage     → /_my_git_manage
/project-manage → /_my_project_manage
/project-find   → /_my_project_find
/quick-edit     → /_my_quick_edit
/capture        → /_my_capture
/recall         → /_my_recall
/memorize       → /_my_memorize
/review-compact → /_my_review_compact
```

**Files to update:**
1. All 16 command files in `claude-pack/commands/`
2. `claude-pack/hooks/capture.sh` (line 74: `/memorize` reference)
3. `claude-pack/hooks/query-transcript.py` (line 312: `/memorize` reference)
4. `claude-pack/claude-md-checklist.md` (multiple references)
5. `claude-pack/agents/recall.md` (internal references)
6. `README.md` (workflow documentation)

### Component 2: Global Setup Script (`setup-global.sh`)

**Location:** `scripts/setup-global.sh`

**Purpose:** One-time installation of symlinks to `~/.claude/`

**Interface:**
```bash
./scripts/setup-global.sh [--dry-run]
```

**Data Flow:**
1. Determine source directory (script location)
2. Create `~/.claude/` directory structure
3. For each file in `claude-pack/{commands,agents,hooks,skills,rules}/`:
   - Check if target exists
   - If not, create symlink with absolute path
4. Merge hook configuration into `~/.claude/settings.json`
5. Write source path to `~/.claude/.agentic-pack-source`
6. Write version to `~/.claude/.agentic-pack-version`

**Implementation Details:**

```bash
#!/bin/bash
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
        [ ! -d "$dir" ] && echo -e "${BLUE}[DRY RUN] Would create: $dir${NC}"
    else
        mkdir -p "$dir"
    fi
}

# Main execution
echo -e "${GREEN}Agentic Pack Global Setup${NC}"
echo "========================="
[ "$DRY_RUN" = true ] && echo -e "${YELLOW}[DRY RUN MODE]${NC}"
echo ""

# Create directories
for subdir in commands agents hooks skills rules; do
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
for file in "$CLAUDE_PACK"/hooks/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    create_symlink "$file" "$TARGET_DIR/hooks/$filename" "$filename"
done

# Symlink skills
echo ""
echo "Setting up skills..."
for file in "$CLAUDE_PACK"/skills/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    create_symlink "$file" "$TARGET_DIR/skills/$filename" "$filename"
done

# Symlink rules
echo ""
echo "Setting up rules..."
for file in "$CLAUDE_PACK"/rules/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    create_symlink "$file" "$TARGET_DIR/rules/$filename" "$filename"
done

# Configure settings.json (hook configuration)
echo ""
echo "Configuring hooks..."
configure_hooks() {
    local settings_file="$TARGET_DIR/settings.json"
    local hook_path="$TARGET_DIR/hooks/precompact-capture.sh"

    # New hook configuration
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
echo "To update later, run: cd $SOURCE_DIR && git pull"
```

### Component 3: Per-Project Setup Script (`init-project.sh`)

**Location:** `scripts/init-project.sh`

**Purpose:** Initialize `.project/` in target projects, optionally vendor `.claude/`

**Interface:**
```bash
./scripts/init-project.sh [--no-track] [--include-claude] [--source <path>] [--dry-run]
```

**Flag Behavior:**
- Default: Copy `.project/` only
- `--no-track`: Add `.project` to `.gitignore`
- `--include-claude`: Copy `claude-pack/` to `.claude/`, configure local hooks
- `--source <path>`: Override source location
- `--dry-run`: Show what would happen without executing

**Mutual Exclusion:**
- `--no-track` + `--include-claude` → ERROR with explanation

**Implementation Details:**

```bash
#!/bin/bash
set -e

# Colors (same as setup-global.sh)
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
            mkdir -p .project/research .project/reports
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
```

### Component 4: Global Uninstall Script (`uninstall-global.sh`)

**Location:** `scripts/uninstall-global.sh`

**Purpose:** Remove symlinks and configuration from `~/.claude/`

**Implementation Details:**

```bash
#!/bin/bash
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
        [ -L "$file" ] || continue

        # Check if symlink points to our source
        target=$(readlink "$file")
        if [[ "$target" == "$SOURCE_DIR"* ]]; then
            rm "$file"
            echo -e "${GREEN}  ✓ Removed: $subdir/$(basename "$file")${NC}"
            ((REMOVED++))
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
    # Remove PreCompact hooks that reference our hooks
    if jq -e '.hooks.PreCompact' "$settings_file" > /dev/null 2>&1; then
        # Create backup
        cp "$settings_file" "$settings_file.bak"
        # Remove our hook entries (those pointing to ~/.claude/hooks/)
        jq 'del(.hooks.PreCompact[] | select(.hooks[].command | contains("/.claude/hooks/")))' "$settings_file" > "$settings_file.tmp"
        mv "$settings_file.tmp" "$settings_file"
        echo -e "${GREEN}  ✓ Cleaned hook configuration${NC}"
    fi
fi

# Remove metadata files
echo ""
echo "Removing metadata..."
for file in .agentic-pack-source .agentic-pack-version; do
    if [ -f "$TARGET_DIR/$file" ]; then
        rm "$TARGET_DIR/$file"
        echo -e "${GREEN}  ✓ Removed: $file${NC}"
        ((REMOVED++))
    fi
done

echo ""
echo -e "${GREEN}✓ Uninstall complete!${NC}"
echo "Removed $REMOVED items."
echo ""
echo "Note: Empty directories in ~/.claude/ were preserved."
echo "Commands will no longer be available after restarting Claude Code."
```

### Component 5: Per-Project Uninstall Script (`uninstall-project.sh`)

**Location:** `scripts/uninstall-project.sh`

**Purpose:** Remove `.project/` and optionally vendored `.claude/` from a project

**Implementation Details:**

```bash
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
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

# Confirmation
if [ "$FORCE" != true ]; then
    echo "This will remove:"
    echo "  - .project/ directory and all contents"
    if [ -f ".claude/.agentic-pack-vendored" ]; then
        echo "  - .claude/ vendored content"
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
        grep -vxF ".project" .gitignore > .gitignore.tmp
        mv .gitignore.tmp .gitignore
        echo -e "${GREEN}  ✓ Removed .project from .gitignore${NC}"
    fi
fi

# Handle vendored .claude/
if [ -f ".claude/.agentic-pack-vendored" ]; then
    echo ""
    if [ "$FORCE" != true ]; then
        read -p "Also remove vendored .claude/ content? (y/N) " -n 1 -r
        echo
    else
        REPLY="y"
    fi

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing vendored .claude/ content..."

        # Remove only files that match our pattern
        for subdir in commands agents hooks skills rules; do
            if [ -d ".claude/$subdir" ]; then
                # Remove _my_* files from commands
                if [ "$subdir" = "commands" ]; then
                    rm -f .claude/$subdir/_my_*.md
                fi
                # Remove known agent files
                if [ "$subdir" = "agents" ]; then
                    rm -f .claude/$subdir/recall.md .claude/$subdir/example-agent.md
                fi
                # Remove known hook files
                if [ "$subdir" = "hooks" ]; then
                    rm -f .claude/$subdir/precompact-capture.sh .claude/$subdir/capture.sh
                    rm -f .claude/$subdir/parse-transcript.py .claude/$subdir/query-transcript.py
                fi
                # Remove known skill/rule files
                if [ "$subdir" = "skills" ]; then
                    rm -f .claude/$subdir/example-skill.md
                fi
                if [ "$subdir" = "rules" ]; then
                    rm -f .claude/$subdir/example-rules.md
                fi
            fi
        done

        # Remove marker and settings if we created them
        rm -f .claude/.agentic-pack-vendored

        echo -e "${GREEN}  ✓ Removed vendored content${NC}"
        echo -e "${YELLOW}  Note: Preserved any user-created files in .claude/${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ Uninstall complete!${NC}"
```

---

## Potential Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Broken symlinks if source moved | Medium | High | Store source path, detect broken symlinks in scripts |
| jq not available for JSON merge | Medium | Low | Graceful fallback with warning |
| User has existing conflicting files | Medium | Low | Skip with warning, don't overwrite |
| Cross-reference regex misses edge cases | Low | Medium | Manual review after automated update |
| macOS vs Linux path differences | Low | Low | Use portable shell constructs |

---

## Integration Strategy

### Migration from Submodule Approach

Users with existing submodule setup should:

1. Remove submodule from projects:
   ```bash
   git submodule deinit claude-templates
   git rm claude-templates
   rm -rf .git/modules/claude-templates
   ```

2. Remove old symlinks:
   ```bash
   rm .claude/commands .claude/hooks .claude/agents .claude/skills .claude/rules
   ```

3. Run new global setup:
   ```bash
   ~/path/to/agentic-project-init/scripts/setup-global.sh
   ```

### Command Invocation Change

Document in README.md that commands now use `/_my_` prefix:

| Old | New |
|-----|-----|
| `/research` | `/_my_research` |
| `/spec` | `/_my_spec` |
| `/design` | `/_my_design` |
| etc. | etc. |

---

## Validation Approach

### Manual Testing

1. **Global Setup**
   - [ ] Run `setup-global.sh` on clean system
   - [ ] Verify symlinks created in `~/.claude/`
   - [ ] Verify `settings.json` has hook configuration
   - [ ] Verify metadata files created
   - [ ] Run `setup-global.sh` again (idempotent test)
   - [ ] Test `--dry-run` mode

2. **Project Init**
   - [ ] Run `init-project.sh` in fresh project
   - [ ] Verify `.project/` created with all subdirectories
   - [ ] Run again (merge strategy test)
   - [ ] Test `--no-track` adds to .gitignore
   - [ ] Test `--include-claude` copies files
   - [ ] Test mutual exclusion error
   - [ ] Test `--dry-run` mode

3. **Uninstall**
   - [ ] Run `uninstall-global.sh`
   - [ ] Verify symlinks removed, user files preserved
   - [ ] Run `uninstall-project.sh`
   - [ ] Verify `.project/` removed, `.claude/` optionally cleaned

4. **Integration**
   - [ ] Start Claude Code, verify commands appear with (user) suffix
   - [ ] Invoke `/_my_research`, verify it works
   - [ ] Test hooks execute correctly

### Cross-Reference Verification

After renaming commands:
```bash
# Search for old-style references (should find none)
grep -r "/research\|/spec\|/design" claude-pack/ --include="*.md" | grep -v "_my_"
```

---

**Next Steps:** After approval, proceed to `/_my_plan` or `/_my_implement`
