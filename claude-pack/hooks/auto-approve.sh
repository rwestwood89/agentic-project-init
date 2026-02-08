#!/bin/bash
# PreToolUse auto-approve hook — config-driven, three-tier review pipeline
# Tier 1: Fast bash pattern matching (built-in + config safe lists)
# Tier 2: Headless Claude (Haiku) review for uncertain cases
# Tier 3: Escalation to user prompt
#
# Config: ~/.claude/hooks/allowed-tools.json (managed by /_my_allow_tool)

AUDIT_LOG="/tmp/claude-hook-audit.log"

# =============================================================================
# Section 1: Config loading
# =============================================================================
HOOK_DIR="$(dirname "$0")"
CONFIG_FILE="$HOOK_DIR/allowed-tools.json"

# Load config or use defaults
tier2_enabled=true
declare -a config_paths=()
declare -a config_commands=()

if [[ -f "$CONFIG_FILE" ]] && command -v jq &>/dev/null; then
  tier2_enabled=$(jq -r 'if .tier2_enabled == false then "false" else "true" end' "$CONFIG_FILE" 2>/dev/null)
  while IFS= read -r p; do
    [[ -n "$p" ]] && config_paths+=("$p")
  done < <(jq -r '.allowed_paths[]? // empty' "$CONFIG_FILE" 2>/dev/null)
  while IFS= read -r c; do
    [[ -n "$c" ]] && config_commands+=("$c")
  done < <(jq -r '.safe_commands[]? // empty' "$CONFIG_FILE" 2>/dev/null)
fi

# =============================================================================
# Section 2: Output helpers — ALL use stdout + exit 0 with hookEventName
# =============================================================================
allow() {
  [[ -f "$AUDIT_LOG" ]] && echo "[$(date +%H:%M:%S)] ALLOW $*" >> "$AUDIT_LOG" || true
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
}
deny() {
  [[ -f "$AUDIT_LOG" ]] && echo "[$(date +%H:%M:%S)] DENY $*" >> "$AUDIT_LOG" || true
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}
ask_user() {
  [[ -f "$AUDIT_LOG" ]] && echo "[$(date +%H:%M:%S)] ASK $*" >> "$AUDIT_LOG" || true
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}
fall_through() {
  [[ -f "$AUDIT_LOG" ]] && echo "[$(date +%H:%M:%S)] FALL-THROUGH $*" >> "$AUDIT_LOG" || true
  exit 0
}

# Tier 2 routing: for file tools and bash commands where the hook HAS an opinion
# (the path/command was evaluated and found outside the safe zone)
tier2_or_escalate() {
  local context="$1"
  if [[ "$tier2_enabled" == "true" ]] && command -v claude &>/dev/null; then
    invoke_tier2 "$context"
  else
    ask_user "Requires confirmation: ${context}"
  fi
}

# Tier 2 routing: for unhandled tools where the hook has NO opinion
# When Tier 2 is disabled, fall through to Claude Code's default permission system
tier2_or_fallthrough() {
  local context="$1"
  if [[ "$tier2_enabled" == "true" ]] && command -v claude &>/dev/null; then
    invoke_tier2 "$context"
  else
    fall_through "$context"
  fi
}

# =============================================================================
# Section 3: Path helpers (pure bash, no external commands)
# =============================================================================
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

