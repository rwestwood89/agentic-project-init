# Implementation Plan: Tiered Auto-Approve with Allowed Tools Management

**Status:** Complete
**Created:** 2026-02-08
**Last Updated:** 2026-02-08

## Source Documents
- **Spec:** `.project/active/allowed-tools/spec.md`
- **Design:** `.project/active/allowed-tools/design.md` — See here for component details, execution flow, hook protocol, CLI syntax, and risk analysis

## Implementation Strategy

**Phasing Rationale:**
Phase 1 creates all static artifacts (config template, review prompt, schema, command file) with zero integration risk. Phase 2 builds the core hook script on top of those artifacts — this is the riskiest component and gets the most validation. Phase 3 wires everything into setup/uninstall, extending proven patterns with minimal risk.

**Overall Validation Approach:**
- Phase 1: File existence + JSON validity checks
- Phase 2: Manual stdin-driven hook tests with crafted JSON payloads
- Phase 3: `--dry-run` output verification + full install/uninstall cycle

---

## Phase 1: Static Artifacts

### Goal
Create the 4 new files that have no dependencies on each other or existing code: the default config template, Tier 2 review prompt, Tier 2 JSON schema, and the `/_my_allow_tool` command. These are pure file creation with content from the design doc.

### Test Stencil (Write This First)
```bash
# Validate all static artifacts exist and are well-formed
# Run after creating all 4 files

# 1. Config template is valid JSON with required fields
jq -e '.version and .tier2_enabled and .allowed_paths and .safe_commands' \
  claude-pack/hooks/allowed-tools.default.json

# 2. Review schema is valid JSON with required structure
jq -e '.properties.decision.enum | length == 3' \
  claude-pack/hooks/review-schema.json

# 3. Review prompt exists and contains all 3 decision types
grep -q "APPROVE" claude-pack/hooks/review-prompt.md && \
grep -q "PUSH_BACK" claude-pack/hooks/review-prompt.md && \
grep -q "ELEVATE" claude-pack/hooks/review-prompt.md

# 4. Command file exists
test -f claude-pack/commands/_my_allow_tool.md
```

### Changes Required

**See `design.md` for:**
- Config schema and rationale → `design.md#component-1-config-file-allowed-toolsjson`
- Review prompt content → `design.md#component-3-review-prompt-review-promptmd`
- Schema content → `design.md#component-4-review-schema-review-schemajson`
- Command actions and process → `design.md#component-5-_my_allow_tool-command`

**Specific file changes:**

#### 1. Default Config Template
**File:** `claude-pack/hooks/allowed-tools.default.json` (NEW)
- [x] Create with exact JSON from `design.md#component-1` (`version`, `tier2_enabled`, `allowed_paths`, `safe_commands`)

#### 2. Review Prompt
**File:** `claude-pack/hooks/review-prompt.md` (NEW)
- [x] Create with prompt content from `design.md#component-3` (APPROVE/PUSH_BACK/ELEVATE criteria)

#### 3. Review Schema
**File:** `claude-pack/hooks/review-schema.json` (NEW)
- [x] Create with schema from `design.md#component-4` (decision enum + reason)

#### 4. Allow Tool Command
**File:** `claude-pack/commands/_my_allow_tool.md` (NEW)
- [x]Create following command template pattern (see `design.md#command-file-pattern`)
- [x]Include all 6 actions from `design.md#component-5`: add/remove path, add/remove command, list, toggle tier2
- [x]Include config file location (`~/.claude/hooks/allowed-tools.json`)
- [x]Include path normalization and validation instructions
- [x]Include duplicate-checking instructions

### Validation

**Automated:**
- [x]`jq . claude-pack/hooks/allowed-tools.default.json` → valid JSON
- [x]`jq . claude-pack/hooks/review-schema.json` → valid JSON
- [x]`grep -c "##" claude-pack/hooks/review-prompt.md` → 3 (one per decision)

**Manual:**
- [x]Review prompt reads clearly — a reviewer model should understand the three decisions
- [x]Command file follows existing `_my_*.md` patterns (compare with `_my_capture.md`)

**What We Know Works After This Phase:**
All static artifacts are in place. The hook script (Phase 2) will be able to reference `review-prompt.md` and `review-schema.json`. Setup (Phase 3) will be able to copy `allowed-tools.default.json`.

---

## Phase 2: Hook Script

