#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
evidence_file="$probe_dir/probe-evidence.txt"

[[ -f "$evidence_file" ]] || { echo "FAIL: missing probe-evidence.txt" >&2; exit 1; }

phase_1_digest="$(sed -n 's/^phase_1_sha256=//p' "$evidence_file")"
phase_2_nonce="$(sed -n 's/^phase_2_nonce=//p' "$evidence_file")"
phase_2_marker="$(sed -n 's/^phase_2_marker=//p' "$evidence_file")"

[[ "$phase_1_digest" =~ ^[0-9a-f]{64}$ ]] || { echo "FAIL: invalid phase-1 digest" >&2; exit 1; }
[[ -n "$phase_2_nonce" ]] || { echo "FAIL: missing phase-2 nonce" >&2; exit 1; }
[[ "$phase_2_marker" == "followup_received" ]] || { echo "FAIL: missing phase-2 marker" >&2; exit 1; }

actual_digest="$(printf '%s' "$phase_2_nonce" | sha256sum | awk '{print $1}')"
[[ "$actual_digest" == "$phase_1_digest" ]] || { echo "FAIL: phase-2 nonce does not match phase-1 digest" >&2; exit 1; }

echo "PASS: follow-up turn retained the phase-1 nonce"
