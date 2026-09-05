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
SKILL_DIST="$ROOT/dist/codex/skills/my-mental-model"

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

out="$("$HELPER" run concept_design_review --dry-run <<< 'Review the architecture')"
echo "$out" | grep -q 'Use $my-concept-design-review' || fail "concept_design_review did not map to \$my-concept-design-review"
echo "$out" | grep -q -- '--sandbox read-only' || fail "concept_design_review did not default to read-only"

out="$("$HELPER" run pre_pr --dry-run <<< 'Check the thing')"
echo "$out" | grep -q 'Use $my-pre-pr' || fail "pre_pr did not map to \$my-pre-pr"

out="$("$HELPER" resume 019-test --dry-run <<< 'Continue')"
echo "$out" | grep -q 'codex exec resume' || fail "resume dry-run did not print codex exec resume argv"
if echo "$out" | grep -q -- '--sandbox'; then
  fail "resume dry-run included --sandbox"
fi
pass "dry-run helper contract"

tmpdir="$(mktemp -d)"
cleanup() {
  local pid_file pid
  while IFS= read -r pid_file; do
    pid="$(sed -n '1p' "$pid_file")"
    if [ -n "$pid" ]; then
      kill "$pid" 2>/dev/null || true
    fi
  done < <(find "$tmpdir" -name '*.pid' -type f 2>/dev/null)
  rm -rf "$tmpdir"
}
trap cleanup EXIT

wait_for_file() {
  local file="$1"
  local attempt
  for attempt in $(seq 1 50); do
    [ -s "$file" ] && return 0
    sleep 0.1
  done
  fail "timed out waiting for $file"
}

assert_process_gone() {
  local pid="$1"
  local context="$2"
  local attempt
  for attempt in $(seq 1 50); do
    if ! kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    sleep 0.1
  done
  kill "$pid" 2>/dev/null || true
  fail "$context left process $pid alive after cleanup grace"
}

fake_bin="$tmpdir/fake-bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/codex" <<'FAKE_CODEX'
#!/usr/bin/env bash
set -uo pipefail

mode="${FAKE_CODEX_MODE:-success}"
session_id="${FAKE_CODEX_SESSION_ID:-019-test-fresh}"
pid_file="${FAKE_CODEX_PID_FILE:-}"
signal_file="${FAKE_CODEX_SIGNAL_FILE:-}"
prompt_file="${FAKE_CODEX_PROMPT_FILE:-}"
args_file="${FAKE_CODEX_ARGS_FILE:-}"
last_message=""
is_resume=0

on_signal() {
  if [ -n "$signal_file" ]; then
    printf 'terminated pid=%s\n' "$$" > "$signal_file"
  fi
  exit 143
}
trap on_signal HUP INT TERM

[ -z "$pid_file" ] || printf '%s\n' "$$" > "$pid_file"
[ -z "$args_file" ] || printf '%s\n' "$@" > "$args_file"

args=("$@")
for ((index = 0; index < ${#args[@]}; index += 1)); do
  case "${args[$index]}" in
    resume)
      is_resume=1
      ;;
    --output-last-message|-o)
      index=$((index + 1))
      last_message="${args[$index]}"
      ;;
    019-*)
      if [ "$is_resume" -eq 1 ]; then
        session_id="${args[$index]}"
      fi
      ;;
  esac
done

if [ -n "$prompt_file" ]; then
  cat > "$prompt_file"
else
  while IFS= read -r _line; do :; done
fi

printf '{"type":"thread.started","thread_id":"%s"}\n' "$session_id"
printf '{"type":"turn.started"}\n'

if [ "$mode" = "hang" ]; then
  while :; do
    printf '{"type":"item.completed","item":{"type":"agent_message","text":"fake stage alive"}}\n'
    printf 'fake-codex: alive\n' >&2
    sleep 1
  done
fi

if [ -n "$last_message" ]; then
  printf 'Fake stage complete.\n\nARTIFACT: .project/active/fake-stage/result.md\n' > "$last_message"
fi

if [ "$mode" = "event_failure" ]; then
  printf '{"type":"turn.failed","message":"fake reported failure"}\n'
else
  printf '{"type":"turn.completed","usage":{"input_tokens":12}}\n'
fi
FAKE_CODEX
chmod +x "$fake_bin/codex"

