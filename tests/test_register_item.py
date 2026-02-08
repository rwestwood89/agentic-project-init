"""Integration tests for register-item script."""

import json
import subprocess
import sys
from pathlib import Path

import pytest

from src.models.registry import Registry


@pytest.fixture
def temp_project(tmp_path: Path) -> Path:
    """Create temporary .project directory for testing.

    Args:
        tmp_path: pytest temporary directory

    Returns:
        Path to temporary .project directory
    """
    project_dir = tmp_path / '.project'
    project_dir.mkdir()
    return project_dir


@pytest.fixture
def registry_with_epic(temp_project: Path) -> Path:
    """Create registry with an epic for testing.

    Args:
        temp_project: Temporary project directory

    Returns:
        Path to registry file
    """
    from src.models.work_item import Epic

    registry = Registry(temp_project / 'registry.json')
    epic = Epic(code='EP-001', title='Test Epic', status='active')
    registry.add_epic(epic)
    registry.save()
    return temp_project / 'registry.json'


def run_register_item(
    *args: str,
    cwd: Path | None = None
) -> tuple[int, str, str]:
    """Run register-item script as subprocess.

    Args:
        *args: Command-line arguments
        cwd: Working directory for subprocess

    Returns:
        Tuple of (exit_code, stdout, stderr)
    """
    cmd = [
        sys.executable,
        '-m',
        'src.scripts.register_item',
        *args
    ]
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=cwd
    )
    return result.returncode, result.stdout, result.stderr


def test_register_backlog_item_no_epic(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test registering a backlog item without an epic."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, stdout, stderr = run_register_item(
        '--title', 'Test Item',
        '--stage', 'backlog'
    )

    assert exit_code == 0, f"Expected success, got stderr: {stderr}"

    # Parse output
    result = json.loads(stdout.strip())
    assert result['code'] == 'WI-001'
    assert result['path'] is None

    # Verify registry
    registry = Registry(temp_project / 'registry.json')
    registry.load()
    item = registry.get_item('WI-001')
    assert item is not None
    assert item.title == 'Test Item'
    assert item.stage == 'backlog'
    assert item.path is None
    assert item.epic is None

    # Verify no folder was created
    assert not (temp_project / 'active').exists()


