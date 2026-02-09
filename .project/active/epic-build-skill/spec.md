# Spec: Epic Build Skill

**Status:** Draft
**Created:** 2026-01-26
**Complexity:** MEDIUM

---

## Business Goals

### Why This Matters

Agents currently fail to follow established epic methodology when asked to "start an epic" mid-conversation. They either:
- Don't read the relevant docs (EPIC_GUIDE.md, README.md), producing inconsistent output
- Or use `/project-manage` which is so comprehensive it wipes valuable conversation context

Users need a way to invoke epic-building that is **lightweight enough to preserve context** while still **routing agents to the right instructions**.

### Success Criteria

- [ ] Agent can be invoked mid-conversation to capture an epic without losing context
- [ ] Agent reads appropriate instructions for the current phase (not everything)
- [ ] Output follows established methodology consistently
- [ ] `/project-manage` is simplified to operational tasks only

### Priority

Foundational workflow improvement - affects daily use of the project management system.

---

## Problem Statement

### Current State

1. **No lightweight entry point**: Saying "start an epic" relies on agent memory/training, which is inconsistent
2. **`/project-manage decompose`** exists but:
   - Is bundled with unrelated operational modes (status, close, backlog)
   - Loads ~500 lines of instructions, wiping conversation context
   - Doesn't support the earlier phases (sketch, define)
3. **Instruction files are monolithic**: EPIC_GUIDE.md covers everything; no way to load just what's needed for one phase

### Desired Outcome

A new `/epic-build` skill that:
- Acts as a **lightweight router** (~40-50 lines)
- Points agents to **separate instruction files** based on phase
- Supports three phases: sketch → define → decompose
- Auto-detects the appropriate phase with user confirmation

---

## Scope

### In Scope

1. **New skill**: `/epic-build` in `claude-pack/commands/`
2. **New instruction files** in `project-pack/`:
   - `guides/epic-sketch.md` - Instructions for quick capture
   - `guides/epic-define.md` - Instructions for filling in essentials
   - `guides/epic-decompose.md` - Instructions for breaking into items
3. **Refactored `/project-manage`**: Remove `decompose` mode
4. **Mode detection logic**: Auto-detect phase based on epic state, confirm with user

### Out of Scope

- Changes to core EPIC_GUIDE.md methodology (content stays the same, just reorganized)
- Changes to epic_template.md structure
- Changes to spec/design/plan/implement workflow for items
- Changes to BACKLOG.md format

### Edge Cases & Considerations

- User invokes `/epic-build` with no context and no epic specified
- Epic exists but is in ambiguous state (partially defined)
- User wants to skip phases (e.g., go straight to decompose on a new epic)

---

## Requirements

### Functional Requirements

#### FR-1: Skill as Router Pattern

The `/epic-build` skill file MUST be lightweight (~40-50 lines) and MUST NOT contain full instructions inline. It MUST:
- Describe available modes
- Specify which instruction file to read for each mode
- Provide mode detection guidance

#### FR-2: Three Distinct Modes

The skill MUST support three modes:

| Mode | Purpose | Instruction File |
|------|---------|------------------|
| `sketch` | Quick capture from conversation context | `project-pack/guides/epic-sketch.md` |
| `define` | Fill in template essentials | `project-pack/guides/epic-define.md` |
| `decompose` | Break into backlog items | `project-pack/guides/epic-decompose.md` |

#### FR-3: Mode Auto-Detection with Confirmation

When invoked without explicit mode, the skill MUST:
1. Check if an epic name was provided
2. If epic exists, assess its state (empty, partial, ready for decomposition)
3. If no epic, check conversation context for epic-like discussion
4. Propose a mode based on assessment
5. Confirm with user before proceeding

#### FR-4: Sketch Mode Behavior

The `epic-sketch.md` instructions MUST:
- Emphasize preserving conversation context (DO NOT read extensive docs)
- Use existing `epic_template.md` structure
- Capture only: Executive Summary, rough Success Criteria, Why This Epic
- Leave Backlog Items section empty/minimal
- Add entry to BACKLOG.md
- Be short (~50-80 lines)

#### FR-5: Define Mode Behavior

The `epic-define.md` instructions MUST:
- Read the existing epic file
- Reference only the "Initialization" section concepts from EPIC_GUIDE
- Interactively complete: Executive Summary, Success Criteria, Why This Epic
- NOT touch Backlog Items section
- Be moderate length (~80-120 lines)

#### FR-6: Decompose Mode Behavior

The `epic-decompose.md` instructions MUST:
- Contain the full decomposition methodology (moved from `/project-manage`)
- Include the mandatory Stage 5 PAUSE for feedback
- Reference EPIC_GUIDE for Goldilocks sizing, anti-patterns, etc.
- Be the heaviest of the three (~150-200 lines)

#### FR-7: Refactored /project-manage

The `/project-manage` command MUST:
- Remove `decompose` mode entirely
- Keep only: `status` (default), `close`, `backlog`
- Update documentation to point to `/epic-build decompose` for decomposition

---

## Acceptance Criteria

### Core Functionality

- [ ] `/epic-build sketch` creates a minimal epic from conversation context without reading EPIC_GUIDE.md
- [ ] `/epic-build define` fills in essentials on an existing epic interactively
- [ ] `/epic-build decompose` follows full methodology with mandatory pause
- [ ] `/epic-build` (no args) auto-detects mode and confirms with user
- [ ] `/project-manage decompose` no longer exists
- [ ] `/project-manage` still works for status, close, backlog

### Quality & Integration

- [ ] Skill file is under 60 lines
- [ ] Each instruction file is appropriately sized for its phase
- [ ] Existing epic_template.md is used (not duplicated)
- [ ] Mode detection handles edge cases gracefully

---

## Open Questions

1. **EPIC_GUIDE.md fate**: Should the original file be kept as-is (human reference) with guides/ being agent-focused extracts? Or should EPIC_GUIDE.md be deprecated in favor of the split files?

2. **Guides location**: `project-pack/guides/` is proposed. Alternative: `project-pack/instructions/` or just top-level in `project-pack/`. Preference?

3. **Cross-references**: Should instruction files reference each other (e.g., sketch says "when done, use define mode") or keep them independent?

---

## Related Artifacts

- **Current methodology**: `project-pack/EPIC_GUIDE.md`
- **Current command**: `claude-pack/commands/_my_project_manage.md`
- **Template**: `project-pack/epic_template.md`
- **Design**: `.project/active/epic-build-skill/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`
