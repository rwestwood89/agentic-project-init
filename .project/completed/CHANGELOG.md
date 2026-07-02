# Changelog

Historical record of completed work.

---

## [2026-07-01] - Epic WORKFLOW-V2: Workflow v2 Redesign

**Type**: Epic (9 items)
**Duration**: 2 days (2026-06-30 to 2026-07-01)

### Summary
Redesigned the workflow pipeline to close gaps in traceability, certification, and command ergonomics. Added a bridge from shaping to scoping via epic Source Documents and Required Reading. Replaced the read-only audit with a certification step that updates tracking artifacts. Decomposed the overloaded `_my_project_manage` into focused single-purpose commands. Consolidated two overlapping code review commands into a single pre-PR gate.

### Deliverables
- **New commands:** `_my_epic_plan`, `_my_close`, `_my_pre_pr`, `_my_status`
- **Expanded:** `_my_audit` (certification with plan/spec/epic checkbox updates, work-item + epic scope)
- **Renamed:** `_my_design_review` (from `_my_review_design`, now writes persistent artifact)
- **Modified:** `_my_spec`, `_my_product_design`, `_my_design` (Required Reading from epics)
- **Templates:** `epic_template.md` and `EPIC_GUIDE.md` (Source Documents, Required Reading)
- **Retired:** `_my_audit_implementation`, `_my_code_review`, `_my_code_quality`, `_my_project_manage`, `_my_review_design`
- **Codex dist:** rebuilt with new skill landscape
- **Specs:** 7 items with specs, 4 items with designs
- **Archived to:** `.project/completed/20260701_epic_workflow_v2.md`

### Lessons Learned
- [TODO: Add lessons learned]

---

## [2025-12-30] - codebase-organization

**Type**: Item
**Duration**: ~1 day

### Summary
Established the repository structure with separate `claude-pack/` for Claude Code configuration and `project-pack/` for project management templates. Set up symlinks for development workflow.

### Deliverables
- `claude-pack/` structure (commands, hooks, agents, rules, skills)
- `project-pack/` structure (project management templates)
- `.claude/` symlinks for this repo
- `design.md` and `plan.md` documentation

### Lessons Learned
- Symlink approach works well for testing what you ship
- Separating claude-pack and project-pack provides cleaner organization

---

## [2025-12-30] - init-audit

**Type**: Item (Superseded)
**Duration**: ~2 hours

### Summary
Conducted initial audit of `init-project.sh` for epic EPIC-001. Epic was later simplified - instead of building complex auto-detection, we leverage Claude's `/init` command for CLAUDE.md generation.

### Deliverables
- `spec.md` - Audit methodology
- `audit-report.md` - Comprehensive findings (useful as reference)

### Lessons Learned
- Don't over-engineer: Claude Code already has project initialization capabilities
- Simpler approach: check for CLAUDE.md and suggest `/init` if missing
- Audit work wasn't wasted - informed the simpler solution

---
