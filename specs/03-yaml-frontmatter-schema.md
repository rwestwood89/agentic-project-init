
## Purpose
Define standardized YAML frontmatter structure for spec, design, and plan artifacts to enable reliable automated parsing.

## Requirements
- All spec.md, design.md, and plan.md files begin with YAML frontmatter
- Frontmatter is delimited by `---` on separate lines before and after YAML content
- Common fields (all artifact types): `id`, `title`, `type`, `status`, `epic`, `owner`, `created`, `updated`
- Plan-specific fields: `phases_total`, `phases_complete`
- `id` must match work item code from registry
- `type` must be one of: `spec`, `design`, `plan`
- `status` must be one of: `draft`, `in-progress`, `complete`
- `epic` is epic code or `null`
- Timestamps must use ISO 8601 format
- Frontmatter must be parseable by standard YAML libraries
- Scripts must preserve frontmatter formatting when updating values

## Acceptance Criteria

**Given** a spec file with valid frontmatter  
**When** parsed by a Python YAML library  
**Then** all required fields are present and correctly typed

**Given** a plan file at 0% progress  
**When** the frontmatter is read  
**Then** `phases_total` is a positive integer and `phases_complete` is 0

**Given** a completed design artifact  
**When** the frontmatter status is read  
**Then** the status field equals `"complete"`

**Given** a script updates the `updated` timestamp  
**When** the file is written back  
**Then** all other frontmatter fields and all content below frontmatter are preserved

**Given** an artifact with missing or malformed frontmatter  
**When** the dashboard generation runs  
**Then** the item is ignored (not shown), no error is raised

## Interfaces

### Frontmatter Structure

**Common fields (spec, design, plan):**
```yaml
---
id: WI-NNN
title: Human-readable item title
type: spec | design | plan
status: draft | in-progress | complete
epic: EP-NNN | null
owner: Author name or identifier
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---

