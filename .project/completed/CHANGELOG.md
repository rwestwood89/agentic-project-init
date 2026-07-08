# Changelog

Historical record of completed work.

---

## [2026-07-06] - spike-and-learning-test-commands

**Type**: Item
**Duration**: 4 days (2026-07-02 to 2026-07-06)

### Summary
Closed the pipeline's bottom-up learning gap: the top-down flow assumed the mechanism was known, and nothing let an agent stop planning and write code to find out how something actually behaves. Added two hands-on de-risking commands — `/_my_spike` (confirm a known assumption with a throwaway probe) and `/_my_learning_test` (map an unfamiliar surface with real, kept tests) — as the write-code-to-learn siblings of read-only `/_my_research`, sharing one discipline: reproducible steps, a living findings doc, summary-on-top written last, and a close-the-loop back-reference into the triggering upstream doc.

### Deliverables
- **New commands:** `_my_spike`, `_my_learning_test` (installed via `setup-global.sh`)
- **Soft de-risking wiring:** `_my_concept_design`, `_my_spec`, `_my_design`, `_my_epic_plan`, `_my_research` (suggestions at existing anchors, never gates)
- **Orchestration awareness (user-requested addition):** `_my_orchestrate`, `_my_pipeline`, and `orchestrate-stage.sh` (`bypassPermissions` default for spike/learning_test)
- **Codex:** both skills built + installed (`my-spike`, `my-learning-test`); description keys in `codex-overrides/config.sh`
- **Docs:** README command table rows, CLAUDE.md "De-risking" section
- **Artifacts:** spec.md, spec-review.md, design.md, plan.md, audit.md (Certify), findings.md + `probe_yaml_description.py` (Phase-1 live spike: leading `*`/`**` breaks Codex SKILL.md YAML, mid-value colons are safe)

### Lessons Learned
- [TODO: Add lessons learned]

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
