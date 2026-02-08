# Design: Tiered Auto-Approve with Allowed Tools Management

**Status:** Draft
**Owner:** Reid Westwood
**Created:** 2026-02-08 21:15:00 UTC
**Branch:** allowed-tools

## Overview

Generalizes the existing `~/.claude/hooks/auto-approve.sh` into a config-driven, three-tier PreToolUse hook shipped via `claude-pack/hooks/`, with a `/_my_allow_tool` command for managing the config.

## Related Artifacts

- **Spec**: `.project/active/allowed-tools/spec.md`
- **Existing hook**: `~/.claude/hooks/auto-approve.sh` (reference baseline)
- **Setup script**: `scripts/setup-global.sh`
- **Uninstall script**: `scripts/uninstall-global.sh`

---

## Research Findings

### Existing Hook Architecture (`~/.claude/hooks/auto-approve.sh`)

The current hook is a 277-line bash script with clear sections:

| Section | Lines | Purpose |
|---------|-------|---------|
| Output helpers | 11-29 | `allow()`, `deny()`, `ask_user()`, `fall_through()` — all exit 0 with JSON |
| Path helpers | 34-78 | `is_allowed_path()` (hardcoded), `is_tmp_path()`, `check_path_args()` |
| `classify_segment()` | 84-201 | Classifies bash command segments as allow/deny/ask/unknown |
| Input parsing | 206-227 | Single `jq` call, base64 for command safety |
| File tools section | 232-241 | Auto-approves Read/Write/Edit/Glob/Grep in allowed paths |
| Bash section | 246-275 | Splits on `&&`/`||`/`;`, classifies each segment, aggregates |
| Final fall-through | 277 | Unhandled tools fall through silently |

**Built-in command classifications in `classify_segment()`:**

| Category | Commands | Decision |
|----------|----------|----------|
| Shell builtins | cd, ls, pwd, echo, printf, etc. | allow |
| Text tools | grep, sed, awk, tr, cut, jq, wc, sort, etc. | allow |
| Git read | status, diff, log, branch, show, fetch, etc. | allow (unless --hard/--force) |
| Git write | commit, push, add, rebase, reset, etc. | ask |
| Interpreters | python, python3, pytest, mypy, ruff, black, isort | allow |
| uv safe | pip, venv, sync, lock, tree | allow |
| uv run safe | python, python3, pytest, mypy, ruff, etc. | allow |
| rm -rf | outside /tmp | deny |
| Path-aware tools | cp, mv, mkdir, touch, cat, find, etc. | allow if all paths in allowed dirs |
| gh read | pr/issue/repo view/list/status/diff | allow |
| .claude/.project scripts | .sh files in allowed paths | allow |

### setup-global.sh Integration Points

1. **Hook symlink loop** (`setup-global.sh:117-121`): Iterates `$CLAUDE_PACK/hooks/*` — new files in `claude-pack/hooks/` will be automatically symlinked. No code change needed for symlinks.

2. **`configure_hooks()`** (`setup-global.sh:148-192`): Currently only adds `PreCompact` hook config. Needs PreToolUse entries added to `hook_config`.

3. **`write_hook_paths()`** (`setup-global.sh:208-232`): Writes `.hook-paths.json` with entries for each hook. Needs new entries for auto-approve artifacts.

4. **Settings merge** (`setup-global.sh:180`): Uses `jq -s '.[0] * .[1]'` — shallow merge. The `*` operator merges top-level keys; for nested objects like `hooks`, it will overwrite the entire `hooks` object. This is fine because the hook_config already includes all hook types.

### uninstall-global.sh Integration Points

1. **Symlink removal** (`uninstall-global.sh:33-51`): Already removes ALL symlinks pointing to source dir. New hook files are automatically covered.

2. **Settings cleanup** (`uninstall-global.sh:62-78`): Only cleans `PreCompact`. Needs to also clean `PreToolUse`.

### Hook Protocol (from spec investigation)

