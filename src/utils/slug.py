"""Utilities for generating URL-safe slugs from text."""

import re


def slugify(text: str) -> str:
    """Convert text to a URL-safe slug.

    Args:
        text: Input text to slugify

    Returns:
        Lowercase slug with words separated by hyphens

    Examples:
        >>> slugify("Hello World")
        'hello-world'
        >>> slugify("Design Auth Flow!!")
        'design-auth-flow'
        >>> slugify("  Multiple   Spaces  ")
        'multiple-spaces'
    """
    # Convert to lowercase
    text = text.lower()

    # Replace non-alphanumeric characters with hyphens
    text = re.sub(r'[^a-z0-9]+', '-', text)

    # Remove leading/trailing hyphens
    text = text.strip('-')

    # Collapse multiple hyphens
    text = re.sub(r'-+', '-', text)

    return text
