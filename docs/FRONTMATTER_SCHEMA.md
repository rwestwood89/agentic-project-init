# YAML Frontmatter Schema Reference

This document defines the standardized YAML frontmatter structure for spec, design, and plan artifacts.

## Overview

All project artifacts (`spec.md`, `design.md`, `plan.md`) begin with YAML frontmatter. Frontmatter enables:

- Machine-readable metadata extraction
- Automated progress tracking
- Dashboard visualization
- Registry reconciliation

## Format

Frontmatter is delimited by `---` on separate lines:

```markdown
---
id: WI-001
title: Implement login flow
type: spec
status: complete
epic: EP-001
owner: Alice
created: 2026-02-01T10:00:00Z
updated: 2026-02-08T14:30:00Z
---

# Artifact Content

The rest of the markdown content goes here...
```

## Common Fields

These fields appear in **all artifact types** (spec, design, plan).

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|--------------|-------------|
| `id` | string | Yes | `EP-NNN`, `WI-NNN` | Work item or epic code |
| `title` | string | Yes | Any string | Human-readable title |
| `type` | enum | Yes | `spec`, `design`, `plan` | Artifact type |
| `status` | enum | Yes | `draft`, `in-progress`, `complete` | Current status |
| `epic` | string or null | Yes | `EP-NNN`, `null` | Parent epic code or null |
| `owner` | string | Yes | Any string | Author name or identifier |
| `created` | string | Yes | ISO 8601 | Creation timestamp |
| `updated` | string | Yes | ISO 8601 | Last update timestamp |

### Field Descriptions

#### `id`

Work item or epic code from registry.

- Format: `WI-NNN` (work item) or `EP-NNN` (epic)
- Must match entry in `.project/registry.json`
- Used to link artifact to registry

**Examples:**

```yaml
id: WI-001   # Work item
id: EP-001   # Epic
```

#### `title`

Human-readable title describing the work item.

- Must match title in registry
- Keep concise (under 80 characters recommended)

**Examples:**

```yaml
title: Implement login flow
title: User Authentication System
title: Fix session timeout bug
```

#### `type`

Artifact type identifier.

- `spec` - Specification document (requirements, acceptance criteria)
- `design` - Design document (architecture, implementation approach)
- `plan` - Implementation plan (phases, tasks, validation)

**Examples:**

```yaml
type: spec
type: design
type: plan
```

#### `status`

Current completion status of the artifact.

- `draft` - Initial version, not reviewed
- `in-progress` - Being actively worked on
- `complete` - Finished and approved

Scripts update status as work progresses.

**Examples:**

```yaml
status: draft
status: in-progress
status: complete
```

**Status Transitions:**

```
draft → in-progress → complete
  ↓          ↓
  └──────────┘
  (allowed to go backwards)
```

#### `epic`

Parent epic code (optional grouping).

- `EP-NNN` - Parent epic code
- `null` - No parent epic (standalone item)

**Examples:**

```yaml
epic: EP-001
epic: null
```

#### `owner`

Person responsible for the work item.

- Can be name, username, email, or identifier
- Used for accountability and dashboard tooltips

**Examples:**

```yaml
owner: Alice
owner: alice@example.com
owner: @alice
owner: Alice Johnson
```

#### `created`

Timestamp when artifact was created.

- Format: ISO 8601 with timezone
- Set once at creation, never updated
- Timezone: UTC (`Z` suffix) or offset (`+00:00`)

**Examples:**

```yaml
created: 2026-02-01T10:00:00Z
created: 2026-02-01T10:00:00+00:00
created: 2026-02-01T05:00:00-05:00
```

**Python generation:**

```python
from datetime import datetime, timezone

now = datetime.now(timezone.utc).isoformat()
# "2026-02-08T14:30:00+00:00"
```

#### `updated`

Timestamp of last modification.

- Format: ISO 8601 with timezone
- Updated automatically by scripts
- Timezone: UTC (`Z` suffix) or offset (`+00:00`)

**Examples:**

```yaml
updated: 2026-02-08T14:30:00Z
updated: 2026-02-08T14:30:00+00:00
```

Scripts update this field whenever frontmatter changes.

---

## Plan-Specific Fields

These fields appear **only in plan artifacts** (`type: plan`).

| Field | Type | Required | Valid Values | Description |
|-------|------|----------|--------------|-------------|
| `phases_total` | integer | Yes | 1-999 | Total number of implementation phases |
| `phases_complete` | integer | Yes | 0-`phases_total` | Number of completed phases |

### Field Descriptions

#### `phases_total`

Total number of implementation phases in the plan.

- Positive integer (1-999)
- Set when plan is created
- Rarely changes (plan scope change)

**Examples:**

```yaml
phases_total: 5
phases_total: 10
phases_total: 1   # Single-phase plan
```

#### `phases_complete`

Number of phases completed so far.

- Non-negative integer (0-999)
- Must be ≤ `phases_total`
- Updated by `update-artifact` script as phases complete
- Used for progress bar in dashboard

**Examples:**