success_dir="$tmpdir/success"
success_prompt="$success_dir/prompt"
success_args="$success_dir/args"
mkdir -p "$success_dir/logs"
success_out="$(
  PATH="$fake_bin:$PATH" \
  FAKE_CODEX_MODE=success \
  FAKE_CODEX_SESSION_ID=019-test-success \
  FAKE_CODEX_PROMPT_FILE="$success_prompt" \
  FAKE_CODEX_ARGS_FILE="$success_args" \
    "$HELPER" run design --timeout 10 --log-dir "$success_dir/logs" <<< 'Build the design'
)"
jq -e '
  .session_id == "019-test-success" and
  .result == "Fake stage complete.\n\nARTIFACT: .project/active/fake-stage/result.md\n" and
  .is_error == false
' <<< "$success_out" >/dev/null || fail "success result shape changed"
[ -f "$(jq -r '.raw' <<< "$success_out")" ] || fail "success raw log was not retained"
[ -f "$(jq -r '.stderr' <<< "$success_out")" ] || fail "success stderr log was not retained"
grep -q 'Use \$my-design' "$success_prompt" || fail "success prompt did not invoke the design skill"
grep -q '^--sandbox$' "$success_args" || fail "fresh run omitted the sandbox argument"

resume_dir="$tmpdir/resume"
mkdir -p "$resume_dir/logs"
resume_out="$(
  PATH="$fake_bin:$PATH" \
  FAKE_CODEX_MODE=success \
  FAKE_CODEX_ARGS_FILE="$resume_dir/args" \
    "$HELPER" resume 019-test-resume --timeout 10 --log-dir "$resume_dir/logs" <<< 'Continue'
)"
jq -e '.session_id == "019-test-resume" and .is_error == false' <<< "$resume_out" >/dev/null \
  || fail "resume did not preserve the original session id"
grep -q '^resume$' "$resume_dir/args" || fail "resume argv omitted the resume subcommand"
if grep -q '^--sandbox$' "$resume_dir/args"; then
  fail "resume argv included an unsupported sandbox argument"
fi

failure_dir="$tmpdir/event-failure"
mkdir -p "$failure_dir/logs"
set +e
failure_out="$(
  PATH="$fake_bin:$PATH" \
  FAKE_CODEX_MODE=event_failure \
  FAKE_CODEX_SESSION_ID=019-test-event-failure \
    "$HELPER" run design_review --timeout 10 --log-dir "$failure_dir/logs" <<< 'Review the design'
)"
failure_rc=$?
set -e
[ "$failure_rc" -eq 3 ] || fail "reported failure should exit 3, got $failure_rc"
jq -e '.session_id == "019-test-event-failure" and .is_error == true' <<< "$failure_out" >/dev/null \
  || fail "reported failure result shape changed"

timeout_dir="$tmpdir/helper-timeout"
mkdir -p "$timeout_dir/logs"
set +e
PATH="$fake_bin:$PATH" \
FAKE_CODEX_MODE=hang \
FAKE_CODEX_PID_FILE="$timeout_dir/fake.pid" \
FAKE_CODEX_SIGNAL_FILE="$timeout_dir/signal" \
  "$HELPER" run design --timeout 1 --log-dir "$timeout_dir/logs" <<< 'Time out' \
    > "$timeout_dir/stdout" 2> "$timeout_dir/stderr"
timeout_rc=$?
set -e
[ "$timeout_rc" -eq 1 ] || fail "helper timeout should exit 1, got $timeout_rc"
[ ! -s "$timeout_dir/stdout" ] || fail "helper timeout wrote compact stdout"
contains "$timeout_dir/stderr" 'stage timed out after 1s'
wait_for_file "$timeout_dir/fake.pid"
wait_for_file "$timeout_dir/signal"
assert_process_gone "$(sed -n '1p' "$timeout_dir/fake.pid")" "helper timeout"

cancel_dir="$tmpdir/external-cancellation"
mkdir -p "$cancel_dir/logs"
PATH="$fake_bin:$PATH" \
FAKE_CODEX_MODE=hang \
FAKE_CODEX_PID_FILE="$cancel_dir/fake.pid" \
FAKE_CODEX_SIGNAL_FILE="$cancel_dir/signal" \
  "$HELPER" run design --timeout 30 --log-dir "$cancel_dir/logs" <<< 'Cancel externally' \
    > "$cancel_dir/stdout" 2> "$cancel_dir/stderr" &
