#!/usr/bin/env bash
# Count parent events between a marked host tool call and its terminal output.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'usage: %s SESSION_JSONL MARKER\n' "$0" >&2
  exit 2
fi

session_log="$1"
marker="$2"

mapfile -t marker_lines < <(rg -nF "$marker" "$session_log" | sed -n '1,2p' | cut -d: -f1)
if [ "${#marker_lines[@]}" -ne 2 ]; then
  printf 'expected marker in one tool call and its output: %s\n' "$marker" >&2
  exit 2
fi

start_line="${marker_lines[0]}"
end_line="${marker_lines[1]}"
if [ "$end_line" -le "$start_line" ]; then
  printf 'invalid marker order: %s then %s\n' "$start_line" "$end_line" >&2
  exit 2
fi

sed -n "${start_line},${end_line}p" "$session_log" | jq -s --arg marker "$marker" '
  {
    marker: $marker,
    start: .[0].timestamp,
    terminal: .[-1].timestamp,
    records_between: (length - 2),
    parent_tool_calls_between: ([.[1:-1][]
      | select(.type == "response_item")
      | select(.payload.type == "function_call" or .payload.type == "custom_tool_call")]
      | length),
    wait_calls_between: ([.[1:-1][]
      | select(.type == "response_item")
      | select(.payload.type == "function_call" and .payload.name == "wait")]
      | length),
    token_events_between: ([.[1:-1][]
      | select(.type == "event_msg" and .payload.type == "token_count")]
      | length)
  }
'