| Decision | JSON `permissionDecision` | Who sees `permissionDecisionReason` | Behavior |
|----------|--------------------------|-------------------------------------|----------|
| Auto-approve | `"allow"` | User (in permission area) | Tool executes immediately |
| Push-back | `"deny"` + reason | **Claude** (in context) | Claude self-corrects, retries differently |
| Escalate | `"ask"` + reason | **User** (in permission dialog) | User must approve/deny |
| Hard deny | `"deny"` + reason | **Claude** | Tool blocked, Claude adjusts |
| Fall-through | exit 0, no stdout | N/A | Default Claude Code permission system |

### Headless Claude CLI Syntax (from spec investigation)

```bash
timeout 30 claude -p "$PROMPT" \
  --model haiku \
  --output-format json \
  --json-schema "$SCHEMA" \
  --tools "" \
  --max-turns 3 \
  --no-session-persistence \
  --max-budget-usd 0.05
```

- Response has `.structured_output.decision` and `.structured_output.reason`
- Need `--max-turns 3` (schema extraction counts as a turn)
- Embed context in prompt argument (stdin unreliable with `--tools ""`)
- Latency: ~3-5s with Haiku, cost: ~$0.005-0.015/call

### Command File Pattern (from investigation)

Commands use this structure:
```
# Title
**Purpose:** ...
**Input:** ...
**Output:** ...
## Overview
## Process
**Related Commands:**
**Last Updated:**
```

Commands reference file paths in backticks, use `$ARGUMENTS` for user input, and include safety/confirmation steps for destructive operations.

---

## Proposed Design

### Architecture Overview

```
claude-pack/hooks/
├── auto-approve.sh              # Main hook script (Tiers 1-3)
├── allowed-tools.default.json   # Default config template (COPIED during setup)
├── review-prompt.md             # Tier 2 system prompt (symlinked)
└── review-schema.json           # Tier 2 JSON schema (symlinked)

claude-pack/commands/
└── _my_allow_tool.md            # Command for managing config

Installed to ~/.claude/hooks/:
├── auto-approve.sh        → symlink (updates via git pull)
├── allowed-tools.json     ← COPIED from default (user-specific data)
├── review-prompt.md       → symlink (updates via git pull, user can break to customize)
└── review-schema.json     → symlink (updates via git pull)
```

**Key distinction**: `auto-approve.sh`, `review-prompt.md`, and `review-schema.json` are **symlinked** (so `git pull` propagates improvements). `allowed-tools.json` is **copied** from `allowed-tools.default.json` because it contains user-specific data (their project paths). `/_my_allow_tool` edits the installed copy, not the source.

### Component 1: Config File (`allowed-tools.json`)

**Source**: `claude-pack/hooks/allowed-tools.default.json`
**Installed to**: `~/.claude/hooks/allowed-tools.json` (copied, not symlinked)

```json
{
  "version": 1,
  "tier2_enabled": true,
  "allowed_paths": [],
  "safe_commands": []
}
```

| Field | Type | Purpose |
|-------|------|---------|
| `version` | number | Schema version for future migration |
| `tier2_enabled` | boolean | Toggle Tier 2 headless review. When `false`, unknown → Tier 3 directly |
| `allowed_paths` | string[] | Absolute directory paths. File tools and path-aware bash commands are auto-approved when all paths fall within these directories |
| `safe_commands` | string[] | Additional bash command names to auto-approve (merged with built-in baseline) |

**Design rationale**:

- **`allowed_paths` starts empty**: `/tmp` is always built-in. User-specific project paths must be explicitly added via `/_my_allow_tool`. This avoids shipping overly-permissive defaults. The command guides the user to add their first path.

- **`safe_commands` extends, doesn't replace**: The built-in baseline (cd, ls, grep, python, git-read, etc.) is hardcoded in the script. The config adds user-specific tools (e.g., `node`, `npm`, `cargo`, `go`, `make`). This keeps the config clean — users only see what they added.

- **No command-deny or path-deny lists**: Keep it simple. The deny logic (rm -rf outside /tmp, etc.) stays hardcoded. Users who need to customize deny rules are advanced enough to edit the script directly.

- **Flat structure**: No nested categories. `safe_commands` is a flat list because the hook treats them all the same way — "this command name is safe to auto-approve." The complex classification logic (git subcommands, uv nesting, path-aware tools) stays in code.

