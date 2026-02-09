#!/bin/bash
# PreToolUse auto-approve hook — two-tier review pipeline
# Tier 1: Fast bash pattern matching → auto-approve or auto-elevate
# Tier 2: Headless Claude (Haiku) review → approve, push back, or elevate
#
# Config: ~/.claude/hooks/allowed-tools.json (managed by /_my_allow_tool)

AUDIT_LOG="/tmp/claude-hook-audit.log"
PUSHBACK_HASH_FILE="/tmp/claude-hook-last-pushback.hash"

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
send_to_tier2() {
  local context="$1"
  if [[ "$tier2_enabled" == "true" ]] && command -v claude &>/dev/null; then
    invoke_tier2 "$context"
  else
    ask_user "Requires confirmation: ${context}"
  fi
}

# Tier 2 invocation — headless Claude review
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

  # Check if this is a retry of a previously pushed-back request
  local request_hash is_retry=false
  request_hash=$(echo "$input" | md5sum | cut -d' ' -f1)
  if [[ -f "$PUSHBACK_HASH_FILE" ]] && [[ "$(cat "$PUSHBACK_HASH_FILE")" == "$request_hash" ]]; then
    is_retry=true
  fi

  # Build context section with tool description
  local context_section=""
  if [[ -n "$description" ]]; then
    context_section="Agent's stated purpose: ${description}"
  fi

  # Extract recent transcript context (last few assistant/user text messages)
  local transcript_context=""
  if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    transcript_context=$(tail -50 "$transcript_path" | jq -r '
      select(.type == "assistant" or .type == "user") |
      if .type == "user" then
        "User: " + (.message.content // "" | if type == "string" then .[:200] else "" end)
      elif .type == "assistant" then
        (.message.content // [] | if type == "array" then
          [.[] | select(.type == "text") | .text[:200]] | join(" ")
        else "" end) | if . != "" then "Assistant: " + . else empty end
      else empty end
    ' 2>/dev/null | tail -10)
  fi

  local review_prompt="Review this tool use request:
Tool: ${tool_name}
Input: $(echo "$input" | jq -c '.tool_input' 2>/dev/null)
Working Directory: ${cwd_val}"

  if [[ -n "$context_section" ]]; then
    review_prompt="${review_prompt}

${context_section}"
  fi

  if [[ -n "$transcript_context" ]]; then
    review_prompt="${review_prompt}

Recent conversation context:
${transcript_context}"
  fi

  if [[ "$is_retry" == true ]]; then
    review_prompt="${review_prompt}

IMPORTANT: This is a RETRY of a previously pushed-back request. The agent has already been asked to reconsider. You MUST choose either APPROVE or ELEVATE. Do NOT choose PUSH_BACK."
  fi

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
    APPROVE)
      rm -f "$PUSHBACK_HASH_FILE"
      allow "Tier2-approved: $reason"
      ;;
    PUSH_BACK)
      if [[ "$is_retry" == true ]]; then
        rm -f "$PUSHBACK_HASH_FILE"
        ask_user "Tier 2 could not decide — please confirm: $context"
      else
        echo "$request_hash" > "$PUSHBACK_HASH_FILE"
        deny "Tier 2 review: $reason"
      fi
      ;;
    ELEVATE)
      rm -f "$PUSHBACK_HASH_FILE"
      ask_user "Tier 2 escalated: $reason"
      ;;
    *)
      ask_user "Tier 2 unknown response — please confirm: $context"
      ;;
  esac
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
    is_allowed_path "${cwd_val:-}" && check_result="safe" || check_result="review"
  elif [[ "$all_ok" == true ]]; then
    check_result="safe"
  else
    check_result="review"
  fi
}

