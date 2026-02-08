
## Purpose
Ensure all registry and artifact file modifications are atomic to prevent corruption from partial writes or failures.

## Requirements
- All scripts that write files must use atomic write pattern
- Pattern: write to temporary file, then rename to target path
- Python implementation uses `tempfile.mkstemp()` or `tempfile.NamedTemporaryFile()` and `os.rename()`
- Temporary files must be in same filesystem as target (for atomic rename guarantee)
- If write or rename fails, temporary file is cleaned up
- Atomic writes apply to: registry.json, all artifact frontmatter updates, dashboard.html
- Permissions of target file are preserved after rename

## Acceptance Criteria

**Given** a script writes an updated registry  
**When** the write operation is performed  
**Then** data is written to a temp file in `.project/`, then renamed to `registry.json`

**Given** a script updates artifact frontmatter  
**When** the update is performed  
**Then** new content is written to temp file in same directory as artifact, then renamed

**Given** a write operation fails halfway through (disk full, interrupted)  
**When** the error occurs  
**Then** target file is unchanged (old content remains), temp file is deleted

**Given** a rename operation succeeds  
**When** the file is replaced  
**Then** the operation is atomic (no partial states visible to other processes)

**Given** a script crashes after writing temp file but before rename  
**When** the script is re-run  
**Then** orphaned temp file is ignored or cleaned up, new temp file is used

## Interfaces

### Python Implementation Pattern

```python
import tempfile
import os
import json

def atomic_write_json(data, target_path):
    """Write data to target_path atomically."""
    dir_path = os.path.dirname(target_path)
    fd, temp_path = tempfile.mkstemp(dir=dir_path, prefix='.tmp_', suffix='.json')
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(data, f, indent=2)
        os.chmod(temp_path, 0o644)  # Set readable permissions
        os.rename(temp_path, target_path)
    except Exception as e:
        os.unlink(temp_path)  # Clean up on failure
        raise e