### Component 2: Hook Script (`auto-approve.sh`)

**Source**: `claude-pack/hooks/auto-approve.sh`
**Installed to**: `~/.claude/hooks/auto-approve.sh` (symlinked)

This replaces the existing `~/.claude/hooks/auto-approve.sh`. The script preserves the proven structure of the current hook but adds config loading and Tier 2 invocation.

#### Execution Flow

```
Input (JSON on stdin)
  │
  ├─ Parse failure → fall_through (genuine no-opinion)
  │
  ├─ Load config (~/.claude/hooks/allowed-tools.json)
  │   └─ Missing/malformed → use built-in defaults only
  │
  ├─ TIER 1: Fast pattern matching
  │   ├─ File tools (Read/Write/Edit/Glob/Grep)
  │   │   ├─ Path in allowed_paths or /tmp → allow()
  │   │   └─ Path outside → tier2_or_escalate()
  │   │
  │   └─ Bash commands
  │       ├─ Split on && || ;
  │       ├─ Classify each segment:
  │       │   ├─ Built-in safe OR config safe_commands → allow
  │       │   ├─ deny pattern (rm -rf outside /tmp) → deny(reason)
  │       │   ├─ ask pattern (git write ops) → ask_user(reason)
  │       │   └─ unknown → unknown
  │       ├─ Aggregate: deny > ask > unknown > allow
  │       ├─ allow → allow()
  │       ├─ deny → deny(reason)
  │       ├─ ask → ask_user(reason)
  │       └─ unknown → tier2_or_escalate()
  │
  │   └─ Built-in safe tool (Task, WebSearch, etc.) → allow()
  │   └─ Other unhandled tool → tier2_or_fallthrough()
  │
  ├─ TIER 2: Headless Claude review (if tier2_enabled)
  │   ├─ Check claude CLI available → else escalate
  │   ├─ Read review-prompt.md, review-schema.json
  │   ├─ Build prompt with tool context
  │   ├─ timeout 30 claude -p ... --model haiku
  │   ├─ Parse .structured_output.decision:
  │   │   ├─ APPROVE → allow()
  │   │   ├─ PUSH_BACK → deny(reason)  [Claude self-corrects]
  │   │   └─ ELEVATE → ask_user(reason)
  │   └─ Failure/timeout → ask_user("Review unavailable")
  │
  └─ TIER 3: Escalation / fall-through
      ├─ tier2_or_escalate path → ask_user(reason)  [file tools, bash]
      └─ tier2_or_fallthrough path → fall_through()  [unhandled tools]
```

#### Script Structure (sections)

**Section 1: Config loading** (new)

```bash
HOOK_DIR="$(dirname "$0")"
CONFIG_FILE="$HOOK_DIR/allowed-tools.json"

# Load config or use defaults
tier2_enabled=true
declare -a config_paths=()
declare -a config_commands=()

if [[ -f "$CONFIG_FILE" ]] && command -v jq &>/dev/null; then
  tier2_enabled=$(jq -r '.tier2_enabled // true' "$CONFIG_FILE" 2>/dev/null)
  while IFS= read -r p; do
    [[ -n "$p" ]] && config_paths+=("$p")
  done < <(jq -r '.allowed_paths[]? // empty' "$CONFIG_FILE" 2>/dev/null)
  while IFS= read -r c; do
    [[ -n "$c" ]] && config_commands+=("$c")
  done < <(jq -r '.safe_commands[]? // empty' "$CONFIG_FILE" 2>/dev/null)
fi
```

Uses `$(dirname "$0")` to find sibling files — same pattern as `precompact-capture.sh:5`.

**Section 2: Output helpers** (preserved from current, plus new `tier2_or_escalate`)

The existing `allow()`, `deny()`, `ask_user()`, `fall_through()` functions are kept as-is.

New functions:
```bash
tier2_or_escalate() {
  local context="$1"
  if [[ "$tier2_enabled" == "true" ]] && command -v claude &>/dev/null; then
    invoke_tier2 "$context"
  else
    ask_user "Requires confirmation: ${context}"
  fi
}

# For unhandled tools: fall through to default permissions when Tier 2 is disabled,
# rather than forcing ask_user (which would be more restrictive than current behavior)
tier2_or_fallthrough() {
  local context="$1"
  if [[ "$tier2_enabled" == "true" ]] && command -v claude &>/dev/null; then
    invoke_tier2 "$context"
  else
    fall_through
  fi
}
```

