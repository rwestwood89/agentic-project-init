# Design: Simplify auto-approve.sh Decision Pipeline

**Status:** Draft
**Owner:** Reid Westwood
**Created:** 2026-02-09
**Branch:** allowed-tools

## Related Artifacts

- **Spec:** `.project/active/simplify-auto-approve/spec.md`
- **Source:** `claude-pack/hooks/auto-approve.sh`
- **Review prompt:** `claude-pack/hooks/review-prompt.md`
- **Review schema:** `claude-pack/hooks/review-schema.json`

---

## How It Works

Every tool call Claude makes hits `auto-approve.sh`. The hook decides what
happens. There are only two tiers, and every call goes through exactly one:

```
                        ┌──────────────────┐
                        │   Tool call in   │
                        └────────┬─────────┘
                                 │
                    ┌────────────┴────────────┐
                    │    Tier 1: Pattern      │
                    │    matching (bash)       │
                    └────────────┬────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                   │
         Known safe        Known needs          Everything
         operation          human OK              else
              │                  │                   │
              ▼                  ▼                   ▼
         ┌────────┐      ┌────────────┐    ┌────────────────┐
         │ APPROVE │      │ ASK USER   │    │  Tier 2:       │
         │ (auto)  │      │ (auto)     │    │  Subagent      │
         └────────┘      └────────────┘    │  (Haiku)       │
                                            └───────┬────────┘
                                                    │
                                       ┌────────────┼───────────┐
                                       │            │            │
                                   APPROVE     PUSH BACK     ELEVATE
                                       │            │            │
                                       ▼            ▼            ▼
                                  ┌────────┐  ┌──────────┐  ┌──────────┐
                                  │ APPROVE │  │ DENY w/  │  │ ASK USER │
                                  │         │  │ reason   │  │          │
                                  └────────┘  └──────────┘  └──────────┘
                                                    │
                                              Claude adjusts
                                              and retries
                                                    │
                                                    ▼
                                            ┌──────────────┐
                                            │  Same request │──→ APPROVE
                                            │  again?       │    or
                                            │  No PUSH BACK │──→ ELEVATE
                                            │  allowed      │    only
                                            └──────────────┘
```

### The three outcomes (and ONLY these three)

| Outcome | Hook protocol | What the user sees | Who decides |
|---------|--------------|-------------------|-------------|
| **Approve** | `permissionDecision: "allow"` | Nothing — Claude proceeds silently | Tier 1 pattern match OR Tier 2 subagent |
| **Push back** | `permissionDecision: "deny"` | Nothing — Claude sees reason, tries differently | Tier 2 subagent ONLY (never Tier 1) |
| **Elevate** | `permissionDecision: "ask"` | User gets prompted to approve/deny | Tier 1 auto-elevate OR Tier 2 subagent |

### What goes where

**Tier 1 auto-approve** (fast, no subagent):
- Read-only commands: `ls`, `cat`, `grep`, `jq`, `head`, `tail`, etc.
- Dev tools: `python`, `pytest`, `ruff`, `mypy`, `pip`, etc.
- Read-only git: `git status`, `git diff`, `git log`, `git -C /path diff`, etc.
- Safe uv: `uv run pytest`, `uv pip install`, `uv sync`, etc.
- File tools on allowed paths: Read/Write/Edit/Glob/Grep within configured dirs
- Built-in safe tools: Task, WebSearch, WebFetch, AskUserQuestion
- Config-driven: anything in `allowed-tools.json` safe_commands/allowed_paths

**Tier 1 auto-elevate** (straight to user, no subagent):
- Git write ops: `commit`, `push`, `add`, `rebase`, `reset`, `checkout`, etc.

**Tier 2 subagent** (everything else):
- Bash commands not in safe list: `npm`, `curl`, `docker`, `make`, etc.
- `rm -rf` on non-tmp paths
- File tools outside allowed paths
- Unknown/unhandled tools
- NotebookEdit outside allowed paths

