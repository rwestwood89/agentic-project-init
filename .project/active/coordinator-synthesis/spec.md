# Spec: Coordinator + Synthesis Step (Claude)

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-20
**Complexity:** MEDIUM
**Branch:** anchor-on-the-point

---

## Problem

The mental-alignment checkpoint's v1 failed because one agent got one instruction set covering
discovery, thinking, and rendering. It raced to the HTML, skipped the thinking, dropped the
owner's conversation reasoning, and forced one output shape. The concept-design's repair is a
two-agent, one-pause skill where the thinking step gets its own agent whose prompt ends at a short
written synthesis — so the thinking actually happens.

This item builds the first half: the coordinator that classifies the request and spawns the
synthesis agent, and the synthesis agent that thinks and writes. Together they produce a readable
synthesis markdown at a mandatory pause, and nothing else. The render step, the switch, and the
feedback system are Item 4; packaging for Codex is Item 5.

This is also the first directory skill with sibling instruction files. Every future skill migration
depends on the pattern this item proves: a `SKILL.md` entry point that reads a flat sibling
(`design_synthesis.md`) and a nested sibling (`feedback/synthesis.md`), resolved by
`/_my_mental_model`, installed by `setup-global.sh`'s existing whole-directory symlink
(`setup-global.sh:126-134`).

Governing obligation, re-derived from concept SC2–SC5, SC12.

The owner asks a question and gets a visual reconstruction of the relevant system, built through
three independently instructable steps. Every run pauses after the synthesis, where the owner
reads, corrects, and chooses the render path. Policy and shape are classified from the request —
no flags. The synthesis is the skeleton: narrative logic clear enough that a reader can judge
whether the thinking is sound without the details, progressing in no more than 5–6 logical steps,
important things first. Judgment stays visibly separate from evidence claims.
[source: concept SC2–SC5, SC12–SC13; owner-verbatim on skeleton and narrative logic, grade: `[OWNER]`]

## Success Criteria

- [ ] **SC1**: A question produces a synthesis markdown at `.project/mental-alignment/runs/` with
  narrative, metadata, and judgment sections — before any HTML exists
- [ ] **SC2**: The coordinator states its classification (policy + shape) in the conversation
  before spawning the synthesis agent
- [ ] **SC3**: Under carried policy, the synthesis agent is a fork and the owner's conversation
  reasoning reaches the synthesis output
- [ ] **SC4**: Under clean-room policy, the synthesis agent is fresh, the restriction is restated
  in its prompt, and the coordinator states that nothing enforces it
- [ ] **SC5**: Under discovered policy (the default), the synthesis agent is fresh and explores
  by relevance to the question
- [ ] **SC6**: Every run pauses after the synthesis is presented; no HTML is built. The synthesis
  agent's prompt contains no instruction to produce an HTML
- [ ] **SC7a**: `/_my_mental_model` resolves to the skill directory on Claude — the slash name
  invokes the coordinator in `SKILL.md`
- [ ] **SC7b**: The synthesis agent can read its instruction file (`design_synthesis.md`) and the
  nested feedback file (`feedback/synthesis.md`) during a run
- [ ] **SC7c**: The working form of the sibling reference is confirmed against the spike's
  measured result and recorded, because every future skill's instruction files depend on it
- [ ] **SC8**: The shared starter feedback file (`feedback/synthesis.md`) ships with a header and
  stated purpose; it fills from real runs, not agent-invented content

## Known Requirements

### Skill directory structure

- **[INHERITED: concept-design §Core Model]** The skill lives at
  `claude-pack/skills/_my_mental_model/` with three authored files: `SKILL.md` (coordinator),
  `design_synthesis.md` (synthesis instruction), and `feedback/synthesis.md` (shared starter
  feedback body).
- **[INHERITED: concept-design §Distribution lane]** `setup-global.sh` already symlinks whole
  skill directories (`setup-global.sh:126-134`); no script change is needed for the Claude
  install. The frontmatter has `name` and `description` fields; `description` must be plain prose
  (no leading `*`, which crashes Codex YAML parsing — carried from the concept-design, relevant
  at Item 5).