**`tier2_or_escalate` vs `tier2_or_fallthrough`**: File tools and bash commands use `tier2_or_escalate` because these are cases where the hook *has an opinion* (the path/command was evaluated and found outside the safe zone) — escalating to the user is appropriate. Unhandled tools use `tier2_or_fallthrough` because the hook *has no opinion* on them — when Tier 2 is disabled, the correct behavior is to defer to Claude Code's default permission system, preserving the current baseline behavior.

**Section 3: Path helpers** (modified `is_allowed_path`)

Replace the hardcoded path checks with a loop over `config_paths`:

```bash
is_allowed_path() {
  local p="${1:-}"
  [[ -z "$p" ]] && return 1
  [[ "$p" == "~/"* ]] && p="$HOME/${p:2}"
  [[ "$p" != /* ]] && p="${cwd_val:-.}/${p}"
  [[ "$p" == *".."* ]] && return 1

  # Built-in: /tmp always allowed
  [[ "$p" == "/tmp/"* || "$p" == "/tmp" ]] && return 0

  # Config-driven allowed paths
  for allowed in "${config_paths[@]}"; do
    [[ "$p" == "${allowed}/"* || "$p" == "${allowed}" ]] && return 0
  done

  return 1
}
```

Note: hardcoded `/home/reid` is replaced with generic `$HOME` expansion.

**Section 4: `classify_segment`** (extended with config commands)

The built-in safe command list stays hardcoded. Config `safe_commands` are checked as an additional case:

```bash
# After the built-in case statement for always-safe commands:
# Check config-driven safe commands
for safe_cmd in "${config_commands[@]}"; do
  [[ "$cmd" == "$safe_cmd" ]] && { seg_result="allow"; return; }
done
```

All other classification logic (git, uv, rm, path-aware tools, gh, .claude/.project scripts) remains unchanged from the current script.

**Section 5: Input parsing** (unchanged)

The single `jq` call with base64 encoding stays exactly as-is.

**Section 6: File tools** (modified — unknown paths go to Tier 2)

```bash
if [[ "$tool_name" =~ ^(Read|Write|Edit|Glob|Grep)$ ]]; then
  if [[ -z "$file_path" ]]; then
    if [[ "$tool_name" == "Glob" || "$tool_name" == "Grep" ]]; then
      is_allowed_path "${cwd_val:-}" && allow "$tool_name" "(cwd: $cwd_val)"
    fi
    tier2_or_escalate "$tool_name (no path resolved)"
  fi
  is_allowed_path "$file_path" && allow "$tool_name" "$file_path"
  tier2_or_escalate "$tool_name $file_path (outside allowed paths)"
fi
```

Key change: `fall_through` → `tier2_or_escalate` for file tools outside allowed paths.

**Section 7: Bash commands** (modified — unknown aggregate goes to Tier 2)

```bash
case "$overall" in
  allow)   allow "Bash" "$command_str" ;;
  ask)     ask_user "Git write operation — requires confirmation" ;;
  deny)    deny "Blocked: $command_str" ;;
  *)       tier2_or_escalate "Bash: $command_str" ;;
esac
```

Key change: the `*` (unknown) case calls `tier2_or_escalate` instead of `fall_through`.

**Section 8: Tier 2 invocation** (new)

