I'm setting up a Ralph Wiggum loop to build this system. Ralph loops work by
having an AI agent iterate in a bash loop, each iteration getting fresh context.
The agent reads specs, picks a task from an implementation plan, implements it,
runs tests, commits, and exits.

Break this design into individual specification files for a `specs/` directory.
Each spec should cover ONE topic of concern — a distinct capability area that
can be described in one sentence without using "and" to conjoin unrelated things.

For EACH spec file, use this exact format:

```markdown specs/[filename].md
# [Topic Name]

## Purpose
[One sentence describing what this component does]

## Requirements
[Behavioral outcomes as bullet points - what observable results indicate success?]

## Acceptance Criteria
[Specific, testable conditions using Given/When/Then or similar]

## Interfaces
[How this connects to other components - inputs, outputs, data formats]
[Reference other spec files by name where relevant]

## Constraints
[Non-negotiable rules - what must NEVER happen?]

## Out of Scope
[What this spec explicitly does NOT cover]
```

Important:
- Use the EXACT format above with ```markdown specs/filename.md as the code fence
- Each spec should be 50-150 lines
- Order specs by dependency (foundational first)
- Acceptance criteria should be machine-verifiable where possible
- Think about what tests would catch bad implementations

CRITICAL FORMAT REQUIREMENT:
Your output will be parsed by a machine. The parser scans for lines matching
exactly: ```markdown specs/FILENAME.md  (opening fence with path)
and extracts content until the next ``` (closing fence).

If the parser finds ZERO matching fences, the entire step FAILS.
Common mistakes that cause FAIL:
- Writing a prose summary like "I've created 16 specification files..."
- Using ```md instead of ```markdown
- Omitting the specs/ path prefix
- Adding extra text before the first fenced block

Start DIRECTLY with the first ```markdown specs/... fenced block.
Do NOT include any introductory text, summary, or explanation before or between spec blocks.

---

DESIGN DOCUMENT:

