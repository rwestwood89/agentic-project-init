#!/bin/bash
# Verify orchestrate-stage.sh resumes a session in the permission mode its run started with.
# Uses a fake `claude` on PATH that records its argv, so no API calls are made.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$(dirname "$SCRIPT_DIR")/claude-pack/scripts/orchestrate-stage.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo -e "${RED}FAIL${NC}: $*" >&2; exit 1; }

mkdir -p "$TMP/bin"
cat > "$TMP/bin/claude" <<'FAKE'
#!/bin/bash
cat > /dev/null
echo "$*" >> "$FAKE_ARGV_LOG"
echo '[{"type":"result","session_id":"sess-123","result":"ok","total_cost_usd":0,"is_error":false}]'
FAKE
chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH" FAKE_ARGV_LOG="$TMP/argv"
LOGS="$TMP/logs"

last_perm() { tail -1 "$FAKE_ARGV_LOG" | sed -n 's/.*--permission-mode \([^ ]*\).*/\1/p'; }

echo "== implement run gets bypassPermissions =="
printf 'x' | "$HELPER" run implement --log-dir "$LOGS" > /dev/null || fail "run exited nonzero"
[ "$(last_perm)" = "bypassPermissions" ] || fail "run used $(last_perm)"

echo "== resume inherits bypassPermissions =="
printf 'go on' | "$HELPER" resume sess-123 --log-dir "$LOGS" > /dev/null || fail "resume exited nonzero"
[ "$(last_perm)" = "bypassPermissions" ] || fail "resume used $(last_perm)"

echo "== resume of a spec run stays acceptEdits =="
printf 'x' | "$HELPER" run spec --log-dir "$LOGS" > /dev/null || fail "spec run exited nonzero"
printf 'go on' | "$HELPER" resume sess-123 --log-dir "$LOGS" > /dev/null || fail "resume exited nonzero"
[ "$(last_perm)" = "acceptEdits" ] || fail "resume used $(last_perm)"

echo "== unknown session falls back to acceptEdits =="
out="$(printf 'm' | "$HELPER" resume other-sess --log-dir "$LOGS" --dry-run)"
echo "$out" | grep -q -- '--permission-mode acceptEdits' || fail "unknown session not acceptEdits"

echo "== explicit --perm on resume still wins =="
out="$(printf 'm' | "$HELPER" resume sess-123 --perm plan --log-dir "$LOGS" --dry-run)"
echo "$out" | grep -q -- '--permission-mode plan' || fail "--perm override ignored"

echo "== path-like session id rejected =="
printf 'm' | "$HELPER" resume ../evil --log-dir "$LOGS" --dry-run 2>/dev/null && fail "path-like id accepted"

echo -e "${GREEN}All orchestrate-stage tests passed${NC}"
