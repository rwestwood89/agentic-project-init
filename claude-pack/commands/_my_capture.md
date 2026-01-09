# Capture

Mark the current conversation for later review with `/_my_memorize`.

## Usage

```
/_my_capture                    # capture current session
/_my_capture --memorize         # capture AND create memory now
```

## Instructions

1. **Find the current transcript:**
   - Run: `.claude/hooks/query-transcript.py --list --json`
   - Take the first (most recent) transcript — this is the current session

2. **Run the capture script:**
   ```bash
   .claude/hooks/_my_capture.sh <transcript_path> manual
   ```
   - This creates a capture file in `.project/memories/`
   - Updates the index

3. **If `--memorize` flag was passed:**
   - Also run `/_my_memorize` to create the memory artifact immediately

4. **Report** the capture file path to the user

$ARGUMENTS
