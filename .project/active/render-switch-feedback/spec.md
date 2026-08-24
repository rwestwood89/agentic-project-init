# Spec: Render + Switch + Feedback (Claude)

**Status:** Implemented 2026-08-20 — first validation run passed (resumed path, clean room, checkpoint shape)
**Owner:** Reid W
**Created:** 2026-08-20
**Complexity:** MEDIUM
**Branch:** anchor-on-the-point
**Epic:** MENTAL-ALIGN-V2, Item 4

---

## Problem

The coordinator and synthesis step (Item 3) works: a question produces a synthesis markdown at a
mandatory pause, and the owner picks a render path. But the pause is a dead end. The render paths
don't exist, so neither does the visual layer that makes the synthesis actionable, the comparison
that would tell the owner which path produces better results, or the feedback system that would
improve future runs.

This item builds everything past the pause: the two render paths (resumed agent, fresh agent), the
owner's switch between them, the comparison mechanism, and the two-tier feedback system with
manual promotion. Together with Item 3, this completes the full end-to-end flow on Claude.

Governing obligation, re-derived from concept SC1, SC3, SC7, SC12; concept-design Design
Principles §3, Core Model.

The HTML inherits the synthesis narrative and adds a second layer of detail using what HTML can
do — visuals, disclosure, color — so it is never the same words in a different format. The owner
picks the render path at the pause: resume the same agent (faster, noisier window), use a fresh
one (clean window, re-earns the understanding), or both on one synthesis for a side-by-side
comparison measured on wall-clock time, tokens, and the owner's read of quality. Feedback
improves future runs through two bodies (synthesis, HTML) across two tiers (shared starter,
project-local), with manual promotion.
[source: concept SC1, SC3, SC7, SC12; owner-verbatim on skeleton/meat and comparison; grade: `[OWNER]`]

## Success Criteria

Every criterion here is verified by a manual run — see the design's Validation Approach
(`design.md`, nine numbered runs). One run has happened, and it covered more than one criterion.

**Run V1 — 2026-08-20, resumed path, clean-room policy, checkpoint shape.** Run in
`echo-workspace`, not this repo, through the global symlink install. Artifacts:
`/home/rwestwood/echo-workspace/.project/mental-alignment/runs/20260820-152840_lofi-runner-architecture.md`
and its `_resumed.html`. Owner's verdict: *"it worked … got my artifact."* What the artifacts show:

- The HTML is paired by stem, suffixed `_resumed`, 78 KB against a 27 KB synthesis.
- **The detail layer is real and labelled.** 17 spots marked `render addition`, 11 tables, 3 inline
  SVG. The render went after exactly the four claims the synthesis had flagged as
  cited-not-verified, and its "Sources this page drew on" footer separates what it inherited from
  the owner's named sources from the four external sources it read for the detail layer.
- **Clean-room default behaved as D9 says.** The owner took the default rather than the override,
  and the HTML states it on its face: *"Clean room for the synthesis … Unrestricted for this
  render."*
- Checkpoint shape rendered the metadata block and the judgment, visibly separate.
- Safety limits held: no `<script>`, no event handlers, no `iframe`/`object`/`embed`, no remote URLs.
- Step 7 wrote its `# Renders` block — `wall clock: 10m 44s`, `tokens: not measured`,
  `owner quality: not asked`.

Untested after V1: the fresh path, the comparison, plain-document shape, the correction gate,
feedback recording, and promotion.

- [x] **SC1**: The resumed render path produces a standalone HTML file that opens in a browser
  and presents the intended content, paired to its synthesis — the same agent that wrote the
  synthesis reads `visualize.md`, the HTML feedback bodies, and builds the HTML
  — *V1. The render's source footer, its `render addition` labelling, and its safety compliance are
  all `visualize.md` behaviours, so the instruction file was read.*
- [ ] **SC2**: The fresh render path produces a standalone HTML file that opens in a browser
  and presents the intended content, paired to its synthesis — a new agent reads the synthesis,
  `visualize.md`, the HTML feedback bodies, and builds the HTML
- [x] **SC3**: The HTML inherits the synthesis narrative and adds a detail layer — not the same
  words in a different format. Skeleton sections become populated: categories with their members,
  data models with their forms, flow diagrams with labels and notes
  — *V1, on the owner's read plus 17 labelled `render addition` spots and four external sources read
  for detail the synthesis did not carry.*
- [ ] **SC4**: Under checkpoint shape, metadata and judgment render into the HTML; under plain
  document shape, they are omitted from the HTML and the coordinator reads the judgment back
  in the terminal
  — *checkpoint half confirmed by V1; the plain-document half and the terminal read-back are
  untested.*
- [ ] **SC5**: Comparison produces two distinct HTMLs from one synthesis, with wall-clock time
  reported for each, the token story stated honestly per runtime (reported if available,
  "not measured" if not), and the owner's quality assessment preserved per HTML