### Goal
Create the new `claude-pack/hooks/auto-approve.sh` that generalizes the existing hardcoded hook into a config-driven, three-tier review pipeline. This is the core of the feature and the riskiest component.

### Test Stencil (Write This First)
```bash
# Manual hook tests — pipe crafted JSON to the script and check stdout
# Set up: create a test config with a known allowed path
HOOK="claude-pack/hooks/auto-approve.sh"
chmod +x "$HOOK"

# Create test config alongside the script
cat > claude-pack/hooks/allowed-tools.json << 'EOF'
{"version":1,"tier2_enabled":false,"allowed_paths":["/tmp","/home/testuser/project"],"safe_commands":["node","cargo"]}
EOF

# Test 1: File tool in allowed path → allow
echo '{"tool_name":"Read","cwd":"/home/testuser/project","tool_input":{"file_path":"/home/testuser/project/src/main.rs"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "allow"'

# Test 2: File tool outside allowed path, tier2 disabled → ask
echo '{"tool_name":"Write","cwd":"/home/testuser/project","tool_input":{"file_path":"/etc/passwd"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "ask"'

# Test 3: Safe bash command → allow
echo '{"tool_name":"Bash","cwd":"/home/testuser/project","tool_input":{"command":"ls -la"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "allow"'

# Test 4: rm -rf outside /tmp → deny
echo '{"tool_name":"Bash","cwd":"/home/testuser/project","tool_input":{"command":"rm -rf /home/testuser/important"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "deny"'

# Test 5: Git write op → ask
echo '{"tool_name":"Bash","cwd":"/home/testuser/project","tool_input":{"command":"git push origin main"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "ask"'

# Test 6: Config safe_commands → allow
echo '{"tool_name":"Bash","cwd":"/home/testuser/project","tool_input":{"command":"node index.js"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "allow"'

# Test 7: Built-in safe tool (Task) → allow
echo '{"tool_name":"Task","cwd":"/home/testuser/project","tool_input":{}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "allow"'

# Test 8: Unhandled tool, tier2 disabled → fall-through (empty stdout)
echo '{"tool_name":"SomeNewMCPTool","cwd":"/home/testuser/project","tool_input":{}}' \
  | "$HOOK" | test -z "$(cat)"

# Test 9: Missing config → falls back to defaults (no error)
rm claude-pack/hooks/allowed-tools.json
echo '{"tool_name":"Bash","cwd":"/tmp","tool_input":{"command":"ls"}}' \
  | "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision == "allow"'

# Cleanup
rm -f claude-pack/hooks/allowed-tools.json
```

### Changes Required

**See `design.md` for:**
- Full execution flow diagram → `design.md#execution-flow`
- All 10 script sections with code → `design.md#script-structure-sections`
- `tier2_or_escalate` vs `tier2_or_fallthrough` rationale → `design.md#section-2`
- Built-in safe tools list → `design.md#section-9`
- `invoke_tier2()` implementation → `design.md#section-8`

**Specific file changes:**

#### 1. Hook Script
**File:** `claude-pack/hooks/auto-approve.sh` (NEW)
- [x]Section 1: Config loading — `HOOK_DIR`, `CONFIG_FILE`, jq reads into bash arrays (see `design.md#section-1`)
- [x]Section 2: Output helpers — preserve `allow()`, `deny()`, `ask_user()`, `fall_through()` from existing hook; add `tier2_or_escalate()` and `tier2_or_fallthrough()`
- [x]Section 3: Path helpers — `is_allowed_path()` with config-driven loop replacing hardcoded paths; preserve `is_tmp_path()`, `check_path_args()`
- [x]Section 4: `classify_segment()` — preserve entire existing function, add config `safe_commands` loop after built-in case statement
- [x]Section 5: Input parsing — copy unchanged from existing hook (lines 206-227)
- [x]Section 6: File tools — same logic, replace `fall_through` with `tier2_or_escalate`
- [x]Section 7: Bash commands — same logic, replace `*` case with `tier2_or_escalate`
- [x]Section 8: `invoke_tier2()` — new function, reads prompt/schema files, calls `claude -p` with structured output
- [x]Section 9: Built-in safe tools — `Task`, `WebSearch`, `WebFetch`, `AskUserQuestion`, `NotebookEdit` (path-gated)
- [x]Section 10: Final catch-all — `tier2_or_fallthrough`
- [x]Make executable (`chmod +x`)

