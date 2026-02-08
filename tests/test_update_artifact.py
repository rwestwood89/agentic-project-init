"""Tests for update-artifact script."""

import json
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.fixture
def test_project(tmp_path: Path) -> Path:
    """Create a test project structure with registry and artifacts."""
    project_dir = tmp_path / '.project'
    project_dir.mkdir()

    # Create registry with one active item
    registry_data = {
        'epics': {},
        'items': {
            'WI-001': {
                'title': 'Test Item',
                'epic': None,
                'stage': 'active',
                'path': '.project/active/test-item'
            },
            'WI-002': {
                'title': 'Backlog Item',
                'epic': None,
                'stage': 'backlog',
                'path': None  # backlog items have no path
            }
        },
        'next_epic_id': 1,
        'next_item_id': 3
    }

    registry_path = project_dir / 'registry.json'
    registry_path.write_text(json.dumps(registry_data, indent=2))

    # Create active item folder and artifacts
    item_dir = project_dir / 'active' / 'test-item'
    item_dir.mkdir(parents=True)

    # Create spec.md with frontmatter
    spec_content = """---
id: WI-001
title: Test Item
type: spec
status: draft
epic: null
owner: ""
created: 2024-01-01T00:00:00Z
updated: 2024-01-01T00:00:00Z
---

# Test Item

This is the specification content.
"""
    spec_path = item_dir / 'spec.md'
    spec_path.write_text(spec_content)

    # Create design.md
    design_content = """---
id: WI-001
title: Test Item Design
type: design
status: draft
epic: null
owner: Alice
created: 2024-01-01T00:00:00Z
updated: 2024-01-01T00:00:00Z
---

# Design

Design content here.
"""
    design_path = item_dir / 'design.md'
    design_path.write_text(design_content)

    # Create plan.md with phases
    plan_content = """---
id: WI-001
title: Test Item Plan
type: plan
status: in-progress
epic: null
owner: Bob
phases_total: 5
phases_complete: 0
created: 2024-01-01T00:00:00Z
updated: 2024-01-01T00:00:00Z
---

# Plan

Plan content here.
"""
    plan_path = item_dir / 'plan.md'
    plan_path.write_text(plan_content)

    return tmp_path


def run_update_artifact(cwd: Path, *args: str) -> subprocess.CompletedProcess:
    """Run update-artifact script."""
    return subprocess.run(
        [sys.executable, '-m', 'src.scripts.update_artifact', *args],
        cwd=cwd,
        capture_output=True,
        text=True
    )


