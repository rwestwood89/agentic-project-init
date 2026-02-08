"""YAML frontmatter parsing and updating for markdown artifacts.

This module provides utilities to parse and update YAML frontmatter in
spec.md, design.md, and plan.md files. Frontmatter is delimited by '---'
lines and contains metadata about work items.
"""

import re
from typing import Any

import yaml


def parse_frontmatter(content: str) -> tuple[dict[str, Any] | None, str]:
    """Parse YAML frontmatter from markdown content.

    Args:
        content: Full markdown file content

    Returns:
        Tuple of (frontmatter_dict, body_content)
        - frontmatter_dict is None if no valid frontmatter found
        - body_content is the content after frontmatter
          (or entire content if no frontmatter)

    Examples:
        >>> content = "---\\nid: WI-001\\n---\\nBody text"
        >>> meta, body = parse_frontmatter(content)
        >>> meta['id']
        'WI-001'
        >>> body
        'Body text'
    """
    # Match frontmatter: starts with ---, YAML content, ends with ---
    # The (?:...) is a non-capturing group
    # [\s\S] matches any character including newlines
    pattern = r'^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$'
    match = re.match(pattern, content)

    if not match:
        return None, content

    yaml_content = match.group(1)
    body_content = match.group(2)

    try:
        frontmatter = yaml.safe_load(yaml_content)
        if not isinstance(frontmatter, dict):
            return None, content
        return frontmatter, body_content
    except yaml.YAMLError:
        return None, content


def update_frontmatter(
    content: str,
    updates: dict[str, Any],
    create_if_missing: bool = False
) -> str:
    """Update specific fields in YAML frontmatter.

    Args:
        content: Original markdown content
        updates: Dictionary of fields to update (merged into existing frontmatter)
        create_if_missing: If True, create new frontmatter if none exists

    Returns:
        Updated markdown content with modified frontmatter

    Raises:
        ValueError: If frontmatter is missing and create_if_missing=False

    Examples:
        >>> content = "---\\nid: WI-001\\nstatus: draft\\n---\\nBody"
        >>> updated = update_frontmatter(content, {'status': 'complete'})
        >>> 'status: complete' in updated
        True
        >>> 'Body' in updated
        True
    """
    frontmatter, body = parse_frontmatter(content)

    if frontmatter is None:
        if not create_if_missing:
            raise ValueError("No frontmatter found and create_if_missing=False")
        frontmatter = {}

    # Merge updates into existing frontmatter
    frontmatter.update(updates)

    # Serialize back to YAML
    yaml_str = yaml.dump(
        frontmatter,
        default_flow_style=False,
        allow_unicode=True,
        sort_keys=False
    )

    # Reconstruct markdown with updated frontmatter
    return f"---\n{yaml_str}---\n{body}"


def validate_frontmatter(frontmatter: dict[str, Any]) -> list[str]:
    """Validate frontmatter contains required fields with correct types.

    Args:
        frontmatter: Parsed frontmatter dictionary

    Returns:
        List of validation error messages (empty list if valid)

    Examples:
        >>> validate_frontmatter({'id': 'WI-001', 'type': 'spec', 'status': 'draft'})
        []
        >>> errors = validate_frontmatter({'id': 'WI-001'})
        >>> 'type' in errors[0]
        True
    """
    errors = []

    # Required fields for all artifacts
    required_common = [
        'id', 'title', 'type', 'status', 'epic', 'owner', 'created', 'updated'
    ]

    for field in required_common:
        if field not in frontmatter:
            errors.append(f"Missing required field: {field}")

    # Validate types if present
    if 'type' in frontmatter:
        valid_types = {'spec', 'design', 'plan'}
        if frontmatter['type'] not in valid_types:
            errors.append(
                f"Invalid type: {frontmatter['type']} "
                f"(must be one of {valid_types})"
            )

    if 'status' in frontmatter:
        valid_statuses = {'draft', 'in-progress', 'complete'}
        if frontmatter['status'] not in valid_statuses:
            errors.append(
                f"Invalid status: {frontmatter['status']} "
                f"(must be one of {valid_statuses})"
            )

    # Validate plan-specific fields
    if frontmatter.get('type') == 'plan':
        if 'phases_total' not in frontmatter:
            errors.append("Plan artifact missing required field: phases_total")
        elif (
            not isinstance(frontmatter['phases_total'], int)
            or frontmatter['phases_total'] < 0
        ):
            errors.append("phases_total must be a non-negative integer")

        if 'phases_complete' not in frontmatter:
            errors.append("Plan artifact missing required field: phases_complete")
        elif (
            not isinstance(frontmatter['phases_complete'], int)
            or frontmatter['phases_complete'] < 0
        ):
            errors.append("phases_complete must be a non-negative integer")

    # Validate ID format
    if 'id' in frontmatter:
        id_pattern = r'^(EP|WI)-\d{3}$'
        if not re.match(id_pattern, frontmatter['id']):
            errors.append(
                f"Invalid ID format: {frontmatter['id']} "
                "(must match EP-NNN or WI-NNN)"
            )

    return errors


def extract_frontmatter_field(content: str, field: str) -> Any:
    """Extract a single field from frontmatter without parsing the entire document.

    This is a convenience function for when you only need one field.

    Args:
        content: Markdown content with frontmatter
        field: Field name to extract

    Returns:
        Field value, or None if not found

    Examples:
        >>> content = "---\\nid: WI-001\\nstatus: draft\\n---\\nBody"
        >>> extract_frontmatter_field(content, 'id')
        'WI-001'
        >>> extract_frontmatter_field(content, 'missing')
        None
    """
    frontmatter, _ = parse_frontmatter(content)
    if frontmatter is None:
        return None
    return frontmatter.get(field)
