# Epic: Workflow v2

**Epic ID**: WORKFLOW-V2
**Status**: In Progress
**Priority**: High
**Created**: 2026-06-30
**Estimated Effort**: 6-8 days

---

## Executive Summary

Implement the workflow v2 redesign: new commands, expanded commands, consolidated commands, renamed commands, and template changes that close the gaps identified in the pipeline audit. The target state is fully captured in the README_v2 artifact.

**Critical Success Factor**: An AI agent can operate the workflow across many work items and epics with no dropped requirements, no orphaned artifacts, and no stale tracking files.

---

## Source Documents

- **README_v2 artifact**: the authoritative target state (`https://claude.ai/code/artifact/9a7e2b06-4412-4e44-9c84-b3fc17b7544a`)
- **README_v2 source**: `/tmp/claude-1000/-home-rwestwood-agentic-project-init/f51d3828-b759-47fa-979a-e4070e1c1272/scratchpad/readme-v2.html`
- **Handoff**: `/tmp/handoff-20260630-165453.md`

---

## Why This Epic?

**Current State**:
- Concepts live in `concepts/` with no formal link to work items. Design intent gets lost crossing the shaping-to-scoping boundary.
- Audit is a read-only findings report. Spec and epic checkboxes never get marked off. There is no closure.
- `/_my_project_manage` is overloaded with modes (status, close, decompose, backlog). Users have to remember flags.
- `/_my_code_review` conflates spec/design conformance with code quality. These are different jobs at different points in the lifecycle.
- Sessions and work items are falsely coupled. Wrap-up is positioned as a lifecycle step when it is a session utility.

**Future State**:
- The epic bridges shaping and scoping with Source Documents and Required Reading. Every work-item command can trace back to the original concept.
- Audit certifies: it evaluates AND updates plan, spec, and epic checkboxes. Close archives. Each has one job.
- Each workflow action is a standalone command with no mode flags.
- Spec/design conformance lives in audit. Code quality lives in pre-PR. Clean separation.
- Sessions and work items are independent. Wrap-up is a session utility, not a lifecycle step.

---

## Success Criteria

- [ ] An agent following the workflow can take a concept through epic decomposition, spec, design, plan, implement, audit, and close without manual intervention on tracking files
- [ ] Every work-item command reads Required Reading from the epic when the item belongs to one
- [ ] Audit updates plan checkboxes, spec success criteria, and epic item status
- [ ] Close archives to `completed/` and updates BACKLOG.md, CURRENT_WORK.md, and CHANGELOG.md
- [ ] No command references a retired command name (`_my_audit_implementation`, `_my_project_manage`, `_my_code_review`, `_my_code_quality`, `_my_review_design`)
- [ ] Codex dist builds cleanly with the new command landscape

---

## Epic Strategy

**Value Delivery Path**:
- Templates first — they define the Required Reading format that downstream commands depend on
- New commands next — epic_plan, close, pre_pr, status, design_review rename
- Modified commands — spec, product-design, design get Required Reading; audit gets certification
- Cleanup last — retire old files, update cross-references, rebuild Codex dist

**Critical Path**:
- Item 1 (templates) → Item 2 (epic_plan) and Item 3 (pipeline Required Reading) depend on knowing the template format
- Item 9 (cleanup) depends on all other items being done

**Decomposition Logic**:
- Each item is one command or one coherent group of changes
- Items 4-8 are independent and can be done in any order
- Item 9 is a sweep that catches everything else

---

## Backlog Items

### Item 1: Epic Template Foundation ✅

**Type**: Implementation
**Effort**: 0.5 days (spec 0h — requirements are in the artifact, design 0h, plan 0h, execute 3-4h)
**Dependencies**: None

**Objective**: Add Source Documents and Required Reading to the epic template and update EPIC_GUIDE to explain the traceability mechanism.

**Why This Is One Work Item**:
- Both files define the same concept (how epics carry shaping-tier intent downstream)
- Changes to one require changes to the other

**In Scope (High Level)**:
- Add Source Documents section to `project-pack/epic_template.md` (top-level, lists concept/research files the epic was built from)
- Add Required Reading field to each backlog item in the template (lists files the work-item pipeline must read)
- Update `project-pack/EPIC_GUIDE.md` to explain Required Reading and source document traceability
- Update the `.project/epic_template.md` copy in the live project

**Non-Goals / Out of Scope**:
- Modifying existing epics in any project's backlog (that happens when epic_plan runs)
- Changing the BACKLOG.md template

**Success / Done State**:
- [x] Epic template has Source Documents and Required Reading sections
- [x] EPIC_GUIDE explains how Required Reading carries intent from shaping to scoping