# =============================================================================
# Section 4: classify_segment — sets seg_result variable (no subshell)
# Values: safe | elevate | review
# =============================================================================
classify_segment() {
  local seg="$1"
  seg_result="review"

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
      seg_result="safe"; return ;;
  esac

  # Config-driven safe commands
  for safe_cmd in "${config_commands[@]}"; do
    [[ "$cmd" == "$safe_cmd" ]] && { seg_result="safe"; return; }
  done

  if [[ "$cmd" == "git" ]]; then
    local rest="${seg#*git }"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    # Skip global git flags (e.g., -C <path>, --no-pager, -c key=val)
    while [[ -n "$rest" && "${rest%% *}" == -* ]]; do
      local flag="${rest%% *}"
      rest="${rest#"$flag"}"
      rest="${rest#"${rest%%[![:space:]]*}"}"
      # Flags that consume a separate argument — skip it too
      case "$flag" in
        -C|-c|--git-dir|--work-tree|--namespace)
          rest="${rest#"${rest%% *}"}"
          rest="${rest#"${rest%%[![:space:]]*}"}"
          ;;
      esac
    done
    local subcmd="${rest%% *}"
    case "$subcmd" in
      status|diff|log|branch|show|remote|tag|stash|fetch|ls-files|rev-parse|describe|shortlog|reflog|config|count-objects)
        if [[ "$seg" != *"--hard"* && "$seg" != *"--force"* && "$seg" != *" -f "* && "$seg" != *" -D "* ]]; then
          seg_result="safe"; return
        fi
        ;;
      commit|push|add|rebase|reset|checkout|merge|cherry-pick|revert|clean|restore|switch|pull)
        seg_result="elevate"; return ;;
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
            seg_result="safe"; return ;;
        esac
        ;;
      pip|venv|sync|lock|tree)
        seg_result="safe"; return ;;
    esac
    return
  fi

  case "$cmd" in
    python|python3|pytest|mypy|ruff|black|isort|pip|pip3)
      seg_result="safe"; return ;;
    claude)
      [[ "$seg" == *"--version"* || "$seg" == *"--help"* ]] && seg_result="safe"
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
        seg_result="safe"
      else
        seg_result="review"
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
          seg_result="safe"; return
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
            seg_result="safe"; return ;;
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

# Extract tool description (Claude's stated purpose) and transcript path
description=""
transcript_path=""
description=$(echo "$input" | jq -r '.tool_input.description // ""' 2>/dev/null) || description=""
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null) || transcript_path=""

# If parsing failed, send to tier2 for review
[[ -z "$tool_name" ]] && send_to_tier2 "(parse failure)"

# =============================================================================
# Section 6: Decision pipeline — every tool call ends here
# =============================================================================

# --- File tools ---
if [[ "$tool_name" =~ ^(Read|Write|Edit|Glob|Grep)$ ]]; then
  if [[ -n "$file_path" ]] && is_allowed_path "$file_path"; then
    allow "$tool_name" "$file_path"
  fi
  if [[ -z "$file_path" ]] && [[ "$tool_name" == "Glob" || "$tool_name" == "Grep" ]]; then
    is_allowed_path "${cwd_val:-}" && allow "$tool_name" "(cwd: $cwd_val)"
  fi
  send_to_tier2 "$tool_name ${file_path:-(no path)}"
fi

# --- Built-in safe tools ---
case "$tool_name" in
  Task|WebSearch|WebFetch|AskUserQuestion)
    allow "$tool_name" "(built-in safe)" ;;
  NotebookEdit)
    nb_path=$(echo "$input" | jq -r '.tool_input.notebook_path // empty' 2>/dev/null)
    if [[ -n "$nb_path" ]] && is_allowed_path "$nb_path"; then
      allow "NotebookEdit" "$nb_path"
    fi
    send_to_tier2 "NotebookEdit ${nb_path:-unknown}" ;;
esac

# --- Bash commands ---
if [[ "$tool_name" == "Bash" ]]; then
  [[ -z "$command_str" ]] && send_to_tier2 "Bash (empty command)"

  segments=()
  while IFS= read -r seg; do
    seg="${seg#"${seg%%[![:space:]]*}"}"
    seg="${seg%"${seg##*[![:space:]]}"}"
    [[ -n "$seg" ]] && segments+=("$seg")
  done < <(echo "$command_str" | sed 's/ && /\n/g; s/ || /\n/g; s/ ; /\n/g')
  [[ ${#segments[@]} -eq 0 ]] && segments=("$command_str")

  worst="safe"
  for seg in "${segments[@]}"; do
    classify_segment "$seg"
    case "$seg_result" in
      elevate) worst="elevate" ;;
      review)  [[ "$worst" != "elevate" ]] && worst="review" ;;
      safe)    ;;
    esac
  done

  case "$worst" in
    safe)    allow "Bash" "$command_str" ;;
    elevate) ask_user "Requires confirmation: $command_str" ;;
    review)  send_to_tier2 "Bash: $command_str" ;;
  esac
fi

# --- Everything else ---
send_to_tier2 "${tool_name:-unknown} (unhandled tool)"
