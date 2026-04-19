#!/bin/bash
# Install generated Codex compatibility assets into ~/.codex/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$ROOT_DIR/dist/codex"
OVERRIDES_DIR="$ROOT_DIR/codex-overrides"
TARGET_DIR="$HOME/.codex"
USER_SKILLS_DIR="$HOME/.agents/skills"

source "$OVERRIDES_DIR/config.sh"

DRY_RUN=false
COPY_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --copy)
            COPY_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--copy]"
            echo ""
            echo "Options:"
            echo "  --dry-run  Show what would be installed without changing ~/.codex"
            echo "  --copy     Copy files instead of creating symlinks"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ ! -d "$DIST_DIR" ]; then
    echo "Generated Codex assets not found at $DIST_DIR" >&2
    echo "Run scripts/build-codex-pack.sh first." >&2
    exit 1
fi

managed_installed=0
managed_skipped=0
managed_removed=0

ensure_dir() {
    local dir="$1"
    if [ "$DRY_RUN" = true ]; then
        if [ ! -d "$dir" ]; then
            echo "[DRY RUN] Would create directory: $dir"
        fi
        return 0
    fi
    mkdir -p "$dir"
}

install_path() {
    local source="$1"
    local target="$2"
    local mode="${3:-auto}"

    ensure_dir "$(dirname "$target")"

    if [ -L "$target" ]; then
        local current
        current="$(readlink "$target")"
        if [ "$current" = "$source" ]; then
            if [ "$mode" = "copy" ]; then
                if [ "$DRY_RUN" = true ]; then
                    echo "[DRY RUN] Would replace symlink with copied file: $target"
                else
                    rm "$target"
                    cp "$source" "$target"
                    echo "  ~ Replaced symlink with copied file: $target"
                fi
                managed_installed=$((managed_installed + 1))
                return 0
            fi
            echo "  = Already managed: $target"
            managed_skipped=$((managed_skipped + 1))
            return 0
        fi
        echo "  ! Skipping existing symlink: $target -> $current"
        managed_skipped=$((managed_skipped + 1))
        return 0
    fi

    if [ -e "$target" ]; then
        echo "  ! Skipping existing file: $target"
        managed_skipped=$((managed_skipped + 1))
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        if [ "$mode" = "copy" ] || [ "$COPY_MODE" = true ]; then
            echo "[DRY RUN] Would copy: $target <= $source"
        else
            echo "[DRY RUN] Would symlink: $target -> $source"
        fi
        managed_installed=$((managed_installed + 1))
        return 0
    fi

    if [ "$mode" = "copy" ] || [ "$COPY_MODE" = true ]; then
        cp "$source" "$target"
    else
        ln -s "$source" "$target"
    fi
    echo "  + Installed: $target"
    managed_installed=$((managed_installed + 1))
}

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

echo "Installing generated Codex compatibility assets"
[ "$DRY_RUN" = true ] && echo "[DRY RUN MODE]"
echo ""

ensure_dir "$TARGET_DIR"
ensure_dir "$TARGET_DIR/agents"
ensure_dir "$USER_SKILLS_DIR"

echo "Cleaning up legacy managed prompts..."
ensure_dir "$TARGET_DIR/prompts"
cleanup_legacy_prompts

echo ""
echo "Agents..."
while IFS= read -r file; do
    install_path "$file" "$TARGET_DIR/agents/$(basename "$file")"
done < <(find "$DIST_DIR/agents" -maxdepth 1 -type f -name '*.toml' | sort)

echo ""
echo "Skills..."
while IFS= read -r file; do
    skill_name="$(basename "$(dirname "$file")")"
    ensure_dir "$USER_SKILLS_DIR/$skill_name"
    install_path "$file" "$USER_SKILLS_DIR/$skill_name/SKILL.md" "copy"
done < <(find "$DIST_DIR/skills" -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' | sort)

if [ -f "$DIST_DIR/AGENTS.md" ]; then
    echo ""
    echo "Global instructions..."
    install_path "$DIST_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
fi

if [ -d "$DIST_DIR/hooks" ] && find "$DIST_DIR/hooks" -maxdepth 1 -type f | grep -q .; then
    echo ""
    echo "Hooks..."
    ensure_dir "$TARGET_DIR/hooks"
    while IFS= read -r file; do
        install_path "$file" "$TARGET_DIR/hooks/$(basename "$file")"
    done < <(find "$DIST_DIR/hooks" -maxdepth 1 -type f | sort)

    if [ -f "$DIST_DIR/hooks.json" ]; then
        install_path "$DIST_DIR/hooks.json" "$TARGET_DIR/hooks.json"
        if [ -f "$TARGET_DIR/config.toml" ] && ! grep -q 'codex_hooks' "$TARGET_DIR/config.toml"; then
            echo "  ! Hooks installed, but config.toml does not appear to enable codex hooks."
            echo "    Add the feature flag manually if needed."
        fi
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY RUN] Would record managed source metadata in $TARGET_DIR/.agentic-pack-codex-source"
else
    printf "%s\n" "$ROOT_DIR" > "$TARGET_DIR/.agentic-pack-codex-source"
    printf "%s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TARGET_DIR/.agentic-pack-codex-installed-at"
fi

echo ""
echo "Excluded from this Codex install by design:"
for item in "${EXCLUDED_COMMANDS[@]}"; do
    echo "  - command: $item"
done
for item in "${EXCLUDED_AGENTS[@]}"; do
    echo "  - agent: $item"
done
for item in "${EXCLUDED_HOOKS[@]}"; do
    echo "  - hook: $item"
done

echo ""
echo "Summary: $managed_installed installed, $managed_skipped skipped, $managed_removed removed"
