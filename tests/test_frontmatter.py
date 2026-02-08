"""Tests for YAML frontmatter parsing and updating."""

import pytest

from src.models.frontmatter import (
    extract_frontmatter_field,
    parse_frontmatter,
    update_frontmatter,
    validate_frontmatter,
)


class TestParseFrontmatter:
    """Tests for parse_frontmatter function."""

    def test_parse_valid_frontmatter(self):
        """Test parsing valid YAML frontmatter."""
        content = """---
id: WI-001
title: Test Item
type: spec
status: draft
epic: EP-001
owner: Alice
created: 2024-01-01T10:00:00Z
updated: 2024-01-02T10:00:00Z
---
This is the body content.
More content here."""

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is not None
        assert frontmatter['id'] == 'WI-001'
        assert frontmatter['title'] == 'Test Item'
        assert frontmatter['type'] == 'spec'
        assert frontmatter['status'] == 'draft'
        assert body.startswith('This is the body content.')

    def test_parse_plan_with_phases(self):
        """Test parsing plan frontmatter with phase tracking."""
        content = """---
id: WI-002
title: Implementation Plan
type: plan
status: in-progress
epic: null
owner: Bob
created: 2024-01-01T10:00:00Z
updated: 2024-01-03T10:00:00Z
phases_total: 5
phases_complete: 2
---
## Phase 1: Setup"""

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is not None
        assert frontmatter['type'] == 'plan'
        assert frontmatter['phases_total'] == 5
        assert frontmatter['phases_complete'] == 2
        assert '## Phase 1: Setup' in body

    def test_parse_no_frontmatter(self):
        """Test parsing content without frontmatter."""
        content = "Just plain markdown content"

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is None
        assert body == content

    def test_parse_malformed_frontmatter(self):
        """Test parsing malformed YAML frontmatter."""
        content = """---
id: WI-001
this is not valid yaml: [
---
Body content"""

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is None
        assert body == content

    def test_parse_incomplete_frontmatter_delimiters(self):
        """Test parsing with incomplete delimiter markers."""
        content = """---
id: WI-001
Body without closing delimiter"""

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is None
        assert body == content

    def test_parse_empty_frontmatter(self):
        """Test parsing empty frontmatter section."""
        content = """---
---
Body content"""

        frontmatter, body = parse_frontmatter(content)

        # Empty YAML parses to None, which we handle
        assert frontmatter is None
        assert body == content

    def test_parse_null_values(self):
        """Test parsing frontmatter with null values."""
        content = """---
id: WI-003
epic: null
owner: null
---
Content"""

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is not None
        assert frontmatter['epic'] is None
        assert frontmatter['owner'] is None

    def test_parse_multiline_values(self):
        """Test parsing frontmatter with multiline values."""
        content = """---
id: WI-004
title: |
  This is a multiline
  title value
---
Body"""

        frontmatter, body = parse_frontmatter(content)

        assert frontmatter is not None
        assert 'multiline' in frontmatter['title']


class TestUpdateFrontmatter:
    """Tests for update_frontmatter function."""

    def test_update_existing_field(self):
        """Test updating an existing frontmatter field."""
        content = """---
id: WI-001
status: draft
---
Body content"""

        updated = update_frontmatter(content, {'status': 'complete'})

        assert 'status: complete' in updated
        assert 'Body content' in updated
        assert updated.startswith('---\n')
        assert '---\n' in updated[4:]  # Second delimiter

    def test_update_multiple_fields(self):
        """Test updating multiple fields at once."""
        content = """---
id: WI-001
status: draft
updated: 2024-01-01T10:00:00Z
---
Body"""

        updates = {
            'status': 'in-progress',
            'updated': '2024-01-02T10:00:00Z'
        }
        updated = update_frontmatter(content, updates)

        assert 'status: in-progress' in updated
        assert '2024-01-02T10:00:00Z' in updated
        assert 'Body' in updated

    def test_update_add_new_field(self):
        """Test adding a new field to existing frontmatter."""
        content = """---
id: WI-001
---
Body"""

        updated = update_frontmatter(content, {'owner': 'Charlie'})

        assert 'owner: Charlie' in updated
        assert 'id: WI-001' in updated

    def test_update_plan_phases(self):
        """Test updating phase completion in plan artifact."""
        content = """---
id: WI-002
type: plan
phases_total: 5
phases_complete: 2
---
Implementation"""

        updated = update_frontmatter(content, {'phases_complete': 3})

        assert 'phases_complete: 3' in updated
        assert 'phases_total: 5' in updated
        assert 'Implementation' in updated

    def test_update_preserve_body_formatting(self):
        """Test that update preserves body content and formatting."""
        content = """---
id: WI-001
---
# Heading

- List item 1
- List item 2

Code block:
```python
def foo():
    pass
```"""

        updated = update_frontmatter(content, {'status': 'draft'})

        # Body should be preserved exactly
        assert '# Heading' in updated
        assert '- List item 1' in updated
        assert '```python' in updated
        assert 'def foo():' in updated

    def test_update_missing_frontmatter_raises_error(self):
        """Test that updating missing frontmatter raises error by default."""
        content = "No frontmatter here"

        with pytest.raises(ValueError, match="No frontmatter found"):
            update_frontmatter(content, {'status': 'draft'})

    def test_update_create_if_missing(self):
        """Test creating frontmatter when missing if create_if_missing=True."""
        content = "Plain markdown body"

        updated = update_frontmatter(
            content,
            {'id': 'WI-001', 'type': 'spec'},
            create_if_missing=True
        )

        assert 'id: WI-001' in updated
        assert 'type: spec' in updated
        assert 'Plain markdown body' in updated

    def test_update_unicode_content(self):
        """Test updating frontmatter with unicode characters."""
        content = """---
id: WI-001
title: Test
---
Unicode: 你好 🎉"""

        updated = update_frontmatter(content, {'title': 'Новый заголовок'})

        assert 'Новый заголовок' in updated
        assert '你好 🎉' in updated


