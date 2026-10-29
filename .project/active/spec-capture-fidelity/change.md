# Change: Spec Capture Fidelity

**Status:** Implemented; behavioral validation pending

## Requirements

- `[OWNER]` Capture in plain English, and with the richness provided by the owner and surrounding context, what the intent for the work item is.
- `[OWNER]` Collect additional context as needed to understand what the owner is looking for.
- `[OWNER]` Question in rounds over the current frontier: the material decisions whose prerequisites are already settled. Investigate facts; ask the owner for decisions.
- `[OWNER]` Record additional need statements with provenance. Use EARS where it adds clarity rather than as a mandatory translation exercise.
- `[OWNER]` Keep the prompt simple and outcome-focused.

## Validation

- [x] The command leads with the desired artifact and behavior rather than a catalog of failure prohibitions.
- [x] The owner request is captured before questioning begins.
- [x] Question rounds follow the frontier model without requiring every possible branch to be explored.
- [x] Provenance and optional EARS phrasing apply to additional need statements.
- [x] Generated Codex guidance matches the authored command.
- [x] The authored command is 94 lines, down from 183.
- [x] `test_codex_orchestrator_pack.sh`, `test_docs.sh`, `test_pipeline_sync.sh`, and `git diff --check` pass.
- [ ] Validate on real work items with rich owner input before changing spec review or the rest of the pipeline.
