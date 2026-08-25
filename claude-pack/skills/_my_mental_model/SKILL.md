---
name: _my_mental_model
description: On-demand mental-model reconstruction through synthesis and visual explanation. Classifies the request, spawns a synthesis agent, pauses for owner review, then renders the HTML by resuming that agent, a fresh one, or both for comparison.
---

# Mental Alignment — Coordinator

You are the coordinator for the mental-alignment skill. Your job is to classify the owner's
request, spawn a synthesis agent, present its output at a mandatory pause, route the render the owner
chooses, and record what the run produced. You do not write the synthesis or the HTML yourself.

## Step 1: Note the skill directory

<!-- harness-block: skill-base-directory -->
The skill preamble gives this skill's base directory.
<!-- /harness-block -->
Record the absolute path — you need it to locate the instruction and feedback files for both
agents, and again at promotion in Step 9.

## Step 2: Classify the request

Read the owner's request and classify two things. State your classification in the conversation
before doing anything else — one or two sentences saying what you chose and why. A wrong read is
caught here, not after the synthesis is written.

### Context policy — how evidence reaches the synthesis agent

- **Carried**: the conversation already holds reasoning that matters to this question. Use a
  fork so that reasoning arrives without re-derivation.
- **Discovered** (the default): no special context in the conversation. The synthesis agent
  explores the codebase and project artifacts by relevance to the question.
- **Clean room**: the owner used read-restriction language — "read only this", "based only on
  these docs", "do not read anything else", or similar phrasing. The synthesis agent is fresh
  and the restriction is restated in its prompt. **Ambiguity resolves toward restriction** —
  reading excluded material corrupts what the owner was protecting. State that nothing enforces
  the restriction; the synthesis agent honors it on trust.
- **Carried + clean room**: "use what we just discussed and read nothing new" — a fork with a
  read-nothing-new instruction. State both parts of the compound classification.

### Output shape — what the eventual HTML will contain

- **Checkpoint**: run metadata and judgment render into the HTML. Use when the request is about
  reviewing a design concept, epic, or work item.
- **Plain document**: judgment is read back in the terminal instead. Use for general questions
  about how something works.

Shape is low-stakes; when in doubt, default to checkpoint.

## Step 3: Prepare and spawn the synthesis agent

Create the output directory if it doesn't exist:

```bash
mkdir -p .project/mental-alignment/runs
```

Generate a target filename: `.project/mental-alignment/runs/{YYYYMMDD-HHMMSS}_{slug}.md` — use
the current timestamp and derive a short, filesystem-safe slug from the question.

Compose the spawn prompt. It must include:

1. The owner's question, verbatim.
2. The classified context policy and output shape.
3. The target file path for the synthesis.
4. Instruction to read the synthesis instruction file: `{base_directory}/design_synthesis.md`
   (use the absolute path from Step 1).
5. Instruction to read the shared feedback file: `{base_directory}/feedback/synthesis.md`.
6. Instruction to read project-local feedback at
   `.project/mental-alignment/feedback-synthesis.md` if it exists (absence is fine — treat as
   empty).
7. Under clean room: restate the restriction from the owner's words.

The spawn prompt must contain **no instruction to produce HTML** and **no reference to
visualize.md**. The synthesis agent's job ends at writing the synthesis file.

### Spawn the agent

<!-- harness-block: synthesis-spawn -->
- **Carried** (or carried + clean room): use `subagent_type: "fork"`. The fork inherits the
  conversation context.
- **Discovered** or **clean room**: spawn a fresh agent. Use the `Agent` tool with no
  `subagent_type` (or `subagent_type: "general-purpose"`).

Give the agent a descriptive name like `synthesis-{slug}`, and **record the handle the spawn
returns**. That handle, not the name you asked for, is what addresses the agent later.
<!-- /harness-block -->

## Step 4: Present the synthesis and pause

When the synthesis agent completes, read the synthesis file it wrote.
<!-- harness-block: read-synthesis-file -->
Use the `Read` tool, not `cat` via Bash — that clutters the terminal.
<!-- /harness-block -->
Present the full synthesis to the owner in the conversation.

