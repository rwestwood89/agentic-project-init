---
date: 2026-04-18T08:30:15-04:00
researcher: Claude
topic: "Codex CLI compatibility mapping for claude-pack"
tags: [research, codex, compatibility, installation]
status: complete
last_updated: 2026-04-18
---

# Research: Codex CLI Compatibility Mapping for claude-pack

**Date**: 2026-04-18 08:30:15 EDT
**Researcher**: Claude
**Research Type**: Architecture / Integration

## Research Question

How does OpenAI Codex CLI compare to Claude Code for skills, commands, subagents, and other features in this repo? What's supported, what's not, and how could we create a Codex-focused installation script?

## Summary

- **Commands → Skills**: Claude Code commands map to Codex skills with format changes (SKILL.md frontmatter)
- **Agents → Subagents**: Similar concept but different config (TOML vs markdown frontmatter)
- **Hooks → Hooks**: Both support event hooks with similar lifecycle events
- **Rules → AGENTS.md**: Claude's `rules/` maps to Codex's `AGENTS.md` (global + project)
- **MCP → MCP**: Both support MCP servers with different config formats (JSON vs TOML)

---

## Feature Mapping Matrix

| Claude Code Feature | Codex CLI Equivalent | Supported? | Notes |
|---------------------|---------------------|------------|-------|
| **Commands** (`~/.claude/commands/*.md`) | **Skills** (`~/.codex/skills/**/SKILL.md`) | ✅ Partial | Different frontmatter format |
| **Agents** (`~/.claude/agents/*.md`) | **Subagents** (config.toml `[agents.*]`) | ✅ Partial | TOML config, not markdown files |
| **Hooks** (`~/.claude/hooks/`) | **Hooks** (`hooks.json`) | ✅ Yes | JSON config instead of settings.json |
| **Rules** (`~/.claude/rules/*.md`) | **AGENTS.md** | ✅ Yes | Single file vs directory of files |
| **Skills** (`~/.claude/skills/*.md`) | **Skills** (`~/.codex/skills/**/SKILL.md`) | ✅ Yes | Same concept, different structure |
| **MCP Servers** (settings.json) | **MCP Servers** (config.toml) | ✅ Yes | TOML instead of JSON |
| **settings.json** | **config.toml** | ✅ Yes | Different format, similar options |
| **CLAUDE.md** | **AGENTS.md** | ✅ Yes | Equivalent project instructions |
| **Auto-memory** (`~/.claude/projects/*/memory/`) | N/A | ❌ No | No built-in memory system |
| **Slash commands** (`/command`) | **Slash commands** (`/command`) | ✅ Yes | Built-in commands differ |

---

## Detailed Findings

### 1. Commands → Skills Conversion

**Claude Code Command Format** (`.claude/commands/_my_spec.md`):
```markdown
---
description: Spec Command
---

[Command instructions...]
```

**Codex Skill Format** (`.codex/skills/spec/SKILL.md`):
```markdown
---
name: spec
description: Creates a specification document for a feature. Use when user says "write a spec", "create requirements", or wants to document feature requirements.
---

[Skill instructions...]
```

**Key Differences**:
- Codex requires `name` field (Claude infers from filename)
- Codex `description` is the **primary trigger mechanism** - must include "when to use" hints
- Codex skills must be in a **subdirectory** with exactly `SKILL.md` filename
- Codex loads skill body **only after triggering** (Claude loads on startup)

**Conversion Required**:
- Rename files: `_my_spec.md` → `spec/SKILL.md`
- Add `name` field to frontmatter
- Move trigger hints from body to `description` field

---

### 2. Agents → Subagents Conversion

**Claude Code Agent Format** (`.claude/agents/recall.md`):
```markdown
---
name: recall
description: Research agent for searching past conversations
tools: ["Read", "Grep", "Glob", "Bash"]
---

[Agent instructions...]
```

**Codex Subagent Configuration** (`config.toml`):
```toml
[agents.recall]
description = "Research agent for searching past conversations"
model = "gpt-4.1"
sandbox_mode = "read-only"
# Instructions in separate AGENTS.md or inline
```

**Key Differences**:
- Codex agents are defined in `config.toml`, not markdown files
- Tool restrictions are handled via `sandbox_mode` rather than explicit tool lists
- Instructions can be in AGENTS.md or referenced files
- Codex supports `max_agent_threads` (default 6), `max_agent_depth` (default 1)

**Conversion Required**:
- Extract agent configs to TOML format
- Map `tools` array to appropriate `sandbox_mode`
- Agent instructions may need separate file or inline embedding

---

### 3. Hooks Conversion

**Claude Code Hooks** (settings.json):
```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "auto",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/precompact-capture.sh"
      }]
    }]
  }
}
```

**Codex Hooks** (hooks.json):
```json
{
  "hooks": [{
    "event": "Stop",
    "matcher": "*",
    "command": ["~/.codex/hooks/capture.sh"]
  }]
}
```

**Supported Events Comparison**:

