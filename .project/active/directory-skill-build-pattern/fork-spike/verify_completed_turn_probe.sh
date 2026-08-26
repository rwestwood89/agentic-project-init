#!/usr/bin/env bash
set -euo pipefail

expected_sha256='c5d3597013f4dcf7733ea7374fa32c96e5920b48cecca5d37b2168c8c0ce6b83'

if [[ $# -ne 0 ]]; then
  echo 'usage: printf <candidate> | verify_completed_turn_probe.sh' >&2
  exit 2
fi

IFS= read -r candidate
actual_sha256=$(printf '%s' "$candidate" | sha256sum | cut -d ' ' -f 1)

if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo 'FAIL: nested worker response does not match the parent nonce digest' >&2
  exit 1
fi

echo 'PASS: nested worker recovered its parent completed-turn nonce'