```yaml
phases_complete: 0   # Not started
phases_complete: 3   # 3 of 5 phases done
phases_complete: 5   # All phases complete (if phases_total=5)
```

**Progress calculation:**

```python
progress = phases_complete / phases_total * 100
# Example: 3 / 5 = 60%
```

---

## Complete Examples

### Spec Artifact

```yaml
---
id: WI-001
title: Implement login flow
type: spec
status: complete
epic: EP-001
owner: Alice
created: 2026-02-01T10:00:00Z
updated: 2026-02-05T16:30:00Z
---

# Login Flow Specification

## Purpose
Enable users to authenticate with email and password.

## Requirements
- Email validation
- Password strength check
- Session management
- Remember me checkbox

## Acceptance Criteria
1. User can log in with valid credentials
2. Invalid credentials show error message
3. Session persists across page refreshes
4. "Remember me" extends session to 30 days
```

### Design Artifact

```yaml
---
id: WI-001
title: Implement login flow
type: design
status: in-progress
epic: EP-001
owner: Alice
created: 2026-02-05T10:00:00Z
updated: 2026-02-06T14:00:00Z
---

# Login Flow Design

## Architecture

### Components
- LoginForm (React component)
- AuthService (API client)
- SessionStore (state management)

### Data Flow
1. User submits form
2. LoginForm calls AuthService.login()
3. AuthService POSTs to /api/auth/login
4. Server validates credentials
5. Server returns JWT token
6. SessionStore saves token
7. App redirects to dashboard
```

### Plan Artifact

```yaml
---
id: WI-001
title: Implement login flow
type: plan
status: in-progress
epic: EP-001
owner: Alice
created: 2026-02-06T10:00:00Z
updated: 2026-02-08T14:30:00Z
phases_total: 5
phases_complete: 3
---

# Implementation Plan: Login Flow

## Phase 1: Backend API
- [ ] Create /api/auth/login endpoint
- [ ] Implement password hashing
- [ ] Generate JWT tokens
- [ ] Write unit tests

## Phase 2: Frontend Form
- [ ] Create LoginForm component
- [ ] Add email/password inputs
- [ ] Implement form validation
- [ ] Add submit handler

## Phase 3: State Management
- [x] Create SessionStore
- [x] Implement token storage
- [x] Add logout functionality

## Phase 4: Integration
- [ ] Connect form to API
- [ ] Handle error responses
- [ ] Add loading states

## Phase 5: Testing & Polish
- [ ] E2E tests
- [ ] Error message UX
- [ ] Accessibility review
```

---

## Validation Rules

Scripts validate frontmatter before processing:

### Required Fields

All artifacts MUST have:

```python
REQUIRED_FIELDS = [
    "id", "title", "type", "status",
    "epic", "owner", "created", "updated"
]
```

Plan artifacts MUST also have:

```python
PLAN_FIELDS = ["phases_total", "phases_complete"]
```

### Enum Validation

```python
VALID_TYPES = ["spec", "design", "plan"]
VALID_STATUSES = ["draft", "in-progress", "complete"]
```

### Code Format Validation

```python
import re

EPIC_CODE_PATTERN = re.compile(r"^EP-\d{3}$")
ITEM_CODE_PATTERN = re.compile(r"^WI-\d{3}$")

def validate_code(code: str) -> None:
    if not (EPIC_CODE_PATTERN.match(code) or ITEM_CODE_PATTERN.match(code)):
        raise ValueError(f"Invalid code format: {code}")
```

### Timestamp Validation

```python
from datetime import datetime

def validate_timestamp(timestamp: str) -> None:
    try:
        datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
    except ValueError as e:
        raise ValueError(f"Invalid ISO 8601 timestamp: {timestamp}") from e
```

### Plan Phase Validation

```python
def validate_phases(phases_complete: int, phases_total: int) -> None:
    if phases_complete < 0:
        raise ValueError("phases_complete must be non-negative")
    if phases_complete > phases_total:
        raise ValueError("phases_complete cannot exceed phases_total")
    if phases_total <= 0:
        raise ValueError("phases_total must be positive")
```

---

## Parsing Frontmatter

### Python (PyYAML)

```python
import yaml

def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Parse YAML frontmatter from markdown content.

    Returns:
        (frontmatter_dict, body_content)
    """
    if not content.startswith("---\n"):
        raise ValueError("Missing frontmatter delimiter")

    # Find closing delimiter
    parts = content.split("\n---\n", 1)
    if len(parts) != 2:
        raise ValueError("Missing closing frontmatter delimiter")

    yaml_text = parts[0][4:]  # Remove opening "---\n"
    body = parts[1]

    frontmatter = yaml.safe_load(yaml_text)

    return frontmatter, body
```

### JavaScript (gray-matter)

```javascript
const matter = require('gray-matter');

const content = `---
id: WI-001
title: Implement login flow
---
# Content`;

const { data, content: body } = matter(content);
console.log(data.id);  // "WI-001"
```

---

## Updating Frontmatter

### Preserve Content

When updating frontmatter, **preserve body content**:

```python
import yaml