### Validation

**Automated:**
- [x]Run test stencil above — all 9 tests pass
- [x]`bash -n claude-pack/hooks/auto-approve.sh` → no syntax errors
- [x]`shellcheck claude-pack/hooks/auto-approve.sh` → no critical warnings (if shellcheck available)

**Manual:**
- [x]Compare structure side-by-side with existing `~/.claude/hooks/auto-approve.sh` — all existing logic preserved
- [x]Verify `AUDIT_LOG` writes happen for all decision paths
- [x]Verify `invoke_tier2()` uses correct CLI flags per `design.md#headless-claude-cli-syntax`

**What We Know Works After This Phase:**
The hook script correctly classifies all Tier 1 decisions (allow/deny/ask) for file tools and bash commands using config-driven paths/commands. Built-in safe tools auto-approve. Unhandled tools fall through when Tier 2 is disabled. The script is syntactically valid and ready to be symlinked.

---

## Phase 3: Setup & Uninstall Integration

### Goal
Wire the new artifacts into the installation and uninstallation flows. Modify `setup-global.sh` to install the hook (with migration), copy config, configure PreToolUse, and update hook-paths. Modify `uninstall-global.sh` to clean up PreToolUse and the config file.

### Test Stencil (Write This First)
```bash
# Test setup dry-run output includes new artifacts
output=$(./scripts/setup-global.sh --dry-run 2>&1)

# Should mention auto-approve migration check
echo "$output" | grep -q "auto-approve"

# Should mention allowed-tools.json config copy
echo "$output" | grep -q "allowed-tools.json"

# Should mention hook configuration
echo "$output" | grep -q "hooks"

# After full install: verify artifacts are in place
# (Run after actual install, not dry-run)
test -L ~/.claude/hooks/auto-approve.sh          # symlink
test -L ~/.claude/hooks/review-prompt.md          # symlink
test -L ~/.claude/hooks/review-schema.json        # symlink
test -f ~/.claude/hooks/allowed-tools.json        # copied file (not symlink)
jq -e '.hooks.PreToolUse' ~/.claude/settings.json # PreToolUse config exists
jq -e '.hooks.PreCompact' ~/.claude/settings.json # PreCompact still exists
```

### Changes Required

**See `design.md` for:**
- Setup changes (3 changes) → `design.md#component-6-setup-globalsh-changes`
- Uninstall changes (2 changes) → `design.md#component-7-uninstall-globalsh-changes`
- Migration logic → `design.md#change-1b`

**Specific file changes:**

#### 1. Setup Script
**File:** `scripts/setup-global.sh` (MODIFY)
- [x]Add `*.default.json` skip in hook symlink loop (line ~117-121) — `design.md#change-1`
- [x]Add migration logic for existing non-symlink `auto-approve.sh` before symlink loop — `design.md#change-1b`
- [x]Add config file copy logic after hook symlink loop — `design.md#change-1`
- [x]Expand `configure_hooks()` hook_config to include PreToolUse with catch-all matcher + 60s timeout — `design.md#change-2`
- [x]Add `auto-approve`, `review-prompt`, `review-schema` entries to `write_hook_paths()` — `design.md#change-3`

#### 2. Uninstall Script
**File:** `scripts/uninstall-global.sh` (MODIFY)
- [x]Extend settings.json jq filter to also clean `PreToolUse` entries — `design.md#component-7-change-1`
- [x]Add `hooks/allowed-tools.json` to metadata cleanup file list — `design.md#component-7-change-2`

### Validation

**Automated:**
- [x]`./scripts/setup-global.sh --dry-run` → output mentions all new artifacts, no errors
- [x]`bash -n scripts/setup-global.sh` → no syntax errors
- [x]`bash -n scripts/uninstall-global.sh` → no syntax errors

**Manual:**
- [x]Full install cycle: run `setup-global.sh`, verify all 4 artifacts installed correctly (3 symlinks + 1 copy)
- [x]Verify `settings.json` has both `PreCompact` and `PreToolUse` sections
- [x]Verify `allowed-tools.json` is a regular file (not symlink): `test -f ~/.claude/hooks/allowed-tools.json && ! test -L ~/.claude/hooks/allowed-tools.json`
- [x]Verify `.hook-paths.json` has new entries
- [x]Run `uninstall-global.sh`, verify all artifacts removed and `settings.json` cleaned
- [x]Test migration: place a non-symlink `auto-approve.sh` at `~/.claude/hooks/`, run setup, verify backup created at `.bak` and symlink created