| Claude Code Event | Codex Event | Notes |
|-------------------|-------------|-------|
| PreCompact | Stop | Similar - session ending |
| PreToolUse | PreToolUse | ✅ Same |
| PostToolUse | PostToolUse | ✅ Same |
| UserPromptSubmit | UserPromptSubmit | ✅ Same |
| N/A | SessionStart | Codex-only |

**Conversion Required**:
- Convert JSON structure (different schema)
- Map `PreCompact` → `Stop` event
- Hook scripts receive JSON on stdin in both systems

---

### 4. Rules → AGENTS.md Conversion

**Claude Code Rules** (multiple files in `~/.claude/rules/`):
```
rules/
├── context-loading.md
├── example-rules.md
└── workflow-accountability.md
```

**Codex AGENTS.md** (single file with sections):
```markdown
# AGENTS.md

## Context Loading
[content from context-loading.md]

## Code Style Guidelines
[content from example-rules.md]

## Workflow Accountability
[content from workflow-accountability.md]
```

**Key Differences**:
- Codex uses single `AGENTS.md` file (or `AGENTS.override.md`)
- Claude allows multiple `.md` files in rules directory
- Codex supports hierarchy: `~/.codex/AGENTS.md` (global) + `.codex/AGENTS.md` (project)
- Codex also supports `TEAM_GUIDE.md` and `.agents.md` filenames

**Conversion Required**:
- Concatenate all rules files into single AGENTS.md
- Use markdown sections to organize content
- Place global rules in `~/.codex/AGENTS.md`

---

### 5. MCP Server Configuration

**Claude Code** (settings.json):
```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["@anthropic/mcp-slack"]
    }
  }
}
```

**Codex** (config.toml):
```toml
[mcp_servers.slack]
command = "npx @anthropic/mcp-slack"
startup_timeout_sec = 10
tool_timeout_sec = 60
enabled = true
```

**Conversion Required**:
- Convert JSON to TOML format
- Combine `command` + `args` into single command string
- Add Codex-specific options (timeouts, enabled flag)

---

### 6. Project Pack (.project/) Compatibility

The `.project/` directory structure is **tool-agnostic** and works with both:

| Component | Claude Code | Codex | Notes |
|-----------|-------------|-------|-------|
| `CURRENT_WORK.md` | ✅ | ✅ | Both can read markdown |
| `active/`, `backlog/`, `completed/` | ✅ | ✅ | Directory structure agnostic |
| `research/` | ✅ | ✅ | Same |
| `memories/` | ✅ | ⚠️ | Codex lacks memory system - may need custom skill |
| `scripts/get-metadata.sh` | ✅ | ✅ | Shell scripts work in both |

---

### 7. Features WITHOUT Codex Equivalent

| Claude Code Feature | Alternative for Codex |
|---------------------|----------------------|
| **Auto-memory** | Custom skill + local storage |
| **Transcript hooks** (`query-transcript.py`) | Need to replicate with Codex session APIs |
| **`/_my_recall`** (search past conversations) | Would need custom MCP server or skill |
| **`/_my_memorize`** | Custom skill writing to `.project/memories/` |
| **`/_my_capture`** | Hook on `Stop` event to save context |

---

## Codex-Focused Installation Script Outline

### Directory Structure

```
codex-pack/                    # Parallel to claude-pack/
├── skills/                    # Commands converted to skills
│   ├── spec/SKILL.md
│   ├── design/SKILL.md
│   ├── plan/SKILL.md
│   ├── implement/SKILL.md
│   ├── research/SKILL.md
│   ├── code-quality/SKILL.md
│   ├── code-review/SKILL.md
│   ├── git-manage/SKILL.md
│   ├── project-manage/SKILL.md
│   ├── quick-edit/SKILL.md
│   ├── wrap-up/SKILL.md
│   └── ...
├── hooks/                     # Same scripts, different config
│   ├── capture.sh
│   └── precompact-capture.sh
├── config/                    # Config templates
│   ├── config.toml           # Base config with agents
│   └── hooks.json            # Hook definitions
├── AGENTS.md                  # Consolidated rules
└── scripts/
    └── convert-command.sh    # Helper to convert claude → codex format
```

### setup-codex-global.sh Script Outline

```bash
#!/bin/bash
# Codex Pack Global Setup
# Installs skills, hooks, config to ~/.codex/

set -e

TARGET_DIR="$HOME/.codex"

# 1. Create directory structure
mkdir -p "$TARGET_DIR"/{skills,hooks,rules}

# 2. Copy/symlink skills (each in subdirectory)
for skill_dir in "$CODEX_PACK"/skills/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$TARGET_DIR/skills/$skill_name"
    ln -sf "$skill_dir/SKILL.md" "$TARGET_DIR/skills/$skill_name/SKILL.md"
done

# 3. Copy hooks
cp "$CODEX_PACK"/hooks/* "$TARGET_DIR/hooks/"

# 4. Merge config.toml
if [ -f "$TARGET_DIR/config.toml" ]; then
    # Merge with existing (needs toml-merge tool or manual)
    echo "Existing config.toml found - manual merge required"
else
    cp "$CODEX_PACK/config/config.toml" "$TARGET_DIR/config.toml"
fi

# 5. Configure hooks.json
# Place in appropriate location (global or project)
cp "$CODEX_PACK/config/hooks.json" "$TARGET_DIR/hooks.json"

# 6. Install AGENTS.md (global instructions)
if [ ! -f "$TARGET_DIR/AGENTS.md" ]; then
    cp "$CODEX_PACK/AGENTS.md" "$TARGET_DIR/AGENTS.md"
fi

echo "Codex Pack installed to $TARGET_DIR"
echo "Restart Codex to pick up new skills"
```

