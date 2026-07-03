# Design: Workflow Orchestrator

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Branch:** workflow-orchestrator
**Complexity:** HIGH

---

## Overview

A single command, run on a high-judgment model, that drives the existing v2 pipeline end to end
with no human in the loop — delegating each stage to a headless `claude -p` subagent and exercising
the judgment a human would normally supply at the gates.

## Related Artifacts

- **Spec:** [spec.md](spec.md)
- **Spike (settles the invocation mechanism):** [spike-findings.md](spike-findings.md) + `spike/`
- **Pipeline commands orchestrated:** `claude-pack/commands/_my_{research,concept_design,epic_plan,spec,spec_review,product_design,design,design_review,plan,implement,audit,pre_pr,close}.md`
- **Prior art (headless `claude -p`):** `claude-pack/scripts/ralph-init.sh`
- **Codex exclusion:** `codex-overrides/config.sh` (`EXCLUDED_COMMANDS`)

---

## Research Findings

- **The invocation mechanism is settled by the spike.** `claude -p "/_my_<stage> …"` runs a pipeline
  command headless and lands its artifact; `--output-format json` returns `session_id` + final
  `result` text + cost; `--resume <session_id>` re-enters a stage's own context to apply a review.
  All confirmed against real `_my_spec` / `_my_spec_review` runs. Gotchas (pipe prompt on stdin,
  keep stderr separate, tolerate a stdin-warning prefix, parse the `type:result` array element) are
  captured and handled in `spike/run.sh`.
- **Commands use the Task tool today, none shell out.** Every existing `_my_*` command spawns
  subagents via `subagent_type=Explore` (e.g. `_my_spec.md:30`, `_my_design.md:109`). No command
  runs `claude -p`. So a command backed by a helper script that spawns headless subagents is a new
  pattern here — but it mirrors `ralph-init.sh`'s existing `claude -p` usage (`claude_run()`, lines 86–97).
- **Script home:** `claude-pack/scripts/` (currently just `ralph-init.sh`). Symlinked globally by
  `scripts/setup-global.sh`.
- **Metadata helper** (`get-metadata.sh`) ships in `project-pack/scripts/` and lands at
  `.project/scripts/` in target projects; it may be absent, so fall back to git + `date`.
- **Codex layer:** `EXCLUDED_COMMANDS` in `codex-overrides/config.sh` is the one place to exclude a
  Claude-only command. No description override, no built skill.

---

## Core Concept

**The orchestrator is a judgment agent, not a workflow engine.** The spike proved that running a
pipeline stage is a mechanical, solved problem: the stage commands already work headless, and when
told plainly that no human is listening, they make their own calls and record them instead of
hanging. So the orchestrator does not need to be clever about *running* stages. Its entire reason to
exist is the part a script cannot do:

- decide **where to start** and whether the work is an **epic or a single item**,
- **answer the clarifying questions** a stage yields when it needs them — the stage decides *when*
  to ask, the orchestrator reacts by answering from the concept doc and its own judgment, then
  resuming the stage (see D7),
- judge when a **review loop has converged** well enough to move on — because a good reviewer never
  stops finding issues (the spike showed re-review returns "Revise" indefinitely),
- and **record every such call** so the human can audit the reasoning after the fact.

The design splits cleanly along that line. A thin **helper script owns mechanism** — assembling the
stage prompt, piping it on stdin, parsing the JSON result, tracking the session id, guarding spend.
The **command prompt owns judgment** — sequencing, question-answering, convergence, commit
discipline. The orchestrator keeps its own context lean by treating each stage's JSON result (a
summary line, a session id, an artifact path) as the record of that stage, reading a full artifact
only when a decision actually needs the detail.

This is the right approach because it puts the model exactly where judgment is required and nowhere
else, and it encodes the fiddly, already-solved mechanics once in a script instead of asking the
model to re-derive them on every call.

## Key Bets

- **B1. A high-judgment model can make the gate calls (scope, entry point, review-convergence) about
  as well as a human would.** *If false → the orchestrator produces plausible but misjudged work —
  wrong scope, premature "good enough" — and autonomous mode isn't trustworthy; you're back to
  supervising.* This is the bet the whole command exists to test.
- **B2. The orchestrator can answer a stage's yielded questions well enough to stand in for the
  human.** *If false → the shaping questions get wrong answers, the artifact is built on them, and
  downstream stages compound the error.* A stage yields questions and stops before writing (D7), so
  the answers land before the artifact takes shape; whether they're *good* answers is the open part,
  and it depends on the concept doc being rich enough to answer from (see Risks). Probed early (Handoff).
