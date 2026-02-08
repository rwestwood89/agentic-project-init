"""Tests for generate_dashboard script."""

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from src.models.registry import Registry
from src.models.work_item import Epic, WorkItem
from src.scripts.generate_dashboard import (
    extract_completion_date,
    get_artifact_progress,
    main,
    render_dashboard_html,
)


@pytest.fixture
def temp_project(tmp_path: Path) -> Path:
    """Create temporary project directory structure."""
    project_dir = tmp_path / ".project"
    project_dir.mkdir()
    return tmp_path


@pytest.fixture
def registry_with_items(temp_project: Path) -> Registry:
    """Create registry with sample epics and items."""
    registry = Registry(temp_project / ".project" / "registry.json")

    # Add epics
    registry.add_epic(
        Epic(code="EP-001", title="Authentication System", status="active")
    )
    registry.add_epic(
        Epic(code="EP-002", title="Dashboard Features", status="active")
    )

    # Add items in different stages
    registry.add_item(WorkItem(
        code="WI-001",
        title="Login page",
        epic="EP-001",
        stage="backlog",
        path=None
    ))
    registry.add_item(WorkItem(
        code="WI-002",
        title="User registration",
        epic="EP-001",
        stage="active",
        path="active/user-registration"
    ))
    registry.add_item(WorkItem(
        code="WI-003",
        title="Password reset",
        epic="EP-001",
        stage="completed",
        path="completed/2026-02-08_password-reset"
    ))
    registry.add_item(WorkItem(
        code="WI-004",
        title="Kanban board",
        epic="EP-002",
        stage="active",
        path="active/kanban-board"
    ))
    registry.add_item(WorkItem(
        code="WI-005",
        title="Analytics page",
        epic=None,
        stage="backlog",
        path=None
    ))

    registry.save()
    return registry


def test_extract_completion_date_with_date_prefix():
    """Test extracting completion date from completed item path."""
    path = "completed/2026-02-08_item-name"
    assert extract_completion_date(path) == "2026-02-08"


def test_extract_completion_date_without_date():
    """Test extracting completion date from path without date prefix."""
    path = "completed/item-name"
    assert extract_completion_date(path) is None


def test_extract_completion_date_active_item():
    """Test extracting completion date from active item (should be None)."""
    path = "active/item-name"
    assert extract_completion_date(path) is None


def test_extract_completion_date_none():
    """Test extracting completion date from None path."""
    assert extract_completion_date(None) is None


def test_get_artifact_progress_no_path():
    """Test get_artifact_progress with None path."""
    progress = get_artifact_progress(None)
    assert progress['spec_status'] is None
    assert progress['design_status'] is None
    assert progress['plan_status'] is None


def test_get_artifact_progress_with_artifacts(temp_project: Path):
    """Test get_artifact_progress with actual artifact files."""
    # Create item directory with artifacts
    item_dir = temp_project / ".project" / "active" / "test-item"
    item_dir.mkdir(parents=True)

    # Create spec.md with frontmatter
    spec_content = """---
id: WI-001
title: Test Item
type: work-item
status: complete
owner: Alice
created: 2026-02-01
updated: 2026-02-05
---
# Test Item Spec
"""
    (item_dir / "spec.md").write_text(spec_content, encoding='utf-8')

    # Create design.md with frontmatter
    design_content = """---
id: WI-001
title: Test Item
type: design
status: in-progress
updated: 2026-02-06
---
# Test Item Design
"""
    (item_dir / "design.md").write_text(design_content, encoding='utf-8')

    # Create plan.md with phases
    plan_content = """---
id: WI-001
title: Test Item
type: plan
status: in-progress
phases_total: 5
phases_complete: 3
updated: 2026-02-07
---
# Test Item Plan
"""
    (item_dir / "plan.md").write_text(plan_content, encoding='utf-8')

    # Test extraction
    progress = get_artifact_progress("active/test-item", temp_project)
    assert progress['spec_status'] == 'complete'
    assert progress['design_status'] == 'in-progress'
    assert progress['plan_status'] == 'in-progress'
    assert progress['phases_complete'] == 3
    assert progress['phases_total'] == 5
    assert progress['owner'] == 'Alice'
    # PyYAML parses dates as datetime.date objects, convert to string for comparison
    assert str(progress['created']) == '2026-02-01'
    assert str(progress['updated']) == '2026-02-07'  # Latest update


