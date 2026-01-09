# Init Script Audit Report

**Item**: Item 1 from EPIC-001 (Project Initialization Strategy)
**Completed**: 2025-12-30
**Status**: Complete

---

## Executive Summary

- **Current state**: `init-project.sh` is a functional but minimal script that copies template files without any project discovery or context capture
- **Architecture is sound**: The symlink-for-shared + copy-for-project-specific pattern correctly enables upstream edits and per-project customization
- **Critical gaps**: No interactive prompting, no project type detection, no CLAUDE.md generation, no context capture
- **Key opportunity**: Adding discovery flow would transform this from "file copier" to "intelligent project setup assistant"
- **Comparable tools** (npm init, cargo init, poetry init) provide proven patterns for interactive prompts, auto-detection, and handling existing projects

---

## Current Script Analysis

### Script Location & Invocation

- **Path**: `scripts/init-project.sh`
- **Invocation**: Run from target project root
- **Prerequisites**: Must be in a git repository (`git init` first)

### Execution Flow

```
1. Validate git repo exists
   └─ Exit with error if .git/ not found

2. Add template repo as submodule
   ├─ Uses $TEMPLATE_REPO_URL (env var with fallback)
   ├─ Creates claude-templates/ directory
   ├─ Runs: git submodule add + git submodule update --init --recursive
   └─ Skips if submodule already exists

3. Create .claude/ directory
   └─ mkdir -p .claude

4. Create symlinks (for shared content)
   ├─ .claude/commands → ../claude-templates/claude-pack/commands
   ├─ .claude/hooks    → ../claude-templates/claude-pack/hooks
   ├─ .claude/agents   → ../claude-templates/claude-pack/agents
   ├─ .claude/skills   → ../claude-templates/claude-pack/skills
   └─ .claude/rules    → ../claude-templates/claude-pack/rules

5. Copy .project/ (for project-specific content)
   ├─ cp -r claude-templates/claude-pack/project .project
   ├─ mkdir -p .project/research
   └─ mkdir -p .project/reports

6. Display success message and next steps
```

### Strengths

| Aspect | Implementation | Notes |
|--------|----------------|-------|
| **Git validation** | Checks for `.git/` directory | Clear error message on failure |
| **Submodule safety** | Checks if submodule exists before adding | Prevents duplicate submodule errors |
| **Symlink safety** | Checks for existing symlinks AND non-symlink paths | Warns but doesn't overwrite |
| **Colored output** | Uses RED/GREEN/YELLOW ANSI codes | Good visual feedback |
| **Idempotent** | Can re-run without breaking | Skips existing items gracefully |
| **Configurable** | `TEMPLATE_REPO_URL` env var | Allows custom template sources |

### Architecture Validation

**Requirement 1**: `.project/` should be actively used by all projects
- **Status**: ✅ Correctly implemented
- **How**: `.project/` is **copied** (not symlinked), giving each project its own instance
- **Location**: Lines 67-76 of init-project.sh

**Requirement 2**: Editing `.claude/commands/*.md` should modify upstream
- **Status**: ✅ Correctly implemented
- **How**: `.claude/commands/` is a **symlink** pointing to the submodule
- **Effect**: Edits propagate to `claude-templates/claude-pack/commands/`
- **Location**: Lines 58-62 of init-project.sh

### Edge Case Handling

| Scenario | Current Behavior |
|----------|------------------|
| Not in git repo | ❌ Exits with error |
| Submodule already exists | ⚠️ Warns, skips submodule add |
| Symlink already exists | ⚠️ Warns, skips symlink creation |
| Non-symlink file at target | ⚠️ Warns, asks user to manually resolve |
| .project/ already exists | ⚠️ Warns, skips copy entirely |
| Script interrupted mid-run | ❌ No rollback, partial state possible |
| No network (submodule fetch fails) | ❌ Exits on error (set -e) |
| Wrong directory (not project root) | ❌ No detection, proceeds anyway |

---

## Template Files Inventory

### Claude Configuration (Symlinked)