- **B3. A stage's JSON summary + artifact path is enough to decide the next move without loading the
  full artifact.** *If false → the orchestrator must read every artifact, its context bloats, and the
  context-efficiency goal fails.* Spike supports this.
- **B4. Review loops reach acceptable quality within a small iteration budget (2–3 rounds).** *If
  false → the orchestrator either stops too early (ships weak work) or burns unbounded cost chasing a
  reviewer that never says Approve.* The spike proved reviews don't self-terminate, so this budget is
  load-bearing.

## Key Decisions

- **D1. Orchestrate via headless `claude -p` subprocesses, not the in-harness Task/Agent tool.**
  *Rejected: Task subagents — they can't be resumed with `--resume` session semantics for the
  review-feedback loop, per-call model control and slash-command invocation are awkward, and the
  spike proved `claude -p` end to end.*
- **D2. Split into a thin mechanism helper script + a judgment-focused command prompt.**
  *Rejected: pure-prompt orchestration — the model would re-derive the stdin/stderr/JSON gotchas on
  every call, inconsistently. Also rejected: a fat script that owns the flow — it would hard-code the
  judgment we specifically want the model to exercise.*
- **D3. Convergence policy = bounded iteration.** Default 2 review rounds per stage; the orchestrator
  classifies reviewer findings as must-fix vs. optional, loops only on must-fix, and when it stops
  with findings outstanding it records a "proceeding over these findings, because …" decision.
  *Rejected: loop-until-Approve — the spike showed it never terminates.*
- **D4. The judgment trail is git.** One commit per completed stage or material decision; the commit
  subject leads with the decision/assumption. *Rejected: a separate running-log file as the primary
  record — it duplicates git and adds state to maintain.* (A short `orchestration-log.md` may be
  added as a convenience, but git is the source of truth.)
- **D5. Permission posture is staged.** Artifact stages (spec, design, plan, reviews, audit) run
  `--permission-mode acceptEdits`. The implement and pre_pr stages, which must run project commands
  (tests, lint, `gh`), run `--permission-mode bypassPermissions` inside the already-trusted project
  dir. Every call carries a `--max-budget-usd` guard. *Rejected: `--dangerously-skip-permissions`
  everywhere — needless blast radius for doc-only stages.*
- **D6. Models: orchestrator = fable, stage subagents = opus, both overridable.** *Rejected: one
  model for both — wastes opus on mechanical orchestration and/or under-powers the stages.* Note:
  the host model is a **usage convention** (invoke the command from a fable session); a command
  can't set its own host model. The helper sets stage models via `--model`.
