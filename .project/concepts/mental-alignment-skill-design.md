# Design: Mental Alignment Checkpoint — Skill Shape

**Status:** Accepted (2026-08-20, after independent review — verdict Approve — and owner resolution of findings)
**Owner:** Reid W
**Created:** 2026-08-20
**Concept:** `.project/concepts/mental-alignment-checkpoint.md` (the settled decisions live there; this design wires them)

---

## Overview

This is the second design for the mental-alignment checkpoint: an on-demand tool that rebuilds the owner's understanding of a system around one question, ending in a committed visual explanation. The first version shipped as a single delegated instruction set and failed in use. This design splits the work into three named steps — collect context, synthesize, render — run by two agents with a human pause between them.

The core insight: an agent that can see the final deliverable in its prompt races to it and skips the thinking. So the thinking step gets its own agent whose prompt ends at a short written synthesis. The owner reads that synthesis at a mandatory pause, corrects it if needed, and only then chooses how the visual layer gets built.

---

## Problem

The workflow preserves decisions in durable artifacts, but the owner cannot read them all; recovering the whole mental model of a system is the standing pain the checkpoint exists to solve. The shipped version tried to solve it by handing one fresh worker a complete instruction set covering discovery, thinking, and rendering in a single pass. Three failures followed, all structural.

First, the thinking was never a step. The instructions described gathering evidence and described the finished output, but the work between them — choosing the abstractions, the narrative, the structure that compresses the system best — had no name, no output, and no checkpoint. With the deliverable visible from the start, the worker treated the early steps mechanically and produced weak explanations.

Second, the worker was always fresh. When the owner had just spent a conversation reasoning through the architecture, none of that reasoning could reach the output, because a fresh agent cannot inherit a conversation. Third, the output shape was mandatory: a question that wanted a plain explanation came back wrapped in checkpoint metadata anyway, ignoring the context the owner gave. A single undifferentiated feedback file compounded the drift, mixing lessons about thinking with lessons about rendering.

---

## Goals

- Recover the owner's mental model from one question, placed in relevant system context, without reading the full artifact chain.
- Make the thinking visible and correctable: a short readable synthesis exists, and is shown to the owner, before any rendering starts.
- Let reasoning from the current conversation reach the run when it matters, and honor read restrictions phrased in the owner's own words.
- Fit the output shape to the question — checkpoint or plain explanation — while keeping the agent's own judgment separable from claims carried from evidence, in both shapes.
- Support comparing the two ways of building the visual layer on real runs, measured on wall-clock time, tokens, and the owner's read of quality.
- Improve through curated feedback: lessons land project-local first and cross projects only when the owner promotes them.
- Behave equivalently when driven from either supported runtime.

## Non-Goals

- Automatic generation anywhere in the pipeline; a mandatory catalog of visuals; writing into `docs/`; flags or named arguments.
- Automated checks of any kind on the output — no quality fixtures, no mechanical ones. The owner judges; feedback is the loop.
- Migrating other commands to skills, or relocating the existing prose specs out of `claude-pack/scripts/` — this skill sets the precedent only.
- Replacing concept-design review, product-lens checks, design review, or audit. This serves comprehension, not certification.

---

## Design Principles

### 1. The prompt ends where the thinking must happen
An agent whose prompt contains the final deliverable optimizes toward it. The synthesis agent's initial instructions therefore end at the synthesis; the instruction to render arrives only afterwards, as a separate message or a separate agent. Merging the steps back "for efficiency" recreates the shipped failure.

### 2. Classify, don't configure
Policy and output shape are read from what the owner said, never from flags. The skill states its classification out loud before acting, so a wrong read is caught in one exchange. Ambiguous restriction language resolves toward restriction, because reading excluded material corrupts exactly what the owner was protecting.

### 3. Skeleton, then meat
The synthesis is the simplest view: high-level logic, narrative, maximum compression. The rendered layer inherits that narrative and adds a second layer of detail using what the medium can do — visuals, disclosure, color. It is never the same words in a different format.

