# Init Script Audit & Gap Analysis Spec

**Item**: Item 1 from EPIC-001 (Project Initialization Strategy)
**Type**: Research
**Created**: 2025-12-30
**Status**: Spec Complete

---

## Objective

Document the current `init-project.sh` capabilities comprehensively and identify specific gaps that need addressing to achieve the epic's vision of intelligent project discovery and context capture.

---

## Audit Scope

### 1. Current Script Behavior Analysis

Document the complete behavior of `scripts/init-project.sh`:

| Aspect | What to Document |
|--------|------------------|
| **Prerequisites** | Git repo requirements, environment variables, dependencies |
| **Submodule Setup** | URL handling, existing submodule detection, error scenarios |
| **Symlink Creation** | What gets linked, safety checks, conflict handling |
| **File Copying** | What's copied vs linked, directory creation |
| **User Output** | Messages shown, colors, progress indicators |
| **Exit Behavior** | Success/failure paths, cleanup on failure |
| **Edge Cases** | Existing files, partial runs, re-runs |

### 2. Template Files Inventory

Create a complete inventory of distributed template files:

```
claude-pack/
├── commands/    → [list each file with purpose]
├── hooks/       → [list each file with purpose]
├── agents/      → [list each file with purpose]
├── rules/       → [list each file with purpose]
├── skills/      → [list each file with purpose]
└── project/     → [list each file with purpose]
```

For each file, document:
- Purpose/function
- Dependencies on other files
- Customization points (what users might modify)

### 3. Gap Analysis

Compare current state against epic requirements:

| Epic Requirement | Current State | Gap |
|------------------|---------------|-----|
| Handles greenfield projects | ? | ? |
| Handles existing projects | ? | ? |
| Captures project context | ? | ? |
| Auto-detects project structure | ? | ? |
| Generates useful CLAUDE.md | ? | ? |
| Works across project types | ? | ? |

Identify specific missing capabilities:
- [ ] Interactive prompting for project info
- [ ] Project type detection (Node, Python, Rust, etc.)
- [ ] Test directory detection
- [ ] Build system detection
- [ ] Documentation location detection
- [ ] CLAUDE.md generation with context
- [ ] Existing project analysis
- [ ] User confirmation of discoveries
- [ ] Non-interactive mode with defaults

### 4. Comparable Tools Research

Analyze initialization approaches from:

| Tool | What to Study |
|------|---------------|
| `npm init` / `npm create` | Interactive prompts, defaults, config generation |
| `cargo init` / `cargo new` | Project structure detection, template generation |
| `python -m venv` / `poetry init` | Environment setup, dependency detection |
| `create-react-app` | Template selection, post-install instructions |
| `git init` | Minimal setup philosophy |
| `gh repo create` | Interactive flow, API integration |

For each tool, document:
- Interactive vs non-interactive modes
- What questions they ask
- What they auto-detect
- How they handle existing content
- Post-init guidance provided

---

## Deliverables

### 1. Audit Report (`audit-report.md`)

Structure:
```markdown
# Init Script Audit Report

## Executive Summary
[Key findings in 3-5 bullets]

## Current Script Analysis
### Behavior Documentation
[Detailed walkthrough of what the script does]

### Template Inventory
[Complete file listing with purposes]

### Strengths
[What the current script does well]

### Edge Case Handling
[How various scenarios are handled]

## Gap Analysis
### Missing vs Epic Requirements
[Table comparing current state to requirements]

### Prioritized Gap List
[Ordered by importance for Item 2 design]

### User Experience Gaps
[Friction points, missing feedback, confusion areas]

## Comparable Tools Analysis
### Patterns Worth Adopting
[Best practices from other tools]

### Anti-patterns to Avoid
[What not to do based on research]

## Recommendations for Item 2
### Must-Have Features
[Critical for MVP]

### Should-Have Features
[Important but not blocking]

### Could-Have Features
[Nice to have if time permits]

### Implementation Considerations
[Technical constraints, dependencies, risks]
```

---

## Success Criteria

- [ ] Current script behavior documented with sufficient detail that someone unfamiliar could understand exactly what it does
- [ ] All template files inventoried with clear purposes
- [ ] Gap analysis clearly maps current state to epic requirements
- [ ] At least 4 comparable tools researched with actionable insights
- [ ] Recommendations are specific and actionable for Item 2 design
- [ ] Report is structured for easy reference during design phase

---

## Methodology

### Phase 1: Script Analysis (1-2 hours)
1. Read `init-project.sh` line by line
2. Trace execution paths for success and failure
3. Test edge cases (re-run, existing files, missing git)
4. Document all behaviors observed

### Phase 2: Template Inventory (1 hour)
1. List all files in `claude-pack/`
2. Read each file and summarize purpose
3. Map dependencies between files
4. Note customization points

### Phase 3: Gap Analysis (1 hour)
1. List epic requirements from `epic_init_strategy.md`
2. Check each against current capabilities
3. Identify and categorize gaps
4. Prioritize by impact on epic goals

### Phase 4: Research (1-2 hours)
1. Run/explore comparable init tools
2. Document their approaches
3. Identify patterns and anti-patterns
4. Extract applicable insights

### Phase 5: Report Writing (1 hour)
1. Compile findings into structured report
2. Synthesize recommendations
3. Review for completeness
4. Format for readability

---

## Out of Scope

Per epic definition, this item does NOT include:
- Implementing any changes to the script
- Detailed design of new features (that's Item 2)
- Testing on multiple project types (that's Item 4)
- Writing code or making PRs

---

## Notes

### Current Script Quick Reference

**Location**: `scripts/init-project.sh`

**What it does today**:
1. Validates git repo exists
2. Adds template repo as git submodule (`claude-templates/`)
3. Creates `.claude/` directory
4. Symlinks: commands, hooks, agents, skills, rules → submodule
5. Copies: `claude-pack/project/` → `.project/`
6. Creates: `.project/research/`, `.project/reports/`

**Key gaps evident from initial review**:
- No interactive prompting
- No project type detection
- No CLAUDE.md generation
- No context capture
- Hard-coded submodule URL pattern
- No greenfield vs existing project handling
- No summary of what was discovered/configured

---

## Related Files

- Epic: `.project/backlog/epic_init_strategy.md`
- Script: `scripts/init-project.sh`
- Templates: `claude-pack/`
- Update script: `scripts/update-templates.sh`
