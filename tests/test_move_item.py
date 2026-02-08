"""Tests for move-item script."""

import json
import shutil

import pytest

from src.scripts.move_item import check_epic_completion, main, update_changelog


@pytest.fixture
def test_project(tmp_path):
    """Create a test project structure."""
    project_root = tmp_path / '.project'
    project_root.mkdir()

    # Create stage directories
    (project_root / 'active').mkdir()
    (project_root / 'completed').mkdir()

    # Create registry
    registry_data = {
        'epics': {
            'EP-001': {
                'title': 'Test Epic',
                'status': 'active',
                'created': '2026-02-08T10:00:00+00:00'
            }
        },
        'items': {
            'WI-001': {
                'title': 'Backlog Item',
                'epic': 'EP-001',
                'stage': 'backlog',
                'path': None
            },
            'WI-002': {
                'title': 'Active Item',
                'epic': 'EP-001',
                'stage': 'active',
                'path': 'active/active-item'
            },
            'WI-003': {
                'title': 'Another Active Item',
                'epic': 'EP-001',
                'stage': 'active',
                'path': 'active/another-active-item'
            },
            'WI-004': {
                'title': 'Completed Item',
                'epic': 'EP-001',
                'stage': 'completed',
                'path': 'completed/2026-02-01_completed-item'
            }
        },
        'next_epic_id': 2,
        'next_item_id': 5
    }

    registry_path = project_root / 'registry.json'
    registry_path.write_text(json.dumps(registry_data, indent=2))

    # Create active item folder with spec.md
    active_folder = project_root / 'active' / 'active-item'
    active_folder.mkdir(parents=True)
    (active_folder / 'spec.md').write_text('# Active Item\n\nTest content')

    another_active_folder = project_root / 'active' / 'another-active-item'
    another_active_folder.mkdir(parents=True)
    (another_active_folder / 'spec.md').write_text('# Another Active Item')

    return tmp_path


def test_move_backlog_to_active(test_project, monkeypatch):
    """Test moving item from backlog to active stage."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-001', '--to', 'active']
    )

    exit_code = main()

    assert exit_code == 0

    # Verify folder was created
    folder = test_project / '.project' / 'active' / 'backlog-item'
    assert folder.exists()
    assert folder.is_dir()

    # Verify spec.md was created
    spec_path = folder / 'spec.md'
    assert spec_path.exists()
    spec_content = spec_path.read_text()
    assert 'id: WI-001' in spec_content
    assert 'title: Backlog Item' in spec_content
    assert 'epic: EP-001' in spec_content

    # Verify registry was updated
    registry = json.loads(
        (test_project / '.project' / 'registry.json').read_text()
    )
    assert registry['items']['WI-001']['stage'] == 'active'
    assert registry['items']['WI-001']['path'] == 'active/backlog-item'


def test_move_active_to_completed(test_project, monkeypatch):
    """Test moving item from active to completed stage."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-002', '--to', 'completed']
    )

    exit_code = main()

    assert exit_code == 0

    # Verify old folder was moved
    old_folder = test_project / '.project' / 'active' / 'active-item'
    assert not old_folder.exists()

    # Verify new folder exists with date prefix
    completed_dir = test_project / '.project' / 'completed'
    completed_folders = list(completed_dir.glob('*_active-item'))
    assert len(completed_folders) == 1
    new_folder = completed_folders[0]

    # Verify spec.md was preserved
    assert (new_folder / 'spec.md').exists()

    # Verify CHANGELOG.md was created
    changelog = new_folder / 'CHANGELOG.md'
    assert changelog.exists()
    changelog_content = changelog.read_text()
    assert 'WI-002' in changelog_content
    assert 'Active Item' in changelog_content
    assert 'Completed' in changelog_content

    # Verify registry was updated
    registry = json.loads(
        (test_project / '.project' / 'registry.json').read_text()
    )
    assert registry['items']['WI-002']['stage'] == 'completed'
    assert 'completed/' in registry['items']['WI-002']['path']
    assert '_active-item' in registry['items']['WI-002']['path']


def test_move_active_to_backlog(test_project, monkeypatch):
    """Test moving item from active back to backlog."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-002', '--to', 'backlog']
    )

    exit_code = main()

    assert exit_code == 0

    # Verify folder was removed
    folder = test_project / '.project' / 'active' / 'active-item'
    assert not folder.exists()

    # Verify registry was updated
    registry = json.loads(
        (test_project / '.project' / 'registry.json').read_text()
    )
    assert registry['items']['WI-002']['stage'] == 'backlog'
    assert registry['items']['WI-002']['path'] is None


def test_invalid_transition_backlog_to_completed(test_project, monkeypatch):
    """Test that backlog cannot move directly to completed."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-001', '--to', 'completed']
    )

    exit_code = main()

    assert exit_code == 2


