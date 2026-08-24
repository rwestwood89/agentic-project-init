## spec — 2026-08-13 — rev .project/active/codex-orchestrator-observable-waiting/spec.md
Point (re-derived): Codex orchestration must keep stages isolated and auditable, while leaving `close` and post-close `pre_pr` to the human unless requested. [source: `docs/guide.md`; `.project/adr/0007-pre-pr-branch-gate-after-close.md`, grade: INHERITED; owner/HARD]
Falsifier: The changed orchestrator loses per-stage isolation or its commit trail, or runs `close`/`pre_pr` without an explicit request.
Findings:
- spec-F1 [DO] The spec does not explicitly preserve the owner-required boundary that orchestration leaves `close` and post-close `pre_pr` to the human unless requested; the broad stage-selection non-goal does not make that observable invariant testable — `.project/adr/0007-pre-pr-branch-gate-after-close.md` (owner/HARD) — disposition: BLOCK
- spec-F2 [DO] The success criteria preserve stage protocol and diagnostics but omit the documented one-headless-agent-per-stage isolation and auditable commit trail — `docs/guide.md` (INHERITED) — disposition: add an explicit preservation criterion before design
Gate: BLOCKED (spec-F1)

## spec — 2026-08-13 — rev .project/active/codex-orchestrator-observable-waiting/spec.md
Point (re-derived): Codex orchestration must keep stages isolated and auditable, while leaving `close` and post-close `pre_pr` to the human unless requested. [source: `docs/guide.md`; `.project/adr/0007-pre-pr-branch-gate-after-close.md`, grade: INHERITED; owner/HARD]
Falsifier: The changed orchestrator loses per-stage isolation or its commit trail, or runs `close`/`pre_pr` without an explicit request.
Findings:
- None.
Gate: CLEAR
Resolves:
- spec-F1: FIXED — authority: owner — basis: The Success Criteria and Known Requirements now explicitly preserve ADR 0007’s human-owned `close` and post-close `pre_pr` boundary.
- spec-F2: FIXED — authority: INHERITED — basis: The Success Criteria and Known Requirements now explicitly preserve one isolated headless agent per stage and the auditable commit trail.

## audit — 2026-08-13 — rev b114400 + working tree (uncommitted)
Point (re-derived): Codex orchestration must let the owner follow the main agent's terminal timeline without spending parent-model turns to learn there is no news, while keeping one isolated headless agent per stage, an auditable commit trail, generated `dist/codex/` regenerated from source, and `close` plus the post-close `pre_pr` branch gate left to the human unless asked.   [source: owner quotes 2026-08-13 ("it makes following the progress of the main agent in terminal impossible", "Codex seems to very actively poll, which seems like kind of a waste of tokens"); `docs/guide.md:137`; `.project/adr/0007-pre-pr-branch-gate-after-close.md`; `docs/STRUCTURE.md:98`, grade: owner/HARD; INHERITED]
Falsifier: A long stage produces repeated no-news wait rows or repeated prompt/command bodies in the parent timeline; or the orchestrator invokes `pre_pr`/`close` without an explicit request; or `dist/codex/` diverges from `codex-overrides/` on rebuild.
Findings:
- audit-F1 [DO] The Codex orchestrator's finish rule gates only `$my-close` (`codex-overrides/command-skill-replacements/orchestrate/SKILL.md:118`) while listing `$my-pre-pr` as a common stage with no gate (`:108`, `:145`), so it does not carry ADR 0007's human-owned post-close `pre_pr` boundary that the Claude command states in full (`claude-pack/commands/_my_orchestrate.md:73-74`); the new tests assert no boundary at all — `.project/adr/0007-pre-pr-branch-gate-after-close.md` (owner/HARD, active) — disposition: BLOCK
- audit-F2 [DO] Smell 1 (two representations manually synchronized): the host-cell recipe requires the agent to hand-sync three copies of the stage timeout — `--timeout T` in the bash command, `helperTimeoutSeconds` in the JS body, and the literal `yield_time_ms` in the `// @exec:` pragma (`.../orchestrate/SKILL.md`, "## Tools"). Drift makes the outer cell yield before the helper is terminal and drops execution into the `functions.wait` fallback, i.e. back toward the model-visible waiting the owner complained about — owner quote 2026-08-13 (owner/HARD) via [INFERRED] mechanism reading — disposition: DISPOSE (derive the pragma and the JS literal from one stated `T`, or assert the arithmetic in `scripts/test_codex_orchestrator_pack.sh`)
- audit-F3 [DO] Smell 6 (test passes by selecting one route) and smell 4 (correctness rests on an external internal detail): the cancellation test's fake codex traps and honours TERM, so the SIGKILL escalation branch in `cancel_runner` is never exercised; that branch works only because GNU `timeout` puts its child in its own process group, a fact stated nowhere in the script — `docs/guide.md:137` (INHERITED) — disposition: DISPOSE (add a TERM-ignoring fake-codex case and a one-line comment naming the `timeout` process-group dependency)
Gate: BLOCKED (audit-F1)

## audit — 2026-08-13 — rev b114400 + working tree (audit-F1 remediation)
Point (re-derived): Codex orchestration must remove no-news parent waiting while preserving isolated, auditable stages and human ownership of `close` and post-close `pre_pr` unless requested. [source: `.project/active/codex-orchestrator-observable-waiting/spec.md`; `docs/guide.md`; `.project/adr/0007-pre-pr-branch-gate-after-close.md`, grade: owner/HARD; INHERITED]
Falsifier: A long stage creates repeated no-news parent turns, or the orchestrator permits autonomous `close`/`pre_pr`, or generated Codex behavior diverges from its authored source.
Findings:
- None.
Gate: CLEAR
Resolves:
- audit-F1: FIXED — authority: owner — basis: The authored and generated skills now preserve the complete `close`/post-close `pre_pr` boundary (`SKILL.md:118`), and the generated-pack test asserts it (`scripts/test_codex_orchestrator_pack.sh:315`; focused suite passes).