**Location**: `.project/active/epic-template-foundation/`

---

### Item 2: `/_my_epic_plan` Command ✅

**Type**: Implementation
**Effort**: 1-1.5 days (spec 1h, design 1h, plan 0.5h, execute 4-6h)
**Dependencies**: Item 1

**Objective**: Write the bridge command that decomposes shaping output into a scoped epic with source document references and Required Reading per item.

**Why This Is One Work Item**:
- Single new command with clear inputs (concepts, research) and output (epic file + BACKLOG.md entry)
- Absorbs the decompose mode from `_my_project_manage`

**In Scope (High Level)**:
- New command file `claude-pack/commands/_my_epic_plan.md`
- Reads concept, concept-design, and research files as input
- Produces `backlog/epic_{name}.md` using the updated template (with Source Documents and Required Reading)
- Updates `backlog/BACKLOG.md` with a new entry
- Follows the EPIC_GUIDE decomposition methodology
- Add Codex skill description to `codex-overrides/config.sh`

**Non-Goals / Out of Scope**:
- Modifying existing epics (this creates new ones)
- Backlog reprioritization

**Success / Done State**:
- [x] Command exists and can be invoked with `/_my_epic_plan`
- [x] Produced epic has Source Documents and Required Reading sections populated
- [x] BACKLOG.md is updated with the new epic entry

**Location**: `.project/active/epic-plan-command/`

---

### Item 3: Pipeline Required Reading

**Type**: Implementation
**Effort**: 1 day (spec 0.5h, design 0.5h, plan 0.5h, execute 4-5h)
**Dependencies**: Item 1

**Objective**: Modify spec, product-design, and design commands to read Required Reading from the epic. Modify spec to update CURRENT_WORK.md when creating a new item.