#### Commands (`claude-pack/commands/`) - 7 files

| File | Purpose | Dependencies |
|------|---------|--------------|
| `capture.md` | Mark conversation for later review | `capture.sh`, `query-transcript.py` |
| `memorize.md` | Create structured memory from transcript | `parse-transcript.py`, `index.json` |
| `project-manage.md` | Project status, decompose epics, close items | All `.project/` files |
| `project-find.md` | Quick context lookup by topic | `.project/` files |
| `recall.md` | Search past conversations | Spawns `recall.md` agent |
| `review-compact.md` | Review auto-compacted transcripts | `parse-transcript.py`, `index.json` |
| `example-command.md` | Template for custom commands | None |

#### Hooks (`claude-pack/hooks/`) - 4 files

| File | Purpose | Type |
|------|---------|------|
| `capture.sh` | Create capture file, update index.json | Bash (2.4KB) |
| `parse-transcript.py` | Parse JSONL transcripts to markdown | Python (6.8KB) |
| `query-transcript.py` | Search/filter transcripts | Python (12.4KB) |
| `precompact-capture.sh` | PreCompact hook wrapper | Bash (151B) |

#### Agents (`claude-pack/agents/`) - 2 files

| File | Purpose |
|------|---------|
| `recall.md` | Research agent for transcript search |
| `example-agent.md` | Template for custom agents |

#### Rules (`claude-pack/rules/`) - 1 file

| File | Purpose |
|------|---------|
| `example-rules.md` | Template with code style, testing, docs guidelines |

#### Skills (`claude-pack/skills/`) - 1 file

| File | Purpose |
|------|---------|
| `example-skill.md` | Template for specialized capabilities |

### Project Management (Copied)

#### Root Files (`claude-pack/project/`)

| File | Purpose |
|------|---------|
| `README.md` | Workflow overview and quick reference |
| `CURRENT_WORK.md` | Active work tracking template |
| `EPIC_GUIDE.md` | Epic decomposition methodology |
| `epic_template.md` | Template for new epics |

#### Subdirectories

| Directory | Contents | Purpose |
|-----------|----------|---------|
| `backlog/` | `BACKLOG.md`, `README.md` | Prioritized epic list |
| `active/` | `README.md` | Work-in-progress item folders |
| `completed/` | `CHANGELOG.md`, `README.md` | Archived completed work |
| `memories/` | `SPEC.md`, `index.json` | Conversation captures |

### Additional Directories Created

| Directory | Purpose |
|-----------|---------|
| `.project/research/` | Analysis artifacts (created empty) |
| `.project/reports/` | Status reports (created empty) |

---

## Gap Analysis

### Epic Requirements vs Current State

| Requirement | Current State | Gap Severity |
|-------------|---------------|--------------|
| Init handles greenfield projects | ⚠️ Partial - works but no guidance | Medium |
| Init handles existing projects | ⚠️ Partial - works but no detection | High |
| Project context captured | ❌ Not implemented | **Critical** |
| User understands what was set up | ⚠️ Minimal - shows next steps only | Medium |
| Works across project types | ❌ No project type awareness | High |
| Auto-detects project structure | ❌ Not implemented | **Critical** |
| Generates useful CLAUDE.md | ❌ Not implemented | **Critical** |

### Missing Capabilities (Prioritized)

#### P0 - Critical (Blocking epic success)

1. **CLAUDE.md Generation**
   - No CLAUDE.md is created
   - Projects have no Claude-specific guidance
   - Example in `artifacts/` shows what good looks like

2. **Project Context Capture**
   - No questions asked about project purpose
   - No discovery of project conventions
   - No capture of where things live

3. **Project Type Detection**
   - No detection of Node/Python/Rust/etc.
   - No awareness of build systems
   - No recognition of test locations

#### P1 - High (Significant impact)

4. **Interactive Prompting**
   - No project name prompt (could default to directory)
   - No description prompt
   - No conventions/preferences questions

