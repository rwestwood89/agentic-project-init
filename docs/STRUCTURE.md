# Repository Structure

This document explains how this repository is organized to solve the meta-problem: **we're building a bootstrap package while using it to develop itself**.

## The Challenge

We need to:
1. Develop Claude Code templates (commands, hooks, agents)
2. Develop project management templates
3. Use those same tools to organize our own development
4. Keep "what we ship" separate from "what we use to develop"

## Solution: Separate Packs with Symlinks

```
agentic-project-init/
│
├── claude-pack/                  # CLAUDE CODE CONFIGURATION
│   ├── commands/                 # Slash commands
│   ├── hooks/                    # Event hooks
│   ├── agents/                   # Specialized agents
│   ├── rules/                    # Project guidelines
│   └── skills/                   # Skills
│
├── project-pack/                 # PROJECT MANAGEMENT TEMPLATE
│   ├── README.md                 # → .project/ in target projects
│   ├── backlog/
│   ├── active/
│   ├── completed/
│   └── memories/
│
├── .claude/                      # SYMLINKS for this repo's use
│   ├── commands -> ../claude-pack/commands
│   ├── hooks -> ../claude-pack/hooks
│   ├── agents -> ../claude-pack/agents
│   ├── settings.json             # Repo-specific (not symlinked)
│   └── settings.local.json       # Local overrides (gitignored)
│
├── .project/                     # THIS REPO's project management
│   └── (not distributed)
│
├── scripts/                      # Installation scripts
├── docs/                         # Documentation
└── README.md
```

## Key Directories

### `claude-pack/` - What Ships

This is the distributable package. Everything here gets installed in target projects.

Contents become `.claude/*` in target projects via symlinks:
- `commands/` - Slash commands (memory management, project management)
- `hooks/` - Event hooks (capture, parse-transcript, etc.)
- `agents/` - Specialized agents (recall agent, etc.)
- `rules/` - Project guidelines
- `skills/` - Specialized capabilities

### `project-pack/` - Project Management Template

Becomes `.project/` in target projects (copied, not symlinked):
- Project management workflow templates
- Backlog structure
- Memory storage structure

### `.claude/` - Symlinked for Development

We use symlinks so that:
1. **We test what we ship** - Using the actual templates during development
2. **Edits go to the right place** - Changes to commands update `claude-pack/`
3. **No drift** - Can't accidentally have different dev vs shipped versions

**Exception**: `settings.json` is NOT symlinked (repo-specific configuration).

### `.project/` - This Repo Only

Actual project management for this repository:
- Our backlog
- Our work items
- Our memories

This is NOT the template. The template is in `project-pack/`.

### `scripts/` - Installation Tools

- `init-project.sh` - Sets up templates in a new project
- `update-templates.sh` - Syncs latest template changes

## Workflow

### Developing Templates

1. Edit files in `claude-pack/` (commands, hooks, agents, project)
2. Changes are immediately available via symlinks
3. Test by using the commands/hooks normally
4. Commit to `claude-pack/` directory

### Using for This Repo's Development

1. `.claude/` symlinks make templates available
2. `.project/` contains our actual work tracking
3. Commands like `/capture`, `/recall` work normally
4. Memories are stored in `.project/memories/` (not distributed)

### Installing in Another Project

```bash
./scripts/init-project.sh
# Creates symlinks: .claude/* -> submodule/claude-pack/*
# Copies template: .project/ from project-pack/
# Suggests /init if no CLAUDE.md exists
```

## What's Distributed vs Local

| Directory | In Git | Distributed to Users | Purpose |
|-----------|--------|---------------------|---------|
| `claude-pack/` | Yes | Yes | The package |
| `scripts/` | Yes | Yes | Installation |
| `docs/` | Yes | Yes | Documentation |
| `.claude/` | Symlinks only | No | This repo's config |
| `.project/` | Yes | No | This repo's work |
| `.gitignore` | Yes | No | This repo only |

## FAQ

**Q: Why not just use `.claude/` as the source of truth?**

A: Then we'd have to copy/sync to a distributable location. With `claude-pack/` as source of truth and symlinks for use, there's no sync step.

**Q: Why is `.project/` not symlinked like `.claude/`?**

A: `.project/` contains project-specific content (actual backlog items, memories). We want to USE the template to organize this repo, but the content is repo-specific. So we copy the template structure but don't share the content.

**Q: What about `settings.json`?**

A: Not symlinked because it contains repo-specific config (MCP servers, model preferences). Templates can include a `settings.template.json` for reference.

**Q: Can I break out of symlinks for customization?**

A: Yes. Replace any symlink with an actual directory:
```bash
rm .claude/commands
cp -r claude-pack/commands .claude/commands
# Now .claude/commands is independent
```