### The push-back loop problem and how we solve it

When the subagent pushes back, Claude gets a reason and retries. But if
Claude retries the exact same command, the subagent would push back again
with the same reasoning → infinite loop.

**Solution:** We hash each request. On PUSH_BACK, we store the hash. If
the next request has the same hash, we tell the subagent "you already
pushed back on this — choose APPROVE or ELEVATE only." If the subagent
still says PUSH_BACK (ignoring the instruction), we force-escalate to
the user.

```
Request #1:  npm install  →  hash=abc123  →  subagent: PUSH_BACK
                                              store abc123

Request #2:  npm install  →  hash=abc123  →  matches stored hash!
                                              tell subagent: no PUSH_BACK
                                              subagent: APPROVE or ELEVATE
                                              clear stored hash
```

### When Tier 2 is unavailable

If `claude` CLI isn't installed or `tier2_enabled: false` in config:
everything that isn't auto-approved gets elevated to the user. No
silent failures, no fall-through.

---

## Research Findings

### Current script structure (auto-approve.sh, 464 lines)

The script has 9 sections but the logic is hard to follow because:

1. **4 outcome functions** with overlapping semantics: `allow()`, `deny()`, `ask_user()`, `fall_through()`
2. **2 routing functions** to Tier 2 with different fallbacks: `tier2_or_escalate()` (falls back to ask_user), `tier2_or_fallthrough()` (falls back to silent exit)
3. **`classify_segment` returns 4 values** (`allow`, `deny`, `ask`, `unknown`) then Section 7 maps these through a second aggregation step (`overall`) before dispatching — two levels of indirection
4. **Bypass paths**: git write ops → `ask` (skips subagent), rm -rf non-tmp → `ask` (skips subagent), catch-all → `fall_through` (skips everything)

### What's actually good (keep as-is)

- **Section 1 (config loading):** Clean, works fine
- **Section 3 (path helpers):** `is_allowed_path()`, `is_tmp_path()`, `first_word()`, `check_path_args()` — all pure functions, no issues
- **Section 4 (classify_segment):** The pattern-matching logic itself is solid. Only the return values and rm/git special cases need changing
- **Section 5 (input parsing):** Works fine, including the new description/transcript_path extraction
- **`invoke_tier2` body:** The Haiku call mechanics, timeout, context building — all recently improved and working

### Hook protocol (from Claude Code docs)

The hook can return three `permissionDecision` values:
- `"allow"` — auto-approve
- `"deny"` — block with reason (Claude sees reason, adjusts approach)
- `"ask"` — prompt user for confirmation

There is no "fall through" in the protocol — returning empty JSON (`exit 0` with no output) means "no opinion." This is what `fall_through()` currently does.

### PUSH_BACK hash mechanism

For detecting same-request retries, we need:
- A hash of the request identity (tool_name + tool_input is sufficient)
- Storage in `/tmp` (lightweight, cleared on reboot)
- Check before calling subagent, write after PUSH_BACK

`md5sum` is available on all Linux systems and fast. A single temp file per-session would work, but simpler: one file keyed by hash name. Or simplest: store just the last pushed-back hash in a single file.

Simplest approach: `/tmp/claude-hook-last-pushback.hash` containing the md5 of the last pushed-back request. On each subagent call, compare. On PUSH_BACK, write. On APPROVE/ELEVATE, clear.

### Review prompt and schema

Current `review-prompt.md` and `review-schema.json` support APPROVE/PUSH_BACK/ELEVATE. No changes needed to the schema. The review prompt needs a small addition for the "no push_back on retry" mode — we can just append a line to the prompt dynamically.

## Proposed Design

### New script structure

```
Section 1: Config loading                          (unchanged)
Section 2: Output helpers + invoke_tier2           (simplified)
Section 3: Path helpers                            (unchanged)
Section 4: classify_segment                        (simplified returns)
Section 5: Input parsing                           (unchanged)
Section 6: Decision pipeline                       (NEW — single linear flow)
```

