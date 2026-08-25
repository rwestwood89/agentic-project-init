#!/usr/bin/env bash
set -euo pipefail

expected_sha256='fc82603d2f20f536468373cd94d6909a09d2ee2a6a4896bddbf0962e4cffdabe'

if [[ $# -ne 0 ]]; then
  echo 'usage: printf <candidate> | verify_probe.sh' >&2
  exit 2
fi

IFS= read -r candidate
actual_sha256=$(printf '%s' "$candidate" | sha256sum | cut -d ' ' -f 1)

if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo 'FAIL: worker response does not match the parent nonce digest' >&2
  exit 1
fi

echo 'PASS: worker recovered the parent conversation nonce'
