#!/bin/bash
# Verify the generated Codex orchestrator fork and helper contract.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
HELPER="$ROOT/dist/codex/scripts/orchestrate-stage-codex.sh"
ORCH="$ROOT/dist/codex/skills/my-orchestrate/SKILL.md"
AGENTS="$ROOT/dist/codex/AGENTS.md"
MANIFEST="$ROOT/dist/codex/manifest.json"

fail() { echo -e "${RED}FAIL: $1${NC}"; exit 1; }
pass() { echo -e "${GREEN}PASS: $1${NC}"; }

contains() {
  local file="$1"
  local pattern="$2"
  grep -q -- "$pattern" "$file" || fail "expected '$pattern' in $file"
}

does_not_contain() {
  local file="$1"
  local pattern="$2"
  if grep -q -- "$pattern" "$file"; then
    fail "unexpected '$pattern' in $file"
  fi
}

echo "Verifying Codex orchestrator pack..."
echo ""

[ -x "$HELPER" ] || fail "helper missing or not executable: $HELPER"
[ -f "$ROOT/dist/codex/scripts/orchestrate-preamble-codex.md" ] || fail "preamble missing"
contains "$MANIFEST" '"scripts"'
pass "generated scripts present"

out="$("$HELPER" run spec --dry-run <<< 'Build the thing')"
echo "$out" | grep -q 'codex exec' || fail "run dry-run did not print codex exec argv"
echo "$out" | grep -q 'Use $my-spec' || fail "spec did not map to \$my-spec"
echo "$out" | grep -q -- '--sandbox workspace-write' || fail "spec did not default to workspace-write"

out="$("$HELPER" run spec_review --dry-run <<< 'Review the thing')"
echo "$out" | grep -q 'Use $my-spec-review' || fail "spec_review did not map to \$my-spec-review"
echo "$out" | grep -q -- '--sandbox read-only' || fail "spec_review did not default to read-only"

out="$("$HELPER" run pre_pr --dry-run <<< 'Check the thing')"
echo "$out" | grep -q 'Use $my-pre-pr' || fail "pre_pr did not map to \$my-pre-pr"

out="$("$HELPER" resume 019-test --dry-run <<< 'Continue')"
echo "$out" | grep -q 'codex exec resume' || fail "resume dry-run did not print codex exec resume argv"
if echo "$out" | grep -q -- '--sandbox'; then
  fail "resume dry-run included --sandbox"
fi
pass "dry-run helper contract"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
fixture="$tmpdir/codex-events.jsonl"
last="$tmpdir/last-message.txt"
printf '%s\n' \
  '{"type":"thread.started","thread_id":"019-test"}' \
  '{"type":"turn.completed","usage":{"input_tokens":1}}' > "$fixture"
printf 'ARTIFACT: .project/active/demo/spec.md\n' > "$last"
parsed="$("$HELPER" --parse-only "$fixture" "$last")"
echo "$parsed" | grep -q '"session_id":"019-test"' || fail "parser did not return session_id"
echo "$parsed" | grep -q 'ARTIFACT:' || fail "parser did not include final message"

printf '%s\n' \
  '{"type":"thread.started","thread_id":"019-fail"}' \
  '{"type":"turn.failed","message":"boom"}' > "$fixture"
set +e
parsed="$("$HELPER" --parse-only "$fixture" "$last")"
rc=$?
set -e
[ "$rc" -eq 3 ] || fail "failure fixture should exit 3, got $rc"
echo "$parsed" | grep -q '"is_error":true' || fail "failure fixture did not mark is_error"
pass "JSONL parser fixtures"

contains "$ORCH" '~/.codex/scripts/orchestrate-stage-codex.sh'
contains "$ORCH" '\$my-pipeline'
contains "$ORCH" '\$my-spike'
contains "$ORCH" '\$my-learning-test'
does_not_contain "$ORCH" '~/.claude/scripts/orchestrate-stage.sh'
does_not_contain "$ORCH" 'claude -p'
does_not_contain "$ORCH" '/_my_'
pass "Codex orchestrator replacement"

contains "$AGENTS" '\$my-pipeline'
contains "$AGENTS" '$HOME/.agents/skills/my-pipeline/SKILL.md'
does_not_contain "$AGENTS" '~/.claude/commands/_my_pipeline.md'
does_not_contain "$AGENTS" '/_my_'
does_not_contain "$AGENTS" 'auto-memory'
pass "Codex AGENTS guidance"

setup_out="$(bash "$ROOT/scripts/setup-codex.sh" --dry-run)"
echo "$setup_out" | grep -q '.codex/scripts' || fail "setup dry-run did not mention .codex/scripts"
echo "$setup_out" | grep -q 'orchestrate-stage-codex.sh' || fail "setup dry-run did not include helper script"
pass "installer dry-run includes scripts"

echo ""
echo -e "${GREEN}Codex orchestrator pack checks passed.${NC}"
