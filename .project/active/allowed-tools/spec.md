# Spec: Tiered Auto-Approve with Allowed Tools Management

**Status:** Draft
**Owner:** Reid Westwood
**Created:** 2026-02-08 20:59:42 UTC
**Complexity:** HIGH
**Branch:** allowed-tools

---

## Business Goals

### Why This Matters

Running Claude Code in a more autonomous mode requires a safety net smarter than binary allow/deny. The current `auto-approve.sh` hook (built for `~/1cfe/`) is a solid foundation — it handles known-safe tools instantly and blocks dangerous operations — but it has two limitations:

1. **Hardcoded paths**: Allowed folders are baked into the script (`~/1cfe/`, `~/agentic-project-init/`), requiring manual edits for each new project.
2. **No middle ground**: Unknown tool uses fall through to the default Claude Code permission prompt. There's no intelligent review layer that could catch subtle issues or guide Claude to rephrase risky commands without interrupting the user.

This feature generalizes the auto-approve hook into a distributable, configurable, three-tier review system that ships with the agentic-project-init pack.

### Success Criteria

- [ ] Users install the pack and get a sensible auto-approve baseline out of the box
- [ ] Users can scope the system to their own project folders without editing bash
- [ ] Unknown/uncertain tool uses get a lightweight AI review before bothering the user
- [ ] AI review can "push back" on Claude (deny with reason → Claude self-corrects) without user involvement
- [ ] Users can teach the system to trust new tools/patterns via `/_my_allow_tool`
- [ ] The system integrates cleanly with the existing `setup-global.sh` installation flow

### Priority

High — core enabler for autonomous/semi-autonomous Claude Code usage.

---

## Problem Statement

### Current State

A working `auto-approve.sh` hook exists at `~/.claude/hooks/auto-approve.sh` with:
- Helper functions: `allow()`, `deny()`, `ask_user()`, `fall_through()`
- Path validation: `is_allowed_path()` with hardcoded allowed directories
- Bash command classification: `classify_segment()` with safe/dangerous command lists
- File tool handling: auto-approves Read/Write/Edit/Glob/Grep within allowed paths
- Git awareness: read-only git ops auto-approved, write ops deferred to user
- Audit logging to `/tmp/claude-hook-audit.log`

**Problems:**
1. Allowed paths hardcoded in `is_allowed_path()` — requires editing bash to add projects
2. Allowed commands hardcoded in `classify_segment()` — no easy way to extend
3. When a tool use is unknown, it falls through silently — no intelligent review
4. Not distributable — lives in `~/.claude/hooks/` outside the pack

### Desired Outcome

A three-tier review system distributed via `claude-pack/hooks/`:
1. **Tier 1 (Auto-approve)**: Fast bash pattern matching — the current logic, but reading allowed paths/tools from a config file
2. **Tier 2 (Headless Claude review)**: For uncertain cases, spawn a headless `claude -p --model haiku` to review the tool use and return a structured verdict: APPROVE, PUSH_BACK (deny with reason → Claude adjusts), or ELEVATE
3. **Tier 3 (User escalation)**: Ask the user, either directly from Tier 1 (known-risky like git push) or escalated from Tier 2

Plus a `/_my_allow_tool` command that knows how to update the config to add new auto-approved patterns.

---

## Scope

### In Scope

1. **Generalized auto-approve hook script** in `claude-pack/hooks/`
   - Reads allowed paths and tool patterns from a config file
   - Implements the three-tier decision pipeline within a single script
   - Uses the existing `auto-approve.sh` logic as the default baseline
2. **Config file** for allowed paths and tool patterns
   - Read by the hook at runtime
   - Editable by `/_my_allow_tool` command
   - Installed to `~/.claude/hooks/` alongside the hook script
3. **Review prompt file** for the headless Claude tier
   - Static prompt shipped with the pack in `claude-pack/hooks/`
   - Installed via symlink, so users can find and customize it post-install
4. **`/_my_allow_tool` command** in `claude-pack/commands/`
   - Knows the config file format and location
   - Can add allowed paths, allowed bash commands, and allowed tool patterns
5. **Integration with `setup-global.sh`**
   - Installs the hook, config, and review prompt via existing symlink mechanism
   - Configures `settings.json` with PreToolUse hook entries
6. **JSON schema** for the headless Claude structured output
   - Shipped as a file in `claude-pack/hooks/` for maintainability

### Out of Scope

- Per-project override configurations (global config only for now)
- GUI/TUI for managing allowed tools
- Windows support
- Changes to the PreCompact hook or transcript capture system
- A daemon or long-running review process (each review is a one-shot CLI call)
- Training or fine-tuning the review model

### Edge Cases & Considerations