def test_get_artifact_progress_missing_files(temp_project: Path):
    """Test get_artifact_progress with missing artifact files."""
    item_dir = temp_project / ".project" / "active" / "test-item"
    item_dir.mkdir(parents=True)

    progress = get_artifact_progress("active/test-item", temp_project)
    assert progress['spec_status'] is None
    assert progress['design_status'] is None
    assert progress['plan_status'] is None


def test_render_dashboard_html(registry_with_items: Registry, temp_project: Path):
    """Test rendering complete HTML dashboard."""
    html = render_dashboard_html(registry_with_items, temp_project)

    # Verify HTML structure
    assert '<!DOCTYPE html>' in html
    assert '<title>Project Dashboard</title>' in html
    assert 'Last generated:' in html

    # Verify JSON data injection
    assert '"backlog"' in html
    assert '"active"' in html
    assert '"completed"' in html

    # Verify epic codes are present
    assert 'EP-001' in html
    assert 'EP-002' in html

    # Verify item codes are present
    assert 'WI-001' in html
    assert 'WI-002' in html
    assert 'WI-003' in html
    assert 'WI-004' in html
    assert 'WI-005' in html

    # Verify item titles are present
    assert 'Login page' in html
    assert 'User registration' in html
    assert 'Password reset' in html


def test_render_dashboard_html_empty_registry(temp_project: Path):
    """Test rendering dashboard with empty registry."""
    registry = Registry(temp_project / ".project" / "registry.json")
    html = render_dashboard_html(registry, temp_project)

    # Should still generate valid HTML
    assert '<!DOCTYPE html>' in html
    assert '<title>Project Dashboard</title>' in html


def test_main_success(registry_with_items: Registry, temp_project: Path):
    """Test main function with successful dashboard generation."""
    # Output should be: project_root / relative_path
    output_path = temp_project / "dashboard.html"

    with patch(
        'sys.argv',
        [
            'generate-dashboard',
            '--output',
            'dashboard.html',
            '--project-root',
            str(temp_project),
        ],
    ):
        with patch('src.scripts.generate_dashboard.Registry') as mock_registry_class:
            mock_registry = mock_registry_class.return_value
            mock_registry.load.return_value = None
            mock_registry.items = registry_with_items.items
            mock_registry.epics = registry_with_items.epics

            exit_code = main()

    assert exit_code == 0
    assert output_path.exists()

    # Verify dashboard content
    html = output_path.read_text(encoding='utf-8')
    assert '<!DOCTYPE html>' in html
    assert 'WI-001' in html


def test_main_missing_registry(temp_project: Path, capsys):
    """Test main function when registry.json is missing."""
    with patch(
        'sys.argv',
        [
            'generate-dashboard',
            '--output',
            'dashboard.html',
            '--project-root',
            str(temp_project),
        ],
    ):
        exit_code = main()

    assert exit_code == 2
    captured = capsys.readouterr()
    assert 'registry.json not found' in captured.err

    # Verify JSON output
    output = json.loads(captured.out.strip())
    assert output['error'] == 'registry_not_found'


def test_main_invalid_registry(temp_project: Path, capsys):
    """Test main function with corrupted registry.json."""
    registry_path = temp_project / ".project" / "registry.json"
    registry_path.parent.mkdir(parents=True, exist_ok=True)
    registry_path.write_text("invalid json {{{", encoding='utf-8')

    with patch(
        'sys.argv',
        [
            'generate-dashboard',
            '--output',
            'dashboard.html',
            '--project-root',
            str(temp_project),
        ],
    ):
        exit_code = main()

    assert exit_code == 2
    captured = capsys.readouterr()
    assert 'Invalid registry format' in captured.err


def test_main_default_output_path(registry_with_items: Registry, temp_project: Path):
    """Test main function with default output path."""
    # Create registry in temp_project so the check passes
    registry_path = temp_project / ".project" / "registry.json"
    registry_path.parent.mkdir(parents=True, exist_ok=True)
    registry_with_items.registry_path = registry_path
    registry_with_items.save()

    with patch('sys.argv', ['generate-dashboard', '--project-root', str(temp_project)]):
        exit_code = main()

    assert exit_code == 0

    # Verify default output location (relative to project root)
    default_path = temp_project / '.project/dashboard.html'
    assert default_path.exists()


def test_dashboard_includes_completion_date(temp_project: Path):
    """Test that completed items show completion date."""
    registry = Registry(temp_project / ".project" / "registry.json")
    registry.add_item(WorkItem(
        code="WI-001",
        title="Completed item",
        epic=None,
        stage="completed",
        path="completed/2026-02-08_completed-item"
    ))

    html = render_dashboard_html(registry, temp_project)
    assert '2026-02-08' in html


