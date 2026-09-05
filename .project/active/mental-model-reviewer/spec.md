# Spec: Mental-Model Reviewer and the Prompt-versus-Feedback Split

**Status:** Approved 2026-09-02 (revised after spec-review; owner proceeded to design)
**Owner:** Reid W
**Created:** 2026-09-02 09:04
**Complexity:** MEDIUM
**Branch:** main (uncommitted working tree holds the 2026-09-02 feedback drafts this item starts from)

---

## Problem

The skill has two kinds of instruction file and no working definition of the difference. `design_synthesis.md` and `visualize.md` are "the contract"; `feedback/synthesis.md` and `feedback/html.md` are "the improvement loop." In practice both are read by the same agent and both bind the same way, so the promotion pass this morning produced a shared feedback file that reads as a second prompt: fifteen numbered rules, several of which describe the artifact's shape as much as any line in the contract.

That collapse has three costs, all observed in the echo-workspace runs (`~/echo-workspace/.project/mental-alignment/`):

- **The writer reads a growing list and does not converge on it.** Five correction rounds against a lengthening prohibition list each cleared the quoted line and shipped the same defect elsewhere (`feedback-html.md`, 2026-08-25). The owner's three rejected-to-correct heading pairs (2026-09-01) did what the list could not.
- **The coordinator carries everything.** It reads the prompt, both feedback files, and the full artifact, then reviews and relays. The owner's instruction is to keep its context as light as possible; today it is the heaviest context in the run.
- **Recurring patterns reach the owner.** Undefined terms, stat-dump headings, and definition sections headlined by run results shipped across four runs. Nothing between the writer and the owner was looking for known patterns with a clean context; the writer and coordinator share source context and stop seeing them (`feedback-html.md`, 2026-09-01).

The owner set the semantics in this session **[OWNER]**:

- The core prompt is the rules. A writer working from the prompt alone should produce good output.
- Feedback is evidence: standalone data points of good and bad, appended, not necessarily generalized, and allowed to be conditional ("IF x, THEN y"). A piece of feedback does not have to be relevant to every run.
- Better results come from passing the output and the feedback to a separate small model that knows nothing about the domain and says "consider improving A, B, and C," in both directions: a pattern followed that should not have been, and a technique that would have improved the deliverable.

Three settled decisions in the concept (`.project/concepts/mental-alignment-checkpoint.md`) are amended by this item. All three were made by the owner, and the owner confirmed the amendments on 2026-09-02 (`spec-review.md`, Resolutions L1-1 and L1-2). ADR 0012 records the change; the product-lens ledger cites it against the finding IDs below.

- Decision 7 **[OWNER]** (product-lens spec-F1) says "a run reads both" feedback tiers and "promotion ... targets the shared feedback file rather than the instruction files, which stay the contract." Under this item the writer reads the project-local tier only, the reviewer reads both, and promotion of a *rule* targets the prompt. The concept's reason for keeping promotion off the instruction files was that agent-written feedback needs rewriting to generalize. That reason changes shape rather than surviving: an example is promoted as an instance and needs no generalizing; a rule is generalized by the owner into the prompt at promotion. The owner-review step stays.
- Non-goal **[OWNER]** (spec-F2) "Automated checks are out of scope — no quality fixtures and no mechanical ones either, since a noisy suite gets ignored." This item adds an advisory agent review that runs on every artifact without being asked. The writer judges its findings, and neither the notes nor the writer's decisions reach the owner or the coordinator, so nothing new arrives at the pause. The non-goal narrows to mechanical checks and fixtures. Under the same narrowing, the coordinator's send-back gates from the 2026-08-26 quality-ownership change, never recorded in the concept, are now recorded. No gate is added.
- Non-goal **[OWNER]** (spec-F3) puts "sequencing beyond two steps" out of scope. The owner's decision: the reviewer pass runs inside the existing synthesis step and inside the existing render step. The pipeline shape, synthesis then pause then render, is unchanged, and the non-goal stands.

## Success Criteria

