# Backlog

## P0 - Critical / Active

### [EPIC-002] Migrate Commands from Artifacts ✅

**Priority:** P0
**Status:** Complete
**Estimate:** L (incremental)
**Category:** Command Migration

#### Problem

The `artifacts/agentic_codebase_template/.claude/commands/` directory contains battle-tested commands that need to be migrated into `claude-pack/commands/`. However:
- Some commands may need updates/improvements
- We want to review each one before migrating
- Some may overlap with existing commands (e.g., `project-manage.md`)

#### Commands to Migrate

| Command | Size | Notes |
|---------|------|-------|
| `spec.md` | 8KB | Core workflow command - **MIGRATED** |
| `design.md` | 11KB | Core workflow command - **MIGRATED** |
| `implement.md` | 5KB | Core workflow command - **MIGRATED** (BL-001 integrated) |
| `research.md` | 5KB | Investigation workflow - **MIGRATED** |
| `code-review.md` | 14KB | Quality workflow - **MIGRATED** |
| `code-quality.md` | 6KB | Quality workflow - **MIGRATED** |
| `quick-edit.md` | 3KB | Lightweight workflow - **MIGRATED** |
| `git-manage.md` | 18KB | Advanced workflow - **MIGRATED** |
| `my-plan.md` | 10KB | Planning workflow - **MIGRATED** (renamed to `plan.md`) |
| `project-manage.md` | 12KB | Compare with existing - **KEPT EXISTING** |

#### Migration Strategy

For each command:
1. **Review** - Read and understand what it does
2. **Compare** - Check if we have an existing version
3. **Decide** - Keep as-is, modify, merge, or skip
4. **Migrate** - Copy to `claude-pack/commands/` with any improvements
5. **Test** - Verify it works through symlink

#### Sub-items (migrate incrementally)

- [x] **EPIC-002.1**: Migrate `spec.md` - Core workflow, review for improvements
- [x] **EPIC-002.2**: Migrate `design.md` - Core workflow, integrate BL-004 ideas
      - *Init reqs: Optional project docs (structure, patterns, commands); inline metadata approach*
- [x] **EPIC-002.3**: Migrate `implement.md` - Core workflow, integrate BL-001 improvements
      - *Init reqs: CLAUDE.md for env/test commands; plan.md + design.md + spec.md; optional CURRENT_WORK.md*
- [x] **EPIC-002.4**: Migrate `research.md` - Investigation workflow
      - *Init reqs: `.project/research/` directory; optional project docs in CLAUDE.md*
- [x] **EPIC-002.5**: Migrate `quick-edit.md` - Lightweight edits
      - *Init reqs: None new - uses existing `.project/active/{feature}/` structure*
- [x] **EPIC-002.6**: Migrate `code-review.md` - Quality workflow
      - *Init reqs: `.project/reports/` for ad-hoc reviews; uses existing active structure*
- [x] **EPIC-002.7**: Migrate `code-quality.md` - Quality checks
      - *Init reqs: CLAUDE.md with test/lint/format commands; uses existing active structure*
- [x] **EPIC-002.8**: Migrate `my-plan.md` - Planning workflow (renamed to `plan.md`)
      - *Init reqs: Requires spec.md + design.md in active dir; CLAUDE.md for env/test commands*
- [x] **EPIC-002.9**: Review `git-manage.md` - Large, kept as single command (worktree workflow)
      - *Init reqs: `.claude/settings.local.json` for worktree permissions; CLAUDE.md for env setup*
- [x] **EPIC-002.10**: Compare `project-manage.md` - Kept existing claude-pack version (already better)
      - *Init reqs: CURRENT_WORK.md, EPIC_GUIDE.md, CHANGELOG.md; uses all .project/ dirs*
- [x] **EPIC-002.11**: Update project initialization with accrued requirements
      - Added `claude-pack/claude-md-checklist.md` - guidance for CLAUDE.md content
      - Added `project-pack/research/` and `project-pack/reports/` directories
      - Commands gracefully handle missing CLAUDE.md info (ask user, explore codebase)

#### Accrued Initialization Requirements

Use `{keyword}` pattern where possible to enable script-based customization.

