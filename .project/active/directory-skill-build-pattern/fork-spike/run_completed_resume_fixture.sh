#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
evidence_dir="$script_dir/evidence/completed-resume-fixture"
marker='RESUME-FIXTURE-4f7c92b16a8de305'
mkdir -p "$evidence_dir"

codex exec \
  --json \
  -c 'sandbox_mode="read-only"' \
  -o "$evidence_dir/parent-final.txt" \
  "Do not call tools or inspect files. Retain this marker in the conversation: $marker. Reply exactly PARENT_COMPLETE." \
  >"$evidence_dir/parent.jsonl" \
  2>"$evidence_dir/parent.stderr"

session_id=$(sed -n 's/.*"thread_id":"\([^"]*\)".*/\1/p' "$evidence_dir/parent.jsonl" | head -n 1)
if [[ -z "$session_id" ]]; then
  echo 'could not extract parent thread_id' >&2
  exit 1
fi
printf '%s\n' "$session_id" >"$evidence_dir/session-id.txt"

codex exec resume \
  --json \
  -c 'sandbox_mode="read-only"' \
  -o "$evidence_dir/resume-final.txt" \
  "$session_id" \
  'Do not call tools or inspect files. Report exactly the marker retained in the prior conversation, or CANNOT_RECOVER if absent.' \
  >"$evidence_dir/resume.jsonl" \
  2>"$evidence_dir/resume.stderr"

printf 'session_id=%s\n' "$session_id"
printf 'parent_final=%s\n' "$(sed -n '1p' "$evidence_dir/parent-final.txt")"
printf 'resume_final=%s\n' "$(sed -n '1p' "$evidence_dir/resume-final.txt")"
