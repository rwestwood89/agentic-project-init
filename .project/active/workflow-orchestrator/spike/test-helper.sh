#!/usr/bin/env bash
# Smoke test for orchestrate-stage.sh (Phase 2).
# 1. Composition (free, --dry-run): the composed prompt carries the command + the preamble.
# 2. Real run (cheap, sonnet): a stage call returns parseable {session_id,result,cost}.
# 3. Resume: the session is re-entered and replies.
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
HELPER="$ROOT/claude-pack/scripts/orchestrate-stage.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== 1. composition (dry-run, no API cost) =="
comp="$(printf 'do the thing' | "$HELPER" run spec --dry-run)" || fail "dry-run exited nonzero"
echo "$comp" | grep -q '/_my_spec do the thing' || fail "composed prompt missing the command line"
echo "$comp" | grep -qi 'non-interactive'        || fail "composed prompt missing the preamble"
echo "$comp" | grep -q 'ARTIFACT:'               || fail "composed prompt missing the ARTIFACT contract"
echo "   ok: command + preamble + ARTIFACT contract present"

echo "== 2. real run (sonnet, cheap stage in an empty sandbox) =="
mkdir -p "$TMP/.project/active"
printf '# Current Work\n\n## Active Work\n\n*(none)*\n' > "$TMP/.project/CURRENT_WORK.md"
printf '# Sandbox\n' > "$TMP/CLAUDE.md"
out="$(cd "$TMP" && printf '' | "$HELPER" run status --model sonnet --budget 3 --timeout 240 --log-dir "$TMP/logs")" \
  || fail "run exited nonzero: $out"
python3 - "$out" <<'PY' || fail "run output not the expected JSON shape"
import json,sys
d=json.loads(sys.argv[1])
assert d.get("session_id"), "no session_id"
assert d.get("is_error") is False, "is_error true"
assert isinstance(d.get("cost"), (int,float)), "no cost"
print("   ok: session_id=%s cost=$%s" % (d["session_id"][:8], d["cost"]))
PY
SID="$(python3 -c 'import json,sys;print(json.loads(sys.argv[1])["session_id"])' "$out")"

echo "== 3. resume (context re-entered) =="
rout="$(cd "$TMP" && printf 'Reply with exactly: RESUMED_OK' | "$HELPER" resume "$SID" --model sonnet --budget 2 --timeout 180 --log-dir "$TMP/logs")" \
  || fail "resume exited nonzero: $rout"
echo "$rout" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert "RESUMED_OK" in d["result"], d["result"]; print("   ok: resume replied in-session")' \
  || fail "resume did not reply as expected"

echo "ALL PASS"
