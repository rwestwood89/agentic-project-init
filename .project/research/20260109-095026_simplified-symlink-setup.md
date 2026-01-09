---
date: 2026-01-09T09:50:26-08:00
researcher: Claude
topic: "Simplified Symlink-Based Setup Without Submodule Dependency"
tags: [research, architecture, installation, symlinks, gitignore]
status: complete
last_updated: 2026-01-09
---

# Research: Simplified Symlink-Based Setup

**Date**: 2026-01-09T09:50:26-08:00
**Researcher**: Claude
**Research Type**: Architecture / Feasibility

## Research Question

How can we simplify the setup to:
1. Avoid making this project a git dependency (no submodule)
2. Handle projects that already have `.claude/` directories checked in
3. Use symlinks back to a cloned source repo
4. Avoid command naming conflicts with existing project commands
5. Support a "don't track" mode that gitignores symlinked content

## Summary

- **Clone-and-symlink approach is fully feasible** - eliminates submodule dependency entirely
- **Command prefix strategy (`_my_*.md`)** provides reliable conflict avoidance
- **Selective symlinking** (individual files, not directories) solves the `.claude/` conflict problem
- **"Don't track" mode** adds symlinked files and `.project/` to `.gitignore`
- **The approach simplifies both initial setup and ongoing maintenance**

## Detailed Findings

### Current Architecture Problems

The current setup uses git submodules:

```
target-project/
├── claude-templates/           # Git submodule (problematic)
└── .claude/
    ├── commands/ -> symlink    # Entire directory symlinked
    ├── hooks/ -> symlink
    └── ...
```

**Problems Identified:**

1. **Submodule complexity**: Requires `git submodule update --init` in every project
2. **Directory-level symlinks**: Can't merge with existing `.claude/` content
3. **Command conflicts**: If project has `/commit`, our `/commit` would collide
4. **All-or-nothing**: Can't selectively use some commands

### Proposed New Architecture

```
~/.local/share/agentic-project-init/   # Or any user-chosen location
├── claude-pack/
│   ├── commands/
│   │   ├── _my_research.md
│   │   ├── _my_design.md
│   │   └── ...
│   ├── hooks/
│   ├── agents/
│   ├── skills/
│   └── rules/
├── project-pack/
└── scripts/
    └── setup-target.sh

target-project/                         # User's project
├── .claude/
│   ├── commands/
│   │   ├── existing-command.md        # Project's existing command
│   │   ├── _my_research.md -> symlink
│   │   └── _my_design.md -> symlink
│   ├── hooks/
│   │   └── precompact-capture.sh -> symlink
│   ├── settings.json                  # May exist, not touched
│   └── settings.local.json            # May exist, not touched
└── .project/                          # Always copied (each project needs its own state)
    └── ...
```

### Command Naming Strategy

**Research Findings on Command Naming:**

| Aspect | Finding |
|--------|---------|
| Underscore prefix | Not filtered - commands appear in list |
| Naming conflicts | Project commands override user-level commands |
| Hyphen bug | Known issue #15852 - underscores more reliable |
| Skills collision | Skills take priority over same-named commands |

**Recommended Prefix: `_my_`**

Rationale:
- Starts with underscore (common convention for "internal/imported")
- `my` is short, personal, and clearly indicates "my custom commands"
- Underscores work reliably (avoid hyphen bug)
- Distinct namespace avoids collision with any project command

**Example Command Names:**

| Current | New |
|---------|-----|
| `research.md` | `_my_research.md` |
| `design.md` | `_my_design.md` |
| `spec.md` | `_my_spec.md` |
| `plan.md` | `_my_plan.md` |
| `implement.md` | `_my_implement.md` |
| `code-review.md` | `_my_code_review.md` |
| `code-quality.md` | `_my_code_quality.md` |
| `git-manage.md` | `_my_git_manage.md` |
| `project-manage.md` | `_my_project_manage.md` |
| `project-find.md` | `_my_project_find.md` |
| `quick-edit.md` | `_my_quick_edit.md` |
| `capture.md` | `_my_capture.md` |
| `recall.md` | `_my_recall.md` |
| `memorize.md` | `_my_memorize.md` |
| `review-compact.md` | `_my_review_compact.md` |

**Invocation Changes:**
- `/research` becomes `/_my_research`
- Users can alias in their workflow if desired

### Symlink Strategy: File-Level vs Directory-Level

**Directory-level (current approach - problematic):**
```bash
ln -s ../source/claude-pack/commands .claude/commands
# Problem: Entire directory is replaced, can't merge
```

**File-level (proposed - solves merge problem):**
```bash
mkdir -p .claude/commands
for file in /path/to/source/claude-pack/commands/*.md; do
    ln -s "$file" ".claude/commands/$(basename $file)"
done
# Result: Individual symlinks, existing files preserved
```

