# Concept: Mental Alignment Checkpoint

**Created:** 2026-08-09
**Revised:** 2026-08-19 (owner-directed, two passes: the three-step rev, then the shape rev)
**Status:** Draft

---

## Problem Statement

The workflow preserves product, architecture, scoping, and implementation decisions in durable artifacts. For
substantial work that record spans concepts, product designs, concept-designs and reviews, epics, specs,
designs, plans, ADRs, product-lens ledgers, audits, and code. The owner cannot read every artifact in full, so
catching up means reconstructing one system from five to ten documents written at different levels and times.
Agents check product purpose, architecture, or implementation, but none help the owner recover the whole
mental model, so drift, architectural slop, and small code issues go unnoticed.

A summary of the artifacts alone would not close the gap; it could faithfully visualize a bad premise every
upstream artifact shares. The work must put intended behavior, the proposed system, and code reality into one
context while keeping its own interpretation separate from source authority.

### What the shipped version got wrong (2026-08-19)

- **The middle step was never named** — context construction and the two-layer output were described, never
  the work between them: synthesizing how to describe the design.
- **The handoff drops the owner's reasoning.** The cause is structural: the command spawns a *fresh* subagent,
  and a fresh subagent cannot inherit a conversation.
- **The checkpoint shape is mandatory,** so a question that wanted a plain explanation came back wrapped in
  metadata and two layers anyway.

## Owner's Words

Verbatim statements from the 2026-08-09 shaping conversation and both 2026-08-19 revisions are in the
Appendix; later sections paraphrase, and those quotes are the record they trace to.

## Success Criteria

1. **[OWNER] On-demand recovery** — The owner asks about a project, epic, item, subsystem, or artifact and
   receives committed HTML placing it in relevant system context.
2. **[OWNER] Three named steps, synthesis independent** — Collecting context, synthesis, and rendering are
   named separately and each can be instructed and improved on its own. Synthesis is the thinking piece —
   describing the design concisely, capturing its patterns and abstractions — and it happens on its own rather
   than as a side effect of rendering. The owner can take just the markdown.
3. **[OWNER] The synthesis is the skeleton, the HTML is the meat** — The synthesis is the simplest view: the
   high-level logic, the narrative, the structure that compresses the information best. The HTML inherits that
   narrative and adds a second layer of detail, using what HTML can do — visuals, disclosure, color — to fit
   more in without overwhelming a human reader. It must not be the same words in a different format.
4. **[OWNER] Policy and shape read from the request** — Context reaches a run as *carried*, *discovered*, or
   *clean room*; output is a checkpoint (run metadata and judgment in the HTML) or a plain document (judgment
   spoken in the terminal). No flags: the skill classifies from what was said and states its read first.
5. **[OWNER] Judgment stays separable in both shapes** — Judgment is the agent's own material: concerns,
   unresolved uncertainty, disagreements between sources, suggested spot checks. It is distinct from claims
   carried from the evidence, and never reads as settled truth.
6. **[OWNER] One fixed HTML location** — Every run writes to the same place; moving a document into `docs/`
   is the owner's act.
7. **[OWNER] Two feedback bodies, two tiers** — One body for synthesizing and communicating design, useful for
   technical communication generally; one for building a good HTML. New feedback lands project-local first; a
   starter body ships with the pack, git-tracked and symlinked, and a run reads both. A lesson moves to shared
   only when the owner asks, because agent-written feedback needs rewriting first.
8. **[AGENT] Grounded in evidence** — The output connects intended behavior, relevant artifacts, and current
   code or tests. It inspects code when explaining current behavior or judging seams, and otherwise says code
   was not inspected. Material disagreements are surfaced, not reconciled.
9. **[AGENT] Reviewable decision points** — At concept-design the HTML exposes proposed system shape,
   responsibilities, and invariants; at epic-plan, item boundaries, dependencies, and cross-item obligations.
10. **[AGENT] Demonstrable comprehension** — On representative questions the owner can identify intended
    behavior, relationships, invariants, and the highest-leverage tensions without reading the full chain.
11. **[AGENT] Safe committed output** — The HTML step is instructed to exclude secrets, unsafe active content,
    and undisclosed remote resources. Nothing verifies it, the same posture as clean room.
