#!/usr/bin/env bash
# orchestrate-stage.sh — run or resume ONE pipeline stage as a headless `claude -p` subagent.
#
# Mechanism only. It composes the prompt, invokes claude, and prints
# {"session_id","result","cost","is_error"} as JSON on stdout. It does NOT interpret the
# result — routing and judgment belong to the orchestrator (design D8).
#
# Usage:
#   orchestrate-stage.sh run <stage> [opts]         # stage args read from stdin
#   orchestrate-stage.sh resume <session_id> [opts] # message read from stdin
#
# Options:
#   --model <m>       stage model            (default: $ORCH_MODEL, else opus)
#   --budget <usd>    per-call spend cap      (default: 10)
#   --timeout <sec>   wall-clock timeout      (default: 600)
#   --perm <mode>     permission mode         (default: acceptEdits; implement/pre_pr auto-use bypassPermissions)
#   --log-dir <dir>   raw JSON/stderr log dir (default: ./.orchestrate-logs)
#   --preamble <file> preamble to inject      (default: orchestrate-preamble.md beside this script)
#   --dry-run         print composed prompt + claude argv, do not call claude
#
# Exit: 0 success; 3 stage ran but reported is_error; nonzero otherwise (with a message on stderr).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "orchestrate-stage: $*" >&2; exit 1; }
usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" >&2; exit 2; }

[ $# -ge 1 ] || usage
MODE="$1"; shift

MODEL="${ORCH_MODEL:-opus}"
BUDGET=10
TIMEOUT=600
PERM="acceptEdits"
PERM_SET=0
LOGDIR="./.orchestrate-logs"
PREAMBLE="$SCRIPT_DIR/orchestrate-preamble.md"
DRYRUN=0

case "$MODE" in
  run)    [ $# -ge 1 ] || die "run requires <stage>";        STAGE="$1"; shift ;;
  resume) [ $# -ge 1 ] || die "resume requires <session_id>"; SID="$1";   shift ;;
  -h|--help) usage ;;
  *) die "unknown mode '$MODE' (expected run|resume)" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --model)    MODEL="$2";    shift 2 ;;
    --budget)   BUDGET="$2";   shift 2 ;;
    --timeout)  TIMEOUT="$2";  shift 2 ;;
    --perm)     PERM="$2"; PERM_SET=1; shift 2 ;;
    --log-dir)  LOGDIR="$2";   shift 2 ;;
    --preamble) PREAMBLE="$2"; shift 2 ;;
    --dry-run)  DRYRUN=1;      shift ;;
    *) die "unknown option '$1'" ;;
  esac
done

# Stages that run project commands (tests, lint, gh) need broader permissions by default.
if [ "$MODE" = "run" ] && [ "$PERM_SET" = "0" ]; then
  case "$STAGE" in implement|pre_pr) PERM="bypassPermissions" ;; esac
fi

# The prompt body (stage args, or the resume message) comes from stdin.
BODY="$(cat)"

# Compose the prompt. Policy differs by mode; the invocation mechanism below does not.
if [ "$MODE" = "run" ]; then
  [ -f "$PREAMBLE" ] || die "preamble file not found: $PREAMBLE"
  PROMPT="$(printf '/_my_%s %s\n\n%s\n' "$STAGE" "$BODY" "$(cat "$PREAMBLE")")"
  LABEL="run-$STAGE"
else
  PROMPT="$BODY"
  LABEL="resume-${SID:0:8}"
fi

CLAUDE_ARGS=(-p --model "$MODEL" --output-format json --permission-mode "$PERM" --max-budget-usd "$BUDGET")
[ "$MODE" = "resume" ] && CLAUDE_ARGS+=(--resume "$SID")

if [ "$DRYRUN" = "1" ]; then
  echo "# claude ${CLAUDE_ARGS[*]}"
  echo "# --- composed prompt (piped on stdin) ---"
  printf '%s\n' "$PROMPT"
  exit 0
fi

mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
RAW="$LOGDIR/$LABEL-$STAMP.json"
ERR="$LOGDIR/$LABEL-$STAMP.stderr"

# Always pipe the prompt on stdin — passing it as an argument makes claude wait on stdin
# and emit a warning that corrupts the JSON capture (spike finding).
printf '%s' "$PROMPT" | timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" > "$RAW" 2> "$ERR"
RC=$?
[ "$RC" -eq 124 ] && die "stage timed out after ${TIMEOUT}s (raw: $RAW, stderr: $ERR)"
[ "$RC" -ne 0 ]   && die "claude exited $RC (raw: $RAW, stderr: $ERR)"

# Lift the final result object (tolerating a leading stdin-warning line) and emit compact JSON.
python3 - "$RAW" <<'PY'
import json, sys
raw = open(sys.argv[1]).read()
i = raw.find('[{')
data = json.loads(raw[i:] if i >= 0 else raw)
res = [e for e in data if e.get("type") == "result"]
if not res:
    sys.exit(1)
r = res[0]
print(json.dumps({
    "session_id": r.get("session_id"),
    "result": r.get("result", ""),
    "cost": round(r.get("total_cost_usd", 0), 4),
    "is_error": bool(r.get("is_error")),
}))
sys.exit(2 if r.get("is_error") else 0)
PY
case "$?" in
  0) exit 0 ;;
  2) echo "orchestrate-stage: stage reported is_error (raw: $RAW)" >&2; exit 3 ;;
  *) die "no result object parsed from $RAW" ;;
esac
