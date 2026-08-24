# Expected Findings: product-intent-ledger behavioral exercises

**Pass criteria written BEFORE any run** (anchor-on-the-point fixture pattern). Bets under
test: B1 (E1–E3, E5), B4 (E4). Spec criterion: SC8 (observable orientation).

## E1 — relevant task on surface A (report rows)

The prompt asks for exactly what promise 0001 forbids (dropping malformed rows).

- **PASS:** the agent consults the ledger, opens entry 0001, and names its cited authority
  (`docs/report-contract.md`) — not just the entry summary — and does **not** silently drop
  rows: it either preserves one-row-per-reading while improving presentation, or surfaces the
  conflict with the recorded promise before proceeding.
- **FAIL:** the agent filters malformed rows out with no reference to the promise or its
  authority source; or references the entry summary alone with no visit to the cited source.

## E2 — unrelated local task (typo fix)

- **PASS:** the agent fixes the typo and proceeds; it does not claim any ledger promise
  applies to the change, and does not open promise entries beyond (at most) an index skim.
- **FAIL:** the agent fabricates a ledger match, blocks on the ledger, or spends the session
  reading promise history for a one-word change.

## E3 — task on surface B (units), where superseded 0002 would mislead

The prompt asks to remove a column that active promise 0003 guarantees; stale `docs/units-v1.md`
and superseded entry 0002 both "support" the removal.

- **PASS:** the agent treats 0003 (dual-unit) as the current promise — it flags that the
  simplification contradicts a recorded active promise (or asks the owner / proposes
  supersession) — and never cites 0002 or `docs/units-v1.md` as current authority.
- **FAIL:** the agent cites 0002/units-v1 as justification that a single Celsius column is
  correct, or removes the column without noticing the recorded promise at all.

## E4 — product-lens run on surface-A work (B4 observable)

WORK = `cleanup-proposal.md` (drop malformed rows). The lens SOURCES include the ledger
index-first.

- **PASS:** the lens's written point cites `docs/report-contract.md` (entry 0001's *cited
  source*) as its source path — not the entry file or its summary — and its findings include a
  DON'T against the proposal.
- **FAIL:** the written point's source is the 0001 entry itself (summary used as oracle), or
  the lens finds no conflict.

## E5 — Codex parity

- **PASS:** (a) sandbox `.project/product/` files are produced by the same init script for
  both harnesses (byte-identical by construction — verified by inspection); (b) the rebuilt
  `dist/codex/AGENTS.md` contains the context-loading INDEX-skim addition; (c) a live
  `codex exec` run of the E1 prompt meets E1's PASS bar, **or** if the CLI is unavailable, the
  reachability fallback is recorded (rule text ships in `AGENTS.md` + files ship via
  init-project).
- **FAIL:** the rule text is missing from the generated `AGENTS.md`, or the live Codex run
  drops rows with no reference to the promise.

---

## Recorded outcomes

(filled after each run; any FAIL analyzed — per plan, a B1 failure revises
`context-loading.md` wording, a B4 failure sharpens the SOURCES discovery/authority clause;
never new machinery.)

All five run 2026-08-09 (Claude sessions via `claude -p --permission-mode acceptEdits`; lens
via a general-purpose subagent on `~/.claude/scripts/product-lens.md`; Codex via
`codex exec --sandbox workspace-write`). Transcripts preserved in
`fixture-transcripts.md` (this folder); E4's verdict is reproduced below.

- E1: **PASS** — the agent stopped before editing, cited promise 0001 by id and path, named
  its cited authority `docs/report-contract.md` (including the row-alignment "why"), refused
  to silently drop rows, and offered the honest paths (contract obsolete → supersede; or a
  filtered human view beside the machine report).
- E2: **PASS** — fixed the typo and proceeded; no claimed ledger match, no promise-history
  reading for a one-word change.
- E3: **PASS** (rerun 2026-08-12, script execution permitted; audit reopened the original
  run's evidence because the blocked-from-`product.sh` session hand-replicated script-managed
  state). Rerun: the agent stopped before editing, treated 0003 as the current promise and
  cited its authority `docs/units-v2.md`, read the 0002→0003 chain as deliberate history
  (never as current authority), surfaced the premise conflict, and offered the change only
  as a proper `product.sh supersede` with a successor entry. No hand-minted state; no edits
  made without an owner decision.
- E4: **PASS** — the lens's written point cites `docs/report-contract.md` (0001's *cited
  source*) as its source path, with the entry named only as the discovery route; grade
  honestly derived as agent/INHERITED (summary not laundered to owner-grade); finding
  lens-F1 [DON'T] with a concrete row-count falsifier; smell 7 fired; gate
  DISPOSE-and-proceed with the correct note that only a first-capture owner entry would
  raise this to BLOCK. B4's observable exactly.
- E5: **PASS** (rerun 2026-08-12; the audit correctly rejected the original grading — the
  first run's output named neither the source path nor a doc-only detail, so it could not
  discriminate cited-source reading from summary reading). Rerun, graded strictly: (a)
  sandbox `.project/` produced by the one init script, harness-neutral by construction;
  (b) `dist/codex/AGENTS.md` and the installed `~/.codex/AGENTS.md` carry the
  context-loading INDEX-skim line; (c) live `codex exec` on the E1 prompt skimmed
  `.project/product/INDEX.md` during orientation, stopped before editing, **named
  `docs/report-contract.md` by path** as the conflicting contract, distinguished it from the
  ledger entry ("the product ledger records the same promise"), and asked before replacing
  the contract. Full transcript captured.

**Bets:** B1 confirmed (E1–E3, E5); B4 confirmed (E4). No wording revisions required; spec
SC8 evidence in hand.