| Requirement | Source | Type | Notes |
|-------------|--------|------|-------|
| `CLAUDE.md` | 002.3 | Required | Environment, test, and quality commands |
| `.project/active/{feature}/` | 002.1-3 | Required | Directory for active work items |
| `.project/backlog/BACKLOG.md` | 002.1-2 | Required | Backlog tracking |
| `.project/research/` | 002.1-2 | Required | Research artifacts |
| `.project/completed/` | 002.1 | Required | Archived completed work |
| `spec.md`, `design.md`, `plan.md` | 002.3 | Required | Per-feature documents in active dir |
| Project docs (structure, patterns, commands) | 002.2 | Optional | Referenced in CLAUDE.md if they exist |
| `CURRENT_WORK.md` | 002.3 | Optional | Status tracking |
| `{feature-name}` | 002.1-3 | Pattern | Used in paths, should be kebab-case |
| `.project/research/` | 002.4 | Required | Research output directory |
| `{YYYYMMDD-HHMMSS}_{topic}.md` | 002.4 | Pattern | Timestamped research filename |
| `.project/reports/` | 002.6 | Required | Ad-hoc review reports |
| `plan.md` | 002.8 | Required | Per-feature implementation plan |
| `CURRENT_WORK.md` | 002.10 | Optional | Active work tracking (root of .project/) |
| `EPIC_GUIDE.md` | 002.10 | Optional | Epic decomposition methodology |
| `CHANGELOG.md` | 002.10 | Optional | In .project/completed/ |

*Migration complete. See EPIC-002.11 for consolidated requirements.*

#### Notes
- Do incrementally - one command at a time with review
- Some commands may fold into each other
- BL-001 and BL-004 improvements can be applied during migration

---

## Completed / Archived

### ~~[EPIC-001] Project Initialization Strategy~~ ✅

**Status:** Simplified & Completed (2025-12-30)
**Outcome:** Instead of building complex auto-detection, simplified to:
- Check for CLAUDE.md, suggest `/init` if missing
- Added merge strategy for existing `.project/`
- Moved `project-pack/` to top level

**Archived to:** `.project/completed/20251230_epic_init_strategy.md`

---

## P1 - High Priority

### [BL-001] Improve `/implement` command code scrutiny

**Priority:** P1
**Status:** Backlog
**Estimate:** M
**Category:** Command Improvement
**Affected File:** `.claude/commands/implement.md`

#### Problem
The `/implement` command is blindly following the plan without adequately scrutinizing or thinking through the code as it progresses. This leads to:
- Mechanical code generation without critical analysis
- Missing edge cases or issues that would be caught with deeper thought
- Lack of adaptation when implementation reveals plan flaws
- Not fully understanding the design rationale before coding

#### Proposed Solution
Add prompting to the `/implement` command that enforces understanding before action.

**Draft language to test:**
```
NOTE: I do not want you to blindly implement the code in the plan. make sure you thoroughly read the `design.md` and supporting documents to FULLY understand how things are supposed to work, and the rationale behind the design. Furthermore, you should read `spec.md` in full to ensure you understand the outcomes and expectations.

If you need to perform codebase searches to help your understanding up front, use `Task` tool with `subagent_type=Explore`.
```

#### Acceptance Criteria
- [ ] Agent reads and understands `design.md` before implementing
- [ ] Agent reads and understands `spec.md` for expected outcomes
- [ ] Agent uses Explore subagent when needing codebase context
- [ ] Agent demonstrates understanding of *why* not just *what*
- [ ] Implementation quality improves (fewer bugs, better edge case handling)

#### Notes
- Key insight: Force reading of design rationale, not just implementation steps
- Explore subagent can front-load understanding before coding begins
- May need additional prompts for mid-implementation reflection
- **Can be applied during EPIC-002.3 migration**

### [BL-002] Create git history subagent

**Priority:** P1
**Status:** Backlog
**Estimate:** M
**Category:** New Agent
**Affected Files:** `.claude/agents/git-history.md`, possibly `.claude/skills/git-*.md`

#### Problem
When exploring a codebase for relevant code, agents often need to investigate git history (blame, log, diff between commits) but this is verbose and context-heavy.

#### Proposed Solution
Create a dedicated `git-history` subagent with question-response interface:
```
Q: "When was function X last modified and why?"
A: {commit, author, date, message, diff_snippet}
```

### [BL-003] Create codebase-search subagent

**Priority:** P1
**Status:** Backlog
**Estimate:** M
**Category:** New Agent
**Affected Files:** `.claude/agents/codebase-search.md`

#### Problem
When exploring a codebase, agents return too much raw content and miss relevant files due to incomplete searching.

