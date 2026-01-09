# Spec: Simplified Setup System

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-01-09 10:11:06 PST
**Complexity:** HIGH
**Branch:** main

---

## Business Goals

### Why This Matters

The current submodule-based setup creates unnecessary complexity and git dependencies in target projects. Users must run `git submodule update --init` in every project, and the submodule appears in project history. This approach also doesn't handle projects that already have `.claude/` directories with existing commands.

A simplified setup system enables "clone once, use everywhere" - users clone this repository to a permanent location, run a one-time global setup, and then can initialize any project with a simple script. Updates propagate automatically via symlinks when users `git pull` the source repository.

### Success Criteria

- [ ] Users can clone the repository to any location and use it across all projects
- [ ] One-time global setup installs commands/agents/hooks/skills to `~/.claude/`
- [ ] Per-project setup only handles `.project/` directory (fast, minimal)
- [ ] `git pull` in source repo updates all projects automatically (via symlinks)
- [ ] Projects with existing `.claude/` directories work without conflicts (via `_my_` prefix)
- [ ] Option exists for projects that want vendored (copied) commands
- [ ] Clean uninstall path for both global and per-project setups

### Priority

P0 - Critical infrastructure that affects all users and projects.

---

## Problem Statement

### Current State

The current setup uses git submodules:

```
target-project/
├── claude-templates/           # Git submodule (problematic)
└── .claude/
    ├── commands/ -> symlink    # Entire directory symlinked
    ├── hooks/ -> symlink
    └── ...
```

**Problems:**
1. Submodule complexity - requires `git submodule update --init` in every project
2. Directory-level symlinks can't merge with existing `.claude/` content
3. Command conflicts if project has same-named commands (e.g., `/commit`)
4. All-or-nothing approach - can't selectively use commands
5. Creates git dependency in target projects

### Desired Outcome

A two-tier setup system:

1. **Global setup (one-time):** Symlinks commands/agents/hooks/skills to `~/.claude/` where Claude Code natively supports user-level configuration

2. **Per-project setup (each project):** Copies `.project/` template for project-specific state (research, specs, designs, transcripts)

This approach:
- Eliminates submodule dependency
- Uses Claude Code's native user-level configuration
- Avoids command conflicts via `_my_` prefix
- Enables single-point updates via `git pull`
- Provides vendoring option for projects that need it

---

## Scope

### In Scope

1. **Command Renaming**
   - Rename all commands with `_my_` prefix
   - Update all cross-references between commands
   - Update internal documentation references

2. **Global Setup Script (`setup-global.sh`)**
   - Create symlinks in `~/.claude/` directories
   - Configure hooks in `~/.claude/settings.json`
   - Handle existing files gracefully
   - Provide clear output and next steps

3. **Per-Project Setup Script (`init-project.sh`)**
   - Copy `project-pack/` to `.project/`
   - Support `--no-track` flag for gitignore mode
   - Support `--include-claude` flag for vendoring
   - Handle existing `.project/` with merge strategy
   - Configure project-local hooks when vendoring

4. **Uninstall Scripts**
   - Global uninstall (`uninstall-global.sh`)
   - Per-project uninstall (`uninstall-project.sh`)

5. **Documentation Updates**
   - README.md with new workflow
   - Migration guide for existing users

### Out of Scope

- Windows support (symlinks require admin/developer mode)
- Network drive support (symlinks may not work)
- Auto-migration from submodule-based setup
- GUI or interactive setup wizard
- Per-project selective command enabling (use global or vendor all)

### Edge Cases & Considerations

1. **Existing `~/.claude/` content:** Global setup MUST preserve existing user files, only add new symlinks
2. **Existing `.project/` directory:** Per-project setup MUST merge missing components, not overwrite
3. **Existing `.claude/` in target project:** Not modified by per-project setup (global handles via `~/.claude/`)
4. **Hook path resolution:** Hooks use relative `.project/` paths which resolve to current working directory
5. **Broken symlinks:** If source repo is moved/deleted, symlinks break - scripts should detect this
6. **Command invocation change:** Users must use `/_my_research` instead of `/research`

