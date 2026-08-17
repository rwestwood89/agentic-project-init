---
name: my-mental-model
description: Rebuild the owner's understanding of a system around one question: a dated HTML checkpoint connecting product intent, proposed structure, and code reality, built by a dedicated subagent. Use on the owner's direct request or when they accept a stage's checkpoint offer; never during headless orchestration.
---

Generated from `claude-pack/commands/_my_mental_model.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Mental Model Checkpoint

**Purpose:** Rebuild the owner's understanding of a system around one question — a visual, on-demand HTML checkpoint connecting product intent, proposed structure, and code reality
**Input:** The owner's question, plus optional starting context (a concept, epic, or review path)
**Output:** One dated report under `.project/mental-alignment/runs/`, plus a compact summary in-console

## What This Is

The artifact chain preserves decisions faithfully, but its volume makes it unrealistic for the
owner to keep a current mental model of a substantial system. This command builds a one-off,
question-led explanation for human judgment. The report explains; it does not govern — it is a
dated snapshot, subordinate to the evidence it explains, and it cannot settle conflicts or
outrank its sources.

This is not the orchestrator's launch-time Align checkpoint, not a review stage, and not a
living status dashboard. Generation is always owner-initiated: direct invocation here, or the
owner accepting an interactive offer from concept-design review or epic planning (both route to
this same flow). Headless orchestration never generates a checkpoint on the owner's behalf.

## Generate a Checkpoint (default)

1. **Get the question.** If `User-provided arguments are supplied when this skill is invoked.` carries it, use it. Otherwise ask the owner what they
   want to understand. Note any starting context you already have (the artifact under
   discussion, paths the owner mentions) — it is a hint for the builder, never a required list.
2. **Delegate whole.** Spawn a fresh-context `default` subagent whose entire instruction set is
   `$HOME/.codex/scripts/mental-model-builder.md` (pack source:
   `claude-pack/scripts/mental-model-builder.md`). Hand it exactly two inputs: **QUESTION**
   (verbatim) and **CONTEXT** (the optional starting paths). The builder solely owns discovery,
   the HTML, its safety and traceability guarantees, and success or failure.
3. **Relay the result.** Report the returned path, coverage boundary, limits, and concerns to
   the owner without restating the report and without a second output check. If the builder
   returns failure, relay it as failure — never relabel it as success.

Do not author or validate HTML yourself, resolve conflicts the report surfaces, record feedback
as part of generation, or promote lessons.

## Record Feedback (on request)

When the owner gives feedback on a checkpoint, append an entry to
`.project/mental-alignment/feedback.md` (create it if absent):

```markdown
## {YYYY-MM-DD} — re: runs/{report-filename}
{the owner's feedback, faithfully}
```

Every entry names the run it evaluates. Feedback stays project-local and changes no shared
behavior merely by being recorded.

## Promote a Lesson (explicit request only)

A reusable lesson moves into shared builder instructions only through an explicit, owner-visible
choice — never automatically, never as a side effect of recording feedback.

1. **Resolve the authored source.** Promotion targets the authored pack root only: from a
   development checkout, `claude-pack/scripts/mental-model-builder.md`; from a symlinked global
   install, follow the installed script's symlink back to its checkout; from a Codex install,
   use `source_root` in the dist `manifest.json`. Generated, installed, and vendored copies are
   evidence, not promotion targets.
2. **If authored source is unreachable, stop locally.** Record the candidate lesson in
   `feedback.md` marked `PROMOTION CANDIDATE (authored source unavailable)` and stop. Do not
   edit a generated or vendored copy instead.
3. **If reachable, propose a focused edit** to the builder contract (or this command) for owner
   review before applying it. After an applied edit, remind the owner to rerun the pack's
   install/build steps so both runtimes pick it up.

User-provided arguments are supplied when this skill is invoked.

