"""Tests for registry data model."""

import json

import pytest

from src.models.registry import Registry
from src.models.work_item import Epic, WorkItem


class TestEpic:
    """Test Epic model."""

    def test_valid_epic(self):
        """Test creating a valid epic."""
        epic = Epic(code="EP-001", title="Auth System", status="active")
        assert epic.code == "EP-001"
        assert epic.title == "Auth System"
        assert epic.status == "active"

    def test_invalid_epic_code(self):
        """Test epic with invalid code format raises ValueError."""
        with pytest.raises(ValueError, match="Invalid epic code format"):
            Epic(code="EP001", title="Test", status="active")

        with pytest.raises(ValueError, match="Invalid epic code format"):
            Epic(code="WI-001", title="Test", status="active")

    def test_invalid_epic_status(self):
        """Test epic with invalid status raises ValueError."""
        with pytest.raises(ValueError, match="Invalid epic status"):
            Epic(code="EP-001", title="Test", status="pending")

    def test_epic_to_dict(self):
        """Test epic serialization to dict."""
        epic = Epic(code="EP-002", title="Dashboard", status="completed")
        data = epic.to_dict()
        assert data == {
            "title": "Dashboard",
            "status": "completed",
        }
        # Code not included in dict (used as key in registry)
        assert "code" not in data

    def test_epic_from_dict(self):
        """Test epic deserialization from dict."""
        data = {"title": "API Layer", "status": "active"}
        epic = Epic.from_dict("EP-003", data)
        assert epic.code == "EP-003"
        assert epic.title == "API Layer"
        assert epic.status == "active"


class TestWorkItem:
    """Test WorkItem model."""

    def test_valid_work_item(self):
        """Test creating a valid work item."""
        item = WorkItem(
            code="WI-001",
            title="Implement login",
            epic="EP-001",
            stage="active",
            path="active/implement-login"
        )
        assert item.code == "WI-001"
        assert item.title == "Implement login"
        assert item.epic == "EP-001"
        assert item.stage == "active"
        assert item.path == "active/implement-login"

    def test_work_item_without_epic(self):
        """Test work item without epic assignment."""
        item = WorkItem(
            code="WI-002",
            title="Fix bug",
            epic=None,
            stage="backlog",
            path=None
        )
        assert item.epic is None

    def test_backlog_item_with_null_path(self):
        """Test backlog items must have path=null."""
        item = WorkItem(
            code="WI-003",
            title="Research task",
            epic=None,
            stage="backlog",
            path=None
        )
        assert item.path is None

    def test_backlog_item_with_path_fails(self):
        """Test backlog items cannot have a path."""
        with pytest.raises(ValueError, match="Backlog items must have path=null"):
            WorkItem(
                code="WI-004",
                title="Invalid",
                epic=None,
                stage="backlog",
                path="backlog/invalid"
            )

    def test_invalid_work_item_code(self):
        """Test work item with invalid code format raises ValueError."""
        with pytest.raises(ValueError, match="Invalid work item code format"):
            WorkItem(
                code="WI001",
                title="Test",
                epic=None,
                stage="active",
                path="active/test"
            )

    def test_invalid_stage(self):
        """Test work item with invalid stage raises ValueError."""
        with pytest.raises(ValueError, match="Invalid stage"):
            WorkItem(
                code="WI-005",
                title="Test",
                epic=None,
                stage="pending",
                path=None
            )

    def test_invalid_epic_reference(self):
        """Test work item with invalid epic code raises ValueError."""
        with pytest.raises(ValueError, match="Invalid epic code reference"):
            WorkItem(
                code="WI-006",
                title="Test",
                epic="INVALID",
                stage="active",
                path="active/test"
            )

    def test_work_item_to_dict(self):
        """Test work item serialization to dict."""
        item = WorkItem(
            code="WI-007",
            title="Build dashboard",
            epic="EP-002",
            stage="completed",
            path="completed/build-dashboard"
        )
        data = item.to_dict()
        assert data == {
            "title": "Build dashboard",
            "epic": "EP-002",
            "stage": "completed",
            "path": "completed/build-dashboard",
        }

    def test_work_item_from_dict(self):
        """Test work item deserialization from dict."""
        data = {
            "title": "Write tests",
            "epic": None,
            "stage": "active",
            "path": "active/write-tests"
        }
        item = WorkItem.from_dict("WI-008", data)
        assert item.code == "WI-008"
        assert item.title == "Write tests"
        assert item.epic is None
        assert item.stage == "active"
        assert item.path == "active/write-tests"