def test_register_backlog_item_with_epic(
    registry_with_epic: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test registering a backlog item with an epic."""
    project_dir = registry_with_epic.parent
    monkeypatch.chdir(project_dir.parent)

    exit_code, stdout, stderr = run_register_item(
        '--title', 'Backlog Task',
        '--epic', 'EP-001',
        '--stage', 'backlog'
    )

    assert exit_code == 0, f"Expected success, got stderr: {stderr}"

    # Parse output
    result = json.loads(stdout.strip())
    assert result['code'] == 'WI-001'
    assert result['path'] is None

    # Verify registry
    registry = Registry(registry_with_epic)
    registry.load()
    item = registry.get_item('WI-001')
    assert item is not None
    assert item.epic == 'EP-001'


def test_register_active_item(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test registering an active item creates folder and spec.md."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, stdout, stderr = run_register_item(
        '--title', 'Active Task',
        '--stage', 'active'
    )

    assert exit_code == 0, f"Expected success, got stderr: {stderr}"

    # Parse output
    result = json.loads(stdout.strip())
    assert result['code'] == 'WI-001'
    assert result['path'] == 'active/active-task'

    # Verify registry
    registry = Registry(temp_project / 'registry.json')
    registry.load()
    item = registry.get_item('WI-001')
    assert item is not None
    assert item.title == 'Active Task'
    assert item.stage == 'active'
    assert item.path == 'active/active-task'

    # Verify folder structure
    item_dir = temp_project / 'active' / 'active-task'
    assert item_dir.exists()
    assert item_dir.is_dir()

    # Verify spec.md exists and has frontmatter
    spec_path = item_dir / 'spec.md'
    assert spec_path.exists()

    content = spec_path.read_text(encoding='utf-8')
    assert content.startswith('---\n')
    assert 'id: WI-001' in content
    assert 'title: Active Task' in content
    assert 'type: spec' in content
    assert 'status: draft' in content
    assert 'epic: null' in content
    assert '# Active Task' in content


def test_register_active_item_with_epic(
    registry_with_epic: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test registering an active item with epic."""
    project_dir = registry_with_epic.parent
    monkeypatch.chdir(project_dir.parent)

    exit_code, stdout, stderr = run_register_item(
        '--title', 'Design Auth Flow',
        '--epic', 'EP-001',
        '--stage', 'active'
    )

    assert exit_code == 0, f"Expected success, got stderr: {stderr}"

    # Parse output
    result = json.loads(stdout.strip())
    assert result['code'] == 'WI-001'
    assert result['path'] == 'active/design-auth-flow'

    # Verify spec.md has epic
    spec_path = project_dir / 'active' / 'design-auth-flow' / 'spec.md'
    content = spec_path.read_text(encoding='utf-8')
    assert 'epic: EP-001' in content


def test_title_slugification(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that titles are properly slugified for folder names."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, stdout, _ = run_register_item(
        '--title', 'Design Auth Flow!!',
        '--stage', 'active'
    )

    assert exit_code == 0
    result = json.loads(stdout.strip())
    assert result['path'] == 'active/design-auth-flow'

    # Verify folder exists with slugified name
    assert (temp_project / 'active' / 'design-auth-flow').exists()


def test_sequential_item_codes(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that sequential registrations get incrementing codes."""
    monkeypatch.chdir(temp_project.parent)

    # Register first item
    exit_code, stdout, _ = run_register_item(
        '--title', 'First Item',
        '--stage', 'backlog'
    )
    assert exit_code == 0
    result1 = json.loads(stdout.strip())
    assert result1['code'] == 'WI-001'

    # Register second item
    exit_code, stdout, _ = run_register_item(
        '--title', 'Second Item',
        '--stage', 'backlog'
    )
    assert exit_code == 0
    result2 = json.loads(stdout.strip())
    assert result2['code'] == 'WI-002'

    # Verify registry has both
    registry = Registry(temp_project / 'registry.json')
    registry.load()
    assert registry.get_item('WI-001') is not None
    assert registry.get_item('WI-002') is not None
    assert registry.next_item_id == 3


def test_default_stage_is_backlog(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that default stage is backlog when --stage not specified."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, stdout, _ = run_register_item(
        '--title', 'Default Stage Item'
    )

    assert exit_code == 0
    result = json.loads(stdout.strip())
    assert result['path'] is None

    # Verify in registry
    registry = Registry(temp_project / 'registry.json')
    registry.load()
    item = registry.get_item('WI-001')
    assert item is not None
    assert item.stage == 'backlog'


def test_invalid_epic_code_format(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that invalid epic code format returns exit code 1."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, _, stderr = run_register_item(
        '--title', 'Test Item',
        '--epic', 'INVALID'
    )

    assert exit_code == 1
    assert 'Invalid epic code format' in stderr


def test_epic_not_found(temp_project: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    """Test that referencing non-existent epic returns exit code 1."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, _, stderr = run_register_item(
        '--title', 'Test Item',
        '--epic', 'EP-999'
    )

    assert exit_code == 1
    assert 'Epic EP-999 not found' in stderr


def test_missing_title_argument(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that missing --title returns non-zero exit code."""
    monkeypatch.chdir(temp_project.parent)

    exit_code, _, stderr = run_register_item(
        '--stage', 'backlog'
    )

    assert exit_code != 0
    assert 'required' in stderr.lower() or 'title' in stderr.lower()


def test_registry_corruption_handling(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that corrupted registry returns exit code 2."""
    monkeypatch.chdir(temp_project.parent)

    # Create invalid registry
    registry_path = temp_project / 'registry.json'
    registry_path.write_text('{"invalid": "data"}', encoding='utf-8')

    exit_code, _, stderr = run_register_item(
        '--title', 'Test Item'
    )

    assert exit_code == 2
    assert 'Failed to load registry' in stderr


def test_idempotent_folder_creation(
    temp_project: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test that script handles existing folders gracefully."""
    monkeypatch.chdir(temp_project.parent)

    # Pre-create the active directory
    (temp_project / 'active').mkdir()

    exit_code, stdout, _ = run_register_item(
        '--title', 'Test Item',
        '--stage', 'active'
    )

    assert exit_code == 0
    result = json.loads(stdout.strip())
    assert result['path'] == 'active/test-item'
