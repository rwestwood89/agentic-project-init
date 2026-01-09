# Implementation Plan: Simplified Setup System

**Status:** Complete
**Created:** 2026-01-09
**Last Updated:** 2026-01-09

## Source Documents
- **Spec:** `.project/active/simplified-setup-system/spec.md`
- **Design:** `.project/active/simplified-setup-system/design.md` ← See here for component details, dependencies, architecture

## Implementation Strategy

**Phasing Rationale:**
Commands must be renamed first (foundation for all scripts), then global setup (primary entry point), then per-project init (depends on global metadata), then uninstall (cleanup), then docs (must document complete system).

**Overall Validation Approach:**
- Each phase has manual shell-based validation
- Idempotency tested by running scripts twice
- Edge cases tested explicitly (existing files, missing jq, etc.)

---

## Phase 1: Command Renaming + Cross-Reference Updates

### Goal
Rename all 16 commands with `_my_` prefix and update all cross-references throughout the codebase. This is the foundation - all subsequent scripts depend on the new command names.

### Test Stencil (Write This First)
```bash
# Verification script - run after renaming
# test_rename.sh

# Check all commands have _my_ prefix
echo "Checking command files..."
for f in claude-pack/commands/*.md; do
    basename=$(basename "$f")
    if [[ ! "$basename" =~ ^_my_ ]] && [[ "$basename" != "example-command.md" ]]; then
        echo "FAIL: $basename missing _my_ prefix"
        exit 1
    fi
done
echo "PASS: All commands have _my_ prefix"

# Check no old-style references remain
echo "Checking cross-references..."
if grep -rE "^[^#]*/(research|spec|design|plan|implement|code-review|code-quality|git-manage|project-manage|project-find|quick-edit|capture|recall|memorize|review-compact)[^_]" claude-pack/ --include="*.md" --include="*.sh" --include="*.py" | grep -v "_my_"; then
    echo "FAIL: Found old-style references"
    exit 1
fi
echo "PASS: No old-style references found"
```

### Changes Required

**See `design.md` for:**
- Full rename mapping → `design.md#component-1-command-renaming`
- Cross-reference update pattern → `design.md#component-1-command-renaming`
- List of files requiring updates → `design.md#command-cross-references`

**Specific file changes:**

#### 1. Rename Command Files
**Location:** `claude-pack/commands/`

- [x] `research.md` → `_my_research.md`
- [x] `spec.md` → `_my_spec.md`
- [x] `design.md` → `_my_design.md`
- [x] `plan.md` → `_my_plan.md`
- [x] `implement.md` → `_my_implement.md`
- [x] `code-review.md` → `_my_code_review.md`
- [x] `code-quality.md` → `_my_code_quality.md`
- [x] `git-manage.md` → `_my_git_manage.md`
- [x] `project-manage.md` → `_my_project_manage.md`
- [x] `project-find.md` → `_my_project_find.md`
- [x] `quick-edit.md` → `_my_quick_edit.md`
- [x] `capture.md` → `_my_capture.md`
- [x] `recall.md` → `_my_recall.md`
- [x] `memorize.md` → `_my_memorize.md`
- [x] `review-compact.md` → `_my_review_compact.md`
- [x] `example-command.md` → `_my_example_command.md`

#### 2. Update Cross-References in Command Files
**Location:** `claude-pack/commands/_my_*.md`

For each renamed command file:
- [x] Update internal `/command` references to `/_my_command`
- [x] Update "Related Commands" sections at bottom of files

#### 3. Update Hook Files
**Files:**
- [x] `claude-pack/hooks/capture.sh` - Update `/memorize` reference (line ~74)
- [x] `claude-pack/hooks/query-transcript.py` - Update `/memorize` reference (line ~312)

#### 4. Update Documentation Files
- [x] `claude-pack/claude-md-checklist.md` - Update all command references
- [x] `claude-pack/agents/recall.md` - No changes needed (no command references)

### Validation (How to Verify This Phase)

**Automated:**
- [x] Run verification script above → All checks pass
- [x] `grep -r "/research" claude-pack/ --include="*.md" | grep -v "_my_"` → No results
- [x] `ls claude-pack/commands/` → All files start with `_my_`

**Manual:**
- [x] Open 3-4 command files, verify "Related Commands" sections updated
- [x] Check capture.sh has `/_my_memorize` not `/memorize`

**What We Know Works After This Phase:**
All commands have consistent `_my_` naming, all internal references are updated, ready for symlinking.

---

## Phase 2: Global Setup Script (`setup-global.sh`)

### Goal
Create the one-time global installation script that symlinks commands to `~/.claude/`. This is the primary user entry point.