**Why This Is One Work Item**:
- All three commands get the same type of change (read Required Reading)
- The CURRENT_WORK.md update in spec is closely related (it's the other half of "spec creates the item properly")

**In Scope (High Level)**:
- Modify `_my_spec.md`: read Required Reading from epic as primary input; update CURRENT_WORK.md when creating `active/{item}/`
- Modify `_my_product_design.md`: read Required Reading from epic as background context
- Modify `_my_design.md`: read Required Reading from epic as background context
- Each command must handle the case where the item has no epic (standalone items skip Required Reading)

**Non-Goals / Out of Scope**:
- Modifying plan or implement (they don't read the epic directly)
- Changing what these commands produce (only what they read)

**Success / Done State**:
- [ ] Spec, product-design, and design all read Required Reading when the item belongs to an epic
- [ ] Spec updates CURRENT_WORK.md when creating a new item folder
- [ ] Commands work correctly for items with no epic (standalone usage)

**Location**: `.project/active/pipeline-required-reading/`

---

### Item 4: `/_my_audit` Certification

**Type**: Implementation
**Effort**: 1-1.5 days (spec 1h, design 1h, plan 0.5h, execute 5-7h)
**Dependencies**: Soft dependency on Item 1 (audit certifies epic checkboxes, so it should understand the updated epic template format with Required Reading)

**Objective**: Expand `_my_audit_implementation` into `/_my_audit` — a certification step that evaluates code AND updates plan, spec, and epic checkboxes. Support both work-item and epic scope.

**Why This Is One Work Item**:
- Single command rewrite with expanded responsibilities
- Work-item scope and epic scope are two modes of the same evaluator

**Implementation note**: The command prompt should be succinct. Audit's scope is broad but the prompt itself should be tight — clear instructions, no bloat. A good command prompt is short enough to read in one pass.

**In Scope (High Level)**:
- Rename `_my_audit_implementation.md` → `_my_audit.md`
- Add certification behavior: update plan phase checkboxes, spec success criteria, epic item status
- Add epic scope: `/_my_audit {epic}` reviews all items and assesses against concept/concept-design source documents
- Write `audit.md` artifact in the work item directory
- Absorb spec/design conformance checking from `_my_code_review`
- Update CURRENT_WORK.md with certification status

**Non-Goals / Out of Scope**:
- Code quality checks (that's pre_pr's job)
- Archiving (that's close's job)

**Success / Done State**:
- [ ] `/_my_audit {item}` evaluates and updates plan/spec/epic checkboxes, writes audit.md
- [ ] `/_my_audit {epic}` reviews entire epic including against source documents
- [ ] Old `_my_audit_implementation.md` file retired

**Location**: `.project/active/audit-certification/`

---

### Item 5: `/_my_close` Command

**Type**: Implementation
**Effort**: 0.5-1 day (spec 0.5h, design 0.5h, plan 0.5h, execute 3-4h)
**Dependencies**: None

**Objective**: Write the archive command that moves completed work items or epics to `completed/` and updates all tracking files.

**Why This Is One Work Item**:
- Single new command with clear inputs (item or epic name) and outputs (archived files, updated tracking)
- Absorbs the close mode from `_my_project_manage`

**In Scope (High Level)**:
- New command file `claude-pack/commands/_my_close.md`
- Work item scope: move `active/{item}/` → `completed/{date}_{item}/`, update CURRENT_WORK.md, CHANGELOG.md
- Epic scope: archive epic + all child items, update BACKLOG.md, CURRENT_WORK.md, CHANGELOG.md
- Require user confirmation before archiving
- Add Codex skill description to `codex-overrides/config.sh`

**Non-Goals / Out of Scope**:
- Evaluating or certifying (that's audit's job)
- Session context persistence (that's wrap-up's job)

**Success / Done State**:
- [ ] `/_my_close {item}` archives a work item and updates tracking files
- [ ] `/_my_close {epic}` archives an epic and all child items
- [ ] User is prompted for confirmation before archiving

**Location**: `.project/active/close-command/`

---

### Item 6: `/_my_pre_pr` Command

**Type**: Implementation
**Effort**: 0.5-1 day (spec 0.5h, design 0.5h, plan 0.5h, execute 3-5h)
**Dependencies**: None

**Objective**: Consolidate `_my_code_review` and `_my_code_quality` into a single pre-PR defensive quality gate.

**Why This Is One Work Item**:
- Consolidating two existing commands into one
- Clear scope: code quality checks, not spec/design conformance

**In Scope (High Level)**:
- New command file `claude-pack/commands/_my_pre_pr.md`
- Runs automated tests, linting (ruff), formatting, type checking
- Flags pattern violations and code slop
- Not tied to a specific work item — runs against whatever is about to be committed
- Salvage useful patterns from `_my_code_review.md` and `_my_code_quality.md`
- Add Codex skill description to `codex-overrides/config.sh`

**Non-Goals / Out of Scope**:
- Spec/design conformance (that's audit's job)
- Writing review artifacts to a work item directory

**Success / Done State**:
- [ ] `/_my_pre_pr` runs quality checks and reports findings
- [ ] No spec/design conformance logic — purely code quality

**Location**: `.project/active/pre-pr-command/`

---

### Item 7: `/_my_status` Command

**Type**: Implementation
**Effort**: 0.5 days (spec 0h, design 0h, plan 0h, execute 3-4h)
**Dependencies**: None

**Objective**: Extract status, orientation, and backlog review from `_my_project_manage` into a standalone command. This fully replaces `_my_project_manage` — once status, close, and epic_plan exist, the old command is deleted with nothing left behind.

**Why This Is One Work Item**:
- Small extraction from an existing command
- No new concepts — just isolating what already works

**In Scope (High Level)**:
- New command file `claude-pack/commands/_my_status.md`
- Reads CURRENT_WORK.md, BACKLOG.md, and epic files
- Produces a status report with gap analysis and backlog orientation (priority assessment, staleness)
- No mode flags
- Add Codex skill description to `codex-overrides/config.sh`

**Non-Goals / Out of Scope**:
- Decomposition (that's epic_plan)
- Archiving (that's close)

**Success / Done State**:
- [ ] `/_my_status` produces a clear status report covering active work, backlog, and gaps
- [ ] Includes backlog orientation (what's prioritized, what's stale) — absorbs the backlog mode from `_my_project_manage`
- [ ] No mode flags required

**Location**: `.project/active/status-command/`

---

### Item 8: `/_my_design_review` Rename

**Type**: Implementation
**Effort**: 0.5 days (spec 0h, design 0h, plan 0h, execute 2-3h)
**Dependencies**: None

**Objective**: Rename `_my_review_design` to `_my_design_review` for consistency with `_my_spec_review`, and add persistent artifact output.

**Why This Is One Work Item**:
- Small, self-contained change to an existing command
- Rename + add artifact output are tightly coupled

**In Scope (High Level)**:
- Rename `_my_review_design.md` → `_my_design_review.md`
- Add instruction to write `design-review.md` in the work item directory (currently only produces conversational output)
- Update Codex skill description in `codex-overrides/config.sh` (old key: `review-design`, new key: `design-review`)

**Non-Goals / Out of Scope**:
- Changing the review methodology or lenses
- Cross-reference cleanup (that's Item 9)

**Success / Done State**:
- [ ] Command exists as `/_my_design_review`
- [ ] Writes `design-review.md` artifact to the work item directory

**Location**: `.project/active/design-review-rename/`

---

### Item 9: Cross-Reference Cleanup and Codex Rebuild

**Type**: Implementation
**Effort**: 0.5 days (spec 0h, design 0h, plan 0h, execute 3-4h)
**Dependencies**: Items 2-8 (all command changes must be done first)

**Objective**: Update all files that reference retired or renamed commands, retire old command files, and rebuild the Codex dist.

**Why This Is One Work Item**:
- Sweep across many files but each change is mechanical
- Must happen after all other items so it catches everything

**In Scope (High Level)**:
- Update cross-references in commands:
  - `_my_implement.md:227` — references `/_my_project_manage` → `/_my_audit` then `/_my_pre_pr` (the new post-implementation flow)
  - `_my_quick_edit.md:100` — references `/_my_code_review` → `/_my_pre_pr`
  - `_my_wrap_up.md` — verify no lifecycle-step language remains
- Update rules:
  - `claude-pack/rules/workflow-accountability.md:27` — references `/_my_audit_implementation` → `/_my_audit`
- Update templates:
  - `project-pack/README.md` — references `_my_code_review`, `_my_code_quality`, `_my_project_manage`
- Update Codex config:
  - `codex-overrides/config.sh` — retire old entries (`audit-implementation`, `code-quality`, `code-review`, `project-manage`, `review-design`), add new entries where not already added by prior items
- Retire old command files:
  - `_my_audit_implementation.md` (replaced by `_my_audit.md`)
  - `_my_code_review.md` (replaced by `_my_pre_pr.md` + `_my_audit.md`)
  - `_my_code_quality.md` (replaced by `_my_pre_pr.md`)
  - `_my_project_manage.md` (all 4 modes replaced: status+backlog → `_my_status.md`, close → `_my_close.md`, decompose → `_my_epic_plan.md`)
  - `_my_review_design.md` (replaced by `_my_design_review.md`)
- Rebuild Codex dist: `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`
- Run `./scripts/setup-global.sh` to update symlinks
- Update CLAUDE.md if any references are stale

**Non-Goals / Out of Scope**:
- Writing new command logic (that's done in prior items)
- Updating commands in other projects that use these commands (out of scope for this repo)

**Success / Done State**:
- [ ] `grep -r` for retired command names returns zero hits outside `completed/` and `BACKLOG.md` history
- [ ] Codex dist builds cleanly
- [ ] `setup-global.sh` runs without errors
- [ ] All new commands are available via `/_my_*` in a fresh session

**Location**: `.project/active/cleanup-codex-rebuild/`

---

## Dependencies

**External**: None

**Internal**: None (this epic operates on the meta-project itself)

**Item Dependency Graph**:
```
Item 1: Epic Template Foundation (no dependencies)
  ├─> Item 2: /_my_epic_plan (depends on Item 1)
  └─> Item 3: Pipeline Required Reading (depends on Item 1)

Item 4: /_my_audit (soft dependency on Item 1)
Item 5: /_my_close (no dependencies)
Item 6: /_my_pre_pr (no dependencies)
Item 7: /_my_status (no dependencies)
Item 8: /_my_design_review (no dependencies)

Items 2-8 ──> Item 9: Cleanup + Codex Rebuild (depends on all above)
```

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Commands reference each other in "Related Commands" sections we haven't audited | Low | Item 9 does a grep sweep for all old names |
| Codex build script assumptions break with renamed commands | Med | Test build after each rename, not just at the end |
| Required Reading adds too much context for small items | Low | Commands handle the no-epic case; Required Reading is optional per item |

---

## Timeline

**Total Effort**: 6-8 days

| Item | Effort | Dependencies |
|------|--------|--------------|
| 1. Epic Template Foundation | 0.5 days | None |
| 2. `/_my_epic_plan` | 1-1.5 days | Item 1 |
| 3. Pipeline Required Reading | 1 day | Item 1 |
| 4. `/_my_audit` | 1-1.5 days | None |
| 5. `/_my_close` | 0.5-1 day | None |
| 6. `/_my_pre_pr` | 0.5-1 day | None |
| 7. `/_my_status` | 0.5 days | None |
| 8. `/_my_design_review` | 0.5 days | None |
| 9. Cleanup + Codex Rebuild | 0.5 days | Items 2-8 |

Items 2-8 can be done in any order (except 2 and 3 need Item 1 first). Parallelizable across sessions.

---

**Last Updated**: 2026-06-30
**Next Action**: Start with Item 1 (Epic Template Foundation), then Items 2 and 3 in parallel.