**Advantages of file-level symlinking:**
1. Preserves existing project commands
2. Can selectively skip certain commands
3. Each symlink can be individually gitignored
4. Existing `.claude/settings.json` untouched

### "Don't Track" Mode Implementation

When `--no-track` flag is used, the setup script should:

1. **Add symlinked files to `.gitignore`**
2. **Add `.project/` to `.gitignore`** (if not tracking project state)

**Implementation:**

```bash
#!/bin/bash
# setup-target.sh

SOURCE_DIR="${SOURCE_DIR:-$HOME/.local/share/agentic-project-init}"
TRACK_MODE="${1:-track}"  # "track" or "no-track"

# Ensure .gitignore exists
touch .gitignore

# Function to add to gitignore if not present
add_to_gitignore() {
    local pattern="$1"
    if ! grep -qxF "$pattern" .gitignore; then
        echo "$pattern" >> .gitignore
    fi
}

# Create .claude directory structure
mkdir -p .claude/commands
mkdir -p .claude/hooks
mkdir -p .claude/agents
mkdir -p .claude/skills
mkdir -p .claude/rules

# Symlink commands (file-level)
for file in "$SOURCE_DIR"/claude-pack/commands/_my_*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    target=".claude/commands/$filename"

    if [ ! -e "$target" ]; then
        ln -s "$file" "$target"
        echo "  Linked: $filename"

        if [ "$TRACK_MODE" = "no-track" ]; then
            add_to_gitignore ".claude/commands/$filename"
        fi
    fi
done

# Symlink hooks
for file in "$SOURCE_DIR"/claude-pack/hooks/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    target=".claude/hooks/$filename"

    if [ ! -e "$target" ]; then
        ln -s "$file" "$target"
        echo "  Linked: $filename"

        if [ "$TRACK_MODE" = "no-track" ]; then
            add_to_gitignore ".claude/hooks/$filename"
        fi
    fi
done

# Similar for agents, skills, rules...

# Handle .project/ - always copy (each project needs its own state)
if [ ! -d ".project" ]; then
    cp -r "$SOURCE_DIR/project-pack" .project
fi

# In no-track mode, just gitignore it
if [ "$TRACK_MODE" = "no-track" ]; then
    add_to_gitignore ".project"
fi
```

### Gitignore Patterns for "Don't Track" Mode

When running with `--no-track`:

```gitignore
# Added by agentic-project-init (no-track mode)
.project

# Symlinked commands
.claude/commands/_my_research.md
.claude/commands/_my_design.md
.claude/commands/_my_spec.md
.claude/commands/_my_plan.md
.claude/commands/_my_implement.md
.claude/commands/_my_code_review.md
.claude/commands/_my_code_quality.md
.claude/commands/_my_git_manage.md
.claude/commands/_my_project_manage.md
.claude/commands/_my_project_find.md
.claude/commands/_my_quick_edit.md
.claude/commands/_my_capture.md
.claude/commands/_my_recall.md
.claude/commands/_my_memorize.md
.claude/commands/_my_review_compact.md

# Symlinked hooks
.claude/hooks/capture.sh
.claude/hooks/precompact-capture.sh
.claude/hooks/parse-transcript.py
.claude/hooks/query-transcript.py

# Symlinked agents
.claude/agents/_my_recall.md
.claude/agents/_my_example_agent.md

# Symlinked skills
.claude/skills/_my_example_skill.md

# Symlinked rules
.claude/rules/_my_example_rules.md
```

**Alternative: Use Pattern Instead of Individual Files**

```gitignore
# Simpler pattern-based approach
.project
.claude/commands/_my_*.md
.claude/hooks/capture*.sh
.claude/hooks/precompact*.sh
.claude/hooks/*.py
.claude/agents/_my_*.md
.claude/skills/_my_*/
.claude/rules/_my_*.md
```

### Path Handling in Hooks

Hooks that reference paths need to work regardless of where the source repo is cloned.

**Current issue in `settings.json`:**
```json
{
  "hooks": {
    "PreCompact": [{
      "command": ".claude/hooks/precompact-capture.sh"  // Relative path
    }]
  }
}
```

**With symlinks, this still works** because:
1. The symlink `.claude/hooks/precompact-capture.sh` exists in the project
2. Shell follows the symlink to the actual script
3. Scripts using `$(dirname "$0")` resolve correctly through symlinks

**However**, if `.claude/settings.json` is checked into the project already, we shouldn't touch it. The setup script should:
1. Check if `settings.json` exists
2. If not, create one with hook configuration
3. If yes, warn user to manually add hook config

### Complete Setup Workflow

**One-time user setup:**
```bash
# Clone the template repo anywhere (e.g., ~/.local/share/)
git clone git@github.com:user/agentic-project-init.git ~/.local/share/agentic-project-init

# Optionally add to PATH or create alias
alias claude-setup='~/.local/share/agentic-project-init/scripts/setup-target.sh'
```

