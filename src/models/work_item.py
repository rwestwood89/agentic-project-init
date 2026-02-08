"""Work item and epic data models."""

import re
from dataclasses import dataclass
from typing import Any, Literal

# Regex patterns for code validation
EPIC_CODE_PATTERN = re.compile(r"^EP-\d{3}$")
WORK_ITEM_CODE_PATTERN = re.compile(r"^WI-\d{3}$")

Stage = Literal["backlog", "active", "completed"]
EpicStatus = Literal["active", "completed"]


@dataclass
class Epic:
    """Represents an epic in the project.

    Epics are high-level work containers that group related work items.
    They have a permanent code (EP-NNN) assigned at creation.
    """
    code: str
    title: str
    status: EpicStatus

    def __post_init__(self) -> None:
        """Validate epic code format."""
        if not EPIC_CODE_PATTERN.match(self.code):
            raise ValueError(f"Invalid epic code format: {self.code}. Expected EP-NNN")
        if self.status not in ("active", "completed"):
            raise ValueError(f"Invalid epic status: {self.status}")

    def to_dict(self) -> dict[str, Any]:
        """Convert to registry JSON format."""
        return {
            "title": self.title,
            "status": self.status,
        }

    @classmethod
    def from_dict(cls, code: str, data: dict[str, Any]) -> "Epic":
        """Create Epic from registry JSON data."""
        return cls(
            code=code,
            title=data["title"],
            status=data["status"],
        )


@dataclass
class WorkItem:
    """Represents a work item in the project.

    Work items are individual units of work tracked through stages.
    They have a permanent code (WI-NNN) assigned at creation.
    """
    code: str
    title: str
    epic: str | None
    stage: Stage
    path: str | None

    def __post_init__(self) -> None:
        """Validate work item data."""
        if not WORK_ITEM_CODE_PATTERN.match(self.code):
            raise ValueError(
                f"Invalid work item code format: {self.code}. Expected WI-NNN"
            )
        if self.stage not in ("backlog", "active", "completed"):
            raise ValueError(f"Invalid stage: {self.stage}")
        if self.epic is not None and not EPIC_CODE_PATTERN.match(self.epic):
            raise ValueError(f"Invalid epic code reference: {self.epic}")
        if self.stage == "backlog" and self.path is not None:
            raise ValueError("Backlog items must have path=null")

    def to_dict(self) -> dict[str, Any]:
        """Convert to registry JSON format."""
        return {
            "title": self.title,
            "epic": self.epic,
            "stage": self.stage,
            "path": self.path,
        }

    @classmethod
    def from_dict(cls, code: str, data: dict[str, Any]) -> "WorkItem":
        """Create WorkItem from registry JSON data."""
        return cls(
            code=code,
            title=data["title"],
            epic=data["epic"],
            stage=data["stage"],
            path=data["path"],
        )
