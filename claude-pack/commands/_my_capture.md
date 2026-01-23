# Capture

Mark the current conversation for later review with `/_my_memorize`.

## Usage

```
/_my_capture                    # capture current session
/_my_capture --memorize         # capture AND create memory now
```

## Instructions

1. **Resolve hook paths:**
   ```bash
   CONFIG_FILE=".claude/.hook-paths.json"
   [ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.claude/.hook-paths.json"

   if [ ! -f "$CONFIG_FILE" ]; then
     echo "Error: No hook configuration found. Run setup-global.sh first."
     exit 1
   fi
   ```

2. **Find the current transcript:**
   ```bash
   QUERY_TRANSCRIPT=$(jq -r '.hooks["query-transcript"]' "$CONFIG_FILE")
   "$QUERY_TRANSCRIPT" --list --json
   ```
   - Take the first (most recent) transcript — this is the current session

3. **Run the capture script:**
   ```bash
   CAPTURE_HOOK=$(jq -r '.hooks["capture"]' "$CONFIG_FILE")
   "$CAPTURE_HOOK" <transcript_path> manual
   ```
   - This creates a capture file in `.project/memories/`
   - Updates the index

4. **If `--memorize` flag was passed:**
   - Also run `/_my_memorize` to create the memory artifact immediately

5. **Report** the capture file path to the user

$ARGUMENTS
