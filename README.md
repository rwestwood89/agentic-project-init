# Claude Agentic Templates

A reusable template repository for Claude Code configurations and project management workflows. This enables you to maintain a single source of truth for your agentic coding workflow across multiple projects.

## What's Included

### `claude-pack/` - Claude Code Configuration

Everything that goes into `.claude/` via symlinks:

- **commands/** - Custom slash commands (memory management, project management)
- **hooks/** - Event hooks (capture, transcript parsing)
- **agents/** - Autonomous subprocesses for complex tasks
- **skills/** - Specialized capabilities and domain knowledge
- **rules/** - Project guidelines and coding standards

### `project-pack/` - Project Management Template

Copied to `.project/` in target projects (not symlinked, so each project has its own).

### `.claude/` - Symlinks for Development

This repo uses symlinks to `claude-pack/` so we test what we ship:
- `.claude/commands` -> `../claude-pack/commands`
- `.claude/hooks` -> `../claude-pack/hooks`
- `.claude/agents` -> `../claude-pack/agents`

### `.project/` - This Repo's Project Management

Contains actual work items for developing the templates (not distributed).

### `scripts/` - Automation Scripts
- **init-project.sh** - Initialize templates in a new project
- **update-templates.sh** - Sync latest template changes

### `docs/` - Documentation
- **STRUCTURE.md** - Explains how this repo is organized

## Strategy: Git Submodule + Symlinks

This repository uses a **validated approach** where:

1. The template repo is added as a git submodule to your project
2. Symlinks connect your project's `.claude/` to the submodule
3. Changes to templates automatically sync across all projects
4. Each project can pin to specific template versions

**Validated:** Custom commands, skills, agents, and rules all work correctly through symlinks ✅

## Quick Start

### Initial Setup (Do Once)

1. **Create and publish this template repository:**

```bash
cd /path/to/agentic-project-init
git init
git add .
git commit -m "Initial commit: Claude agentic templates"
git remote add origin git@github.com:yourusername/claude-agentic-templates.git
git push -u origin main
```

2. **Update the repository URL in the init script:**

Edit `scripts/init-project.sh` and update:
```bash
TEMPLATE_REPO_URL="git@github.com:yourusername/claude-agentic-templates.git"
```

### Using Templates in a New Project

1. **Navigate to your project directory:**

```bash
cd /path/to/my-new-project
git init  # if not already a git repo
```

2. **Download and run the init script:**

```bash
# Option A: Download directly
curl -O https://raw.githubusercontent.com/yourusername/claude-agentic-templates/main/scripts/init-project.sh
chmod +x init-project.sh
./init-project.sh

# Option B: Clone and copy
git clone git@github.com:yourusername/claude-agentic-templates.git /tmp/templates
cp /tmp/templates/scripts/init-project.sh .
./init-project.sh
```

3. **Commit the setup:**

```bash
git add .
git commit -m "Add Claude agentic templates"
```

4. **Restart Claude Code:**

Exit and restart Claude Code to discover new commands, skills, and agents.

## Project Structure After Init

```
my-project/
├── .claude/
│   ├── commands/    -> ../claude-templates/claude-pack/commands/  (symlink)
│   ├── hooks/       -> ../claude-templates/claude-pack/hooks/     (symlink)
│   ├── agents/      -> ../claude-templates/claude-pack/agents/    (symlink)
│   ├── skills/      -> ../claude-templates/claude-pack/skills/    (symlink)
│   └── rules/       -> ../claude-templates/claude-pack/rules/     (symlink)
├── .project/                 (copied from project-pack/)
│   ├── CURRENT_WORK.md
│   ├── backlog/
│   ├── active/
│   ├── completed/
│   ├── memories/
│   ├── research/
│   └── reports/
├── claude-templates/         (git submodule)
│   ├── claude-pack/          (commands, hooks, agents, skills, rules)
│   ├── project-pack/         (project management template)
│   └── scripts/
└── [your project files]
```

**Note**: `.claude/` contents are symlinked (shared across projects), while `.project/` is copied (project-specific content).

## Syncing Template Updates

### When You Improve a Template

1. **Make changes in any project:**

```bash
cd my-project/claude-templates
# Edit files in claude-pack/
git add .
git commit -m "Improve code review command"
git push origin main
```

2. **Update other projects:**

```bash
cd my-other-project
./claude-templates/scripts/update-templates.sh
# or manually:
cd claude-templates
git pull origin main
```

3. **Restart Claude Code** to pick up changes.

### Automatic Sync

Changes appear instantly via symlinks! No need to copy files.

Just `git pull` in the submodule to get latest template updates.

## Customization Strategies

### Per-Project Branches (Recommended)

The best way to customize templates for a specific project while maintaining sync capability:

```bash
cd my-project/claude-templates

# Create a project-specific branch
git checkout -b my-project-customizations

# Make your tweaks
vim claude-pack/commands/review.md
git add .
git commit -m "Customize review command for this project"

# Record this branch in the parent project
cd ..
git add claude-templates
git commit -m "Pin submodule to project-specific branch"
```

**Syncing upstream changes to your branch:**

```bash
cd claude-templates
git fetch origin main
git merge origin/main
# Resolve any conflicts, then commit

cd ..
git add claude-templates
git commit -m "Merge latest template updates"
```

**Contributing customizations back to main:**

```bash
cd claude-templates

# Option 1: Cherry-pick specific commits
git checkout main
git cherry-pick <commit-hash>
git push origin main
git checkout my-project-customizations

# Option 2: Merge everything back
git checkout main
git merge my-project-customizations
git push origin main
git checkout my-project-customizations
```

### Per-Project Overrides (Break Symlink)

If a project needs completely independent configuration that won't sync:

```bash
# Remove symlink and create local copy
rm .claude/commands
cp -r claude-templates/claude-pack/commands .claude/commands

# Now edit .claude/commands/ locally
# This project won't receive template updates for commands
```

### Shared + Local Mix

Keep some configs shared, others local:

```bash
.claude/
├── commands/    -> ../claude-templates/claude-pack/commands/  (shared)
├── skills/      -> ../claude-templates/claude-pack/skills/    (shared)
├── agents/      (local directory - project-specific)
└── rules/       (local directory - project-specific)
```

### Version Pinning

Pin a project to a specific template version:

```bash
cd my-project/claude-templates
git checkout v1.2.3  # or specific commit hash
cd ..
git add claude-templates
git commit -m "Pin templates to v1.2.3"
```

## Advanced: Multiple Template Sets

Organize templates by project type:

```
claude-templates/
├── base/         (universal configs)
├── python/       (Python-specific)
├── javascript/   (JS-specific)
└── scripts/

# In init script, symlink selectively:
ln -s ../claude-templates/base/claude-pack/commands .claude/commands
ln -s ../claude-templates/python/claude-pack/rules .claude/rules
```

## Troubleshooting

### Commands Not Appearing

**Symptom:** New commands don't show up in Claude Code

**Solutions:**
1. Restart Claude Code completely (exit and reopen)
2. Verify symlink: `ls -la .claude/commands`
3. Check file permissions: `ls -l claude-templates/claude-pack/commands/`

### Symlink Issues

**Symptom:** Symlinks broken or pointing to wrong location

**Solutions:**
```bash
# Check symlink target
readlink .claude/commands

# Recreate symlink
rm .claude/commands
ln -s ../claude-templates/claude-pack/commands .claude/commands
```

### Git Submodule Not Updating

**Symptom:** `git pull` doesn't update submodule

**Solutions:**
```bash
# Update submodule manually
git submodule update --remote

# Or configure automatic updates
git config submodule.recurse true
```

### Merge Conflicts in Submodule

**Symptom:** Submodule has merge conflicts

**Solutions:**
```bash
cd claude-templates
git status
# Resolve conflicts
git add .
git commit
cd ..
git add claude-templates
git commit
```

### Submodule in Detached HEAD State

**Symptom:** After cloning or updating, `cd claude-templates && git status` shows "HEAD detached"

**Explanation:** This is normal. Git submodules track a specific commit, not a branch. For most workflows this is fine.

**If you need to work on a branch:**
```bash
cd claude-templates

# Check out the branch you want
git checkout main
# or your project-specific branch:
git checkout my-project-customizations

# Now you can make commits normally
```

### Collaborator Doesn't Have Submodule Contents

**Symptom:** After cloning, the `claude-templates/` directory is empty

**Solution:** Submodules must be explicitly initialized:
```bash
# If already cloned:
git submodule update --init --recursive

# Or clone with submodules in one step:
git clone --recurse-submodules <repo-url>
```

## Best Practices

### 1. Start Simple
Begin with a few essential commands and rules. Expand as you discover patterns.

### 2. Document Everything
Add clear descriptions to all commands, skills, and agents. Future you will thank you.

### 3. Version Your Templates
Use git tags for major template changes:
```bash
git tag -a v1.0.0 -m "Initial stable release"
git push origin v1.0.0
```

### 4. Review Before Syncing
Always review template changes before pulling into active projects.

### 5. Test in One Project First
When making significant template changes, test in one project before syncing everywhere.

### 6. Keep Templates Generic
Avoid project-specific details in shared templates. Use template variables or placeholders.

## Examples

### Example: Creating a Code Review Command

```bash
# Edit in any project
vim claude-templates/claude-pack/commands/review.md
```

```markdown
---
description: Perform comprehensive code review
---

Review the changes in this pull request with focus on:

1. Code quality and maintainability
2. Security vulnerabilities
3. Performance considerations
4. Test coverage
5. Documentation completeness

Provide specific, actionable feedback.
```

```bash
# Commit and push
cd claude-templates
git add claude-pack/commands/review.md
git commit -m "Add code review command"
git push origin main

# Update other projects
cd ~/other-project
cd claude-templates && git pull origin main
# Changes appear instantly via symlink!
```

### Example: Architecture Decision Template

Create `.project/architecture/ADR-001-example.md`:

```markdown
# ADR-001: Use PostgreSQL for Primary Database

**Date:** 2024-01-15
**Status:** Accepted

## Context
We need a reliable database for our application with strong ACID guarantees.

## Decision
We will use PostgreSQL as our primary database.

## Consequences

### Positive
- Strong ACID compliance
- Rich ecosystem and tooling
- JSON support for flexible schemas

### Negative
- Requires more operational overhead than managed services
- Scaling requires careful planning

## Alternatives Considered
- MongoDB: Rejected due to ACID requirements
- MySQL: Rejected due to PostgreSQL's superior JSON support
```

## Contributing to Templates

If you're using this across a team:

1. Create feature branches for significant changes
2. Open PRs for team review
3. Use semantic versioning for releases
4. Document breaking changes in commit messages

## Resources

- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [Git Submodules Tutorial](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Architecture Decision Records](https://adr.github.io/)

## License

MIT License - Customize as needed for your organization.

---

**Happy Coding with Claude!** 🚀
