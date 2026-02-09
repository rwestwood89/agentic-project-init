# Design: Hook Path Resolution for Multi-Level Installation

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-01-18 18:01
**Last Updated:** 2026-01-18 18:01

---

## Overview

Enable commands that reference hook scripts to work regardless of whether the package is installed at user-level, project-level, or both, by storing resolved absolute paths in a config file during installation.

## Related Artifacts

- **Spec:** `.project/active/hook-path-resolution/spec.md`

---

## Research Findings

### Current Script References in Commands

Commands reference hooks using relative paths that assume `.claude/hooks/` exists locally:

| Command | Script Reference | Hook Used |
|---------|-----------------|-----------|
| `_my_capture.md:15` | `.claude/hooks/query-transcript.py --list --json` | query-transcript.py |
| `_my_capture.md:20` | `.claude/hooks/_my_capture.sh` | capture.sh (incorrect name in command) |
| `_my_memorize.md:22` | `.claude/hooks/parse-transcript.py <transcript-path>` | parse-transcript.py |
| `_my_recall.md:47` | `.claude/hooks/query-transcript.py` | query-transcript.py |
| `recall.md:10` (agent) | `.claude/hooks/query-transcript.py` | query-transcript.py |

### Current Installation Architecture

**Global install (`setup-global.sh`):**
- Creates `~/.claude/{commands,agents,hooks,skills,rules}/`
- Symlinks files from `claude-pack/` to `~/.claude/`
- Writes metadata: `~/.claude/.agentic-pack-source` (source repo path)
- Configures settings.json with hook path using absolute path to `~/.claude/hooks/precompact-capture.sh`

**Project install (`init-project.sh`):**
- Copies `.project/` template to target project
- With `--include-claude`: copies `claude-pack/` to `.claude/` and writes marker file `.claude/.agentic-pack-vendored`
- Configures settings.json with relative hook path `.claude/hooks/precompact-capture.sh`

### Key Pattern: Metadata File

The install scripts already use a metadata pattern:
- `~/.claude/.agentic-pack-source` stores the source repo path (line 201 of `setup-global.sh`)
- `~/.claude/.agentic-pack-version` stores the version
- `.claude/.agentic-pack-vendored` marks vendored installations

This same pattern can be extended for hook paths.

### Hooks Inventory

All hooks in `claude-pack/hooks/`:
| File | Type | Called By |
|------|------|-----------|
| `query-transcript.py` | Python | `_my_capture`, `_my_recall`, recall agent |
| `parse-transcript.py` | Python | `_my_memorize` |
| `capture.sh` | Shell | `_my_capture` command |
| `precompact-capture.sh` | Shell | settings.json PreCompact hook |

---

## Proposed Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Installation Time                             │
├─────────────────────────────────────────────────────────────────┤
│  setup-global.sh          │     init-project.sh                  │
│         │                 │            │                         │
│         ▼                 │            ▼                         │
│  ~/.claude/               │     .claude/                         │
│    .hook-paths.json       │       .hook-paths.json               │
│    (absolute paths)       │       (absolute paths, if vendored)  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Runtime (Command Execution)                   │
├─────────────────────────────────────────────────────────────────┤
│  Command (e.g., _my_capture)                                     │
│         │                                                        │
│         ▼                                                        │
│  1. Check .claude/.hook-paths.json  (project-level)              │
│         │                                                        │
│         ▼ (if not found)                                         │
│  2. Check ~/.claude/.hook-paths.json (user-level)                │
│         │                                                        │
│         ▼                                                        │
│  3. Use resolved path from config                                │
└─────────────────────────────────────────────────────────────────┘
```

### Component 1: Config File Format

**Location:**
- Global: `~/.claude/.hook-paths.json`
- Project: `.claude/.hook-paths.json`

**Format:**
```json
{
  "version": 1,
  "resolved_at": "2026-01-18T18:00:00Z",
  "source": "/path/to/agentic-project-init",
  "hooks": {
    "query-transcript": "/absolute/path/to/query-transcript.py",
    "parse-transcript": "/absolute/path/to/parse-transcript.py",
    "capture": "/absolute/path/to/capture.sh",
    "precompact-capture": "/absolute/path/to/precompact-capture.sh"
  }
}
```

**Design Rationale:**
- `version`: Allows future format changes
- `resolved_at`: Debugging/troubleshooting timestamp
- `source`: Where hooks were resolved from (for uninstall/update)
- `hooks`: Map of hook names to absolute paths (using short names for readability in commands)

### Component 2: Config Generation in Install Scripts

#### 2.1 `setup-global.sh` Changes

**Location:** `scripts/setup-global.sh`

**Add after line 204** (after writing `.agentic-pack-version`):

```bash
# Write hook paths config
write_hook_paths() {
    local config_file="$TARGET_DIR/.hook-paths.json"
    local hooks_dir="$CLAUDE_PACK/hooks"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN] Would write hook paths to $config_file${NC}"
        return
    fi

    cat > "$config_file" << EOF
{
  "version": 1,
  "resolved_at": "$(date -Iseconds)",
  "source": "$SOURCE_DIR",
  "hooks": {
    "query-transcript": "$hooks_dir/query-transcript.py",
    "parse-transcript": "$hooks_dir/parse-transcript.py",
    "capture": "$hooks_dir/capture.sh",
    "precompact-capture": "$hooks_dir/precompact-capture.sh"
  }
}
EOF
    echo -e "${GREEN}  ✓ Hook paths: $config_file${NC}"
}
write_hook_paths
```

#### 2.2 `init-project.sh` Changes

**Location:** `scripts/init-project.sh`

**Add inside `copy_claude_pack()` function, after line 297** (after writing `.agentic-pack-vendored`):

```bash
# Write hook paths config for vendored installation
local hooks_dir
hooks_dir="$(pwd)/.claude/hooks"

