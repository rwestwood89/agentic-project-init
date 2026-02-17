# File-Native Comment System

A file-native threaded comment system for code review. Comments are stored as sidecar YAML files in `.comments/` directories alongside your source code, tracked in git, and available to both humans and AI agents.

## Quick Start

### Install

```bash
# From the agentic-project-init repo
./scripts/setup-comments.sh

# With VSCode extension
./scripts/setup-comments.sh --vscode
```

### Usage

```bash
# Add a comment to a file
comment add src/main.py -L 42:45 "This function needs error handling"

# List comments
comment list src/main.py
comment list --all                    # All files in project
comment list --status open            # Filter by status

# Show a thread
comment show 01JXYZ...

# Reply to a thread
comment reply 01JXYZ... "Good point, I'll add a try/catch"

# Resolve with a decision
comment resolve 01JXYZ... --decision "Added error handling in commit abc123"

# Reopen a resolved thread
comment reopen 01JXYZ...

# Delete a thread
comment delete 01JXYZ... --force

# Reconcile anchors after edits
comment reconcile src/main.py
comment reconcile --all

# Generate decision log
comment decisions
```

## Architecture

### Sidecar Storage

Comments live in `.comments/` directories as YAML sidecar files, one per source file:

```
project/
├── src/
│   ├── main.py
│   └── utils.py
├── .comments/
│   └── src/
│       ├── main.py.comments.yaml
│       └── utils.py.comments.yaml
└── DECISIONS.md          # Generated from resolved threads
```

Each sidecar contains threads with:
- **Anchor**: Line range, content hash, and snippet for relocating after edits
- **Comments**: Ordered list with author, timestamp, and body
- **Status**: open, resolved, or wontfix
- **Decision**: Optional summary when resolved

### Anchor Reconciliation

When source files change, comment anchors may drift. The reconciliation engine uses multi-signal matching:

1. **Content hash** - exact match (no drift)
2. **Line number proximity** - nearby content check
3. **Fuzzy text matching** - handles edits to the anchored region
4. **Context matching** - surrounding lines for relocated code

Threads are classified as **anchored** (exact match), **drifted** (relocated), or **orphaned** (can't find anchor).

### Concurrency

File-level locking prevents concurrent writes to the same sidecar file. Lock files are created in `.comments/.locks/` and auto-expire after 30 seconds.

## CLI Reference

| Command | Description |
|---------|-------------|
| `comment add <file> -L START:END "body"` | Create a new comment thread |
| `comment list [file]` | List threads (with `--status`, `--health`, `--author`, `--all`, `--json` filters) |
| `comment show <id>` | Show full thread with all comments |
| `comment reply <id> "body"` | Reply to a thread |
| `comment resolve <id> --decision "..."` | Resolve with a decision |
| `comment reopen <id>` | Reopen a resolved thread |
| `comment delete <id>` | Delete a thread permanently |
| `comment reconcile [file]` | Reconcile anchors to current source |
| `comment decisions` | Generate DECISIONS.md from resolved threads |

## MCP Tools (Agent Integration)

The MCP server exposes 7 tools for Claude Code agent integration. Once installed, agents can read, write, and manage comments programmatically.

| Tool | Description |
|------|-------------|
| `comment_add` | Create a new comment thread on a source file |
| `comment_list` | List threads with optional filters |
| `comment_show` | Show full thread details |
| `comment_reply` | Reply to an existing thread |
| `comment_resolve` | Resolve a thread with optional decision |
| `comment_reopen` | Reopen a resolved thread |
| `comment_reconcile` | Force anchor reconciliation |

The MCP server runs via stdio and is auto-configured in `~/.claude/settings.json` during setup.

## VSCode Extension

The optional VSCode extension provides:

- Gutter icons showing comment threads on source lines
- Inline decorations with comment previews
- Click-to-view thread details
- Thread status indicators (open/resolved/wontfix)

Install with `--vscode` flag or manually:
```bash
code --install-extension comment-system/vscode-extension/file-native-comments-0.1.0.vsix
```

See [vscode-extension/README.md](vscode-extension/README.md) for build instructions.

## Storage Format

Sidecar files use YAML with this structure:

```yaml
source_file: src/main.py
source_hash: "abc123..."
threads:
  - id: "01JXYZ..."
    anchor:
      start_line: 42
      end_line: 45
      content_hash: "def456..."
      snippet: "def process_data(input):"
      context_before: "# Data processing"
      context_after: "    result = []"
    status: open
    comments:
      - id: "01JXYZ..."
        author: reid
        author_type: human
        body: "This function needs error handling"
        timestamp: "2025-01-15T10:30:00Z"
    decision: null
    resolved_at: null
```

## Running Tests

```bash
cd comment-system
uv sync
uv run pytest tests/
```

## Specifications

Detailed specifications are in `specs/`:

| Spec | Description |
|------|-------------|
| [data-model.md](specs/data-model.md) | Thread, comment, and anchor schemas |
| [cli-interface.md](specs/cli-interface.md) | CLI command specifications |
| [mcp-tools.md](specs/mcp-tools.md) | MCP tool interfaces |
| [anchor-reconciliation.md](specs/anchor-reconciliation.md) | Multi-signal anchor matching |
| [fuzzy-matching.md](specs/fuzzy-matching.md) | Text similarity algorithms |
| [file-operations.md](specs/file-operations.md) | YAML sidecar read/write |
| [file-tracking.md](specs/file-tracking.md) | Source file hash tracking |
| [concurrency.md](specs/concurrency.md) | File locking strategy |
| [orchestration.md](specs/orchestration.md) | Component interaction |
| [decision-log.md](specs/decision-log.md) | DECISIONS.md generation |
| [vscode-extension.md](specs/vscode-extension.md) | VSCode extension design |
