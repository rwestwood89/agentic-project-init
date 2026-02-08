"""Tests for watch-project script (file watcher)."""

import json
import time
from pathlib import Path
from threading import Thread

import pytest

from src.scripts.watch_project import DebouncedDashboardRegeneration


@pytest.fixture
def temp_project(tmp_path: Path) -> Path:
    """Create a temporary project directory structure.

    Args:
        tmp_path: Pytest temporary path fixture

    Returns:
        Path to temporary project root
    """
    project_dir = tmp_path / '.project'
    project_dir.mkdir()

    # Create registry.json
    registry_path = project_dir / 'registry.json'
    registry_data = {
        'epics': [],
        'items': [],
        'next_epic_id': 1,
        'next_item_id': 1,
    }
    registry_path.write_text(json.dumps(registry_data, indent=2))

    # Create active directory with sample artifact
    active_dir = project_dir / 'active' / 'test-item'
    active_dir.mkdir(parents=True)
    spec_path = active_dir / 'spec.md'
    spec_path.write_text(
        '---\n'
        'id: WI-001\n'
        'title: Test Item\n'
        'status: draft\n'
        '---\n'
        '\n'
        'Test content\n'
    )

    return tmp_path


def test_debounce_multiple_rapid_changes(temp_project: Path) -> None:
    """Test that multiple rapid changes trigger only one regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,  # Short debounce for testing
        project_root=temp_project,
        output_path=output_path,
    )
    # Replace regenerate method with mock
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    # Create mock events
    from watchdog.events import FileModifiedEvent

    registry_path = temp_project / '.project' / 'registry.json'

    # Trigger 5 rapid changes
    for _ in range(5):
        event = FileModifiedEvent(str(registry_path))
        handler.on_modified(event)
        time.sleep(0.01)  # 10ms between changes

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should only regenerate once
    assert regeneration_count == 1


def test_ignore_dashboard_html_changes(temp_project: Path) -> None:
    """Test that changes to dashboard.html do not trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileModifiedEvent

    dashboard_path = temp_project / '.project' / 'dashboard.html'

    # Trigger change to dashboard.html
    event = FileModifiedEvent(str(dashboard_path))
    handler.on_modified(event)

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should not regenerate (infinite loop prevention)
    assert regeneration_count == 0


def test_watch_registry_json_changes(temp_project: Path) -> None:
    """Test that registry.json changes trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileModifiedEvent

    registry_path = temp_project / '.project' / 'registry.json'

    # Trigger change to registry.json
    event = FileModifiedEvent(str(registry_path))
    handler.on_modified(event)

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should regenerate once
    assert regeneration_count == 1


def test_watch_artifact_files(temp_project: Path) -> None:
    """Test that artifact file changes trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_times: list[str] = []

    def mock_regenerate() -> None:
        """Mock regeneration function that tracks calls."""
        regeneration_times.append(time.strftime('%H:%M:%S.%f'))

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileModifiedEvent

    # Test spec.md
    spec_path = temp_project / '.project' / 'active' / 'test-item' / 'spec.md'
    event = FileModifiedEvent(str(spec_path))
    handler.on_modified(event)
    time.sleep(0.25)  # Wait for regeneration to complete
    assert len(regeneration_times) == 1

    # Test design.md (create file first to make test more realistic)
    design_path = temp_project / '.project' / 'active' / 'test-item' / 'design.md'
    design_path.write_text('# Design')
    event = FileModifiedEvent(str(design_path))
    handler.on_modified(event)
    time.sleep(0.25)  # Wait for regeneration to complete
    assert len(regeneration_times) == 2

    # Test plan.md
    plan_path = temp_project / '.project' / 'active' / 'test-item' / 'plan.md'
    plan_path.write_text('# Plan')
    event = FileModifiedEvent(str(plan_path))
    handler.on_modified(event)
    time.sleep(0.25)  # Wait for regeneration to complete
    assert len(regeneration_times) == 3