### 4. Snapshot, not authority
Every output reflects the evidence available when generated and is never a second canonical model. Source authority and provenance are preserved; the agent's judgment is visibly its own; later runs regenerate rather than update.

### 5. Short and situational in the prompt; long and improvable in a file
Instructions that vary per run (the context policy, the question) travel in the spawn prompt. Instructions that grow with feedback (how to synthesize, how to render) live in files the spawned agent reads, so they cost the conversation nothing and can improve independently.

---

## Architectural Bets

- **A human pause is the seam between the two machine steps.** Every run stops on the synthesis. This is what makes the thinking correctable, makes the render choice free (the owner is already there), and lets one synthesis carry multiple renders for comparison.
- **Resume means continuing the live synthesis agent in-session,** not spinning up headless sessions. The Codex spike confirmed that the runtime can message a completed spawned agent and preserve its conversation context. Its completion notification did not report per-agent token usage, so Item 5 must find a supported measurement source or report that measure as unavailable on Codex. See `.project/active/codex-resume-spike/spike-findings.md`. Rejected: reusing the headless orchestration machinery — it drags that plumbing into an interactive skill.
- **Codex parity by construction, not by rewrite.** The skill entry is written in runtime-neutral delegation language, and the build learns to copy an allowlisted skill directory whole. Rejected: a Codex-specific sanitization pass for native skills (a second rewrite engine to maintain), and shipping Claude-only (the concept grades the Codex changes in scope).
- **This is the first `_my_*` directory skill** and sets the migration pattern for the rest: one directory, entry point plus supporting instruction and feedback files, installed as a single symlink on Claude.

## ADR Candidates

Decisions scoped to this one skill (the withheld render deliverable, in-session resume) are recorded in this design and its principles, not as ADRs — they don't cross a seam beyond the skill itself. Two decisions do:

### Pack capabilities ship as directory skills, not commands with shared scripts
- **Proposed decision:** A capability is a skill directory — `SKILL.md` entry point plus sibling instruction and feedback files — installed on Claude as one symlink to the whole directory. This replaces the command-file-plus-`claude-pack/scripts/`-spec pattern; `_my_mental_model` is the first migration and sets the shape for the rest.
- **Why it may need a record:** The command + shared-script pattern is the dominant precedent in the pack (product-lens, the v1 builder). A future agent adding or migrating a capability would plausibly copy it, including its absolute-path delegation, instead of the skill-directory shape.
- **Affected seams:** `claude-pack/` layout, `setup-global.sh`, every future capability, the Codex build.
- **Provenance:** `[OWNER]` — the concept settles the skill-directory unit and that it sets the migration pattern.
- **Alternative rejected:** command file delegating to a spec in `claude-pack/scripts/` (the v1 shape and current dominant pattern).

### Native-skill Codex lane: copy whole, keep bodies runtime-neutral
- **Proposed decision:** The Codex build copies every file of an allowlisted skill directory; in exchange, native skill bodies must avoid runtime-specific delegation vocabulary. No sanitization pass exists for them; the existing dist scan enforces this for `SKILL.md` only, so sibling files carry the obligation by convention. Whether a widened scan later enforces it is spec's call — the record is the convention decision itself.
- **Why it may need a record:** A future skill author would plausibly assume the command-style rewrite pass applies and write Claude-specific text that breaks the Codex build.
- **Affected seams:** `build-codex-pack.sh`, `setup-codex.sh`, `codex-overrides/config.sh`, `test_codex_orchestrator_pack.sh`, every future native skill.
- **Provenance:** `[AGENT]` (ratified by owner, 2026-08-20).
- **Alternative rejected:** a native-skill sanitization pass mirroring the command lane.

---

## Core Model

*Register shift: identifiers from here down.*

