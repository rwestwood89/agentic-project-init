---
id: 0012
title: Mental-model guidance separates generalized rules from feedback examples
date: 2026-09-02
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [claude-pack/skills/_my_mental_model, project-pack .project/mental-alignment feedback tiers]
supersedes: null
promoted_to: null
---

## Decision

Generalized rules belong in the mental-model prompts, which must work on their own. Feedback contains attributed examples and conditional techniques that support independent critique without becoming another rule set.

## Why

The owner distinguished the core prompt rules from feedback that can be conditional and example-specific. Keeping that boundary lets the prompt remain sufficient while feedback sharpens judgment without hardening every observed failure into a universal rule.

## Invariants established

- A rule in a prompt stands without an example.
- Feedback remains attributed to the run and artifact it reviewed.
