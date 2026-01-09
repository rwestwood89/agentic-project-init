# Recall

Retrieve information from past conversations using a research subagent.

## Usage

```
/_my_recall <question>                      # search most recent transcript
/_my_recall --all <question>                # search ALL transcripts
/_my_recall --index <question>              # search only indexed/_my_memorized transcripts
/_my_recall <transcript-path> <question>    # search specific transcript
```

## Examples

```
/_my_recall What files did we create?
/_my_recall --all What authentication approaches have I discussed?
/_my_recall --index What were the key decisions?
/_my_recall ~/.claude/projects/.../session.jsonl What errors did we encounter?
```

## Instructions

1. **Parse the arguments:**
   - If `--all` flag present, search all transcripts
   - If `--index` flag present, search only indexed transcripts
   - If first arg looks like a path (contains `/` or `.jsonl`), use it as specific transcript
   - Otherwise, use "latest" as transcript path and treat all args as the question

2. **Spawn a subagent** using the Task tool:
   - Use the recall agent defined in `.claude/agents/_my_recall.md`
   - Pass the search mode (all/index/latest/_my_specific) and question
   - The subagent will use `query-transcript.py` to search

3. **Return the subagent's findings** to the user

## Subagent Prompt Template

```
You are a recall agent. Read your instructions from .claude/agents/_my_recall.md

Search mode: {all|index|latest|specific}
Transcript: {transcript_path if specific, otherwise N/A}
Question: {question}

Find the answer by querying transcripts using .claude/hooks/query-transcript.py
```

$ARGUMENTS