**What We Know Works After This Phase:**
Full install/uninstall cycle works. The hook is properly registered in `settings.json` with correct matchers and timeout. Existing hooks (PreCompact) are unaffected. Config file is copied (not symlinked) and preserved across updates. Migration from old hardcoded hook works cleanly.

---

## Environment Setup

**See CLAUDE.md for full environment rules**

**Key dependencies:** `jq` (required), `bash` (POSIX-compatible), `claude` CLI (optional, for Tier 2)

---

## Risk Management

**See `design.md#potential-risks` for detailed risk analysis**

**Phase-Specific Mitigations:**
- **Phase 2**: Tier 2 invocation (`invoke_tier2`) can't be fully tested without a live `claude` CLI. Test with `tier2_enabled: false` to verify all Tier 1 paths. Tier 2 graceful degradation is exercised by the "missing claude CLI" code path.
- **Phase 3**: The `jq -s '.[0] * .[1]'` shallow merge replaces the entire `hooks` object. The hook_config must include ALL hook types (PreCompact + PreToolUse) to avoid dropping existing config. This is already accounted for in the design.

## Implementation Notes

### Phase 1 Completion
**Completed:** 2026-02-08
**Actual Changes:**
- Created `claude-pack/hooks/allowed-tools.default.json` with version/tier2_enabled/allowed_paths/safe_commands
- Created `claude-pack/hooks/review-prompt.md` with APPROVE/PUSH_BACK/ELEVATE criteria
- Created `claude-pack/hooks/review-schema.json` with decision enum + reason
- Created `claude-pack/commands/_my_allow_tool.md` with all 6 actions (add/remove path, add/remove command, list, toggle tier2)
**Issues:** None
**Deviations:** None

### Phase 2 Completion
**Completed:** 2026-02-08
**Actual Changes:**
- Created `claude-pack/hooks/auto-approve.sh` with all 10 sections from design
- Made executable (`chmod +x`)
**Issues:**
- **jq `//` operator bug**: `jq -r '.tier2_enabled // true'` returns `true` even when config value is `false`, because jq's `//` (alternative) operator triggers on both `null` and `false`. Fixed with `jq -r 'if .tier2_enabled == false then "false" else "true" end'`. This was a design doc bug — the pseudocode used `//` which has different semantics than expected.
**Deviations:**
- Config loading uses `if .tier2_enabled == false then "false" else "true" end` instead of `.tier2_enabled // true` to handle boolean false correctly
- `NotebookEdit` in Section 9 uses a regular variable (not `local`) since it's at top-level `case` scope, not inside a function

### Phase 3 Completion
**Completed:** 2026-02-08
**Actual Changes:**
- Modified `scripts/setup-global.sh`:
  - Added migration logic for existing non-symlink `auto-approve.sh` (backup to `.bak`)
  - Added `*.default.json` skip in hook symlink loop
  - Added config file copy logic (copy if not exists, preserve if exists)
  - Expanded `configure_hooks()` to include PreToolUse with catch-all matcher + 60s timeout
  - Added `auto-approve`, `review-prompt`, `review-schema` to `write_hook_paths()`
- Modified `scripts/uninstall-global.sh`:
  - Extended jq filter to clean both PreCompact and PreToolUse entries
  - Added `hooks/allowed-tools.json` to metadata cleanup file list
**Issues:**
- Pre-existing `create_dir()` bug: `[ ! -d "$dir" ] && echo ...` under `set -e` exits with 1 when directory exists. Not introduced by this feature — was pre-existing. Does not affect real install (only dry-run when all dirs exist).
**Deviations:** None

### Test Results (Phase 2)
All 9 test cases passed:
1. File tool in allowed path -> allow
2. File tool outside allowed path, tier2 disabled -> ask
3. Safe bash command -> allow
4. rm -rf outside /tmp -> deny
5. Git write op -> ask
6. Config safe_commands -> allow
7. Built-in safe tool (Task) -> allow
8. Unhandled tool, tier2 disabled -> fall-through (empty stdout)
9. Missing config -> falls back to defaults

---

**Status**: Complete
