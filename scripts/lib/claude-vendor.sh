#!/bin/bash
# Vendor claude-pack/ into a project's .claude/ and track which files the pack owns.
#
# The inventory (.claude/.agentic-pack-inventory) records each installed file as
# "<relative path><TAB><sha256 of the installed bytes>". A file is pack-owned only
# while its bytes still match that hash, so a refresh or uninstall never replaces or
# removes a file the owner edited, and never touches a file the pack did not install.

: "${GREEN:=}"
: "${YELLOW:=}"
: "${BLUE:=}"
: "${NC:=}"

CLAUDE_VENDOR_SUBDIRS=(commands agents skills rules scripts)
CLAUDE_VENDOR_INVENTORY=".agentic-pack-inventory"

claude_vendor_hash() {
    if command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

# Print the recorded hash for a relative path, or nothing.
claude_vendor_recorded() {
    local inventory="$1" rel="$2"
    [ -f "$inventory" ] || return 0
    awk -F'\t' -v p="$rel" '$1 == p { print $2; exit }' "$inventory"
}

# True when the destination or any ancestor below the .claude root is a symlink.
claude_vendor_redirected() {
    local claude_dir="$1" rel="$2" path
    path="$claude_dir/$rel"
    while [ "$path" != "$claude_dir" ]; do
        [ -L "$path" ] && return 0
        path=$(dirname "$path")
    done
    [ -L "$claude_dir" ]
}

# Remove now-empty directories left behind by a removed file, stopping at the
# pack subdirectory (commands/, skills/, ...).
claude_vendor_prune() {
    local claude_dir="$1" rel="$2" dir
    dir=$(dirname "$rel")
    while [ "$dir" != "." ] && [ "${dir%%/*}" != "$dir" ]; do
        rmdir "$claude_dir/$dir" 2> /dev/null || return 0
        dir=$(dirname "$dir")
    done
}

# Install or refresh the pack. Plain runs add missing files. --force also refreshes
# pack-owned files that are out of date. Either way, files the pack retired are removed
# if unmodified, and edited or owner-authored files are kept with a diagnostic.
vendor_claude_pack() {
    local claude_pack="$1" claude_dir="$2"
    local inventory="$claude_dir/$CLAUDE_VENDOR_INVENTORY"
    local marker="$claude_dir/.agentic-pack-vendored"
    local new_inventory rel src target recorded current shipped adopt=false

    # A vendored install from before the inventory existed: adopt its pack-named files.
    if [ -f "$marker" ] && [ ! -f "$inventory" ]; then
        adopt=true
    fi

    new_inventory=$(mktemp)

    while IFS= read -r -d '' src; do
        rel="${src#"$claude_pack"/}"
        target="$claude_dir/$rel"
        recorded=$(claude_vendor_recorded "$inventory" "$rel")
        shipped=$(claude_vendor_hash "$src")

        if claude_vendor_redirected "$claude_dir" "$rel"; then
            echo -e "${YELLOW}  ⚠ Skipped (symlink): $rel${NC}"
            continue
        fi

        if [ ! -e "$target" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "${BLUE}[DRY RUN] Would add: $rel${NC}"
            else
                mkdir -p "$(dirname "$target")"
                cp -p "$src" "$target"
                echo -e "${GREEN}  ✓ $rel${NC}"
            fi
            printf '%s\t%s\n' "$rel" "$shipped" >> "$new_inventory"
            continue
        fi

        current=$(claude_vendor_hash "$target")
        # The marker says the pack vendored this file; take its bytes as installed.
        [ -n "$recorded" ] || [ "$adopt" != true ] || recorded="$current"
        if [ "$current" = "$shipped" ]; then
            printf '%s\t%s\n' "$rel" "$shipped" >> "$new_inventory"
        elif [ -n "$recorded" ] && [ "$current" != "$recorded" ]; then
            echo -e "${YELLOW}  ⚠ Kept (locally modified): $rel${NC}"
            printf '%s\t%s\n' "$rel" "$recorded" >> "$new_inventory"
        elif [ -z "$recorded" ]; then
            echo -e "${YELLOW}  ⚠ Kept (not installed by the pack): $rel${NC}"
        elif [ "$FORCE_UPDATE" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "${BLUE}[DRY RUN] Would update: $rel${NC}"
            else
                cp -p "$src" "$target"
                echo -e "${GREEN}  ✓ Updated: $rel${NC}"
            fi
            printf '%s\t%s\n' "$rel" "$shipped" >> "$new_inventory"
        else
            echo -e "${YELLOW}  ⚠ Outdated (rerun with --force to refresh): $rel${NC}"
            printf '%s\t%s\n' "$rel" "$recorded" >> "$new_inventory"
        fi
    done < <(for subdir in "${CLAUDE_VENDOR_SUBDIRS[@]}"; do
                 [ -d "$claude_pack/$subdir" ] && find "$claude_pack/$subdir" -type f -print0
             done)

    # Retire files the pack installed but no longer ships.
    if [ -f "$inventory" ]; then
        while IFS=$'\t' read -r rel recorded; do
            [ -n "$rel" ] || continue
            [ -f "$claude_pack/$rel" ] && continue
            target="$claude_dir/$rel"
            if [ ! -f "$target" ] || claude_vendor_redirected "$claude_dir" "$rel"; then
                continue
            fi
            if [ "$(claude_vendor_hash "$target")" != "$recorded" ]; then
                echo -e "${YELLOW}  ⚠ Kept (retired from the pack but locally modified): $rel${NC}"
            elif [ "$DRY_RUN" = true ]; then
                echo -e "${BLUE}[DRY RUN] Would remove retired: $rel${NC}"
            else
                rm "$target"
                claude_vendor_prune "$claude_dir" "$rel"
                echo -e "${GREEN}  ✓ Removed retired: $rel${NC}"
            fi
        done < "$inventory"
    fi

    if [ "$DRY_RUN" != true ]; then
        sort "$new_inventory" > "$inventory"
        echo "vendored" > "$marker"
    fi
    rm -f "$new_inventory"
}

# Remove every inventoried file that is still unmodified. Edited files are kept.
uninstall_claude_pack() {
    local claude_dir="$1"
    local inventory="$claude_dir/$CLAUDE_VENDOR_INVENTORY"
    local rel recorded target

    while IFS=$'\t' read -r rel recorded; do
        [ -n "$rel" ] || continue
        target="$claude_dir/$rel"
        if [ ! -f "$target" ] || claude_vendor_redirected "$claude_dir" "$rel"; then
            continue
        fi
        if [ "$(claude_vendor_hash "$target")" = "$recorded" ]; then
            rm "$target"
            claude_vendor_prune "$claude_dir" "$rel"
            echo -e "${GREEN}  ✓ Removed: $rel${NC}"
        else
            echo -e "${YELLOW}  ⚠ Kept (locally modified): $rel${NC}"
        fi
    done < "$inventory"
    rm -f "$inventory"
}