---

## Requirements

### Functional Requirements

#### FR-1: Command Renaming with `_my_` Prefix

> Requirements from user's request

1. **FR-1.1**: All commands in `claude-pack/commands/` MUST be renamed with `_my_` prefix
2. **FR-1.2**: Hyphens in command names MUST be converted to underscores (e.g., `code-review.md` → `_my_code_review.md`)
3. **FR-1.3**: All cross-references MUST be updated to use new command names. This includes:
   - References within command files (e.g., `/spec` → `/_my_spec`)
   - "Related Commands" sections at the bottom of command files
   - References in `README.md`
   - References in `CLAUDE.md` (if any)
   - References in any other documentation files
4. **FR-1.4**: The `example-command.md` SHOULD be renamed to `_my_example_command.md` for consistency
5. **FR-1.5**: Agents MUST NOT be renamed (keep `recall.md`, `example-agent.md`)

**Command Rename Mapping:**

| Current | New |
|---------|-----|
| `research.md` | `_my_research.md` |
| `spec.md` | `_my_spec.md` |
| `design.md` | `_my_design.md` |
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
| `example-command.md` | `_my_example_command.md` |

#### FR-2: Global Setup Script (`setup-global.sh`)

> Requirements from user's request and research

1. **FR-2.1**: Script MUST be located at `scripts/setup-global.sh`
2. **FR-2.2**: Script MUST create `~/.claude/` directory structure if not exists:
   - `~/.claude/commands/`
   - `~/.claude/agents/`
   - `~/.claude/hooks/`
   - `~/.claude/skills/`
   - `~/.claude/rules/`
3. **FR-2.3**: Script MUST create file-level symlinks (not directory-level) for each file in:
   - `claude-pack/commands/*.md` → `~/.claude/commands/`
   - `claude-pack/agents/*.md` → `~/.claude/agents/`
   - `claude-pack/hooks/*` → `~/.claude/hooks/`
   - `claude-pack/skills/*` → `~/.claude/skills/`
   - `claude-pack/rules/*.md` → `~/.claude/rules/`
4. **FR-2.4**: Script MUST use absolute paths for symlink targets
5. **FR-2.5**: Script MUST skip files that already exist at target location (preserve user files)
6. **FR-2.6**: Script MUST configure hooks in `~/.claude/settings.json`:
   - Merge with existing settings if present
   - Add `PreCompact` hook configuration
   - Use absolute paths to `~/.claude/hooks/` scripts
7. **FR-2.7**: Script MUST store source repository location in `~/.claude/.agentic-pack-source` for reference
8. **FR-2.8**: Script MUST store version in `~/.claude/.agentic-pack-version` for future migration detection
9. **FR-2.9**: Script MUST output clear success/skip messages for each file
10. **FR-2.10**: Script MUST output next steps after completion

**FR-2.11: `--dry-run` Flag**

1. When `--dry-run` is specified, script MUST show what actions would be taken without executing them
2. Script MUST clearly label output as "[DRY RUN]"
3. Script MUST list each symlink that would be created
4. Script MUST show settings.json changes that would be made
5. Script MUST NOT modify any files or create any symlinks in dry-run mode

#### FR-3: Per-Project Setup Script (`init-project.sh`)

> Requirements from user's request

