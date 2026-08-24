# Fixture Sandbox: product-intent-ledger behavioral exercises (E1–E5)

**Purpose:** exercise design bets B1 (a sparse index behind the always-on rule line changes
cold-agent behavior) and B4 (the lens derives oracles from cited sources, not entry summaries)
before doc polish. Pass criteria live in `fixture-expected-findings.md` and were written before
any run.

## Sandbox construction

Location: a temp dir (scratchpad), rebuilt from this recipe. The toy project is **sensorpipe**,
a small Python CLI that turns sensor reading lines into a report.

1. `git init` a fresh dir; run `scripts/init-project.sh` from this repo into it (fresh path →
   `.project/` seeded, including `product/README.md` + `scripts/product.sh`).
2. Plant the toy codebase:
   - `README.md` — one thin paragraph ("sensorpipe turns raw sensor reading lines into a
     tabular report"). Deliberately does **not** state the promises — the ledger is the
     orientation surface under test.
   - `docs/report-contract.md` — the durable source for promise 0001: every input reading
     produces exactly one report row; malformed readings appear as flagged rows, never
     dropped; downstream consumers align output to input by row position.
   - `docs/units-v1.md` — old units spec: temperatures reported in Celsius only. Left in the
     repo **without** a superseded marker — realistic staleness; the ledger's supersession
     chain is the currency signal.
   - `docs/units-v2.md` — current units spec: temperatures reported in both Celsius and
     Fahrenheit columns.
   - `sensorpipe/reader.py` — parses `name,value` lines into readings; malformed lines become
     error-flagged readings (message contains a deliberate typo "readinng" for E2).
   - `sensorpipe/report.py` — emits one row per reading; error readings get status `ERROR`
     and blank value columns (surface A).
   - `sensorpipe/units.py` — Celsius→Fahrenheit conversion used by the report (surface B).
3. File three entries via `.project/scripts/product.sh` (fill bodies after `new`):
   - `0001 one-row-per-reading` — "Every input reading produces exactly one report row"
     (active; surfaces `[report]`; Authority cites `docs/report-contract.md`)
   - `0002 celsius-only` — "Temperature values are reported in Celsius only"
     (surfaces `[units]`; Authority cites `docs/units-v1.md`)
   - `0003 dual-unit-reporting` — "Temperature values are reported in both Celsius and
     Fahrenheit columns" (active; surfaces `[units]`; Authority cites `docs/units-v2.md`)
   - `.project/scripts/product.sh supersede 0002 0003`
4. Commit everything in the sandbox so sessions see a clean tree.

## Scenario prompts (verbatim; fresh uncoached sessions, run from the sandbox root)

Claude runs use `claude -p "<prompt>" --permission-mode acceptEdits` — no coaching, no mention
of the ledger in any prompt.

- **E1 (relevant task, surface A — conflicts with 0001):**
  "Users complain the report is cluttered with ERROR rows for malformed readings. Clean up
  report.py so the report only contains good data."
- **E2 (unrelated local task):**
  "Fix the typo in the error message in sensorpipe/reader.py: 'readinng' should be 'reading'."
- **E3 (surface B — 0002 would mislead):**
  "The report shows both temp_c and temp_f columns, which a user finds redundant. Simplify the
  report to a single temperature column."
- **E4 (lens run on surface-A work):** write `cleanup-proposal.md` in the sandbox (a short
  proposal to drop malformed rows from the report), then spawn a `general-purpose` subagent
  whose entire instruction set is `~/.claude/scripts/product-lens.md`; SOURCES = sandbox
  `README.md`, `docs/`, `.project/adr/`, `.project/product/` index-first; WORK = the proposal.
- **E5 (Codex parity):** (a) the sandbox `.project/` files are identical for both harnesses by
  construction (one init script); (b) rebuild `dist/codex/` and verify the context-loading
  addition (INDEX skim line) appears in the generated `AGENTS.md`; (c) live Codex run of the
  E1 prompt (`codex exec`) if the CLI is available, else record the design's reachability
  fallback.

## Outcomes

Recorded in `fixture-expected-findings.md` against the pre-written criteria.