- [ ] **SC6**: New feedback lands in the project-local feedback file — synthesis feedback
  attributed to the synthesis/run, HTML feedback attributed to the specific HTML version
- [x] **SC7**: `visualize.md` and `feedback/html.md` ship with the skill in the existing
  directory at `claude-pack/skills/_my_mental_model/`
- [ ] **SC8**: Promotion targets the shared feedback file in the skill directory; copy-install
  promotion (Codex, vendored Claude) fails closed by recording the candidate project-locally
- [x] **SC9**: The render agent can reach `visualize.md` and `feedback/html.md` during a run
  — *V1, and through the harder path: a different repository reaching the pack by directory
  symlink.*
- [ ] **SC10**: When the owner corrects the synthesis at the pause, the correction updates the
  saved synthesis file before either render path starts — both paths consume the same
  corrected authority

## Known Requirements

### Render agent and the HTML

- **[NEED]** The HTML inherits the synthesis narrative and adds the detail layer: what the
  synthesis compresses, the HTML expands using what the medium can do — visuals, disclosure
  elements, color, layout. The synthesis names the visual form that fits each section; the
  render agent acts on those cues.
  [source: concept SC3, owner-verbatim "synthesis.md = skeleton … HTML = the meat"]
- **[NEED]** The HTML must not restate the synthesis in a different format. The synthesis is the
  skeleton; the HTML adds the second layer. If the synthesis already has the detail, the HTML
  has nothing to add.
  [source: owner-verbatim "I DO NOT WANT THE HTML JUST TO BE THE SAME WORDS IN A DIFFERENT FORMAT"]
- **[NEED]** Checkpoint shape: the synthesis's metadata section and judgment section render into
  the HTML. Plain document shape: the HTML omits them, and the coordinator reads the judgment
  section back in the terminal after the render completes.
  [source: concept SC5, concept-design §Core Model]
- **[INHERITED: concept-design §Required Invariants]** Every HTML resolves to exactly one
  synthesis; one synthesis may pair with many HTMLs. A synthesis file exists on disk before any
  HTML sharing its stem.
- **[INHERITED: concept-design §Core Model]** Safety posture is instructional, not verified: no
  active content, no undisclosed remote resources, no secrets. Same trust level as clean room.

### The render agent's instruction files

- **[INHERITED: concept-design §Design Principles §5]** `visualize.md` is the long, improvable
  instruction file the render agent reads — the same pattern as `design_synthesis.md` for the
  synthesis step. Its content is an authored deliverable, not a spec-level requirement.
- **[NEED]** The render agent reads `visualize.md` plus both HTML feedback bodies (shared at
  `feedback/html.md`, project-local at `.project/mental-alignment/feedback-html.md`). Absence
  of the project-local file is empty, not an error.