1. **FR-3.1**: Script MUST be located at `scripts/init-project.sh`
2. **FR-3.2**: Script MUST be run from within the target project directory
3. **FR-3.3**: Script MUST copy `project-pack/` contents to `.project/` in target
4. **FR-3.4**: Script MUST handle existing `.project/` with merge strategy (add missing, don't overwrite)
5. **FR-3.5**: Script MUST ensure required subdirectories exist:
   - `.project/research/`
   - `.project/reports/`
   - `.project/memories/`
   - `.project/active/`
   - `.project/completed/`
   - `.project/backlog/`

**FR-3.6: `--no-track` Flag**

1. When `--no-track` is specified, script MUST add `.project` to `.gitignore`
2. Script MUST check if pattern already exists before adding
3. Script MUST NOT modify `.gitignore` when flag is not specified

**FR-3.7: `--include-claude` Flag**

1. When `--include-claude` is specified, script MUST COPY (not symlink) `claude-pack/` contents to `.claude/` in target project
2. Script MUST create `.claude/` directory structure:
   - `.claude/commands/`
   - `.claude/agents/`
   - `.claude/hooks/`
   - `.claude/skills/`
   - `.claude/rules/`
3. Script MUST copy all files from source `claude-pack/` to target `.claude/`
4. Script MUST configure hooks in `.claude/settings.json` with project-local paths
5. Script MUST handle existing `.claude/` content (skip existing files, add new)

**FR-3.8: Mutual Exclusion**

1. Script MUST error out if both `--no-track` and `--include-claude` are specified
2. Error message MUST clearly explain that these options are mutually exclusive
3. Error message SHOULD explain rationale: vendored commands should be tracked in project

**FR-3.9: Source Location Handling**

1. Script MUST read source location from `~/.claude/.agentic-pack-source` if it exists
2. Script MUST accept `--source <path>` argument to override
3. Script MUST error with helpful message if source cannot be determined

**FR-3.10: `--dry-run` Flag**

1. When `--dry-run` is specified, script MUST show what actions would be taken without executing them
2. Script MUST clearly label output as "[DRY RUN]"
3. Script MUST list each file/directory that would be created or copied
4. Script MUST show .gitignore changes that would be made (if `--no-track`)
5. Script MUST show .claude/ files that would be copied (if `--include-claude`)
6. Script MUST NOT modify any files or create any directories in dry-run mode

#### FR-4: Global Uninstall Script (`uninstall-global.sh`)

> Requirements from user's request

1. **FR-4.1**: Script MUST be located at `scripts/uninstall-global.sh`
2. **FR-4.2**: Script MUST remove all symlinks from `~/.claude/` that point to this repository
3. **FR-4.3**: Script MUST NOT remove files that are not symlinks to this repository
4. **FR-4.4**: Script MUST NOT remove user-created files
5. **FR-4.5**: Script MUST remove hook configuration from `~/.claude/settings.json` (if added by setup)
6. **FR-4.6**: Script MUST remove `~/.claude/.agentic-pack-source` file
7. **FR-4.7**: Script MUST remove `~/.claude/.agentic-pack-version` file
8. **FR-4.8**: Script MUST output summary of removed items

#### FR-5: Per-Project Uninstall Script (`uninstall-project.sh`)

> [INFERRED] Based on user request for uninstall scripts

1. **FR-5.1**: Script MUST be located at `scripts/uninstall-project.sh`
2. **FR-5.2**: Script MUST be run from within the target project directory
3. **FR-5.3**: Script MUST prompt for confirmation before removing `.project/`
4. **FR-5.4**: Script MUST support `--force` flag to skip confirmation
5. **FR-5.5**: If `--include-claude` was used, script MUST offer to remove `.claude/` vendored content
6. **FR-5.6**: Script MUST remove `.project` entry from `.gitignore` if present
7. **FR-5.7**: Script MUST NOT remove `.claude/` content that wasn't vendored by this tool

#### FR-6: Documentation Updates

> [INFERRED] Required for usability

1. **FR-6.1**: README.md MUST be updated with new setup workflow
2. **FR-6.2**: README.md MUST document all script options and flags
3. **FR-6.3**: README.md MUST include migration guide for existing submodule users
4. **FR-6.4**: README.md MUST explain the `_my_` prefix and command invocation

### Non-Functional Requirements

1. **NFR-1**: All scripts MUST be POSIX-compliant shell (#!/bin/bash)
2. **NFR-2**: Scripts MUST use colored output for clarity (green=success, yellow=warning, red=error)
3. **NFR-3**: Scripts MUST exit with non-zero status on error
4. **NFR-4**: Scripts MUST be idempotent (safe to run multiple times)
5. **NFR-5**: Scripts MUST not require sudo/root permissions
6. **NFR-6**: Scripts MUST work on Linux and macOS

---

## Acceptance Criteria

### Core Functionality

- [ ] All 16 commands renamed with `_my_` prefix
- [ ] All cross-references updated (commands, README.md, CLAUDE.md, "Related Commands" sections)
- [ ] `setup-global.sh` creates symlinks in `~/.claude/`
- [ ] `setup-global.sh` configures hooks in `~/.claude/settings.json`
- [ ] `setup-global.sh` stores version in `~/.claude/.agentic-pack-version`
- [ ] `setup-global.sh --dry-run` shows actions without executing
- [ ] `init-project.sh` copies `.project/` to target
- [ ] `init-project.sh --no-track` adds `.project` to `.gitignore`
- [ ] `init-project.sh --include-claude` copies `claude-pack/` to `.claude/`
- [ ] `init-project.sh --dry-run` shows actions without executing
- [ ] `init-project.sh` errors when both `--no-track` and `--include-claude` specified
- [ ] `uninstall-global.sh` removes symlinks from `~/.claude/`
- [ ] `uninstall-global.sh` removes version and source tracking files
- [ ] `uninstall-project.sh` removes `.project/` from target

### Integration

- [ ] Commands work correctly when invoked as `/_my_<command>`
- [ ] Hooks execute correctly from `~/.claude/hooks/`
- [ ] Hooks write to project-local `.project/transcripts/`
- [ ] Agents work correctly from `~/.claude/agents/`
- [ ] User-level commands show "(user)" suffix in `/help`

### Edge Cases

- [ ] Setup preserves existing `~/.claude/` content
- [ ] Setup preserves existing `.project/` content (merge strategy)
- [ ] Uninstall only removes content from this tool
- [ ] Scripts handle missing directories gracefully
- [ ] Scripts detect and report broken symlinks

### Quality

- [ ] All scripts are idempotent
- [ ] All scripts have helpful error messages
- [ ] All scripts use colored output
- [ ] README.md documents complete workflow
- [ ] Existing tests continue to pass

---

## Technical Notes

### Claude Code Scope Hierarchy

Claude Code has a configuration scope hierarchy (highest to lowest priority):

1. **Managed** - System-level configuration
2. **Local** - `.claude/*.local.*` files
3. **Project** - `.claude/` directory
4. **User** - `~/.claude/` directory

This means:
- User-level commands in `~/.claude/commands/` are available in all projects
- Project-level commands in `.claude/commands/` override user-level commands of same name
- The `_my_` prefix ensures no conflicts with project commands

### Hook Path Resolution

Hooks configured in `~/.claude/settings.json` execute in the context of the current project directory. When a hook script references `.project/transcripts/`, this resolves to the current project's `.project/` directory - exactly what we want.

### Symlink Strategy

File-level symlinks (not directory-level) enable:
- Preserving existing project commands
- Selective addition of new files
- Individual gitignore patterns if needed
- Graceful handling of conflicts

---

## Related Artifacts

- **Research:** `.project/research/20260109-095026_simplified-symlink-setup.md`
- **Research:** `.project/research/20260109-100205_user-level-claude-symlink-alternative.md`
- **Design:** `.project/active/simplified-setup-system/design.md` (to be created)
- **Current Script:** `scripts/init-project.sh` (to be replaced)

---

## Open Questions (Resolved)

| Question | Resolution |
|----------|------------|
| Hook configuration for `--include-claude`? | Automatically configure project-local `.claude/settings.json` |
| Update cross-references after rename? | Yes, include in scope |
| Cross-reference scope? | All locations: command files, README.md, CLAUDE.md, "Related Commands" sections |
| Prefix agents with `_my_`? | No, keep original names |
| Include uninstall scripts? | Yes, both global and per-project |
| Error handling for conflicting flags? | Error out with clear message |
| Add `--dry-run` flag? | Yes, for both `setup-global.sh` and `init-project.sh` |
| Version tracking? | Yes, store in `~/.claude/.agentic-pack-version` for migration detection |

---

**Next Steps:** After approval, proceed to `/_my_design`
