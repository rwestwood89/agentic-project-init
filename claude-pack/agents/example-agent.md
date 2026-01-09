---
name: example-agent
description: Example custom agent template
tools: ["Read", "Grep", "Glob", "Bash"]
---

This is an example custom agent. Replace this content with your own agent logic.

Agents are specialized subprocesses that can autonomously handle complex tasks using specific tool subsets.

## Example Use Cases:
- Specialized code reviewers
- Test generators
- Documentation writers
- Refactoring assistants
- Bug hunters

## Available Tools:
Configure the `tools` array in the frontmatter to specify which tools this agent can use.

## Documentation:
https://github.com/anthropics/claude-code
