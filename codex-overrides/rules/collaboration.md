# Codex Collaboration Calls

When calling `spawn_agent`:

- `fork_turns: "all"` inherits the parent agent type, model, and reasoning effort. Do not combine
  it with `agent_type`, `model`, or `reasoning_effort`.
- `fork_turns` defaults to `"all"`, so specifying one of those overrides without setting
  `fork_turns` is also invalid.
- To select an agent type, model, or reasoning effort, set `fork_turns` to `"none"` or a positive
  turn count.
- Use `fork_turns: "none"` for fresh explorer, reviewer, and product-lens agents unless inherited
  conversation history is specifically required.