### Coordinator — `claude-pack/skills/_my_mental_model/SKILL.md`
The user-invoked entry (`/_my_mental_model`), running in the main conversation. Responsible for: classifying context policy (*clean room* / *carried* / *discovered*) and output shape (*checkpoint* / *plain document*) from the request and stating its read; composing the spawn prompt (question verbatim, policy, context hints, target synthesis path); spawning the synthesis agent; presenting the synthesis at the pause and routing the owner's choice (resume / fresh / both); reporting wall-clock and token readings after renders; appending owner feedback to the project-local feedback files; proposing promotions against the shared feedback files. NOT responsible for: authoring synthesis or HTML content, validating output quality, resolving evidence conflicts.

### Synthesis agent + `design_synthesis.md`
A fork of the conversation (`subagent_type: "fork"` on Claude, `fork_turns: "all"` on Codex) under *carried* policy; a fresh agent otherwise (under *clean room*, with the restriction restated in its prompt — unenforced, which the coordinator says out loud). Reads `design_synthesis.md` plus both synthesis feedback bodies. Discovers evidence per policy, then writes exactly one file: `.project/mental-alignment/runs/{YYYYMMDD-HHMMSS}_{slug}.md` — the skeleton: narrative, per-section claim with register and provenance, the visual form that fits it, a pointer to where details live, plus a metadata section (question, date, policy, evidence, code-inspected, limits) and a judgment section (concerns, uncertainty, disagreements, spot checks). Its prompt ends here.

### Render agent + `visualize.md`
Either the resumed synthesis agent (a follow-up message: read `visualize.md`, both HTML feedback bodies, and build) or a fresh agent given the synthesis path and the same reading list. Writes one new HTML beside the synthesis, paired to it; comparison renders get distinct names. The HTML inherits the synthesis narrative and adds the detail layer. In *checkpoint* shape it renders the metadata and judgment sections; in *plain document* shape it omits them and the coordinator reads the judgment back in the terminal. Safety posture is instructional, not verified: no active content, no undisclosed remote resources, no secrets — same trust level as clean room.

### Feedback bodies — two topics, two tiers
Shared starters ship in the skill directory: `feedback/synthesis.md`, `feedback/html.md` — git-tracked in the pack, present wherever the skill is installed. Project-local files at `.project/mental-alignment/feedback-synthesis.md` and `feedback-html.md` are where new feedback always lands, attributed to the run (and, for comparisons, the specific HTML) it reviewed. A run reads shared then project-local. Promotion is owner-initiated only and edits the shared feedback file in the authored pack, arriving as an uncommitted change the owner rewrites before committing.

### Run artifacts — `.project/mental-alignment/runs/`
One synthesis markdown per run, one or more HTMLs paired to it. Two candidate pairing mechanisms — filename stem, or a pointer list in the synthesis metadata — spec chooses. Committed, never overwritten; a rerun writes new files. Promotion of an HTML into `docs/` is the owner's manual act.