class TestUpdateArtifactSuccess:
    """Test successful artifact updates."""

    def test_update_spec_status(self, test_project: Path):
        """Update spec status to complete."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 0

        # Parse JSON output
        output = json.loads(result.stdout)
        assert output['code'] == 'WI-001'
        assert output['artifact'] == 'spec'
        assert output['updates']['status'] == 'complete'
        assert 'updated' in output['updates']

        # Verify file content
        spec_path = test_project / '.project/active/test-item/spec.md'
        content = spec_path.read_text()

        assert 'status: complete' in content
        assert 'This is the specification content.' in content  # body preserved

    def test_update_design_owner(self, test_project: Path):
        """Update design owner."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'design',
            '--owner', 'Charlie'
        )

        assert result.returncode == 0

        # Verify file content
        design_path = test_project / '.project/active/test-item/design.md'
        content = design_path.read_text()

        assert 'owner: Charlie' in content
        assert 'Design content here.' in content

    def test_update_plan_phases(self, test_project: Path):
        """Update plan phases_complete."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'plan',
            '--phases-complete', '3'
        )

        assert result.returncode == 0

        # Parse JSON output
        output = json.loads(result.stdout)
        assert output['updates']['phases_complete'] == 3

        # Verify file content
        plan_path = test_project / '.project/active/test-item/plan.md'
        content = plan_path.read_text()

        assert 'phases_complete: 3' in content
        assert 'phases_total: 5' in content
        assert 'Plan content here.' in content

    def test_update_multiple_fields(self, test_project: Path):
        """Update multiple fields at once."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'in-progress',
            '--owner', 'Dave'
        )

        assert result.returncode == 0

        # Verify file content
        spec_path = test_project / '.project/active/test-item/spec.md'
        content = spec_path.read_text()

        assert 'status: in-progress' in content
        assert 'owner: Dave' in content

    def test_timestamp_updated(self, test_project: Path):
        """Verify updated timestamp is set to current time."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 0

        # Verify timestamp in output
        output = json.loads(result.stdout)
        updated_time = output['updates']['updated']
        assert updated_time.startswith('202')  # reasonable year check
        assert 'T' in updated_time  # ISO 8601 format

        # Verify timestamp in file (YAML may quote it)
        spec_path = test_project / '.project/active/test-item/spec.md'
        content = spec_path.read_text()
        # Check for timestamp with or without quotes
        assert (f'updated: {updated_time}' in content or
                f"updated: '{updated_time}'" in content or
                f'updated: "{updated_time}"' in content)

    def test_case_insensitive_code(self, test_project: Path):
        """Item code is case-insensitive."""
        result = run_update_artifact(
            test_project,
            'wi-001',  # lowercase
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 0

        output = json.loads(result.stdout)
        assert output['code'] == 'WI-001'  # normalized to uppercase


class TestUpdateArtifactInputErrors:
    """Test input validation errors (exit code 1)."""

    def test_no_update_fields(self, test_project: Path):
        """Error if no update fields provided."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec'
        )

        assert result.returncode == 1
        assert 'at least one update field' in result.stderr.lower()

    def test_invalid_status(self, test_project: Path):
        """Error if invalid status value."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'invalid'
        )

        assert result.returncode != 0  # argparse will fail
        assert 'invalid choice' in result.stderr.lower()

    def test_phases_on_non_plan(self, test_project: Path):
        """Error if phases-complete used with non-plan artifact."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--phases-complete', '2'
        )

        assert result.returncode == 1
        assert 'can only be used with plan' in result.stderr.lower()

    def test_negative_phases(self, test_project: Path):
        """Error if phases_complete is negative."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'plan',
            '--phases-complete', '-1'
        )

        assert result.returncode == 1
        assert 'non-negative' in result.stderr.lower()

    def test_phases_exceed_total(self, test_project: Path):
        """Error if phases_complete exceeds phases_total."""
        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'plan',
            '--phases-complete', '10'  # phases_total is 5
        )

        assert result.returncode == 1
        assert 'exceeds phases_total' in result.stderr.lower()


class TestUpdateArtifactStateErrors:
    """Test state errors (exit code 2)."""

    def test_registry_not_found(self, tmp_path: Path):
        """Error if registry.json doesn't exist."""
        result = run_update_artifact(
            tmp_path,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 2
        assert 'registry not found' in result.stderr.lower()

    def test_item_not_found(self, test_project: Path):
        """Error if work item doesn't exist."""
        result = run_update_artifact(
            test_project,
            'WI-999',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 2
        assert 'not found in registry' in result.stderr.lower()

    def test_backlog_item(self, test_project: Path):
        """Error if trying to update backlog item (no path)."""
        result = run_update_artifact(
            test_project,
            'WI-002',  # backlog item
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 2
        assert 'backlog item' in result.stderr.lower()
        assert 'no filesystem path' in result.stderr.lower()

    def test_artifact_file_not_found(self, test_project: Path):
        """Error if artifact file doesn't exist."""
        # Remove spec.md
        spec_path = test_project / '.project/active/test-item/spec.md'
        spec_path.unlink()

        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 2
        assert 'artifact file not found' in result.stderr.lower()

    def test_missing_frontmatter(self, test_project: Path):
        """Error if artifact has no frontmatter."""
        # Overwrite spec.md with no frontmatter
        spec_path = test_project / '.project/active/test-item/spec.md'
        spec_path.write_text('Just some content without frontmatter')

        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 2
        assert 'no valid frontmatter' in result.stderr.lower()


class TestUpdateArtifactContentPreservation:
    """Test that updates preserve content correctly."""

    def test_preserve_body_content(self, test_project: Path):
        """Ensure body content is preserved."""
        run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        updated_spec = (test_project / '.project/active/test-item/spec.md').read_text()

        # Body content should be unchanged
        assert 'This is the specification content.' in updated_spec
        assert '# Test Item' in updated_spec

    def test_preserve_other_frontmatter_fields(self, test_project: Path):
        """Ensure non-updated frontmatter fields are preserved."""
        run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        spec_path = test_project / '.project/active/test-item/spec.md'
        content = spec_path.read_text()

        # These fields should remain unchanged
        assert 'id: WI-001' in content
        assert 'title: Test Item' in content
        assert 'type: spec' in content
        assert 'epic: null' in content
        # YAML may reformat the created timestamp slightly
        assert 'created:' in content and '2024-01-01' in content

    def test_unicode_content_preserved(self, test_project: Path):
        """Ensure unicode content is preserved."""
        spec_path = test_project / '.project/active/test-item/spec.md'

        # Add unicode content
        spec_content = """---
id: WI-001
title: Test Item with émojis 🚀
type: spec
status: draft
epic: null
owner: José
created: 2024-01-01T00:00:00Z
updated: 2024-01-01T00:00:00Z
---

# Test Item

Unicode content: café, naïve, 日本語, 🎉
"""
        spec_path.write_text(spec_content, encoding='utf-8')

        result = run_update_artifact(
            test_project,
            'WI-001',
            '--artifact', 'spec',
            '--status', 'complete'
        )

        assert result.returncode == 0

        # Verify unicode preserved
        content = spec_path.read_text(encoding='utf-8')
        assert 'café' in content
        assert 'naïve' in content
        assert '日本語' in content
        assert '🎉' in content
        assert 'José' in content
        assert '🚀' in content
