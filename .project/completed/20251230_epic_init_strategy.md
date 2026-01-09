# EPIC-001: Project Initialization Strategy

**Priority**: P0
**Status**: Decomposed
**Total Estimate**: 4-5 days
**Category**: Strategy / Infrastructure

---

## Executive Summary

Enhance the project initialization script to not just copy files, but intelligently discover project context and set up Claude for effective collaboration. This includes auto-detecting project structure, prompting for essential context, and generating useful initial documentation.

## Success Criteria

- [ ] Init handles both greenfield and existing projects
- [ ] Project-specific context is captured somewhere useful
- [ ] User understands what was set up and why
- [ ] Works across common project types (Node, Python, Rust, etc.)

## Why This Epic

**Current State**:
- `init-project.sh` just copies template files
- No guidance through initial project discovery
- No capture of where docs, tests, configs live
- No useful initial CLAUDE.md or project context

**Future State**:
- Interactive discovery flow captures project specifics
- Auto-detection identifies test dirs, build system, config files
- Generated CLAUDE.md contains actionable project context
- Users hit the ground running with Claude assistance

---

## Backlog Items

### Item 1: Init Script Audit & Gap Analysis [0.5-1 day]

**Type**: Research

**Objective**: Document current init script capabilities and identify specific gaps that need addressing.

**Current State**:
- ✅ `init-project.sh` exists and copies template files
- ❌ No inventory of what it currently does well
- ❌ No documented requirements for enhancement
- ❓ Unknown how it handles edge cases (existing .project/, etc.)

**Scope**:
1. **Audit Current Script**:
   - Read and document `init-project.sh` behavior
   - Trace what files get copied and where
   - Document any existing logic (conditionals, prompts)
2. **Identify Gaps**:
   - What's missing vs the epic requirements?
   - What would improve user experience?
   - What context would help Claude be effective?
3. **Research Comparable Tools**:
   - How do other init tools (create-react-app, cargo init) handle discovery?
   - What patterns are worth adopting?