5. **Test Directory Detection**
   - Common patterns: `tests/`, `test/`, `__tests__/`, `spec/`
   - File patterns: `*.test.ts`, `*_test.py`, `*_spec.rb`

6. **Documentation Detection**
   - Look for: `docs/`, `documentation/`, `README.md`, `CONTRIBUTING.md`

7. **Build System Detection**
   - `package.json` → Node.js (npm/yarn/pnpm)
   - `Cargo.toml` → Rust
   - `pyproject.toml` / `requirements.txt` → Python
   - `go.mod` → Go
   - `Makefile` → General build

#### P2 - Medium (Nice to have)

8. **Non-Interactive Mode**
   - Flag for CI/automation: `--yes` or `-y`
   - Use sensible defaults when no TTY

9. **Discovery Confirmation**
   - Show what was detected
   - Allow user to correct before proceeding

10. **Existing Content Handling**
    - Merge strategies for existing `.project/`
    - Preserve user customizations

11. **Summary Output**
    - Show all files created/linked
    - Highlight key customization points

---

## Comparable Tools Analysis

### npm init / npm create

**Source**: [npm init documentation](https://commandmasters.com/commands/npm-init-common/), [Building npm create packages](https://www.alexchantastic.com/building-an-npm-create-package)

| Aspect | Approach |
|--------|----------|
| **Prompts** | Name, version, description, entry point, test command, git repo, keywords, license |
| **Defaults** | Directory name for package name, 1.0.0 for version, ISC for license |
| **Quick mode** | `npm init --yes` skips all prompts, uses defaults |
| **Customization** | `npm config set init.author.name "Name"` for persistent defaults |
| **Output** | Generates `package.json` with answers |

**Patterns to adopt**:
- Default project name to directory name
- Offer `--yes` flag for non-interactive mode
- Allow persistent user defaults via config

### cargo init / cargo new

**Source**: [Cargo init documentation](https://doc.rust-lang.org/cargo/commands/cargo-init.html), [Project Creation DeepWiki](https://deepwiki.com/rust-lang/cargo/6.2-project-creation)

| Aspect | Approach |
|--------|----------|
| **Auto-detection** | Checks for `src/main.rs` vs `src/lib.rs` to determine binary vs library |
| **Existing files** | Scans for `fn main` in existing `.rs` files to infer project type |
| **VCS detection** | Detects existing `.git/`, appends to existing `.gitignore` |
| **Existing project** | Can initialize Cargo in pre-existing non-Cargo directories |
| **Error on conflict** | Refuses to run if `Cargo.toml` already exists |

**Patterns to adopt**:
- Auto-detect project type from existing files
- Append to existing ignore files rather than overwriting
- Intelligent handling of existing projects (enhance, don't replace)
- Refuse to overwrite critical files, offer merge instead

### poetry init

**Source**: [Poetry basic usage](https://python-poetry.org/docs/basic-usage/), [Poetry CLI commands](https://python-poetry.org/docs/cli/)

| Aspect | Approach |
|--------|----------|
| **Existing projects** | `poetry init` specifically designed for pre-existing directories |
| **Interactive session** | Walks through all pyproject.toml fields |
| **Suggestions** | Offers defaults, Enter accepts |
| **Preview** | Shows generated file before writing |
| **Confirmation** | User confirms before file is created |

**Patterns to adopt**:
- Preview generated files before writing
- Offer suggestions with defaults
- Explicit confirmation before writes
- Design specifically for existing project initialization

### General Patterns Observed

| Pattern | Used By | Applicability |
|---------|---------|---------------|
| Directory name as default project name | npm, cargo, poetry | High - easy win |
| `--yes` flag for non-interactive | npm, yarn | High - CI/automation |
| Auto-detect from existing files | cargo | High - reduces questions |
| Preview before writing | poetry | Medium - builds confidence |
| Append to existing files | cargo (.gitignore) | Medium - plays nice with existing |
| Persistent user defaults | npm (npm config) | Low - complex for v1 |

### Anti-Patterns to Avoid

| Anti-Pattern | Why |
|--------------|-----|
| Overwriting without warning | Destroys user work |
| Assuming empty directory | Real projects have files |
| No way to skip prompts | Blocks automation |
| Silent failures | User doesn't know what happened |
| Too many questions upfront | Analysis paralysis |
| No escape hatch | User trapped in flow |

---

## Recommendations for Item 2

### Must-Have Features (P0)

1. **CLAUDE.md Generation**
   - Template-based generation with discovered context
   - Sections: Project Overview, Development Setup, Essential Commands, Architecture
   - Use `artifacts/agentic_codebase_template/CLAUDE.md` as reference

2. **Project Type Detection**
   - Check for presence of: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`
   - Map to project type and common conventions
   - Inform template selection

3. **Basic Prompts**
   - Project name (default: directory name)
   - Brief description
   - Confirmation of detected project type

4. **Discovery Confirmation**
   - Show detected: project type, test location, docs location, build commands
   - Allow user to correct/override

### Should-Have Features (P1)

5. **Test Directory Detection**
   - Scan for common patterns
   - Populate CLAUDE.md with test command

6. **Non-Interactive Mode**
   - `--yes` flag uses all defaults
   - `--quiet` reduces output

7. **Build Command Detection**
   - Extract from package.json scripts, Makefile targets, etc.
   - Include in CLAUDE.md

8. **Summary Output**
   - List all files created/modified
   - Highlight what to customize

### Could-Have Features (P2)

9. **Existing `.project/` Merge**
   - Detect existing, offer: skip, merge, overwrite
   - Preserve user customizations

10. **Config Detection**
    - Find: `.eslintrc`, `tsconfig.json`, `mypy.ini`, etc.
    - Note code style preferences in CLAUDE.md

11. **README.md Parsing**
    - Extract project description if available
    - Use as default for prompts

### Implementation Considerations

#### Technical Constraints

- Script should remain pure Bash (no Python/Node dependencies for init)
- Must work on macOS and Linux
- Should complete in < 30 seconds even for large repos

#### Design Decisions Needed

1. **Detection depth**: How many directories deep to scan?
2. **Prompt ordering**: What to ask first vs auto-detect?
3. **Override mechanism**: How to correct auto-detection?
4. **Template variants**: One CLAUDE.md template or per-project-type?
5. **Existing project behavior**: Enhance existing or require clean state?

#### Risks

| Risk | Mitigation |
|------|------------|
| Over-detection (false positives) | Always confirm with user |
| Under-detection (misses things) | Allow manual override |
| Slow on large repos | Limit scan depth, exclude node_modules/vendor |
| Bash limitations | Keep logic simple, defer complex parsing |

---

## Appendix: Script Behavior Reference

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `TEMPLATE_REPO_URL` | `git@github.com:yourusername/claude-agentic-templates.git` | Template repository URL |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Not in git repository |
| 1 | Submodule add failed |
| 1 | Any command failure (set -e) |

### Files Created/Modified

| Path | Type | Action |
|------|------|--------|
| `claude-templates/` | Directory | Submodule clone |
| `.claude/` | Directory | Created |
| `.claude/commands` | Symlink | Created |
| `.claude/hooks` | Symlink | Created |
| `.claude/agents` | Symlink | Created |
| `.claude/skills` | Symlink | Created |
| `.claude/rules` | Symlink | Created |
| `.project/` | Directory tree | Copied from template |
| `.project/research/` | Directory | Created empty |
| `.project/reports/` | Directory | Created empty |

---

## Sources

- [npm init examples](https://commandmasters.com/commands/npm-init-common/)
- [Building npm create packages](https://www.alexchantastic.com/building-an-npm-create-package)
- [Cargo init documentation](https://doc.rust-lang.org/cargo/commands/cargo-init.html)
- [Cargo project creation](https://deepwiki.com/rust-lang/cargo/6.2-project-creation)
- [Poetry basic usage](https://python-poetry.org/docs/basic-usage/)
- [Poetry CLI commands](https://python-poetry.org/docs/cli/)
