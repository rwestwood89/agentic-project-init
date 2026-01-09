# Codebase Organization - Implementation Plan

## Overview

Reorganize the repository so that:
- `claude-pack/` is the single source of truth for distributable Claude config
- `.claude/` symlinks to `claude-pack/` (eating our own dog food)
- `.project/` is used for THIS repo's development (not distributed)
- `claude-pack/project/` contains the project template for distribution

## Phase 1: Consolidate claude-pack/

**Goal**: Make `claude-pack/` the complete, authoritative source for Claude configuration.

### 1.1 Copy commands from .claude to claude-pack

Copy the memory management commands currently in `.claude/commands/` to `claude-pack/commands/`:
- `capture.md`
- `memorize.md`
- `recall.md`
- `review-compact.md`

These will join the existing project management commands:
- `project-find.md`
- `project-manage.md`
- `example-command.md` (evaluate if still needed)

### 1.2 Copy agents from .claude to claude-pack

Copy agents from `.claude/agents/` to `claude-pack/agents/`:
- `recall.md`

### 1.3 Copy hooks from .claude to claude-pack

Create `claude-pack/hooks/` and copy:
- `capture.sh`
- `precompact-capture.sh`
- `parse-transcript.py`
- `query-transcript.py`

### 1.4 Review and clean up claude-pack

- Remove `example-command.md` if redundant
- Ensure all commands have proper frontmatter
- Verify hooks have correct permissions/shebang

## Phase 2: Create project template

**Goal**: Create distributable project structure in `claude-pack/project/`.

### 2.1 Create claude-pack/project/ structure

```
claude-pack/project/
├── README.md             # Workflow documentation
├── CURRENT_WORK.md       # Template (starter content)
├── EPIC_GUIDE.md
├── epic_template.md
├── backlog/
│   ├── README.md
│   └── BACKLOG.md
├── active/
│   └── README.md
├── completed/
│   ├── README.md
│   └── CHANGELOG.md
└── memories/
    ├── SPEC.md
    └── index.json        # Empty: {}
```

### 2.2 Copy template files from .project

Copy structural/template files (not actual work items):
- `README.md`
- `EPIC_GUIDE.md`
- `epic_template.md`
- `backlog/README.md`, `backlog/BACKLOG.md` (template version)
- `active/README.md`
- `completed/README.md`, `completed/CHANGELOG.md` (template version)
- `memories/SPEC.md`, empty `memories/index.json`

## Phase 3: Set up symlinks for .claude

**Goal**: Make `.claude/` use symlinks to `claude-pack/` so we test what we ship.

### 3.1 Back up current .claude

```bash
mv .claude .claude.backup
```

### 3.2 Create new .claude with symlinks

```bash
mkdir .claude
ln -s ../claude-pack/commands .claude/commands
ln -s ../claude-pack/hooks .claude/hooks
ln -s ../claude-pack/agents .claude/agents
```

### 3.3 Restore non-symlinked files

Copy back repo-specific files:
```bash
cp .claude.backup/settings.json .claude/
cp .claude.backup/settings.local.json .claude/  # if exists
```

### 3.4 Verify symlinks work

- Test that commands appear in Claude Code
- Test that hooks execute correctly
- Test memory capture/recall workflow

### 3.5 Clean up backup

```bash
rm -rf .claude.backup
```

## Phase 4: Update .project for this repo

**Goal**: Ensure `.project/` is set up for THIS repo's development.

### 4.1 Keep existing .project content

The current `.project/` already has our actual work items and memories. Keep it as-is.

### 4.2 Ensure .project is gitignored appropriately

Decide what parts of `.project/` should be committed vs ignored:
- Committed: Structure, work items we want to track
- Ignored: Potentially large memory files, local scratch

## Phase 5: Update scripts

**Goal**: Update installation scripts for new structure.

### 5.1 Update init-project.sh