helper_pid=$!
wait_for_file "$cancel_dir/fake.pid"
kill -TERM "$helper_pid"
set +e
wait "$helper_pid"
cancel_rc=$?
set -e
[ "$cancel_rc" -eq 143 ] || fail "external cancellation should exit 143, got $cancel_rc"
[ ! -s "$cancel_dir/stdout" ] || fail "external cancellation wrote compact stdout"
fake_pid="$(sed -n '1p' "$cancel_dir/fake.pid")"
assert_process_gone "$fake_pid" "external cancellation"
wait_for_file "$cancel_dir/signal"
contains "$cancel_dir/stderr" 'run-design'
contains "$cancel_dir/stderr" 'raw:'
contains "$cancel_dir/stderr" 'stderr:'
pass "helper lifecycle and cancellation contract"

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
contains "$ORCH" 'take ownership of delivering high-quality implemented work'
contains "$ORCH" 'You are the quality owner for the run'
contains "$ORCH" 'Invoke a stage only when its output is likely to change the implementation'
contains "$ORCH" 'A persisted `Revise` verdict is historical evidence'
contains "$ORCH" 'Rerun `concept_design_review`, `spec_review`, or `design_review`'
contains "$ORCH" '\$my-concept-design-review'
contains "$ORCH" 'functions.exec'
contains "$ORCH" 'tools.exec_command'
contains "$ORCH" 'tools.write_stdin'
contains "$ORCH" 'functions.wait'
contains "$ORCH" 'T + 30'
contains "$ORCH" 'remaining deadline'
contains "$ORCH" 'only once'
contains "$ORCH" 'Do not poll'
contains "$ORCH" 'terminate: true'
contains "$ORCH" 'compatibility failure'
contains "$ORCH" 'one concise launch update'
contains "$ORCH" 'unchanged state'
contains "$ORCH" 'Keep JSONL'
contains "$ORCH" 'stderr in their retained files'
contains "$ORCH" 'Leave `$my-close` and the post-close `$my-pre-pr` branch gate to the human unless explicitly asked.'
does_not_contain "$ORCH" 'notify('
does_not_contain "$ORCH" 'setInterval'
does_not_contain "$ORCH" 'setTimeout'
does_not_contain "$ORCH" 'yield_control'
does_not_contain "$ORCH" '~/.claude/scripts/orchestrate-stage.sh'
does_not_contain "$ORCH" 'claude -p'
does_not_contain "$ORCH" '/_my_'
pass "Codex orchestrator replacement"

# Directory skills ship as a unit: the whole pack tree reaches dist under the derived Codex name.
[ -d "$SKILL_DIST" ] || fail "derived skill dir missing: $SKILL_DIST"
if [ -d "$ROOT/dist/codex/skills/_my_mental_model" ]; then
  fail "pack-side name leaked into dist"
fi
for f in SKILL.md design_synthesis.md visualize.md feedback/synthesis.md feedback/html.md; do
  [ -f "$SKILL_DIST/$f" ] || fail "sibling missing from dist: $f"
done
contains "$SKILL_DIST/SKILL.md" 'name: my-mental-model'
jq -e '.included.skills == ["my-mental-model", "show-me"]' "$MANIFEST" >/dev/null \
  || fail "manifest skills array is not exactly [my-mental-model, show-me]"
does_not_contain "$MANIFEST" 'example-skill'
# The flat single-file skill lane is gone (D6), so a flat .md produces no skill on either runtime.
does_not_contain "$ROOT/scripts/build-codex-pack.sh" 'skills" -maxdepth 1 -type f'
pass "directory skill tree and derived name"

# The adapter ran: no marker survives, and the Codex vocabulary replaced the Claude vocabulary.
if grep -rn 'harness-block' "$SKILL_DIST"; then
  fail "unsubstituted harness-block reached dist"