12. **[OWNER] A pause, then a choice** — Every run stops after the synthesis and shows it. At that pause the
    owner picks where the HTML gets built: resume the same agent, use a fresh one, or run both on the same
    synthesis to compare them side by side on wall-clock time, tokens, and their own read of quality.
13. **[OWNER] No new ceremony** — Nothing is generated by default. Only concept-design and epic-plan actively
    suggest a checkpoint; the owner may invoke it anywhere else.

---

## Why This Shape

- **Key bet:** **[OWNER]** A question-led, visual reconstruction of the relevant system restores enough of the
  owner's mental model to make product, architecture, and code spot checks practical. **[AGENT] (ratified by
  owner, 2026-08-09)** The HTML stays a committed snapshot, not governing truth: it preserves source authority,
  separates fact from judgment, and exposes doubt.
- **Second bet (2026-08-19):** **[OWNER]** Naming the steps separately beats one instruction set doing all
  three; an agent whose prompt contains the final deliverable races to it, so a prompt that ends at the
  synthesis is what makes the thinking real.

---

## User Stories

**[AGENT]** derived from the owner-originated outcomes above.

- **US-1:** I ask how a subsystem works and get one visual explanation, without reading the whole chain, and
  reasoning I just worked through in conversation reaches it.
- **US-2:** I say "read only these docs" in my own words and the run honors it, with no flag to remember.
- **US-3:** I read a one-page synthesis, and fix it, before it is baked into a document.
- **US-4:** Reviewing an epic or concept-design, I see boundaries, invariants, flows, and code reality at once.

---

## Key Concepts

### 1. Question-Led Output

The invocation starts with what the owner wants to understand or review; a named project, epic, item, or
subsystem is a seed, not a hard boundary. The work builds the smallest useful model and states its boundary.

### 2. Three Named Steps, Two Instruction Files, One Seam

Naming the steps separately is what makes each improvable: synthesis gets guidance on describing a design
concisely, rendering gets checklist material for common visual failure modes, and collection gets the policy
below. **[OWNER]** Collection needs no file of its own — the coordinating agent composes the policy into the
spawn prompt, and under a fork it barely applies. **[AGENT] (ratified by owner, 2026-08-20)** The dividing
rule: short and situational travels in the spawn prompt, long and improvable lives in a file the spawned agent
reads, so it costs the conversation nothing and can grow with feedback.

The synthesis is a file written before any HTML exists, and it stays a short readable page: the high-level
logic, the narrative, and the structure that compresses best — per section, the claim with its register and
provenance, the visual form that fits it, and a pointer to where the details live. The HTML inherits that
narrative and adds the second layer. **[EXAMPLE]** "three categories of methods" becomes the categories with
the methods under each; "two data models" becomes the two models with their forms; a flow diagram becomes a
full diagram with labels and notes that explain. **[OWNER-VERBATIM]** "I DO NOT WANT THE HTML JUST TO BE THE
SAME WORDS IN A DIFFERENT FORMAT".
**[AGENT]** The synthesis is kept and paired to its HTML by filename — one synthesis may carry more than one
HTML — and it is what feedback critiques and what a rerun starts from.

### 3. Two Execution Shapes, Switched and Compared

**[OWNER]** Every run pauses after the synthesis and shows it, and the owner answers there — which is why the
switch needs no flag and no stored setting. The choice is between two real trade-offs, both shipping:

- **Same agent, resumed** — nothing is rediscovered. Likely faster, with more noise in the window.
- **Fresh second agent** — clean window, but it re-earns the understanding the first agent already had.

**[OWNER]** The owner may also ask for both on one synthesis, producing two HTMLs under different names,
measured on wall-clock time, tokens, and their own read of quality. Deciding at the pause costs nothing while
the pause is unconditional; removing it later means choosing a default anyway, and a front-loaded "don't pause"
request could carry its own answer. Both mechanisms exist in the pack (Appendix).

### 4. Context Policy, Classified From the Request

How context reaches a run is decided by what the owner said, not by an argument they must remember:

- **Clean room** — any read-restriction language. **[EXAMPLE]** "READ ONLY THIS", "BASED ON ONLY THESE DOCS",
  "DO NOT READ ANYTHING ELSE", "or something to that effect". Missing this corrupts the run with exactly the
  material the owner was excluding, so ambiguity resolves toward restriction.
