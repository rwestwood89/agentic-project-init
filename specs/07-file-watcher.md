
## Purpose
Automatically regenerate dashboard when project files change to keep dashboard current.

## Requirements
- Script `watch-project` monitors `.project/` directory for changes
- Triggers `generate-dashboard` when relevant files change
- Debounces rapid changes (wait N seconds after last change before regenerating)
- Watches registry.json and all artifact files (spec.md, design.md, plan.md)
- Ignores changes to dashboard.html itself (prevent infinite loop)
- Outputs log messages for monitoring
- Runs as long-lived background process
- Can be gracefully stopped via SIGTERM

## Acceptance Criteria

**Given** the watch script is running  
**When** `registry.json` is modified  
**Then** dashboard regenerates within 2 seconds

**Given** a spec.md file is updated  
**When** the change is detected  
**Then** dashboard regenerates after debounce period (2 seconds)

**Given** 5 files are modified in rapid succession  
**When** debounce logic activates  
**Then** dashboard regenerates once, 2 seconds after the last change

**Given** dashboard.html is regenerated  
**When** the watcher sees dashboard.html change  
**Then** no regeneration is triggered (infinite loop prevented)

**Given** the watcher process receives SIGTERM  
**When** signal handler runs  
**Then** process logs shutdown message and exits gracefully

**Given** dashboard generation fails due to corrupt registry  
**When** watcher detects the failure  
**Then** error is logged to stderr, watcher continues running

## Interfaces

### Script: watch-project

**Usage:**
```bash
watch-project [--debounce SECONDS]

