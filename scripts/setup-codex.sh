#!/bin/bash
# Install generated Codex compatibility assets for the current user.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$HOME/.codex"
source "$ROOT_DIR/codex-overrides/config.sh"
DRY_RUN=false
args=()
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true; args+=("$arg") ;;
        --copy|--force) args+=("$arg") ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--copy] [--force]"
            echo "Install user-level Codex assets; --copy copies helpers instead of symlinking."
            echo "--force replaces conflicting owner files; --dry-run writes nothing."
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done
python3 "$SCRIPT_DIR/lib/codex-install.py" --source "$ROOT_DIR" "${args[@]}"
managed_removed=0
remove_path_if_managed() {
    local target="$1"
    local expected_prefix="$2"

    if [ ! -L "$target" ]; then
        return 0
    fi

    local current
    current="$(readlink "$target")"
    case "$current" in
        "$expected_prefix"*)
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would remove old managed path: $target"
            else
                rm "$target"
                echo "  - Removed old managed path: $target"
            fi
            managed_removed=$((managed_removed + 1))
            ;;
    esac
}

cleanup_legacy_prompts() {
    local commands_dir="$ROOT_DIR/claude-pack/commands"
    local file
    while IFS= read -r file; do
        local base base_no_ext semantic_name prompt_name target
        base="$(basename "$file")"
        base_no_ext="${base%.md}"

        case " ${EXCLUDED_COMMANDS[*]} " in
            *" $base_no_ext "*) continue ;;
        esac

        semantic_name="${base_no_ext#_my_}"
        semantic_name="${semantic_name//_/-}"
        prompt_name="${COMMAND_SKILL_PREFIX}${semantic_name}"
        target="$TARGET_DIR/prompts/$prompt_name.md"
        remove_path_if_managed "$target" "$ROOT_DIR/dist/codex/prompts/"
    done < <(find "$commands_dir" -maxdepth 1 -type f -name '*.md' | sort)
}

cleanup_legacy_prompts