**Per-project setup (tracking mode):**
```bash
cd /path/to/my-project
~/.local/share/agentic-project-init/scripts/setup-target.sh
# Creates symlinks, copies .project/, files are tracked in git
```

**Per-project setup (no-track mode):**
```bash
cd /path/to/my-project
~/.local/share/agentic-project-init/scripts/setup-target.sh --no-track
# Creates symlinks, adds to .gitignore, nothing committed
```

**Updating templates:**
```bash
cd ~/.local/share/agentic-project-init
git pull
# All projects automatically get updates via symlinks!
```

## Architecture Insights

### Why This Approach is Better

| Aspect | Submodule Approach | New Symlink Approach |
|--------|-------------------|---------------------|
| Dependency | Creates git dependency | No dependency |
| Updates | Per-project submodule update | Single `git pull` updates all |
| Conflicts | Directory replacement | File-level merge |
| Tracking | Always tracked | Optional tracking |
| Setup complexity | Moderate | Low |
| Removal | Complex submodule removal | Delete symlinks |

### Key Design Decisions

1. **`_my_` prefix** - Clear namespace, avoids conflicts, underscores reliable
2. **File-level symlinks** - Maximum flexibility, preserves existing content
3. **Absolute paths in symlinks** - Works regardless of current directory
4. **`.project/` handling** - Always copy (each project needs its own state), gitignore in no-track mode
5. **`.gitignore` management** - Dynamic updates only in no-track mode

## Feasibility Assessment

**Overall: HIGHLY FEASIBLE**

| Component | Feasibility | Notes |
|-----------|-------------|-------|
| Clone-anywhere approach | HIGH | Standard git workflow |
| File-level symlinks | HIGH | Well-supported on all platforms |
| Command prefix rename | HIGH | Requires renaming files |
| No-track mode | HIGH | Standard .gitignore usage |
| Existing .claude/ preservation | HIGH | File-level merging works |
| Hook path resolution | HIGH | Symlinks handled correctly |

**Potential Issues:**

1. **Windows symlinks** - Require admin privileges or developer mode
2. **Network drives** - Symlinks may not work across network boundaries
3. **User must remember source location** - Could store in `.claude-pack-source` file

## Recommendations

### 1. Rename Commands with `_my_` Prefix

Rename all 16 commands:
```bash
cd claude-pack/commands
for f in *.md; do
    [ "$f" = "example-command.md" ] && continue
    mv "$f" "_my_${f//-/_}"
done
```

### 2. Create New `setup-target.sh` Script

Replace `init-project.sh` with a simpler script that:
- Takes optional `--no-track` flag
- Uses absolute symlinks to files (not directories)
- Creates `.gitignore` entries in no-track mode
- Preserves existing `.claude/` content

### 3. Update README for New Workflow

Document:
- Clone location (suggest `~/.local/share/agentic-project-init`)
- Per-project setup command
- No-track vs track mode
- How updates work (`git pull` in source repo)

### 4. Create Uninstall Script

For easy cleanup:
```bash
# uninstall-from-target.sh
# Removes all _my_* symlinks from .claude/
```

### 5. Consider Source Location Storage

Store the source repo location in target project:
```bash
echo "$SOURCE_DIR" > .claude/.pack-source
```

This allows:
- Easy uninstall
- Verification that symlinks point to valid location
- Potential for per-project different sources

## Open Questions

1. **Should agents also be prefixed?** Currently `recall.md` - should become `_my_recall.md`?

2. **Skills namespace** - Skills use SKILL.md inside directories. Should directory be prefixed? e.g., `_my_example-skill/`

3. **Hook naming** - Hooks aren't invoked by name, so no conflict concern. Keep original names?

4. **Cross-references in commands** - Commands that reference other commands (e.g., `/research` -> `/spec`) need updating to new names (`/_my_research` -> `/_my_spec`)

5. **User aliases** - Should we provide a mechanism for users to create short aliases for frequently used commands?

---

## Implementation Checklist

- [ ] Rename commands with `_my_` prefix
- [ ] Update cross-references in command files
- [ ] Rename agents with `_my_` prefix
- [ ] Create `setup-target.sh` with file-level symlinks
- [ ] Implement `--no-track` flag
- [ ] Create `.gitignore` management logic
- [ ] Test on project with existing `.claude/`
- [ ] Test on fresh project
- [ ] Update README.md
- [ ] Create uninstall script
- [ ] Test on Windows (if applicable)

---

## Next Steps

1. **Decide on prefix** - Confirm `_my_` or alternative (e.g., `_api_`, `_tpl_`, `_ext_`)
2. **Create spec** - `/spec` for the new setup-target.sh script
3. **Implement** - Start with command renaming, then script

**Related Commands:**
- After research -> `/spec` to define requirements for setup-target.sh
- After spec -> `/design` for implementation details