That's it. 6 sections instead of 9. One linear decision flow instead of scattered if/case blocks.

### Section 2: Output helpers

**Remove:** `fall_through()`, `tier2_or_escalate()`, `tier2_or_fallthrough()`

**Keep:** `allow()`, `deny()`, `ask_user()`

`deny()` still exists but is ONLY callable from inside `invoke_tier2()` on PUSH_BACK. No Tier 1 code path reaches it.

`invoke_tier2()` stays in Section 2 (where we moved it), with one addition: the PUSH_BACK hash check.

### Section 4: classify_segment

**Current returns:** `allow`, `deny`, `ask`, `unknown`
**New returns:** `safe`, `elevate`, `review`

Mapping:
| Current | New | Meaning |
|---|---|---|
| `allow` | `safe` | Auto-approve |
| `deny` (rm -rf non-tmp) | `review` | Send to subagent |
| `ask` (git write ops) | `elevate` | Auto-elevate to user |
| `unknown` (default) | `review` | Send to subagent |

Specific changes inside `classify_segment`:
- Default: `seg_result="review"` (was `"unknown"`)
- All safe commands: `seg_result="safe"` (was `"allow"`)
- Git write ops: `seg_result="elevate"` (was `"ask"`)
- `rm -rf` non-tmp: `seg_result="review"` (was `"deny"`, then `"ask"`)
- `rm` without -r/-f: `seg_result="review"` (was `"unknown"` via implicit return)

### Section 6: Decision pipeline (replaces Sections 6-9)

This is the core simplification. One linear flow:

```bash
# =============================================================================
# Section 6: Decision pipeline
# =============================================================================

# --- File tools ---
if [[ "$tool_name" =~ ^(Read|Write|Edit|Glob|Grep)$ ]]; then
  if [[ -n "$file_path" ]] && is_allowed_path "$file_path"; then
    allow "$tool_name" "$file_path"
  fi
  if [[ -z "$file_path" && ("$tool_name" == "Glob" || "$tool_name" == "Grep") ]]; then
    is_allowed_path "${cwd_val:-}" && allow "$tool_name" "(cwd: $cwd_val)"
  fi
  send_to_tier2 "$tool_name ${file_path:-(no path)} (outside allowed paths)"
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

  # Split on && || ; and classify each segment
  # ... segment splitting (unchanged) ...

  local dominated="safe"  # worst-case across all segments
  for seg in "${segments[@]}"; do
    classify_segment "$seg"
    case "$seg_result" in
      elevate) dominated="elevate" ;;
      review)  [[ "$dominated" != "elevate" ]] && dominated="review" ;;
      safe)    ;;
    esac
  done

  case "$dominated" in
    safe)    allow "Bash" "$command_str" ;;
    elevate) ask_user "Requires confirmation: $command_str" ;;
    review)  send_to_tier2 "Bash: $command_str" ;;
  esac
fi

# --- Everything else ---
send_to_tier2 "${tool_name:-unknown} (unhandled tool)"
```

Key properties:
- **`elevate` dominates `review`**: if ANY segment needs human confirmation (git push), the whole command does — even if other segments would just need review
- **`review` dominates `safe`**: if ANY segment needs review, the whole command does
- **No `deny`**: nothing in this pipeline calls `deny()`
- **No `fall_through`**: every path ends in `allow`, `ask_user`, or `send_to_tier2`

### `send_to_tier2()`: single routing function

Replaces both `tier2_or_escalate` and `tier2_or_fallthrough`:

```bash
send_to_tier2() {
  local context="$1"
  if [[ "$tier2_enabled" == "true" ]] && command -v claude &>/dev/null; then
    invoke_tier2 "$context"
  else
    ask_user "Requires confirmation: ${context}"
  fi
}
```

One function. If subagent available, use it. If not, ask user. Always.

### PUSH_BACK hash detection in `invoke_tier2()`