**Out of Scope**:
- Actually implementing any changes
- Detailed design of new features (that's Item 2)
- Testing on multiple project types (that's Item 4)

**Success Criteria**:
- [ ] Current script behavior fully documented
- [ ] Gap analysis completed with prioritized list
- [ ] Recommendations for Item 2 design captured
- [ ] Audit report produced

**Estimated Effort**: 0.5-1 day (spec 1h, research 3-4h, document 1h)

**Location**: `.project/active/init-audit/`

**Dependencies**: None

**Deliverables**:
- `.project/active/init-audit/spec.md` - What to audit and analyze
- `.project/active/init-audit/audit-report.md` - Findings and recommendations

---

### Item 2: Discovery Flow Design [1 day]

**Type**: Design

**Objective**: Design the interactive discovery flow that captures project context during initialization.

**Current State**:
- ❌ No discovery flow exists
- ❌ No defined questions to ask users
- ❌ No auto-detection heuristics designed
- ❓ Unclear where captured context should live

**Scope**:
1. **User Prompt Design**:
   - What questions to ask (project type, name, etc.)
   - When to prompt vs auto-detect
   - How to handle "I don't know" responses
2. **Auto-Detection Heuristics**:
   - Test location patterns (`tests/`, `__tests__/`, `*.test.ts`)
   - Doc location patterns (`docs/`, `README.md`)
   - Build system detection (`package.json`, `Cargo.toml`, `pyproject.toml`)
   - Config file patterns
3. **Output Format Design**:
   - CLAUDE.md template with discovered context
   - .project/ initial files structure
   - How to present discoveries to user for confirmation

**Out of Scope**:
- Implementation of the design (that's Item 3)
- Actual testing on projects (that's Item 4)
- Shell scripting details (focus on logic flow)

**Success Criteria**:
- [ ] User prompt flow documented with all questions
- [ ] Auto-detection heuristics specified for common project types
- [ ] Output templates designed (CLAUDE.md, etc.)
- [ ] Edge cases documented (conflicts, missing info, etc.)
- [ ] Design reviewed and approved

**Estimated Effort**: 1 day (spec 1h, design 4h, review/iterate 2h)

**Location**: `.project/active/init-discovery-design/`

**Dependencies**: Item 1 (audit findings inform design)

**Deliverables**:
- `.project/active/init-discovery-design/spec.md` - Design requirements
- `.project/active/init-discovery-design/design.md` - Full design document
- `.project/active/init-discovery-design/templates/` - Output templates

---

### Item 3: Enhanced Init Implementation [1-1.5 days]

**Type**: Implementation

**Objective**: Implement the enhanced initialization script with discovery flow and auto-detection.

**Current State**:
- ✅ Basic `init-project.sh` exists as starting point
- ❌ No interactive prompting
- ❌ No auto-detection logic
- ❌ No context generation

**Scope**:
1. **Interactive Prompting**:
   - Implement question flow from design
   - Handle user responses gracefully
   - Support non-interactive mode with defaults
2. **Auto-Detection**:
   - Implement heuristics from design
   - Test pattern matching logic
   - Provide fallbacks when detection fails
3. **Context Generation**:
   - Generate CLAUDE.md from template + discoveries
   - Set up .project/ with appropriate initial state
   - Handle existing files (merge, skip, overwrite prompts)
4. **User Experience**:
   - Clear output showing what was discovered/created
   - Summary of setup at end
   - Instructions for next steps

**Out of Scope**:
- Multi-project validation (that's Item 4)
- Supporting every possible project type
- IDE integrations

**Success Criteria**:
- [ ] Script prompts for essential project info
- [ ] Auto-detection works for Node, Python, Rust projects
- [ ] CLAUDE.md generated with useful context
- [ ] .project/ set up correctly
- [ ] Works on greenfield (empty) directories
- [ ] Works on existing repositories
- [ ] Clear user feedback throughout

**Estimated Effort**: 1-1.5 days (spec 1h, plan 1h, implement 6-8h, polish 2h)

**Location**: `.project/active/init-implementation/`

**Dependencies**: Item 2 (design must be complete)

**Deliverables**:
- `.project/active/init-implementation/spec.md` - Implementation requirements
- `.project/active/init-implementation/plan.md` - Implementation phases
- `init-project.sh` - Enhanced script (updated in place)
- Templates in `templates/` directory

---

### Item 4: Multi-Project Validation [0.5-1 day]

**Type**: Testing/Validation

**Objective**: Validate the enhanced init script works correctly across different project types and scenarios.

**Current State**:
- ❓ Unknown how script performs on real projects
- ❓ Unknown edge cases that may surface
- ❓ Unknown user experience issues

**Scope**:
1. **Test Matrix**:
   - Node.js project (package.json, npm/yarn)
   - Python project (pyproject.toml or requirements.txt)
   - Rust project (Cargo.toml)
   - Greenfield (empty directory)
   - Existing repo with code
   - Repo with existing .project/ directory
2. **Validation Criteria**:
   - Auto-detection accuracy
   - Generated CLAUDE.md quality
   - User prompt flow smoothness
   - Error handling
3. **Iteration**:
   - Document issues found
   - Fix critical bugs
   - Note improvements for future

**Out of Scope**:
- Supporting additional languages beyond test matrix
- Performance optimization
- CI/CD integration

**Success Criteria**:
- [ ] Tested on at least one project per type in matrix
- [ ] All critical bugs fixed
- [ ] Test results documented
- [ ] Known limitations documented
- [ ] Script ready for general use

**Estimated Effort**: 0.5-1 day (spec 0.5h, testing 3-4h, fixes 2h, documentation 1h)

**Location**: `.project/active/init-validation/`

**Dependencies**: Item 3 (implementation must be complete)

**Deliverables**:
- `.project/active/init-validation/spec.md` - Test plan
- `.project/active/init-validation/test-results.md` - Results and findings
- Bug fixes applied to `init-project.sh`

---

## Dependency Graph

```
Item 1: Audit ──────┐
                    ▼
               Item 2: Design ──────┐
                                    ▼
                              Item 3: Implementation ──────┐
                                                          ▼
                                                     Item 4: Validation
```

## Total Effort Summary

| Item | Type | Effort | Dependencies |
|------|------|--------|--------------|
| 1. Init Audit | Research | 0.5-1 day | None |
| 2. Discovery Design | Design | 1 day | Item 1 |
| 3. Implementation | Implementation | 1-1.5 days | Item 2 |
| 4. Validation | Testing | 0.5-1 day | Item 3 |
| **Total** | | **3-4.5 days** | |

---

## Notes

- Items are sequential due to natural dependencies
- Could potentially parallelize Item 1 research with some design thinking, but cleaner to keep sequential
- Item 3 is the largest and could be split further if it grows in scope during design
- Consider creating reusable detection utilities that could help other scripts
