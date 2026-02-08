#!/usr/bin/env python3
"""Move work item between stages (backlog→active→completed).

This script handles transitions between stages, including:
- Creating folder/spec when moving backlog→active
- Renaming folder with date prefix when moving active→completed
- Updating CHANGELOG.md in completed items
- Checking if epic should be marked complete
"""

import argparse
import json
import shutil
import sys
from datetime import UTC, datetime
from pathlib import Path

from ..models.registry import Registry
from ..utils.slug import slugify


def create_spec_skeleton(
    code: str,
    title: str,
    epic: str | None,
    spec_path: Path
) -> None:
    """Create spec.md skeleton with frontmatter.

    Args:
        code: Work item code (e.g., WI-001)
        title: Work item title
        epic: Optional epic code
        spec_path: Path to spec.md file
    """
    now = datetime.now(UTC).isoformat(timespec='seconds')

    frontmatter = f"""---
id: {code}
title: {title}
type: spec
status: draft
epic: {epic if epic else "null"}
owner: ""
created: {now}
updated: {now}
---

# {title}

## Purpose

[Describe the purpose of this work item]

## Requirements

[List key requirements]

## Acceptance Criteria

[Define success criteria using Given/When/Then format]

## Constraints

[Note any constraints or limitations]

## Out of Scope

[Explicitly state what is not included]
"""

    spec_path.write_text(frontmatter, encoding='utf-8')


def update_changelog(folder_path: Path, code: str, title: str) -> None:
    """Update or create CHANGELOG.md with completion entry.

    Args:
        folder_path: Path to the work item folder
        code: Work item code
        title: Work item title
    """
    changelog_path = folder_path / 'CHANGELOG.md'
    completion_date = datetime.now(UTC).strftime('%Y-%m-%d')

    entry = f"""# {code}: {title}

**Completed**: {completion_date}

## Summary

[Summary of work completed]

## Changes

[List of key changes made]

## Testing

[Testing performed]

## Notes

[Any additional notes]
"""

    if changelog_path.exists():
        # Prepend new entry to existing changelog
        existing = changelog_path.read_text(encoding='utf-8')
        content = f"{entry}\n---\n\n{existing}"
    else:
        content = entry

    changelog_path.write_text(content, encoding='utf-8')


def check_epic_completion(registry: Registry, epic_code: str) -> bool:
    """Check if all items in an epic are completed.

    Args:
        registry: Registry instance
        epic_code: Epic code to check

    Returns:
        True if all items are completed, False otherwise
    """
    epic_items = [
        item for item in registry.items.values()
        if item.epic == epic_code
    ]

    if not epic_items:
        return False

    return all(item.stage == 'completed' for item in epic_items)


def main() -> int:
    """Move a work item between stages.

    Returns:
        Exit code: 0 for success, 1 for input error, 2 for state error
    """
    parser = argparse.ArgumentParser(
        description='Move a work item between stages'
    )
    parser.add_argument(
        'code',
        help='Work item code (e.g., WI-001)'
    )
    parser.add_argument(
        '--to',
        required=True,
        choices=['backlog', 'active', 'completed'],
        help='Target stage'
    )

    args = parser.parse_args()
    code = args.code.upper()
    target_stage = args.to

    # Load registry
    try:
        registry = Registry()
        registry.load()
    except Exception as e:
        print(f"Error: Failed to load registry: {e}", file=sys.stderr)
        return 2

    # Find item
    item = registry.get_item(code)
    if not item:
        print(f"Error: Work item {code} not found in registry", file=sys.stderr)
        return 1

    current_stage = item.stage
    old_path = item.path

    # Validate transition
    if current_stage == target_stage:
        print(
            f"Error: Item {code} is already in {target_stage} stage",
            file=sys.stderr
        )
        return 2

    # Define valid transitions
    valid_transitions = {
        'backlog': ['active'],
        'active': ['backlog', 'completed'],
        'completed': []  # Cannot move from completed
    }

    if target_stage not in valid_transitions.get(current_stage, []):
        print(
            f"Error: Invalid transition from {current_stage} to {target_stage}",
            file=sys.stderr
        )
        return 2

    project_root = Path('.project')
    new_path = None

    try:
        # Handle backlog → active transition
        if current_stage == 'backlog' and target_stage == 'active':
            slug = slugify(item.title)
            folder_path = project_root / 'active' / slug
            folder_path.mkdir(parents=True, exist_ok=True)

            # Create spec.md skeleton
            spec_path = folder_path / 'spec.md'
            create_spec_skeleton(code, item.title, item.epic, spec_path)

            new_path = f"active/{slug}"

        # Handle active → completed transition
        elif current_stage == 'active' and target_stage == 'completed':
            if not old_path:
                print(
                    f"Error: Item {code} has no path in registry",
                    file=sys.stderr
                )
                return 2

            old_folder = project_root / old_path
            if not old_folder.exists():
                print(
                    f"Error: Folder {old_folder} does not exist",
                    file=sys.stderr
                )
                return 2

            # Generate new path with date prefix
            completion_date = datetime.now(UTC).strftime('%Y-%m-%d')
            slug = slugify(item.title)
            new_folder_name = f"{completion_date}_{slug}"
            new_folder = project_root / 'completed' / new_folder_name

            # Move folder
            new_folder.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(old_folder), str(new_folder))

            # Update CHANGELOG.md
            update_changelog(new_folder, code, item.title)

            new_path = f"completed/{new_folder_name}"

        # Handle active → backlog transition
        elif current_stage == 'active' and target_stage == 'backlog':
            if old_path:
                old_folder = project_root / old_path
                if old_folder.exists():
                    # Remove folder (confirmation already handled by caller)
                    shutil.rmtree(old_folder)

            new_path = None  # Backlog items have no path

        # Update item in registry
        item.stage = target_stage
        item.path = new_path

        # Check epic completion if moving to completed
        epic_updated = False
        if target_stage == 'completed' and item.epic:
            epic = registry.get_epic(item.epic)
            if epic and check_epic_completion(registry, item.epic):
                epic.status = 'completed'
                epic_updated = True

        # Save registry
        registry.save()

        # Output result
        result = {
            'code': code,
            'old_stage': current_stage,
            'new_stage': target_stage,
            'path': new_path,
        }
        if epic_updated:
            result['epic_completed'] = item.epic

        print(json.dumps(result))
        return 0

    except Exception as e:
        print(f"Error: Failed to move item: {e}", file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
