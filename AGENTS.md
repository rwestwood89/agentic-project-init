claude -p --model sonnet "$(cat << 'EOF'
Generate an AGENTS.md file for a Ralph Wiggum loop. This is the operational 
guide loaded into EVERY iteration. It must be:

- BRIEF (~60 lines max). Every token costs context in every iteration.
- OPERATIONAL ONLY. No status, no progress, no changelogs.
- Focused on HOW TO BUILD AND TEST.

The project uses:
- Python with UV for package management
- pytest for testing
- ruff for linting  
- mypy for type checking

Include ONLY these sections:

## Build & Run
[Exact commands to install deps and run the project]

## Validation
[Exact commands for tests, typecheck, lint - these are the backpressure]

## Codebase Patterns
[Key conventions: project structure, imports, error handling]
[Any critical rules from the design constraints]

## Known Gotchas
[Common agent pitfalls for this specific project]

Output ONLY the AGENTS.md content, no explanations.

---

DESIGN DOCUMENT:

EOF
cat DESIGN.md)" > AGENTS.md

head -40 AGENTS.md