- **[NEED]** The render agent can reach its instruction and feedback files during a run. How
  the coordinator makes the paths available is design's call.
  [source: Item 3 spec-review L1-4 resolution — "state the outcome, leave the mechanism to
  design"; spike-findings A8]
- **[INHERITED: epic Item 3 In Scope; spike-findings A8, B5]** Every sibling reference in
  authored files is written as a bare filename in prose — `visualize.md`, `feedback/html.md` —
  never as a path containing the skill's own directory name.

### Corrections at the pause

- **[NEED]** When the owner gives feedback on the synthesis at the pause, the coordinator
  passes it to the synthesis agent. The synthesis agent updates the saved synthesis file
  before any render starts. Both the resumed and fresh render paths then consume the
  corrected file.
  [source: owner decision at spec review L2-1 — "why would we move to render with a bad
  synthesis?"]
- **[INFERRED]** The correction flow uses the same mechanism as resume: the coordinator sends
  a follow-up message to the synthesis agent with the owner's correction. The agent amends the
  synthesis file and confirms when done.

### Resume path

- **[INHERITED: concept-design §Core Model]** Resume means sending a follow-up message to the
  live synthesis agent, not spinning up a headless session.
- **[NEED]** The follow-up message instructs the synthesis agent to read `visualize.md`, both
  HTML feedback bodies, and build the HTML.
- **[INFERRED]** The resumed agent keeps all its discovered context from the synthesis step —
  evidence, code it inspected, the narrative it built. This is the resume path's advantage.
- **[NEED]** If the synthesis agent is unavailable (disappeared, context compacted, or the
  mechanism fails), the coordinator says so plainly and offers the fresh path as a fallback.
  This degrades the comparison, never the run.
  [source: concept-design §Edge Cases]

### Fresh path

- **[INHERITED: concept-design §Core Model]** Fresh = spawn a new agent given the synthesis
  file path, `visualize.md`, and both HTML feedback bodies.
- **[NEED]** The fresh agent reads the synthesis file to understand the narrative it inherits,
  then builds the HTML. It re-earns the understanding the synthesis agent already had.
- **[INFERRED]** The coordinator uses the `Agent` tool (not `subagent_type: "fork"`) for the
  fresh render agent, since the point is a clean window.

### Comparison

- **[NEED]** At the pause, the owner may ask for both render paths on one synthesis.
  [source: concept SC12, owner-verbatim "I am assuming that a smart agent will allow me to say:
  actually I want to A/B test this"]
- **[INHERITED: concept-design §How It Works]** Both renders run sequentially: the resumed
  agent first (while it is still live), then a fresh agent on the same synthesis.
- **[NEED]** Each render produces a distinct HTML. The naming convention must make clear which
  HTML came from which path. The pairing mechanism (filename stem linking HTML to synthesis)
  was chosen in Item 3's spec; comparison HTMLs extend it.
  [source: concept-design §How It Works, Item 3 spec §Run directory]
- **[NEED]** The comparison is measured on three readings: wall-clock time, token usage, and
  the owner's read of quality. All three are preserved per HTML.
  [source: concept SC12, owner-verbatim on wall-clock time, tokens, and quality assessment]
- **[NEED]** Wall-clock time is reported for each render.
- **[NEED]** Token usage: the requirement is honest reporting per runtime, not a specific
  measurement. Report token data if the runtime mechanism exposes it; state "not measured"
  if it does not. The Codex spike found no per-agent token count on Codex
  (`codex-resume-spike/spike-findings.md`). Claude's Agent/SendMessage results have not been
  verified — the first real render will establish what is available.
  [source: epic Item 4 In Scope — "the token story stated honestly per runtime"]
- **[NEED]** The owner's quality assessment is a first-class comparison reading. After a
  comparison, the coordinator presents both HTMLs for the owner to judge and preserves the
  assessment per HTML alongside the machine readings.
  [source: concept SC12]
- **[INFERRED]** If resume is unavailable, the comparison cannot happen (it requires both
  paths). The coordinator says so and falls back to fresh-only.

### Timing and comparison readings

- **[INFERRED]** Wall-clock readings, available token data, and the owner's quality assessment
  from each render are durably recorded — not only printed in the terminal. The synthesis
  metadata section is the natural home, since it already carries run information and the
  readings are paired to the synthesis. The exact format is design's call.
- **[INFERRED]** For a comparison, both renders' readings are recorded alongside each other so
  the owner can review them later.

### HTML output location

- **[INHERITED: concept-design §Run artifacts]** All HTML output lands under
  `.project/mental-alignment/runs/`, beside the synthesis it was built from. A later run never
  replaces an earlier run's artifact; timestamp collisions get a new timestamp. Post-render
  annotations belonging to the same run (timing data, quality readings) may update that run's
  synthesis — "never overwritten" means never clobbered by a different run, not immutable after
  creation.
- **[INHERITED: Item 3 spec §Run directory]** Synthesis and HTML are paired by filename stem.
  One synthesis may carry multiple HTMLs with suffixed names.

### Feedback — recording

- **[NEED]** New feedback always lands project-local first. Two project-local files:
  `.project/mental-alignment/feedback-synthesis.md` for synthesis feedback (attributed to the
  synthesis/run) and `.project/mental-alignment/feedback-html.md` for HTML feedback (attributed
  to the specific HTML version). Both are created on first write; absence is empty, not an error.
  [source: concept SC7, concept-design §Core Model]
- **[NEED]** Synthesis feedback is about the thinking: narrative quality, abstraction choices,
  compression, evidence gaps. HTML feedback is about the rendering: visual effectiveness,
  detail layer, layout. Both are distinct feedback bodies with separate recording and
  promotion paths.
  [source: concept SC7, owner-verbatim on two feedback bodies]
- **[NEED]** For comparisons, the owner can give feedback per-HTML. Each comparison HTML's
  feedback is attributed to that specific HTML.
  [source: epic Item 4 In Scope]
- **[NEED]** A run reads shared feedback then project-local feedback, so project-local lessons
  take precedence when they refine or override shared ones.
  [source: concept-design §Core Model]
- **[INFERRED]** After a render completes, the coordinator offers to record feedback. The
  owner's feedback goes into the conversation; the coordinator writes it to the project-local
  file. The exact recording format is design's call.

### Feedback — shared starters

- **[NEED]** `feedback/html.md` ships with a header and stated purpose, same pattern as
  `feedback/synthesis.md` from Item 3: a header only, filling from real runs. No
  agent-invented content.
  [source: Item 3 spec-review L2-3 resolution — owner decided header-only for shared starters]
- **[INHERITED: concept-design §Core Model]** Shared starters are git-tracked in the pack,
  present wherever the skill is installed via `setup-global.sh`'s whole-directory symlink.

### Feedback — promotion

- **[NEED]** Promotion is owner-initiated only. The coordinator does not auto-promote.
  [source: concept SC7, concept-design §Core Model]
- **[NEED]** Promotion targets the shared feedback file (`feedback/html.md` or
  `feedback/synthesis.md`) in the skill directory, not the instruction files (`visualize.md`,
  `design_synthesis.md`). The instruction files are the contract; the feedback files are the
  improvement loop.
  [source: concept-design §Core Model, owner-verbatim "this. definitely."]
- **[NEED]** Promotion arrives as an uncommitted change in the authored pack, so the owner
  reviews and rewrites before committing.
  [source: concept SC7 — "agent-written feedback needs rewriting first"]
- **[NEED]** Copy-install promotion fails closed. When the shared feedback file is a copy (Codex
  install, or a Claude project vendored with `init-project.sh --include-claude`), promotion
  records a candidate project-locally instead of editing a copy whose edits would be lost.
  [source: concept-design §Edge Cases, continuity with v1 posture]
- **[INFERRED]** The coordinator detects copy-install by checking whether the shared feedback
  file path resolves to the authored pack source. How this detection works is design's call.

## Non-Goals

- Automated quality checks on the HTML — the owner judges; feedback is the loop.
- Moving HTML into `docs/` — that is the owner's manual act.
- Migrating the old single feedback file (`feedback.md`) — deprecated in place; new runs use
  the two-body, two-tier system.
- Wiring the Codex resumed-render path — Item 5. Item 1's spike proved it works; the wiring
  waits for the packaging item.
- The exact prose content of `visualize.md` — an authored deliverable, not a spec-level
  requirement. The spec requires it exists and serves its stated purpose (teaching the render
  agent how to inherit the synthesis narrative and add the detail layer).
- The exact prose content of `feedback/html.md` beyond the header — it fills from real runs.
- HTML styling, design system, or visual consistency standards — `visualize.md` instructs the
  render agent; the feedback loop improves it.

## Open Questions / Deferred to design

- **HTML naming convention for comparisons.** The pairing mechanism is filename-stem (from
  Item 3). How comparison HTMLs are distinguished (e.g., `_resumed.html` vs. `_fresh.html`,
  or a different scheme) is design's call.
- **Render-agent spawn prompt composition.** What exactly goes in the follow-up message
  (resume) or the spawn prompt (fresh) beyond the synthesis path, instruction-file paths, and
  feedback-file paths. Design's call.
- **Whether the render agent should have tool restrictions.** The concept-design doesn't
  restrict tools; the render agent needs file reads, code reads, and file writes. Whether to
  constrain further is design's call.
- **Feedback entry format.** What a project-local feedback entry looks like — the attribution
  fields, the structure, and how entries accumulate in the file. Design's call.
- **Promotion candidate format.** What a copy-install promotion candidate looks like when
  recorded project-locally. Design's call.
- **Durable recording of comparison readings.** The synthesis metadata section is the natural
  home; the exact format and whether readings are appended to the existing synthesis file or
  recorded separately is design's call.
- **Whether `visualize.md` prescribes visual-form types or leaves structure to the agent.**
  The synthesis already names the visual form that fits each section; `visualize.md` may
  teach the agent how to build those forms, or leave it to the agent's judgment. Whatever it
  offers must serve the skeleton-to-meat progression.
- **Claude token data availability.** The Codex spike confirmed no per-agent token count on
  Codex. Claude's Agent/SendMessage results have not been verified. The first real render
  establishes what is available. If usage data appears, report it; otherwise state
  "not measured."

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2, Item 4)
- **Required Reading:**
  - `.project/concepts/mental-alignment-checkpoint.md` — concept (SC3, SC5–SC7, SC12; Key Concepts §2–§3, §5–§7; Owner's Words on skeleton/meat, execution shapes, feedback)
  - `.project/concepts/mental-alignment-skill-design.md` — concept-design (Core Model: render agent + feedback bodies; How It Works: comparison, edge cases)
  - `.project/active/codex-resume-spike/spike-findings.md` — Item 1 output (resume confirmed; no per-agent token count on Codex)
- **Predecessor:** `.project/active/coordinator-synthesis/spec.md` — Item 3 spec (defines the seam this item picks up from)
- **Predecessor spec review:** `.project/active/coordinator-synthesis/spec-review.md` — settles L1-4 (instruction-file reachability) and L2-1 (prompt-scoped invariant)
- **Spike findings:** `.project/active/directory-skill-build-pattern/spike-findings.md` — sibling-reference mechanics (A8, B5)
- **Spec review:** `.project/active/render-switch-feedback/spec-review.md` — verdict Revise, all findings dispositioned
- **Product lens:** `.project/active/render-switch-feedback/product-lens.md` — gate CLEAR, no findings
- **Design:** `.project/active/render-switch-feedback/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