def update_frontmatter(content: str, updates: dict) -> str:
    """Update frontmatter fields while preserving body."""
    frontmatter, body = parse_frontmatter(content)

    # Update fields
    frontmatter.update(updates)

    # Rebuild document
    yaml_text = yaml.dump(frontmatter, default_flow_style=False, sort_keys=False)
    return f"---\n{yaml_text}---\n{body}"
```

### Auto-Update Timestamp

Scripts automatically update `updated` field:

```python
from datetime import datetime, timezone

def update_artifact(content: str, updates: dict) -> str:
    """Update frontmatter with auto-timestamp."""
    # Add current timestamp
    updates["updated"] = datetime.now(timezone.utc).isoformat()

    return update_frontmatter(content, updates)
```

---

## Error Handling

### Missing Frontmatter

If artifact has no frontmatter:

- Dashboard ignores item (not shown)
- `reconcile-registry` skips artifact
- Scripts fail with clear error

**Fix:**

Add frontmatter manually or re-create with `register-item`.

### Malformed YAML

If YAML parse fails:

- Dashboard ignores item
- `reconcile-registry` logs error, skips artifact
- Scripts fail with parse error

**Fix:**

Validate YAML syntax at [yamllint.com](http://www.yamllint.com/)

### Missing Required Field

If required field missing:

- Dashboard may show partial data
- Scripts fail with validation error

**Fix:**

Add missing field manually.

### Invalid Enum Value

If `status` or `type` has invalid value:

- Scripts fail with validation error

**Fix:**

Correct to valid enum value.

### Invalid Phases

If `phases_complete > phases_total`:

- `update-artifact` rejects update
- Dashboard may show >100% progress

**Fix:**

```bash
uv run update-artifact WI-001 --artifact plan --phases-complete 3
```

---

## Best Practices

1. **Use scripts to update** - Scripts enforce validation and auto-update timestamps
2. **Keep titles synced** - Match title in frontmatter and registry
3. **Use UTC timestamps** - Avoid timezone confusion
4. **Set phases_total early** - Define total phases when creating plan
5. **Update progressively** - Increment `phases_complete` as phases finish
6. **Don't skip statuses** - Follow progression: draft → in-progress → complete
7. **Use null for no epic** - Explicitly set `epic: null` for standalone items
8. **Validate after manual edits** - Run `reconcile-registry` after editing frontmatter

---

## Dashboard Integration

Frontmatter fields power dashboard features:

| Field | Dashboard Use |
|-------|---------------|
| `id` | Item code (click to copy) |
| `title` | Card title |
| `type` | Badge indicator (spec/design/plan) |
| `status` | Badge color (draft=gray, in-progress=blue, complete=green) |
| `epic` | Group items under epic header |
| `owner` | Tooltip metadata |
| `created` | Tooltip metadata |
| `updated` | Tooltip metadata |
| `phases_total` | Progress bar denominator |
| `phases_complete` | Progress bar numerator |

### Progress Visualization

Dashboard shows two types of progress:

**Definition Phase** (before implementation):

```
[spec] [design] [plan]
```

Green badge = complete, gray badge = incomplete.

**Implementation Phase** (plan exists):

```
████████░░ 60% (3 / 5)
```

Progress bar fills based on `phases_complete / phases_total`.

---

## Schema Evolution

### Adding Optional Fields

New optional fields can be added without breaking existing artifacts:

```yaml
priority: high    # New optional field
estimate: 5d      # New optional field
```

Readers should ignore unknown fields.

### Deprecating Fields

To deprecate a field:

1. Mark as deprecated in docs
2. Stop writing field in new artifacts
3. Update scripts to handle missing field
4. After transition period, remove from schema

### Versioning

Future versions may add `schema_version`:

```yaml
---
schema_version: 2
id: WI-001
...
---
```

Current version is implicitly `1` (no version field).

---

## Tools and Utilities

### Validation Script

```python
from src.models.frontmatter import validate_frontmatter

with open(".project/active/login-flow/spec.md") as f:
    content = f.read()

try:
    validate_frontmatter(content)
    print("✓ Valid frontmatter")
except ValueError as e:
    print(f"✗ Invalid frontmatter: {e}")
```

### Extraction Utility

```python
from src.models.frontmatter import extract_frontmatter_field

with open(".project/active/login-flow/spec.md") as f:
    content = f.read()

status = extract_frontmatter_field(content, "status")
print(f"Status: {status}")
```

### Bulk Update

```bash
# Update all specs to complete
for spec in .project/active/*/spec.md; do
  code=$(grep "^id:" "$spec" | cut -d' ' -f2)
  uv run update-artifact "$code" --artifact spec --status complete
done
```

---

## Related Documentation

- [Lifecycle Scripts Usage Guide](LIFECYCLE_SCRIPTS.md) - Tools for updating frontmatter
- [Registry Schema](REGISTRY_SCHEMA.md) - Registry structure and work item codes
- [Dashboard Documentation](DASHBOARD.md) - How frontmatter powers dashboard visualization
