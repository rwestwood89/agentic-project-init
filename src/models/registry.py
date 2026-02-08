"""Registry data model for project work items and epics.

The registry is the single source of truth for structural project data,
stored at .project/registry.json. It tracks all work items, epics, and
code assignments.
"""

import json
from pathlib import Path
from typing import Any

from ..utils.atomic_write import atomic_write_json
from .work_item import EPIC_CODE_PATTERN, WORK_ITEM_CODE_PATTERN, Epic, WorkItem

__all__ = ["Registry", "Epic", "WorkItem"]


class Registry:
    """Manages the registry.json file with atomic read/write operations.

    The registry contains:
    - epics: Map of epic codes to epic metadata
    - items: Map of work item codes to work item metadata
    - next_epic_id: Next epic code to assign (integer)
    - next_item_id: Next work item code to assign (integer)
    """

    def __init__(self, registry_path: str | Path = ".project/registry.json"):
        """Initialize registry manager.

        Args:
            registry_path: Path to registry.json file
        """
        self.registry_path = Path(registry_path)
        self.epics: dict[str, Epic] = {}
        self.items: dict[str, WorkItem] = {}
        self.next_epic_id: int = 1
        self.next_item_id: int = 1

    def load(self) -> None:
        """Load registry from file.

        If file doesn't exist, initializes with empty registry.

        Raises:
            ValueError: If registry schema is invalid
            json.JSONDecodeError: If file contains invalid JSON
        """
        if not self.registry_path.exists():
            # Initialize with empty registry
            self.epics = {}
            self.items = {}
            self.next_epic_id = 1
            self.next_item_id = 1
            return

        with open(self.registry_path, encoding='utf-8') as f:
            data = json.load(f)

        # Validate schema
        self._validate_schema(data)

        # Parse epics
        self.epics = {
            code: Epic.from_dict(code, epic_data)
            for code, epic_data in data.get("epics", {}).items()
        }

        # Parse items
        self.items = {
            code: WorkItem.from_dict(code, item_data)
            for code, item_data in data.get("items", {}).items()
        }

        # Load counters
        self.next_epic_id = data.get("next_epic_id", 1)
        self.next_item_id = data.get("next_item_id", 1)

    def save(self) -> None:
        """Save registry to file atomically.

        Uses atomic write pattern to prevent corruption.
        """
        data = {
            "epics": {
                code: epic.to_dict()
                for code, epic in self.epics.items()
            },
            "items": {
                code: item.to_dict()
                for code, item in self.items.items()
            },
            "next_epic_id": self.next_epic_id,
            "next_item_id": self.next_item_id,
        }

        atomic_write_json(data, self.registry_path)

    def _validate_schema(self, data: dict[str, Any]) -> None:
        """Validate registry JSON schema.

        Args:
            data: Parsed JSON data

        Raises:
            ValueError: If schema is invalid
        """
        # Check top-level keys
        required_keys = {"epics", "items", "next_epic_id", "next_item_id"}
        missing_keys = required_keys - set(data.keys())
        if missing_keys:
            raise ValueError(f"Missing required keys in registry: {missing_keys}")

        # Validate types
        if not isinstance(data["epics"], dict):
            raise ValueError("'epics' must be a dictionary")
        if not isinstance(data["items"], dict):
            raise ValueError("'items' must be a dictionary")
        if not isinstance(data["next_epic_id"], int):
            raise ValueError("'next_epic_id' must be an integer")
        if not isinstance(data["next_item_id"], int):
            raise ValueError("'next_item_id' must be an integer")

        # Validate epic codes
        for code in data["epics"].keys():
            if not EPIC_CODE_PATTERN.match(code):
                raise ValueError(f"Invalid epic code format: {code}")

        # Validate work item codes
        for code in data["items"].keys():
            if not WORK_ITEM_CODE_PATTERN.match(code):
                raise ValueError(f"Invalid work item code format: {code}")

    def generate_next_epic_code(self) -> str:
        """Generate next available epic code.

        Returns:
            Epic code in format EP-NNN (e.g., EP-001, EP-015)
        """
        code = f"EP-{self.next_epic_id:03d}"
        self.next_epic_id += 1
        return code

    def generate_next_item_code(self) -> str:
        """Generate next available work item code.

        Returns:
            Work item code in format WI-NNN (e.g., WI-001, WI-042)
        """
        code = f"WI-{self.next_item_id:03d}"
        self.next_item_id += 1
        return code

    def get_epic(self, code: str) -> Epic | None:
        """Get epic by code.

        Args:
            code: Epic code (e.g., EP-001)

        Returns:
            Epic instance or None if not found
        """
        return self.epics.get(code)

    def get_item(self, code: str) -> WorkItem | None:
        """Get work item by code.

        Args:
            code: Work item code (e.g., WI-001)

        Returns:
            WorkItem instance or None if not found
        """
        return self.items.get(code)

    def add_epic(self, epic: Epic) -> None:
        """Add or update an epic in the registry.

        Args:
            epic: Epic instance to add
        """
        self.epics[epic.code] = epic

    def add_item(self, item: WorkItem) -> None:
        """Add or update a work item in the registry.

        Args:
            item: WorkItem instance to add
        """
        self.items[item.code] = item

    def remove_epic(self, code: str) -> None:
        """Remove an epic from the registry.

        Args:
            code: Epic code to remove
        """
        if code in self.epics:
            del self.epics[code]

    def remove_item(self, code: str) -> None:
        """Remove a work item from the registry.

        Args:
            code: Work item code to remove
        """
        if code in self.items:
            del self.items[code]
