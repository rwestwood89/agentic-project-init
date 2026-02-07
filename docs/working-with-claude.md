# Working with Claude Code

A practical guide for effective collaboration with Claude Code using the agentic-project-init workflow system.

## Quick Reference

| Situation | Command | When to Use |
|-----------|---------|-------------|
| Non-trivial task | `/_my_plan` | Multiple files, unclear scope, architectural decisions |
| Understand codebase | `/_my_research` | Deep exploration, feasibility analysis |
| New feature | Full workflow | Spec → Design → Plan → Implement |
| Bug fix (obvious) | Just fix it | Clear cause, single file, explicit instructions |
| Small change | `/_my_quick_edit` | Too small for full workflow, needs some planning |
| After correction | `/_my_capture` | User corrects you, important learning moment |
| Before session | `/_my_recall` | Need context from past conversations |
| Verify implementation | `/_my_audit_implementation` | Check completed phases against plan |
| Review against spec | `/_my_code_review` | Verify requirements are met |
| Run quality checks | `/_my_code_quality` | Lint, format, tests passing |

---

## When to Plan vs Just Do

### Use Full Workflow (Spec → Design → Plan → Implement)

**Architectural decisions required:**
- New subsystem or service
- Database schema changes
- API design
- Authentication/authorization changes

**Multi-file changes:**
- Feature touches 3+ files
- Requires integration across components
- Changes existing interfaces

**Unclear scope or requirements:**
- "Make it better" or "improve performance"
- User describes outcome, not approach
- Multiple valid solutions exist

**Complex logic:**
- Business rules with edge cases
- Data transformations
- State management changes

### Skip to Implementation

**Obvious fixes:**
- Typos, formatting, syntax errors
- Clear bug with visible root cause
- Stack trace points directly to issue

**Single-file, localized changes:**
- Add a log statement
- Change a constant or config value
- Fix an off-by-one error

**Explicit instructions:**
- User provides exact code to write
- User specifies file and line
- Change is mechanical, not creative

**Use `/_my_quick_edit` for:**
- Small features (1-3 files)
- Clear requirements but some planning needed
- Changes too small for full workflow but not trivial

---

## Agent Strategy

### Offload to Subagents

**Use `/_my_research` or `Task(Explore)` for:**
- Finding all files related to a concept
- Understanding how a feature works
- Locating existing patterns to follow
- Discovering integration points

**Use `Task(Plan)` for:**
- Evaluating design alternatives
- Architectural trade-off analysis
- Risk assessment

**Use parallel agents for:**
- Independent searches across codebase areas
- Comparing multiple approaches
- Gathering context from unrelated components

### Keep in Main Context

**Execution and edits:**
- File modifications go through main agent
- User sees changes in real-time
- Easier to course-correct

**User interaction:**
- Clarifying questions
- Approval gates
- Progress updates

**Final verification:**
- Running tests
- Checking results
- Confirming completion

---

## Learning Loop

```
User corrects you or provides important context
    ↓
/_my_capture              Mark conversation for later
    ↓
/_my_memorize             Create structured memory artifact
    ↓
[End of session]
    ↓
/_my_wrap_up              Update CURRENT_WORK.md, MEMORY.md, docs
    ↓
[Next session]
    ↓
(auto-loaded)             CLAUDE.md → MEMORY.md → .claude/rules/
    ↓
(read on demand)          .project/CURRENT_WORK.md (pointed to by CLAUDE.md)
```

### Session Start (Auto-Context)

Claude Code auto-loads three context sources every session:
1. **CLAUDE.md** — project orientation and "Session Start" pointers
2. **Auto-memory** (`~/.claude/projects/*/memory/MEMORY.md`) — distilled working knowledge
3. **`.claude/rules/`** — behavioral rules (including context-loading rule)

Everything else (`.project/`, `docs/`, code) requires Claude to discover and read it. The "Session Start" section in CLAUDE.md bridges this gap by telling Claude what to read first.

### When to Wrap Up (`/_my_wrap_up`)

- End of a work session
- After completing significant work
- After discovering a gotcha that shouldn't burn time again
- When the user says "update docs", "save context", or similar

### When to Capture (`/_my_capture`)

- User corrects a mistake you made
- Project-specific convention discovered
- Important decision made
- Complex problem solved
- User provides context that should persist

### When to Recall (`/_my_recall`)

- Starting work on an area you've touched before
- User references "what we discussed"
- Need to understand prior decisions
- Looking for patterns you've seen

---

## Verification Gates

Before marking work complete, verify:

### `/_my_audit_implementation`
- Do completed phases match the plan?
- Any placeholder code or TODOs remaining?
- Deviations documented and justified?

### `/_my_code_review`
- Requirements traced to implementation?
- Edge cases from spec handled?
- Tests cover acceptance criteria?

### `/_my_code_quality`
- Linting passes?
- Tests pass?
- Formatting correct?

### Show Proof, Not Claims

Instead of:
> "I've implemented the feature and it should work."

Provide:
> "Implementation complete. Tests passing (15/15). Verified edge cases X, Y, Z at `file.py:123-145`."

---

## Autonomous Execution

### Just Fix (Don't Ask)

**Clear evidence:**
- Error message or stack trace visible
- Failing test with obvious cause
- Log shows specific failure point

**Explicit delegation:**
- User says "fix it" or "handle it"
- User says "do what makes sense"
- User approved a plan, now executing

**Bounded scope:**
- Fix stays within mentioned files
- No architectural implications
- No side effects on other features

### Ask First

**Multiple valid approaches:**
- "We could use A or B, which do you prefer?"
- Different performance/simplicity trade-offs
- Library choice matters

**Architectural implications:**
- Change affects other components
- Creates new patterns or precedents
- Adds dependencies

**Scope uncertainty:**
- Root cause unclear
- Fix might require larger changes
- Side effects possible

**Outside the immediate task:**
- Noticed related bug
- Opportunity to refactor
- "While we're here" improvements

---

## Workflow Reference

```
/_my_spec       →  WHAT: Requirements, acceptance criteria, scope
/_my_design     →  HOW: Technical approach, alternatives, decisions
/_my_plan       →  WHEN: Phased execution, validation strategy
/_my_implement  →  DO: Execute with progress tracking
/_my_code_review → CHECK: Audit against spec/design
```

### Abbreviated Flow (`/_my_quick_edit`)

```
Understand → Propose → [Plan] → Execute → Review
```

Use when full workflow is overkill but you still need structure.

### Skip-to-Fix Flow

```
Read error → Identify cause → Fix → Verify → Done
```

Use for obvious bugs with clear root cause.

---

## Tips

### Read Before Writing
Never propose changes to code you haven't read. Even for "obvious" fixes, verify assumptions.

### Prefer Editing Over Creating
Most tasks involve modifying existing code, not creating new files. Understand the existing patterns first.

### Stay Focused
Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up.

### Trust but Verify
After making changes, verify they work. Run tests, check output, trace execution paths.

### Document Surprises
If implementation deviates from plan, document why in the plan.md or change.md file.

---

## Related Resources

- **Command Reference:** See individual `/_my_*` command documentation in `claude-pack/commands/`
- **Project Management:** `.project/` directory contains active work, backlog, and completed items
- **Memory System:** `.project/memories/` stores captured learnings and session summaries
