#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
evidence_dir="$script_dir/evidence"
mkdir -p "$evidence_dir"

codex --version >"$evidence_dir/codex-version.txt" 2>&1
codex --help >"$evidence_dir/codex-help.txt" 2>&1
codex exec --help >"$evidence_dir/codex-exec-help.txt" 2>&1
codex exec resume --help >"$evidence_dir/codex-exec-resume-help.txt" 2>&1
codex exec fork --help >"$evidence_dir/codex-exec-fork-help.txt" 2>&1

echo "Captured CLI help under $evidence_dir"
