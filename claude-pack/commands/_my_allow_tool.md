# Allow Tool

**Purpose:** Manage the auto-approve hook configuration (allowed paths, safe commands, tier2 toggle)
**Input:** Action and arguments via `$ARGUMENTS`
**Output:** Updated config file with confirmation of changes

## Overview

Read and modify `~/.claude/hooks/allowed-tools.json` to control which operations the auto-approve hook allows automatically.

## Usage

```
/_my_allow_tool add path ~/myproject
/_my_allow_tool add command node
/_my_allow_tool remove path ~/myproject
/_my_allow_tool remove command node
/_my_allow_tool list
/_my_allow_tool toggle tier2
```

## Process

### Step 1: Parse Arguments

Parse `$ARGUMENTS` to determine the action:

| Action | Pattern | Example |
|--------|---------|---------|
| Add path | `add path <path>` | `add path ~/myproject` |
| Add command | `add command <name>` | `add command node` |
| Remove path | `remove path <path>` | `remove path ~/myproject` |
| Remove command | `remove command <name>` | `remove command node` |
| List | `list` or `show` | `list` |
| Toggle tier2 | `toggle tier2` or `enable tier2` or `disable tier2` | `toggle tier2` |

If no arguments or unrecognized action, show usage help.

### Step 2: Read Config

Read `~/.claude/hooks/allowed-tools.json` using the Read tool.

If the file doesn't exist, report an error:
```
Config file not found at ~/.claude/hooks/allowed-tools.json
Run setup-global.sh to install the auto-approve hook first.
```

### Step 3: Execute Action

#### Add Path
1. Normalize the path: expand `~` to `$HOME`, resolve relative paths to absolute
2. Verify the path is a directory that exists (use Bash `test -d`)
3. Check for duplicates in `allowed_paths`
4. If not duplicate, append to `allowed_paths` array
5. Write updated JSON back using the Write tool

#### Add Command
1. Validate the command name is reasonable (alphanumeric, hyphens, underscores, no spaces or special characters)
2. Check for duplicates in `safe_commands`
3. If not duplicate, append to `safe_commands` array
4. Write updated JSON back using the Write tool

#### Remove Path
1. Normalize the path (same as add)
2. Check if path exists in `allowed_paths`
3. If found, remove it; if not found, report "Path not in config"
4. Write updated JSON back using the Write tool

#### Remove Command
1. Check if command exists in `safe_commands`
2. If found, remove it; if not found, report "Command not in config"
3. Write updated JSON back using the Write tool

#### List
1. Display the current config in a readable format:
   ```
   Auto-approve configuration (~/.claude/hooks/allowed-tools.json):

   Tier 2 (AI review): enabled/disabled

   Allowed paths:
     - /home/user/project1
     - /home/user/project2
     (none configured — add with: /_my_allow_tool add path ~/myproject)

   Safe commands (in addition to built-in baseline):
     - node
     - cargo
     (none configured — add with: /_my_allow_tool add command node)
   ```

#### Toggle Tier2
1. Flip the `tier2_enabled` boolean
2. Write updated JSON back using the Write tool
3. Report new state: "Tier 2 AI review is now enabled/disabled"

### Step 4: Confirm

Report what changed. For add/remove operations, show the updated list.

$ARGUMENTS

---

**Related Commands:**
- `/_my_implement` — implementation workflow
- `/_my_project_manage` — project status

**Last Updated**: 2026-02-08