cat > ".claude/.hook-paths.json" << EOF
{
  "version": 1,
  "resolved_at": "$(date -Iseconds)",
  "source": "vendored",
  "hooks": {
    "query-transcript": "$hooks_dir/query-transcript.py",
    "parse-transcript": "$hooks_dir/parse-transcript.py",
    "capture": "$hooks_dir/capture.sh",
    "precompact-capture": "$hooks_dir/precompact-capture.sh"
  }
}
EOF
echo -e "${GREEN}  ✓ Created hook paths config${NC}"
```

### Component 3: Command Updates

Commands need to instruct Claude to resolve hook paths from the config file before running hooks.

#### 3.1 Resolution Instructions (Add to Commands)

Add a standard resolution block to each affected command. This block goes at the top of the "Instructions" section:

```markdown
## Hook Resolution

Before running any hook script, resolve its path:

1. Check if `.claude/.hook-paths.json` exists (project-level config)
2. If not, check if `~/.claude/.hook-paths.json` exists (global config)
3. If neither exists, show error: "No hook configuration found. Run setup-global.sh or init-project.sh first."
4. Read the JSON and use the path from `hooks.<hook-name>`

Use `jq` to extract paths:
```bash
# Try project first, fall back to global
CONFIG_FILE=".claude/.hook-paths.json"
[ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.claude/.hook-paths.json"

# Extract specific hook path
QUERY_TRANSCRIPT=$(jq -r '.hooks["query-transcript"]' "$CONFIG_FILE")
```
```

#### 3.2 Specific Command Changes

**`_my_capture.md`** - Replace lines 15-22:

Current:
```markdown
1. **Find the current transcript:**
   - Run: `.claude/hooks/query-transcript.py --list --json`
   - Take the first (most recent) transcript — this is the current session

2. **Run the capture script:**
   ```bash
   .claude/hooks/_my_capture.sh <transcript_path> manual
   ```
```

New:
```markdown
1. **Resolve hook paths:**
   ```bash
   CONFIG_FILE=".claude/.hook-paths.json"
   [ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.claude/.hook-paths.json"

   if [ ! -f "$CONFIG_FILE" ]; then
     echo "Error: No hook configuration found. Run setup-global.sh first."
     exit 1
   fi
   ```

2. **Find the current transcript:**
   ```bash
   QUERY_TRANSCRIPT=$(jq -r '.hooks["query-transcript"]' "$CONFIG_FILE")
   "$QUERY_TRANSCRIPT" --list --json
   ```
   - Take the first (most recent) transcript — this is the current session

3. **Run the capture script:**
   ```bash
   CAPTURE_HOOK=$(jq -r '.hooks["capture"]' "$CONFIG_FILE")
   "$CAPTURE_HOOK" <transcript_path> manual
   ```
```

**`_my_memorize.md`** - Replace line 22:

Current:
```markdown
2. **Parse the transcript using the helper script:**
   - Run: `.claude/hooks/parse-transcript.py <transcript-path> --max-chars=40000`
```

New:
```markdown
2. **Resolve hook path and parse the transcript:**
   ```bash
   CONFIG_FILE=".claude/.hook-paths.json"
   [ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.claude/.hook-paths.json"
   PARSE_TRANSCRIPT=$(jq -r '.hooks["parse-transcript"]' "$CONFIG_FILE")
   "$PARSE_TRANSCRIPT" <transcript-path> --max-chars=40000
   ```
