#!/bin/bash
# PreCompact hook: delegates to capture.sh
# Reads JSON from stdin and passes to capture script

exec "$(dirname "$0")/capture.sh" --stdin