### Test Stencil (Write This First)
```bash
# test_global_setup.sh

# Setup: Clean test environment
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

# Test 1: Fresh install
./scripts/setup-global.sh
[ -L "$HOME/.claude/commands/_my_research.md" ] || { echo "FAIL: symlink not created"; exit 1; }
[ -f "$HOME/.claude/settings.json" ] || { echo "FAIL: settings.json not created"; exit 1; }
[ -f "$HOME/.claude/.agentic-pack-source" ] || { echo "FAIL: source file not created"; exit 1; }
echo "PASS: Fresh install"

# Test 2: Idempotent (run again)
./scripts/setup-global.sh
echo "PASS: Idempotent run"

# Test 3: Dry run
./scripts/setup-global.sh --dry-run 2>&1 | grep -q "DRY RUN" || { echo "FAIL: dry run not working"; exit 1; }
echo "PASS: Dry run"

# Cleanup
rm -rf "$TEST_HOME"
```

### Changes Required

**See `design.md` for:**
- Full script implementation → `design.md#component-2-global-setup-script`
- Directory structure → `design.md#architecture-overview`
- Hook configuration format → `design.md#component-2-global-setup-script`

**Specific file changes:**

#### 1. Create Setup Script
**File:** `scripts/setup-global.sh` (NEW)

- [x] Create file with implementation from `design.md#component-2`
- [x] Add shebang and `set -e`
- [x] Add color definitions (reuse from existing `init-project.sh:5-9`)
- [x] Add argument parsing for `--dry-run`
- [x] Add `create_symlink()` helper function
- [x] Add `create_dir()` helper function
- [x] Add directory creation loop for commands/agents/hooks/skills/rules
- [x] Add symlink creation loops for each directory
- [x] Add `configure_hooks()` function for settings.json
- [x] Add metadata file writing (.agentic-pack-source, .agentic-pack-version)
- [x] Add success message and next steps
- [x] Make executable: `chmod +x scripts/setup-global.sh`

### Validation (How to Verify This Phase)

**Automated:**
- [x] `./scripts/setup-global.sh --dry-run` → Shows actions without executing
- [x] `ls -la ~/.claude/commands/` → Shows symlinks to source
- [x] `cat ~/.claude/settings.json` → Shows hook configuration
- [x] `cat ~/.claude/.agentic-pack-source` → Shows source path

**Manual:**
- [x] Run on clean system (backup ~/.claude first)
- [x] Verify symlinks point to correct absolute paths
- [x] Run again, verify "already exists" messages appear
- [x] Test with pre-existing ~/.claude/commands/foo.md (should be preserved)

**What We Know Works After This Phase:**
Global symlink installation works, settings.json configured, metadata tracked, idempotent.

---

## Phase 3: Per-Project Setup Script (`init-project.sh`)

### Goal
Replace the existing submodule-based script with the new simplified version that copies `.project/` and optionally vendors `.claude/`.

### Test Stencil (Write This First)
```bash
# test_init_project.sh

# Setup: Create temp project
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init

# Test 1: Basic init
/path/to/scripts/init-project.sh --source /path/to/agentic-project-init
[ -d ".project" ] || { echo "FAIL: .project not created"; exit 1; }
[ -d ".project/research" ] || { echo "FAIL: research dir missing"; exit 1; }
echo "PASS: Basic init"

# Test 2: --no-track
/path/to/scripts/init-project.sh --source /path/to/agentic-project-init --no-track
grep -q ".project" .gitignore || { echo "FAIL: .gitignore not updated"; exit 1; }
echo "PASS: --no-track"

# Test 3: --include-claude
rm -rf .project .claude .gitignore
/path/to/scripts/init-project.sh --source /path/to/agentic-project-init --include-claude
[ -d ".claude/commands" ] || { echo "FAIL: .claude not created"; exit 1; }
[ -f ".claude/.agentic-pack-vendored" ] || { echo "FAIL: vendor marker missing"; exit 1; }
echo "PASS: --include-claude"

# Test 4: Mutual exclusion error
/path/to/scripts/init-project.sh --no-track --include-claude 2>&1 | grep -q "cannot be used together" || { echo "FAIL: mutual exclusion not working"; exit 1; }
echo "PASS: Mutual exclusion"

# Cleanup
rm -rf "$TEST_DIR"
```

### Changes Required

**See `design.md` for:**
- Full script implementation → `design.md#component-3-per-project-setup-script`
- Flag behavior → `design.md#component-3-per-project-setup-script`
- Mutual exclusion logic → `design.md#component-3-per-project-setup-script`

**Specific file changes:**

#### 1. Replace Init Script
**File:** `scripts/init-project.sh` (REPLACE)

