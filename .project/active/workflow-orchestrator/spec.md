# Spec: Workflow Orchestrator

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Complexity:** HIGH
**Branch:** workflow-v2

---

## Problem

The v2 workflow is a strong pipeline, but every stage is hand-driven. The human invokes each command, answers each approval gate, carries context from one stage to the next, and babysits the spec/design review loops. For work that is already well-defined — especially side projects — that supervision is the expensive part, not the thinking.

We want to test a different mode: hand a concept (or clear-outcomes) document to a high-judgment agent and let it *orchestrate* the whole pipeline on its own. The agent uses engineering and product judgment to decide how to proceed — run concept-design, decide epic-vs-single-item, drive spec → design → plan → implement with reviews — and delegates the execution of each stage to subagents. The human reviews the artifacts and commits afterward, not each step in real time.

The open risk is the invocation mechanism. It is not yet proven that an orchestrator can drive the existing `/_my_*` commands through headless subagents, resume a subagent to feed a review back, and have artifacts land correctly. So this work starts with a de-risking spike before the full command is built.

## Success Criteria

- [ ] A single command hands a concept/outcomes document to an orchestrator that drives the pipeline end to end **without requiring user interaction during the run**.
- [ ] The orchestrator exercises real judgment: it decides epic-vs-single-item, manages decomposition when it's an epic, and picks the right entry point from what it's given.
- [ ] It runs the review loops itself to convergence — invoke the stage agent, invoke the reviewer, hand the review back to the stage agent with specific changes, repeat until the reviewer approves.
- [ ] It invokes the existing pipeline commands rather than reimplementing them: `research`, `concept_design`, `epic_plan`, `spec`, `spec_review`, `product_design`, `design`, `design_review`, `plan`, `implement`, `audit`, `pre_pr`, `close`.
- [ ] Context stays lean: the orchestrator works primarily from artifacts and subagent conversations, reading full files only when it needs to.
- [ ] Progress is durable and inspectable: the orchestrator commits frequently, and each commit message **leads with the key decision(s) or assumption(s)** made in that unit of work.
- [ ] Fable orchestrates; opus subagents execute the stages.
- [ ] The invocation mechanism is proven by a spike before the full command is built.

## Known Requirements

- **[HARD]** Claude-only. The orchestrator depends on `claude -p` headless subagents and/or the Claude subagent (`Task`) tool, which have no Codex equivalent. It is excluded from the Codex build (`EXCLUDED_COMMANDS` in `codex-overrides/config.sh`); no ported skill and no description override.
- **[HARD]** Subagents run non-interactively and cannot prompt the user. Any clarifying question a stage command would normally ask the human is answered by the orchestrator instead.
- **[NEED]** Default posture is fully autonomous — no user checkpoints during a run. The human's review happens after the fact, on the artifacts and commits. (The autonomous run is the point; the command is meant to be handed off, not watched.)
- **[NEED]** The orchestrator focuses on high-level engineering and product judgment. It decides *how* to run the process; it delegates the *doing* of each stage to subagents.
- **[NEED]** Review loops run to convergence — the orchestrator keeps feeding reviewer findings back to the stage agent until the review verdict is Approve (or it makes and records a documented call when a loop stalls).
- **[NEED]** Context efficiency is a first-class outcome: the orchestrator's primary data is artifacts and subagent output, not re-reading the whole repo. It reads files only when a decision needs it.
- **[NEED]** Commit frequently. Each commit message starts with the key decision/assumption behind that unit of work, so the human can reconstruct the agent's reasoning from `git log` alone.
- **[NEED]** Models are Fable (orchestrator) and opus (stage subagents) by default, configurable via invocation flags.
- **[INFERRED]** The entry point is flexible. The orchestrator is given the general process and figures out where to start from what it receives — typically a concept/outcomes document, beginning at concept-design and/or research. It does not assume a fixed first command.
- **[INFERRED]** A new skill (or guide) instructs the orchestrator on operating the workflow while keeping context clean: how to invoke a stage agent, invoke the matching reviewer, hand the review back to the original agent with targeted changes, and iterate.

## Non-Goals

- **Not** building the notify-and-wait feedback mode now (see Future Work). This run is unattended by design.
- **Not** authoring the initial concept. That stays human-driven, matching how `/_my_concept` is framed.
- **Not** porting to Codex.
- **Not** replacing the manual pipeline. This is an additional autonomous path alongside the hand-driven commands.

## Open Questions / Deferred to design

- **The invocation mechanism — this is what the spike resolves.** Can `claude -p "/_my_design ..."` run a pipeline command headless and land its artifact? Can the same subagent session be resumed (`--session-id` / `--resume` / `--fork-session`) to feed a review back and iterate? Is the right primitive a headless subprocess (`claude -p`), the in-harness `Task` subagent tool, or a mix? What permission mode do subagents run in (`--dangerously-skip-permissions`?) and what are the safety implications?
- How the orchestrator keeps its own context ledger across stages — what it records about each stage so it can decide the next without re-reading everything.
- How review-loop convergence and stall detection are decided — iteration budget, and when to stop iterating and make a documented judgment call.
- Commit granularity — what counts as a "unit of work" worth a commit.
- For epics, how multi-item orchestration sequences vs. parallelizes across backlog items.
- Where the orchestrator surfaces its judgment trail (beyond commit messages) for after-the-fact review.

## Future Work

- **Opt-in feedback checkpoints.** A flag at invocation that lets the orchestrator push a notification and wait for human feedback at a decision point, then resume. Deferred deliberately — we want to see how well pure autonomy works before adding a supervision path.

---

## Related Artifacts

- **Pipeline commands orchestrated:** `claude-pack/commands/_my_{research,concept_design,epic_plan,spec,spec_review,product_design,design,design_review,plan,implement,audit,pre_pr,close}.md`
- **Codex exclusion config:** `codex-overrides/config.sh`
- **Headless-invocation prior art:** `claude-pack/scripts/ralph-init.sh` (existing `claude -p` usage)
- **Design:** `.project/active/workflow-orchestrator/design.md` (to be created)

---

**Next Steps:** Do **not** proceed straight to `/_my_design` for the full command. Start with a **de-risking spike** that proves the invocation mechanism (headless command invocation, subagent session resume for review feedback, artifact landing). Once the spike settles the mechanism, run `/_my_design` for the orchestrator using what the spike learned. Consider `/_my_spec_review` on this spec first.