- [ ] `design_synthesis.md` and `visualize.md` carry every generalized rule from today's draft feedback files and from the deprecated `feedback.md` (2026-08-18). Each rule stands without an example beside it.
- [ ] `feedback/synthesis.md` and `feedback/html.md` carry instances only: a pattern in one line, then Bad, then Good, or a conditional technique with the situation it applies to. No numbered rules remain in either file.
- [ ] The synthesis and render agents are pointed at the prompt, the project-local feedback, and the sources. Neither is ever pointed at a shared feedback file.
- [ ] A reviewer runs on every artifact (the synthesis, and each HTML) after the writer finishes and before the coordinator's own check. Its inputs are the artifact, the prompt, the shared feedback, and the project-local feedback. It receives no sources and no conversation.
- [ ] The reviewer's notes reach the writer. The writer decides what to apply. Neither the notes nor the writer's decisions reach the coordinator or the owner.
- [ ] The coordinator reads the prompt and the artifact, nothing else, and its check is prompt compliance. It remains the final gate and the correction gate for owner corrections.
- [ ] Project-local feedback is recorded by the coordinator in the entry shape the shared files use, with the run and artifact it came from named on the entry.
- [ ] The skill contains no promotion procedure. Each shared feedback file's header states the convention: a rule goes into the prompt file, an example into the shared feedback file with its attribution kept as a source line, and the entry leaves the project-local file.
- [ ] `./scripts/test_codex_orchestrator_pack.sh` and `./scripts/test_docs.sh` pass after the rebuild. No unsubstituted harness marker and no Claude tool name reaches `dist/codex/skills/my-mental-model/`.
- [ ] One live run in echo-workspace completes with the reviewer in the loop on the synthesis and on each render. The coordinator's transcript shows it read neither feedback file nor the notes. The reviewer is not required to find anything.
- [ ] A one-time acceptance check runs the reviewer alone against a planted artifact that carries one known anti-pattern from the feedback file and one opening for a recorded technique. It flags both. This is acceptance evidence for this item, not a shipped fixture.

## Known Requirements

- **[HARD]** Any harness-specific text added to `SKILL.md` (tool names, model selection, agent addressing) sits inside a keyed `harness-block` span with a substitution registered in `CODEX_SKILL_HARNESS_BLOCKS` (`scripts/build-codex-pack.sh:187`). Text outside a span that names `subagent_type`, the `Agent` tool, or a general-purpose subagent fails the dist scan (`scripts/test_codex_orchestrator_pack.sh:374`). ADR 0011.
- **[HARD]** On Claude, a per-agent model is selected only through the `Agent` tool's `model` parameter (`haiku` is an accepted value). That is the one place the reviewer's size can be set.
- **[NEED]** The writer produces good output from the prompt alone.
- **[NEED]** The writer does not read shared feedback.
- **[NEED]** The writer reads project-local feedback and applies it. That tier is the fast cycle, and it has not been sorted into rules and examples yet.
- **[NEED]** Feedback entries are appendable, standalone, and may be conditional. They are not required to be generalized rules.
- **[NEED]** The reviewer reads the prompt as well as the feedback, so it can flag structural misses and patterns alike.
- **[NEED]** The reviewer knows nothing about the domain: no sources, no conversation. ~~It is a small model.~~ Amended by the owner at implementation (2026-09-02) after the planted-fixture runs: the reviewer runs on sonnet. The isolation this requirement protects comes from the brief, not from the model's size; size was the proxy. Evidence: `fixture-expected-notes.md` run log; ADR 0012 amendment.
- **[NEED]** The reviewer's first pass goes back to the writer before the coordinator reviews.
- **[NEED]** The reviewer flags in both directions: anti-patterns hit and techniques missed.
- **[NEED]** The coordinator does not accept or triage reviewer findings. If the notes pass through it, they pass mechanically.
- **[NEED]** The reviewer provides feedback, not an audit or a gate. The writer decides internally what to apply. Neither the notes nor the writer's decisions reach the owner or the coordinator. (`spec-review.md`, Resolutions L1-2)
- **[NEED]** The coordinator is the final gate, with the lightest context possible.
- **[NEED]** "Just say the thing" is a prompt rule; the rejected-heading pairs are feedback.
- **[NEED]** A rule that needs an example to be understood is recorded as an anti-pattern with a Bad and a Good, not as a rule.
- **[NEED]** The reviewer runs on every artifact inside the existing synthesis step and the existing render step: `design_synthesis.md` plus the synthesis feedback for the synthesis, `visualize.md` plus the HTML feedback for each HTML. (`spec-review.md`, Resolutions L1-1)
- **[INFERRED]** One review pass per artifact. The writer's amendments are not re-reviewed.
- **[INFERRED]** The coordinator reads neither feedback file. Its Step 3 "read the standard first" shrinks to the prompt.
- **[INFERRED]** ~~Subagents cannot address each other directly on Claude.~~ Corrected at design (2026-09-02): a probe shows a Claude subagent has the `Agent` tool and `SendMessage`. The notes still hop through the coordinator as a path it relays unopened, by design choice (design D14), not by necessity.
- **[NEED]** Promotion is not a coordinator action. It happens outside a run, in the pack repo, with whatever agent the owner is working with there. (owner, 2026-09-02)
- **[INFERRED]** Promotion moves an entry out of the project-local file. The current "append only, never rewrite" stance on that file changes to: appended between promotions, removed by promotion.
- **[INHERITED]** Every feedback entry stays attributed to the run and artifact version it reviewed, in both tiers. Source: concept §6 and epic Item 4 ("attributed to run and HTML version"). Disposes product-lens spec-F4.
- **[INHERITED]** Concept decision 7, amended as stated in Problem and recorded in ADR 0012: two bodies, two tiers, owner-initiated promotion, shared tier git-tracked in the pack. Source: `.project/concepts/mental-alignment-checkpoint.md` §7.
- **[INHERITED]** Concept non-goal on automated checks, narrowed as stated in Problem and recorded in ADR 0012. Source: same file, Non-Goals.
- **[INHERITED]** Skill bodies are written in Claude-native vocabulary; cross-runtime correctness belongs to the Codex adapter. Source: ADR 0011.
- **[INHERITED]** The coordinator never writes synthesis or HTML content; the agent that wrote a thing is the only thing that amends it. Source: `.project/active/mental-model-quality-ownership/change.md`.