```bash
invoke_tier2() {
  local context="$1"
  local prompt_file="$HOOK_DIR/review-prompt.md"
  local schema_file="$HOOK_DIR/review-schema.json"

  # Verify files exist
  if [[ ! -f "$prompt_file" || ! -f "$schema_file" ]]; then
    ask_user "Tier 2 review files missing — please confirm: $context"
    return  # won't reach here (ask_user exits)
  fi

  local system_prompt
  system_prompt=$(<"$prompt_file")
  local schema
  schema=$(<"$schema_file")

  local review_prompt="Review this tool use request:
Tool: ${tool_name}
Input: $(echo "$input" | jq -c '.tool_input' 2>/dev/null)
Working Directory: ${cwd_val}"

  local response
  response=$(timeout 30 claude -p "$review_prompt" \
    --system-prompt "$system_prompt" \
    --model haiku \
    --output-format json \
    --json-schema "$schema" \
    --tools "" \
    --max-turns 3 \
    --no-session-persistence \
    --max-budget-usd 0.05 \
    2>/dev/null) || {
    [[ -f "$AUDIT_LOG" ]] && echo "[$(date +%H:%M:%S)] TIER2-TIMEOUT $context" >> "$AUDIT_LOG"
    ask_user "Tier 2 review timed out — please confirm: $context"
    return
  }

  local decision reason
  decision=$(echo "$response" | jq -r '.structured_output.decision // "ELEVATE"' 2>/dev/null)
  reason=$(echo "$response" | jq -r '.structured_output.reason // "No reason provided"' 2>/dev/null)

  [[ -f "$AUDIT_LOG" ]] && echo "[$(date +%H:%M:%S)] TIER2 decision=$decision reason=$reason context=$context" >> "$AUDIT_LOG"

  case "$decision" in
    APPROVE)  allow "Tier2-approved: $reason" ;;
    PUSH_BACK) deny "Tier 2 review: $reason" ;;
    ELEVATE)  ask_user "Tier 2 escalated: $reason" ;;
    *)        ask_user "Tier 2 unknown response — please confirm: $context" ;;
  esac
}
```

**Section 9: Built-in safe tools** (new)

Before the final catch-all, auto-approve tools that are inherently low-risk and high-frequency. These don't need Tier 2 review because they are either read-only, sandboxed, or internal orchestration tools:

```bash
# Built-in safe tools — auto-approve without Tier 2
case "$tool_name" in
  Task)       allow "Task" "(subagent orchestration)" ;;
  WebSearch)  allow "WebSearch" "(read-only search)" ;;
  WebFetch)   allow "WebFetch" "(read-only fetch)" ;;
  AskUserQuestion) allow "AskUserQuestion" "(user interaction)" ;;
  NotebookEdit)
    # Notebook edits: approve if path is in allowed dirs, else tier2
    local nb_path
    nb_path=$(echo "$input" | jq -r '.tool_input.notebook_path // empty' 2>/dev/null)
    if [[ -n "$nb_path" ]] && is_allowed_path "$nb_path"; then
      allow "NotebookEdit" "$nb_path"
    fi
    tier2_or_escalate "NotebookEdit $nb_path (outside allowed paths)"
    ;;
esac
```

**Rationale**: `Task` spawns subagents (internal orchestration, no external side effects). `WebSearch` and `WebFetch` are read-only. `AskUserQuestion` prompts the user (inherently safe). `NotebookEdit` is path-gated like other file tools. These tools would otherwise hit Tier 2 on every invocation, adding 3-5s latency to very common operations.

**Section 10: Final catch-all** (modified)

```bash
tier2_or_fallthrough "${tool_name:-unknown} (unhandled tool)"
```

Uses `tier2_or_fallthrough` (not `tier2_or_escalate`) — for truly unrecognized tools (MCP tools, future Claude Code tools, etc.), the hook has no opinion. When Tier 2 is enabled, it gets an AI review. When Tier 2 is disabled, it falls through to Claude Code's default permission system, preserving the current baseline behavior.

### Component 3: Review Prompt (`review-prompt.md`)

**Source**: `claude-pack/hooks/review-prompt.md`
**Installed to**: `~/.claude/hooks/review-prompt.md` (symlinked)

