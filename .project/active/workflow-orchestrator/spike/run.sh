#!/usr/bin/env bash
# Reproduces the workflow-orchestrator invocation spike.
#
# Simulates an autonomous orchestrator driving spec -> spec-review -> revise
# through headless `claude -p` subagents, in a throwaway sandbox project.
#
# Usage: ./run.sh [sandbox_dir]
# Requires: claude 2.x on PATH, authenticated.
set -euo pipefail

SPIKE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX="${1:-$(mktemp -d)/spike-sandbox}"
MODEL="${SPIKE_MODEL:-sonnet}"          # production would use opus for stage subagents
LOGS="$SPIKE/logs"; SNAP="$SPIKE/sandbox-snapshot"
mkdir -p "$LOGS" "$SNAP"

# --- helpers ---------------------------------------------------------------
# Run a headless stage. $1=label $2=prompt-file [$3=--resume session-id]
# Prompt is piped on stdin so we never hit the "no stdin data" warning.
run_stage () {
  local label="$1" prompt_file="$2" resume="${3:-}"
  local args=(-p --model "$MODEL" --output-format json --permission-mode acceptEdits)
  [[ -n "$resume" ]] && args+=(--resume "$resume")
  ( cd "$SANDBOX" && claude "${args[@]}" < "$prompt_file" ) \
      > "$LOGS/$label.json" 2> "$LOGS/$label.stderr"
}
# Pull a field out of the final result object (tolerates a stdin-warning prefix).
result_field () { # $1=logfile $2=field
  python3 - "$1" "$2" <<'PY'
import json,sys
raw=open(sys.argv[1]).read(); i=raw.find('[{')
d=json.loads(raw[i:] if i>=0 else raw)
r=[e for e in d if e.get('type')=='result'][0]
v=r.get(sys.argv[2],'')
print(v if not isinstance(v,float) else round(v,4))
PY
}

# --- sandbox ---------------------------------------------------------------
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX/.project/active"
printf '# Current Work\n\n## Active Work\n\n*(none)*\n' > "$SANDBOX/.project/CURRENT_WORK.md"
printf '# Sandbox Project\n\nThrowaway project for the orchestrator spike.\n' > "$SANDBOX/CLAUDE.md"
echo "sandbox: $SANDBOX  model: $MODEL"

# --- 1. spec (fresh) -------------------------------------------------------
echo ">> spec"
run_stage 01-spec "$SPIKE/prompts/spec.txt"
SPEC_SID="$(result_field "$LOGS/01-spec.json" session_id)"
SPEC="$SANDBOX/.project/active/wordfreq/spec.md"
cp "$SPEC" "$SNAP/spec.v1-original.md"
echo "   session=$SPEC_SID  spec=$(wc -l <"$SPEC") lines"

# --- 2. spec-review (fresh) ------------------------------------------------
echo ">> spec-review"
run_stage 02-spec-review "$SPIKE/prompts/spec-review.txt"
cp "$SANDBOX/.project/active/wordfreq/spec-review.md" "$SNAP/spec-review.md"
echo "   verdict in $LOGS/02-spec-review.json"

# --- 3. revise via RESUME of the spec session (recommended path) -----------
echo ">> revise (resume)"
run_stage 03-revise-resume "$SPIKE/prompts/revise-resume.txt" "$SPEC_SID"
cp "$SPEC" "$SNAP/spec.v2-after-resume.md"

# --- 4. revise via FRESH stateless subagent (comparison) -------------------
echo ">> revise (fresh, isolated)"
cp "$SNAP/spec.v1-original.md" "$SPEC"          # isolate from step 3
run_stage 04-revise-fresh "$SPIKE/prompts/revise-fresh.txt"
cp "$SPEC" "$SNAP/spec.v2-after-fresh.md"

# --- 5. re-review for convergence ------------------------------------------
echo ">> re-review (convergence check)"
cp "$SNAP/spec.v2-after-resume.md" "$SPEC"
run_stage 05-spec-review-2 "$SPIKE/prompts/spec-review.txt"

echo "done. logs in $LOGS, artifacts in $SNAP"
