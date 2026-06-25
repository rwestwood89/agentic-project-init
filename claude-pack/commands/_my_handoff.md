# Handoff

Write a handoff document so a fresh agent can pick up where this session left off.

## Instructions

1. Choose a path in the OS temp directory: `${TMPDIR:-/tmp}/handoff-$(date +%Y%m%d-%H%M%S).md`. Do not save inside the workspace.
2. Write the document with these sections:
   - **Focus** — if `$ARGUMENTS` is given, treat it as the next session's focus and tailor the rest accordingly. Otherwise summarize what the next session should pick up.
   - **Context** — brief situation summary. Reference PRDs, plans, ADRs, issues, commits, and diffs by path or URL instead of restating their contents.
   - **Key Discoveries** — non-obvious learnings from this conversation (gotchas, dead ends, validated assumptions) that aren't already captured in those artifacts.
   - **Suggested Skills** — slash commands the next agent should likely invoke (e.g. `/_my_project_find`, `/_my_plan`), one line of reasoning each.
   - **Open Questions** — anything unresolved or awaiting user input.
3. Redact secrets before writing: API keys, tokens, passwords, PII, customer data. Replace with `[REDACTED]`.
4. Print the absolute path of the file you wrote so the user can share it.

$ARGUMENTS