```markdown
You are a tool use security reviewer for a developer workstation running Claude Code.

You will receive a tool use request with the tool name, input arguments, and working
directory. This request was NOT auto-approved by the fast pattern-matching tier, which
means it falls outside the user's configured safe operations.

Evaluate the request and return one of three decisions:

## APPROVE
The operation is safe and routine. Use this when:
- The operation is read-only or low-risk
- The tool arguments target reasonable paths and resources
- The command is a standard development operation (build, test, lint)
- No sensitive files, credentials, or system resources are at risk

## PUSH_BACK
The operation is concerning and should be questioned. Use this when:
- The command could have unintended side effects
- File operations target directories that seem outside the project scope
- The command pattern looks like it could be simplified or made safer
- Network operations target unfamiliar endpoints
- The operation modifies configuration files or system state

Your reason will be shown to Claude, who will reconsider and try a safer approach.
Write the reason as constructive feedback: explain WHAT is concerning and suggest
a safer alternative if possible.

## ELEVATE
The operation requires human review. Use this when:
- Destructive operations on important files (rm -rf on non-tmp dirs)
- Operations that could exfiltrate data (curl with file uploads, network sends)
- System-level changes (modifying PATH, installing global packages)
- Operations you genuinely cannot assess for safety
- Any operation involving credentials, secrets, or authentication tokens

When in doubt between PUSH_BACK and ELEVATE, prefer PUSH_BACK — it lets Claude
self-correct without bothering the user.
```

### Component 4: Review Schema (`review-schema.json`)

**Source**: `claude-pack/hooks/review-schema.json`
**Installed to**: `~/.claude/hooks/review-schema.json` (symlinked)

```json
{
  "type": "object",
  "properties": {
    "decision": {
      "type": "string",
      "enum": ["APPROVE", "PUSH_BACK", "ELEVATE"]
    },
    "reason": {
      "type": "string",
      "description": "Concise explanation for the decision"
    }
  },
  "required": ["decision", "reason"]
}
```

### Component 5: `/_my_allow_tool` Command

**Source**: `claude-pack/commands/_my_allow_tool.md`

This is a Claude Code command (markdown instructions) that guides Claude to read and edit the JSON config file. Claude has native JSON editing capabilities via Read/Edit tools.

**Supported actions:**

| Action | Trigger | What it does |
|--------|---------|--------------|
| `add path` | "add path ~/myproject" | Appends to `allowed_paths` |
| `add command` | "add command node" | Appends to `safe_commands` |
| `remove path` | "remove path ~/myproject" | Removes from `allowed_paths` |
| `remove command` | "remove command node" | Removes from `safe_commands` |
| `list` | "list", "show" | Displays current config |
| `toggle tier2` | "enable/disable tier2" | Flips `tier2_enabled` |

**Process for each action:**

1. Read `~/.claude/hooks/allowed-tools.json`
2. Validate input (path exists for `add path`, command name is reasonable)
3. Check for duplicates
4. Modify the JSON
5. Write back using the Write tool
6. Report what changed

The command should normalize paths (expand `~`, resolve relative paths to absolute, ensure trailing slash consistency) and validate that added paths are directories that exist.

### Component 6: `setup-global.sh` Changes

**File**: `scripts/setup-global.sh`

**Change 1**: Config file copy logic (after hook symlink loop, around line 121)

The existing symlink loop at lines 117-121 will automatically symlink `auto-approve.sh`, `review-prompt.md`, and `review-schema.json`. However, `allowed-tools.default.json` should NOT be symlinked. Instead, add a new step after the loop:

```bash
# Copy default config if not exists (user-specific, not symlinked)
config_source="$CLAUDE_PACK/hooks/allowed-tools.default.json"
config_target="$TARGET_DIR/hooks/allowed-tools.json"
if [ -f "$config_source" ]; then
    if [ "$DRY_RUN" = true ]; then
        if [ -e "$config_target" ]; then
            echo -e "${YELLOW}[DRY RUN] Would skip (exists): allowed-tools.json${NC}"
        else
            echo -e "${GREEN}[DRY RUN] Would copy default config: allowed-tools.json${NC}"
        fi
    elif [ ! -e "$config_target" ]; then
        cp "$config_source" "$config_target"
        echo -e "${GREEN}  ✓ allowed-tools.json (default config)${NC}"
    else
        echo -e "${YELLOW}  ⚠ allowed-tools.json already exists (preserved)${NC}"
    fi
fi
```

The `.default.json` extension prevents it from being picked up by the `*` glob in the symlink loop (since the loop does `$CLAUDE_PACK/hooks/*` but we only want to copy it, not symlink it). Actually wait — the glob `$CLAUDE_PACK/hooks/*` WILL match it. We need to either:
- (a) Exclude it in the symlink loop, or
- (b) Rename it to not live in `hooks/` (e.g., `claude-pack/config/allowed-tools.default.json`)

