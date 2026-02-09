# Design: Add Ralph Loop to Global Setup

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-02-08
**Branch:** dev

## Overview

Integrate `ralph-init.sh` into the existing `claude-pack/` distribution system so it is symlinked to `~/.claude/scripts/` during global setup, cleaned up during uninstall, vendored during `--include-claude`, and documented in the README.

## Related Artifacts

- **Spec:** `.project/active/add-ralph/spec.md`
- **Source Script:** `.project/active/add-ralph/ralph-init.sh`
- **Setup Script:** `scripts/setup-global.sh`
- **Uninstall Script:** `scripts/uninstall-global.sh`
- **Init Script:** `scripts/init-project.sh`
- **README:** `README.md`

## Research Findings

### Existing Patterns

All five content types (commands, agents, hooks, skills, rules) follow the same pattern across all three scripts:

**setup-global.sh:**
- Directory creation: `for subdir in commands agents hooks skills rules` at line 93 — creates `~/.claude/$subdir/`
- Individual symlink blocks (lines 97–143): Each type has its own block with `echo "Setting up {type}..."`, a `for file in` glob, and `create_symlink` calls
- Glob patterns vary: commands/rules use `*.md`, hooks use `*`, skills/rules wrap in `if [ -d ]` guard

**uninstall-global.sh:**
- Single loop: `for subdir in commands agents hooks skills rules` at line 54 — calls `remove_symlinks` for each

**init-project.sh (vendoring):**
- Two identical loops for `commands agents hooks skills rules`: directory creation (line 225), file copying (line 234)
- Copy uses bare `cp "$file" "$target"` (line 253) — does NOT preserve permissions
- Note: This is an existing bug for hook scripts too, but out of scope to fix here. For scripts, we'll use `cp -p` to preserve `+x`.

### Permission Handling

- Source hooks in `claude-pack/hooks/` have `+x` set (verified: `capture.sh`, `precompact-capture.sh`)
- Symlinks inherit source permissions — no issue for global setup
- Vendoring (`cp`) loses permissions — need `cp -p` for scripts specifically

### Scope of Changes

5 files to touch, 1 file to move:

| File | Change Type | Complexity |
|------|------------|------------|
| `claude-pack/scripts/ralph-init.sh` | New (moved from `.project/active/add-ralph/`) | Trivial — git mv + chmod |
| `scripts/setup-global.sh` | Modify | Small — add `scripts` to dir loop + add symlink block |
| `scripts/uninstall-global.sh` | Modify | Trivial — add `scripts` to loop list |
| `scripts/init-project.sh` | Modify | Small — add `scripts` to two vendoring loops + `cp -p` |
| `README.md` | Modify | Moderate — new section for Ralph Loop |

## Proposed Design

### 1. Move Script to `claude-pack/scripts/`

**Action:** `git mv .project/active/add-ralph/ralph-init.sh claude-pack/scripts/ralph-init.sh`

Create the `claude-pack/scripts/` directory. Ensure `+x` is set:

```bash
mkdir -p claude-pack/scripts
git mv .project/active/add-ralph/ralph-init.sh claude-pack/scripts/ralph-init.sh
chmod +x claude-pack/scripts/ralph-init.sh
```

### 2. Update `scripts/setup-global.sh`

**Two changes:**

**(a) Add `scripts` to the directory creation loop** (line 93):

```bash
# Before:
for subdir in commands agents hooks skills rules; do

# After:
for subdir in commands agents hooks skills rules scripts; do
```

**(b) Add a symlink block for scripts** — insert after the rules block (after line 143), before the "Configure settings.json" section. Follow the hooks pattern (glob `*`, not `*.md`) with an `if [ -d ]` guard:

```bash
# Symlink scripts
echo ""
echo "Setting up scripts..."
if [ -d "$CLAUDE_PACK/scripts" ]; then
    for file in "$CLAUDE_PACK"/scripts/*; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        create_symlink "$file" "$TARGET_DIR/scripts/$filename" "$filename"
    done
fi
```

**(c) Update the post-install "Next steps" output** (after line 240) — add Ralph Loop usage info:

