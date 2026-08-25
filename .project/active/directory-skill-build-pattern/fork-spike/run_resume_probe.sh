#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
evidence_dir="$script_dir/evidence"
session_id='01a02290-a71c-78e2-81b6-26f9d0625f0a'
mkdir -p "$evidence_dir"

prompt='Do not call tools or inspect files. From the conversation you resumed, report exactly the high-entropy plaintext nonce that the parent explicitly placed in an assistant conversation message for the context-inheritance probe. Reply with exactly that nonce, or CANNOT_RECOVER if absent.'

set +e
codex exec resume \
  --json \
  -c 'sandbox_mode="read-only"' \
  -o "$evidence_dir/resume-final.txt" \
  "$session_id" \
  "$prompt" \
  >"$evidence_dir/resume.jsonl" \
  2>"$evidence_dir/resume.stderr"
exit_code=$?
set -e

printf '%s\n' "$exit_code" >"$evidence_dir/resume.exit-code.txt"
echo "resume exit code: $exit_code"
if [[ -f "$evidence_dir/resume-final.txt" ]]; then
  sed -n '1,20p' "$evidence_dir/resume-final.txt"
fi