Change paths from `claude-pack/` references to new structure:
```bash
# Symlinks for .claude
ln -s "../$SUBMODULE_PATH/claude-pack/commands" ".claude/commands"
ln -s "../$SUBMODULE_PATH/claude-pack/hooks" ".claude/hooks"
ln -s "../$SUBMODULE_PATH/claude-pack/agents" ".claude/agents"

# Copy .project from template
cp -r "$SUBMODULE_PATH/claude-pack/project" .project
```

### 5.2 Update update-templates.sh

Ensure it handles the new structure correctly.

## Phase 6: Update documentation

**Goal**: Ensure README and docs reflect new structure.

### 6.1 Update README.md

- Update "What's Included" section
- Update "Project Structure After Init" diagram
- Update any path references

### 6.2 Update docs/STRUCTURE.md

- Change `templates/` references to `claude-pack/`
- Ensure accuracy with implemented structure

## Phase 7: Clean up

**Goal**: Remove deprecated files and directories.

### 7.1 Update .gitignore

Add/update ignores as needed:
- `artifacts/`
- `.claude/settings.local.json`
- Any local-only files

### 7.2 Remove deprecated directories

- `artifacts/` (already gitignored)
- `project-mgmt/` (if fully replaced by `.project/`)

### 7.3 Review staged files

Before committing, review:
```bash
git status
git diff --staged
```

## Final Structure

```
agentic-project-init/
├── claude-pack/                  # THE DISTRIBUTABLE
│   ├── commands/
│   │   ├── capture.md
│   │   ├── memorize.md
│   │   ├── recall.md
│   │   ├── review-compact.md
│   │   ├── project-find.md
│   │   └── project-manage.md
│   ├── hooks/
│   │   ├── capture.sh
│   │   ├── precompact-capture.sh
│   │   ├── parse-transcript.py
│   │   └── query-transcript.py
│   ├── agents/
│   │   └── recall.md
│   ├── rules/
│   ├── skills/
│   └── project/                  # Project template
│       ├── README.md
│       ├── CURRENT_WORK.md
│       ├── backlog/
│       ├── active/
│       ├── completed/
│       └── memories/
│
├── .claude/                      # SYMLINKS (this repo)
│   ├── commands -> ../claude-pack/commands
│   ├── hooks -> ../claude-pack/hooks
│   ├── agents -> ../claude-pack/agents
│   ├── settings.json             # Repo-specific
│   └── settings.local.json       # Local (gitignored)
│
├── .project/                     # THIS REPO's work (not distributed)
│   ├── active/
│   │   └── codebase-organization/
│   ├── memories/
│   └── ...
│
├── scripts/
│   ├── init-project.sh
│   └── update-templates.sh
│
├── docs/
│   └── STRUCTURE.md
│
├── README.md
└── .gitignore
```

## Checklist

- [ ] Phase 1: Consolidate claude-pack/
  - [ ] 1.1 Copy commands
  - [ ] 1.2 Copy agents
  - [ ] 1.3 Copy hooks
  - [ ] 1.4 Review and clean up
- [ ] Phase 2: Create project template
  - [ ] 2.1 Create structure
  - [ ] 2.2 Copy template files
- [ ] Phase 3: Set up symlinks
  - [ ] 3.1 Back up .claude
  - [ ] 3.2 Create symlinks
  - [ ] 3.3 Restore settings
  - [ ] 3.4 Verify
  - [ ] 3.5 Clean up backup
- [ ] Phase 4: Update .project
  - [ ] 4.1 Keep existing content
  - [ ] 4.2 Review gitignore
- [ ] Phase 5: Update scripts
  - [ ] 5.1 Update init-project.sh
  - [ ] 5.2 Update update-templates.sh
- [ ] Phase 6: Update documentation
  - [ ] 6.1 Update README.md
  - [ ] 6.2 Update docs/STRUCTURE.md
- [ ] Phase 7: Clean up
  - [ ] 7.1 Update .gitignore
  - [ ] 7.2 Remove deprecated
  - [ ] 7.3 Review before commit
