"""Tests for slug utility."""


from src.utils.slug import slugify


def test_slugify_basic() -> None:
    """Test basic slugification."""
    assert slugify("Hello World") == "hello-world"


def test_slugify_special_characters() -> None:
    """Test removal of special characters."""
    assert slugify("Design Auth Flow!!") == "design-auth-flow"
    assert slugify("Item #123") == "item-123"
    assert slugify("Test@Example.com") == "test-example-com"


def test_slugify_multiple_spaces() -> None:
    """Test collapsing of multiple spaces."""
    assert slugify("  Multiple   Spaces  ") == "multiple-spaces"


def test_slugify_leading_trailing_hyphens() -> None:
    """Test removal of leading/trailing hyphens."""
    assert slugify("--Test Item--") == "test-item"
    assert slugify("-Leading") == "leading"
    assert slugify("Trailing-") == "trailing"


def test_slugify_preserve_numbers() -> None:
    """Test that numbers are preserved."""
    assert slugify("Item 123") == "item-123"
    assert slugify("v2.0 Release") == "v2-0-release"


def test_slugify_empty_string() -> None:
    """Test empty string handling."""
    assert slugify("") == ""
    assert slugify("   ") == ""


def test_slugify_only_special_characters() -> None:
    """Test string with only special characters."""
    assert slugify("!!!") == ""
    assert slugify("@#$%") == ""


def test_slugify_unicode() -> None:
    """Test Unicode character handling."""
    # Non-ASCII characters should be removed
    assert slugify("Café") == "caf"
    assert slugify("Naïve") == "na-ve"


def test_slugify_collapse_consecutive_hyphens() -> None:
    """Test that consecutive hyphens are collapsed."""
    assert slugify("Test -- Item") == "test-item"
    assert slugify("A---B---C") == "a-b-c"
