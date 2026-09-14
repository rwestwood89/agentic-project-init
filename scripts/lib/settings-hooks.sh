#!/bin/bash
# Shared settings.json surgery for the pack installers. Sourced, not run.

# Colors are set by the sourcing script; default them so this file also works
# when a test sources it on its own.
: "${GREEN:=}"
: "${RED:=}"
: "${YELLOW:=}"
: "${NC:=}"

# Remove the PreCompact hook registration an earlier version of the pack wrote.
#
# Usage: cleanup_legacy_hooks <settings-file>
#
# The pack registered a PreCompact hook pointing at precompact-capture.sh. That script
# no longer ships, so a machine that installed the pack before it was deleted keeps a
# registration firing at every autocompact. The match is on the script name rather than
# on the hooks directory, so a PreCompact hook the user wrote themselves survives even
# when it lives in the same directory.
#
# No-op when the file is absent, when jq is missing, or when there is no matching hook.
# Invalid JSON fails visibly without changing the file.
# Writes a .bak next to the file before changing it, as uninstall-global.sh does.
cleanup_legacy_hooks() {
    local settings_file="$1"

    [ -f "$settings_file" ] || return 0

    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}  ⚠ jq not found - please manually remove any PreCompact hook from $settings_file${NC}"
        return 0
    fi

    if ! jq 'def legacy_hook: type == "string" and (. == ".claude/hooks/precompact-capture.sh" or endswith("/.claude/hooks/precompact-capture.sh")); if .hooks.PreCompact then .hooks.PreCompact |= [ .[] | if (.hooks | type) == "array" then .hooks |= [ .[] | select(((.command? // "") | legacy_hook) | not) ] else . end | select((.hooks | type) != "array" or (.hooks | length) > 0) ] else . end | if .hooks.PreCompact == [] then del(.hooks.PreCompact) else . end | if .hooks == {} then del(.hooks) else . end' \
        "$settings_file" > "$settings_file.tmp"; then
        rm -f "$settings_file.tmp"
        echo -e "${RED}Error: invalid JSON in $settings_file; legacy hook cleanup was not applied.${NC}" >&2
        return 1
    fi

    if jq -e --slurpfile cleaned "$settings_file.tmp" '. == $cleaned[0]' "$settings_file" > /dev/null; then
        rm "$settings_file.tmp"
        return 0
    fi

    cp "$settings_file" "$settings_file.bak"
    mv "$settings_file.tmp" "$settings_file"
    echo -e "${GREEN}  ✓ Removed legacy PreCompact hook from $settings_file${NC}"
}