- **Claude CLI unavailable**: Tier 2 must gracefully degrade (escalate to Tier 3)
- **Tier 2 timeout**: Headless Claude call takes too long — must have a bash-level timeout and escalate
- **Tier 2 cost**: Each review costs ~$0.005-0.015 with Haiku; high-frequency tool use could add up
- **Concurrent hooks**: All matching hooks run in parallel — the three tiers MUST be in a single script, not separate hook entries
- **Config file missing**: Hook should fall back to hardcoded defaults (the current baseline) if config is absent
- **Empty/malformed config**: Hook should handle gracefully and not break the permission system
- **Hook timeout**: The hook config has a `timeout` field (default 600s for command hooks); Tier 2 adds latency (~3-5s per Haiku call)

---

## Requirements

### Functional Requirements

> Requirements below are from user's request unless marked [INFERRED] or [FROM INVESTIGATION]

#### FR-1: Config File for Allowed Paths and Tools

1. **FR-1.1**: A JSON config file MUST exist at `~/.claude/hooks/allowed-tools.json` that the hook script reads at runtime via `jq`
2. **FR-1.2**: The config file MUST support specifying allowed directory paths (replacing the hardcoded `is_allowed_path()` list)
3. **FR-1.3**: The config file MUST support specifying allowed bash commands/patterns (extending `classify_segment()`)
4. **FR-1.4**: The config file MUST ship with sensible defaults derived from the current `auto-approve.sh` baseline
5. **FR-1.5**: The config file MUST include a boolean toggle to enable/disable Tier 2 (headless Claude review). When disabled, Tier 1 "unknown" falls through directly to Tier 3 (user prompt)
6. **FR-1.6**: [INFERRED] The hook MUST fall back to built-in defaults if the config file is missing or unreadable

#### FR-2: Three-Tier Review Pipeline

1. **FR-2.1**: The hook MUST implement all three tiers within a single PreToolUse hook script (hooks run in parallel, not chained)
2. **FR-2.2**: **Tier 1 (Auto-approve)** MUST use fast bash pattern matching with no external calls — the current `auto-approve.sh` logic generalized to read from config
3. **FR-2.3**: **Tier 2 (Headless Claude review)** MUST be invoked only when Tier 1 returns "unknown" (not clearly safe, not clearly dangerous)
4. **FR-2.4**: **Tier 3 (User escalation)** MUST be the fallback when Tier 2 returns ELEVATE, when Tier 2 fails/times out, or when Tier 1 explicitly defers (e.g., git write ops)
5. **FR-2.5**: The pipeline MUST short-circuit — if Tier 1 decides allow or deny, Tier 2 is never invoked

#### FR-3: Tier 2 — Headless Claude Review

1. **FR-3.1**: Tier 2 MUST invoke the Claude CLI in headless mode: `claude -p` with `--model haiku`
2. **FR-3.2**: Tier 2 MUST use `--json-schema` to enforce structured output with three possible decisions:
   - **APPROVE**: The operation is safe → hook returns `permissionDecision: "allow"`
   - **PUSH_BACK**: The operation is concerning → hook returns `permissionDecision: "deny"` with the reason (Claude sees the reason and self-corrects)
   - **ELEVATE**: The operation needs human review → hook returns `permissionDecision: "ask"`
3. **FR-3.3**: Tier 2 MUST use `--tools ""` to disable all built-in tools (text-only review, no file access)
4. **FR-3.4**: Tier 2 MUST use `--no-session-persistence` (ephemeral, no disk artifacts)
5. **FR-3.5**: Tier 2 MUST have a bash-level timeout (e.g., `timeout 30`) and escalate to Tier 3 on timeout
6. **FR-3.6**: Tier 2 MUST use `--max-turns 3` (minimum 2 required for `--json-schema` extraction)
7. **FR-3.7**: [INFERRED] Tier 2 SHOULD use `--max-budget-usd` to cap per-review cost
8. **FR-3.8**: Tier 2 MUST gracefully handle Claude CLI not being available (escalate to Tier 3)

#### FR-4: Review Prompt

1. **FR-4.1**: A static review prompt file MUST be shipped with the pack (e.g., `claude-pack/hooks/review-prompt.md`)
2. **FR-4.2**: The review prompt MUST instruct the reviewer model on the three-decision protocol (APPROVE, PUSH_BACK, ELEVATE) with clear criteria for each
3. **FR-4.3**: The review prompt MUST be installed via symlink so users can find and edit it post-installation
4. **FR-4.4**: [INFERRED] The hook script MUST read the prompt from the file at runtime (not embed it inline)

#### FR-5: `/_my_allow_tool` Command

1. **FR-5.1**: A new command `/_my_allow_tool` MUST be created in `claude-pack/commands/`
2. **FR-5.2**: The command MUST know the config file location and format
3. **FR-5.3**: The command MUST support adding a new allowed directory path (scoped folder)
4. **FR-5.4**: The command MUST support adding a new allowed bash command/pattern
5. **FR-5.5**: [INFERRED] The command SHOULD validate inputs before writing to the config file
6. **FR-5.6**: [INFERRED] The command SHOULD show the user what was added and confirm the change