### Classification

- **[NEED]** The coordinator classifies context policy and output shape from the request and
  states its read before acting, so a wrong classification is caught in one exchange.
- **[NEED]** Context policy: *carried* (the conversation holds reasoning that matters), *discovered*
  (the default — explore by relevance), or *clean room* (any read-restriction language).
- **[NEED]** Output shape: *checkpoint* (run metadata and judgment render into the HTML) or *plain
  document* (judgment read back in terminal). Shape classification is low-stakes — the concept
  says "not that important" — so it needs no confirmation step.
- **[NEED]** Clean-room detection resolves ambiguity toward restriction, because reading excluded
  material corrupts exactly what the owner was protecting.
- **[NEED]** The combination "use what we just discussed and read nothing new" is carried
  policy with a clean-room restriction: a fork, with a read-nothing-new instruction. The
  coordinator states this compound classification.

### Agent spawning

- **[INFERRED]** Carried policy uses a fork (`subagent_type: "fork"` on Claude). The fork
  inherits the conversation, so the owner's reasoning arrives without re-derivation.
- **[NEED]** Discovered policy: a fresh agent (not a fork). Explores by relevance to the question.
- **[NEED]** Clean-room policy: a fresh agent (not a fork) with the restriction restated in its
  prompt. The coordinator states that nothing enforces the restriction — same trust level as the
  concept's "unenforced, which the skill says out loud."
- **[INHERITED: concept-design §Design Principles §5]** Short and situational (question, policy,
  target path) travels in the spawn prompt. Long and improvable (how to synthesize) lives in
  `design_synthesis.md`, which the spawned agent reads.

### Synthesis agent behavior

- **[NEED]** The synthesis agent reads `design_synthesis.md` plus both synthesis feedback bodies
  (shared starter at `feedback/synthesis.md`, project-local at
  `.project/mental-alignment/feedback-synthesis.md` if it exists; absence is empty, not an error).
- **[NEED]** The synthesis agent discovers evidence per its policy, then writes exactly one file:
  `.project/mental-alignment/runs/{YYYYMMDD-HHMMSS}_{slug}.md`.
- **[NEED]** The synthesis agent's prompt contains no instruction to produce HTML and no reference
  to `visualize.md`. Its job ends at the synthesis file.

### Synthesis file structure

- **[NEED]** The synthesis file has three mandatory regions: metadata, narrative, and judgment.
- **[INFERRED]** **Metadata** (top): question verbatim, date, context policy, output shape,
  evidence consulted (list of files/sources), code inspected (what, or "not inspected"),
  limits/gaps (what wasn't examined).
- **[INHERITED: concept-design §Core Model]** **Narrative** (middle): the skeleton — each
  section states its claim, the claim's provenance, the visual form that fits it (for the render
  step to act on), and a pointer to where the underlying detail lives. Structure chosen per
  question, not templated. The HTML (Item 4) inherits this narrative and adds the detail layer.
- **[NEED]** **Judgment** (bottom): the agent's own material, visibly separated from claims
  carried from evidence. Concerns, unresolved uncertainty, disagreements between sources,
  suggested spot checks.
- **[INFERRED]** The filename's `{slug}` is derived from the question by the synthesis agent —
  a short, filesystem-safe summary.

### Synthesis quality standard

- **[NEED]** The synthesis is readable and interpretable by someone familiar with the overall
  project, but contains none of the details.
- **[NEED]** The narrative progresses in no more than 5–6 logical steps from introduction to
  conclusion. Important things come first — the reader should be able to stop at any point and
  have gotten the most important content so far.
- **[NEED]** Narrative logic must be clear. Any smart person can read the synthesis and tell
  whether the thought process is sound, without the details. This is what "skeleton" means — the
  abstractions and compression of what is being presented.
