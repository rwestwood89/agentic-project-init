# Change: Design Review Materiality

**Status:** Implemented; behavioral validation pending

## Requirements

- `[OWNER]` Keep technical design focused on understanding the system shape, important invariants, and consequential choices. Do not require implementation decisions that are better made while reading and changing the code.
- `[OWNER]` A design review blocks only for defects that can materially mislead implementation, violate a governing requirement, leave consequential ownership or architecture unresolved, or make broad rework likely.
- `[OWNER]` Route reversible implementation details to the implementation agent. Let audit, human code review, and PR review critique the resulting code.
- `[OWNER]` Make a tight correction to the design and design-review prompts now. Do not redesign planning or perform a broad pipeline cleanse in this item.
- `[OWNER]` Defer deeper changes until real usage or A/B evidence shows what works better.

## Validation

- [x] The authored design prompt no longer requires every technical question or edge case to be settled before implementation.
- [x] The authored review prompt distinguishes design blockers from implementation observations, does not manufacture findings from generic dimensions, and reports currently discoverable blockers together.
- [x] Generated Codex skills match the authored prompts after rebuilding the pack.
- [x] `test_codex_orchestrator_pack.sh`, `test_docs.sh`, `test_pipeline_sync.sh`, and `git diff --check` pass.
- [ ] Exercise the revised prompts on real design work and compare review rounds, document size, blocker precision, and implementation/audit quality before attempting a broader pipeline cleanup.

## Implementation Note

The design workflow, plan prompt, implementation prompt, audit prompt, and shared product-lens prompt were deliberately left unchanged. This pass narrows the design readiness bar and replaces the design review's exhaustive rubric with a materiality gate. Reversible details now stay explicitly open for implementation and later review in working code. The reviewer may invoke `/_my_ponytail` as a deletion-first lens when complexity is materially at issue; its suggestions do not bypass the blocker bar.
