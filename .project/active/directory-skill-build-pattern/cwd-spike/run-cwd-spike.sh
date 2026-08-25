#!/usr/bin/env bash
set -euo pipefail

repository_root=$(git rev-parse --show-toplevel)
spike_directory="$repository_root/.project/active/directory-skill-build-pattern/cwd-spike"
skill_source="$spike_directory/.agents/skills/codex-cwd-probe"
discovery_directory="$repository_root/.agents/skills"
discovery_link="$discovery_directory/codex-cwd-probe"
evidence_directory="$spike_directory/evidence"
nested_launch_directory="$spike_directory/nested-launch"
relative_write_name="codex-cwd-relative-write.txt"

cleanup_discovery_link() {
    if test -L "$discovery_link"; then
        unlink "$discovery_link"
    fi
}

trap cleanup_discovery_link EXIT

mkdir -p "$discovery_directory" "$evidence_directory" "$nested_launch_directory"

if test -e "$discovery_link" || test -L "$discovery_link"; then
    printf 'Refusing to replace existing discovery path: %s\n' "$discovery_link" >&2
    exit 1
fi

ln -s "$skill_source" "$discovery_link"

run_probe() {
    local run_name=$1
    local launch_directory=$2
    local expected_write="$launch_directory/$relative_write_name"

    if test -e "$expected_write"; then
        printf 'Refusing to overwrite existing probe output: %s\n' "$expected_write" >&2
        exit 1
    fi

    codex exec \
        --ephemeral \
        --json \
        --sandbox workspace-write \
        -C "$launch_directory" \
        -o "$evidence_directory/$run_name.final.txt" \
        '$codex-cwd-probe Run the probe exactly. Do not do any unrelated work.' \
        > "$evidence_directory/$run_name.jsonl" \
        2> "$evidence_directory/$run_name.stderr"

    if test -f "$expected_write"; then
        printf 'EXPECTED_WRITE=%s\n' "$expected_write" > "$evidence_directory/$run_name.locations.txt"
        sed -n '1,20p' "$expected_write" > "$evidence_directory/$run_name.relative-write.txt"
    else
        printf 'EXPECTED_WRITE_MISSING=%s\n' "$expected_write" > "$evidence_directory/$run_name.locations.txt"
    fi

    find "$repository_root" -name "$relative_write_name" -print \
        | sort >> "$evidence_directory/$run_name.locations.txt"

    unlink "$expected_write"
}

run_probe root-launch "$repository_root"
run_probe nested-launch "$nested_launch_directory"

if test -e "$skill_source/$relative_write_name"; then
    printf 'UNEXPECTED_SKILL_DIRECTORY_WRITE=%s\n' "$skill_source/$relative_write_name" \
        > "$evidence_directory/skill-directory-check.txt"
else
    printf 'SKILL_DIRECTORY_WRITE=absent\n' > "$evidence_directory/skill-directory-check.txt"
fi

printf 'DISCOVERY_LINK_REMOVED_BY_EXIT_TRAP=%s\n' "$discovery_link" \
    > "$evidence_directory/cleanup.txt"
