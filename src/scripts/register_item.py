#!/usr/bin/env python3
"""Register new work item in the project registry.

This script creates a new work item entry in the registry, optionally
creates the folder structure and spec.md skeleton for active items.
"""

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

from ..models.registry import Registry
from ..models.work_item import EPIC_CODE_PATTERN, WorkItem
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


def main() -> int:
    """Register a new work item.

    Returns:
        Exit code: 0 for success, 1 for input error, 2 for state error
    """
    parser = argparse.ArgumentParser(
        description='Register a new work item in the project registry'
    )
    parser.add_argument(
        '--title',
        required=True,
        help='Work item title'
    )
    parser.add_argument(
        '--epic',
        help='Parent epic code (e.g., EP-001)'
    )
    parser.add_argument(
        '--stage',
        choices=['backlog', 'active'],
        default='backlog',
        help='Initial stage (default: backlog)'
    )

    args = parser.parse_args()

    # Validate epic code format if provided
    if args.epic and not EPIC_CODE_PATTERN.match(args.epic):
        print(
            f"Error: Invalid epic code format: {args.epic}. Expected EP-NNN",
            file=sys.stderr
        )
        return 1

    # Load registry
    registry = Registry()
    try:
        registry.load()
    except Exception as e:
        print(f"Error: Failed to load registry: {e}", file=sys.stderr)
        return 2

    # Validate epic exists if specified
    if args.epic and not registry.get_epic(args.epic):
        print(
            f"Error: Epic {args.epic} not found in registry",
            file=sys.stderr
        )
        return 1

    # Generate code and path
    code = registry.generate_next_item_code()
    path: str | None = None

    if args.stage == 'active':
        slug = slugify(args.title)
        path = f"active/{slug}"

    # Create work item
    try:
        item = WorkItem(
            code=code,
            title=args.title,
            epic=args.epic,
            stage=args.stage,
            path=path,
        )
    except ValueError as e:
        print(f"Error: Invalid work item data: {e}", file=sys.stderr)
        return 1

    # Add to registry
    registry.add_item(item)

    # Create folder and spec.md for active items
    if args.stage == 'active' and path:
        project_root = Path('.project')
        item_dir = project_root / path
        spec_path = item_dir / 'spec.md'

        try:
            # Create directory
            item_dir.mkdir(parents=True, exist_ok=True)

            # Create spec.md skeleton
            create_spec_skeleton(code, args.title, args.epic, spec_path)

        except Exception as e:
            print(
                f"Error: Failed to create folder/spec: {e}",
                file=sys.stderr
            )
            return 2

    # Save registry
    try:
        registry.save()
    except Exception as e:
        print(f"Error: Failed to save registry: {e}", file=sys.stderr)
        return 2

    # Output JSON result
    result = {
        "code": code,
        "path": path,
    }
    print(json.dumps(result))

    return 0


if __name__ == '__main__':
    sys.exit(main())