Option (a) is simpler — add a skip condition in the loop:

```bash
for file in "$CLAUDE_PACK"/hooks/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    # Skip default config (copied, not symlinked)
    [[ "$filename" == *.default.json ]] && continue
    create_symlink "$file" "$TARGET_DIR/hooks/$filename" "$filename"
done
```

**Change 1b**: Migration for existing `auto-approve.sh` (before symlink loop)

If the user has the old hardcoded `auto-approve.sh` (a regular file, not a symlink), `create_symlink` will skip it and the new version won't be installed. Add migration logic:

```bash
# Migrate existing auto-approve.sh (old hardcoded version → new symlinked version)
local existing_hook="$TARGET_DIR/hooks/auto-approve.sh"
if [ -f "$existing_hook" ] && [ ! -L "$existing_hook" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] Would back up existing auto-approve.sh → auto-approve.sh.bak${NC}"
    else
        cp "$existing_hook" "${existing_hook}.bak"
        rm "$existing_hook"
        echo -e "${YELLOW}  ⚠ Backed up existing auto-approve.sh → auto-approve.sh.bak${NC}"
        echo -e "${YELLOW}    (Old hardcoded hook replaced with config-driven version)${NC}"
    fi
fi
```

This backs up the old file and removes it so the symlink loop can create the new symlink. The backup is preserved at `auto-approve.sh.bak` in case the user needs to reference their old customizations.

**Change 2**: PreToolUse hook config in `configure_hooks()` (line 153-167)

Expand the `hook_config` to include both PreCompact and PreToolUse:

```bash
local auto_approve_path="$TARGET_DIR/hooks/auto-approve.sh"
local hook_config='{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "'"$hook_path"'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$auto_approve_path"'",
            "timeout": 60
          }
        ]
      }
    ]
  }
}'
```

**Timeout**: Set to 60 seconds (not the 5s in the current settings.json) to allow time for Tier 2 headless Claude invocation (~30s timeout + overhead). The current user's settings.json uses `"timeout": 5` which would be too short for Tier 2.

**Matcher**: A single catch-all matcher (`""` matches all tools). The script already handles tool-type routing internally via `$tool_name` checks (file tools, bash, built-in safe tools, final catch-all), so external matcher segmentation provides no additional value. A single entry is easier to maintain — one place to update if the command path or timeout changes.

**Change 3**: Update `.hook-paths.json` entries (line 222-227)

Add new entries:
```json
"auto-approve": "$hooks_dir/auto-approve.sh",
"review-prompt": "$hooks_dir/review-prompt.md",
"review-schema": "$hooks_dir/review-schema.json"
```

### Component 7: `uninstall-global.sh` Changes

**File**: `scripts/uninstall-global.sh`

**Change 1**: Settings cleanup (line 64-68)

The current jq filter only handles `PreCompact`. Extend to also handle `PreToolUse`:

```bash
jq '
  # Clean PreCompact
  if .hooks.PreCompact then
    .hooks.PreCompact = [.hooks.PreCompact[] | select(.hooks | all(.command | contains("/.claude/hooks/") | not))]
  else . end |
  if .hooks.PreCompact == [] then del(.hooks.PreCompact) else . end |
  # Clean PreToolUse
  if .hooks.PreToolUse then
    .hooks.PreToolUse = [.hooks.PreToolUse[] | select(.hooks | all(.command | contains("/.claude/hooks/") | not))]
  else . end |
  if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end |
  # Clean empty hooks object
  if .hooks == {} then del(.hooks) else . end
' "$settings_file" > "$settings_file.tmp"
```

**Change 2**: Remove config file (line 83-89)

Add `allowed-tools.json` to metadata cleanup. Although it's not strictly metadata, it was created by setup and should be cleaned by uninstall. Add to the file list:

```bash
for file in .agentic-pack-source .agentic-pack-version .hook-paths.json hooks/allowed-tools.json; do
```

Note: prompt user before removing `allowed-tools.json` since it may contain user customizations. Or: back it up before removing.