- **Carried** — the conversation already holds reasoning that matters, so the run inherits it. Both runtimes
  can fork a conversation into a spawned agent (Appendix).
- **Discovered** — the default. The agent follows relevant docs, concepts, designs, reviews, ADRs, code,
  tests, and history by relevance to the question.

**[OWNER]** Clean room means a fresh agent, not a fork, because a fork inherits every document already pulled
into the conversation — unless the owner says to use what was just discussed and read nothing new. Nothing
enforces it, which the skill says out loud. Under every policy the output names its evidence and its gaps.

### 5. Output Shape, One Location

The synthesis always carries a metadata section and a judgment section; the shape decides where they go. A
**checkpoint** renders both into the HTML. Otherwise the HTML is a plain document and the judgment is read
back in the terminal. Nothing else differs: same synthesis, same visuals, same location, same safety rules.
Visual forms fit the question — data models, flows, mockups, principles, invariants are examples, not required
sections. Nothing lands in `docs/`; promotion there is the owner's act.

### 6. Snapshot, Not Parallel Authority

Each committed HTML reflects the evidence available when generated and is not a second canonical model. Later
runs regenerate from current evidence, feedback stays attributable to the version it reviewed, and
owner-originated decisions keep their provenance when visualized.

### 7. Two Feedback Bodies, Two Tiers, Manual Promotion

The two bodies are synthesizing and communicating design, and rules for building a good HTML. Each has two
tiers: a starter body ships inside the skill, git-tracked here and symlinked on install so lessons cross
projects, and a project-local body is where new feedback always lands first. A run reads the shared body then
the project one. Promotion happens only when the owner asks, and targets the shared feedback file rather than
the instruction files, which stay the contract. Because the shared body sits in the git-tracked pack, a
promotion arrives as an uncommitted edit the owner reviews and rewrites before committing — which is the
point, since agent-written feedback usually needs that rewrite to be general enough to share.

---

## Scope of Behavior Changes

### New artifacts and capabilities