```

**`_my_recall.md`** - Update subagent prompt template (lines 40-48):

Current:
```markdown
```
You are a recall agent. Read your instructions from .claude/agents/_my_recall.md

Search mode: {all|index|latest|specific}
Transcript: {transcript_path if specific, otherwise N/A}
Question: {question}

Find the answer by querying transcripts using .claude/hooks/query-transcript.py
```
```

New:
```markdown
```
You are a recall agent. Read your instructions from .claude/agents/recall.md

Search mode: {all|index|latest|specific}
Transcript: {transcript_path if specific, otherwise N/A}
Question: {question}

First, resolve the query-transcript hook path:
- Check .claude/.hook-paths.json (project level)
- Fall back to ~/.claude/.hook-paths.json (global level)
- Extract: jq -r '.hooks["query-transcript"]' <config_file>

Then use that resolved path to query transcripts.
```
```

**`claude-pack/agents/recall.md`** - Update tool reference (lines 9-11):

Current:
```markdown
```bash
.claude/hooks/query-transcript.py [options]
```
```

New:
```markdown
```bash
# First resolve the hook path:
CONFIG_FILE=".claude/.hook-paths.json"
[ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.claude/.hook-paths.json"
QUERY_TRANSCRIPT=$(jq -r '.hooks["query-transcript"]' "$CONFIG_FILE")

# Then use it:
"$QUERY_TRANSCRIPT" [options]
```
```

### Component 4: Uninstall Script Updates

#### 4.1 `uninstall-global.sh` Changes

**Add to line 83-89** (in the metadata removal section):

```bash
# Add .hook-paths.json to the list
for file in .agentic-pack-source .agentic-pack-version .hook-paths.json; do
```

#### 4.2 `uninstall-project.sh` Changes

**Add after line 122** (after removing vendor marker):

```bash
# Remove hook paths config
rm -f .claude/.hook-paths.json
echo -e "${GREEN}  ✓ Removed hook paths config${NC}"
```

### Component 5: Settings.json Hook Path

The `settings.json` hook configuration for PreCompact already uses absolute paths when created by `setup-global.sh` (line 161). For vendored installs, it uses a relative path.

**No change needed for global install** - already uses `$TARGET_DIR/hooks/precompact-capture.sh` which expands to absolute path.

**For vendored install in `init-project.sh`**, the relative path `.claude/hooks/precompact-capture.sh` will continue to work because:
1. Vendored installs have the hooks in `.claude/hooks/` locally
2. The hook runs from the project directory context

---

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `jq` not installed on user system | Commands fail with confusing error | Add jq check at start of commands; show helpful install message |
| Config file gets out of sync with actual hook locations | Commands fail | Include `source` field for debugging; re-running install regenerates |
| Symlinks in global install break if source repo moves | Hooks not found at resolved paths | Document that re-running `setup-global.sh` fixes this |
| Commands copy/pasted from old docs use hardcoded paths | Inconsistent behavior | Update all documentation; old relative paths will still work for vendored installs |

---

## Integration Strategy

This change is backward compatible:

1. **Existing vendored installs**: Continue working (`.claude/hooks/` exists locally with relative paths)
2. **Existing global installs**: Will start working after re-running `setup-global.sh`
3. **New installs**: Work immediately

**Migration path:**
- Users with global install just re-run `setup-global.sh` to generate the config
- No changes needed for project-level vendored installs (though they can update for consistency)

---

## Validation Approach

### Manual Testing Checklist

1. **Global-only install:**
   - [ ] Run `setup-global.sh`
   - [ ] Verify `~/.claude/.hook-paths.json` created with correct absolute paths
   - [ ] In a new project (no `.claude/`), run `/_my_capture`
   - [ ] Verify it finds transcript and creates capture file

2. **Vendored install:**
   - [ ] Run `init-project.sh --include-claude`
   - [ ] Verify `.claude/.hook-paths.json` created
   - [ ] Run `/_my_capture`
   - [ ] Verify it uses project-level hooks

3. **Both installed (precedence):**
   - [ ] Have global install with one version of hooks
   - [ ] Vendor different version in project
   - [ ] Verify project hooks are used (check resolved path)

4. **Uninstall:**
   - [ ] Run `uninstall-global.sh`
   - [ ] Verify `~/.claude/.hook-paths.json` removed
   - [ ] Run `uninstall-project.sh` in vendored project
   - [ ] Verify `.claude/.hook-paths.json` removed

---

## Implementation Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `scripts/setup-global.sh` | Add function | `write_hook_paths()` to generate global config |
| `scripts/init-project.sh` | Add code | Generate project config in `copy_claude_pack()` |
| `scripts/uninstall-global.sh` | Modify | Add `.hook-paths.json` to removal list |
| `scripts/uninstall-project.sh` | Add code | Remove `.claude/.hook-paths.json` |
| `claude-pack/commands/_my_capture.md` | Modify | Add resolution instructions, update paths |
| `claude-pack/commands/_my_memorize.md` | Modify | Add resolution instructions, update paths |
| `claude-pack/commands/_my_recall.md` | Modify | Update subagent prompt with resolution |
| `claude-pack/agents/recall.md` | Modify | Update tool reference with resolution |

---

**Next Step:** After approval → `/_my_implement` or `/_my_plan`