def test_ignore_directory_events(temp_project: Path) -> None:
    """Test that directory events do not trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import DirModifiedEvent

    active_dir = temp_project / '.project' / 'active'

    # Trigger directory change
    event = DirModifiedEvent(str(active_dir))
    handler.on_modified(event)

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should not regenerate
    assert regeneration_count == 0


def test_ignore_other_files(temp_project: Path) -> None:
    """Test that non-artifact files do not trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileModifiedEvent

    # Test random file
    random_path = temp_project / '.project' / 'README.md'
    random_path.write_text('# README')
    event = FileModifiedEvent(str(random_path))
    handler.on_modified(event)

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should not regenerate
    assert regeneration_count == 0


def test_on_created_event(temp_project: Path) -> None:
    """Test that file creation events trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileCreatedEvent

    spec_path = temp_project / '.project' / 'active' / 'new-item' / 'spec.md'

    # Trigger file creation
    event = FileCreatedEvent(str(spec_path))
    handler.on_created(event)

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should regenerate once
    assert regeneration_count == 1


def test_on_deleted_event(temp_project: Path) -> None:
    """Test that file deletion events trigger regeneration."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileDeletedEvent

    spec_path = temp_project / '.project' / 'active' / 'test-item' / 'spec.md'

    # Trigger file deletion
    event = FileDeletedEvent(str(spec_path))
    handler.on_deleted(event)

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should regenerate once
    assert regeneration_count == 1


def test_timer_cancellation_on_rapid_changes(temp_project: Path) -> None:
    """Test that timers are properly cancelled on rapid changes."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0
    regeneration_times: list[float] = []

    def mock_regenerate() -> None:
        """Mock regeneration function that tracks timing."""
        nonlocal regeneration_count
        regeneration_count += 1
        regeneration_times.append(time.time())

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.2,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileModifiedEvent

    registry_path = temp_project / '.project' / 'registry.json'

    start_time = time.time()

    # Trigger 3 changes with delays
    for i in range(3):
        event = FileModifiedEvent(str(registry_path))
        handler.on_modified(event)
        time.sleep(0.1)  # 100ms between changes

    # Wait for debounce period plus buffer
    time.sleep(0.4)

    # Should only regenerate once
    assert regeneration_count == 1

    # Regeneration should happen after last change + debounce period
    # Last change at ~200ms, regeneration should be at ~400ms
    elapsed = regeneration_times[0] - start_time
    assert 0.3 < elapsed < 0.6


def test_shutdown(temp_project: Path) -> None:
    """Test graceful shutdown of event handler."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.2,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    # Schedule a regeneration
    from watchdog.events import FileModifiedEvent

    registry_path = temp_project / '.project' / 'registry.json'
    event = FileModifiedEvent(str(registry_path))
    handler.on_modified(event)

    # Shutdown before timer fires
    handler.shutdown()

    # Verify shutdown event is set
    assert handler.shutdown_event.is_set()

    # Wait to ensure timer would have fired if not cancelled
    time.sleep(0.3)

    # Regeneration should not have occurred because timer was cancelled
    assert regeneration_count == 0


def test_concurrent_events(temp_project: Path) -> None:
    """Test that concurrent events from different threads are handled correctly."""
    output_path = temp_project / '.project' / 'dashboard.html'
    regeneration_count = 0

    def mock_regenerate() -> None:
        """Mock regeneration function that increments counter."""
        nonlocal regeneration_count
        regeneration_count += 1

    handler = DebouncedDashboardRegeneration(
        debounce_seconds=0.1,
        project_root=temp_project,
        output_path=output_path,
    )
    handler._regenerate_dashboard = mock_regenerate  # type: ignore

    from watchdog.events import FileModifiedEvent

    def trigger_event(path: Path) -> None:
        """Trigger a file modification event."""
        event = FileModifiedEvent(str(path))
        handler.on_modified(event)

    # Trigger events from multiple threads
    threads = []
    paths = [
        temp_project / '.project' / 'registry.json',
        temp_project / '.project' / 'active' / 'test-item' / 'spec.md',
    ]

    for path in paths:
        thread = Thread(target=trigger_event, args=(path,))
        thread.start()
        threads.append(thread)

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Wait for debounce period plus buffer
    time.sleep(0.3)

    # Should only regenerate once despite concurrent events
    assert regeneration_count == 1