#### FR-6: Integration with setup-global.sh

1. **FR-6.1**: [INFERRED] `setup-global.sh` MUST install the auto-approve hook script, config file, review prompt, and JSON schema via the existing symlink mechanism
2. **FR-6.2**: [INFERRED] `setup-global.sh` MUST add PreToolUse hook entries to `~/.claude/settings.json` alongside the existing PreCompact entries
3. **FR-6.3**: [INFERRED] The settings.json configuration MUST include matchers for both file tools (`Read|Write|Edit|Glob|Grep`) and `Bash`, consistent with the current `~/.claude/settings.json` pattern

#### FR-7: Hook Output Protocol

1. **FR-7.1**: [FROM INVESTIGATION] Auto-approve MUST return `{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow" } }`
2. **FR-7.2**: [FROM INVESTIGATION] Push-back MUST return `permissionDecision: "deny"` with `permissionDecisionReason` containing the Tier 2 reason — this is fed back to Claude, which self-corrects
3. **FR-7.3**: [FROM INVESTIGATION] Escalation MUST return `permissionDecision: "ask"` with `permissionDecisionReason` shown to the user explaining why escalation occurred
4. **FR-7.4**: [FROM INVESTIGATION] Hard deny MUST return `permissionDecision: "deny"` with reason — Claude sees it and adjusts
5. **FR-7.5**: [FROM INVESTIGATION] Fall-through (exit 0, no output) MUST be used only when the hook genuinely has no opinion

### Non-Functional Requirements

1. **NFR-1**: Tier 1 MUST complete in <100ms (no external calls, pure bash)
2. **NFR-2**: Tier 2 SHOULD complete in <10s including Claude CLI invocation
3. **NFR-3**: The hook script MUST be POSIX-compatible bash
4. **NFR-4**: [INFERRED] The audit log (`/tmp/claude-hook-audit.log`) pattern SHOULD be preserved for debugging
5. **NFR-5**: [INFERRED] The hook MUST require `jq` (already a dependency of `setup-global.sh`) and fail with a clear error message if unavailable

---

## Acceptance Criteria

### Core Functionality

- [ ] Hook script reads allowed paths from config file (not hardcoded)
- [ ] Hook script reads allowed tool patterns from config file
- [ ] Tier 1 auto-approves known-safe operations (file tools in allowed paths, safe bash commands)
- [ ] Tier 1 denies known-dangerous operations with reason (Claude sees reason)
- [ ] Tier 2 spawns headless Claude with Haiku for uncertain cases
- [ ] Tier 2 returns structured APPROVE/PUSH_BACK/ELEVATE via `--json-schema`
- [ ] PUSH_BACK maps to `deny` + reason (Claude self-corrects without user involvement)
- [ ] ELEVATE maps to `ask` (user sees escalation reason)
- [ ] Tier 2 gracefully degrades when Claude CLI unavailable (escalates to Tier 3)
- [ ] Tier 2 respects timeout and escalates on timeout
- [ ] `/_my_allow_tool` can add a scoped folder to the config
- [ ] `/_my_allow_tool` can add an allowed bash command to the config
- [ ] Config ships with sensible defaults from current `auto-approve.sh`

### Integration

- [ ] `setup-global.sh` installs hook, config, prompt, and schema
- [ ] `setup-global.sh` configures PreToolUse entries in `settings.json`
- [ ] Hook works correctly when invoked via `~/.claude/settings.json` PreToolUse config
- [ ] Existing PreCompact hook continues to work unchanged
- [ ] `uninstall-global.sh` removes the new hook artifacts

### Quality

- [ ] Tier 1 completes in <100ms
- [ ] Hook handles missing config file gracefully (falls back to defaults)
- [ ] Hook handles malformed config file gracefully
- [ ] Audit log captures all tier decisions for debugging
- [ ] Review prompt is readable and editable by users post-install

---

## Related Artifacts

- **Existing hook**: `~/.claude/hooks/auto-approve.sh` (current implementation, reference baseline)
- **Existing settings**: `~/.claude/settings.json` (current PreToolUse + PreCompact config)
- **Setup script**: `scripts/setup-global.sh` (installation mechanism)
- **Design**: `.project/active/allowed-tools/design.md` (to be created)

---

## Open Questions (Resolved)

| Question | Resolution |
|----------|------------|
| Config file format? | JSON — requires `jq` dependency (already required by setup-global.sh) |
| Tier 2 cost controls? | No cap — per-review `--max-budget-usd` only, no daily/session budget |
| Tier 2 on/off toggle? | Yes — include a toggle in the config file to disable Tier 2 (unknown falls through directly to Tier 3 user prompt) |
| Config file location? | `~/.claude/hooks/allowed-tools.json` — within `hooks/` alongside the hook script |

---

**Next Steps:** After approval, proceed to `/_my_design`