class TestValidateFrontmatter:
    """Tests for validate_frontmatter function."""

    def test_validate_complete_valid_spec(self):
        """Test validation of complete valid spec frontmatter."""
        frontmatter = {
            'id': 'WI-001',
            'title': 'Test Item',
            'type': 'spec',
            'status': 'draft',
            'epic': 'EP-001',
            'owner': 'Alice',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert errors == []

    def test_validate_complete_valid_plan(self):
        """Test validation of complete valid plan frontmatter."""
        frontmatter = {
            'id': 'WI-002',
            'title': 'Plan',
            'type': 'plan',
            'status': 'in-progress',
            'epic': None,
            'owner': 'Bob',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-03T10:00:00Z',
            'phases_total': 5,
            'phases_complete': 2,
        }

        errors = validate_frontmatter(frontmatter)

        assert errors == []

    def test_validate_missing_required_fields(self):
        """Test validation detects missing required fields."""
        frontmatter = {
            'id': 'WI-001',
            'type': 'spec',
        }

        errors = validate_frontmatter(frontmatter)

        assert len(errors) > 0
        assert any('title' in err for err in errors)
        assert any('status' in err for err in errors)
        assert any('owner' in err for err in errors)

    def test_validate_invalid_type(self):
        """Test validation detects invalid type value."""
        frontmatter = {
            'id': 'WI-001',
            'title': 'Test',
            'type': 'invalid_type',
            'status': 'draft',
            'epic': None,
            'owner': 'Alice',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert len(errors) > 0
        assert any('Invalid type' in err for err in errors)

    def test_validate_invalid_status(self):
        """Test validation detects invalid status value."""
        frontmatter = {
            'id': 'WI-001',
            'title': 'Test',
            'type': 'spec',
            'status': 'pending',  # Not a valid status
            'epic': None,
            'owner': 'Alice',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert len(errors) > 0
        assert any('Invalid status' in err for err in errors)

    def test_validate_invalid_id_format(self):
        """Test validation detects invalid ID format."""
        frontmatter = {
            'id': 'INVALID-001',
            'title': 'Test',
            'type': 'spec',
            'status': 'draft',
            'epic': None,
            'owner': 'Alice',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert len(errors) > 0
        assert any('Invalid ID format' in err for err in errors)

    def test_validate_plan_missing_phases(self):
        """Test validation detects missing phase fields in plan."""
        frontmatter = {
            'id': 'WI-002',
            'title': 'Plan',
            'type': 'plan',
            'status': 'draft',
            'epic': None,
            'owner': 'Bob',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert len(errors) > 0
        assert any('phases_total' in err for err in errors)
        assert any('phases_complete' in err for err in errors)

    def test_validate_plan_invalid_phases_type(self):
        """Test validation detects invalid phase field types."""
        frontmatter = {
            'id': 'WI-002',
            'title': 'Plan',
            'type': 'plan',
            'status': 'draft',
            'epic': None,
            'owner': 'Bob',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
            'phases_total': 'five',  # Should be int
            'phases_complete': -1,    # Should be non-negative
        }

        errors = validate_frontmatter(frontmatter)

        assert len(errors) > 0
        assert any('phases_total' in err for err in errors)
        assert any('phases_complete' in err for err in errors)

    def test_validate_epic_code_format(self):
        """Test validation accepts valid epic codes."""
        frontmatter = {
            'id': 'WI-001',
            'title': 'Test',
            'type': 'spec',
            'status': 'draft',
            'epic': 'EP-042',
            'owner': 'Alice',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert errors == []

    def test_validate_null_epic(self):
        """Test validation accepts null epic value."""
        frontmatter = {
            'id': 'WI-001',
            'title': 'Test',
            'type': 'spec',
            'status': 'draft',
            'epic': None,
            'owner': 'Alice',
            'created': '2024-01-01T10:00:00Z',
            'updated': '2024-01-02T10:00:00Z',
        }

        errors = validate_frontmatter(frontmatter)

        assert errors == []


class TestExtractFrontmatterField:
    """Tests for extract_frontmatter_field function."""

    def test_extract_existing_field(self):
        """Test extracting a field that exists."""
        content = """---
id: WI-001
status: draft
---
Body"""

        value = extract_frontmatter_field(content, 'id')

        assert value == 'WI-001'

    def test_extract_missing_field(self):
        """Test extracting a field that doesn't exist."""
        content = """---
id: WI-001
---
Body"""

        value = extract_frontmatter_field(content, 'status')

        assert value is None

    def test_extract_no_frontmatter(self):
        """Test extracting from content without frontmatter."""
        content = "No frontmatter"

        value = extract_frontmatter_field(content, 'id')

        assert value is None

    def test_extract_null_value(self):
        """Test extracting a field with null value."""
        content = """---
id: WI-001
epic: null
---
Body"""

        value = extract_frontmatter_field(content, 'epic')

        assert value is None

    def test_extract_complex_value(self):
        """Test extracting complex value types."""
        content = """---
id: WI-001
phases_complete: 3
---
Body"""

        value = extract_frontmatter_field(content, 'phases_complete')

        assert value == 3
        assert isinstance(value, int)
