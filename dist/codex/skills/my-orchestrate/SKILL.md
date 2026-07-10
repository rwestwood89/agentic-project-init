---
name: my-orchestrate
description: Given a concept or outcomes document, drive it to implemented, reviewed work —
---

Generated from `claude-pack/commands/_my_orchestrate.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Orchestrate Command

**Purpose:** Given a concept or outcomes document, drive it to implemented, reviewed work —
autonomously, using your own judgment. You run the pipeline by delegating each stage to a headless
subagent, and you leave a commit trail the human reads afterward.
**Input:** A concept/outcomes doc (path) or inline outcomes.
**Output:** Pipeline artifacts and code in `.project/`, plus a commit per decision.

Run from a `fable` session. Claude-only. One checkpoint at launch (Align, in step 1); after that, you run to the end.

## What matters most

You're trusted for judgment, not just coordination. Everything below is in service of these two:

- **Hold the bar on engineering quality.** Good, clean, well-architected code and sound best
  practices — not "it runs." Push the subagents there, and don't accept work that falls short. This
  is the main reason a high-judgment model is doing this instead of a script.
- **Stay on intent.** Keep the objective and its broader context in view the whole way. Every stage
  should serve what the concept is actually trying to achieve — steer each subagent toward that
  intent, not just toward producing an artifact that checks a box.

## Your tools

Delegate every stage to a subagent with the helper (`Bash`). Full usage: `~/.claude/scripts/orchestrate-stage.sh --help`.

```
# start a stage; put the work item + the relevant intent from the concept on stdin
~/.claude/scripts/orchestrate-stage.sh run <stage> <<'ARGS'
...
ARGS
# continue that stage's session — answer its questions, or feed back a review
~/.claude/scripts/orchestrate-stage.sh resume <session_id> <<'MSG'
...
MSG
```

Each call returns JSON; read the `result` field — the stage's final message, in prose. It either
finished (ends with `ARTIFACT: <path>`) or is asking you something. Keep the `session_id` to resume.
`<stage>` is any `/_my_*` command name; read a command's own doc when you want to know what it does.

## Running the pipeline

1. **Orient, then Align.** Read the concept and decide where to start and whether it's one
   item or an epic. Then — the one checkpoint — send the owner a short Align message and wait
   for the reply (they just invoked the run, so they are present). Cover:
   - the meaning of the work as you read it ("do you literally want X, or are you solving for
     Y?"), so you don't optimize the wrong thing;
   - the **reserved gates** — the decisions the owner wants to make themselves, not have you
     decide and record;
   - any provenance gaps and cross-document conflicts you spotted while orienting;
   - any `[HARD]` requirement that smells like an inherited assumption, not a real
     constraint — challenge it.
   Record the **reserved gates**; the tier rule in "How to work" consumes them.
2. **Follow ``my-pipeline``** — the canonical pipeline: the stages, how they fit, where reviews sit,
   and the epic-vs-single-item branch. Run its stages through the helper. You're the orchestrator, so
   deviate when the work warrants.
3. **For each stage, the orchestration overlay:**
   - Start it with rich context — the work item plus the relevant intent from the concept — so it
     isn't guessing at what the concept already answers. Mark the provenance of any settled item
     you pass down (owner-grade vs your own inference), so the stage doesn't read your
     operationalization as owner intent (`claude-pack/rules/capture-fidelity.md`).
   - If it asks you something, answer from the concept and your judgment, then resume. What the
     concept can't settle, tell the stage to decide and record, so it lands in the artifact.
   - Where the pipeline pairs a stage with a review, run the review, feed the must-fix points back,
     and don't chase a reviewer past ~2 rounds.
   - Commit each stage and decision, subject leading with the decision — that trail is how the human
     audits the run.
4. **Finish** where the pipeline ends for your scope (leave `close` to the human unless asked).
   Summarize what you built and the key calls you made.

## How to work

- Keep your context light. Work through the subagents; their `result` is your main signal. Read an
  artifact or the code directly when you need the detail to make a call.
- Mid-run, sort each decision into one of three tiers:
  - **Execution detail** — decide it, record it loudly, keep going. Don't stop and wait.
  - **Reserved gate** — a decision the owner reserved at Align. Don't decide it yourself: park
    that branch, keep non-dependent work moving, and hard-halt only when everything remaining
    depends on the answer.
  - **Premise surprise** — genuine evidence against a premise the plan rests on. Invoke the
    surfacing duty (`claude-pack/rules/capture-fidelity.md`): surface it, park the dependent
    conclusions, and don't resolve it silently in either direction.

**Related:** pipeline reference ``my-pipeline``. Input from ``my-concept``, ``my-concept-design``,
``my-research``. Mechanism: `~/.claude/scripts/orchestrate-stage.sh`.

**Last Updated:** 2026-07-02