```bash
PUSHBACK_HASH_FILE="/tmp/claude-hook-last-pushback.hash"

invoke_tier2() {
  local context="$1"
  # ... existing setup (prompt_file, schema_file, system_prompt, schema) ...

  # Check if this is a retry of a previously pushed-back request
  local request_hash is_retry=false
  request_hash=$(echo "$input" | md5sum | cut -d' ' -f1)
  if [[ -f "$PUSHBACK_HASH_FILE" ]] && [[ "$(cat "$PUSHBACK_HASH_FILE")" == "$request_hash" ]]; then
    is_retry=true
  fi

  # ... build review_prompt with description + transcript context (unchanged) ...

  # On retry, tell subagent: no PUSH_BACK option
  if [[ "$is_retry" == true ]]; then
    review_prompt="${review_prompt}

IMPORTANT: This is a RETRY of a previously pushed-back request. The agent has already been asked to reconsider. You MUST choose either APPROVE or ELEVATE. Do NOT choose PUSH_BACK."
  fi

  # ... claude -p call (unchanged) ...

  # ... parse decision ...

  case "$decision" in
    APPROVE)
      rm -f "$PUSHBACK_HASH_FILE"
      allow "Tier2-approved: $reason"
      ;;
    PUSH_BACK)
      echo "$request_hash" > "$PUSHBACK_HASH_FILE"
      deny "Tier 2 review: $reason"
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
```

Note: On retry, if the subagent still returns PUSH_BACK despite the instruction, we treat it as ELEVATE (belt and suspenders):

```bash
    PUSH_BACK)
      if [[ "$is_retry" == true ]]; then
        rm -f "$PUSHBACK_HASH_FILE"
        ask_user "Tier 2 could not decide — please confirm: $context"
      else
        echo "$request_hash" > "$PUSHBACK_HASH_FILE"
        deny "Tier 2 review: $reason"
      fi
      ;;
```

### Review prompt changes

No structural changes needed. The "no PUSH_BACK on retry" instruction is injected dynamically into the review prompt (not baked into `review-prompt.md`). The static prompt and schema stay as they are.

## Potential Risks

1. **Subagent PUSH_BACK on retry despite instruction**: Mitigated by treating PUSH_BACK-on-retry as ELEVATE (see above).
2. **Hash collision**: md5 of full JSON input — collision probability is negligible for this use case.
3. **Hash file persists across sessions**: File is in `/tmp`, cleared on reboot. A stale hash from a previous session could suppress PUSH_BACK once for a matching request — low risk, and the subagent would still APPROVE or ELEVATE correctly.
4. **Regression in safe-list matching**: `classify_segment` internals are unchanged — only the return value names change. Risk is low but testing is important.

## Validation Approach

### Test matrix (all should be run after implementation)

| Input | Expected Tier 1 | Expected outcome |
|---|---|---|
| `ls /tmp` | safe | allow |
| `git status` | safe | allow |
| `git -C /path diff` | safe | allow |
| `python test.py` | safe | allow |
| `git commit -m "msg"` | elevate | ask_user |
| `git push origin main` | elevate | ask_user |
| `npm install` | review | send_to_tier2 |
| `rm -rf /home/user/dir` | review | send_to_tier2 |
| `curl http://example.com` | review | send_to_tier2 |
| Read tool on allowed path | safe | allow |
| Read tool outside allowed path | review | send_to_tier2 |
| Task tool | safe (built-in) | allow |
| Unknown tool "Foo" | review | send_to_tier2 |

### PUSH_BACK loop test

1. Send `npm install` → subagent PUSH_BACKs → hash stored
2. Send `npm install` again → review prompt says "no PUSH_BACK" → subagent returns APPROVE or ELEVATE
3. If subagent still returns PUSH_BACK → treated as ELEVATE

### Tier 2 disabled test

Set `tier2_enabled: false` in config → all non-safe operations should `ask_user`.

---

**Next Step:** After approval → `/_my_implement` or `/_my_plan`
