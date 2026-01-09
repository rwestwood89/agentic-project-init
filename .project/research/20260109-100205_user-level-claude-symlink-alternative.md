---
date: 2026-01-09T10:02:05-08:00
researcher: Claude
topic: "User-Level ~/.claude Symlink Alternative"
tags: [research, architecture, installation, symlinks, user-level]
status: complete
last_updated: 2026-01-09
---

# Research: User-Level ~/.claude Symlink Alternative

**Date**: 2026-01-09T10:02:05-08:00
**Researcher**: Claude
**Research Type**: Architecture / Feasibility

## Research Question

As an alternative to the previous research on symlinks to project folders:
- Can we symlink commands, hooks, agents, and skills to `~/.claude/` instead of each project's `.claude/` folder?
- This would make the commands visible for ALL projects
- Handle `.project/` the same way (copy to each project)

## Summary

- **User-level configuration is FULLY SUPPORTED by Claude Code** - commands, hooks, agents, skills all work in `~/.claude/`
- **This approach is SIMPLER than the previous proposal** - no gitignore management, no per-project symlinks
- **Trade-off: Commands become global** - available across ALL projects, not selectively
- **`.project/` still needs per-project copying** - project state must be local
- **Recommended approach: Hybrid** - user-level for commands/agents, project-level for `.project/` only

## Detailed Findings

### Claude Code User-Level Configuration Capabilities

Claude Code has a **scope hierarchy** for configurations:

| Scope | Location | Priority |
|-------|----------|----------|
| Managed | System-level | Highest |
| Local | `.claude/*.local.*` | High |
| Project | `.claude/` | Medium |
| **User** | **`~/.claude/`** | Lowest |

**Key Finding**: Claude Code fully supports user-level:

| Feature | User Location | Supported? |
|---------|---------------|------------|
| Commands | `~/.claude/commands/` | YES |
| Hooks | `~/.claude/settings.json` hooks section | YES |
| Agents | `~/.claude/agents/` | YES |
| Skills | `~/.claude/skills/` | YES |
| Rules | `~/.claude/settings.json` permissions | YES |
| CLAUDE.md | `~/.claude/CLAUDE.md` | YES |

When listed in `/help`, user-level commands show "(user)" after their description.

### Current Project Structure

```
agentic-project-init/
├── claude-pack/
│   ├── commands/         # 16 command files
│   │   ├── research.md
│   │   ├── design.md
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── implement.md
│   │   ├── code-review.md
│   │   ├── code-quality.md
│   │   ├── git-manage.md
│   │   ├── project-manage.md
│   │   ├── project-find.md
│   │   ├── quick-edit.md
│   │   ├── capture.md
│   │   ├── recall.md
│   │   ├── memorize.md
│   │   ├── review-compact.md
│   │   └── example-command.md
│   ├── agents/           # 2 agent files
│   │   ├── recall.md
│   │   └── example-agent.md
│   ├── hooks/            # 4 hook scripts
│   │   ├── capture.sh
│   │   ├── precompact-capture.sh
│   │   ├── parse-transcript.py
│   │   └── query-transcript.py
│   ├── skills/           # 1 skill
│   │   └── example-skill.md
│   └── rules/            # Rules directory
└── .project/             # Project state (per-project)
```

### Proposed Alternative Architecture

**One-time setup (symlink to ~/.claude/):**

```
~/.claude/
├── commands/
│   ├── research.md -> ~/repos/agentic-project-init/claude-pack/commands/research.md
│   ├── design.md -> ~/repos/agentic-project-init/claude-pack/commands/design.md
│   ├── ... (all commands)
├── agents/
│   ├── recall.md -> ~/repos/agentic-project-init/claude-pack/agents/recall.md
│   └── ...
├── skills/
│   └── ... (symlinks to skills)
└── settings.json          # Hooks configured here
```

**Per-project setup (copy .project/ only):**

```
target-project/
└── .project/              # Copied (each project needs its own state)
    ├── research/
    ├── specs/
    ├── designs/
    └── ...
```

### Comparison: Per-Project Symlinks vs User-Level Symlinks

