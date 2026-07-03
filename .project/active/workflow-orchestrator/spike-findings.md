# Spike: Orchestrating the pipeline via headless subagents

**Status:** Complete
**Owner:** Reid W
**Started / finished:** 2026-07-02
**Branch:** workflow-orchestrator

---

## Summary of findings

**The mechanism works. Build the orchestrator.** An autonomous agent can drive the v2 pipeline
through headless `claude -p` subagents, and every risky assumption in the spec held up.

What's proven:

1. **`_my_*` commands run headless.** `claude -p "/_my_spec ..."` loads the command, runs it end
   to end, and writes its artifact. All pipeline commands appear in the headless `slash_commands`
   list. (Tested: `_my_spec`, `_my_spec_review`.)
2. **Non-interactive stages behave.** Told plainly that no human is listening, the stage agents
   stop asking questions and instead make judgment calls and record them (`[INFERRED]` tags, Open
   Questions entries). No hangs, no waiting into the void.
3. **The review loop closes.** The orchestrator runs the stage agent, runs the reviewer, and hands
   the review back to the *same* stage agent via `--resume`. The resumed agent applied the
   reviewer's findings coherently and correctly.
4. **The context-efficiency bet holds.** With `--output-format json` the orchestrator gets each
   stage's `session_id`, final `result` text, and cost from stdout. It chains stages on those
   summaries and passes file *paths* between subagents — it never has to load a spec or review into
   its own context. The subagents do the file reading.

The one thing that is **not** a mechanism problem but a **judgment** problem — and it's the crux of
the whole command:

- **A review loop does not naturally converge to "Approve."** Re-reviewing the revised spec with a
  fresh aggressive reviewer produced *another* "Revise" — it acknowledged the prior fixes held, then
  found new, lower-stakes issues. A good skeptical reviewer can almost always find something. So
  "loop until Approve" would spin forever. The orchestrator needs a **convergence policy**: an
  iteration budget, a must-fix vs. nice-to-have judgment, and the spine to stop and record a
  decision. This is exactly the "high-level engineering and product judgment" the command is for.

Practical gotchas found (all handled in `spike/run.sh`):

- **Pipe the prompt on stdin.** Passing the prompt as an argument makes `claude -p` wait ~3s for
  stdin and print a `Warning: no stdin data received` line that corrupts a JSON capture. Piping
  (`< prompt.txt`) avoids it; `< /dev/null` works when the prompt must be an argument (e.g. `--resume`).