- [x] Backup existing script (for reference)
- [x] Replace with implementation from `design.md#component-3`
- [x] Add argument parsing for `--dry-run`, `--no-track`, `--include-claude`, `--source`
- [x] Add mutual exclusion check
- [x] Add source directory resolution (from metadata or --source)
- [x] Add `add_to_gitignore()` helper function
- [x] Add `copy_project_pack()` function with merge strategy
- [x] Add `copy_claude_pack()` function for vendoring
- [x] Add settings.json configuration for vendored hooks
- [x] Add success message and next steps
- [x] Verify executable permissions

### Validation (How to Verify This Phase)

**Automated:**
- [x] `./scripts/init-project.sh --dry-run` → Shows actions without executing
- [x] Test in fresh git repo → `.project/` created with all subdirectories
- [x] Test with existing `.project/` → Merge strategy works (adds missing, preserves existing)
- [x] Test `--no-track` → `.project` added to `.gitignore`
- [x] Test `--include-claude` → Files copied (not symlinked) to `.claude/`
- [x] Test both flags together → Error with clear message

**Manual:**
- [x] Run without global setup, verify `--source` required or helpful error
- [x] Run with global setup, verify source auto-detected
- [x] Verify vendored `.claude/settings.json` has correct hook paths

**What We Know Works After This Phase:**
Per-project initialization works with all flag combinations, merge strategy preserves existing content.

---

## Phase 4: Uninstall Scripts

### Goal
Create cleanup scripts for global and per-project uninstall to provide a clean removal path.

### Test Stencil (Write This First)
```bash
# test_uninstall.sh

# Setup: Install first
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
./scripts/setup-global.sh

# Test 1: Global uninstall
./scripts/uninstall-global.sh
[ ! -L "$HOME/.claude/commands/_my_research.md" ] || { echo "FAIL: symlink not removed"; exit 1; }
[ ! -f "$HOME/.claude/.agentic-pack-source" ] || { echo "FAIL: metadata not removed"; exit 1; }
echo "PASS: Global uninstall"

# Test 2: Project uninstall
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
./scripts/init-project.sh --source /path/to/agentic-project-init --include-claude
echo "y" | ./scripts/uninstall-project.sh
[ ! -d ".project" ] || { echo "FAIL: .project not removed"; exit 1; }
echo "PASS: Project uninstall"

# Cleanup
rm -rf "$TEST_HOME" "$TEST_DIR"
```

### Changes Required

**See `design.md` for:**
- Global uninstall implementation → `design.md#component-4-global-uninstall-script`
- Project uninstall implementation → `design.md#component-5-per-project-uninstall-script`

**Specific file changes:**

#### 1. Create Global Uninstall Script
**File:** `scripts/uninstall-global.sh` (NEW)

- [x] Create file with implementation from `design.md#component-4`
- [x] Add symlink removal loop (only removes symlinks pointing to our source)
- [x] Add settings.json cleanup (remove our hook entries)
- [x] Add metadata file removal
- [x] Add summary output
- [x] Make executable

#### 2. Create Project Uninstall Script
**File:** `scripts/uninstall-project.sh` (NEW)

- [x] Create file with implementation from `design.md#component-5`
- [x] Add confirmation prompt (unless `--force`)
- [x] Add `.project/` removal
- [x] Add `.gitignore` cleanup
- [x] Add vendored `.claude/` cleanup (detect via marker file)
- [x] Add summary output
- [x] Make executable

### Validation (How to Verify This Phase)

**Automated:**
- [x] Global uninstall removes only our symlinks
- [x] Global uninstall preserves user-created files
- [x] Project uninstall prompts for confirmation
- [x] Project uninstall `--force` skips confirmation

**Manual:**
- [x] Create a file in `~/.claude/commands/` manually, run uninstall, verify preserved
- [x] Uninstall project with vendored content, verify `.claude/` cleaned appropriately

**What We Know Works After This Phase:**
Complete install/uninstall lifecycle works, user content preserved.

---

## Phase 5: Documentation Updates

### Goal
Update README.md with new workflow, migration guide, and command reference.

### Test Stencil (Write This First)
```bash
# Verify documentation completeness
# test_docs.sh

# Check README has required sections
grep -q "setup-global.sh" README.md || { echo "FAIL: setup-global.sh not documented"; exit 1; }
grep -q "init-project.sh" README.md || { echo "FAIL: init-project.sh not documented"; exit 1; }
grep -q "_my_" README.md || { echo "FAIL: _my_ prefix not documented"; exit 1; }
grep -q "Migration" README.md || { echo "FAIL: migration guide missing"; exit 1; }
echo "PASS: Documentation complete"
```

### Changes Required

**See `design.md` for:**
- Migration strategy → `design.md#migration-from-submodule-approach`
- Command invocation change → `design.md#command-invocation-change`