- **[OWNER]** `claude-pack/skills/_my_mental_model/` — a Claude *skill* directory, not a command, holding
  `SKILL.md` (the user-invoked entry, functionally identical to today's command), `design_synthesis.md`, and
  `visualize.md`. This is the first `_my_*` skill and sets the pattern for migrating the rest later.
- **[OWNER]** Shared starter feedback in that directory: `feedback/synthesis.md`, `feedback/html.md`.
- **[OWNER]** Project-local feedback at `.project/mental-alignment/feedback-synthesis.md` and
  `feedback-html.md`, written first whenever a run gets feedback.
- **[OWNER]** A markdown synthesis file per run, paired to its HTML.
- **[OWNER]** A switch for where the HTML gets built — same agent resumed, or fresh second agent — both shipping.
- **[AGENT] (ratified by owner, 2026-08-09)** The `runs/` location under `.project/mental-alignment/`.
- **[INHERITED: docs/STRUCTURE.md]** Claude and Codex distributions still derive from shared authored sources.

### Existing artifacts to remove or modify

- **[OWNER]** Delete `claude-pack/scripts/mental-model-builder.md`; its content splits into the two new
  instruction files. `claude-pack/commands/_my_mental_model.md` retires in favor of the skill.
- **[AGENT]** The Codex build needs three changes to ship a directory skill with supporting files, and
  `$ARGUMENTS` stops applying. Call sites and line references are in the Appendix.
- **[OWNER]** Concept-design and epic-plan keep offering a checkpoint at their existing boundaries, unchanged.
- **[AGENT] (ratified by owner, 2026-08-09)** Shaping-tier product design stays discoverable to concept-design
  and epic-plan, without becoming a mandatory source.
- **[AGENT]** Command catalogs, distribution, and workflow checks change only as needed to expose this.

### Behavior changes by workflow stage

- **Any time:** The owner asks in their own words; the skill states its read, then records feedback on request.

---

## Non-Goals / Out of Scope

- **[OWNER]** Out of scope: automatic generation across the pipeline, a mandatory catalog of visuals, the
  skill writing into `docs/`, and flags or named arguments of any kind.
- **[OWNER]** Migrating the other commands to skills and relocating the existing prose specs out of
  `claude-pack/scripts/` are out of scope; this skill sets the precedent and the sweep comes later. So is
  sequencing beyond two steps, and feedback outside git tracking — a shared file in an untracked home
  directory was considered and rejected, because promoted feedback needs review.
- **[OWNER]** Automated checks are out of scope — no quality fixtures and no mechanical ones either, since a
  noisy suite gets ignored. The owner judges quality; the two feedback bodies are the improvement loop.
- **[AGENT]** Replacing concept-design review, product-lens checks, design review, or audit is out of scope;
  this serves comprehension, not certification. Status dashboards are separate. Deferred: a continuously
  synchronized living explainer, and continual learning for every skill.

---

## Assumptions & Prerequisites

- `.project/` is tracked and holds the committed HTML, synthesis files, and feedback; each step can read what
  it needs and write in the project.
- The shared pack stays the authored home for cross-project behavior. `setup-global.sh` already symlinks whole
  skill directories, and typing `/<skill-name>` invokes a skill, so the migration keeps today's invocation.
- Output may be useful even when context is incomplete or conflicting, provided the limitation is visible
  rather than filled with invented certainty.

## Open Questions

1. **Resolved by spike (2026-08-20):** `[AGENT]` Codex can continue a completed spawned agent through a
   follow-up task, with conversation continuity proven by a retained-nonce check. The resumed shape can ship.
   The observed collaboration results expose no per-agent token count, so comparison measurement still needs
   a supported source or must be reported as unavailable on Codex. See
   `.project/active/codex-resume-spike/spike-findings.md`.

---

## Next-Stage Handoff

**Settled earlier and still standing:**

- **[OWNER]** (2026-08-09) HTML, generated on demand; visual forms fit the question rather than a template;
  only concept-design and epic-plan actively suggest a checkpoint; runs and feedback are committed.
- **[OWNER]** (first pass) Three named steps, synthesis as the thinking piece with its own markdown output;
  two feedback bodies; three context policies; one fixed HTML location, promotion to `docs/` the owner's job.

**Settled (2026-08-19, second pass — the shape):**

- **[OWNER]** No flags: policy and shape are classified from the request, and the skill states its read first.
- **[OWNER]** Clean room means a fresh agent, not a fork, unless the owner says to use what was just discussed
  and read nothing new.
- **[OWNER]** The synthesis is the skeleton — high-level logic, narrative, maximum compression. The HTML
  inherits that narrative and adds a second layer of detail: "I DO NOT WANT THE HTML JUST TO BE THE SAME
  WORDS IN A DIFFERENT FORMAT".
- **[OWNER]** (2026-08-20) Every run pauses on the synthesis, and the owner picks there: resume the same
  agent, use a fresh one, or run both on one synthesis for two comparable HTMLs. So a synthesis may pair with
  more than one HTML, and the switch needs no flag or stored setting.
- **[OWNER]** The unit is a skill directory, `claude-pack/skills/_my_mental_model/`, holding the entry point
  plus `design_synthesis.md` and `visualize.md`. `/_my_mental_model` stays the entry, unchanged in function.
- **[OWNER]** `claude-pack/scripts/mental-model-builder.md` is deleted.
- **[OWNER]** Feedback: shared starter bodies in the skill directory, project-local written first, promotion
  manual and owner-initiated, targeting the shared feedback file.
- **[OWNER]** (2026-08-20) No automated checks of any kind — the owner judges quality, feedback is the loop.
- **[OWNER]** (2026-08-20) Collection gets no instruction file: the coordinating agent composes the policy
  into the spawn prompt, and a fork makes it moot. **[AGENT] (ratified)** short and situational goes in the
  prompt, long and improvable goes in a file the spawned agent reads.
- **[AGENT]** Carried context is a fork, not a transcription; the mechanism exists in both runtimes.

**Superseded (2026-08-19, owner-directed):**

- "Context construction stays flexible rather than a strict source list" and "a strict source allowlist is out
  of scope" → the context policy; "the main agent delegates construction to a specialized subagent" → the
  switch, over two named steps.
- "Every checkpoint separates the mental model from agent concerns" → amended: separation holds in both shapes;
  the shape decides whether judgment renders or is spoken.
- "The owner selects context policy and output mode as inputs" → classification from the request; and "a
  command in `claude-pack/commands/`" → a skill directory.

**Needs spec next:**

- Each step's inputs, outputs, boundaries, and what the synthesis contains per section.
- Classification rules for policy and shape, and what the skill prints before spawning.
- How source authority, judgment, uncertainty, and snapshot age stay legible in both shapes.
- The Codex build changes, whether Codex can resume a spawned agent, and where the wall-clock, token, and
  quality readings from a comparison get recorded.
- The two feedback bodies across two tiers, and promotion against the existing single ledger.

**Decomposition guidance:**

- Independently verifiable slices: synthesis, render, classification, the switch and its comparison, feedback
  tiers, and the skill-directory migration with its build changes. This warrants an epic.
- Synthesis is the highest-value slice; the build changes are ordinary code and gate Codex parity.

---

## Appendix (does not count toward the main-body budget)

### Resolved at implementation (2026-08-09), previously open

The command name (`/_my_mental_model`), run metadata, promotion when the authored source is unreachable, and
new-file-per-run regeneration.

### Implementation notes (2026-08-19), referenced from the main body

- **Fork mechanism (carried policy).** `subagent_type: "fork"` on Claude, `fork_turns: "all"` on Codex
  (`codex-overrides/rules/collaboration.md`).
- **Resume precedent (the same-agent shape).** `claude-pack/scripts/orchestrate-stage.sh` runs a headless
  `claude -p` agent, captures its `session_id`, resumes it with a message from stdin, and returns `cost` on
  stdout — which is also the token measure the comparison needs.
- **Deleting the builder.** Referencing sites for `claude-pack/scripts/mental-model-builder.md`:
  `_my_mental_model.md`, `build-codex-pack.sh:138` and `:426`, `codex-overrides/config.sh:37`, and the
  regenerated `dist/`. Retiring the command also touches `README.md:131` and `scripts/test_docs.sh`.
- **Codex build changes for a directory skill.** Copy sibling files, which `build-codex-pack.sh:400` and
  `setup-codex.sh:267` do not (both walk only `SKILL.md`); add an entry to `NATIVE_SKILL_ALLOWLIST`
  (`codex-overrides/config.sh:58`), since native skills are opt-in where commands are automatic; and apply the
  `_my_x` → `my-x` name mapping so the Codex name stays `my-mental-model`. `$ARGUMENTS` does not apply in a
  skill; the entry point reads the request as text.

### Owner's Words — 2026-08-20 (no checks)

- **[OWNER-VERBATIM]** "I'm not sure if I see much value in mechanical checks at all. even something like \"every section aligns\" is gonna create more noise than it may be worth. I'm leaning (d), none of the above"
- **[OWNER-VERBATIM]** on a secret scan: "I think this particular command has the least risk of a secret. but that is a good idea in general" — moved to `BACKLOG.md` as **[BL-009]**, out of scope here.
- **[OWNER-VERBATIM]** "then go with (d) with nothing at all"

### Owner's Words — 2026-08-20 (pause, switch, and instruction placement)

- **[OWNER-VERBATIM]** on always pausing before the HTML is built: "yes, let's start with (a)"
- **[OWNER-VERBATIM]** on choosing the execution shape at the pause: "(a). this is the easiest. to address the \"bad\": we said for the foreseeable future we will always pause, so no cost / we we want to remove the pause, we will have to decide the default policy anyway / in the future, we could even have our cake and eat it too: a front-loaded \"don't pause\" could have (via prompt) a default answer to this question"
- **[OWNER-VERBATIM]** "FURTHERMORE (important to capture) I am assuming that a smart agent will allow me to say: \"actually I want to A/B test this -- please resume the existing agent and ask for one file name, and also kick off a fresh agent to produce a different file name\""
- **[OWNER-VERBATIM]** on where collection instructions belong: "wouldn't it be cleaner/easier just to have the MAIN AGENT pass the relevant instructions to the synthesis agent as appropriate? because if the answer is FORK, then its a non-issue."

### Owner's Words — 2026-08-20 (execution shapes)

- **[OWNER-VERBATIM]** "HTMLs can carry a lot of information quite densely. which means to get a good HTML, you need a LOT of information in the markdown. I would suggest that is the OPPOSITE of what we want. You want the markdown to be the simplest view, you want it readable. It's more like the markdown is the logic and skeleton, and then the HTML fills in the details and presents them in visuals."
- **[OWNER-VERBATIM]** "synthesis.md = skeleton. the high level logic. the narrative. the way you structure the information for maximum compression. HTML = the meat. it sits on the same skeleton, but adds detail and helps further the understanding with specifics."
- **[OWNER-VERBATIM] [EXAMPLE]** synthesis => HTML: "here are the three categories of methods" => "here are the three categories, and which methods fall under each" / "we reduce things to two data models" => "two data models, here are the forms" / "here is a flow mermaid diagram" => "here is a full diagram, where we have labels and notes to add a second layer of explanation"
- **[OWNER-VERBATIM]** "the HTML should inheret the narrative, but add the second layer of detail since using the capabilities of HTML (visuals, drop down boxes, coloring) you can compress more information in a way that is not overwhelming for humans to understand"
- **[OWNER-VERBATIM]** "**I DO NOT WANT THE HTML JUST TO BE THE SAME WORDS IN A DIFFERENT FORMAT**"
- **[OWNER-VERBATIM]** "the real trade-off is: two agents: second agent has to rediscover a lot of the information, but starts fresh. likely slower / one agent: has the context. larger starting window, maybe with more noise, but should be faster"
- **[OWNER-VERBATIM]** "look at the orchestration -- we have the ability to coordinate multiple agents using headless."
- **[OWNER-VERBATIM]** "I'm actually now genuinely curious which works better. and I think it should be easy enough to manage via a switch that we shouldl capture both options in the concept doc, and then A/b test a few times (wall clock time, tokens consumed, and my assessment of artifact quality) ... let's carry both forward."

### Owner's Words — 2026-08-19 second pass (the shape)

- **[OWNER-VERBATIM]** "I do not like strict arguments. no one ever remembers what they are."
- **[OWNER-VERBATIM] [EXAMPLE]** "If the user says \"READ ONLY THIS\" or \"BASED ON ONLY THESE DOCS\" or \"DO NOT READ ANYTHING ELSE\" or something to that effect --> cleanroom"
- **[OWNER-VERBATIM]** "If not cleanroom, you already have classification for forking or not"
- **[OWNER-VERBATIM]** "\"Mode\" should also be classified based on context. this is not that important, just \"if this is a checkpoint of a design concept, include this metadata\"."
- **[OWNER-VERBATIM]** "HTMLs can carry a lot of information quite densely. which means to get a good HTML, you need a LOT of information in the markdown. I would suggest that is the OPPOSITE of what we want. You want the markdown to be the simplest view, you want it readable. It's more like the markdown is the logic and skeleton, and then the HTML fills in the details and presents them in visuals."
- **[OWNER-VERBATIM] [EXAMPLE]** details the HTML can embed efficiently: "Shape of a method or API" / "Data models" / "Full sequence diagram" / "Artifact says \"three classes of functions\", HTML actually lists the functions in those three classes"
- **[OWNER-VERBATIM]** "I need git tracking. 95% of the time the feedback an agent writes is REALLY bad and needs a revision to be generalized and useful."
- **[OWNER-VERBATIM]** "in the agentic-project-init, we should have a \"starter pack\" feedback file. it is unpacked and symlinked. ... they is a separate project-specific feedback file -- this is what gets updated first ... any promotion/sharing is done manually by initiation of the user: \"this feedback is valuable, please move it to the shared feedback\""
- **[OWNER-VERBATIM]** on where a promoted lesson lands (shared feedback file, not the instruction file): "this. definitely."
- **[OWNER-VERBATIM]** "I recognize this is slightly breaking a pattern, but this feels like the right time to start migrating the Claude \"commands\" to skills."
- **[OWNER-VERBATIM]** "keep `/_my_mental_model` as the user-invoked command/skill (identical in functionality)" ... "design_synthesis.md and visualize.md would go in the same directory"
- **[OWNER-VERBATIM]** "we should delete `mental-model-builder.md`"
- **[OWNER-VERBATIM]** on the shared feedback bodies living in the skill directory: "yes -- shared feedback should go there."
- **[OWNER-VERBATIM]** on relocating the existing prose specs out of `claude-pack/scripts/`: "ok let's deal with the old stuff later"

### Owner's Words — 2026-08-19 first pass (the three steps)

- **[OWNER-VERBATIM]** "First, there is the \"collect context\" ... Second, there is a \"figure out the right abstractions\" ... Third, there is \"generate a visual-first HTML to convey the abstractions\" ... And then on top of this, there are particulars about the context for the need (this is a checkpoint)"
- **[OWNER-VERBATIM]** "the other questions are: *who* does *what* (agents, subagents) ... *where* does it go"
- **[OWNER-VERBATIM]** "I had, in anticipation of this, talked through some architectural questions with the agent. But then the forced hand-off to a subagent meant I got almost none of that in the artifact."
- **[OWNER-VERBATIM]** "the artifact was forced into a checkpoint look anyway, ignoring the context I gave it"
- **[OWNER-VERBATIM]** "sometimes I intentionally LIMIT automatic fetching of context so as not to corrupt the agent with data that is old, out of date, or poorly written. I enage in \"clean room\" agent thinking to get different outcomes."
- **[OWNER-VERBATIM]** "I want a growing feedback specifically for the \"abstraction thinking\" -- this can be useful for technical communication generally"
- **[OWNER-VERBATIM]** "And then the visuals/HTML building has its own stuff, including lots of \"checklist\" material for common failure modes"
- **[OWNER-VERBATIM]** "I want the default location to ALWAYS be the same for the HTML. promotion to `docs/` is the responsibility of the user."
- **[OWNER-VERBATIM]** "I have found that loading up a simple prompt with a 5-step process promotes laziness. almost always, the first steps are executed mechanically: just execute the required actions. but almost no *intenal thinking* is put into it. It's like once an agent knows what the final deliverable is, it will focus on that rather than all the steps equally."
- **[OWNER-VERBATIM]** "the \"think through the architecture and abstractions\" is always breezed through. and the work product sucks. if I MANUALLY ask it to think through the abstractions, and THEN get it to build an artifact, I get better results."
- **[OWNER-VERBATIM]** "I'd be interested in looking at ways to build multi-pass skills like this, e.g. with hooks or something."
- **[OWNER-VERBATIM]** "I was thinking a pattern where: [Prompt 1] -> [Agent] -> [Result 1] -> [Prompt 2] -> [Agent] -> [Result 2] could be handled automatically. anecdotally, I have notices this works better than: [Prompt 1 + Prompt 2] -> [Agent] -> [Result 1 + Result 2]"
- **[OWNER-VERBATIM]** "we can start with the latter and split later and test (if possible)"

### Owner's Words — 2026-08-09 shaping conversation

- **[OWNER-VERBATIM]** "The artifacts tend to get long and detailed, so in reality I am not going to be able to review each one."
- **[OWNER-VERBATIM]** "then yes actually putting the artifacts in context and understanding the whole system is the pain point."
- **[OWNER-VERBATIM]** "I would say \"mental alignment\"."
- **[OWNER-VERBATIM]** "Misalignment in what the product should be doing"
- **[OWNER-VERBATIM]** "Bad decisions on architecture; slop"
- **[OWNER-VERBATIM]** "Me losing a conceptual understanding of how the codebase works, meaning small issues can magnify to big ones because I cannot do reviews and spot checks"
- **[OWNER-VERBATIM]** "maybe it should only be done upon request. A sort of \"mental alignment checkpoint\" where the agent goes and builds this artifact to put whatever the question is in context of the whole system."
- **[OWNER-VERBATIM]** "Important: I expect this to evolve -- a lot of what \"good\" looks like is very particular."
- **[OWNER-VERBATIM]** "We may want to think through the feedback mechanism (agent is sitting in a particular project, but feedback needs to land in a shared location)"
- **[OWNER-VERBATIM]** "we also should not be that strict about the \"sources\" -- leave flexibility for the agent to construct the relevant context" *(superseded 2026-08-19 — see the context policy; discovery remains the default)*
- **[OWNER-VERBATIM] [EXAMPLE]** "data models" / "data flows" / "mock-ups" / "call out the major principles and design invariants"