- **[NEED]** The narrative body is no longer than 150 lines. Additional information deemed
  important goes in an appendix, which does not count toward the line limit. The body is what
  the narrative-logic test applies to. The metadata header and judgment section also sit outside
  the 150-line count.

### Instruction-file reachability

- **[NEED]** The synthesis agent can reach `design_synthesis.md` and `feedback/synthesis.md`
  during a run. The mechanism is design's call — the coordinator has access to the skill's base
  directory and composes the spawn prompt.
- **[INHERITED: epic MENTAL-ALIGN-V2 Item 3 In Scope; evidence spike-findings A8, B5]** Every
  sibling reference in authored files is written as a bare filename in prose —
  `design_synthesis.md`, `feedback/synthesis.md` — never as a path containing the skill's own
  directory name. This is the forward-compatibility obligation that keeps Item 5 from needing a
  rewrite pass it is forbidden to have (ADR 0010).

### The pause

- **[NEED]** The coordinator presents the synthesis markdown to the owner after the synthesis
  agent completes. This is the mandatory pause: the owner reads, corrects if needed, and chooses
  the render path.
- **[NEED]** At the pause, the coordinator offers the render choice: resume the same agent, use
  a fresh one, or both for comparison. (The render paths are Item 4's implementation; this item
  presents the choice and stops.)

### Run directory

- **[INHERITED: concept-design §Run artifacts]** All run output lands under
  `.project/mental-alignment/runs/`. The coordinator creates the directory if it doesn't exist.
  Files are never overwritten; timestamp collisions get a new timestamp.
- **[INFERRED]** Synthesis and HTML are paired by filename stem — the simplest transparent
  mechanism. One synthesis may carry multiple HTMLs with suffixed names. (Item 4 confirms or
  amends this choice when it specifies the HTML naming.)

## Non-Goals

- The render step, the render switch, and the comparison mechanism (Item 4).
- `visualize.md`, HTML feedback body, feedback recording, and the promotion workflow (Item 4).
- Anything Codex: the allowlist entry, the name mapping, the sibling build/install lane,
  runtime-neutral phrasing enforcement (Item 5).
- Automated quality checks on the synthesis — the owner judges; feedback is the loop.
- The exact prose content of `design_synthesis.md` — an authored deliverable, not a spec-level
  requirement. The spec requires it exists and serves its stated purpose; its content is
  constrained by the synthesis quality standard above.
- The prose content of `feedback/synthesis.md` beyond the header — it fills from real runs.

## Open Questions / Deferred to design

- **Spawn-prompt composition details.** What exactly goes in the prompt beyond question, policy,
  target path, and the resolved instruction-file paths. Design's call.
- **Exact classification wording.** What the coordinator prints. The requirement is that it states
  its read; the wording is design.
- **Whether the synthesis agent should have tool restrictions.** The concept-design doesn't
  restrict tools; the synthesis agent needs file reads, code reads, and file writes. Design's call
  on whether to constrain further.
- **The narrative's internal structure conventions.** Whether `design_synthesis.md` prescribes
  section types (e.g., "system shape," "key abstractions," "flows") or leaves the structure
  entirely to the agent per question. Whatever structure it offers must serve the 5–6 step
  progression and the cut-off-at-any-point ordering from the synthesis quality standard.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2, Item 3)
- **Required Reading:**
  - `.project/concepts/mental-alignment-checkpoint.md` — concept (SC1–SC5, SC8–SC11, SC13; Key Concepts §1–§4)
  - `.project/concepts/mental-alignment-skill-design.md` — concept-design (Core Model, Design Principles §1–§2, Flow)
  - `.project/active/directory-skill-build-pattern/spike-findings.md` — sibling-reference mechanics (A8, B5: read before authoring instruction files)
- **Concept-design review:** `.project/concepts/mental-alignment-skill-design-review.md`
- **Product lens:** `.project/active/coordinator-synthesis/product-lens.md`
- **Design:** `.project/active/coordinator-synthesis/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
