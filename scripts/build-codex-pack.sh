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
included_scripts=()
included_replacements=()

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
        /^\*\*Purpose[:*]/ {
            line = $0
            sub(/^\*\*Purpose\*\*:?[[:space:]]*/, "", line)
            sub(/^\*\*Purpose:\*\*[[:space:]]*/, "", line)
            gsub(/\*\*/, "", line)
            sub(/[[:space:]]+$/, "", line)
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

# A directory skill's Codex name (D2). `_my_x_y` becomes `my-x-y`, which is what the command lane
# rewrites a `/_my_x_y` mention to, so cross-references from other skills resolve. Any other
# directory name passes through unchanged. A pure function of the pack directory name — the
# frontmatter is never consulted, because Claude requires it to match the directory.
codex_name_for_skill_dir() {
    local dir_name="$1"

    if [[ "$dir_name" == _my_* ]]; then
        printf "%s%s" "$COMMAND_SKILL_PREFIX" "$(to_hyphen_name "$(strip_command_prefix "$dir_name")")"
        return 0
    fi
    printf "%s" "$dir_name"
}

# Substitutions every Codex lane applies: shared path rewrites, the Claude agent-tool vocabulary,
# and $ARGUMENTS. Reads a body on stdin and writes it on stdout, so a lane can pipe its own
# lane-specific pass after this one (D8).
apply_common_substitutions() {
    perl -0pe '
        s{~/\.claude/scripts/product-lens\.md}{\$HOME/.codex/scripts/product-lens.md}g;
        s{Use `Task` tool with `subagent_type=general-purpose`}{Use a fresh-context `default` subagent}g;
        s{Use `Task` tool with `subagent_type=Explore`}{Use a fresh-context `explorer` subagent}g;
        s{Use `Agent` tool with `subagent_type=Explore`}{Use a fresh-context `explorer` subagent}g;
        s{use the `Task` tool with `subagent_type=Explore`}{use a fresh-context `explorer` subagent}g;
        s{using `Task` tool with `subagent_type=Explore`}{using a fresh-context `explorer` subagent}g;
        s{Spawn a `general-purpose` subagent}{Spawn a fresh-context `default` subagent}g;
        s{spawn a `general-purpose` subagent}{spawn a fresh-context `default` subagent}g;
        s{\*\*general-purpose agent\*\*}{**fresh-context `default` subagent**}g;
        s{\*\*general-purpose agents:\*\*}{**fresh-context `default` subagents:**}g;
        s{\*\*Explore agent\*\*}{**fresh-context `explorer` subagent**}g;
        s{\*\*Explore agents:\*\*}{**fresh-context `explorer` subagents:**}g;
        s{Use Explore subagent}{Use a fresh-context `explorer` subagent}g;
        s{Task subagents}{Codex subagents}g;
        s{using the Task tool}{using the collaboration tools}g;
        s{\$ARGUMENTS}{User-provided arguments are supplied when this skill is invoked.}g;
    '
}

sanitize_command_body_for_skill() {
    local file="$1"
    export COMMAND_SKILL_PREFIX

    strip_frontmatter "$file" | apply_common_substitutions | perl -0pe '
        s{~/\.claude/commands/_my_ponytail\.md}{\$HOME/.agents/skills/my-ponytail/SKILL.md}g;
        s{/_my_([a-z_]+)}{
            my $n = $1;
            $n =~ tr/_/-/;
            "`" . ($ENV{COMMAND_SKILL_PREFIX} // "") . $n . "`";
        }ge;
    '
}

# The Codex text for each `harness-block` key in a pack skill (D9). Keyed rather than matched on
# sentence text, so rewording the Claude prose cannot silently break a substitution. Phrasing
# follows codex-overrides/rules/collaboration.md, which already ships to Codex inside AGENTS.md.
declare -A CODEX_SKILL_HARNESS_BLOCKS

CODEX_SKILL_HARNESS_BLOCKS[skill-base-directory]="$(cat <<'HARNESS_BLOCK'
Your available-skills inventory gives this skill's absolute `SKILL.md` path. The directory that
path sits in is this skill's base directory.
HARNESS_BLOCK
)"

CODEX_SKILL_HARNESS_BLOCKS[synthesis-spawn]="$(cat <<'HARNESS_BLOCK'
- **Carried** (or carried + clean room): call `spawn_agent` with `fork_turns: "all"`, which passes
  the surrounding conversation to the new agent. Do not set `agent_type`, `model`, or
  `reasoning_effort` alongside it — the call is invalid with any of them.
- **Discovered** or **clean room**: call `spawn_agent` with `fork_turns: "none"`, stated
  explicitly. `fork_turns` defaults to `"all"`, so omitting it hands the agent the whole
  conversation — which under clean room breaks the restriction the owner asked for.

Pass a `task_name` like `synthesis_{slug}` — lowercase letters, digits, and underscores only — and
**record the agent identity the spawn returns**. It comes back in the form `/root/synthesis_{slug}`,
and that value, not the name you asked for, is what addresses the agent later.
HARNESS_BLOCK
)"