def test_invalid_transition_completed_to_active(test_project, monkeypatch):
    """Test that completed items cannot be moved."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-004', '--to', 'active']
    )

    exit_code = main()

    assert exit_code == 2


def test_already_in_target_stage(test_project, monkeypatch):
    """Test error when item is already in target stage."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-001', '--to', 'backlog']
    )

    exit_code = main()

    assert exit_code == 2


def test_item_not_found(test_project, monkeypatch):
    """Test error when item code doesn't exist."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-999', '--to', 'active']
    )

    exit_code = main()

    assert exit_code == 1


def test_epic_completion_check(test_project, monkeypatch):
    """Test that epic is marked complete when all items are completed."""
    monkeypatch.chdir(test_project)

    # Move WI-002 to completed
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-002', '--to', 'completed']
    )
    main()

    # Move WI-003 to completed (should trigger epic completion)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-003', '--to', 'completed']
    )
    exit_code = main()

    assert exit_code == 0

    # Verify epic status was updated
    registry = json.loads(
        (test_project / '.project' / 'registry.json').read_text()
    )

    # Epic should NOT be complete yet because WI-001 is still in backlog
    # and WI-004 was already completed
    assert registry['epics']['EP-001']['status'] == 'active'


def test_epic_completion_all_items(test_project, monkeypatch):
    """Test epic completion when truly all items are completed."""
    monkeypatch.chdir(test_project)

    # Move all non-completed items to completed
    for item_code in ['WI-001', 'WI-002', 'WI-003']:
        # First move WI-001 to active
        if item_code == 'WI-001':
            monkeypatch.setattr(
                'sys.argv',
                ['move-item', item_code, '--to', 'active']
            )
            main()

        # Then move to completed
        monkeypatch.setattr(
            'sys.argv',
            ['move-item', item_code, '--to', 'completed']
        )
        main()

    # Verify epic status
    registry = json.loads(
        (test_project / '.project' / 'registry.json').read_text()
    )
    assert registry['epics']['EP-001']['status'] == 'completed'


def test_update_changelog_creates_file(tmp_path):
    """Test that update_changelog creates a new CHANGELOG.md."""
    folder = tmp_path / 'test-item'
    folder.mkdir()

    update_changelog(folder, 'WI-005', 'Test Item')

    changelog = folder / 'CHANGELOG.md'
    assert changelog.exists()

    content = changelog.read_text()
    assert 'WI-005' in content
    assert 'Test Item' in content
    assert 'Completed' in content


def test_update_changelog_prepends_to_existing(tmp_path):
    """Test that update_changelog prepends to existing file."""
    folder = tmp_path / 'test-item'
    folder.mkdir()

    changelog = folder / 'CHANGELOG.md'
    changelog.write_text('# Existing Entry\n\nOld content')

    update_changelog(folder, 'WI-006', 'New Entry')

    content = changelog.read_text()
    assert 'WI-006' in content
    assert 'New Entry' in content
    assert 'Existing Entry' in content
    # New entry should come before old content
    assert content.index('WI-006') < content.index('Existing Entry')


def test_check_epic_completion_helper(test_project, monkeypatch):
    """Test the check_epic_completion helper function."""
    from src.models.registry import Registry

    monkeypatch.chdir(test_project)
    registry = Registry()
    registry.load()

    # Not all items are completed
    assert not check_epic_completion(registry, 'EP-001')

    # Mark all items as completed
    for item in registry.items.values():
        item.stage = 'completed'

    assert check_epic_completion(registry, 'EP-001')


def test_missing_folder_for_active_item(test_project, monkeypatch):
    """Test error when active item folder doesn't exist."""
    monkeypatch.chdir(test_project)

    # Remove the folder but keep registry entry
    folder = test_project / '.project' / 'active' / 'active-item'
    shutil.rmtree(folder)

    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'WI-002', '--to', 'completed']
    )

    exit_code = main()

    assert exit_code == 2


def test_case_insensitive_code(test_project, monkeypatch):
    """Test that item codes are case-insensitive."""
    monkeypatch.chdir(test_project)
    monkeypatch.setattr(
        'sys.argv',
        ['move-item', 'wi-001', '--to', 'active']  # lowercase
    )

    exit_code = main()

    assert exit_code == 0

    # Verify the item was found and moved
    registry = json.loads(
        (test_project / '.project' / 'registry.json').read_text()
    )
    assert registry['items']['WI-001']['stage'] == 'active'