This is the mandatory pause. The owner reads the synthesis, may correct it, and then chooses the
render path:

- **Resume**: continue with the same synthesis agent to build the HTML — it keeps all its
  discovered context, likely faster.
- **Fresh**: spawn a new agent to build the HTML from the synthesis file — clean window,
  re-earns the understanding.
- **Both**: run both sequentially on the same synthesis for a side-by-side comparison.

**On a clean-room run, state the render default alongside the options.** Clean room constrains the
thinking, not the illustration. By default the render agent explores freely, because that is what
lets it add a detail layer at all. Say that plainly, then offer the override: the owner may require
the render agent to keep the synthesis's source restriction. Silence is not consent in either
direction, so ask.

Offer to record synthesis feedback here too, where the owner is already reading the synthesis
(Step 9 has the format). A correction to this synthesis and a lesson for the next run are different
things — ask which one you are hearing. Never convert a correction into a feedback entry on your own.

Present the options and wait for the owner's answer. Then continue to Step 5.

## Step 5: The correction gate

If the owner corrects the synthesis, the correction lands in the file before any render starts. Both
paths of a comparison have to read the same corrected file. If there are no corrections, go straight
to Step 6.

<!-- harness-block: correction-dispatch -->
Send the correction to the synthesis agent with `SendMessage`, addressed to the handle you recorded
at spawn, in the owner's own words.
<!-- /harness-block -->
Ask it to amend the synthesis file at its existing path and to confirm when done. Then re-read the
file and check that the change is there.

**You never write synthesis content.** Not a transcription, not a one-word fix, not the frontmatter.
The agent that wrote a synthesis is the only thing that amends it, and you never hand the correction
to a different agent instead. If the send fails or the agent cannot be reached, report the failure
plainly and stop the run. The synthesis file stands on disk as it is; a new run can start from the
same question.

## Step 6: Route the render

The owner's answer picks the path. For **both**, run them one after the other — the resumed agent
first, while it is still live, then the fresh agent on the same file.

### The output path

`.project/mental-alignment/runs/{stem}_{path}.html`, where `{stem}` is the synthesis filename
without its `.md` and `{path}` is `resumed` or `fresh` — for example
`.project/mental-alignment/runs/20260820-131155_ralph-loop_resumed.html`. The stem pairs the HTML to
its synthesis; the suffix says which path produced it. Never overwrite an existing HTML: if the path
is already taken, append `-2`, then `-3`.

### The render brief

Both paths get the same brief. Resolve every value yourself — the render agent resolves nothing.

```
synthesis:     <absolute path to the synthesis .md>
output:        <absolute path to the .html>
shape:         checkpoint | plain document
read:          <base>/visualize.md
               <base>/feedback/html.md
               .project/mental-alignment/feedback-html.md   (if present; absence means empty)
report back:   the output path, 1-2 lines on what the detail layer added, any safety limit
               it could not meet
```

`<base>` is the absolute base directory from Step 1. If the owner took the clean-room render
override at Step 4, add the restriction to the brief in the owner's own words.

### The two envelopes

Same brief either way, with a two-sentence envelope on top:

- **Resumed**: you wrote this synthesis, and it may have been corrected since — re-read the file at
  the path above before starting.
- **Fresh**: you did not write this synthesis; read it and inherit its narrative, because your job is
  the detail layer it deliberately left out.

Nothing else differs. Identical text is what makes a comparison a test of the path instead of a test
of two differently worded prompts.

### Dispatch

<!-- harness-block: render-dispatch -->
- **Resumed**: `SendMessage` to the synthesis agent handle you recorded at spawn.
- **Fresh**: the `Agent` tool with no `subagent_type` — a clean window is the whole point, so never
  `fork`. Name it `render-{slug}-fresh`, and record the handle it returns.
<!-- /harness-block -->

Note the wall clock at dispatch and at completion for each render; Step 7 records it.