# Claude-only advice with no Codex equivalent: Codex reads files through its shell, so there is no
# quieter tool to prefer. Registered empty, which deletes the span.
CODEX_SKILL_HARNESS_BLOCKS[read-synthesis-file]=""

CODEX_SKILL_HARNESS_BLOCKS[correction-dispatch]="$(cat <<'HARNESS_BLOCK'
Send the correction to the synthesis agent as a follow-up task (`followup_task`), addressed to the
agent identity you recorded at spawn, in the owner's own words.
HARNESS_BLOCK
)"

CODEX_SKILL_HARNESS_BLOCKS[render-dispatch]="$(cat <<'HARNESS_BLOCK'
- **Resumed**: send a follow-up task (`followup_task`) to the synthesis agent identity you recorded
  at spawn.
- **Fresh**: `spawn_agent` with `fork_turns: "none"` — a clean window is the whole point, so never
  `"all"`. Pass a `task_name` like `render_{slug}_fresh` and record the identity it returns.
HARNESS_BLOCK
)"

CODEX_SKILL_HARNESS_BLOCKS[carried-fork]="$(cat <<'HARNESS_BLOCK'
**Carried**: you were spawned with `fork_turns: "all"`, so the conversation's completed turns came
with you. What the coordinator produced during the turn that spawned you did not, so treat the spawn
prompt as the authority on the classification.
HARNESS_BLOCK
)"

# Replace each `harness-block` span with the Codex text registered for its key, dropping the markers
# either way (D9). An unregistered key leaves the Claude wording in place and says nothing — the
# owner's call that this adapter adds no new failure conditions; the detector is running the skill
# on Codex. A key registered as empty deletes the span. A malformed marker matches nothing and
# survives into dist, where the test suite catches it.
substitute_harness_blocks() {
    local line key replacement
    local dropping=0

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '<!-- harness-block: '*' -->')
                key="${line#'<!-- harness-block: '}"
                key="${key%' -->'}"
                if [ -n "${CODEX_SKILL_HARNESS_BLOCKS[$key]+registered}" ]; then
                    replacement="${CODEX_SKILL_HARNESS_BLOCKS[$key]}"
                    if [ -n "$replacement" ]; then
                        printf '%s\n' "$replacement"
                    fi
                    dropping=1
                else
                    dropping=0
                fi
                continue
                ;;
            '<!-- /harness-block -->')
                dropping=0
                continue
                ;;
        esac

        if [ "$dropping" -eq 1 ]; then
            continue
        fi

        printf '%s\n' "$line"
    done
}

# The Codex adapter for a skill-directory file (ADR 0011). Reads a body on stdin, writes it on
# stdout. The shared pass runs over the Claude prose first, so the registered Codex text ships
# exactly as authored. The command lane's `/_my_x` slash-command rule is deliberately absent: it
# fires inside the real path at _my_mental_model/SKILL.md and corrupts it (D8).
sanitize_skill_body_for_codex() {
    apply_common_substitutions | substitute_harness_blocks
}

# Rewrite one markdown file of an already-copied skill tree through the adapter, in place.
adapt_skill_file_in_place() {
    local file="$1"
    local staged="$file.codex-adapt"

    sanitize_skill_body_for_codex < "$file" > "$staged"
    mv "$staged" "$file"
}

