# Review Compact

Review an autocompact capture and create a structured memory file.

## Usage

- `/review-compact` — process the most recent pending capture
- `/review-compact path/to/metadata.md` — process a specific capture

## Instructions

1. **Find the metadata file:**
   - If an argument is provided, use that path
   - Otherwise, find the most recent `*-autocompact.md` file in `.project/compacts/` with status "pending"
   - If no pending files exist, inform the user

2. **Read the metadata file** to get the transcript path

3. **Parse the transcript using the helper script:**
   - Run: `.claude/hooks/parse-transcript.py <transcript-path> --max-chars=40000`
   - This handles large transcripts by extracting key messages and sampling the conversation
   - Read the output — it contains a structured summary with first/last messages and conversation samples

4. **Analyze the parsed output** and create a memory file at `.project/compacts/{same-timestamp}-memory.md` with:

   ```markdown
   # Memory: {brief title}

   ## Goal
   What was the user trying to accomplish?

   ## Learnings
   - Key insights discovered
   - Important decisions made
   - Technical details worth preserving

   ## Open Questions / Issues
   - Unresolved problems
   - Things that need follow-up
   - Blockers encountered

   ## Confidence Level
   How confident are we in the work done? (High/Medium/Low with brief explanation)

   ## Key Files
   - List any important files that were created or modified
   ```

5. **Update the original metadata file:**
   - Change status from "pending" to "reviewed"
   - Add a `## Summary` section with a 1-2 sentence description of the conversation
   - Update the `## Memory` section with a link to the memory file

6. **Report** what you did to the user

$ARGUMENTS