### Distribution lane
Claude: `setup-global.sh` already symlinks whole skill directories — no change. Codex: three build changes — copy allowlisted skill-directory siblings into dist and on install (today both walks pick up only `SKILL.md`), add the directory to `NATIVE_SKILL_ALLOWLIST`, and apply the `_my_x` → `my-x` name mapping so the Codex name is `my-mental-model`. The frontmatter description must be plain prose (Codex's YAML parse chokes on a leading `*`). File-and-line references for all of this, and for retiring the v1 surfaces, are in the Appendix.

## Flow

```
request ─► coordinator: classify policy + shape, state the read
              ├─ carried ─► fork synthesis agent
              └─ else ────► fresh synthesis agent (clean room: restriction restated)
                              │ reads design_synthesis.md + synthesis feedback
                              ▼
                   runs/{stamp}_{slug}.md  (synthesis)
                   ══ PAUSE: owner reads, corrects, chooses ══
              resume same agent │ spawn fresh │ both (comparison)
                              │ read visualize.md + html feedback
                              ▼
                   one or more HTMLs in runs/, paired to the synthesis
```

## Prior Art

Index checked at authoring (8 entries, 0001–0008): none superseded, none contradicted. At acceptance this design filed ADR 0009 (directory-skills pattern) and ADR 0010 (native-skill Codex lane). ADR 0006 (reviews read ADRs but never file them) shapes nothing here beyond leaving the existing stage-offer touch points — in concept-design review and epic planning, with their NON-INTERACTIVE suppression — unchanged, as the concept settles.

The synthesis agent may read decision records as evidence, discovery-led and permissive, and never files, amends, or resolves them. This does not extend the ADR touch-point map (0002 as amended, 0005): that map records where the pipeline *must* read and write; this skill reads by relevance like any exploration. The archived v1 design proposed a map amendment for the same behavior — dropped here deliberately, not by omission.

---

## Required Invariants

All are intended state — this is a fresh build; none hold today. Items marked *(continuity)* carry the same posture v1 had.

### Steps and the pause
- The synthesis agent's initial prompt contains no instruction to produce an HTML.
- A synthesis file exists on disk before any HTML sharing its stem.
- Every run pauses after the synthesis is presented; no HTML is built before the owner answers.
- The coordinator states its policy and shape classification before spawning anything.

### Artifacts
- Every HTML resolves to exactly one synthesis; one synthesis may pair with many HTMLs. (The pairing mechanism is spec's choice.)
- All run output lands under `.project/mental-alignment/runs/`; nothing is overwritten; collisions get a new timestamp *(continuity)*.
- The synthesis always contains metadata and judgment sections; the shape only decides whether they render into the HTML or are read back in the terminal.
- Generation is owner-initiated only; the NON-INTERACTIVE marker suppresses stage offers *(continuity)*.

### Feedback
- New feedback is written project-local first, attributed to the run and HTML version it reviewed.
- Shared feedback bodies change only on owner-initiated promotion, and promotion targets the feedback file, never the instruction files.

### Distribution and transition
- `SKILL.md` contains no Claude-specific delegation vocabulary (checked by the existing dist scan once the skill is allowlisted); the sibling instruction files carry the same obligation, unscanned.
- A global Claude install places the skill as one symlink to the pack directory, so siblings arrive with it; vendored copy-installs exist on both runtimes (see the promotion edge case).
- The v1 builder spec and command no longer exist, and every reference to them is updated in the same change (inventory in the Appendix).

---

## How It Works

### A default run, end to end
The owner asks a question. The coordinator finds no restriction language and no load-bearing conversation reasoning, states "discovered policy, checkpoint shape" (or plain document, if the request reads as a plain question), and spawns a fresh synthesis agent. The agent explores by relevance, writes the synthesis, and stops. The coordinator shows it. The owner corrects one section, then says "resume." The same agent — still holding its discovered context — gets the render message, reads `visualize.md` and the HTML feedback, and writes the HTML. The coordinator records time and tokens in the synthesis metadata and reports the path.

### Carried and clean room
After a long design discussion the owner says "checkpoint what we just worked out": the coordinator classifies *carried* and forks, so the conversation's reasoning arrives without re-derivation. If the owner instead says "based ONLY on these two docs": *clean room*, a fresh agent with the restriction restated — and the coordinator states that nothing enforces it. The combination "use what we just discussed and read nothing new" is a fork under a read-nothing-new instruction.

### A comparison
At the pause the owner asks for both. The coordinator sends the render message to the live synthesis agent, then spawns a fresh render agent on the same synthesis — two HTMLs under distinct names, built sequentially. The coordinator reports wall-clock and tokens for each; the owner judges quality and records feedback attributed per-HTML. Naming and where the readings are durably recorded are spec details.

### Transition from v1
Removed: the builder spec and the command, plus their build wiring. Replaced by: the skill directory, the allowlist entry, generic sibling copying, and the name mapping. Unchanged: the two stage offers, the runs location, owner-initiated-only generation, and the promotion posture.

## Edge Cases and Failure Modes

- **Resume is unavailable** (synthesis agent gone, context compacted, or Codex cannot resume a spawned agent): the coordinator says so and offers the fresh-agent shape. This degrades the comparison, never the run. If the spike finds Codex cannot resume, Codex simply always takes this branch.
- **Contradictory policy language** ("only these docs" + "use our discussion"): carried-with-restriction — fork, read nothing new. Pure ambiguity resolves toward restriction.
- **The owner abandons the pause.** The synthesis stands alone as a committed, readable artifact; a later invocation may render from it or regenerate.
- **Promotion from a copy install** — Codex, or a Claude project vendored with `init-project.sh --include-claude`: the shared feedback file there is a copy, not the authored source. The coordinator records a promotion candidate project-locally instead of editing a file whose edits would be lost *(continuity with v1's fail-closed posture)*.
- **A comparison render contradicts the synthesis narrative.** The synthesis is the arbiter; the divergence is per-HTML feedback material, not something the coordinator reconciles.
- **Feedback files missing** (project never re-inited): created on first write; absence is empty, not an error.
- **The question is too broad.** The synthesis agent narrows or states an explicit coverage boundary in the metadata — visible at the pause, where the owner can redirect cheaply.

## Vocabulary

- `coordinator`: the skill entry running in the main conversation; classifies, spawns, pauses, routes, records.
- `synthesis`: the skeleton markdown — narrative, claims with provenance, chosen visual forms, metadata, judgment.
- `render`: building one HTML from a synthesis; `resumed` and `fresh` name who builds it.
- `carried` / `discovered` / `clean room`: how context reaches the synthesis agent — fork, relevance-led exploration, or stated-source-only.
- `checkpoint` / `plain document`: whether metadata and judgment render into the HTML or the judgment is read back in the terminal.
- `pairing`: the link from each HTML to the synthesis it was built from; the mechanism is chosen at spec.
- `promotion`: owner-initiated move of a project-local lesson into a shared feedback body.

## System Confidence

Boundary obligations: the coordinator guarantees the synthesis agent receives the question verbatim, the policy, and the target path; the synthesis agent guarantees a complete synthesis (narrative + metadata + judgment) exists before the pause; every render agent may treat the synthesis as the narrative authority and must add detail rather than restate it.

Route agreement: resumed and fresh renders must both produce an HTML that inherits the synthesis narrative. By owner decision this equivalence is judged, not checked — the comparison mechanism exists precisely to exercise it under observation.

Dangerous, never-exercised combination: fork + clean-room restriction. Codex + resume was exercised successfully by `.project/active/codex-resume-spike/spike-findings.md`; long-idle and post-compaction continuation remain untested.

Unowned proofs — no single component's behavior establishes these; the epic must own them as items:
1. **Resolved 2026-08-20:** Codex can resume a completed spawned agent through a follow-up task, so the switch exists there. The collaboration result did not expose per-agent token usage. See `.project/active/codex-resume-spike/spike-findings.md`.
2. A fork actually carries conversation reasoning into a materially better synthesis (the carried policy's whole premise).
3. The directory-skill lane works end to end on both runtimes: the build copies siblings, installs place them, and the installed skill resolves by its slash name and finds its files — no `/_my_*` slash invocation resolves to a directory skill anywhere in the repo today, so the migration item verifies this on first invocation, without breaking the two existing native skills.

## Validation Strategy

- Output quality: owner judgment plus the feedback loop — no automated checks, by owner decision.
- The build and retirement changes are ordinary code with ordinary drift guards: the existing docs/catalog tests, the dist delegation-language scan, and the pack build/install tests, updated for the retired command and the new lane. These guard the plumbing, not the output.
- The comparison mechanism itself is the validation instrument for the resume-vs-fresh bet: a few real runs, three readings each.

---

## Next-Stage Handoff

**Settled here:**
- The two-agent, one-pause shape; who reads which instruction file; resume as in-session continuation with fresh-agent fallback; the parity strategy (runtime-neutral body, sibling copy, allowlist, name mapping); the comparison requirement — both renders on request, sequential, reported on wall-clock, tokens, and owner-judged quality.

**Spec detail still needed next:**
- Classification wording and what the coordinator prints; the synthesis template (section-by-section contents); the pairing mechanism (filename stem vs. metadata pointer); comparison naming and where its readings are durably recorded; spawn-prompt composition; the three Codex build changes as concrete edits; whether the sibling runtime-neutrality scan is widened; feedback file formats and the promotion procedure against copy installs.

**First risk de-risked:**
- The Codex resume spike confirmed same-agent continuation through a follow-up task. Per-agent token measurement remains unavailable on the observed collaboration surface. See `.project/active/codex-resume-spike/spike-findings.md`.

**Proof obligations:**
- The three unowned proofs above: the Codex resume spike, a real carried-vs-discovered run judged by the owner, and an end-to-end Codex lane check covering the existing native skills.

**Decomposition:** the concept already calls this an epic; the slices it names (synthesis, render, classification, switch + comparison, feedback tiers, skill migration + build changes) map one-to-one onto this model.

---

## Summary

The failed version asked one fresh agent to think and render in a single breath, so it rendered without thinking and dropped the owner's reasoning on the floor. This design gives the thinking its own agent, its own instruction file, and its own visible output — and puts the owner at the seam, where the render choice, the correction, and the comparison all become free.

---

## Appendix — Transition reference (not part of the main-body budget)

Verified against the working tree, 2026-08-20.

**Claude install (no change needed):** `setup-global.sh:126-134` symlinks whole skill directories (files and dirs both), so siblings ship with the skill automatically.

**Codex build/install changes:**
- `build-codex-pack.sh:395` — the directory-skill walk matches only `SKILL.md` (`-mindepth 2 -maxdepth 2`); extend to copy siblings (including `feedback/`, which a nested walk today would not even discover).
- `setup-codex.sh:267` — installs only `SKILL.md` per skill dir into `~/.agents/skills/`; extend likewise.
- `codex-overrides/config.sh:58` — add the skill directory to `NATIVE_SKILL_ALLOWLIST` (opt-in; without it the skill is silently excluded).
- Name mapping `_my_mental_model` → `my-mental-model` for the dist directory and frontmatter name. This mapping is also what makes the stage offers resolve on Codex: the command lane rewrites their `/_my_mental_model` mentions to `my-mental-model` (`build-codex-pack.sh:155-158`).
- The Codex description has no override lane for native skills — `description_for_native_skill` (`build-codex-pack.sh:243-255`) reads only frontmatter. So the retired override's text must move into the skill's own frontmatter `description:`, which is what makes the plain-prose/no-leading-`*` constraint load-bearing.
- Guard that binds the runtime-neutrality invariant: `test_codex_orchestrator_pack.sh:336-338` — note it is globbed `-g 'SKILL.md'`, so copied siblings are unscanned; whether to widen the glob is spec's call.
- Slash resolution: every `/_my_*` in the repo today resolves to a file in `claude-pack/commands/`; the runtime documents `/<skill-name>` invocation for directory skills, but this migration is the first use — verified at first invocation after install.

**Retiring the v1 surfaces:**
- Delete `claude-pack/scripts/mental-model-builder.md` and `claude-pack/commands/_my_mental_model.md`.
- Remove the path rewrite at `build-codex-pack.sh:138` and the shared-spec copy at `build-codex-pack.sh:426`.
- Remove the command description override at `codex-overrides/config.sh:37`.
- `README.md:131` — replace the command-catalog row (note: `test_docs.sh:43-56` requires catalog rows only for existing command files, and its `RETIRED` list at line 59 would *forbid* a README mention if `_my_mental_model` were added there — the README text and the retired list must change together). No test guards skill-catalog completeness, so the skill's replacement row is convention-only.
- `scripts/uninstall-project.sh:108-114` — hardcoded skill names; add the new directory.
- Rebuild `dist/codex/` (manifest currently lists `my-mental-model` under `command_skills` and `mental-model-builder.md` under `scripts`).