```bash
echo ""
echo "Ralph Loop (autonomous project scaffolding):"
echo "  ~/.claude/scripts/ralph-init.sh <project_name> <concept_file>"
echo "  Run from any git repo with a concept markdown file."
```

### 3. Update `scripts/uninstall-global.sh`

**One change** — add `scripts` to the subdir loop (line 54):

```bash
# Before:
for subdir in commands agents hooks skills rules; do

# After:
for subdir in commands agents hooks skills rules scripts; do
```

### 4. Update `scripts/init-project.sh`

**Three changes in the `copy_claude_pack` function:**

**(a) Add `scripts` to the directory creation loop** (line 225):

```bash
# Before:
for subdir in commands agents hooks skills rules; do

# After:
for subdir in commands agents hooks skills rules scripts; do
```

**(b) Add `scripts` to the file copy loop** (line 234):

```bash
# Before:
for subdir in commands agents hooks skills rules; do

# After:
for subdir in commands agents hooks skills rules scripts; do
```

**(c) Use `cp -p` for scripts to preserve permissions** (around line 253). Replace the bare `cp` with permission-aware copy for the `scripts` subdir:

```bash
# Replace:
cp "$file" "$target"

# With:
cp -p "$file" "$target"
```

Note: Using `cp -p` for all subdirs (not just scripts) is safe and actually fixes an existing latent bug where vendored hook scripts lose their `+x` bit. This is a single-character change (`cp` → `cp -p`) that benefits all executable content.

### 5. Update `README.md`

**Three additions:**

**(a) Add `scripts/` to the "What's Included" section** (after the rules bullet, around line 15):

```markdown
- **scripts/** - Standalone tools (Ralph Loop for autonomous project scaffolding)
```

**(b) Add Ralph Loop section** — new section after "Command Reference" (after line 105). Keep it concise:

```markdown
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
```

**(c) Add `scripts/` to the directory tree diagram** (around line 193):

```markdown
~/.claude/                       (symlinked, shared globally)
├── commands/
├── agents/
├── hooks/
├── skills/
├── rules/
├── scripts/
│   └── ralph-init.sh -> /path/to/agentic-project-init/claude-pack/scripts/ralph-init.sh
└── settings.json
```

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `cp -p` change affects other vendored files | Low — preserving permissions is strictly better than losing them | Only adds `-p` flag; doesn't change behavior for non-executable files |
| User has existing `~/.claude/scripts/` with conflicting files | Low — `create_symlink` already skips existing files | Existing pattern handles this correctly |
| Git doesn't preserve execute bit on clone | Medium — script would be installed without `+x` | Ensure `chmod +x` is committed. Git tracks the execute bit in its tree objects, so this persists across clones. Verify with `git ls-files -s` after commit. |

## Integration Strategy

This follows the established pattern exactly — adding `scripts` as a sixth content type alongside commands, agents, hooks, skills, and rules. The only deviation is `cp -p` in vendoring (which is an improvement, not a divergence).

The changes are purely additive — no existing behavior is modified except the harmless `cp` → `cp -p` upgrade.

## Validation Approach

### Manual Verification Steps

1. **After implementation:**
   - `ls -la claude-pack/scripts/ralph-init.sh` — confirm `+x`
   - `git ls-files -s claude-pack/scripts/ralph-init.sh` — confirm mode `100755`

2. **Global setup test:**
   - `./scripts/setup-global.sh --dry-run` — verify scripts section appears
   - `./scripts/setup-global.sh` — verify `~/.claude/scripts/ralph-init.sh` exists as symlink
   - `~/.claude/scripts/ralph-init.sh --help` — verify it runs

3. **Uninstall test:**
   - `./scripts/uninstall-global.sh` — verify symlink removed
   - `ls ~/.claude/scripts/` — directory may remain (matches existing behavior for empty dirs)

4. **Vendoring test:**
   - Create temp project, run `init-project.sh --include-claude`
   - `ls -la .claude/scripts/ralph-init.sh` — confirm file exists with `+x`

5. **README review:**
   - Visual inspection of new sections for clarity and accuracy

---

**Next Step:** After approval → `/_my_plan` or `/_my_implement`