| Aspect | Per-Project Symlinks (Previous Research) | User-Level Symlinks (This Research) |
|--------|------------------------------------------|-------------------------------------|
| **Setup complexity** | Per-project script execution | One-time global setup |
| **Gitignore management** | Required in each project | Not needed |
| **Command visibility** | Per-project (selective) | All projects (global) |
| **Conflicts with existing** | Need `_my_` prefix | Still need prefix if project has same |
| **Updates** | `git pull` updates all linked projects | `git pull` updates globally |
| **Uninstall** | Per-project symlink removal | Single global cleanup |
| **New project setup** | Run setup script | Copy `.project/` only |
| **Per-project customization** | Possible | Not easily |
| **Hook configuration** | Per-project settings.json | Global ~/.claude/settings.json |

### Hook Configuration Considerations

**Previous approach** - hooks in `.claude/settings.json` per project:
```json
{
  "hooks": {
    "PreCompact": [{
      "command": ".claude/hooks/precompact-capture.sh"
    }]
  }
}
```

**User-level approach** - hooks in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreCompact": [{
      "command": "~/.claude/hooks/precompact-capture.sh"
    }]
  }
}
```

**CRITICAL ISSUE**: The hooks reference paths like `.project/transcripts/` which is project-specific!

The `precompact-capture.sh` hook writes to:
- `.project/transcripts/`

This means the hook MUST be aware of the current project directory, not ~/.claude.

**Solution**: Hooks can work globally IF they:
1. Use relative paths (`.project/transcripts/`) which resolve to current working directory
2. The `.project/` folder exists in each target project

### Implementation Approach

**Step 1: One-time global setup**

```bash
#!/bin/bash
# setup-user-level.sh - Run once

SOURCE_DIR="${1:-$(dirname "$(readlink -f "$0")")/..}"

# Create ~/.claude directories if needed
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/hooks

# Symlink commands (file-level to allow mixing)
for file in "$SOURCE_DIR"/claude-pack/commands/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    target="$HOME/.claude/commands/$filename"

    if [ ! -e "$target" ]; then
        ln -s "$file" "$target"
        echo "Linked command: $filename"
    else
        echo "Skipped (exists): $filename"
    fi
done

# Symlink agents
for file in "$SOURCE_DIR"/claude-pack/agents/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    target="$HOME/.claude/agents/$filename"

    if [ ! -e "$target" ]; then
        ln -s "$file" "$target"
        echo "Linked agent: $filename"
    fi
done

# Symlink hooks
for file in "$SOURCE_DIR"/claude-pack/hooks/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    target="$HOME/.claude/hooks/$filename"

    if [ ! -e "$target" ]; then
        ln -s "$file" "$target"
        echo "Linked hook: $filename"
    fi
done

# Configure hooks in ~/.claude/settings.json
# (merge with existing if present)
echo "NOTE: You need to manually add hook configuration to ~/.claude/settings.json"
```

**Step 2: Per-project initialization**

```bash
#!/bin/bash
# init-project.sh - Run in each project

SOURCE_DIR="${SOURCE_DIR:-$HOME/.local/share/agentic-project-init}"

# Copy .project/ template (each project needs its own state)
if [ ! -d ".project" ]; then
    cp -r "$SOURCE_DIR/project-pack" .project
    echo "Created .project/ directory"
else
    echo ".project/ already exists"