---

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Tier 2 latency** | 3-5s delay on every unknown tool use | Short-circuit: Tier 1 handles 90%+ of cases instantly. Users can disable Tier 2 via config toggle |
| **Tier 2 cost** | ~$0.005-0.015 per review adds up | Tier 1 baseline is generous. Only genuinely unknown operations hit Tier 2. `--max-budget-usd 0.05` caps each call |
| **jq dependency** | Hook fails without jq | `jq` is already required by `setup-global.sh`. Add clear error message at hook top |
| **claude CLI dependency** | Tier 2 fails without claude CLI | Graceful degradation: escalates to Tier 3 (user prompt). No breakage |
| **Timeout interaction** | settings.json timeout vs bash timeout | Set settings.json timeout to 60s, bash `timeout` for claude call to 30s. Bash timeout fires first, script still has time to return ask_user |
| **Shallow merge overwrites** | `jq -s '.[0] * .[1]'` replaces entire `hooks` object | The hook_config includes ALL hook types (PreCompact + PreToolUse), so the merge produces the correct complete result |
| **Config file corruption** | Malformed JSON after bad edit | Hook falls back to built-in defaults. `/_my_allow_tool` validates JSON. Users can reset by deleting the file and re-running setup |
| **Existing auto-approve.sh conflict** | User has the old hardcoded script at same path | setup-global.sh detects non-symlink `auto-approve.sh`, backs it up to `auto-approve.sh.bak`, and replaces with symlink. User retains backup for reference |

---

## Integration Strategy

### How This Fits Into the Pack

- **Installation**: Fully handled by existing `setup-global.sh` flow with targeted modifications. No new scripts needed.
- **First-run experience**: After installation, user runs `/_my_allow_tool add path ~/myproject` to scope their first project. The hook works immediately with Tier 1 built-in rules even before adding paths.
- **Day-to-day use**: Invisible to the user. Tools are auto-approved or reviewed. User is only interrupted for genuinely risky operations.
- **Updates**: `git pull` in source repo updates the hook script, review prompt, and schema via symlinks. Config file is preserved (user data).
- **Customization**: Users can edit `review-prompt.md` by breaking the symlink (`cp ~/.claude/hooks/review-prompt.md ~/.claude/hooks/review-prompt.md.bak && cp ~/.claude/hooks/review-prompt.md.bak ~/.claude/hooks/review-prompt.md`). Or they can just edit the symlink target if they're contributing back.

### Relationship to Existing Components

| Component | Relationship |
|-----------|-------------|
| `precompact-capture.sh` | Unchanged. Lives alongside the new hook. Different event type (PreCompact vs PreToolUse) |
| `setup-global.sh` | Extended with PreToolUse config and config-file copy logic |
| `uninstall-global.sh` | Extended with PreToolUse cleanup |
| `settings.json` | Gets new PreToolUse entries alongside existing PreCompact |
| `_my_allow_tool.md` | New command. Joins existing `_my_*` commands |

---

## Validation Approach

### Testing Strategy

1. **Tier 1 unit tests** (manual): Invoke the hook with crafted JSON on stdin, verify correct decisions for:
   - File tool in allowed path → allow
   - File tool outside allowed path → tier2/ask
   - Safe bash command → allow
   - Git write command → ask
   - rm -rf outside /tmp → deny
   - Unknown command → tier2/ask
   - Config safe_commands → allow

2. **Tier 2 integration test**: Verify headless Claude invocation with a known-safe and known-risky command, confirm structured output parsing.

3. **Config operations**: Test `/_my_allow_tool` add/remove/list/toggle for each action type.

4. **Installation test**: Run `setup-global.sh --dry-run` and verify new artifacts appear in output.

5. **Graceful degradation**: Test with `tier2_enabled: false`, test with `claude` CLI removed from PATH, test with missing config file.

### Success Criteria (from spec)

- Tier 1 completes in <100ms (no external calls)
- Tier 2 completes in <10s
- Missing config falls back to defaults without error
- Audit log captures all tier decisions
- All acceptance criteria from spec are met

---

**Next Step:** After approval → `/_my_plan` (to break into implementation phases) or `/_my_implement` (if ready to implement directly)
