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
FORCE=false

is_managed_file() {
    local path="$1"
    [ -f "$path" ] && head -n 20 "$path" 2>/dev/null | grep -q "Generated from"
}

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
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--copy] [--force]"
            echo ""
            echo "Options:"
            echo "  --dry-run  Show what would be installed without changing ~/.codex"
            echo "  --copy     Copy files instead of creating symlinks"
            echo "  --force    Overwrite existing files even if not previously managed"
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

AGENTS_BLOCK_BEGIN="<!-- agentic-project-init codex rules begin -->"
AGENTS_BLOCK_END="<!-- agentic-project-init codex rules end -->"

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
        if is_managed_file "$target" || [ "$FORCE" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would overwrite managed file: $target"
                managed_installed=$((managed_installed + 1))
                return 0
            fi
            rm "$target"
        else
            echo "  ! Skipping user-authored file (use --force to overwrite): $target"
            managed_skipped=$((managed_skipped + 1))
            return 0
        fi
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

install_global_agents() {
    local source="$1"
    local target="$2"

    ensure_dir "$(dirname "$target")"

    if [ ! -e "$target" ] || [ -L "$target" ] || is_managed_file "$target" || [ "$FORCE" = true ]; then
        install_path "$source" "$target"
        return 0
    fi

    if grep -q "$AGENTS_BLOCK_BEGIN" "$target"; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would update managed Codex rules block in: $target"
            managed_installed=$((managed_installed + 1))
            return 0
        fi

        local tmp
        tmp="$(mktemp)"
        awk -v begin="$AGENTS_BLOCK_BEGIN" -v end="$AGENTS_BLOCK_END" -v source="$source" '
            $0 == begin {
                print begin
                while ((getline line < source) > 0) print line
                close(source)
                print end
                skipping = 1
                next
            }
            $0 == end {
                skipping = 0
                next
            }
            !skipping { print }
        ' "$target" > "$tmp"
        mv "$tmp" "$target"
        echo "  ~ Updated managed Codex rules block: $target"
        managed_installed=$((managed_installed + 1))
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would append managed Codex rules block to user-authored file: $target"
        managed_installed=$((managed_installed + 1))
        return 0
    fi

    {
        printf "\n%s\n" "$AGENTS_BLOCK_BEGIN"
        cat "$source"
        printf "%s\n" "$AGENTS_BLOCK_END"
    } >> "$target"
    echo "  + Appended managed Codex rules block: $target"
    managed_installed=$((managed_installed + 1))
}

# Does an installed skill directory belong to us? The entry point answers for the whole tree
# (D3): missing, carrying the `Generated from` marker, or still a symlink into the dist we manage.
# One answer governs every file, which is what makes verbatim-copied siblings re-installable — the
# per-file marker check classifies them user-authored from the second install onward.
skill_dir_is_managed() {
    local entry_point="$1"

    [ -e "$entry_point" ] || return 0
    if [ -L "$entry_point" ]; then
        case "$(readlink "$entry_point")" in
            "$DIST_DIR"/*) return 0 ;;
        esac
    fi
    is_managed_file "$entry_point"
}

# Put one file of an approved skill directory in place. No per-file guard runs here: the
# directory-level decision was already made. Always a copy, never a symlink — Codex silently
# refuses to register a skill whose SKILL.md is a symlink.
install_skill_file() {
    local source="$1"
    local target="$2"

    if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$source" "$target"; then
        echo "  = Already current: $target"
        managed_skipped=$((managed_skipped + 1))
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would copy: $target <= $source"
        managed_installed=$((managed_installed + 1))
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    rm -f "$target"
    cp "$source" "$target"
    echo "  + Installed: $target"
    managed_installed=$((managed_installed + 1))
}

remove_stale_skill_file() {
    local target="$1"

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would remove file no longer in dist: $target"
    else
        rm -f "$target"
        echo "  - Removed file no longer in dist: $target"
    fi
    managed_removed=$((managed_removed + 1))
}

# Mirror one dist skill directory onto its target: add, overwrite, and remove files so a re-install
# converges instead of accumulating. An entry point that exists without our marker means someone
# authored it, and the whole directory is left alone.
mirror_skill_dir() {
    local source_dir="$1"
    local target_dir="$2"
    local rel

    if [ "$FORCE" != true ] && ! skill_dir_is_managed "$target_dir/SKILL.md"; then
        echo "  ! Skipping user-authored skill directory (use --force to overwrite): $target_dir"
        managed_skipped=$((managed_skipped + 1))
        return 0
    fi

    ensure_dir "$target_dir"

    while IFS= read -r rel; do
        rel="${rel#./}"
        install_skill_file "$source_dir/$rel" "$target_dir/$rel"
    done < <(cd "$source_dir" && find . -type f | sort)

    [ -d "$target_dir" ] || return 0

    while IFS= read -r rel; do
        rel="${rel#./}"
        if [ ! -f "$source_dir/$rel" ]; then
            remove_stale_skill_file "$target_dir/$rel"
        fi
    done < <(cd "$target_dir" && find . \( -type f -o -type l \) | sort)
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
ensure_dir "$TARGET_DIR/scripts"
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
while IFS= read -r source_dir; do
    mirror_skill_dir "$source_dir" "$USER_SKILLS_DIR/$(basename "$source_dir")"
done < <(find "$DIST_DIR/skills" -mindepth 1 -maxdepth 1 -type d | sort)

if [ -f "$DIST_DIR/AGENTS.md" ]; then
    echo ""
    echo "Global instructions..."
    install_global_agents "$DIST_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
fi

if [ -d "$DIST_DIR/scripts" ] && find "$DIST_DIR/scripts" -maxdepth 1 -type f | grep -q .; then
    echo ""
    echo "Scripts..."
    ensure_dir "$TARGET_DIR/scripts"
    while IFS= read -r file; do
        install_path "$file" "$TARGET_DIR/scripts/$(basename "$file")"
    done < <(find "$DIST_DIR/scripts" -maxdepth 1 -type f | sort)
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
