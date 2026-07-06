#!/usr/bin/env python3
"""Spike probe: does a SKILL.md description starting with `*` break strict YAML?

Reproduces the exact frontmatter shape emitted by build-codex-pack.sh:250
    printf "description: %s\n" "$description"

Run: python3 probe_yaml_description.py
"""
import yaml

# The build emits: ---\nname: ...\ndescription: <raw string>\n---
def skill_frontmatter(description: str) -> str:
    return f"---\nname: my-spike\ndescription: {description}\n---\n"

cases = {
    "plain prose":        "De-risk a known assumption. Use when uncertain.",
    "leading single *":   "*Purpose* de-risk a known assumption.",
    "leading double **":  "**Purpose:** de-risk a known assumption.",
    "leading &":          "&anchor de-risk a known assumption.",
    "colon inside":       "De-risk: confirm an assumption.",
}

for label, desc in cases.items():
    doc = skill_frontmatter(desc)
    # frontmatter is the block between the --- fences; parse it as YAML
    fm = doc.split("---")[1]
    try:
        parsed = yaml.safe_load(fm)
        got = parsed.get("description")
        print(f"[ OK ] {label:18} -> description={got!r}")
    except yaml.YAMLError as e:
        first = str(e).splitlines()[0]
        print(f"[FAIL] {label:18} -> {type(e).__name__}: {first}")