fi
contains "$SKILL_DIST/SKILL.md" 'fork_turns'
does_not_contain "$SKILL_DIST/SKILL.md" 'subagent_type'
does_not_contain "$SKILL_DIST/SKILL.md" 'SendMessage'
# A non-inheriting spawn must name fork_turns: "none" explicitly — the Codex default is "all".
contains "$SKILL_DIST/SKILL.md" 'fork_turns: "none"'
# The adapter reached a sibling, not only the entry point.
contains "$SKILL_DIST/design_synthesis.md" 'fork_turns'
# The reviewer's instruction file is a sibling too, and the review pass is dead without it.
[ -f "$SKILL_DIST/review.md" ] || fail "review.md did not reach dist"
# The command lane's slash rule stays off skill bodies: this real path must survive intact (D8).
contains "$SKILL_DIST/SKILL.md" 'claude-pack/skills/_my_mental_model'
pass "harness blocks substituted across the tree"

contains "$AGENTS" '\$my-pipeline'
contains "$AGENTS" '$HOME/.agents/skills/my-pipeline/SKILL.md'
contains "$AGENTS" 'Stages are quality tools, not mandatory ceremony'
contains "$AGENTS" 'record the verification'
contains "$AGENTS" 'fork_turns: "all"'
contains "$AGENTS" 'Do not combine'
contains "$AGENTS" 'fork_turns.*defaults to.*"all"'
contains "$AGENTS" 'owner explicitly invokes.*\$my-quick-edit'
contains "$AGENTS" 'Do not use it for routine documentation or `.project` artifact edits'
does_not_contain "$AGENTS" '~/.claude/commands/_my_pipeline.md'
does_not_contain "$AGENTS" '/_my_'
does_not_contain "$AGENTS" 'auto-memory'

# Narrowed job: confirm the adapter ran over every generated skill file. Not a phrase detector —
# a phrase you can list is one that belongs in the dictionary. Uses grep, not rg: rg is not on PATH
# inside this script, so the rg form never executed and this check silently passed for free.
# Scoped to every .md under dist skills, because ADR 0011 makes all of them adapter output.
if grep -rnE --include='*.md' \
  'subagent_type|`Task` tool|`Agent` tool|general-purpose (subagent|agent)|Task subagents|Explore subagent|Explore agent' \
  "$ROOT/dist/codex/skills"; then
  fail "generated Codex skills retained Claude-specific delegation terminology"
fi
contains "$ROOT/dist/codex/skills/my-design/SKILL.md" 'fresh-context `explorer` subagent'
contains "$ROOT/dist/codex/skills/my-spec/SKILL.md" 'fresh-context `default` subagent'
contains "$ROOT/dist/codex/skills/my-design-review/SKILL.md" 'fresh-context `default` subagent'
pass "Codex AGENTS guidance"

QUICK_EDIT_SKILL="$ROOT/dist/codex/skills/my-quick-edit"
contains "$QUICK_EDIT_SKILL/SKILL.md" 'small, scoped code change'
contains "$QUICK_EDIT_SKILL/SKILL.md" 'user explicitly invokes this skill'
contains "$QUICK_EDIT_SKILL/SKILL.md" 'Do not use for routine documentation or .project artifact edits'
contains "$QUICK_EDIT_SKILL/agents/openai.yaml" 'allow_implicit_invocation: false'
pass "quick-edit is code-only and explicit-only"

GIT_MANAGE_SKILL="$ROOT/dist/codex/skills/my-git-manage"
contains "$GIT_MANAGE_SKILL/SKILL.md" 'parallel Git worktrees'
contains "$GIT_MANAGE_SKILL/SKILL.md" 'user explicitly invokes this skill'
contains "$GIT_MANAGE_SKILL/SKILL.md" 'Do not use for ordinary branches, commits, pushes, or pull requests'
contains "$GIT_MANAGE_SKILL/agents/openai.yaml" 'allow_implicit_invocation: false'
pass "git-manage is worktree-specific and explicit-only"

setup_out="$(bash "$ROOT/scripts/setup-codex.sh" --dry-run)"
echo "$setup_out" | grep -q '.codex/scripts' || fail "setup dry-run did not mention .codex/scripts"
echo "$setup_out" | grep -q 'orchestrate-stage-codex.sh' || fail "setup dry-run did not include helper script"
echo "$setup_out" | grep -q 'Global instructions' || fail "setup dry-run did not mention global instructions"