fi
```

### Handling `.project/` State

The `.project/` directory contains per-project state:
- Research documents
- Specs
- Design documents
- Transcripts
- Context/memory

This MUST remain per-project because:
1. Each project has different research/specs
2. Transcripts are project-specific
3. Memory/context is project-scoped

**Gitignore options for `.project/`:**

| Mode | Description | Gitignore |
|------|-------------|-----------|
| Track | Commit project state | Nothing |
| No-track | Don't commit | `.project` |
| Selective | Some tracked | `.project/transcripts/` |

### Command Naming Consideration

Even with user-level commands, the `_my_` prefix from the previous research may still be valuable:

**Without prefix:**
- Risk: If a project has `.claude/commands/research.md`, it overrides the user-level one
- Benefit: Cleaner command names

**With `_my_` prefix:**
- Risk: Longer command invocations (`/_my_research` instead of `/research`)
- Benefit: Never conflicts with project commands

**Recommendation**: Keep original names. If a project needs a custom `/research`, they can create it and it will override - this is expected behavior.

## Architecture Insights

### Scope Priority (from Claude Code docs)

When the same command exists at multiple levels:
1. Project-level (`.claude/commands/`) takes priority
2. User-level (`~/.claude/commands/`) is fallback

This means:
- User-level commands are "defaults"
- Projects can override with their own versions
- No explicit conflict handling needed

### This Approach Aligns Better with Claude Code's Design

Claude Code was designed with user-level configuration in mind. Using `~/.claude/` is:
- The intended way to share personal tools across projects
- Simpler than per-project symlink management
- No gitignore pollution in target projects

## Feasibility Assessment

**Overall: HIGHLY FEASIBLE AND SIMPLER**

| Component | Feasibility | Notes |
|-----------|-------------|-------|
| User-level commands | HIGH | Native Claude Code support |
| User-level agents | HIGH | Native Claude Code support |
| User-level hooks | HIGH | Configured in ~/.claude/settings.json |
| Per-project .project/ | HIGH | Simple copy operation |
| Hook path resolution | HIGH | Hooks use relative `.project/` paths |

**Advantages over per-project approach:**
1. One-time setup instead of per-project
2. No gitignore management
3. Cleaner target projects (no `.claude/` modifications)
4. Aligns with Claude Code's intended design

**Disadvantages:**
1. Commands visible in ALL projects (may not want `/capture` in non-dev projects)
2. Can't selectively enable commands per project
3. Hooks run in all projects (may create `.project/` unexpectedly)

## Recommendations

### Recommended: Hybrid Approach

Use user-level for most things, but be selective:

1. **User-level (`~/.claude/`)** for:
   - Core commands (research, design, spec, plan, implement)
   - Code review commands
   - Recall/memorize agents

2. **Per-project initialization** for:
   - `.project/` directory (always copy)
   - CLAUDE.md additions (project-specific guidance)

3. **Optional per-project override** for:
   - Projects that need custom versions of commands
   - Projects that shouldn't have certain commands

### Setup Script Design

**Global setup (run once):**
```bash
~/.local/share/agentic-project-init/scripts/setup-global.sh
```
- Creates symlinks in `~/.claude/`
- Configures hooks in `~/.claude/settings.json`

**Project setup (run per project):**
```bash
~/.local/share/agentic-project-init/scripts/init-project.sh [--no-track]
```
- Copies `.project/` template
- Optionally adds `.project` to `.gitignore`

### Migration Path

From current setup to user-level:

1. Run global setup script (creates ~/.claude/ symlinks)
2. Remove `.claude/commands`, `.claude/agents`, `.claude/hooks` symlinks from this project
3. Keep `.claude/settings.json` for project-specific settings
4. Test commands work globally

## Open Questions

1. **Should hooks create `.project/` automatically?**
   - If hook runs in a project without `.project/`, should it create it?
   - Or fail gracefully?

2. **Per-project hook disable?**
   - Can a project disable user-level hooks?
   - May need `.claude/settings.json` override

3. **Skills handling?**
   - Skills have more complex directory structures
   - Need to verify skill symlinks work at user level

4. **Command discoverability?**
   - Users seeing "(user)" suffix in `/help` - is this clear?
   - Should we document which commands are available?

---

## Implementation Checklist

- [ ] Create `setup-global.sh` script for one-time ~/.claude setup
- [ ] Create `init-project.sh` script for per-project .project/ copying
- [ ] Test user-level commands work
- [ ] Test user-level agents work
- [ ] Test hooks with relative .project/ paths
- [ ] Update README.md with new workflow
- [ ] Create uninstall-global.sh for cleanup
- [ ] Test in a fresh project

---

## Summary Comparison

| Approach | Setup Effort | Maintenance | Flexibility | Cleanliness |
|----------|--------------|-------------|-------------|-------------|
| **Per-project symlinks** | Per-project | Low | High (selective) | Medium (gitignore) |
| **User-level symlinks** | One-time | Very low | Medium (global) | High (no project changes) |

**Recommendation**: User-level symlinks for simplicity, with per-project `.project/` copying.

---

## Next Steps

1. **Decide**: User-level vs per-project (or hybrid)
2. **Create spec**: `/spec` for chosen approach
3. **Implement**: Setup scripts
4. **Test**: In multiple projects
5. **Document**: Update README

**Related Commands:**
- After research -> `/spec` to define requirements
- After spec -> `/design` for implementation details
