# Agentic Project Init

A reusable template repository for Claude Code configurations and project management workflows. Clone once, use everywhere - commands are available globally via symlinks to `~/.claude/`.

## What's Included

### `claude-pack/` - Claude Code Configuration

Everything that gets symlinked to `~/.claude/`:

- **commands/** - Custom slash commands (`/_my_research`, `/_my_spec`, `/_my_design`, etc.)
- **hooks/** - Event hooks (transcript capture, memory management)
- **agents/** - Autonomous subprocesses for complex tasks
- **skills/** - Specialized capabilities and domain knowledge
- **rules/** - Project guidelines and coding standards
- **scripts/** - Standalone tools (Ralph Loop for autonomous project scaffolding)

### `project-pack/` - Project Management Template

Copied to `.project/` in target projects:

- **CURRENT_WORK.md** - Track active work
- **backlog/** - Planned features and tasks
- **active/** - In-progress specs, designs, and plans
- **completed/** - Finished work
- **adr/** - Append-only decision records with a generated index
- **product/** - Append-only ledger of implemented product promises, with a generated index
- **memories/** - Conversation summaries and learnings
- **research/** - Research notes and findings
- **reports/** - Generated reports

### `scripts/` - Setup Scripts

- **setup-global.sh** - One-time global installation to `~/.claude/`
- **init-project.sh** - Per-project initialization
- **uninstall-global.sh** - Remove global installation
- **uninstall-project.sh** - Remove from a project

## Quick Start

### Step 1: Clone This Repository (Once)

```bash
# Clone to a permanent location
git clone https://github.com/yourusername/agentic-project-init.git ~/agentic-project-init
```

### Step 2: Run Global Setup (Once)

```bash
cd ~/agentic-project-init
./scripts/setup-global.sh
```

This creates symlinks in `~/.claude/` pointing to the commands, hooks, agents, skills, rules, and scripts.

### Step 3: Initialize Projects (Each Project)

```bash
cd /path/to/your-project
~/agentic-project-init/scripts/init-project.sh
```

This copies the `.project/` template for project-specific state.

### Step 4: Use Commands

Restart Claude Code, then use commands with the `_my_` prefix. **Run `/_my_pipeline` first** — it's the canonical map of the workflow stages and when to use each one. The full catalog is in the Command Reference below.

## Working with Claude Code

See **[docs/guide.md](docs/guide.md)** for the full guide:
- The questions that decide which commands to run ("how well do you understand the problem?")
- The shaping path (concept, product design, concept design, epic planning) and the work-item flow
- When to research, spike, or write learning tests; when decisions become ADRs
- Using reviews to manage consistency and good design across complexity
- Session continuity (the wrap-up/boot sequence)

## Command Reference

One line per command; each command's own doc in `claude-pack/commands/` has the mechanics. For stage order and when to use each stage, run `/_my_pipeline`.

### Pipeline map and orchestration

| Command | Description |
|---------|-------------|
| `/_my_pipeline` | The canonical map of the workflow — stage order, entry points, when to use each stage |
| `/_my_orchestrate` | Autonomously drive the pipeline end to end via staged subagents |

### Shaping and de-risking

| Command | Description |
|---------|-------------|
| `/_my_research` | Deep codebase exploration and feasibility analysis (read-only) |
| `/_my_concept` | Develop a feature concept with success criteria |
| `/_my_concept_design` | Shape system architecture and load-bearing decisions |
| `/_my_concept_design_review` | Pressure-test a design concept in a fresh session |
| `/_my_spike` | Confirm a known assumption with a throwaway probe; keeps a findings doc |
| `/_my_learning_test` | Discover how an unfamiliar surface behaves via real, kept tests |

### Per work item

| Command | Description |
|---------|-------------|
| `/_my_epic_plan` | Decompose shaping output into a scoped epic with backlog items |
| `/_my_spec` | Capture the problem, success criteria, and requirements |
| `/_my_spec_review` | Adversarial spec review in a fresh session |
| `/_my_product_design` | Experience design for consumer-facing surfaces (optional stage) |
| `/_my_design` | Technical design: architecture, interfaces, decisions |
| `/_my_design_review` | Critical design review in a fresh session |
| `/_my_plan` | Phased implementation plan with test-first checkboxes |
| `/_my_implement` | Execute the plan phase by phase with validation |
| `/_my_audit` | Certify work against plan/spec/design |
| `/_my_close` | Archive completed work items or epics |
| `/_my_pre_pr` | Branch gate after close: quality checks and PR submission (per shippable item, or once at epic end) |

### Shortcuts and modes

| Command | Description |
|---------|-------------|
| `/_my_quick_edit` | Small, scoped changes that skip the pipeline |
| `/_my_ponytail` | Lazy-senior-dev mode: force the simplest solution that works |
| `/_my_slop` | Reset writing style for the rest of the session |
| `/_my_ask_me` | Ask questions the right way: one at a time, with context, options, and a recommendation |

### Project management and session continuity

| Command | Description |
|---------|-------------|
| `/_my_status` | Project orientation, gap analysis, next steps |
| `/_my_project_find` | Quick lookups of project context |
| `/_my_git_manage` | Git workflow, worktrees, conflict resolution |
| `/_my_wrap_up` | End-of-session context persistence |
| `/_my_handoff` | Write a handoff doc so a fresh agent can continue mid-task |

### Legacy (superseded by `/_my_wrap_up` + auto-memory)

Kept for edge cases (e.g. salvaging content after an unexpected compaction); excluded from the Codex distribution.

| Command | Description |
|---------|-------------|
| `/_my_capture` | Mark the conversation for later memorization |
| `/_my_memorize` | Create a structured memory from a transcript |
| `/_my_recall` | Search past conversation transcripts |
| `/_my_review_compact` | Review an autocompact capture |

## Ralph Loop

The Ralph Wiggum Loop is an autonomous coding pipeline. Given a concept file describing
project outcomes, it generates a complete project scaffold in a git worktree:

- Multi-pass design documents (initial → review → refined)
- Individual specification files
- Agent prompts (planning + building modes)
- A loop runner script for iterative autonomous coding
- Python project scaffold (UV, pytest, ruff, mypy)

### Usage

```bash
~/.claude/scripts/ralph-init.sh <project_name> <concept_file> [options]
```

### Example

```bash
cd ~/my-repo
~/.claude/scripts/ralph-init.sh comment-system ./CONCEPT.md
~/.claude/scripts/ralph-init.sh auth-system ./auth-concept.md --design-model opus
```

### Prerequisites

- Must be run from within a git repository
- Claude CLI installed and configured
- UV installed (for Python projects)

### Options

| Option | Description |
|--------|-------------|
| `--model <model>` | Model for generation (default: sonnet) |
| `--design-model <model>` | Model for design phase (default: sonnet) |
| `--help` | Show usage information |

Environment variables: `RALPH_MODEL`, `RALPH_DESIGN_MODEL`

### What It Produces

```
../repo_projectname/          (git worktree)
├── DESIGN_v1.md              Initial design
├── DESIGN_REVIEW.md          Critical review
├── DESIGN.md                 Refined design
├── specs/                    Individual specifications
├── AGENTS.md                 Operational guide
├── PROMPT_plan.md            Planning mode prompt
├── PROMPT_build.md           Building mode prompt
├── loop.sh                   Ralph loop runner
├── pyproject.toml            Python project config
├── src/<package>/            Source package
└── tests/                    Test scaffold
```

After setup: review the design evolution, then `./loop.sh plan 3` to plan, `./loop.sh 10` to build.

## Script Reference

### setup-global.sh

One-time installation of commands to `~/.claude/`.

```bash
./scripts/setup-global.sh [--dry-run]
```

**Options:**
- `--dry-run` - Show what would be done without making changes

**What it does:**
- Creates `~/.claude/{commands,agents,hooks,skills,rules,scripts}/` directories
- Symlinks all files from `claude-pack/` to `~/.claude/`
- Configures hooks in `~/.claude/settings.json`
- Stores source location in `~/.claude/.agentic-pack-source`

### init-project.sh

Initialize a project with the `.project/` template.

```bash
./scripts/init-project.sh [options]
```

**Options:**
- `--dry-run` - Show what would be done without making changes
- `--no-track` - Add `.project` to `.gitignore` (don't commit project state)
- `--include-claude` - Copy (vendor) commands to `.claude/` instead of using global
- `--source <path>` - Override source location

**Modes:**

| Mode | Commands From | .project/ |
|------|---------------|-----------|
| Default | `~/.claude/` (global) | Tracked in git |
| `--no-track` | `~/.claude/` (global) | Not tracked |
| `--include-claude` | `.claude/` (vendored) | Tracked in git |

**Note:** `--no-track` and `--include-claude` cannot be used together.

### uninstall-global.sh

Remove global installation from `~/.claude/`.

```bash
./scripts/uninstall-global.sh
```

**What it does:**
- Removes symlinks pointing to this repository (preserves user files)
- Cleans hook configuration from `settings.json`
- Removes metadata files

### uninstall-project.sh

Remove `.project/` and vendored content from a project.

```bash
./scripts/uninstall-project.sh [--force]
```

**Options:**
- `--force` - Skip confirmation prompt

**What it does:**
- Removes `.project/` directory
- Cleans `.project` from `.gitignore` if present
- If vendored, removes agentic-pack files from `.claude/` (preserves user files)

## Project Structure After Init

```
your-project/
├── .project/                    (copied, project-specific)
│   ├── CURRENT_WORK.md
│   ├── active/
│   ├── adr/
│   ├── backlog/
│   ├── completed/
│   ├── memories/
│   ├── product/
│   ├── research/
│   └── reports/
└── [your project files]

~/.claude/                       (symlinked, shared globally)
├── commands/
│   ├── _my_research.md -> /path/to/agentic-project-init/claude-pack/commands/_my_research.md
│   └── ...
├── agents/
├── hooks/
├── skills/
├── rules/
├── scripts/
│   └── ralph-init.sh -> /path/to/agentic-project-init/claude-pack/scripts/ralph-init.sh
└── settings.json
```

## Updating

To get the latest commands and templates:

```bash
cd ~/agentic-project-init
git pull
```

Changes are instantly available via symlinks - no need to re-run setup.

## Vendoring (Self-Contained Projects)

For projects that need to be fully self-contained (e.g., to share with others who don't have global setup):

```bash
./scripts/init-project.sh --include-claude
```

This copies all commands to `.claude/` in the project. The project works independently of the global installation.

## Migration from Submodule Approach

If you previously used the git submodule approach:

### Step 1: Remove Submodule

```bash
cd your-project
git submodule deinit claude-templates
git rm claude-templates
rm -rf .git/modules/claude-templates
```

### Step 2: Remove Old Symlinks

```bash
rm -rf .claude/commands .claude/hooks .claude/agents .claude/skills .claude/rules
```

### Step 3: Run New Setup

```bash
# Global setup (once)
~/agentic-project-init/scripts/setup-global.sh

# Project init (if .project/ doesn't exist)
~/agentic-project-init/scripts/init-project.sh
```

### Step 4: Update Command References

Commands now use `_my_` prefix:

| Old | New |
|-----|-----|
| `/research` | `/_my_research` |
| `/spec` | `/_my_spec` |
| `/design` | `/_my_design` |
| `/plan` | `/_my_plan` |
| `/implement` | `/_my_implement` |
| `/code-review` | `/_my_audit` (conformance) + `/_my_pre_pr` (quality) |
| `/code-quality` | `/_my_pre_pr` |
| etc. | etc. |

## Why the `_my_` Prefix?

The `_my_` prefix:
1. Prevents conflicts with project-local commands
2. Clearly identifies these as user-level commands
3. Groups them together in command listings
4. Follows Claude Code's convention for user commands

## Troubleshooting

### Commands Not Appearing

1. Restart Claude Code completely
2. Verify symlinks exist: `ls -la ~/.claude/commands/`
3. Check symlink targets: `readlink ~/.claude/commands/_my_research.md`

### "Cannot determine source location" Error

Run global setup first, or specify source:
```bash
./scripts/init-project.sh --source ~/agentic-project-init
```

### Broken Symlinks

If the source repository was moved:
```bash
# Uninstall and reinstall
./scripts/uninstall-global.sh
cd /new/location/agentic-project-init
./scripts/setup-global.sh
```

### Hook Not Running

Check `~/.claude/settings.json` has the PreCompact hook configured:
```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/.claude/hooks/precompact-capture.sh"
          }
        ]
      }
    ]
  }
}
```

## License

MIT License - Customize as needed for your organization.