fresh_home="$tmpdir/home"
mkdir -p "$fresh_home"
setup_out="$(HOME="$fresh_home" bash "$ROOT/scripts/setup-codex.sh" --dry-run)"
echo "$setup_out" | grep -q '.codex/AGENTS.md' || fail "fresh HOME dry-run did not install user-level AGENTS.md"
echo "$setup_out" | grep -q '.agents/skills/my-orchestrate/SKILL.md' || fail "fresh HOME dry-run did not install user-level skills"

custom_home="$tmpdir/custom-home"
mkdir -p "$custom_home/.codex"
printf '# Personal Codex instructions\n\nKeep this line.\n' > "$custom_home/.codex/AGENTS.md"
HOME="$custom_home" bash "$ROOT/scripts/setup-codex.sh" --copy > "$tmpdir/setup-custom.log"
grep -q 'Keep this line.' "$custom_home/.codex/AGENTS.md" || fail "installer did not preserve user-authored AGENTS.md content"
grep -q 'agentic-project-init codex rules begin' "$custom_home/.codex/AGENTS.md" || fail "installer did not append managed AGENTS.md block"
grep -q 'Stages are quality tools, not mandatory ceremony' "$custom_home/.codex/AGENTS.md" || fail "managed AGENTS.md block missing pipeline rule"
grep -q 'fork_turns: "all"' "$custom_home/.codex/AGENTS.md" || fail "managed AGENTS.md block missing collaboration rule"
pass "installer dry-run includes scripts and user-level rules"

# The skills install is a directory mirror (D3): whole tree in, stale files out, and the
# managed decision is made once per directory by asking its entry point.
mirror_home="$tmpdir/mirror-home"
skills_home="$mirror_home/.agents/skills"
mkdir -p "$mirror_home"
HOME="$mirror_home" bash "$ROOT/scripts/setup-codex.sh" --copy >/dev/null
[ -f "$skills_home/my-mental-model/feedback/html.md" ] || fail "nested sibling not installed"
[ -f "$skills_home/my-mental-model/visualize.md" ] || fail "flat sibling not installed"
[ -f "$skills_home/my-git-manage/agents/openai.yaml" ] || fail "git-manage invocation policy not installed"
contains "$skills_home/my-git-manage/agents/openai.yaml" 'allow_implicit_invocation: false'
[ -f "$skills_home/my-quick-edit/agents/openai.yaml" ] || fail "quick-edit invocation policy not installed"
contains "$skills_home/my-quick-edit/agents/openai.yaml" 'allow_implicit_invocation: false'

# A sibling carries no `Generated from` marker, so the old per-file guard skipped it from the
# second install onward. The directory-level check is what makes it update.
printf 'hand edit\n' > "$skills_home/my-mental-model/visualize.md"
touch "$skills_home/my-mental-model/stale.md"
HOME="$mirror_home" bash "$ROOT/scripts/setup-codex.sh" --copy >/dev/null
does_not_contain "$skills_home/my-mental-model/visualize.md" 'hand edit'
if [ -f "$skills_home/my-mental-model/stale.md" ]; then
  fail "mirror did not remove a file absent from dist"
fi

# An entry point without our marker means the directory is someone else's: leave all of it.
printf '# my own skill\n' > "$skills_home/show-me/SKILL.md"
touch "$skills_home/show-me/mine.md"
HOME="$mirror_home" bash "$ROOT/scripts/setup-codex.sh" --copy >/dev/null
contains "$skills_home/show-me/SKILL.md" '# my own skill'
[ -f "$skills_home/show-me/mine.md" ] || fail "mirror removed a file from an unmanaged skill dir"
pass "install mirror converges"

# No v1 mental-model surface remains, and nothing repeats the false symlink claim.
does_not_contain "$ROOT/scripts/build-codex-pack.sh" 'mental-model-builder'
does_not_contain "$ROOT/codex-overrides/config.sh" 'mental-model'
does_not_contain "$ROOT/README.md" 'mental_model'
# Scoped to the surfaces that make the claim. `.project/` records quote it as dated evidence and
# keep it on purpose. `-s` because CLAUDE.md is gitignored here and absent from a fresh clone.
if grep -rns --exclude='test_*.sh' 'Codex reads copies, not symlinks' "$ROOT/scripts" "$ROOT/CLAUDE.md"; then
  fail "false symlink claim still present"
fi
pass "v1 surfaces retired"

echo ""
echo -e "${GREEN}Codex orchestrator pack checks passed.${NC}"
