---
id: 0012
title: Mental-model skill: prompt holds the rules, feedback holds examples, an advisory reviewer pass runs inside each step
date: 2026-09-02
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [claude-pack/skills/_my_mental_model, scripts/build-codex-pack.sh, project-pack .project/mental-alignment feedback tiers]
supersedes: null
promoted_to: null
---

## Decision

The mental-model skill's instruction files (`design_synthesis.md`, `visualize.md`) hold every generalized rule; its feedback files hold examples and conditional techniques only. The writer reads the prompt and the project-local feedback and never the shared feedback. A reviewer with no domain context, on a mid-size model, reads the artifact, the prompt, and both feedback tiers and returns advisory notes to the writer inside the synthesis step and inside the render step; the writer decides what to apply, and neither the notes nor those decisions reach the coordinator or the owner. Promotion sorts a project-local entry into the prompt (a rule, rewritten by the owner) or the shared feedback (an example) and removes it from the local file.

## Why

Owner decision, 2026-09-02, in the spec session and confirmed in `spec-review.md` (Resolutions L1-1, L1-2): *"the core prompt SHOULD be the rules"*; *"You should be able to get good performance from just the prompt. But you can get BETTER results if you were to pass the output along with the feedback to another SMALL model to just do a review"*; feedback *"does not have to be generalized, hard and fast rules"* and *"could be formed as 'IF x, THEN y'"*.

**Amended 2026-09-02 (owner), on the model size.** The reviewer runs on sonnet, not on the smallest available model. The owner's words above asked for a SMALL model; the planted-fixture runs during implementation showed a small model matches the rules stated in a prompt file and does not match the recorded examples, which is most of what this pass exists to do. Across six runs a haiku reviewer never once cited an example entry, and the split made it worse by moving examples out of rule shape; a sonnet reviewer cited three entries by name, found both plants, and found true defects nobody planted. The isolation the requirement was protecting — no sources, no conversation — comes from the reviewer's brief, not from the model's size. Evidence: `.project/active/mental-model-reviewer/fixture-expected-notes.md` run log.

Evidence from the echo-workspace runs: five correction rounds against a growing prohibition list each cleared the quoted line and shipped the same defect elsewhere, while the owner's three rejected-to-correct heading pairs fixed the render; the coordinator carried the prompt, both feedback files, and the artifact; undefined terms, stat-dump headings, and definition sections headlined by run results reached the owner across four runs because nothing with a clean context looked for known patterns.

This entry amends concept decision 7 (`.project/concepts/mental-alignment-checkpoint.md` §7: "a run reads both"; promotion "targets the shared feedback file rather than the instruction files"). The guardrail's rationale, that agent-written feedback needs rewriting to generalize, is replaced: an example is promoted as an instance and needs no generalizing; a rule is generalized by the owner into the prompt at promotion. The owner-review step stays.

It narrows the concept non-goal "no automated checks of any kind" to mechanical checks and fixtures. The reviewer is advisory, never a gate, and invisible to the owner, so it adds no noise at the pause. The coordinator's send-back gates from the 2026-08-26 quality-ownership change are recorded under the same narrowing. The "sequencing beyond two steps" non-goal is untouched: the reviewer pass runs inside the existing synthesis or render step, and the pipeline stays synthesis, pause, render.

## Invariants established

- A rule in a prompt file stands without an example. A lesson that needs an example to be understood is feedback, not a rule.
- The writer is never pointed at a shared feedback file.
- The reviewer receives no sources and no conversation.
- The reviewer never blocks. Only the coordinator's prompt-compliance check sends work back on its own authority.
- Reviewer notes and the writer's decisions on them do not reach the coordinator or the owner. The coordinator may relay a path it does not open.
- Every feedback entry stays attributed to the run and artifact it reviewed, in both tiers.
- No shipped fixture or suite checks artifact quality. Acceptance evidence for the item that introduces the reviewer is one-time.

## Rejected alternatives

- The writer reads the shared feedback too: rejected, because the reviewer's hits would stop measuring the prompt and the writer overfits to exemplars.
- Reviewer notes and the writer's dispositions reach the owner at the pause: rejected by the owner (spec-review L1-2); the reviewer is feedback, not an audit.
- The coordinator triages reviewer findings: rejected; it keeps the coordinator's context heavy and the writer is the one with the context to decide.
- Fold every lesson into the instruction files and return the shared feedback to empty starters: rejected; the examples are what changed the renders and need a home outside the contract.