### init-project-codex.sh Script Outline

```bash
#!/bin/bash
# Initialize project for Codex

# 1. Copy .project/ (same as Claude version)
cp -r "$PROJECT_PACK" .project

# 2. Create .codex/ if vendoring
if [ "$INCLUDE_CODEX" = true ]; then
    mkdir -p .codex/{skills,hooks}
    # Copy skills to .codex/skills/
    # Copy hooks to .codex/hooks/
fi

# 3. Create AGENTS.md (instead of CLAUDE.md)
if [ ! -f "AGENTS.md" ]; then
    echo "# AGENTS.md" > AGENTS.md
    echo "" >> AGENTS.md
    echo "Project instructions for Codex." >> AGENTS.md
fi
```

### Command Conversion Script

```bash
#!/bin/bash
# convert-command.sh: Convert Claude command to Codex skill

INPUT="$1"  # e.g., _my_spec.md
OUTPUT_DIR="$2"  # e.g., codex-pack/skills/spec/

# Extract name from filename
NAME=$(basename "$INPUT" .md | sed 's/^_my_//')

# Read existing content
CONTENT=$(cat "$INPUT")

# Extract description from frontmatter
DESC=$(echo "$CONTENT" | grep -A1 "^---" | grep "description:" | cut -d: -f2- | xargs)

# Create SKILL.md with Codex format
mkdir -p "$OUTPUT_DIR"
cat > "$OUTPUT_DIR/SKILL.md" << EOF
---
name: $NAME
description: $DESC Use when user wants to $NAME something.
---

$(echo "$CONTENT" | sed '1,/^---$/d' | sed '1,/^---$/d')
EOF
```

---

## Recommendations

### Phase 1: Create codex-pack/ Parallel Structure
1. Create `codex-pack/` directory mirroring `claude-pack/`
2. Write conversion script for commands → skills
3. Convert all `_my_*.md` commands to `SKILL.md` format
4. Consolidate `rules/*.md` into single `AGENTS.md`

### Phase 2: Adapt Hooks
1. Port `capture.sh` and `precompact-capture.sh` to Codex hook system
2. Create `hooks.json` configuration
3. Test hook execution on Codex lifecycle events

### Phase 3: Handle Missing Features
1. Create custom skill for memory operations (recall, memorize)
2. Evaluate if Codex session APIs can replace transcript queries
3. Consider MCP server for persistent memory across sessions

### Phase 4: Installation Scripts
1. Create `setup-codex-global.sh` parallel to `setup-global.sh`
2. Add `--codex` flag to `init-project.sh` or create `init-project-codex.sh`
3. Test installation on fresh system

### Phase 5: Documentation
1. Update README with Codex installation instructions
2. Document differences and limitations
3. Create migration guide for users switching between tools

---

## Open Questions

1. **Memory system**: Should we build a custom MCP server for persistent memory, or accept the limitation?
2. **Dual installation**: Should one script support both tools, or keep separate scripts?
3. **Feature parity**: Which Claude-specific features are essential vs nice-to-have for Codex?
4. **Testing**: How do we test the Codex installation without access to Codex CLI?

---

## Code References

- Claude setup script: `/home/rwestwood/agentic-project-init/scripts/setup-global.sh`
- Claude init script: `/home/rwestwood/agentic-project-init/scripts/init-project.sh`
- Claude commands: `/home/rwestwood/agentic-project-init/claude-pack/commands/`
- Claude hooks: `/home/rwestwood/agentic-project-init/claude-pack/hooks/`
- Claude rules: `/home/rwestwood/agentic-project-init/claude-pack/rules/`
- Claude agents: `/home/rwestwood/agentic-project-init/claude-pack/agents/`

---

## Sources

- [Codex CLI Features](https://developers.openai.com/codex/cli/features)
- [Agent Skills - Codex](https://developers.openai.com/codex/skills)
- [Custom Instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
- [Codex Subagents](https://developers.openai.com/codex/subagents)
- [Codex Hooks](https://developers.openai.com/codex/hooks)
- [Codex Configuration Reference](https://developers.openai.com/codex/config-reference)
- [Codex MCP Configuration](https://developers.openai.com/codex/mcp)
- [GitHub - openai/codex](https://github.com/openai/codex)
- [GitHub - openai/skills](https://github.com/openai/skills)
