#!/usr/bin/env python3
"""Update artifact frontmatter (status, phases, etc.).

This script updates YAML frontmatter fields in artifact files:
- spec.md, design.md, plan.md
- Updates status, phases_complete, and other metadata
- Automatically updates the 'updated' timestamp
"""

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

from ..models.frontmatter import parse_frontmatter, update_frontmatter
from ..models.registry import Registry
from ..utils.atomic_write import atomic_write_text


def main() -> int:
    """Update artifact frontmatter.

    Returns:
        0 on success, 1 on input error, 2 on state error
    """
    parser = argparse.ArgumentParser(
        description='Update artifact frontmatter fields',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Mark spec as complete
  update-artifact WI-001 --artifact spec --status complete

  # Update plan progress
  update-artifact WI-002 --artifact plan --phases-complete 3

  # Update multiple fields
  update-artifact WI-003 --artifact design --status in-progress --owner "John Doe"
        """
    )

    parser.add_argument(
        'code',
        help='Work item code (e.g., WI-001)'
    )
    parser.add_argument(
        '--artifact',
        choices=['spec', 'design', 'plan'],
        required=True,
        help='Artifact type to update'
    )
    parser.add_argument(
        '--status',
        choices=['draft', 'in-progress', 'complete'],
        help='New status value'
    )
    parser.add_argument(
        '--phases-complete',
        type=int,
        help='Number of completed phases (plan artifacts only)'
    )
    parser.add_argument(
        '--owner',
        help='Owner name or identifier'
    )

    args = parser.parse_args()

    # Normalize code to uppercase
    code = args.code.upper()

    # Validate at least one update field is provided
    if not any([args.status, args.phases_complete is not None, args.owner]):
        print(
            "Error: At least one update field must be provided "
            "(--status, --phases-complete, or --owner)",
            file=sys.stderr
        )
        return 1

    # Validate phases_complete is only used with plan artifacts
    if args.phases_complete is not None and args.artifact != 'plan':
        print(
            f"Error: --phases-complete can only be used with plan "
            f"artifacts, not {args.artifact}",
            file=sys.stderr
        )
        return 1

    try:
        # Load registry
        registry_path = Path('.project/registry.json')
        if not registry_path.exists():
            print(f"Error: Registry not found at {registry_path}", file=sys.stderr)
            return 2

        registry = Registry()
        registry.load()

        # Find work item
        item = registry.get_item(code)
        if item is None:
            print(f"Error: Work item {code} not found in registry", file=sys.stderr)
            return 2

        # Check if item is in backlog (no path)
        if item.path is None:
            print(
                f"Error: Cannot update artifact for backlog item {code} "
                f"(no filesystem path)",
                file=sys.stderr
            )
            return 2

        # Construct artifact file path
        artifact_filename = f"{args.artifact}.md"
        artifact_path = Path(item.path) / artifact_filename

        if not artifact_path.exists():
            print(f"Error: Artifact file not found at {artifact_path}", file=sys.stderr)
            return 2

        # Read current content
        content = artifact_path.read_text(encoding='utf-8')

        # Parse frontmatter
        frontmatter, body = parse_frontmatter(content)
        if frontmatter is None:
            print(
                f"Error: No valid frontmatter found in {artifact_path}",
                file=sys.stderr
            )
            return 2

        # Build updates dictionary
        updates: dict[str, str | int] = {}

        if args.status:
            updates['status'] = args.status

        if args.phases_complete is not None:
            # Validate phases_complete is non-negative
            if args.phases_complete < 0:
                print("Error: --phases-complete must be non-negative", file=sys.stderr)
                return 1

            # Validate against phases_total if present
            if 'phases_total' in frontmatter:
                phases_total = frontmatter['phases_total']
                if (isinstance(phases_total, int) and
                        args.phases_complete > phases_total):
                    print(
                        f"Error: --phases-complete ({args.phases_complete}) "
                        f"exceeds phases_total ({phases_total})",
                        file=sys.stderr
                    )
                    return 1

            updates['phases_complete'] = args.phases_complete

        if args.owner:
            updates['owner'] = args.owner

        # Always update the 'updated' timestamp
        now = datetime.now(UTC).isoformat(timespec='seconds')
        updates['updated'] = now

        # Update frontmatter
        updated_content = update_frontmatter(content, updates)

        # Write updated content atomically (note: content first, then path)
        atomic_write_text(updated_content, artifact_path)

        # Output JSON result (convert Path to string for JSON serialization)
        result = {
            'code': code,
            'artifact': args.artifact,
            'path': str(artifact_path),
            'updates': {
                k: str(v) if isinstance(v, Path) else v
                for k, v in updates.items()
            }
        }
        print(json.dumps(result, indent=2))

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
