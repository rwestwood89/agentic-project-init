# CLAUDE.md Checklist

After running init, verify your CLAUDE.md includes these sections for optimal slash command support.

## Required for Commands

| Section | Used By | What to Include |
|---------|---------|-----------------|
| Test commands | `/_my_implement`, `/_my_code_quality` | How to run tests (e.g., `pytest`, `npm test`, `cargo test`) |
| Lint/format commands | `/_my_code_quality` | How to lint/format (e.g., `ruff check`, `eslint`, `prettier`) |
| Build commands | `/_my_implement` | How to build the project (if applicable) |

## Helpful for Commands

| Section | Used By | What to Include |
|---------|---------|-----------------|
| Project structure | `/_my_design`, `/_my_research` | Key directories, where code lives |
| Conventions/patterns | `/_my_design` | Coding patterns, architectural decisions |
| Environment setup | `/_my_implement`, `/_my_code_quality` | How to set up dev environment |

## Example Sections

```markdown
## Development Commands

- Run tests: `pytest tests/`
- Format code: `ruff format .`
- Lint code: `ruff check .`
- Type check: `mypy src/`

## Project Structure

- `src/` - Main source code
- `tests/` - Test files
- `docs/` - Documentation

## Conventions

- Follow existing patterns in the codebase
- All new code should have tests
- Use type hints for public functions
```

## If Missing

Commands will gracefully handle missing info by:
- Asking you directly
- Exploring the codebase for common patterns
- Using sensible defaults

This checklist is guidance, not a hard requirement.
