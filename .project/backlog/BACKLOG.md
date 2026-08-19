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

## ~~P0 - Critical / Active~~

### ~~[WORKFLOW-V2] Workflow v2 Redesign~~ ✅

**Priority:** P0
**Status:** Complete (2026-07-01)
**Estimate:** 6-8 days (9 work items)
**Category:** Workflow Redesign

Pipeline redesign: new bridge command (epic_plan), certification step (audit), archive command (close), consolidated pre-PR gate, Required Reading traceability from concepts through implementation.

**Items**:
- [x] Item 1: Epic Template Foundation (0.5 days)
- [x] Item 2: `/_my_epic_plan` command (1-1.5 days) — depends on 1
- [x] Item 3: Pipeline Required Reading (1 day) — depends on 1
- [x] Item 4: `/_my_audit` certification (1-1.5 days)
- [x] Item 5: `/_my_close` command (0.5-1 day)
- [x] Item 6: `/_my_pre_pr` command (0.5-1 day)
- [x] Item 7: `/_my_status` command (0.5 days)
- [x] Item 8: `/_my_design_review` rename (0.5 days)
- [x] Item 9: Cleanup + Codex rebuild (0.5 days) — depends on 2-8

**Archived to:** `.project/completed/20260701_epic_workflow_v2.md`

---

## P0 - Anchor on the Point

These five tickets address one root failure: agents lose the purpose of the work and produce
artifacts anchored on mechanics instead of outcomes. They are discrete strategies but need to be
considered together and prioritized as a group.

**Root cause (observed):** The agent reads for actions, not intent. Every "understand the point"
instruction in the pipeline can be satisfied by extraction or skipped silently. The concept doc —
the source of truth — already mixes outcomes with solution architecture, so even faithful
extraction propagates design vocabulary into problem space. The pipeline has 26 point-anchoring
mechanisms; zero produce a checkable artifact whose wrongness is visible without human review.

**Reference:** `.project/research/20260818-151200_anchor-on-the-point-inventory.md`

---

### [AOP-001] Keep the concept stage outcome-pure

**Priority:** P0
**Status:** Backlog
**Estimate:** M
**Category:** Command Improvement
**Affected File:** `claude-pack/commands/_my_concept.md`

#### Problem

The concept doc is the source of truth for what the work is and why. But the current
`/_my_concept` command allows — and the agent gravitates toward — mixing outcomes with solution
architecture. Terms like "stage contract," "attributed chain," and "content-addressable artifacts"
leak into the problem space, and every downstream document inherits them. By the time the
orchestrator reads the concept, it's thinking in stages and artifacts instead of "the user wants
to tweak a setting and refit."

The concept doc for the staged-fitting pipeline captures "iterate on hyperparameters" strongly,
"fit other xRHB configs" as intent only, and "iterate on model forms" weakly — despite all three
being stated in the concept conversation.

#### Strategy

Groom `/_my_concept` to enforce outcome/behavior language and reject solution architecture:

- **No terms that don't exist before this work.** If the concept introduces vocabulary (stages,
  artifacts, chains, contracts), it's doing design, not capturing the problem.
- **Problem framed as cost.** What can't the user do today, and what does it cost them?
- **Success framed as capability.** What does the user do differently after?
- **Strategy at the "what, not how" altitude.** "Replace the scattered fitting process with a
  clean pipeline" — not "four explicit configurable steps with content-addressed artifacts."

Build a set of product-anchoring documents (including PDRs) that can be used for outcome
grounding, free of design and code biases.

#### Acceptance Criteria

- [ ] `/_my_concept` has explicit guidance rejecting solution-architecture language
- [ ] The concept template separates problem/cost from strategy, with strategy constrained to
      "what, not how"
- [ ] Product-anchoring document set identified and referenced (concept, PDRs, epic problem
      statements)
- [ ] Test: re-run the staged-fitting concept through the revised command; all three outcome
      dimensions (model iteration, hyperparameter iteration, multi-config fitting) captured at
      equal strength

---

### [AOP-002] PDRs as live anchors during execution

**Priority:** P0
**Status:** Backlog
**Estimate:** S
**Category:** Workflow Improvement
**Depends On:** AOP-001 (product-anchoring doc set)

#### Problem

PDRs (Product Design Records) are currently written after implementation as anchoring for future
work. But the execution process — spec, design, implementation — is where the point gets lost.
A PDR written at the start of an activity, with status tracking, would serve as an outcome anchor
*within* the pipeline, not just after it.

#### Strategy

