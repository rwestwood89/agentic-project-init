
## Purpose
Generate an HTML Kanban dashboard showing all work items organized by stage and epic.

## Requirements
- Script `generate-dashboard` creates `.project/dashboard.html`
- Dashboard layout: three columns (Backlog, Active, Completed)
- Items grouped under epic headers within each column
- Ungrouped items appear in separate section per column
- Epic headers show epic code, title, and aggregate progress
- Item cards show code, title, progress indicator, and completion date
- Progress indicator for active items: definition phase (badges) or implementation phase (progress bar)
- Dashboard includes "Last generated" timestamp
- Click-to-copy functionality on item codes (minimal JavaScript)
- Tooltips on cards showing owner, dates, status details
- HTML is self-contained (embedded CSS, minimal embedded JS, no external CDN dependencies)
- Generation completes in <1 second for projects with 100 items

## Acceptance Criteria

**Given** a registry with 3 epics and 15 items  
**When** dashboard generation runs  
**Then** HTML file is created with three column layout, items correctly placed, epics as headers

**Given** an active item with spec and design complete, plan not started  
**When** dashboard renders the item  
**Then** item card shows badges: `[spec]` `[design]` and missing badge for plan

**Given** an active item with plan showing phases_complete=3, phases_total=5  
**When** dashboard renders the item  
**Then** item card shows progress bar at 60% with text "3 / 5"

**Given** a completed item moved on 2026-02-08  
**When** dashboard renders the item  
**Then** item card shows completion date "2026-02-08"

**Given** an item code is clicked in the dashboard  
**When** JavaScript handler runs  
**Then** code is copied to clipboard and visual feedback is shown

**Given** mouse hovers over an item card  
**When** tooltip is displayed  
**Then** tooltip shows owner, created date, updated date, current status

## Interfaces

### Script: generate-dashboard

**Usage:**
```bash
generate-dashboard [--output PATH]