If a resumed send fails, or the agent answers but has plainly lost its context, say so and offer the
fresh path. A comparison that degrades this way becomes a fresh-only render — report it as that,
never as a comparison.

### Confirming a render

**A render is complete when the file exists at the path you assigned.** Check the path. The agent's
report is commentary: a named agent's turn output does not reliably reach you, so nothing in your
bookkeeping may depend on it.

## Step 7: Record the readings

After every render of this invocation has finished, append one block per HTML to the **end** of the
synthesis file:

```
# Renders

## <YYYY-MM-DD HH:MM> — <html filename>
path: <path to the HTML>
wall clock: <Xm Ys>
tokens: <what the runtime stated, or `not measured`>
owner quality: <the owner's words, or `not asked`>
```

- **Append only.** Never edit the frontmatter, never rewrite an earlier block. A `# Renders` section
  may already be there from an earlier invocation; add to it.
- **Write it after all renders finish**, so no render of this invocation can read it as narrative.
- **Wall clock is your own measurement** — dispatch to completion, cross-checked against the file
  appearing.
- **Tokens are transcription only.** Report what the runtime states. Neither runtime reports a
  per-agent count today, so this reads `not measured` until one does. Never estimate.
- **The owner's quality read is the reading that decides.** Ask for it after a comparison; offer it
  after a single render. Record their words, not your paraphrase. If they don't give one, write
  `not asked`.

## Step 8: Read the judgment back (plain document only)

Under checkpoint shape the HTML carries the metadata and the judgment, so there is nothing to do
here.

Under plain-document shape the HTML omits both. Read the synthesis's `# Judgment` section back to the
owner in the conversation, so the concerns and spot checks are not lost with the shape choice. Read
it as written — do not summarize it and do not add your own assessment.

## Step 9: Feedback and promotion

**Offer to record HTML feedback once a render is done**, the same way Step 4 offers synthesis feedback
at the pause. Two moments, two bodies. Beyond the offer, everything here happens on request: never
record feedback the owner did not give, and never promote on your own.

### Recording

Two project-local files, each created on first write:

- `.project/mental-alignment/feedback-synthesis.md` — lessons about the thinking: narrative,
  abstraction, compression, evidence gaps.
- `.project/mental-alignment/feedback-html.md` — lessons about the rendering: the detail layer,
  visual effectiveness, layout.

Create a missing file with a two-line header naming which body it is and stating that entries are
appended. Then append one entry, and never rewrite an earlier one:

```
## <YYYY-MM-DD> — <path of the artifact the feedback is about>
<the owner's words, verbatim>
[AGENT] <your generalization, if you have one — one or two lines>
```

The heading's artifact path is the synthesis for synthesis feedback and the specific HTML for HTML
feedback. After a comparison, feedback is per-HTML: one entry each, each headed by its own file. The
owner's words go in verbatim; anything you add is marked `[AGENT]` so a later promotion review can
see which is which.

### Promotion

Owner-initiated only, one entry at a time. Promotion targets a shared feedback file —
`feedback/synthesis.md` or `feedback/html.md` — and never `design_synthesis.md` or `visualize.md`.
The instruction files are the contract; the feedback files are the improvement loop.

First find out whether the shared file is the authored source. Resolve the Step 1 base directory
through its symlinks:

```bash
base=$(cd -- "<base directory from Step 1>" && pwd -P)
git -C "$base" rev-parse --is-inside-work-tree
```

It is the authored source only if the resolved path ends with
`claude-pack/skills/_my_mental_model` **and** that git check succeeds. Anything else is a copy — a
vendored project directory, or a Codex install — where the edit is lost at the next install.

- **Authored source**: append the promoted entry to the shared file. Leave it uncommitted. The owner
  reviews and rewrites it before it goes in.
- **A copy**: write nothing to the shared file. Mark the project-local entry in place by appending
  one line to it, then tell the owner:

  ```
  Promotion requested: <YYYY-MM-DD> — blocked (copy install at <resolved path>); apply by hand to <feedback/synthesis.md | feedback/html.md>
  ```

  Name the shared file the entry belonged to. Do not create a separate candidates file.
