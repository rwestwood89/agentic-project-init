
## Purpose
Integrate lifecycle scripts into existing agentic commands to automate registry and metadata management.

## Requirements
- Update five agentic commands: `_my_spec`, `_my_design`, `_my_plan`, `_my_implement`, `_my_project_manage`
- Commands must call lifecycle scripts at appropriate workflow steps
- Commands must handle script failures gracefully (log error, inform user, allow manual fallback)
- Commands must preserve existing behavior when scripts are not available
- Updated command prompts must instruct agents to use scripts, not manual file operations
- Integration points must be documented in command source
- Settings file `.claude/settings.local.json` must include permissions for new scripts

## Acceptance Criteria

**Given** `/_my_spec` command is invoked to create a new item  
**When** the command reaches the "create item" step  
**Then** the agent calls `register-item` script instead of manually creating folder

**Given** `/_my_implement` command marks a phase complete  
**When** the agent updates progress  
**Then** the agent calls `update-artifact --phases-complete N` instead of editing frontmatter

**Given** `/_my_project_manage close` command is invoked  
**When** the command reaches the move step  
**Then** the agent calls `move-item WI-NNN --to completed` and does NOT manually move folder or edit CHANGELOG.md

**Given** a lifecycle script fails with exit code 2  
**When** the command detects the failure  
**Then** the agent logs the error, informs the user, and pauses for user decision

**Given** lifecycle scripts are not installed  
**When** the command attempts to call a script  
**Then** the command detects absence, warns user, falls back to previous manual method

## Interfaces

### Command Modifications

#### `_my_spec` command
**Integration point:** After user confirms item title and epic  
**Action:** Call `register-item --title "..." [--epic EP-NNN] --stage active`  
**Output handling:** Parse JSON output for assigned code, use code in subsequent steps

#### `_my_design` command
**Integration point:** After design document is written and user approves  
**Action:** Call `update-artifact <code> --artifact design --status complete`  
**Output handling:** Log success, update session context with completion

#### `_my_plan` command
**Integration point:** After plan document is written  
**Action:** Call `update-artifact <code> --artifact plan --status complete`  
**Additional:** Set `phases_total` in frontmatter during plan creation

#### `_my_implement` command
**Integration point:** After each phase completion is confirmed  
**Action:** Call `update-artifact <code> --artifact plan --phases-complete N`  
**Output handling:** Verify success, continue to next phase or mark item complete

**Integration point:** After final phase completion  
**Action:** Call `move-item <code> --to completed`  
**Output handling:** Verify CHANGELOG.md is updated, confirm epic completion status

#### `_my_project_manage` command
**Subcommand: status**  
**Integration point:** Beginning of status report generation  
**Action:** Read `.project/registry.json` directly for structured data  
**Output handling:** Use registry as primary data source instead of parsing markdown files

**Subcommand: close**  
**Integration point:** After user confirms item to close  
**Action:** Call `move-item <code> --to completed`  
**Output handling:** Verify folder renamed, CHANGELOG.md updated

**Subcommand: archive**  
**Integration point:** After user confirms item to archive  
**Action:** Call `move-item <code> --to completed` (if not already), then perform archival compression  
**Output handling:** Verify registry reflects completion before archiving

### Settings File: `.claude/settings.local.json`

**New entries required:**
```json
{
  "allowedCommands": [
    ".project/scripts/register-item",
    ".project/scripts/move-item",
    ".project/scripts/update-artifact",
    ".project/scripts/reconcile-registry",
    ".project/scripts/generate-dashboard"
  ]
}