is_tmp_path() {
  local p="${1:-}"
  [[ -z "$p" ]] && return 1
  [[ "$p" != /* ]] && p="${cwd_val:-.}/${p}"
  [[ "$p" == /tmp/* || "$p" == /tmp ]]
}

first_word() {
  local s="${1:-}"
  s="${s#"${s%%[![:space:]]*}"}"
  echo "${s%% *}"
}

check_path_args() {
  local seg="$1"
  local all_ok=true found=false word
  local rest="${seg#* }"
  [[ "$rest" == "$seg" ]] && rest=""
  for word in $rest; do
    [[ "$word" == -* || -z "$word" ]] && continue
    found=true
    if ! is_allowed_path "$word"; then
      all_ok=false; break
    fi
  done
  if [[ "$found" == false ]]; then
    is_allowed_path "${cwd_val:-}" && check_result="allow" || check_result="unknown"
  elif [[ "$all_ok" == true ]]; then
    check_result="allow"
  else
    check_result="unknown"
  fi
}

# =============================================================================
# Section 4: classify_segment — sets seg_result variable (no subshell)
# Values: allow | deny | ask | unknown
# =============================================================================
classify_segment() {
  local seg="$1"
  seg_result="unknown"

  local cmd="$seg"
  cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  while [[ "$cmd" =~ ^[A-Z_][A-Z_0-9]*=[^[:space:]]* ]]; do
    cmd="${cmd#* }"
  done
  cmd=$(first_word "$cmd")
  cmd="${cmd##*/}"

  # Built-in always-safe commands
  case "$cmd" in
    cd|ls|pwd|echo|printf|which|date|whoami|true|false|test|\[|env|export|source|type|command|tee|xargs|grep|sed|awk|tr|cut|jq|wc|sort|uniq|head|tail)
      seg_result="allow"; return ;;
  esac

  # Config-driven safe commands
  for safe_cmd in "${config_commands[@]}"; do
    [[ "$cmd" == "$safe_cmd" ]] && { seg_result="allow"; return; }
  done

  if [[ "$cmd" == "git" ]]; then
    local rest="${seg#*git }"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    local subcmd="${rest%% *}"
    case "$subcmd" in
      status|diff|log|branch|show|remote|tag|stash|fetch|ls-files|rev-parse|describe|shortlog|reflog|config)
        if [[ "$seg" != *"--hard"* && "$seg" != *"--force"* && "$seg" != *" -f "* && "$seg" != *" -D "* ]]; then
          seg_result="allow"; return
        fi
        ;;
      commit|push|add|rebase|reset|checkout|merge|cherry-pick|revert|clean|restore|switch|pull)
        seg_result="ask"; return ;;
    esac
    return
  fi

  if [[ "$cmd" == "uv" ]]; then
    local rest="${seg#*uv }"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    local uv_sub="${rest%% *}"
    case "$uv_sub" in
      run)
        local run_rest="${rest#run }"
        run_rest="${run_rest#"${run_rest%%[![:space:]]*}"}"
        local target="${run_rest%% *}"
        case "$target" in
          python|python3|pytest|mypy|ruff|sysml-codegen|agentic-mbse|black|isort)
            seg_result="allow"; return ;;
        esac
        ;;
      pip|venv|sync|lock|tree)
        seg_result="allow"; return ;;
    esac
    return
  fi

  case "$cmd" in
    python|python3|pytest|mypy|ruff|black|isort|pip|pip3)
      seg_result="allow"; return ;;
    claude)
      [[ "$seg" == *"--version"* || "$seg" == *"--help"* ]] && seg_result="allow"
      return ;;
  esac

  if [[ "$cmd" == "rm" ]]; then
    if [[ "$seg" == *"-"*"r"* || "$seg" == *"-"*"f"* ]]; then
      local all_tmp=true found_path=false word
      local rest="${seg#* }"
      for word in $rest; do
        [[ "$word" == -* || -z "$word" ]] && continue
        found_path=true
        if ! is_tmp_path "$word"; then
          all_tmp=false; break
        fi
      done
      if [[ "$found_path" == true && "$all_tmp" == true ]]; then
        seg_result="allow"
      else
        seg_result="deny"
      fi
      return
    fi
    return
  fi

  case "$cmd" in
    cp|mv|mkdir|touch|cat|find|tree|file|stat|realpath|dirname|basename|less|more|diff)
      check_path_args "$seg"
      seg_result="$check_result"
      return ;;
  esac

  if [[ "$seg" == *".claude/"*".sh"* || "$seg" == *".project/"*".sh"* ]]; then
    local word
    for word in $seg; do
      if [[ "$word" == *".claude/"*".sh" || "$word" == *".project/"*".sh" ]]; then
        if is_allowed_path "$word"; then
          seg_result="allow"; return
        fi
      fi
    done
  fi

  if [[ "$cmd" == "gh" ]]; then
    local rest="${seg#*gh }"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    local gh_sub="${rest%% *}"
    case "$gh_sub" in
      pr|issue|repo|api|run)
        local action_rest="${rest#* }"
        action_rest="${action_rest#"${action_rest%%[![:space:]]*}"}"
        local gh_action="${action_rest%% *}"
        case "$gh_action" in
          view|list|status|diff|checks|show)
            seg_result="allow"; return ;;
        esac
        ;;
    esac
    return
  fi
}

