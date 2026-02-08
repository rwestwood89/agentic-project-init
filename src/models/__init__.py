"""Data models for the dashboard system.

This package contains:
- WorkItem and Epic models for representing project work
- Registry model for managing the source of truth (registry.json)
"""

from .registry import Epic, Registry, WorkItem

__all__ = ["Registry", "WorkItem", "Epic"]
