# Spec: Simplify auto-approve.sh Decision Pipeline

**Status:** Draft
**Owner:** Reid Westwood
**Created:** 2026-02-09 16:55 UTC
**Complexity:** MEDIUM
**Branch:** allowed-tools

---

## Business Goals

### Why This Matters
The auto-approve hook runs on every tool call in every Claude Code session. The current logic is incomprehensible to the maintainer — 4 outcome functions, 4 segment classification values, 2 tier2 routing functions, and bypass paths that skip the subagent. This has caused real bugs: `rm -rf` was silently auto-denied (user never saw it), `invoke_tier2` was defined after its callers so it never ran for Bash/file tools, and the git write ops bypass meant the subagent never reviewed those at all.

### Success Criteria
- [ ] Any developer can read the script and immediately trace any tool call to one of exactly 3 outcomes
- [ ] No auto-deny exists anywhere — the hook never silently blocks operations
- [ ] The subagent's PUSH_BACK cannot cause infinite retry loops
- [ ] All existing safe-list approvals continue to work (no regressions)

### Priority
High — actively causing problems in real sessions.

---

## Problem Statement

### Current State
The hook has 4 outcome functions (`allow`, `deny`, `ask_user`, `fall_through`), a segment classifier returning 4 values (`allow`, `deny`, `ask`, `unknown`), two tier2 routing functions (`tier2_or_escalate`, `tier2_or_fallthrough`), and multiple bypass paths where operations skip the subagent entirely. The maintainer cannot follow the logic after reading it twice.

### Desired Outcome
A clean 3-tier pipeline where every tool call follows one path:

```
Tool call
  ├── Tier 1: Auto-approve (known safe) ──────────────────→ ALLOW
  ├── Tier 1: Auto-elevate (known needs-human) ──────────→ ASK USER
  └── Tier 2: Subagent review (everything else)
        ├── APPROVE ──────────────────────────────────────→ ALLOW
        ├── PUSH_BACK (first time only) ─────────────────→ DENY w/ reason
        └── ELEVATE ─────────────────────────────────────→ ASK USER
```

---

## Scope

### In Scope
- Restructure `auto-approve.sh` decision pipeline to 3 outcomes
- Simplify `classify_segment` to return binary: `safe` / `review`
- Merge the two tier2 routing functions into one
- Add same-request-twice detection to prevent PUSH_BACK loops
- Remove `fall_through` — we always have an opinion
- Remove `deny` as a Tier 1 outcome — only the subagent can push back
- Move git write ops from "ask bypass" to "auto-elevate" tier
- Update review-prompt.md and review-schema.json if the subagent contract changes

### Out of Scope
- Changing which commands/paths are in the safe lists (Tier 1 content)
- Changing the Haiku call mechanics (timeout, model, budget)
- Changing the config format (allowed-tools.json)
- Changing the input parsing (Section 5)

### Edge Cases & Considerations
- Tier 2 disabled or `claude` CLI not available: everything non-auto-approved MUST escalate to user
- Tier 2 timeout: MUST escalate to user (not silently fail)
- Same request after PUSH_BACK: MUST strip PUSH_BACK option from subagent, forcing APPROVE or ELEVATE

---

## Requirements

### Functional Requirements

> Requirements below are from user's request unless marked [INFERRED] or [FROM INVESTIGATION]

1. **FR-1**: The hook MUST have exactly 3 possible outcomes for any tool call: auto-approve, auto-elevate, or send to subagent
2. **FR-2**: The hook MUST NOT auto-deny any operation. There SHALL be no path where the hook silently blocks a tool call without user visibility
3. **FR-3**: The Tier 1 classifier MUST return binary results: `safe` (auto-approve) or `needs_review`. A third value `elevate` MAY exist for known needs-human operations (git write ops)
4. **FR-4**: There MUST be exactly one function that sends work to the subagent, not two
5. **FR-5**: When the subagent returns PUSH_BACK, the hook MUST record a hash of the request
6. **FR-6**: When a subsequent request matches a stored PUSH_BACK hash, the subagent MUST be told to choose only APPROVE or ELEVATE — PUSH_BACK SHALL NOT be an option on retry
7. **FR-7**: When Tier 2 is disabled or `claude` CLI is unavailable, everything not auto-approved MUST escalate to the user
8. **FR-8**: When Tier 2 times out, the request MUST escalate to the user
9. **FR-9**: Git write operations (commit, push, add, rebase, etc.) SHOULD be auto-elevated to the user without going through the subagent
10. **FR-10**: [INFERRED] The `deny()` output function is still needed for subagent PUSH_BACK responses (it's the hook protocol's way of telling Claude "try differently") but MUST only be reachable via the subagent, never from Tier 1 pattern matching
11. **FR-11**: [INFERRED] The `fall_through()` function MUST be removed — the hook always has an opinion

### Non-Functional Requirements

- The script MUST remain readable by a developer who hasn't seen it before
- Decision flow MUST be traceable: given any tool call, a reader can follow one linear path to the outcome
- The PUSH_BACK hash mechanism MUST be lightweight (no persistent state beyond `/tmp`)

---

## Acceptance Criteria

### Core Functionality
- [ ] `classify_segment` returns only `safe` or `review` (or `elevate` for git write ops)
- [ ] No code path from Tier 1 reaches `deny()`
- [ ] Only one tier2 routing function exists
- [ ] `fall_through()` is removed
- [ ] Same-request PUSH_BACK detection works: first PUSH_BACK stores hash, second request with same hash strips PUSH_BACK option
- [ ] Git write ops go directly to user prompt (auto-elevate)
- [ ] `rm -rf` on non-tmp paths goes to subagent (not auto-denied, not auto-elevated)

### Quality & Integration
- [ ] All existing safe-list commands still auto-approve (no regressions)
- [ ] Tier 2 disabled fallback works (everything escalates to user)
- [ ] Script is comprehensible on first read

---

## Related Artifacts

- **Source file:** `claude-pack/hooks/auto-approve.sh`
- **Review prompt:** `claude-pack/hooks/review-prompt.md`
- **Review schema:** `claude-pack/hooks/review-schema.json`
- **Config:** `claude-pack/hooks/allowed-tools.json` / `allowed-tools.default.json`

---

**Next Steps:** After approval, proceed to `/_my_design`
