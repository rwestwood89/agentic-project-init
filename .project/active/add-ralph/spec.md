# Spec: Add Ralph Loop to Global Setup

**Status:** Implementation Complete
**Owner:** Reid W
**Created:** 2026-02-08 09:10
**Complexity:** MEDIUM
**Branch:** dev

---

## Business Goals

### Why This Matters
The Ralph Wiggum Loop is a powerful autonomous coding pattern — it takes a concept file and produces a complete project scaffold with multi-pass design documents, specs, agent prompts, and a loop runner. Making it a first-class part of the agentic-project-init toolset means users who have run `setup-global.sh` can spin up Ralph projects from any git repository without manual path management or permissions issues.

### Success Criteria

- [ ] After running `setup-global.sh`, `ralph-init.sh` is available as a symlink at `~/.claude/scripts/ralph-init.sh`
- [ ] The script is executable and can be invoked directly from any git repo
- [ ] Running `uninstall-global.sh` cleanly removes the script symlink
- [ ] The README output during project init tells users what Ralph is and where to find it
- [ ] `setup-global.sh --dry-run` shows what it would do for the scripts directory

### Priority
Active work item — script already written, just needs integration into the install infrastructure.

---

## Problem Statement

### Current State
`ralph-init.sh` exists as a standalone script in `.project/active/add-ralph/`. It is not distributed as part of the `claude-pack/` and is not installed by `setup-global.sh`. Users must manually locate and invoke it.

### Desired Outcome
`ralph-init.sh` lives in `claude-pack/scripts/`, is symlinked to `~/.claude/scripts/` during global setup, is cleaned up during uninstall, and users are told about it when they initialize projects.

---

## Scope

### In Scope
1. Move `ralph-init.sh` from `.project/active/add-ralph/` to `claude-pack/scripts/`
2. Create the `~/.claude/scripts/` directory in `setup-global.sh`
3. Symlink `claude-pack/scripts/*` to `~/.claude/scripts/` during global setup (following existing pattern for commands/hooks/agents)
4. Ensure the symlinked script retains executable permissions
5. Update `uninstall-global.sh` to remove symlinks from `~/.claude/scripts/`
6. Update `init-project.sh` to handle vendoring of `scripts/` when `--include-claude` is used
7. Update the README and/or post-install output to document Ralph Loop — what it is and where to find it

### Out of Scope
- Modifying `ralph-init.sh` internal logic
- Creating a `/_my_ralph` slash command
- Adding `~/.claude/scripts/` to `$PATH`
- Per-project customization of Ralph templates
- Testing the Ralph Loop itself (it's already written and tested)

### Edge Cases & Considerations
- Symlinks preserve the execute bit of the source file, but the source file MUST have `chmod +x` set in the repo
- If the user already has a `~/.claude/scripts/` directory with files, setup must not clobber them (existing pattern: skip if exists)
- The `--include-claude` vendoring path needs to copy scripts and preserve `chmod +x`
- The uninstall script currently iterates `commands agents hooks skills rules` — needs `scripts` added

---

## Requirements

### Functional Requirements

1. **FR-1**: Move `ralph-init.sh` to `claude-pack/scripts/ralph-init.sh` as its canonical source location
2. **FR-2**: `setup-global.sh` MUST create `~/.claude/scripts/` directory and symlink all files from `claude-pack/scripts/` into it (same pattern as commands, hooks, etc.)
3. **FR-3**: `ralph-init.sh` MUST have the executable bit set (`chmod +x`) in the repository so symlinks inherit it
4. **FR-4**: `uninstall-global.sh` MUST remove symlinks from `~/.claude/scripts/` that point to the source repo
5. **FR-5**: `init-project.sh --include-claude` MUST copy `claude-pack/scripts/` to `.claude/scripts/` and preserve executable permissions (`cp -p` or explicit `chmod +x`)
6. **FR-6**: [INFERRED] `setup-global.sh --dry-run` MUST show the scripts directory creation and symlink operations (follows existing dry-run pattern)
7. **FR-7**: The post-install output (in `setup-global.sh` and/or `init-project.sh`) MUST tell users about Ralph — what it does and how to invoke it
8. **FR-8**: [INFERRED] The project `README.md` MUST be updated to document the `scripts/` directory under `claude-pack/`, including Ralph Loop in the feature set, and add Ralph usage to the Quick Start or a new section
9. **FR-9**: [INFERRED] `.hook-paths.json` metadata does NOT need updating — this is for hooks, not scripts

### Non-Functional Requirements

- The integration MUST follow the existing patterns exactly (symlink creation, dry-run support, error messages, color output) for consistency
- No new dependencies introduced — uses the same bash/git tooling already required

---

## Acceptance Criteria

### Core Functionality
- [ ] `claude-pack/scripts/ralph-init.sh` exists and is executable (`ls -la` shows `+x`)
- [ ] After running `setup-global.sh`, `~/.claude/scripts/ralph-init.sh` is a symlink pointing to `claude-pack/scripts/ralph-init.sh`
- [ ] The symlinked script is executable: `~/.claude/scripts/ralph-init.sh --help` works
- [ ] After running `uninstall-global.sh`, the `~/.claude/scripts/ralph-init.sh` symlink is removed
- [ ] `setup-global.sh --dry-run` shows `scripts/` directory creation and symlink operations without making changes
- [ ] `init-project.sh --include-claude` copies scripts to `.claude/scripts/` with executable permissions preserved

### Documentation & Output
- [ ] `setup-global.sh` output includes a "Setting up scripts..." section (matching style of "Setting up commands...")
- [ ] Post-install output mentions Ralph Loop and how to use it (e.g., `~/.claude/scripts/ralph-init.sh <project_name> <concept_file>`)
- [ ] `README.md` documents `claude-pack/scripts/` in the "What's Included" section
- [ ] `README.md` includes Ralph Loop usage instructions (invocation, prerequisites, what it produces)

### Quality & Integration
- [ ] Existing tests continue to pass
- [ ] The symlink pattern for scripts is identical to the pattern used for commands/hooks/agents (create_symlink function reused)
- [ ] No regressions in existing `setup-global.sh`, `uninstall-global.sh`, or `init-project.sh` behavior

---

## Related Artifacts

- **Source Script:** `.project/active/add-ralph/ralph-init.sh`
- **Design:** `.project/active/add-ralph/design.md` (to be created)
- **Setup Script:** `scripts/setup-global.sh` (will be modified)
- **Uninstall Script:** `scripts/uninstall-global.sh` (will be modified)
- **Init Script:** `scripts/init-project.sh` (will be modified)
- **README:** `README.md` (will be modified)

---

**Next Steps:** After approval, proceed to `/_my_design`