def test_dashboard_progress_badges(temp_project: Path):
    """Test that active items show progress badges."""
    registry = Registry(temp_project / ".project" / "registry.json")
    registry.add_item(WorkItem(
        code="WI-001",
        title="Active item",
        epic=None,
        stage="active",
        path="active/active-item"
    ))

    # Create artifact with status
    item_dir = temp_project / ".project" / "active" / "active-item"
    item_dir.mkdir(parents=True)

    spec_content = """---
id: WI-001
status: complete
---
# Spec
"""
    (item_dir / "spec.md").write_text(spec_content, encoding='utf-8')

    design_content = """---
id: WI-001
status: in-progress
---
# Design
"""
    (item_dir / "design.md").write_text(design_content, encoding='utf-8')

    html = render_dashboard_html(registry, temp_project)

    # Check that badge CSS classes are referenced
    assert 'badge' in html
    assert 'complete' in html or 'in-progress' in html


def test_dashboard_progress_bar(temp_project: Path):
    """Test that items with phases show progress bar."""
    registry = Registry(temp_project / ".project" / "registry.json")
    registry.add_item(WorkItem(
        code="WI-001",
        title="Item with phases",
        epic=None,
        stage="active",
        path="active/item-with-phases"
    ))

    # Create plan with phases
    item_dir = temp_project / ".project" / "active" / "item-with-phases"
    item_dir.mkdir(parents=True)

    plan_content = """---
id: WI-001
status: in-progress
phases_total: 5
phases_complete: 3
---
# Plan
"""
    (item_dir / "plan.md").write_text(plan_content, encoding='utf-8')

    html = render_dashboard_html(registry, temp_project)

    # Check that progress bar elements are present
    assert 'progress-bar' in html
    # The JavaScript will compute 60% (3/5)


def test_dashboard_click_to_copy_javascript(
    registry_with_items: Registry, temp_project: Path
):
    """Test that JavaScript for click-to-copy is included."""
    html = render_dashboard_html(registry_with_items, temp_project)

    # Verify JavaScript functions are present
    assert 'copyToClipboard' in html
    assert 'navigator.clipboard.writeText' in html


def test_dashboard_tooltips(registry_with_items: Registry, temp_project: Path):
    """Test that tooltip CSS and structure is included."""
    html = render_dashboard_html(registry_with_items, temp_project)

    # Verify tooltip CSS
    assert '.tooltip' in html
    assert 'tooltip-label' in html


def test_dashboard_self_contained(registry_with_items: Registry, temp_project: Path):
    """Test that dashboard HTML is self-contained (no CDN links)."""
    html = render_dashboard_html(registry_with_items, temp_project)

    # Should not have any external links
    assert 'cdn.' not in html.lower()
    assert 'http://' not in html
    assert 'https://' not in html

    # Should have embedded CSS
    assert '<style>' in html
    assert '</style>' in html

    # Should have embedded JavaScript
    assert '<script>' in html
    assert '</script>' in html


def test_dashboard_epic_progress_calculation(temp_project: Path):
    """Test that epic progress is calculated correctly."""
    registry = Registry(temp_project / ".project" / "registry.json")

    # Add epic
    registry.add_epic(Epic(code="EP-001", title="Test Epic", status="active"))

    # Add items: 2 completed, 3 total
    registry.add_item(WorkItem(
        code="WI-001",
        title="Item 1",
        epic="EP-001",
        stage="completed",
        path="completed/2026-02-08_item-1"
    ))
    registry.add_item(WorkItem(
        code="WI-002",
        title="Item 2",
        epic="EP-001",
        stage="completed",
        path="completed/2026-02-08_item-2"
    ))
    registry.add_item(WorkItem(
        code="WI-003",
        title="Item 3",
        epic="EP-001",
        stage="active",
        path="active/item-3"
    ))

    html = render_dashboard_html(registry, temp_project)

    # Epic should show 2/3 completed (66%)
    # This will be in the JavaScript data
    assert 'EP-001' in html


def test_dashboard_ungrouped_items(temp_project: Path):
    """Test that items without epics appear in ungrouped section."""
    registry = Registry(temp_project / ".project" / "registry.json")

    registry.add_item(WorkItem(
        code="WI-001",
        title="Ungrouped item",
        epic=None,
        stage="active",
        path="active/ungrouped-item"
    ))

    html = render_dashboard_html(registry, temp_project)

    # Should have reference to ungrouped section
    assert 'ungrouped' in html.lower() or 'no epic' in html.lower()
