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
from ..utils.logging import init_logger
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
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable debug logging'
    )

    args = parser.parse_args()

    # Initialize logger
    logger = init_logger(verbose=args.verbose, use_colors=True)

    # Validate epic code format if provided
    if args.epic and not EPIC_CODE_PATTERN.match(args.epic):
        logger.error(
            f"Invalid epic code format: {args.epic}",
            suggestion="Epic codes must match pattern EP-NNN (e.g., EP-001)"
        )
        return 1

    # Load registry
    logger.debug("Loading registry", path=".project/registry.json")
    registry = Registry()
    try:
        registry.load()
        logger.debug("Registry loaded successfully",
                    epics=len(registry.epics),
                    items=len(registry.items))
    except FileNotFoundError:
        logger.error(
            "Registry file not found",
            suggestion="Run 'uv run reconcile-registry' to create registry.json"
        )
        return 2
    except (json.JSONDecodeError, ValueError) as e:
        logger.exception("Failed to load registry (corrupted or invalid format)", e)
        logger.info("Consider running 'uv run reconcile-registry' to rebuild")
        return 2
    except Exception as e:
        logger.exception("Unexpected error loading registry", e)
        return 2

    # Validate epic exists if specified
    if args.epic and not registry.get_epic(args.epic):
        available_epics = list(registry.epics.keys())
        suggestion = (
            f"Available epics: {', '.join(available_epics)}"
            if available_epics
            else "No epics exist yet. Create an epic first or omit --epic flag."
        )
        logger.error(f"Epic {args.epic} not found in registry", suggestion=suggestion)
        return 1

    # Generate code and path
    code = registry.generate_next_item_code()
    logger.debug("Generated code", code=code)

    path: str | None = None
    if args.stage == 'active':
        slug = slugify(args.title)
        path = f"active/{slug}"
        logger.debug("Generated path", path=path)

    # Create work item
    try:
        item = WorkItem(
            code=code,
            title=args.title,
            epic=args.epic,
            stage=args.stage,
            path=path,
        )
        logger.debug("Created work item", code=code, stage=args.stage)
    except ValueError as e:
        logger.error(f"Invalid work item data: {e}")
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
            logger.debug("Creating directory", path=str(item_dir))
            item_dir.mkdir(parents=True, exist_ok=True)

            # Create spec.md skeleton
            logger.debug("Creating spec.md skeleton", path=str(spec_path))
            create_spec_skeleton(code, args.title, args.epic, spec_path)

        except PermissionError:
            logger.error(
                f"Permission denied creating {item_dir}",
                suggestion="Check directory permissions"
            )
            return 2
        except OSError as e:
            logger.exception(f"Failed to create folder/spec at {item_dir}", e)
            return 2
        except Exception as e:
            logger.exception("Unexpected error creating folder/spec", e)
            return 2

    # Save registry
    try:
        logger.debug("Saving registry")
        registry.save()
        logger.debug("Registry saved successfully")
    except PermissionError:
        logger.error(
            "Permission denied writing to registry.json",
            suggestion="Check file permissions for .project/registry.json"
        )
        return 2
    except OSError as e:
        logger.exception("Failed to save registry", e)
        return 2
    except Exception as e:
        logger.exception("Unexpected error saving registry", e)
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