#### Proposed Solution
Create a `codebase-search` subagent that returns structured pointers, not raw code dumps.

### [BL-004] Update `/spec` and `/design` to enforce codebase discovery

**Priority:** P1
**Status:** Backlog
**Estimate:** S
**Category:** Command Improvement
**Depends On:** BL-003 (codebase-search subagent)

#### Problem
Specs and designs are created without adequate exploration of existing code.

#### Proposed Solution
Add prompting to enforce codebase discovery before finalizing specs/designs.
- **Can be applied during EPIC-002.1 and EPIC-002.2 migration**

---

## P2 - Medium Priority

### [BL-005] Document workflow types and command mappings

**Priority:** P2
**Status:** Backlog
**Estimate:** M
**Category:** Documentation

When to use full epic workflow vs quick edits, decision trees, BKMs.

### [BL-006] Workflow management helper scripts

**Priority:** P2
**Status:** Backlog
**Estimate:** M
**Category:** Tooling

Git worktree helpers, project artifact management scripts.

### [BL-007] Document "no replacement for design" principles

**Priority:** P2
**Status:** Backlog
**Estimate:** S
**Category:** Documentation

Core principles about AI amplifying vs replacing design thinking.

### [BL-008] Create `get_good_prompt` command/agent

**Priority:** P2
**Status:** Backlog
**Estimate:** M
**Category:** New Command/Agent

Compose prompts from proven BKM phrase book.

---

## P3 - Low Priority

*(empty)*

---

## Ideas / Future Considerations

### [EPIC-003] Skills as Continual Learning Mechanism

**Priority:** P2 (Experimental)
**Status:** Backlog
**Estimate:** L (iterative experimentation)
**Category:** Learning & Improvement
**Reference:** `artifacts/skills-as-continual-learning.txt`

#### Problem

Currently, insights gained during coding sessions are lost when the session ends. Each new session starts fresh without knowledge of:
- What approaches worked or failed previously
- Edge cases discovered during implementation
- Configuration patterns that proved successful
- Mistakes that should be avoided

As described in the reference video: "One of the problems with this is the agent never actually learns on its own."

#### Proposed Solution

Leverage Claude Code skills as a **persistent learning mechanism** where the model can read AND write to skill files, enabling:

1. **Learning Loops** - Query skill registry before tasks; update skills after sessions
2. **Failure Documentation** - Capture what went wrong so future sessions can avoid it
3. **Success Patterns** - Record working configurations and approaches
4. **Retrospectives** - End-of-session review that extracts and persists learnings

Key insight from Robert Nishihara (Anyscale CEO): "Knowledge stored outside the model's weights is interpretable, correctable, and data efficient."

#### Research Items

- [ ] **EPIC-003.1**: Study existing skills structure in `claude-pack/skills/`
- [ ] **EPIC-003.2**: Design a "learnable skill" template with sections for successes/failures
- [ ] **EPIC-003.3**: Create `/retrospective` command to trigger end-of-session learning capture
- [ ] **EPIC-003.4**: Test learning loop with a single pilot skill (e.g., debugging or code review)
- [ ] **EPIC-003.5**: Evaluate: Does accumulated learning actually improve outcomes?

#### Implementation Ideas

1. **Skill Structure Additions:**
   - `## Known Failures` - approaches that don't work, with context
   - `## Working Patterns` - proven configurations and approaches
   - `## Experiments Log` - timestamped learnings from sessions

2. **Triggers:**
   - `/retrospective` slash command for manual learning capture
   - Hook-based automatic capture at session end
   - PR-based updates for shared skill registries

3. **Progressive Disclosure:**
   - Skill descriptions stay in main context (token efficient)
   - Full skill content + learnings loaded only when invoked

#### Success Criteria

- [ ] At least one skill demonstrates measurable improvement over 5+ sessions
- [ ] Failure documentation prevents repeat mistakes
- [ ] Learning capture doesn't add significant overhead to workflow
- [ ] Learnings are interpretable and editable by humans

#### Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Skill files grow too large | Med | Periodic summarization/pruning |
| Learnings become stale | Med | Timestamp entries, periodic review |
| Noise overwhelms signal | High | Structured templates, quality gates |

#### Notes

- Start small with one skill, validate before scaling
- Consider integration with existing `/capture` and `/memorize` commands
- May inform future improvements to command prompts themselves