# =============================================================================
# Section 5: Input parsing — single jq call, base64 for command (may contain newlines)
# =============================================================================
input=$(cat) || true
tool_name=""
cwd_val=""
file_path=""
command_b64=""

{
  read -r tool_name
  read -r cwd_val
  read -r file_path
  read -r command_b64
} < <(echo "$input" | jq -r '
  (.tool_name // ""),
  (.cwd // ""),
  (.tool_input.file_path // .tool_input.path // ""),
  ((.tool_input.command // "") | @base64)
' 2>/dev/null) || true

command_str=$(echo "${command_b64:-}" | base64 -d 2>/dev/null) || command_str=""

# If parsing failed, fall through silently
[[ -z "$tool_name" ]] && fall_through "(parse failure)"

# =============================================================================
# Section 6: File tools (Read, Write, Edit, Glob, Grep)
# =============================================================================
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

# =============================================================================
# Section 7: Bash commands
# =============================================================================
if [[ "$tool_name" == "Bash" ]]; then
  [[ -z "$command_str" ]] && fall_through "Bash" "(empty command)"

  segments=()
  while IFS= read -r seg; do
    seg="${seg#"${seg%%[![:space:]]*}"}"
    seg="${seg%"${seg##*[![:space:]]}"}"
    [[ -n "$seg" ]] && segments+=("$seg")
  done < <(echo "$command_str" | sed 's/ && /\n/g; s/ || /\n/g; s/ ; /\n/g')
  [[ ${#segments[@]} -eq 0 ]] && segments=("$command_str")

  overall="allow"
  seg_result=""

  for seg in "${segments[@]}"; do
    classify_segment "$seg"
    case "$seg_result" in
      deny)  deny "$seg" ;;
      ask)   overall="ask" ;;
      allow) ;;
      *)     [[ "$overall" == "allow" ]] && overall="unknown" ;;
    esac
  done

  case "$overall" in
    allow)   allow "Bash" "$command_str" ;;
    ask)     ask_user "Git write operation — requires confirmation" ;;
    deny)    deny "Blocked: $command_str" ;;
    *)       tier2_or_escalate "Bash: $command_str" ;;
  esac
fi

# =============================================================================
# Section 8: Tier 2 invocation — headless Claude review
# =============================================================================
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
    APPROVE)   allow "Tier2-approved: $reason" ;;
    PUSH_BACK) deny "Tier 2 review: $reason" ;;
    ELEVATE)   ask_user "Tier 2 escalated: $reason" ;;
    *)         ask_user "Tier 2 unknown response — please confirm: $context" ;;
  esac
}

# =============================================================================
# Section 9: Built-in safe tools — auto-approve without Tier 2
# =============================================================================
case "$tool_name" in
  Task)            allow "Task" "(subagent orchestration)" ;;
  WebSearch)       allow "WebSearch" "(read-only search)" ;;
  WebFetch)        allow "WebFetch" "(read-only fetch)" ;;
  AskUserQuestion) allow "AskUserQuestion" "(user interaction)" ;;
  NotebookEdit)
    # Notebook edits: approve if path is in allowed dirs, else tier2
    nb_path=$(echo "$input" | jq -r '.tool_input.notebook_path // empty' 2>/dev/null)
    if [[ -n "$nb_path" ]] && is_allowed_path "$nb_path"; then
      allow "NotebookEdit" "$nb_path"
    fi
    tier2_or_escalate "NotebookEdit ${nb_path:-unknown} (outside allowed paths)"
    ;;
esac

# =============================================================================
# Section 10: Final catch-all — unhandled tools
# =============================================================================
tier2_or_fallthrough "${tool_name:-unknown} (unhandled tool)"
