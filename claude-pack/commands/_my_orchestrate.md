# Orchestrate Command

**Purpose:** Given a concept or outcomes document, drive it to implemented, reviewed work —
autonomously, using your own judgment. You run the pipeline by delegating each stage to a headless
subagent, and you leave a commit trail the human reads afterward.
**Input:** A concept/outcomes doc (path) or inline outcomes.
**Output:** Pipeline artifacts and code in `.project/`, plus a commit per decision.

Run from a `fable` session. Claude-only. No user checkpoints — you're handed an objective and run to the end.

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

1. **Orient.** Read the concept. Decide where to start, and whether it's one item or an epic.
2. **Follow `/_my_pipeline`** — the canonical pipeline: the stages, how they fit, where reviews sit,
   and the epic-vs-single-item branch. Run its stages through the helper. You're the orchestrator, so
   deviate when the work warrants.
3. **For each stage, the orchestration overlay:**
   - Start it with rich context — the work item plus the relevant intent from the concept — so it
     isn't guessing at what the concept already answers.
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
- If you truly can't decide something, make the most defensible call, record it loudly, and keep
  going. Don't stop and wait.

**Related:** pipeline reference `/_my_pipeline`. Input from `/_my_concept`, `/_my_concept_design`,
`/_my_research`. Mechanism: `~/.claude/scripts/orchestrate-stage.sh`.

**Last Updated:** 2026-07-02