## Non-Goals

- A gate. The reviewer suggests; the writer decides; the coordinator's prompt-compliance check is the only thing that sends work back on its own authority.
- Mechanical checks, fixtures, or linting of any kind in the shipped skill. The concept's non-goal stands for those. The planted-artifact acceptance check is one-time evidence for this item, not a shipped fixture.
- Validating the reviewer on Codex. The text must build and install through the adapter; whether Codex can select a small model is an Item 5 question, not this item's.
- Pruning the existing project-local files in echo-workspace. Their content is the source for today's drafts; clearing them after promotion is the owner's act.
- A reader for the deprecated 2026-08-18 `feedback.md`. Its five orphaned rules are absorbed into the prompt by the split.
- Changing the pause, the render switch, the comparison, or the `# Renders` bookkeeping.
- Re-review loops. One pass per artifact.

## Open Questions / Deferred to design

- Where the notes live, what a note looks like, and whether the notes file persists on disk after the writer has read it. A sibling file beside the artifact (`{stem}.review.md`) is the obvious shape; design decides.
- How the coordinator knows the writer is done with the notes without reading them.
- Whether the reviewer re-runs after owner corrections at the pause. Default is no.
- Whether the reviewer gets the owner's question separately or reads it from the artifact. The synthesis frontmatter carries it; the HTML carries it only under checkpoint shape.
- Whether the "before delivering" checklists live in the prompt as the writer's self-check, in the reviewer's brief, or both.
- The exact small model id on Claude and what the Codex adapter substitutes for the reviewer spawn if Codex cannot select a model.
- Whether the coordinator's render check keeps its current four items (detail-layer test, shape, safety, provenance) or narrows further now that the reviewer reads `visualize.md`.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2), Item 6. It amends Items 3 and 4 and follows the quality-ownership change of 2026-08-26.
- **Required Reading:** `.project/concepts/mental-alignment-checkpoint.md` (decision 7, the automated-checks non-goal, Owner's Words on feedback); `.project/active/mental-model-quality-ownership/change.md` (the coordinator review gates this item narrows).
- **Source material for the split:** the uncommitted 2026-09-02 working tree of `claude-pack/skills/_my_mental_model/` (five files), and the three echo-workspace feedback files: `~/echo-workspace/.project/mental-alignment/feedback.md`, `feedback-synthesis.md`, `feedback-html.md`.
- **Adapter constraints:** `.project/adr/0011-native-skill-codex-adapter.md`; `.project/active/render-switch-feedback/harness-phrases.md` (the phrase dictionary any new harness-specific text extends).
- **Spec review:** `.project/active/mental-model-reviewer/spec-review.md` (Revise, 2026-09-02; all three resolutions applied)
- **Decision record:** `.project/adr/0012-mental-model-prompt-feedback-split-and-reviewer.md`
- **Product lens:** `.project/active/mental-model-reviewer/product-lens.md` (CLEAR after owner confirmation)
- **Design:** `.project/active/mental-model-reviewer/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
