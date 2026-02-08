"""Tests for reconcile_registry script."""

import json
from pathlib import Path

import pytest

from src.scripts.reconcile_registry import (
    determine_stage,
    extract_code_from_frontmatter,
    find_artifacts,
    reconcile,
)


class TestFindArtifacts:
    """Tests for find_artifacts function."""

    def test_finds_spec_files(self, tmp_path: Path) -> None:
        """Should find all spec.md files."""
        (tmp_path / "active" / "item1").mkdir(parents=True)
        (tmp_path / "active" / "item1" / "spec.md").write_text("content")
        (tmp_path / "backlog" / "item2").mkdir(parents=True)
        (tmp_path / "backlog" / "item2" / "spec.md").write_text("content")

        artifacts = find_artifacts(tmp_path)
        assert len(artifacts) == 2
        assert all(p.name == "spec.md" for p in artifacts)

    def test_finds_all_artifact_types(self, tmp_path: Path) -> None:
        """Should find spec.md, design.md, and plan.md."""
        item_dir = tmp_path / "active" / "item1"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text("spec")
        (item_dir / "design.md").write_text("design")
        (item_dir / "plan.md").write_text("plan")

        artifacts = find_artifacts(tmp_path)
        assert len(artifacts) == 3
        names = {p.name for p in artifacts}
        assert names == {"spec.md", "design.md", "plan.md"}

    def test_empty_directory(self, tmp_path: Path) -> None:
        """Should return empty list for empty directory."""
        artifacts = find_artifacts(tmp_path)
        assert artifacts == []


class TestExtractCodeFromFrontmatter:
    """Tests for extract_code_from_frontmatter function."""

    def test_extracts_work_item_code(self) -> None:
        """Should extract valid work item code."""
        frontmatter = {"id": "WI-001", "title": "Test"}
        code = extract_code_from_frontmatter(frontmatter)
        assert code == "WI-001"

    def test_extracts_epic_code(self) -> None:
        """Should extract valid epic code."""
        frontmatter = {"id": "EP-005", "title": "Epic"}
        code = extract_code_from_frontmatter(frontmatter)
        assert code == "EP-005"

    def test_missing_id_field(self) -> None:
        """Should return None if id field missing."""
        frontmatter = {"title": "Test"}
        code = extract_code_from_frontmatter(frontmatter)
        assert code is None

    def test_invalid_code_format(self) -> None:
        """Should return None for invalid code format."""
        frontmatter = {"id": "INVALID-123", "title": "Test"}
        code = extract_code_from_frontmatter(frontmatter)
        assert code is None


class TestDetermineStage:
    """Tests for determine_stage function."""

    def test_active_stage(self, tmp_path: Path) -> None:
        """Should detect active stage from path."""
        artifact = tmp_path / "active" / "item1" / "spec.md"
        stage = determine_stage(artifact, tmp_path)
        assert stage == "active"

    def test_backlog_stage(self, tmp_path: Path) -> None:
        """Should detect backlog stage from path."""
        artifact = tmp_path / "backlog" / "item2" / "spec.md"
        stage = determine_stage(artifact, tmp_path)
        assert stage == "backlog"

    def test_completed_stage(self, tmp_path: Path) -> None:
        """Should detect completed stage from path."""
        artifact = tmp_path / "completed" / "2026-01-15_item3" / "spec.md"
        stage = determine_stage(artifact, tmp_path)
        assert stage == "completed"

    def test_unknown_directory_defaults_to_backlog(self, tmp_path: Path) -> None:
        """Should default to backlog for unknown directories."""
        artifact = tmp_path / "unknown" / "item" / "spec.md"
        stage = determine_stage(artifact, tmp_path)
        assert stage == "backlog"


