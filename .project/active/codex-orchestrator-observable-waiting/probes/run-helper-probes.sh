#!/usr/bin/env bash
# Exercise the real orchestration helper against the fake Codex CLI.
set -uo pipefail

probe_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
item_dir="$(dirname "$probe_dir")"
repo_root="$(cd "$item_dir/../../.." && pwd)"
helper="$repo_root/codex-overrides/scripts/orchestrate-stage-codex.sh"
case_name="${1:-all}"
run_stamp="$(date +%Y%m%d-%H%M%S)-$$"
run_dir="$item_dir/probe-output/$run_stamp"
mkdir -p "$run_dir"

export PATH="$probe_dir:$PATH"

record_case() {
  local name="$1"
  local expected_rc="$2"
  shift 2
  local case_dir="$run_dir/$name"
  mkdir -p "$case_dir/logs"

  local started ended rc
  started="$(date +%s)"
  "$@" > "$case_dir/stdout" 2> "$case_dir/stderr"
  rc=$?
  ended="$(date +%s)"

  printf 'case=%s rc=%s expected_rc=%s elapsed_seconds=%s\n' \
    "$name" "$rc" "$expected_rc" "$((ended - started))" > "$case_dir/summary"
  if [ "$rc" -ne "$expected_rc" ]; then
    printf 'unexpected return code for %s\n' "$name" >&2
    return 1
  fi
}

success_long() {
  local case_dir="$run_dir/success-long"
  FAKE_CODEX_MODE=success \
  FAKE_CODEX_DURATION="${PROBE_LONG_DURATION:-36}" \
  FAKE_CODEX_SESSION_ID=019-spike-long \
    "$helper" run design \
      --timeout "${PROBE_HELPER_TIMEOUT:-60}" \
      --cd "$repo_root" \
      --log-dir "$case_dir/logs" <<'PROMPT'
Run the fake long design stage.
PROMPT
}

resume_case() {
  local case_dir="$run_dir/resume"
  FAKE_CODEX_MODE=success \
  FAKE_CODEX_DURATION=1 \
    "$helper" resume 019-spike-resume \
      --timeout 15 \
      --log-dir "$case_dir/logs" <<'PROMPT'
Resume the fake stage.
PROMPT
}

event_failure_case() {
  local case_dir="$run_dir/event-failure"
  FAKE_CODEX_MODE=event_failure \
  FAKE_CODEX_DURATION=1 \
  FAKE_CODEX_SESSION_ID=019-spike-event-failure \
    "$helper" run design_review \
      --timeout 15 \
      --cd "$repo_root" \
      --log-dir "$case_dir/logs" <<'PROMPT'
Report a fake turn failure.
PROMPT
}

timeout_case() {
  local case_dir="$run_dir/timeout"
  FAKE_CODEX_MODE=hang \
  FAKE_CODEX_PID_FILE="$case_dir/fake.pid" \
  FAKE_CODEX_SIGNAL_FILE="$case_dir/signal" \
    "$helper" run design \
      --timeout 2 \
      --cd "$repo_root" \
      --log-dir "$case_dir/logs" <<'PROMPT'
Time out the fake stage.
PROMPT
}

cancellation_case() {
  local case_dir="$run_dir/cancellation"
  FAKE_CODEX_MODE=hang \
  FAKE_CODEX_PID_FILE="$case_dir/fake.pid" \
  FAKE_CODEX_SIGNAL_FILE="$case_dir/signal" \
    timeout --kill-after=2 2 \
      "$helper" run design \
        --timeout 30 \
        --cd "$repo_root" \
        --log-dir "$case_dir/logs" <<'PROMPT'
Cancel the fake stage from outside the helper.
PROMPT
}

inspect_cleanup() {
  local name="$1"
  local case_dir="$run_dir/$name"
  local pid=""
  local alive="no"
  local signaled="no"

  if [ -f "$case_dir/fake.pid" ]; then
    pid="$(sed -n '1p' "$case_dir/fake.pid")"
  fi
  sleep 1
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    alive="yes"
    kill "$pid" 2>/dev/null || true
  fi
  if [ -f "$case_dir/signal" ]; then
    signaled="yes"
  fi
  printf 'fake_pid=%s alive_after_wait=%s signal_recorded=%s\n' \
    "$pid" "$alive" "$signaled" >> "$case_dir/summary"
}

run_all() {
  record_case success-long 0 success_long || return 1
  record_case resume 0 resume_case || return 1
  record_case event-failure 3 event_failure_case || return 1
  record_case timeout 1 timeout_case || return 1
  inspect_cleanup timeout
  record_case cancellation 124 cancellation_case || return 1
  inspect_cleanup cancellation

  printf 'RUN_DIR=%s\n' "$run_dir"
  find "$run_dir" -name summary -type f -print -exec sed -n '1,3p' {} \;
}

case "$case_name" in
  all) run_all ;;
  success-long)
    record_case success-long 0 success_long
    case_rc=$?
    printf 'RUN_DIR=%s\n' "$run_dir"
    exit "$case_rc"
    ;;
  *) printf 'unknown case: %s\n' "$case_name" >&2; exit 2 ;;
esac
