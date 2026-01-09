# Memorize

Create a structured memory artifact from a conversation transcript. Can be called anytime, not just after compaction.

## Usage

```
/_my_memorize                           # process most recent pending capture
/_my_memorize <transcript-path>         # memorize a specific transcript
/_my_memorize <capture-file>            # process a specific capture file
```

## Instructions

1. **Determine the transcript to process:**
   - If argument is a `.jsonl` file, use it directly as the transcript
   - If argument is a `-capture.md` file, read it to get the transcript path
   - If no argument, find the most recent `*-capture.md` in `.project/memories/` with status "pending"
   - If no pending captures, inform the user they can specify a transcript path directly

2. **Parse the transcript using the helper script:**
   - Run: `.claude/hooks/parse-transcript.py <transcript-path> --max-chars=40000`
   - This handles large transcripts by extracting key messages

3. **Generate a timestamp ID** for this memory (or use existing if from a capture)

4. **Analyze the parsed output** and create a memory file at `.project/memories/{id}-memory.md`:

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

   ## Topics
   - keyword1
   - keyword2
   - keyword3
   ```

5. **Update the index** at `.project/memories/index.json`:
   - Add entry to `memories` array with id, created, transcript, memory_file, summary, topics, source
   - Update `transcripts` entry to include this memory_id
   - Use jq or read/write JSON carefully

6. **If processing a capture file**, update it:
   - Change status from "pending" to "memorized"
   - Add link to memory file

7. **Report** what you created to the user

$ARGUMENTS
