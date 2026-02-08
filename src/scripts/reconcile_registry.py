"""Reconcile registry.json from filesystem artifacts.

This script rebuilds the registry by scanning .project/ for all artifacts
with YAML frontmatter. It preserves existing codes, assigns new codes to
artifacts missing IDs, and removes orphaned registry entries.

Usage:
    reconcile-registry [--dry-run]

Exit codes:
    0: Success
    1: Input/validation error
    2: File system error
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any, cast

from ..models.frontmatter import parse_frontmatter
from ..models.registry import Registry
from ..models.work_item import (
    EPIC_CODE_PATTERN,
    WORK_ITEM_CODE_PATTERN,
    Epic,
    EpicStatus,
    Stage,
    WorkItem,
)
from ..utils.logging import init_logger


def find_artifacts(project_root: Path) -> list[Path]:
    """Find all artifact files in .project/ tree.

    Args:
        project_root: Path to .project/ directory

    Returns:
        List of paths to spec.md, design.md, and plan.md files
    """
    artifact_files: list[Path] = []
    for pattern in ["**/spec.md", "**/design.md", "**/plan.md"]:
        artifact_files.extend(project_root.glob(pattern))
    return sorted(artifact_files)


def extract_code_from_frontmatter(frontmatter: dict[str, Any]) -> str | None:
    """Extract work item or epic code from frontmatter.

    Args:
        frontmatter: Parsed YAML frontmatter

    Returns:
        Code string (EP-NNN or WI-NNN) or None if missing/invalid
    """
    code = frontmatter.get("id")
    if not isinstance(code, str):
        return None

    # Validate format
    if EPIC_CODE_PATTERN.match(code) or WORK_ITEM_CODE_PATTERN.match(code):
        return code

    return None


def determine_stage(artifact_path: Path, project_root: Path) -> str:
    """Determine stage based on artifact location.

    Args:
        artifact_path: Path to artifact file
        project_root: Path to .project/ directory

    Returns:
        Stage: 'backlog', 'active', or 'completed'
    """
    relative_path = artifact_path.relative_to(project_root)
    parts = relative_path.parts

    if len(parts) == 0:
        return "backlog"

    first_dir = parts[0]
    if first_dir == "backlog":
        return "backlog"
    elif first_dir == "active":
        return "active"
    elif first_dir == "completed":
        return "completed"
    else:
        return "backlog"  # Default to backlog if unclear


def reconcile(
    project_root: Path = Path(".project"),
    dry_run: bool = False
) -> dict[str, Any]:
    """Reconcile registry.json from filesystem artifacts.

    Args:
        project_root: Path to .project/ directory
        dry_run: If True, don't write changes to disk

    Returns:
        Summary dict with:
            - preserved: List of preserved codes
            - assigned: List of newly assigned codes
            - conflicts: List of duplicate code conflicts
            - removed: List of removed orphaned entries
            - next_epic_id: Updated next epic ID
            - next_item_id: Updated next item ID

    Raises:
        FileNotFoundError: If .project/ doesn't exist
    """
    if not project_root.exists():
        raise FileNotFoundError(f"Project root not found: {project_root}")

    # Find all artifacts
    artifacts = find_artifacts(project_root)

    # Track results
    preserved_codes: list[str] = []
    assigned_codes: list[str] = []
    conflicts: list[dict[str, str]] = []
    seen_codes: set[str] = set()

    # Track max IDs for next_epic_id and next_item_id
    max_epic_id = 0
    max_item_id = 0

    # New registry data
    new_epics: dict[str, Epic] = {}
    new_items: dict[str, WorkItem] = {}

    # Process each artifact
    for artifact_path in artifacts:
        # Read and parse frontmatter
        try:
            content = artifact_path.read_text(encoding="utf-8")
        except Exception as e:
            print(
                f"Warning: Failed to read {artifact_path}: {e}",
                file=sys.stderr
            )
            continue

        frontmatter, _ = parse_frontmatter(content)
        if frontmatter is None:
            # No frontmatter, skip this file
            continue

        # Extract code
        code = extract_code_from_frontmatter(frontmatter)
        if code is None:
            # No valid code, skip this artifact
            continue

        # Check for duplicate codes
        if code in seen_codes:
            conflicts.append({
                "code": code,
                "path": str(artifact_path.relative_to(project_root))
            })
            # First occurrence keeps the code, this one gets skipped
            continue

        seen_codes.add(code)
        preserved_codes.append(code)

        # Extract metadata
        title = frontmatter.get("title", "Untitled")
        epic_code = frontmatter.get("epic")

        # Determine stage and path
        raw_stage = determine_stage(artifact_path, project_root)
        stage = cast(Stage, raw_stage)

        # Calculate relative path (parent directory of artifact)
        relative_path = artifact_path.parent.relative_to(project_root)
        if stage == "backlog":
            path = None
        else:
            path = str(relative_path)

        # Determine if epic or work item
        if EPIC_CODE_PATTERN.match(code):
            # It's an epic
            epic_id = int(code.split("-")[1])
            max_epic_id = max(max_epic_id, epic_id)

            raw_status = frontmatter.get("status", "active")
            if raw_status not in ("active", "completed"):
                raw_status = "active"
            epic_status = cast(EpicStatus, raw_status)

            new_epics[code] = Epic(
                code=code,
                title=title,
                status=epic_status
            )
        elif WORK_ITEM_CODE_PATTERN.match(code):
            # It's a work item
            item_id = int(code.split("-")[1])
            max_item_id = max(max_item_id, item_id)

            new_items[code] = WorkItem(
                code=code,
                title=title,
                epic=epic_code,
                stage=stage,
                path=path
            )

    # Set next IDs to one higher than max found
    next_epic_id = max_epic_id + 1
    next_item_id = max_item_id + 1

    # Load existing registry to find removed entries
    registry_path = project_root / "registry.json"
    removed_codes: list[str] = []

    if registry_path.exists():
        try:
            old_registry = Registry(registry_path)
            old_registry.load()

            # Find removed epics
            for old_code in old_registry.epics.keys():
                if old_code not in new_epics:
                    removed_codes.append(old_code)

            # Find removed items
            for old_code in old_registry.items.keys():
                if old_code not in new_items:
                    removed_codes.append(old_code)
        except Exception as e:
            print(
                f"Warning: Failed to load existing registry: {e}",
                file=sys.stderr
            )

    # Write new registry (unless dry-run)
    if not dry_run:
        new_registry = Registry(registry_path)
        new_registry.epics = new_epics
        new_registry.items = new_items
        new_registry.next_epic_id = next_epic_id
        new_registry.next_item_id = next_item_id
        new_registry.save()

    # Return summary
    return {
        "preserved": preserved_codes,
        "assigned": assigned_codes,
        "conflicts": conflicts,
        "removed": removed_codes,
        "next_epic_id": next_epic_id,
        "next_item_id": next_item_id,
    }


def main() -> int:
    """Main CLI entry point.

    Returns:
        Exit code (0 for success, 1 for error)
    """
    parser = argparse.ArgumentParser(
        description="Reconcile registry.json from filesystem artifacts"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show changes without writing to disk"
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(".project"),
        help="Path to .project/ directory (default: .project)"
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable debug logging'
    )
    args = parser.parse_args()
    _logger = init_logger(verbose=args.verbose, use_colors=True)  # noqa: F841

    try:
        summary = reconcile(
            project_root=args.project_root,
            dry_run=args.dry_run
        )

        # Print summary to stderr for human readability
        print("Reconciliation Summary:", file=sys.stderr)
        print(f"  Preserved codes: {len(summary['preserved'])}", file=sys.stderr)
        print(f"  Newly assigned: {len(summary['assigned'])}", file=sys.stderr)
        print(f"  Conflicts: {len(summary['conflicts'])}", file=sys.stderr)
        print(f"  Removed entries: {len(summary['removed'])}", file=sys.stderr)
        print(f"  Next epic ID: {summary['next_epic_id']}", file=sys.stderr)
        print(f"  Next item ID: {summary['next_item_id']}", file=sys.stderr)

        if summary['conflicts']:
            print("\nConflicts (duplicate codes):", file=sys.stderr)
            for conflict in summary['conflicts']:
                print(
                    f"  {conflict['code']} at {conflict['path']}",
                    file=sys.stderr
                )

        if summary['removed']:
            print("\nRemoved entries (missing files):", file=sys.stderr)
            for code in summary['removed']:
                print(f"  {code}", file=sys.stderr)

        if args.dry_run:
            print("\nDry-run mode: No changes written", file=sys.stderr)

        # Print JSON summary to stdout
        print(json.dumps(summary, indent=2))

        return 0

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
