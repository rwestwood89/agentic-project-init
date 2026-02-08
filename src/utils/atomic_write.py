"""Atomic file write utilities to prevent corruption from partial writes.

All registry and artifact modifications use these functions to ensure
all-or-nothing write semantics.
"""

import json
import os
import tempfile
from pathlib import Path
from typing import Any


def atomic_write_json(data: Any, target_path: str | Path) -> None:
    """Write data to target_path as JSON atomically.

    Uses temp file + rename pattern to ensure atomic write:
    1. Write to temporary file in same directory as target
    2. Rename temp file to target (atomic operation)
    3. Clean up temp file on any failure

    Args:
        data: Python object to serialize as JSON
        target_path: Destination file path

    Raises:
        OSError: If write or rename fails
        TypeError: If data is not JSON-serializable
    """
    target_path = Path(target_path)
    dir_path = target_path.parent

    # Ensure parent directory exists
    dir_path.mkdir(parents=True, exist_ok=True)

    # Create temp file in same directory (required for atomic rename)
    fd, temp_path = tempfile.mkstemp(
        dir=dir_path,
        prefix='.tmp_',
        suffix='.json'
    )

    try:
        # Write JSON data to temp file
        with os.fdopen(fd, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # Add trailing newline for better git diffs

        # Set readable permissions (rw-r--r--)
        os.chmod(temp_path, 0o644)

        # Atomic rename (replaces target if it exists)
        os.rename(temp_path, target_path)

    except Exception as e:
        # Clean up temp file on any failure
        try:
            os.unlink(temp_path)
        except OSError:
            pass  # Temp file may not exist if error was in mkstemp
        raise e


def atomic_write_text(content: str, target_path: str | Path) -> None:
    """Write text content to target_path atomically.

    Uses temp file + rename pattern to ensure atomic write.
    Used for markdown artifacts (spec.md, design.md, plan.md).

    Args:
        content: Text content to write
        target_path: Destination file path

    Raises:
        OSError: If write or rename fails
    """
    target_path = Path(target_path)
    dir_path = target_path.parent

    # Ensure parent directory exists
    dir_path.mkdir(parents=True, exist_ok=True)

    # Create temp file in same directory
    fd, temp_path = tempfile.mkstemp(
        dir=dir_path,
        prefix='.tmp_',
        suffix=target_path.suffix
    )

    try:
        # Write text content to temp file
        with os.fdopen(fd, 'w', encoding='utf-8') as f:
            f.write(content)
            if not content.endswith('\n'):
                f.write('\n')  # Ensure trailing newline

        # Set readable permissions (rw-r--r--)
        os.chmod(temp_path, 0o644)

        # Atomic rename
        os.rename(temp_path, target_path)

    except Exception as e:
        # Clean up temp file on any failure
        try:
            os.unlink(temp_path)
        except OSError:
            pass
        raise e
