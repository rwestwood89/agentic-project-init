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
#   --perm <mode>     permission mode         (default: acceptEdits; implement/pre_pr/spike/learning_test
#                                              auto-use bypassPermissions; resume reuses the run's mode)
#   --add-dir <dir>   extra directory the stage may access, e.g. a sibling repo (repeatable;
#                                              resume reuses the run's dirs)
#   --log-dir <dir>   raw JSON/stderr log dir (default: ./.orchestrate-logs)
#   --preamble <file> preamble to inject      (default: orchestrate-preamble.md beside this script)
#   --dry-run         print composed prompt + claude argv, do not call claude
#
# Exit: 0 success; 3 stage ran but reported is_error; nonzero otherwise (with a message on stderr).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "orchestrate-stage: $*" >&2; exit 1; }
usage() { sed -n '2,23p' "${BASH_SOURCE[0]}" >&2; exit 2; }

[ $# -ge 1 ] || usage
MODE="$1"; shift

MODEL="${ORCH_MODEL:-opus}"
BUDGET=10
TIMEOUT=600
PERM="acceptEdits"
PERM_SET=0
ADD_DIRS=()
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
    --add-dir)  [ -d "$2" ] || die "--add-dir not a directory: $2"
                ADD_DIRS+=("$(cd "$2" && pwd)"); shift 2 ;;
    --log-dir)  LOGDIR="$2";   shift 2 ;;
    --preamble) PREAMBLE="$2"; shift 2 ;;
    --dry-run)  DRYRUN=1;      shift ;;
    *) die "unknown option '$1'" ;;
  esac
done

# Stages that run project commands (tests, lint, gh) or execute probe code need broader
# permissions by default. spike/learning_test write and run throwaway or real test code.
if [ "$MODE" = "run" ] && [ "$PERM_SET" = "0" ]; then
  case "$STAGE" in implement|pre_pr|spike|learning_test) PERM="bypassPermissions" ;; esac
fi

# A resumed session keeps the mode it was started with, so a resume never silently loses the
# permissions its stage needs and the orchestrator never has to request an escalation.
case "${SID:-}" in */*|.*) die "invalid session id '$SID'" ;; esac
PERMDIR="$LOGDIR/sessions"
if [ "$MODE" = "resume" ] && [ "$PERM_SET" = "0" ] && [ -f "$PERMDIR/$SID.perm" ]; then
  PERM="$(cat "$PERMDIR/$SID.perm")"
fi
# Likewise for extra directories: a resume without --add-dir keeps the run's.
if [ "$MODE" = "resume" ] && [ "${#ADD_DIRS[@]}" -eq 0 ] && [ -f "$PERMDIR/$SID.dirs" ]; then
  mapfile -t ADD_DIRS < "$PERMDIR/$SID.dirs"
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
for d in "${ADD_DIRS[@]}"; do CLAUDE_ARGS+=(--add-dir "$d"); done
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
python3 - "$RAW" "$PERMDIR" "$PERM" "${ADD_DIRS[@]}" <<'PY'
import json, os, sys
raw = open(sys.argv[1]).read()
# claude emits a single result object today; older builds emitted an array of events.
starts = [j for j in (raw.find('[{'), raw.find('{')) if j >= 0]
data = json.loads(raw[min(starts):] if starts else raw)
events = data if isinstance(data, list) else [data]
res = [e for e in events if isinstance(e, dict) and e.get("type") == "result"]
if not res:
    sys.exit(1)
r = res[0]
sid = r.get("session_id")
if sid and "/" not in sid:
    os.makedirs(sys.argv[2], exist_ok=True)
    with open(os.path.join(sys.argv[2], sid + ".perm"), "w") as f:
        f.write(sys.argv[3])
    with open(os.path.join(sys.argv[2], sid + ".dirs"), "w") as f:
        f.write("".join(d + "\n" for d in sys.argv[4:]))
print(json.dumps({
    "session_id": sid,
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
