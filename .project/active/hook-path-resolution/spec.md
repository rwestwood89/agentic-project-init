# Spec: Hook Path Resolution for Multi-Level Installation

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-01-18 12:53
**Complexity:** MEDIUM
**Branch:** TBD

---

## Business Goals

### Why This Matters
When users install this package at the user-level (`~/.claude/`) and then initialize a new project, commands like `/_my_capture` fail because they reference hooks using relative paths (`.claude/hooks/...`) that assume the hooks exist in the project directory. This breaks the primary installation workflow where users run `setup-global.sh` once and then use the commands across multiple projects.

### Success Criteria
- [ ] Commands work when package is installed at user-level only
- [ ] Commands work when package is installed at project-level only
- [ ] Commands work when package is installed at both levels (project takes precedence)
- [ ] Existing installations continue to work after update

### Priority
High - this is a fundamental usability issue that prevents the package from working in its intended installation mode.

---

## Problem Statement

### Current State
Commands in `claude-pack/commands/` reference hook scripts using relative paths like:
- `.claude/hooks/query-transcript.py --list --json`
- `.claude/hooks/parse-transcript.py <transcript-path>`

These paths only work when:
1. Running from the development repo (where `.claude/hooks/` is a symlink to `claude-pack/hooks/`)
2. Running from a project with `--include-claude` flag (vendored copy)

They fail when:
- Package is installed globally via `setup-global.sh`
- User initializes a new project that doesn't have `.claude/hooks/` locally

### Desired Outcome
Commands resolve hook paths dynamically, checking project-level first, then falling back to user-level. The resolution is determined at install time and stored in a config file that commands can reference.

---

## Scope

### In Scope
- Config file to store resolved hook paths at install time
- Update `setup-global.sh` to write config with absolute paths
- Update `init-project.sh` to write/update config with project paths taking precedence
- Update affected commands to use config-based paths instead of relative paths
- Update settings.json hook references to use resolved paths

### Out of Scope
- Changing the overall installation architecture (global vs project symlinks)
- Modifying how `.project/` state is handled
- Changing the development repo's symlink structure
- Adding new commands or hooks

### Edge Cases & Considerations
- User runs command before any installation (no config exists) - SHOULD show helpful error
- User updates global installation after project init - project config SHOULD still take precedence
- User removes project-level installation - SHOULD fall back to global if available
- Config file gets corrupted or deleted - SHOULD be regenerable via install scripts

---

## Requirements

### Functional Requirements

1. **FR-1**: A config file MUST be created/updated during installation that stores absolute paths to hook scripts

2. **FR-2**: The config file MUST be located at a predictable location that commands can reference:
   - Global config: `~/.claude/.hook-paths.json` (or similar)
   - Project config: `.claude/.hook-paths.json` (when project-level install exists)

3. **FR-3**: Commands MUST check for project-level config first, then fall back to user-level config

4. **FR-4**: `setup-global.sh` MUST write the global config with absolute paths to `claude-pack/hooks/`

5. **FR-5**: `init-project.sh` MUST write a project-level config when `--include-claude` is used (vendored hooks)

6. **FR-6**: The following commands MUST be updated to use config-based paths:
   - `_my_capture.md` (references `query-transcript.py`)
   - `_my_memorize.md` (references `parse-transcript.py`)
   - `_my_recall.md` (references `query-transcript.py`)

7. **FR-7**: Settings hook configuration MUST use resolved paths or a resolution mechanism

8. **FR-8**: [INFERRED] Uninstall scripts SHOULD remove the corresponding config files

### Non-Functional Requirements

- **NFR-1**: Path resolution SHOULD NOT add noticeable latency to command execution
- **NFR-2**: Config format SHOULD be simple and human-readable (JSON)

---

## Acceptance Criteria

### Core Functionality
- [ ] Global-only install: `/_my_capture` works in a new project after `setup-global.sh`
- [ ] Project-only install: `/_my_capture` works with `--include-claude` flag
- [ ] Both installed: Project hooks are used over global hooks
- [ ] Config file is created by `setup-global.sh` at `~/.claude/.hook-paths.json`
- [ ] Config file contains absolute paths to all hook scripts

### Quality & Integration
- [ ] Existing tests continue to pass
- [ ] Commands fail gracefully with helpful message when no config exists
- [ ] Uninstall scripts clean up config files

---

## Config File Format

```json
{
  "version": 1,
  "resolved_at": "2026-01-18T12:53:00Z",
  "hooks": {
    "query-transcript": "/absolute/path/to/query-transcript.py",
    "parse-transcript": "/absolute/path/to/parse-transcript.py",
    "capture": "/absolute/path/to/capture.sh",
    "precompact-capture": "/absolute/path/to/precompact-capture.sh"
  }
}
```

---

## Affected Files

### Scripts to Modify
- `scripts/setup-global.sh` - Write global config
- `scripts/init-project.sh` - Write project config (when vendoring)
- `scripts/uninstall-global.sh` - Remove global config
- `scripts/uninstall-project.sh` - Remove project config

### Commands to Modify
- `claude-pack/commands/_my_capture.md`
- `claude-pack/commands/_my_memorize.md`
- `claude-pack/commands/_my_recall.md`

### Config to Modify
- `.claude/settings.json` - Hook command paths

---

## Related Artifacts

- **Design:** `.project/active/hook-path-resolution/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`