class TestReconcile:
    """Integration tests for reconcile function."""

    def test_rebuilds_empty_registry_from_artifacts(self, tmp_path: Path) -> None:
        """Should rebuild registry from artifacts when no registry exists."""
        # Create artifacts with frontmatter
        item1_dir = tmp_path / "active" / "item1"
        item1_dir.mkdir(parents=True)
        (item1_dir / "spec.md").write_text(
            "---\n"
            "id: WI-001\n"
            "title: First Item\n"
            "epic: null\n"
            "---\n"
            "Body content"
        )

        item2_dir = tmp_path / "backlog" / "item2"
        item2_dir.mkdir(parents=True)
        (item2_dir / "spec.md").write_text(
            "---\n"
            "id: WI-005\n"
            "title: Second Item\n"
            "epic: EP-001\n"
            "---\n"
            "Body content"
        )

        summary = reconcile(project_root=tmp_path)

        # Check summary
        assert len(summary["preserved"]) == 2
        assert "WI-001" in summary["preserved"]
        assert "WI-005" in summary["preserved"]
        assert len(summary["assigned"]) == 0
        assert len(summary["conflicts"]) == 0
        assert summary["next_item_id"] == 6  # max(1, 5) + 1

        # Check registry file was created
        registry_path = tmp_path / "registry.json"
        assert registry_path.exists()

        with open(registry_path, encoding="utf-8") as f:
            data = json.load(f)

        assert "WI-001" in data["items"]
        assert data["items"]["WI-001"]["title"] == "First Item"
        assert data["items"]["WI-001"]["stage"] == "active"
        assert data["items"]["WI-001"]["path"] == "active/item1"

        assert "WI-005" in data["items"]
        assert data["items"]["WI-005"]["stage"] == "backlog"
        assert data["items"]["WI-005"]["path"] is None

    def test_preserves_codes_from_frontmatter(self, tmp_path: Path) -> None:
        """Should preserve existing codes found in frontmatter."""
        item_dir = tmp_path / "active" / "test-item"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text(
            "---\n"
            "id: WI-042\n"
            "title: Test Item\n"
            "---\n"
            "Content"
        )

        summary = reconcile(project_root=tmp_path)

        assert "WI-042" in summary["preserved"]
        assert summary["next_item_id"] == 43  # 42 + 1

    def test_detects_duplicate_codes(self, tmp_path: Path) -> None:
        """Should detect and log duplicate codes."""
        # Create two artifacts with same code
        item1_dir = tmp_path / "active" / "item1"
        item1_dir.mkdir(parents=True)
        (item1_dir / "spec.md").write_text(
            "---\n"
            "id: WI-007\n"
            "title: First\n"
            "---\n"
            "Content"
        )

        item2_dir = tmp_path / "active" / "item2"
        item2_dir.mkdir(parents=True)
        (item2_dir / "spec.md").write_text(
            "---\n"
            "id: WI-007\n"
            "title: Second\n"
            "---\n"
            "Content"
        )

        summary = reconcile(project_root=tmp_path)

        # First keeps code, second is in conflicts
        assert "WI-007" in summary["preserved"]
        assert len(summary["conflicts"]) == 1
        assert summary["conflicts"][0]["code"] == "WI-007"

        # Only one item should be in registry
        registry_path = tmp_path / "registry.json"
        with open(registry_path, encoding="utf-8") as f:
            data = json.load(f)
        assert len(data["items"]) == 1

    def test_ignores_artifacts_without_frontmatter(self, tmp_path: Path) -> None:
        """Should ignore artifacts without YAML frontmatter."""
        item_dir = tmp_path / "active" / "item1"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text("Just plain markdown, no frontmatter")

        summary = reconcile(project_root=tmp_path)

        assert len(summary["preserved"]) == 0
        assert len(summary["assigned"]) == 0

    def test_removes_orphaned_registry_entries(self, tmp_path: Path) -> None:
        """Should remove registry entries for missing files."""
        # Create initial registry with one item
        registry_path = tmp_path / "registry.json"
        registry_data = {
            "epics": {},
            "items": {
                "WI-001": {
                    "title": "Deleted Item",
                    "epic": None,
                    "stage": "active",
                    "path": "active/deleted-item"
                }
            },
            "next_epic_id": 1,
            "next_item_id": 2
        }
        registry_path.write_text(json.dumps(registry_data))

        # Don't create the actual artifact file
        # (so WI-001 is orphaned)

        summary = reconcile(project_root=tmp_path)

        assert "WI-001" in summary["removed"]
        assert len(summary["preserved"]) == 0

    def test_sets_next_ids_correctly(self, tmp_path: Path) -> None:
        """Should set next_epic_id and next_item_id to max + 1."""
        # Create artifacts with various IDs
        item1_dir = tmp_path / "active" / "item1"
        item1_dir.mkdir(parents=True)
        (item1_dir / "spec.md").write_text(
            "---\nid: WI-005\ntitle: Item\n---\nContent"
        )

        epic1_dir = tmp_path / "active" / "epic1"
        epic1_dir.mkdir(parents=True)
        (epic1_dir / "spec.md").write_text(
            "---\nid: EP-003\ntitle: Epic\n---\nContent"
        )

        summary = reconcile(project_root=tmp_path)

        assert summary["next_item_id"] == 6  # 5 + 1
        assert summary["next_epic_id"] == 4  # 3 + 1

    def test_dry_run_does_not_write_file(self, tmp_path: Path) -> None:
        """Should not write registry in dry-run mode."""
        item_dir = tmp_path / "active" / "item1"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text(
            "---\nid: WI-001\ntitle: Test\n---\nContent"
        )

        summary = reconcile(project_root=tmp_path, dry_run=True)

        # Summary should be generated
        assert "WI-001" in summary["preserved"]

        # But registry file should not exist
        registry_path = tmp_path / "registry.json"
        assert not registry_path.exists()

    def test_idempotent_operation(self, tmp_path: Path) -> None:
        """Should produce same result when run twice."""
        item_dir = tmp_path / "active" / "item1"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text(
            "---\nid: WI-001\ntitle: Test\n---\nContent"
        )

        # Run reconciliation twice
        summary1 = reconcile(project_root=tmp_path)
        summary2 = reconcile(project_root=tmp_path)

        # Both runs should produce identical results
        assert summary1["preserved"] == summary2["preserved"]
        assert summary1["next_item_id"] == summary2["next_item_id"]
        assert len(summary2["conflicts"]) == 0
        assert len(summary2["removed"]) == 0

    def test_handles_epics_and_items(self, tmp_path: Path) -> None:
        """Should correctly process both epics and work items."""
        epic_dir = tmp_path / "active" / "my-epic"
        epic_dir.mkdir(parents=True)
        (epic_dir / "spec.md").write_text(
            "---\n"
            "id: EP-001\n"
            "title: My Epic\n"
            "status: active\n"
            "---\n"
            "Epic content"
        )

        item_dir = tmp_path / "active" / "my-item"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text(
            "---\n"
            "id: WI-001\n"
            "title: My Item\n"
            "epic: EP-001\n"
            "---\n"
            "Item content"
        )

        summary = reconcile(project_root=tmp_path)

        assert "EP-001" in summary["preserved"]
        assert "WI-001" in summary["preserved"]

        registry_path = tmp_path / "registry.json"
        with open(registry_path, encoding="utf-8") as f:
            data = json.load(f)

        assert "EP-001" in data["epics"]
        assert data["epics"]["EP-001"]["title"] == "My Epic"
        assert data["epics"]["EP-001"]["status"] == "active"

        assert "WI-001" in data["items"]
        assert data["items"]["WI-001"]["epic"] == "EP-001"

    def test_error_on_missing_project_root(self) -> None:
        """Should raise error if project root doesn't exist."""
        with pytest.raises(FileNotFoundError):
            reconcile(project_root=Path("/nonexistent/path"))

    def test_handles_malformed_yaml_gracefully(self, tmp_path: Path) -> None:
        """Should skip artifacts with malformed YAML."""
        item_dir = tmp_path / "active" / "item1"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text(
            "---\n"
            "invalid: yaml: content:\n"
            "  - unclosed\n"
            "---\n"
            "Content"
        )

        # Should not raise error, just skip the malformed artifact
        summary = reconcile(project_root=tmp_path)
        assert len(summary["preserved"]) == 0

    def test_handles_multiple_artifact_types_per_item(self, tmp_path: Path) -> None:
        """Should handle items with multiple artifacts (spec, design, plan)."""
        item_dir = tmp_path / "active" / "item1"
        item_dir.mkdir(parents=True)

        # All three artifacts with same ID
        for artifact_type in ["spec.md", "design.md", "plan.md"]:
            (item_dir / artifact_type).write_text(
                "---\n"
                "id: WI-001\n"
                "title: Multi-artifact Item\n"
                "---\n"
                "Content"
            )

        summary = reconcile(project_root=tmp_path)

        # Should detect conflicts for duplicate IDs
        assert "WI-001" in summary["preserved"]
        assert len(summary["conflicts"]) == 2  # design.md and plan.md conflict

    def test_handles_completed_items_with_date_prefix(self, tmp_path: Path) -> None:
        """Should correctly process completed items with date prefixes."""
        item_dir = tmp_path / "completed" / "2026-01-15_my-item"
        item_dir.mkdir(parents=True)
        (item_dir / "spec.md").write_text(
            "---\n"
            "id: WI-001\n"
            "title: Completed Item\n"
            "---\n"
            "Content"
        )

        reconcile(project_root=tmp_path)

        registry_path = tmp_path / "registry.json"
        with open(registry_path, encoding="utf-8") as f:
            data = json.load(f)

        assert data["items"]["WI-001"]["stage"] == "completed"
        assert data["items"]["WI-001"]["path"] == "completed/2026-01-15_my-item"