**Specific file changes:**

#### 1. Update README.md
**File:** `README.md`

- [x] Update Quick Start section with new workflow
- [x] Document `setup-global.sh` usage and options
- [x] Document `init-project.sh` usage and options
- [x] Document uninstall scripts
- [x] Add command prefix explanation (`/_my_research` etc.)
- [x] Add migration guide for existing submodule users
- [x] Update any command references to use `_my_` prefix

### Validation (How to Verify This Phase)

**Automated:**
- [x] Run documentation verification script

**Manual:**
- [x] Read through README as a new user - is workflow clear?
- [x] Verify all command examples use `/_my_` prefix
- [x] Verify migration steps are complete and accurate

**What We Know Works After This Phase:**
Documentation reflects new system, users can follow setup and migration.

---

## Environment Setup

**Shell:** Bash (POSIX-compliant)
**Dependencies:**
- `jq` (optional, for JSON merging - graceful fallback)
- Standard Unix tools (ln, cp, mkdir, grep, etc.)

---

## Risk Management

**See `design.md#potential-risks` for detailed risk analysis**

**Phase-Specific Mitigations:**
- **Phase 1**: Manual review of each file after automated rename; verification grep
- **Phase 2**: Test with/without jq; test idempotency explicitly
- **Phase 3**: Test all flag combinations; test source detection paths
- **Phase 4**: Test preservation of user files explicitly
- **Phase 5**: N/A (documentation only)

---

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
**Completed:** 2026-01-09
**Actual Changes:**
- Renamed all 16 command files in `claude-pack/commands/` with `_my_` prefix
- Updated all cross-references in command files using sed bulk replacement
- Updated `claude-pack/hooks/capture.sh` (2 references)
- Updated `claude-pack/hooks/query-transcript.py` (1 reference)
- Updated `claude-pack/claude-md-checklist.md` (6 command references)
- Created `scripts/test_rename.sh` verification script

**Issues:**
- Initial verification script had false positive on "memorized" vs "/memorize" - fixed regex pattern

**Deviations:**
- `claude-pack/agents/recall.md` had no command references requiring update (plan assumed it did)

### Phase 2 Completion
**Completed:** 2026-01-09
**Actual Changes:**
- Created `scripts/setup-global.sh` with full implementation
- Created `scripts/test_global_setup.sh` for automated testing
- Script creates symlinks for: 16 commands, 2 agents, 4 hooks, 1 skill, 1 rule
- Script configures `~/.claude/settings.json` with PreCompact hook
- Script writes metadata files for source tracking and version

**Issues:**
- None encountered

**Deviations:**
- Added `-h|--help` flag (not in original plan but useful)

### Phase 3 Completion
**Completed:** 2026-01-09
**Actual Changes:**
- Backed up existing `init-project.sh` to `init-project.sh.bak`
- Replaced with new implementation supporting all flags
- Created `scripts/test_init_project.sh` for automated testing
- Script supports: `--dry-run`, `--no-track`, `--include-claude`, `--source`
- Implements merge strategy for existing `.project/`
- Implements full vendoring for `--include-claude`
- Source auto-detection from `~/.claude/.agentic-pack-source`

**Issues:**
- None encountered

**Deviations:**
- Added `-h|--help` flag (not in original plan but useful)
- Added CLAUDE.md tip at end (reused from old script)

### Phase 4 Completion
**Completed:** 2026-01-09
**Actual Changes:**
- Created `scripts/uninstall-global.sh` - removes symlinks, cleans settings.json, removes metadata
- Created `scripts/uninstall-project.sh` - removes .project/, cleans vendored .claude/, cleans .gitignore
- Created `scripts/test_uninstall.sh` for automated testing
- Both scripts preserve user-created content
- Global uninstall only removes symlinks pointing to our source
- Project uninstall detects vendored content via `.agentic-pack-vendored` marker

**Issues:**
- None encountered

**Deviations:**
- Added `-h|--help` flags to both scripts (useful for discoverability)

### Phase 5 Completion
**Completed:** 2026-01-09
**Actual Changes:**
- Completely rewrote `README.md` for new simplified setup system
- Added Quick Start with 4-step workflow
- Added Command Reference table (15 commands)
- Added Script Reference (4 scripts with full option docs)
- Added Project Structure diagram
- Added Migration Guide from submodule approach
- Added "Why the `_my_` Prefix?" explanation
- Added Troubleshooting section
- Created `scripts/test_docs.sh` for documentation verification

**Issues:**
- test_docs.sh grep needed `--` to handle patterns starting with `-`

**Deviations:**
- Removed extensive customization/branching sections from old README (no longer relevant)
- Added Vendoring section for self-contained projects

---

**Status**: Draft → In Progress → Complete