- **D7. Stages decide when to ask; the orchestrator reacts with one uniform loop.** Every stage is
  invoked identically, with the same non-interactive preamble: *you can't wait for a human — if you
  need to ask the user something, make your questions your entire final message and stop; you'll be
  resumed with answers; when the work is done, end with the artifact path.* The orchestrator then
  runs one loop, the same for every stage: invoke → read what came back → if it's questions, answer
  from the concept and resume the session → if it's the finished artifact, advance. The command owns
  the decision *whether* to ask; the orchestrator owns the answers. *Rejected: the orchestrator
  choosing "question mode" vs "produce mode" per stage — that forces it to model each command's
  internals (which stages interrogate, which don't), which is brittle and misplaces the knowledge;
  when to ask belongs in the command.* Same reactive shape as the review loop (D3). A question the
  orchestrator can't answer from the concept, it answers with "no strong signal — use judgment and
  record it," so it lands in the artifact's Open Questions for the human.
- **D8. The subagent↔orchestrator channel is the `result` field, read as prose.** With
  `--output-format json` captured to a file, the stage's tool calls and edits never reach the
  orchestrator — only its final message (`result`) does. The orchestrator reads that message as
  prose and interprets it (questions? done? stuck?); it does not parse it mechanically. *Rejected: a
  `**FOR USER**`-style sentinel wrapper — that only pays off when a script with no judgment must
  route on the content, but here the reader is the model, which reads prose fine.* The one sentinel
  kept is `ARTIFACT: <path>`, because that path becomes an argument to the next stage call — a
  precise string a non-LLM consumer lifts. Questions and verdicts stay prose.

## Architecture

**Invocation.** `/_my_orchestrate <path-to-concept-or-outcomes-doc | inline outcomes>`, run in the
target project from a fable session. The orchestrator does the one full read it needs — the input
doc — plus light project orientation (`CLAUDE.md`, `.project/CURRENT_WORK.md`).

**The orchestration loop** (the command prompt drives this; judgment at every step):

1. **Orient & route.** From the input, decide entry point (research? concept-design? straight to
   spec?) and epic-vs-single-item. Record the routing decision (commit).
2. **Epic branch (if chosen).** Run `epic_plan` via a stage call; from its result, take the item
   list; then iterate items **sequentially**, each through the per-item pipeline below.
3. **Per-item pipeline.** For each stage in `spec → [product_design?] → design → plan → implement →
   audit → pre_pr`, run the **uniform loop** (D7):
   - Call the helper: `orchestrate-stage.sh <stage> <args>` → returns `{session_id, result, cost}`.
     The helper does not interpret `result`; the orchestrator reads it (D8).
   - **If the stage yielded questions**, answer them from the concept intent and **resume the
     session** (`--resume`) to continue. Repeat until the stage returns a finished artifact.
   - **If the stage has a reviewer** (spec→spec_review, design→design_review): run the reviewer as a
     stage call, read its verdict + findings from `result`, classify must-fix vs. optional. On
     must-fix, resume the stage's session with the findings and loop — up to the budget (D3). Record
     the convergence outcome (commit).
   - Advance. Between stages the orchestrator decides from `result` alone; it opens an artifact only
     when a real decision needs the detail (B3).
4. **Finish.** Stop at the scope boundary (through `pre_pr`, or `close` if directed), then write a
   final summary of what was built, the key decisions made, and any findings it proceeded over.

**The helper** `orchestrate-stage.sh` wraps exactly one headless call (the spike's `run.sh`,
generalized): it injects the uniform non-interactive preamble, appends `/_my_<stage>` + args, pipes
on stdin, writes the JSON to a per-run log dir, and returns the `result` text + `session_id` + cost.
It does **not** interpret the result — routing is the orchestrator's judgment (D8). It supports
`--resume <sid>` (to answer questions or feed a review back), `--model`, and `--budget`.

**The preamble** (`orchestrate-preamble.md`, injected by the helper) is **uniform across every
stage**. It says: you are non-interactive and cannot wait for a human; whenever your process would
ask the user something, make your questions your entire final message and stop — you'll be resumed
with answers; when the work is done, end with `ARTIFACT: <path>`. The stage's own logic decides
whether it asks; the preamble only redirects "ask the user" into "yield and stop."

Data flow: **orchestrator ⇄ helper (the `result` text + session ids) ⇄ stage subagents ⇄
`.project/` artifacts.** The orchestrator's context holds result messages and its own decisions —
not artifact bodies, and not tool-call noise.

## Required Invariants

- Every stage call includes the uniform non-interactive preamble. (Without it a stage may hang waiting for input, or ask into the void.)
- The orchestrator never blocks on user input during a run.
- Every material judgment call appears in a commit subject. (The audit trail is the product.)
- The orchestrator loads a full artifact only when a decision requires it.
- Prompts are piped on stdin; stderr is kept separate from the JSON stdout; each call has a spend guard and a wall-clock timeout.
- Stage commands are invoked unmodified — the preamble rides in via arguments, so the commands stay usable by hand.

## Component Overview

- **`claude-pack/commands/_my_orchestrate.md`** — the judgment agent prompt. Owns orientation,
  routing, stage sequencing, reacting to stage output (answering yielded questions, judging review
  convergence), the convergence policy, commit discipline, and the final summary. This is the bulk
  of the work.
- **`claude-pack/scripts/orchestrate-stage.sh`** — mechanism wrapper for one headless stage call
  (+ resume). Owns prompt assembly (injecting the uniform preamble), stdin/stderr handling, JSON
  capture, returning `result` + `session_id` + cost, the spend guard, and the timeout. Does **not**
  interpret the result. Derived directly from `spike/run.sh`.
- **`claude-pack/scripts/orchestrate-preamble.md`** — the single uniform non-interactive preamble
  injected into every stage prompt. Editable without touching script logic.
- **`codex-overrides/config.sh`** — add `_my_orchestrate` to `EXCLUDED_COMMANDS`.
- **Reused unchanged:** all `_my_*` stage commands, git, the target project's `.project/`.

## Non-Goals

- Not building notify-and-wait feedback (spec Future Work).
- Not parallelizing epic items — sequential first; parallelism is a later optimization.
- Not modifying the stage commands to be "orchestrator-aware." They stay usable manually; the
  orchestrator adapts to them, not the reverse.
- Not authoring the initial concept.
- Not a general agent framework — it orchestrates this specific pipeline.

## Implementation Notes

- **One sentinel, and it's a path (D8).** The preamble asks stages to end with `ARTIFACT: <path>`,
  because that path is a machine string the next stage call needs as an argument. Questions and
  review verdicts come back as prose in `result`; the orchestrator reads them — no wrapper, no regex.
- **No tool-call noise reaches the orchestrator.** `--output-format json` captured to a file means
  the orchestrator only ever reads the `result` field; edits and tool calls stay in the log, unread.
- **Resume + args.** When resuming with the prompt as an argument, redirect stdin (`< /dev/null`) or
  pipe it; otherwise `claude -p` waits and emits a warning that corrupts JSON capture (spike finding).
- **JSON shape.** `--output-format json` returns an array; parse the `type:result` element; tolerate
  a leading stdin-warning line.
- **Metadata.** `get-metadata.sh` may be absent in a target project; fall back to git + `date`.
- **Host model.** Fable-as-orchestrator is documented usage, not enforced by the command.
- **Global install.** New command + scripts require `scripts/setup-global.sh` to symlink into
  `~/.claude/` before they're usable in other sessions.

## Potential Risks

- **Autonomous judgment quality (B1/B2) — the central risk.** Mitigation: the command is opt-in and
  produces a git trail + artifacts for after-the-fact review; intended first use is side projects (per
  the user). The convergence budget bounds the failure cost.
- **Runaway cost/time.** Mitigation: `--max-budget-usd` per call, plus an overall budget and
  iteration cap the orchestrator tracks and stops on.
- **A stage hangs despite the preamble.** Mitigation: wall-clock `timeout` on every `claude -p` call
  in the helper; a timed-out stage is a recorded failure, not a hang.
- **Implement-stage blast radius.** `bypassPermissions` runs project commands unattended. Mitigation:
  bounded to the trusted project dir; spend guard; recommend running the whole orchestration in a git
  worktree so a bad run is trivially discarded.
- **Prompt injection across subagents.** The orchestrator feeds subagent output into other subagents.
  Low risk here (all actors are our own commands), but the trust boundary is noted.

## Integration Strategy

An additional autonomous path *alongside* the manual pipeline, not a replacement. It reuses every
stage command unchanged and writes the same `.project/active/{item}/` artifacts, so a human can pick
up, inspect, or take over at any point using the normal commands. Claude-only; excluded from Codex.

## Validation Approach

- **Helper in isolation:** `orchestrate-stage.sh` is `spike/run.sh` generalized — verify a stage call
  returns `result` + `session_id` + cost, and a `--resume` call re-enters context (both demonstrated
  in the spike).
- **End-to-end dogfood:** run the orchestrator on a small **LOW-complexity single item** first
  (spec→…→pre_pr), then a small **epic**. Inspect the git trail and artifacts for judgment quality —
  this is how B1/B2 actually get tested.
- **Success = ** the run completes unattended, artifacts are coherent, and the git log reconstructs
  the reasoning.

## Next-Stage Handoff

- **Fixed:** the `claude -p` primitive; the helper-script + judgment-prompt split; the uniform
  yield-and-react protocol (D7) with the prose `result` channel and single `ARTIFACT:` path sentinel
  (D8); the bounded-iteration convergence policy; git-as-trail; Claude-only / Codex-excluded.
- **Open (tune during dogfood):** default iteration budget and spend caps; the exact preamble
  wording; whether to also emit an `orchestration-log.md`.
- **De-risk first, in the plan** — a second, smaller spike before the command prompt is finalized,
  covering the two legs the first spike didn't:
  1. **The yield-and-react loop (D7/D8).** Confirm a stage told "if you need user input, make your
     questions your entire final message and stop" actually stops (yields questions as prose in
     `result`, writes nothing), and that after the orchestrator answers and resumes, the stage
     produces a good artifact. Early evidence exists — a probe already showed a stage stopping and
     returning its questions as prose — but the resume-to-produce leg is unproven. B2 rests on this.
  2. **The implement stage headless.** Implement is materially different from the document stages —
     it runs code and tests, and its command has "confirm scope / stop on deviation" gates written
     for a human. Prove those deviation-stops become recorded decisions, not hangs.

---

**Next Step:** After approval → `/_my_plan` (this is HIGH complexity with a real sequencing risk —
the implement-stage spike must come before the command prompt is finalized).