- **Keep stderr separate** from the JSON stdout (don't `2>&1` into the log).
- **Stale sibling artifacts confuse a fresh reviewer.** The second reviewer noticed the on-disk
  `spec-review.md` was reviewing an older spec version. The orchestrator must manage artifact
  freshness (version or clear them between rounds, or pass the reviewer the exact target).
- **Resume is cheaper than fresh** for iteration: the resumed spec agent reused ~322k cached tokens
  and cost $0.27 vs. a fresh reviser's $0.31 — and it keeps the original reasoning in context.

Cost/time reference: the full spec → review → revise → re-review cycle was **~$2.23 and ~11 min** on
**sonnet**. Production would run stage subagents on **opus** (higher judgment, higher cost); the
orchestrator itself on **fable**. Mechanism is model-agnostic; only judgment quality scales with model.

**Recommendation for design:** the orchestrator's hard part is not plumbing, it's the policy layer —
convergence/stopping rules, artifact-state hygiene, and how it records the judgment calls it makes on
the user's behalf (commit messages that lead with the decision are a good start). Design should focus
there. The invocation primitives are settled; see "Recommended primitives" below.

---

## Objective

Prove (or disprove) the invocation mechanism behind the [workflow-orchestrator spec](spec.md)
before designing the real command. Risky assumptions: (1) a `_my_*` command runs headless and lands
its artifact; (2) a normally-interactive stage can be told to run non-interactively and self-decide;
(3) a stage session can be resumed to feed a review back; (4) the orchestrator can chain off JSON
results without re-reading files.

## Method

An unattended orchestrator was simulated by driving `claude -p` calls by hand and recording each. A
faux work item ran through **spec → spec-review → revise → re-review**, trying two feedback-loop
approaches (resume vs. fresh). Everything ran in a throwaway sandbox project so the real `.project/`
stayed clean. Model: **sonnet** (mechanism is model-agnostic; kept cheap/fast).

**Faux work item:** a small `wordfreq` CLI — read a text file, print the top-N most frequent words,
ignore stopwords. Concrete enough for a real spec and review (case sensitivity, punctuation,
stopword source, tie-breaking); self-contained; no host codebase.

## Reproducing

```bash
.project/active/workflow-orchestrator/spike/run.sh   # optional: pass a sandbox dir
```

Assets under `spike/`:
- `run.sh` — the runner; each stage is a labeled step, with the stdin/stderr handling baked in.
- `prompts/` — exact prompt text handed to each subagent (`spec`, `spec-review`, `revise-resume`, `revise-fresh`).
- `logs/` — captured JSON result per call (session ids, cost, result text) + stderr.
- `sandbox-snapshot/` — the artifacts the subagents produced: `spec.v1-original.md`,
  `spec-review.md`, `spec.v2-after-resume.md`, `spec.v2-after-fresh.md`.

---

## Environment facts (confirmed)

- `claude` 2.1.198; `claude -p` runs nested (Claude invoking Claude) with no special setup.
- `--output-format json` returns an array of stream events; the final `type:result` object carries
  `session_id`, `result` (final assistant text), `total_cost_usd`, `num_turns`, `duration_ms`, `is_error`.
- The `init` event lists `slash_commands` — all `_my_*` commands resolve headless.
- Default `permissionMode` here is `auto`; the runs used `--permission-mode acceptEdits` so file
  writes land without prompts. (Production orchestrator will need a deliberate permission posture —
  see open items.)

---

## Run log

| # | Stage | Approach | Result | Cost | Time |
|---|-------|----------|--------|------|------|
| 1 | `/_my_spec` | fresh, headless | wrote `spec.md`; recorded assumptions as `[INFERRED]`/Open Questions; ended with `ARTIFACT:` line | $0.39 | 94s |
| 2 | `/_my_spec_review` | fresh, headless | wrote `spec-review.md`; **VERDICT: Revise**; caught mechanism smuggled into `[INFERRED]` + a Non-Goal collision | $0.62 | 222s |
| 3 | revise | **`--resume` spec session** | applied review coherently (narrowed `[INFERRED]` to outcomes, added Non-Goal, fixed provenance); reused ~322k cached tokens | $0.27 | 71s |
| 4 | revise | fresh, stateless (files only) | converged on the *same* substantive fixes as #3 | $0.31 | 60s |
| 5 | `/_my_spec_review` (re-review) | fresh, headless | prior fixes held, but **VERDICT: Revise** again on new lower-stakes issues; noticed stale on-disk review | $0.64 | 227s |
| | | | **TOTAL** | **$2.23** | ~11 min |

Observations per step are captured in the summary above. The revised spec differed from the original
by ~39 changed lines — a real, substantive revision, not cosmetic.

---

## What this means for the design

**Recommended primitives (settled — design can assume these):**

- Invoke a stage: `claude -p --model <m> --output-format json --permission-mode acceptEdits < prompt.txt`.
  Prompt = the `/_my_<stage>` slash command plus an **orchestration-context** preamble that says
  "you are a non-interactive subagent; do not ask; decide and record; end with `ARTIFACT:`/`VERDICT:` lines."
- Capture `session_id` + `result` from the JSON. Chain the next stage off the `result` summary and
  the artifact path; do not read the artifacts into the orchestrator's context.
- Iterate a stage by **resuming its session** (`--resume <session_id>`) and handing it the review
  file path. Cheaper and more coherent than a fresh reviser.

**Where the design work actually is (the judgment/policy layer):**

- **Convergence policy.** Reviews won't self-terminate at Approve. Need an iteration cap, a
  must-fix vs. optional distinction, and a rule for when the orchestrator overrides the reviewer and
  moves on — recording why.
- **Artifact-state hygiene.** Stale review files mislead fresh reviewers. Decide how rounds are
  versioned or cleared, and what each subagent is pointed at.
- **Judgment trail.** The orchestrator makes calls the human would otherwise make. Commit-per-unit
  with the decision in the message subject (per the spec) is the baseline; design may want more.
- **Permission/safety posture** for a fully autonomous multi-stage run (`acceptEdits` vs.
  `bypassPermissions`/`--dangerously-skip-permissions`), and a spend guard (`--max-budget-usd` exists).
- **Prompt-injection surface.** The orchestrator feeds subagent output back into other subagents;
  worth a note on trust boundaries even though all actors are our own commands here.

**Not yet probed (safe to leave for design/build):** the full chain past design (`plan` → `implement`
→ `audit`), epic decomposition with multiple parallel items, and running stage subagents on opus/fable
rather than sonnet. None of these change the invocation primitive; they add orchestration policy.

---

# Spike 2 — the yield-and-react protocol (D7/D8) and implement headless

Ran during Phase 1 of `plan.md`, after the design adopted the **uniform preamble** (the *stage*
decides when to ask; the orchestrator reacts). Goal: close the two legs Spike 1 didn't cover.
Assets: `spike/prompts/uniform-preamble.txt`, `spike/logs/p1*.json`, `spike/sandbox-snapshot/p1*`.

## Verdict: GO. Both legs hold.

**The uniform preamble faithfully preserves each command's own asking threshold.** One preamble —
"if you'd ask the user, make your questions your entire final message and stop; else finish with
`ARTIFACT:`" — produced all three behaviors correctly, with the *stage* choosing:

| Probe | Input | Stage behavior | Hang? |
|---|---|---|---|
| A | `spec`, well-specified `wordfreq` | **Proceeded** — resolved ambiguity by convention, parked the one real unknown in Open Questions, wrote the spec | no |
| A′ | `spec`, un-defaultable discount-code feature | **Yielded** — stopped, wrote nothing, returned 4 scope questions as prose ("stopping per the orchestration rule rather than guessing") | no |
| A′ resume | answers supplied, session resumed | **Produced** — wrote a spec faithfully reflecting the answers, with sensible `[INFERRED]` additions | no |
| B | `implement`, 1-phase plan | **Proceeded** — wrote real code + tests, ran them (3 pass), fail-loudly verified | no |
| B2 | `implement`, 2-phase plan | **Yielded** — returned the "one-by-one vs both" scope question as prose, *and* caught a docs/code discrepancy instead of guessing | no |
| B2 resume | "both phases" answer supplied | **Implemented** — both phases, 5 tests pass | no |

## What this proves

- **D7 works and the knowledge stays in the command.** The orchestrator never picks a mode; the
  stage decides whether to ask. A clear item proceeds; an ambiguous one yields. Same preamble, both.
- **D8 works.** Questions and scope prompts come back as prose in the `result` field. No sentinel
  wrapper needed; the reader is the model. The only sentinel used was `ARTIFACT: <path>`.
- **The yield→resume→produce loop is real end to end** (A′), and so is yield→resume→implement (B2).
  Resume reuses the session (same id) so the stage continues with its own context intact.
- **Implement is safe headless.** It runs code and tests under `bypassPermissions` (D5), produces
  genuine working code (independently re-ran: tests pass, CLI output correct, missing-file exits 1),
  and its "confirm scope / stop on deviation" gates become **prose yields, never hangs.** It even
  surfaced a real discrepancy (leftover `.pyc` with missing sources) as a question rather than
  guessing — exactly the behavior we want.

## Nuance worth carrying into the command prompt

- A well-specified item makes shaping stages **proceed without yielding** — they lean on convention
  and defer. That's correct, but it means the orchestrator only gets to inject concept intent when
  the stage judges a question high-leverage. If we want more of the concept's intent forced in, that
  lives in *how richly the orchestrator front-loads context into the stage args*, not in the preamble.
- No "when in doubt, yield" bias was needed — the commands' own thresholds behaved sensibly. Don't
  add one without evidence.

## Cost

Phase-1 total **$2.19 on sonnet** across 6 headless calls. Production (opus stages) will cost more;
the mechanism is unchanged.