class TestRegistry:
    """Test Registry model."""

    @pytest.fixture
    def temp_registry_path(self, tmp_path):
        """Provide temporary registry path."""
        return tmp_path / "registry.json"

    @pytest.fixture
    def sample_registry_data(self):
        """Provide sample registry data."""
        return {
            "epics": {
                "EP-001": {
                    "title": "Authentication",
                    "status": "active"
                },
                "EP-002": {
                    "title": "Dashboard",
                    "status": "completed"
                }
            },
            "items": {
                "WI-001": {
                    "title": "Implement login",
                    "epic": "EP-001",
                    "stage": "active",
                    "path": "active/implement-login"
                },
                "WI-002": {
                    "title": "Research OAuth",
                    "epic": "EP-001",
                    "stage": "backlog",
                    "path": None
                },
                "WI-003": {
                    "title": "Build Kanban view",
                    "epic": "EP-002",
                    "stage": "completed",
                    "path": "completed/build-kanban-view"
                }
            },
            "next_epic_id": 3,
            "next_item_id": 4
        }

    def test_load_nonexistent_file(self, temp_registry_path):
        """Test loading when registry file doesn't exist."""
        registry = Registry(temp_registry_path)
        registry.load()

        assert len(registry.epics) == 0
        assert len(registry.items) == 0
        assert registry.next_epic_id == 1
        assert registry.next_item_id == 1

    def test_load_valid_registry(self, temp_registry_path, sample_registry_data):
        """Test loading a valid registry file."""
        # Write sample data
        with open(temp_registry_path, 'w') as f:
            json.dump(sample_registry_data, f)

        # Load and validate
        registry = Registry(temp_registry_path)
        registry.load()

        assert len(registry.epics) == 2
        assert len(registry.items) == 3
        assert registry.next_epic_id == 3
        assert registry.next_item_id == 4

        # Check epic parsing
        ep1 = registry.get_epic("EP-001")
        assert ep1 is not None
        assert ep1.title == "Authentication"
        assert ep1.status == "active"

        # Check item parsing
        wi1 = registry.get_item("WI-001")
        assert wi1 is not None
        assert wi1.title == "Implement login"
        assert wi1.epic == "EP-001"
        assert wi1.stage == "active"
        assert wi1.path == "active/implement-login"

        # Check backlog item
        wi2 = registry.get_item("WI-002")
        assert wi2 is not None
        assert wi2.stage == "backlog"
        assert wi2.path is None

    def test_load_missing_keys(self, temp_registry_path):
        """Test loading registry with missing required keys."""
        bad_data = {
            "epics": {},
            "items": {}
            # Missing next_epic_id and next_item_id
        }
        with open(temp_registry_path, 'w') as f:
            json.dump(bad_data, f)

        registry = Registry(temp_registry_path)
        with pytest.raises(ValueError, match="Missing required keys"):
            registry.load()

    def test_load_invalid_epic_code(self, temp_registry_path):
        """Test loading registry with invalid epic code."""
        bad_data = {
            "epics": {
                "INVALID": {"title": "Test", "status": "active"}
            },
            "items": {},
            "next_epic_id": 1,
            "next_item_id": 1
        }
        with open(temp_registry_path, 'w') as f:
            json.dump(bad_data, f)

        registry = Registry(temp_registry_path)
        with pytest.raises(ValueError, match="Invalid epic code format"):
            registry.load()

    def test_load_invalid_item_code(self, temp_registry_path):
        """Test loading registry with invalid work item code."""
        bad_data = {
            "epics": {},
            "items": {
                "INVALID": {
                    "title": "Test",
                    "epic": None,
                    "stage": "active",
                    "path": "active/test"
                }
            },
            "next_epic_id": 1,
            "next_item_id": 1
        }
        with open(temp_registry_path, 'w') as f:
            json.dump(bad_data, f)

        registry = Registry(temp_registry_path)
        with pytest.raises(ValueError, match="Invalid work item code format"):
            registry.load()

    def test_save_registry(self, temp_registry_path):
        """Test saving registry to file."""
        registry = Registry(temp_registry_path)

        # Add some data
        epic = Epic(code="EP-001", title="Test Epic", status="active")
        registry.add_epic(epic)

        item = WorkItem(
            code="WI-001",
            title="Test Item",
            epic="EP-001",
            stage="active",
            path="active/test-item"
        )
        registry.add_item(item)

        registry.next_epic_id = 2
        registry.next_item_id = 2

        # Save
        registry.save()

        # Verify file exists and is valid JSON
        assert temp_registry_path.exists()

        with open(temp_registry_path) as f:
            data = json.load(f)

        assert data["epics"]["EP-001"]["title"] == "Test Epic"
        assert data["items"]["WI-001"]["title"] == "Test Item"
        assert data["next_epic_id"] == 2
        assert data["next_item_id"] == 2

    def test_save_is_atomic(self, temp_registry_path):
        """Test that save uses atomic write pattern."""
        registry = Registry(temp_registry_path)
        registry.add_epic(Epic(code="EP-001", title="Test", status="active"))
        registry.save()

        # Verify no temp files left behind
        temp_files = list(temp_registry_path.parent.glob('.tmp_*'))
        assert len(temp_files) == 0

    def test_generate_next_epic_code(self, temp_registry_path):
        """Test epic code generation."""
        registry = Registry(temp_registry_path)
        registry.next_epic_id = 1

        code1 = registry.generate_next_epic_code()
        assert code1 == "EP-001"
        assert registry.next_epic_id == 2

        code2 = registry.generate_next_epic_code()
        assert code2 == "EP-002"
        assert registry.next_epic_id == 3

    def test_generate_next_item_code(self, temp_registry_path):
        """Test work item code generation."""
        registry = Registry(temp_registry_path)
        registry.next_item_id = 1

        code1 = registry.generate_next_item_code()
        assert code1 == "WI-001"
        assert registry.next_item_id == 2

        code2 = registry.generate_next_item_code()
        assert code2 == "WI-002"
        assert registry.next_item_id == 3

    def test_generate_code_with_large_numbers(self, temp_registry_path):
        """Test code generation with large IDs."""
        registry = Registry(temp_registry_path)
        registry.next_epic_id = 42
        registry.next_item_id = 123

        epic_code = registry.generate_next_epic_code()
        assert epic_code == "EP-042"

        item_code = registry.generate_next_item_code()
        assert item_code == "WI-123"

    def test_add_and_get_epic(self, temp_registry_path):
        """Test adding and retrieving epics."""
        registry = Registry(temp_registry_path)

        epic = Epic(code="EP-005", title="New Epic", status="active")
        registry.add_epic(epic)

        retrieved = registry.get_epic("EP-005")
        assert retrieved is not None
        assert retrieved.code == "EP-005"
        assert retrieved.title == "New Epic"

        # Non-existent epic
        assert registry.get_epic("EP-999") is None

    def test_add_and_get_item(self, temp_registry_path):
        """Test adding and retrieving work items."""
        registry = Registry(temp_registry_path)

        item = WorkItem(
            code="WI-010",
            title="New Item",
            epic=None,
            stage="backlog",
            path=None
        )
        registry.add_item(item)

        retrieved = registry.get_item("WI-010")
        assert retrieved is not None
        assert retrieved.code == "WI-010"
        assert retrieved.title == "New Item"

        # Non-existent item
        assert registry.get_item("WI-999") is None

    def test_remove_epic(self, temp_registry_path):
        """Test removing an epic."""
        registry = Registry(temp_registry_path)

        epic = Epic(code="EP-007", title="To Remove", status="active")
        registry.add_epic(epic)
        assert registry.get_epic("EP-007") is not None

        registry.remove_epic("EP-007")
        assert registry.get_epic("EP-007") is None

        # Removing non-existent epic is safe
        registry.remove_epic("EP-999")  # Should not raise

    def test_remove_item(self, temp_registry_path):
        """Test removing a work item."""
        registry = Registry(temp_registry_path)

        item = WorkItem(
            code="WI-020",
            title="To Remove",
            epic=None,
            stage="backlog",
            path=None
        )
        registry.add_item(item)
        assert registry.get_item("WI-020") is not None

        registry.remove_item("WI-020")
        assert registry.get_item("WI-020") is None

        # Removing non-existent item is safe
        registry.remove_item("WI-999")  # Should not raise

    def test_update_epic(self, temp_registry_path):
        """Test updating an existing epic."""
        registry = Registry(temp_registry_path)

        # Add initial epic
        epic = Epic(code="EP-008", title="Original", status="active")
        registry.add_epic(epic)

        # Update epic
        updated = Epic(code="EP-008", title="Updated", status="completed")
        registry.add_epic(updated)

        retrieved = registry.get_epic("EP-008")
        assert retrieved is not None
        assert retrieved.title == "Updated"
        assert retrieved.status == "completed"

    def test_update_item(self, temp_registry_path):
        """Test updating an existing work item."""
        registry = Registry(temp_registry_path)

        # Add initial item
        item = WorkItem(
            code="WI-025",
            title="Original",
            epic=None,
            stage="backlog",
            path=None
        )
        registry.add_item(item)

        # Update item (move to active)
        updated = WorkItem(
            code="WI-025",
            title="Original",
            epic="EP-001",
            stage="active",
            path="active/original"
        )
        registry.add_item(updated)

        retrieved = registry.get_item("WI-025")
        assert retrieved is not None
        assert retrieved.stage == "active"
        assert retrieved.path == "active/original"
        assert retrieved.epic == "EP-001"

    def test_round_trip_save_load(self, temp_registry_path, sample_registry_data):
        """Test saving and loading preserves all data."""
        # Create registry with sample data
        with open(temp_registry_path, 'w') as f:
            json.dump(sample_registry_data, f)

        # Load
        registry1 = Registry(temp_registry_path)
        registry1.load()

        # Save
        registry1.save()

        # Load again
        registry2 = Registry(temp_registry_path)
        registry2.load()

        # Verify data matches
        assert len(registry2.epics) == len(registry1.epics)
        assert len(registry2.items) == len(registry1.items)
        assert registry2.next_epic_id == registry1.next_epic_id
        assert registry2.next_item_id == registry1.next_item_id

        # Spot check specific items
        ep1 = registry2.get_epic("EP-001")
        assert ep1 is not None
        assert ep1.title == "Authentication"

        wi2 = registry2.get_item("WI-002")
        assert wi2 is not None
        assert wi2.stage == "backlog"
        assert wi2.path is None
