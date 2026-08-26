#!/usr/bin/env bash
set -euo pipefail

skill_directory_arg=${1:?pass the absolute skill directory as argument 1}
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
relative_target="codex-cwd-relative-write.txt"

printf 'PWD_LOGICAL=%s\n' "$PWD"
printf 'PWD_PHYSICAL=%s\n' "$(pwd -P)"
printf 'SKILL_DIRECTORY_ARG=%s\n' "$skill_directory_arg"
printf 'SCRIPT_DIRECTORY=%s\n' "$script_directory"
printf 'SCRIPT_REALPATH=%s\n' "$(readlink -f -- "$0")"
printf 'SIBLING_TOKEN=%s\n' "$(sed -n '1p' "$script_directory/sibling-token.txt")"
printf 'RELATIVE_TARGET_ABSOLUTE=%s\n' "$(realpath -m -- "$relative_target")"

printf 'RELATIVE-WRITE-OK-4N6P\n' > "$relative_target"

printf 'RELATIVE_WRITE_EXISTS=%s\n' "$(test -f "$relative_target" && echo yes || echo no)"

