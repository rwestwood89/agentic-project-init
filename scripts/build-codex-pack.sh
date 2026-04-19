#!/bin/bash
# Build a generated Codex compatibility layer from claude-pack/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

CLAUDE_PACK="$ROOT_DIR/claude-pack"
OVERRIDES_DIR="$ROOT_DIR/codex-overrides"
DIST_DIR="$ROOT_DIR/dist/codex"

source "$OVERRIDES_DIR/config.sh"

included_command_skills=()
excluded_command_skills=()
included_native_skills=()
excluded_native_skills=()
included_agents=()
excluded_agents=()
included_hooks=()
excluded_hooks=()

contains() {
    local needle="$1"
    shift || true
    local item
    for item in "$@"; do
        if [ "$item" = "$needle" ]; then
            return 0
        fi
    done
    return 1
}

quote_json() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/}
    printf '"%s"' "$value"
}

write_json_array() {
    local -n arr_ref="$1"
    local i
    printf "["
    for i in "${!arr_ref[@]}"; do
        if [ "$i" -gt 0 ]; then
            printf ", "
        fi
        quote_json "${arr_ref[$i]}"
    done
    printf "]"
}

extract_frontmatter_value() {
    local file="$1"
    local key="$2"

    awk -v key="$key" '
        NR == 1 && $0 != "---" { exit }
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { exit }
        in_fm && $0 ~ ("^" key ":") {
            sub("^" key ":[[:space:]]*", "", $0)
            gsub(/^"/, "", $0)
            gsub(/"$/, "", $0)
            print
            exit
        }
    ' "$file"
}

strip_frontmatter() {
    local file="$1"

    awk '
        NR == 1 && $0 != "---" {
            print
            next
        }
        NR == 1 && $0 == "---" {
            in_fm = 1
            next
        }
        in_fm && $0 == "---" {
            in_fm = 0
            next
        }
        !in_fm {
            print
        }
    ' "$file"
}

extract_heading() {
    local file="$1"
    awk '/^# / { sub(/^# /, "", $0); print; exit }' "$file"
}

extract_purpose() {
    local file="$1"
    awk '
        /^\*\*Purpose\*\*:/ || /^\*\*Purpose:\*\*/ || /^\*\*Purpose\*\*:|^\*\*Purpose\*\*:/ {
            line = $0
            sub(/^\*\*Purpose\*\*:?[[:space:]]*/, "", line)
            print line
            exit
        }
    ' "$file"
}

strip_command_prefix() {
    local base="$1"
    base="${base%.md}"
    base="${base#_my_}"
    printf "%s" "$base"
}

to_hyphen_name() {
    local name="$1"
    printf "%s" "${name//_/-}"
}

sanitize_command_body_for_skill() {
    local file="$1"
    export COMMAND_SKILL_PREFIX

    strip_frontmatter "$file" | perl -0pe '
        s{\$ARGUMENTS}{User-provided arguments are supplied when this skill is invoked.}g;
        s{/_my_([a-z_]+)}{
            my $n = $1;
            $n =~ tr/_/-/;
            "`" . ($ENV{COMMAND_SKILL_PREFIX} // "") . $n . "`";
        }ge;
    '
}

description_for_command_skill() {
    local source_name="$1"
    local source_file="$2"
    local key

    key="$(to_hyphen_name "$source_name")"
    if [[ -n "${COMMAND_SKILL_DESCRIPTIONS[$key]:-}" ]]; then
        printf "%s" "${COMMAND_SKILL_DESCRIPTIONS[$key]}"
        return 0
    fi

    local fm_desc
    fm_desc="$(extract_frontmatter_value "$source_file" "description" || true)"
    if [ -n "$fm_desc" ]; then
        printf "%s" "$fm_desc"
        return 0
    fi

    local purpose
    purpose="$(extract_purpose "$source_file" || true)"
    if [ -n "$purpose" ]; then
        printf "%s" "$purpose"
        return 0
    fi

    local heading
    heading="$(extract_heading "$source_file" || true)"
    if [ -n "$heading" ]; then
        printf "%s" "$heading"
        return 0
    fi

    printf "Generated Codex skill from %s." "$source_name"
}

description_for_agent() {
    local agent_name="$1"
    local source_file="$2"
    local fm_desc

    if [[ -n "${AGENT_DESCRIPTIONS[$agent_name]:-}" ]]; then
        printf "%s" "${AGENT_DESCRIPTIONS[$agent_name]}"
        return 0
    fi

    fm_desc="$(extract_frontmatter_value "$source_file" "description" || true)"
    if [ -n "$fm_desc" ]; then
        printf "%s" "$fm_desc"
        return 0
    fi

    local heading
    heading="$(extract_heading "$source_file" || true)"
    if [ -n "$heading" ]; then
        printf "%s" "$heading"
        return 0
    fi

    printf "Generated Codex agent from %s." "$agent_name"
}

description_for_native_skill() {
    local skill_name="$1"
    local source_file="$2"
    local fm_desc

    fm_desc="$(extract_frontmatter_value "$source_file" "description" || true)"
    if [ -n "$fm_desc" ]; then
        printf "%s" "$fm_desc"
        return 0
    fi

    printf "Generated Codex skill from %s." "$skill_name"
}

mkdir -p "$DIST_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/agents" "$DIST_DIR/skills" "$DIST_DIR/hooks"

timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
revision="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"

while IFS= read -r file; do
    base="$(basename "$file")"
    base_no_ext="${base%.md}"
    source_name="$(strip_command_prefix "$base")"
    semantic_name="$(to_hyphen_name "$source_name")"
    skill_name="${COMMAND_SKILL_PREFIX}${semantic_name}"

    if contains "$base_no_ext" "${EXCLUDED_COMMANDS[@]}"; then
        excluded_command_skills+=("$skill_name")
        continue
    fi

    description="$(description_for_command_skill "$source_name" "$file")"
    skill_dir="$DIST_DIR/skills/$skill_name"
    output_file="$skill_dir/SKILL.md"
    wrapper_file="$OVERRIDES_DIR/command-skill-prefixes/$semantic_name.md"
    if [ ! -f "$wrapper_file" ]; then
        wrapper_file="$OVERRIDES_DIR/prompt-prefixes/$semantic_name.md"
    fi

    mkdir -p "$skill_dir"
    {
        printf -- "---\n"
        printf "name: %s\n" "$skill_name"
        printf "description: %s\n" "$description"
        printf -- "---\n\n"
        printf "Generated from \`claude-pack/commands/%s\`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.\n\n" "$base"
        if [ -f "$wrapper_file" ]; then
            cat "$wrapper_file"
            printf "\n"
        fi
        sanitize_command_body_for_skill "$file"
        printf "\n"
    } > "$output_file"

    included_command_skills+=("$skill_name")
done < <(find "$CLAUDE_PACK/commands" -maxdepth 1 -type f -name '*.md' | sort)

while IFS= read -r file; do
    base="$(basename "$file" .md)"
    if contains "$base" "${EXCLUDED_AGENTS[@]}"; then
        excluded_agents+=("$base")
        continue
    fi

    agent_name="$(extract_frontmatter_value "$file" "name" || true)"
    if [ -z "$agent_name" ]; then
        agent_name="$base"
    fi
    description="$(description_for_agent "$agent_name" "$file")"
    output_file="$DIST_DIR/agents/$agent_name.toml"

    {
        printf "name = "
        quote_json "$agent_name"
        printf "\n"
        printf "description = "
        quote_json "$description"
        printf "\n"
        printf "developer_instructions = '''\n"
        printf "Generated from claude-pack/agents/%s. Rebuild this file instead of editing it by hand.\n\n" "$(basename "$file")"
        strip_frontmatter "$file"
        printf "\n'''\n"
    } > "$output_file"

    included_agents+=("$agent_name")
done < <(find "$CLAUDE_PACK/agents" -maxdepth 1 -type f -name '*.md' | sort)

while IFS= read -r file; do
    base="$(basename "$file" .md)"
    if [ "${#NATIVE_SKILL_ALLOWLIST[@]}" -gt 0 ] && ! contains "$base" "${NATIVE_SKILL_ALLOWLIST[@]}"; then
        excluded_native_skills+=("$base")
        continue
    fi

    skill_name="$(extract_frontmatter_value "$file" "name" || true)"
    if [ -z "$skill_name" ]; then
        skill_name="$base"
    fi
    description="$(description_for_native_skill "$skill_name" "$file")"
    skill_dir="$DIST_DIR/skills/$skill_name"
    output_file="$skill_dir/SKILL.md"

    mkdir -p "$skill_dir"
    {
        printf -- "---\n"
        printf "name: %s\n" "$skill_name"
        printf "description: %s\n" "$description"
        printf -- "---\n\n"
        printf "Generated from \`claude-pack/skills/%s\`. Rebuild this file instead of editing it by hand.\n\n" "$(basename "$file")"
        strip_frontmatter "$file"
        printf "\n"
    } > "$output_file"

    included_native_skills+=("$skill_name")
done < <(find "$CLAUDE_PACK/skills" -maxdepth 1 -type f -name '*.md' | sort)

{
    printf "# AGENTS.md\n\n"
    printf "Generated from \`claude-pack/rules/\`. Rebuild this file instead of editing it by hand.\n\n"
    while IFS= read -r file; do
        printf "## From \`%s\`\n\n" "$(basename "$file")"
        strip_frontmatter "$file"
        printf "\n\n"
    done < <(find "$CLAUDE_PACK/rules" -maxdepth 1 -type f -name '*.md' | sort)
} > "$DIST_DIR/AGENTS.md"

while IFS= read -r file; do
    base="$(basename "$file")"
    if contains "$base" "${EXCLUDED_HOOKS[@]}"; then
        excluded_hooks+=("$base")
        continue
    fi

    cp "$file" "$DIST_DIR/hooks/$base"
    included_hooks+=("$base")
done < <(find "$CLAUDE_PACK/hooks" -maxdepth 1 -type f | sort)

if [ "${#included_hooks[@]}" -gt 0 ]; then
    {
        printf "{\n"
        printf "  \"hooks\": [\n"
        local_index=0
        for hook_name in "${included_hooks[@]}"; do
            if [ "$local_index" -gt 0 ]; then
                printf ",\n"
            fi
            printf "    {\n"
            printf "      \"event\": \"Stop\",\n"
            printf "      \"matcher\": \"*\",\n"
            printf "      \"command\": [\"~/.codex/hooks/%s\"]\n" "$hook_name"
            printf "    }"
            local_index=$((local_index + 1))
        done
        printf "\n  ]\n"
        printf "}\n"
    } > "$DIST_DIR/hooks.json"
fi

{
    printf "{\n"
    printf "  \"generated_at\": "
    quote_json "$timestamp"
    printf ",\n"
    printf "  \"source_revision\": "
    quote_json "$revision"
    printf ",\n"
    printf "  \"source_root\": "
    quote_json "$ROOT_DIR"
    printf ",\n"
    printf "  \"included\": {\n"
    printf "    \"command_skills\": "
    write_json_array included_command_skills
    printf ",\n"
    printf "    \"skills\": "
    write_json_array included_native_skills
    printf ",\n"
    printf "    \"agents\": "
    write_json_array included_agents
    printf ",\n"
    printf "    \"hooks\": "
    write_json_array included_hooks
    printf "\n"
    printf "  },\n"
    printf "  \"excluded\": {\n"
    printf "    \"command_skills\": "
    write_json_array excluded_command_skills
    printf ",\n"
    printf "    \"skills\": "
    write_json_array excluded_native_skills
    printf ",\n"
    printf "    \"agents\": "
    write_json_array excluded_agents
    printf ",\n"
    printf "    \"hooks\": "
    write_json_array excluded_hooks
    printf "\n"
    printf "  }\n"
    printf "}\n"
} > "$DIST_DIR/manifest.json"

echo "Built Codex compatibility layer in $DIST_DIR"
echo "Command skills: ${#included_command_skills[@]} included, ${#excluded_command_skills[@]} excluded"
echo "Native skills:  ${#included_native_skills[@]} included, ${#excluded_native_skills[@]} excluded"
echo "Agents:         ${#included_agents[@]} included, ${#excluded_agents[@]} excluded"
echo "Hooks:          ${#included_hooks[@]} included, ${#excluded_hooks[@]} excluded"