sanitize_rule_body_for_codex() {
    local file="$1"
    export COMMAND_SKILL_PREFIX

    strip_frontmatter "$file" | apply_common_substitutions | perl -0pe '
        s{~/.claude/commands/_my_pipeline\.md}{\$HOME/.agents/skills/my-pipeline/SKILL.md}g;
        s{/_my_\*}{\$my-*}g;
        s{/_my_([a-z_]+)}{
            my $n = $1;
            $n =~ tr/_/-/;
            "\$" . ($ENV{COMMAND_SKILL_PREFIX} // "") . $n;
        }ge;
        s{\*\*Check auto-memory\*\* \(already loaded\) for known gotchas before making assumptions}{**Check saved project context** for known gotchas before making assumptions}g;
        s{Check auto-memory \(already loaded\) for known gotchas before making assumptions}{Check saved project context for known gotchas before making assumptions}g;
        s{This file contains example rules and guidelines that Claude will follow during the conversation\.}{This file contains example rules and guidelines that Codex will follow during the conversation.}g;
        s{\*\*Note:\*\* The `\.claude/rules/` directory supports symlinks, making it easy to share common rules across projects\.}{**Note:** Codex global instructions are generated from `claude-pack/rules/`; edit the source rules and rebuild.}g;
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
mkdir -p "$DIST_DIR/agents" "$DIST_DIR/skills" "$DIST_DIR/hooks" "$DIST_DIR/scripts"

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
    replacement_file="$OVERRIDES_DIR/command-skill-replacements/$semantic_name/SKILL.md"
    if [ ! -f "$wrapper_file" ]; then
        wrapper_file="$OVERRIDES_DIR/prompt-prefixes/$semantic_name.md"
    fi

    mkdir -p "$skill_dir"
    if [ -f "$replacement_file" ]; then
        cp "$replacement_file" "$output_file"
        included_replacements+=("$skill_name")
    else
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
    fi

    if contains "$semantic_name" "${EXPLICIT_ONLY_COMMAND_SKILLS[@]}"; then
        mkdir -p "$skill_dir/agents"
        {
            printf "policy:\n"
            printf "  allow_implicit_invocation: false\n"
        } > "$skill_dir/agents/openai.yaml"
    fi

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

# Directory skills (skills/<name>/SKILL.md) — the native Claude Code form and the only skill
# shape either runtime registers. The directory is the unit: copy the whole tree, then run the
# Codex adapter over every markdown file that landed, then regenerate the entry point's
# frontmatter (D1). The Codex name is a pure function of the pack directory name (D2), because
# Claude keys a skill's identity on its directory while Codex registers the frontmatter name.
while IFS= read -r skill_src; do
    base="$(basename "$skill_src")"
    source_entry_point="$skill_src/SKILL.md"
    [ -f "$source_entry_point" ] || continue

    if [ "${#NATIVE_SKILL_ALLOWLIST[@]}" -gt 0 ] && ! contains "$base" "${NATIVE_SKILL_ALLOWLIST[@]}"; then
        excluded_native_skills+=("$base")
        continue
    fi

    skill_name="$(codex_name_for_skill_dir "$base")"
    description="$(description_for_native_skill "$skill_name" "$source_entry_point")"
    skill_dir="$DIST_DIR/skills/$skill_name"
    output_file="$skill_dir/SKILL.md"

    cp -R "$skill_src" "$skill_dir"

    # Markdown goes through the adapter; every other file stays byte-for-byte as copied.
    mapfile -t skill_md_files < <(find "$skill_dir" -type f -name '*.md' | sort)
    for skill_md in "${skill_md_files[@]}"; do
        adapt_skill_file_in_place "$skill_md"
    done

    staged_entry_point="$output_file.codex-frontmatter"
    {
        printf -- "---\n"
        printf "name: %s\n" "$skill_name"
        printf "description: %s\n" "$description"
        printf -- "---\n\n"
        printf "Generated from \`claude-pack/skills/%s/SKILL.md\`. Rebuild this file instead of editing it by hand.\n\n" "$base"
        strip_frontmatter "$output_file"
        printf "\n"
    } > "$staged_entry_point"
    mv "$staged_entry_point" "$output_file"

    included_native_skills+=("$skill_name")
done < <(find "$CLAUDE_PACK/skills" -mindepth 1 -maxdepth 1 -type d | sort)

{
    printf "# AGENTS.md\n\n"
    printf "Generated from \`claude-pack/rules/\` and \`codex-overrides/rules/\`. Rebuild this file instead of editing it by hand.\n\n"
    while IFS= read -r file; do
        printf "## From \`%s\`\n\n" "$(basename "$file")"
        sanitize_rule_body_for_codex "$file"
        printf "\n\n"
    done < <(find "$CLAUDE_PACK/rules" -maxdepth 1 -type f -name '*.md' | sort)
    if [ -d "$OVERRIDES_DIR/rules" ]; then
        while IFS= read -r file; do
            printf "## From \`codex-overrides/rules/%s\`\n\n" "$(basename "$file")"
            strip_frontmatter "$file"
            printf "\n\n"
        done < <(find "$OVERRIDES_DIR/rules" -maxdepth 1 -type f -name '*.md' | sort)
    fi
} > "$DIST_DIR/AGENTS.md"

if [ -d "$OVERRIDES_DIR/scripts" ]; then
    while IFS= read -r file; do
        base="$(basename "$file")"
        cp -p "$file" "$DIST_DIR/scripts/$base"
        included_scripts+=("$base")
    done < <(find "$OVERRIDES_DIR/scripts" -maxdepth 1 -type f | sort)
fi

# Shared subagent specs (product-lens, mental-model builder): referenced on demand by the
# skills at $HOME/.codex/scripts/<name>.md (see the path rewrites in
# sanitize_command_body_for_skill). Copied from the single source in claude-pack/scripts so
# the Codex layer cannot drift from it.
for shared_spec in product-lens.md; do
    if [ -f "$CLAUDE_PACK/scripts/$shared_spec" ]; then
        cp -p "$CLAUDE_PACK/scripts/$shared_spec" "$DIST_DIR/scripts/$shared_spec"
        included_scripts+=("$shared_spec")
    fi
done

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
    printf ",\n"
    printf "    \"scripts\": "
    write_json_array included_scripts
    printf ",\n"
    printf "    \"command_skill_replacements\": "
    write_json_array included_replacements
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
echo "Scripts:        ${#included_scripts[@]} included"
echo "Replacements:   ${#included_replacements[@]} included"
echo ""
echo "NOTE: dist/ is built but not installed. Skills install as copies: Codex silently refuses"
echo "a skill whose SKILL.md is a symlink, though it does load a symlinked skill directory."
echo "Run ./scripts/setup-codex.sh to refresh \$HOME/.codex and \$HOME/.agents."
