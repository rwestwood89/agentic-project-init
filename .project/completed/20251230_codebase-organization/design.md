# Codebase Organization Design

## Problem Statement

This repository has a meta-problem: we're building a bootstrap package for agentic coding setups while also using those same tools to develop it. This creates conflicts:

1. **`.claude/`** contains commands/hooks we're actively developing AND using
2. **`.project/`** should be a template but also tracks THIS repo's development
3. **`claude-pack/`** has different (older) commands than what's in `.claude/`
4. No clear separation between "what we ship" vs "what we use to develop"

## Design: Template-First with Symlinks

### Core Principle

> **Source of truth is in `templates/`. We symlink to it for actual use.**

This means:
- When we improve a command, we're improving what ships
- We're always testing the actual distributable
- Clear separation between template content and repo-specific content

### Proposed Structure

```
agentic-project-init/
│
├── templates/                    # THE DISTRIBUTABLE PACKAGE
│   ├── claude/                   # → becomes .claude/ in target projects
│   │   ├── commands/
│   │   │   ├── capture.md
│   │   │   ├── memorize.md
│   │   │   ├── recall.md
│   │   │   ├── review-compact.md
│   │   │   ├── project-find.md
│   │   │   └── project-manage.md
│   │   ├── hooks/
│   │   │   ├── capture.sh
│   │   │   ├── precompact-capture.sh
│   │   │   ├── parse-transcript.py
│   │   │   └── query-transcript.py
│   │   ├── agents/
│   │   │   └── recall.md
│   │   └── rules/
│   │       └── (project guidelines)
│   │
│   └── project/                  # → becomes .project/ in target projects
│       ├── README.md             # Workflow documentation
│       ├── CURRENT_WORK.md       # Template (mostly empty)
│       ├── EPIC_GUIDE.md
│       ├── epic_template.md
│       ├── backlog/
│       │   ├── README.md
│       │   └── BACKLOG.md
│       ├── active/
│       │   └── README.md
│       ├── completed/
│       │   ├── README.md
│       │   └── CHANGELOG.md
│       └── memories/
│           ├── SPEC.md           # Memory system spec
│           └── index.json        # Starts empty: {}
│
├── .claude/                      # THIS REPO uses symlinks
│   ├── commands -> ../templates/claude/commands
│   ├── hooks -> ../templates/claude/hooks
│   ├── agents -> ../templates/claude/agents
│   ├── settings.json             # THIS repo's settings (NOT symlinked)
│   └── settings.local.json       # Local overrides (gitignored)
│
├── .project/                     # THIS REPO's project management
│   ├── ... (actual work items, memories, etc.)
│   └── (NOT distributed - repo-specific)
│
├── scripts/
│   ├── init-project.sh           # Updated to use templates/
│   └── update-templates.sh
│
├── docs/
│   ├── STRUCTURE.md              # This design, for contributors
│   └── USAGE.md                  # How to use the templates
│
├── README.md                     # Updated for new structure
├── .gitignore
└── artifacts/                    # Legacy (gitignored)
```

### What Gets Distributed vs What Stays Local

| Path | Distributed? | Purpose |
|------|--------------|---------|
| `templates/` | YES | The actual package users install |
| `.claude/` | NO | Symlinks for this repo's development |
| `.project/` | NO | This repo's actual project tracking |
| `scripts/` | YES | Installation scripts |
| `docs/` | YES | Documentation |
| `artifacts/` | NO | Legacy/scratch (gitignored) |

### Migration Steps

1. **Create `templates/` directory structure**
2. **Merge commands**: Combine memory commands (from `.claude/commands/`) with project commands (from `claude-pack/commands/`)
3. **Move hooks**: Move `.claude/hooks/` to `templates/claude/hooks/`
4. **Create project template**: Move template files from `.project/` to `templates/project/`, keeping actual work items in `.project/`
5. **Set up symlinks**: Replace `.claude/` contents with symlinks to `templates/claude/`
6. **Update scripts**: Point `init-project.sh` to new `templates/` location
7. **Clean up**: Remove `claude-pack/`, update `.gitignore`

### Symlink Strategy Details

**.claude/commands -> ../templates/claude/commands**
- Symlink the entire directory
- Any file edits affect the template directly
- New commands added to template appear immediately

**.claude/hooks -> ../templates/claude/hooks**
- Same approach
- Hook scripts are tested as we use them

**.claude/settings.json** - NOT symlinked
- This file is repo-specific
- Contains project-specific MCP servers, model preferences, etc.
- Template can include a `settings.template.json` as reference

### How init-project.sh Changes

Current approach (submodule + symlinks):
```bash
git submodule add "$TEMPLATE_REPO_URL" "$SUBMODULE_PATH"
ln -s "../$SUBMODULE_PATH/claude-pack/commands" ".claude/commands"
```

Updated approach:
```bash
git submodule add "$TEMPLATE_REPO_URL" "$SUBMODULE_PATH"
ln -s "../$SUBMODULE_PATH/templates/claude/commands" ".claude/commands"
ln -s "../$SUBMODULE_PATH/templates/claude/hooks" ".claude/hooks"
ln -s "../$SUBMODULE_PATH/templates/claude/agents" ".claude/agents"
cp -r "$SUBMODULE_PATH/templates/project" .project
```

### Benefits

1. **Single source of truth**: `templates/` is what ships
2. **Eat our own dog food**: We use exactly what users will get
3. **Clear separation**: Dev artifacts (`.project/`) vs distributable (`templates/`)
4. **Easy updates**: Edit in `templates/`, changes apply everywhere via symlinks
5. **No confusion**: `templates/claude/` clearly becomes `.claude/` in target projects

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking symlinks | Scripts validate symlink targets before creating |
| Forgetting to commit template changes | Pre-commit hook could warn about uncommitted template changes |
| Confusing contributors | Clear docs in `CONTRIBUTING.md` |

## Open Questions

1. Should we keep `claude-pack/` as an alias/symlink to `templates/claude/` for backwards compatibility?
2. Should `templates/project/memories/` include sample memories as examples?
3. How to handle `settings.json` - template vs actual?