- Add status field to PDRs: `draft` | `in-progress` | `completed`
- PDR written at activity start, referencing the spec or epic it supports
- Pipeline commands can read the PDR for outcome grounding (the "what does done look like for
  the user" framing) without touching design docs or code
- Status tracks whether the capability has been implemented, addressing the "we want to do it
  but it hasn't been built" ambiguity

#### Acceptance Criteria

- [ ] PDR template includes status field with defined values
- [ ] PDR creation integrated into pipeline entry (concept or spec stage)
- [ ] At least one pipeline command (design, implement) references the PDR for outcome grounding
- [ ] PDR updates to `completed` as part of `/_my_close`

---

### [AOP-003] Carve out infected language from prompts

**Priority:** P0
**Status:** Backlog
**Estimate:** L
**Category:** Prompt Improvement

#### Problem

Pipeline command prompts use compressed, jargon-heavy language that agents pattern-match and
propagate. "Attributed chain," "stage contract," "conservatism as configuration" — these terms
become the agent's working vocabulary, and once the vocabulary is set, the agent writes about
mechanisms instead of outcomes. The human review checkpoints become expensive because the
reviewer has to decode the jargon to verify the point.

#### Strategy

Go through all prompts and rewrite in simplified technical English. Add voice guides where needed.

#### Open question (noted by owner)

This is a genuine tension. 99% of the markdown is consumed by another AI, so compressed
language is token-efficient for agent-to-agent communication. But if we permit it, the remaining
human checkpoints become painfully expensive. And it is hard to get Claude to code-switch between
compressed-for-agents and plain-for-humans — it tends to write everything in whatever register it
last read.

Two approaches to test:
- **Full plain English everywhere.** Longer prompts, but human-readable at every checkpoint.
  Agents may produce clearer output because their input is clearer.
- **Plain English for outcome-facing sections only.** Allow compressed language in mechanism
  sections (design internals, implementation details) but enforce plain language in problem
  statements, success criteria, and "The Point" sections.

#### Acceptance Criteria

- [ ] Audit of all `_my_*` commands for jargon-heavy language
- [ ] At least the outcome-facing sections rewritten in plain technical English
- [ ] Decision documented: full plain English vs. outcome-sections-only
- [ ] Voice guide updated or extended if needed

---

### [AOP-004] Fix test quality — real behaviors, not existence proofs

**Priority:** P1
**Status:** Backlog
**Estimate:** L
**Category:** Quality Improvement

#### Problem

Tests generated by agents are currently useless:
- ~95% prove a thing exists (class instantiates, method returns something, file is present)
- Almost none test real edge cases or end-to-end behaviors
- The test suite gives false confidence — green check marks on tests that don't verify anything
  meaningful

This connects to the anchoring problem: an agent that doesn't understand the *point* of the code
writes tests that check structure, not behavior, because structure is extractable and behavior
requires understanding.

#### Strategy

TBD — needs its own research/concept pass. Possible directions:
- Test prompts that require stating the behavior under test before writing the assertion
- Example-based guidance: "a good test for a fitting pipeline checks that changing a
  hyperparameter produces a different fit, not that the pipeline object has a `fit` method"
- Spec-derived test requirements: success criteria in the spec map to test cases

#### Acceptance Criteria

- [ ] Concrete strategy defined (needs research)
- [ ] At least `/_my_implement` updated with test-quality guidance
- [ ] Measurable: ratio of behavior-testing vs. existence-testing assertions improves in a
      real project

---

### [AOP-005] Force contemplation on outcomes — comprehension pump

**Priority:** P0
**Status:** Backlog
**Estimate:** M
**Category:** Hook / Enforcement Mechanism

#### Problem

The pipeline has 26 "understand the point" instructions. All 14 instruction-type mechanisms can
be silently skipped. All 5 template slots can be filled by extraction. The 4 product-lens gates
catch contradiction but not absence. Zero mechanisms produce a transfer task — a question whose
answer requires synthesis, not extraction.

The core asymmetry: the agent does 100% of steps that produce an auditable artifact and ~0% of
steps that are "read and understand." Norms get skimmed; steps that must produce checkable
output get done.

#### Strategy

Convert "understand the point" into steps that emit something checkable, using two approaches:

**Exhibit A: Comprehension-pump hook (directed self-reflection)**

A Stop hook that blocks the agent with three directed transfer questions before allowing
completion at high-leverage moments (orchestrator orientation, handoff writing, deliverable
writing). Each question forces a different kind of synthesis:

1. "What problem existed before this work — what couldn't the user do?"
2. "What does the user do differently after? What capability do they gain?"
3. "How does the strategy solve that specific problem? Why this approach?"

The hook is three static strings, no LLM critic. Value: forces three re-derivation passes.
Limitation: the agent can still produce three plausible-sounding wrong answers — but it's
harder than producing one, and the output is visible.

Full design and implementation options documented in:
`.project/research/20260818-151200_anchor-on-the-point-inventory.md` (Hook Implementation section)

**Exhibit B: Multi-turn outcome anchoring before execution**

A prompting pattern that anchors the agent on outcomes before it reads any design docs or code.
The agent reads ONLY the concept doc and product-anchoring materials, then answers directed
questions about the problem and strategy. Only after this anchoring step does it proceed to
read design/implementation docs.

Tested manually with promising results: the agent produced nuanced, graded analysis of outcome
capture strength ("captured strongly," "captured as intent only," "captured weakest") when
restricted to the concept doc and asked transfer questions. Unclear if the pattern holds without
human follow-up questions — needs testing.

Example prompt pattern (tested on staged-fitting-pipeline):
```
Read ONLY the concept doc. In 5 sentences or less, cover:
- What is the problem we are solving
- What are the fundamental design patterns that must hold
- What does that mean for the design of [specific item]

Do NOT read any documents I did not directly reference.
```

#### Open design questions

1. Can the Stop hook's three-pass pattern produce the same depth as human-directed questioning,
   or does it flatten to extraction without follow-up?
2. Should the outcome-anchoring step be a separate command (`/_my_orient`) or integrated into
   existing commands?
3. How to prevent the agent from reading design/code docs during the anchoring step — instruction
   ("do NOT read") vs. structural (subagent with restricted tool access)?

#### Acceptance Criteria

- [ ] At least one approach (hook or multi-turn) prototyped and tested on a real work item
- [ ] Test result documented: did the agent's understanding improve measurably vs. baseline?
- [ ] If successful, integrated into at least the three high-leverage points (orchestrator
      orientation, handoff, deliverable writing)
- [ ] The agent's comprehension output is visible (not just internally processed)

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
