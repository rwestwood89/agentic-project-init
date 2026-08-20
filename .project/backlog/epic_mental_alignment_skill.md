# Epic: Mental Alignment Skill v2

**Epic ID**: MENTAL-ALIGN-V2
**Status**: Draft
**Priority**: P0
**Created**: 2026-08-20
**Estimated Effort**: 4-5.5 days

---

## Executive Summary

Replace the failed single-agent mental-alignment command with a two-agent, one-pause skill that makes the thinking step visible, correctable, and improvable. The v1 shipped one fresh agent with one instruction set covering discovery, thinking, and rendering; it skipped the thinking, dropped the owner's reasoning, and forced one output shape. This epic builds the v2 skill directory with two agents (synthesis and render) separated by a mandatory human pause, three context policies classified from the request, and two feedback bodies across two tiers.

**Critical Success Factor**: The synthesis step produces a readable, correctable skeleton before any HTML exists, and the owner's reasoning from conversation reaches it when policy says it should.

---

## Source Documents

- `.project/concepts/mental-alignment-checkpoint.md` — concept (settled decisions, owner-verbatim quotes)
- `.project/concepts/mental-alignment-skill-design.md` — concept-design (skill shape, core model, transition inventory)
- `.project/concepts/mental-alignment-skill-design-review.md` — concept-design review (approved, ponytail CLEAR)

---

## Why This Epic?

**Current State**:
- `/_my_mental_model` is a command (`claude-pack/commands/_my_mental_model.md`) that delegates to a monolithic builder spec (`claude-pack/scripts/mental-model-builder.md`).
- One fresh agent covers discovery, thinking, and rendering in a single pass. The thinking step is unnamed — the agent races to the HTML deliverable and treats earlier steps mechanically.
- The fresh-agent handoff drops conversation reasoning the owner just worked through.
- The output shape is mandatory (checkpoint), regardless of context.
- One undifferentiated feedback file mixes lessons about thinking with lessons about rendering.

**Future State**:
- A skill directory (`claude-pack/skills/_my_mental_model/`) with a coordinator entry point, two instruction files (`design_synthesis.md`, `visualize.md`), and shared starter feedback.
- The synthesis agent's prompt ends at the synthesis — it never sees the render instruction, so the thinking actually happens.
- A mandatory pause after the synthesis lets the owner read, correct, and choose the render path (resume same agent, fresh agent, or both for comparison).
- Context policy (carried/discovered/clean room) and output shape (checkpoint/plain document) are classified from the request, not flagged.
- Two feedback bodies (synthesis and HTML) across two tiers (shared starters + project-local), with manual promotion.
- The v1 command, builder, and build wiring are retired.

---

## Success Criteria

- [ ] A question produces a readable synthesis markdown (narrative + metadata + judgment) before any HTML, and the owner sees it at a mandatory pause
- [ ] The owner's conversation reasoning reaches the synthesis under carried policy (fork), and clean-room restrictions are honored
- [ ] Both render paths (resumed agent, fresh agent) produce HTML that inherits the synthesis narrative and adds a detail layer — not the same words in a different format
- [ ] Comparison works: both renders on one synthesis, sequential, with wall-clock time and tokens reported
- [ ] Feedback lands project-local first, attributed to the run; shared starters ship with the skill; promotion targets the shared file
- [ ] The skill resolves by `/_my_mental_model` on both runtimes, with instruction files and feedback reachable; v1 surfaces are gone
- [ ] Existing tests pass; build pipeline handles the directory-skill sibling pattern

---

## Epic Strategy

**Value Delivery Path**:
- First, prove the directory-skill build pattern works with dummy files — this is reusable infrastructure for every future skill migration, and it unblocks everything else.
- Then retire v1, so there's one clean surface to build on.
- Then build the highest-value slice: the coordinator + synthesis step, which is useful on its own (the owner can take just the markdown).
- Last, the render step + switch + feedback, which exercises the composed whole.

**Critical Path**:
- Item 2 (build pattern) → Item 3 (v1 retirement) → Item 4 (synthesis) → Item 5 (render + feedback)
- Item 1 (Codex resume spike) runs in parallel with item 2, but must land before item 5, whose switch design depends on the answer.

**Decomposition Logic**:
- Item 2 is isolated as the reusable pattern — it proves the Claude skill → Codex skill pipeline for directory skills, independent of mental-alignment behavior. Future skill migrations reuse this directly.
- Item 3 is separated from item 2 because v1 retirement is a file-by-file cleanup that depends on the new pattern being in place, but is otherwise independent work. Mixing it with item 2 would obscure the reusable pattern with mental-alignment-specific cleanup.
- Items 4 and 5 split at the mandatory human pause, which is a real architectural seam. The synthesis is independently valuable; the render step exercises the composed whole and owns the feedback system.
- Spec details intentionally deferred: the synthesis template (section-by-section contents), the pairing mechanism (filename stem vs. metadata pointer), classification wording, comparison naming, spawn-prompt composition, feedback file formats, the promotion procedure.

**De-risking**:
- Item 1 exists because the Codex resume capability is an unverified bet. The design handles the fallback (Codex always takes fresh), but item 5's spec needs to know the answer.
- The fork bet (carried policy improves synthesis quality) is tested in use during item 4, judged by the owner — not requiring its own spike.
- The directory-skill mechanism is the third unverified bet: no `/_my_*` slash invocation resolves to a directory skill anywhere in the repo today. Item 2 proves it with a first invocation after install.

---

## Product-Lens

## epic_plan — 2026-08-20 — rev proposed decomposition (5 items, pre-file)

Point (re-derived): The mental-alignment capability's governing obligation is on-demand, question-led visual reconstruction of the owner's mental model, built through three independently instructable steps (collect, synthesize, render) with a mandatory pause after synthesis where the owner picks the render path (resume / fresh / both for comparison), two tiered feedback bodies (shared starter + project-local, manual promotion), shipped as a directory skill — no flags, no ceremony.
[source: `.project/concepts/mental-alignment-checkpoint.md` SC1–SC13, grade: owner/`[OWNER]`]

Falsifier: The decomposition would violate the point if it omits the mandatory pause, makes synthesis non-independent from rendering, drops the owner's render-path choice, or leaves a required feedback or skill-directory obligation with no covering item.

Findings: none.

Gate: CLEAR

### Observations for spec authors

1. **Starter feedback authoring.** SC7 requires shared starter bodies (`feedback/synthesis.md`, `feedback/html.md`) with useful cross-project guidance from day one. The spec for items 4 and 5 should name each starter file as an explicit deliverable so it doesn't ship empty.
2. **Unowned proofs.** (a) Codex resume — item 1; (b) carried policy produces better synthesis — exercised in item 4, owner-judged; (c) directory-skill lane end-to-end — item 2 for the build lane, verified at first real invocation after item 4. Coverage is implicit but complete.
3. **ADR reference.** ADRs 0009 (directory-skills pattern) and 0010 (native-skill Codex lane) were already filed at concept-design acceptance. Item 2's spec should reference these existing ADRs rather than filing new ones.

---

## Backlog Items

### Item 1: Codex Resume Spike

**Type**: Research
**Effort**: 0.5 days (spike + findings doc)
**Dependencies**: None
**Required Reading**:
- `.project/concepts/mental-alignment-skill-design.md` (architectural bets, edge cases: "Resume is unavailable")
- `.project/concepts/mental-alignment-checkpoint.md` (Open Questions §1, Appendix: resume precedent)

**Objective**: Determine whether Codex can resume a spawned agent, which decides whether the render switch has two shapes on Codex or only the fresh-agent path.

**Result (2026-08-20)**: `[AGENT]` Confirmed. Codex resumed one completed spawned agent through a follow-up task under the same identity, with conversation continuity proven by a retained-nonce check. Item 5 may ship the resumed path on Codex. Caveat: the observed collaboration results expose no per-agent token count, so Item 5 must resolve that measurement separately or report it as unavailable rather than estimate it. See `.project/active/codex-resume-spike/spike-findings.md`.

**Why This Is One Work Item**:
- A single targeted probe: one spawn, one resume attempt, findings doc
- The answer is binary (yes / no / with-caveats) and gates item 5's switch design on Codex

**In Scope (High Level)**:
- Spawn a Codex agent, attempt to resume it with a follow-up message
- Document whether the mechanism works, what limitations exist, and what the token-measurement story looks like
- Record the decision that flows into item 5

**Non-Goals / Out of Scope**:
- Building the actual switch — that's item 5
- Testing Claude resume — it's known to work via `SendMessage`
- Performance benchmarking — just "does it work at all"

**Success / Done State**:
- [x] Findings doc with a definitive answer: Codex can / cannot resume a spawned agent, with evidence
- [x] If yes: what the resume mechanism looks like and any caveats
- [ ] If no: confirmation that the fallback (Codex always takes fresh) is the right path

**Location**: `.project/active/codex-resume-spike/`

**Deliverables**:
- `.project/active/codex-resume-spike/spike-findings.md`

---

### Item 2: Directory-Skill Build Pattern

**Type**: Code/Integration
**Effort**: 1-1.5 days (spec 2h, design 2h, plan 1h, execute 4-6h)
**Dependencies**: None
**Required Reading**:
- `.project/concepts/mental-alignment-skill-design.md` (Distribution lane, Appendix: Codex build/install changes, Claude install)
- `.project/concepts/mental-alignment-skill-design-review.md` (ADR candidate 3 assessment, m4 disposition)
- `.project/adr/0009-directory-skills-pattern.md`
- `.project/adr/0010-native-skill-codex-lane.md`

**Objective**: Wire the Claude skill → Codex skill pipeline so directory skills with sibling files (instruction files, feedback directories) build and install correctly on both runtimes, using dummy files as the first test case.

**Why This Is One Work Item**:
- The build-script changes, install-script changes, allowlist entry, and name mapping are tightly coupled — testing any one requires the others
- This is reusable infrastructure: every future directory skill uses this pattern, so it deserves its own spec/design cycle independent of mental-alignment behavior

**In Scope (High Level)**:
- Create `claude-pack/skills/_my_mental_model/` with dummy `SKILL.md` and dummy sibling files (placeholders for `design_synthesis.md`, `visualize.md`, `feedback/`)
- Extend `build-codex-pack.sh` to copy sibling files in directory skills (currently `build-codex-pack.sh:395` matches only `SKILL.md`)
- Extend `setup-codex.sh` to install sibling files (currently `setup-codex.sh:267` installs only `SKILL.md`)
- Add to `NATIVE_SKILL_ALLOWLIST` in `codex-overrides/config.sh:58`
- Apply `_my_mental_model` → `my-mental-model` name mapping for the dist directory and frontmatter
- Ensure the SKILL.md frontmatter description is plain prose (Codex YAML parse chokes on leading `*`)
- Verify `setup-global.sh` symlink behavior for directory skills (expected: already works, `setup-global.sh:126-134`)
- Test the pattern end-to-end: build, install on both runtimes, invoke by `/_my_mental_model`, confirm sibling files are reachable

**Non-Goals / Out of Scope**:
- Implementing the actual coordinator/synthesis/render logic — that's items 4 and 5
- Retiring the v1 command and builder — that's item 3
- Widening the runtime-neutrality scan to cover sibling files — that's a spec-time decision per ADR 0010; this item honors the convention, not the enforcement
- Filing new ADRs — 0009 and 0010 already exist

**Success / Done State**:
- [ ] `/_my_mental_model` resolves to the skill directory on Claude (via symlink) and invokes successfully
- [ ] `build-codex-pack.sh` copies sibling files into `dist/codex/skills/my-mental-model/`; `setup-codex.sh` installs them to `~/.agents/skills/my-mental-model/`
- [ ] Existing tests pass; the skill's sibling files are present after build and install
- [ ] The pattern is generic: another directory skill with siblings would work the same way

**Location**: `.project/active/directory-skill-build-pattern/`

**Deliverables**:
- `.project/active/directory-skill-build-pattern/spec.md`
- `.project/active/directory-skill-build-pattern/design.md`
- `.project/active/directory-skill-build-pattern/plan.md`

---

### Item 3: V1 Retirement

**Type**: Code/Integration
**Effort**: 0.5-1 day (spec 1h, design 1h, plan 0.5h, execute 2-3h)
**Dependencies**: Item 2 (the new skill directory must exist and the build pipeline must handle it before the v1 surfaces are removed)
**Required Reading**:
- `.project/concepts/mental-alignment-skill-design.md` (Appendix: "Retiring the v1 surfaces" — the verified file-by-file inventory)

**Objective**: Remove every v1 surface — the command, builder, and their build wiring — so there is one clean skill-directory entry point for items 4 and 5 to build on.

**Why This Is One Work Item**:
- The retirement is a file-by-file checklist (the design's Appendix verifies it against the working tree), tightly coupled: removing the command without removing the builder's build wiring leaves dangling references, and vice versa
- It must happen atomically — after this item, `/_my_mental_model` resolves only through the skill directory

**In Scope (High Level)**:
- Delete `claude-pack/commands/_my_mental_model.md`
- Delete `claude-pack/scripts/mental-model-builder.md`
- Remove path rewrite at `build-codex-pack.sh:138` and shared-spec copy at `build-codex-pack.sh:426`
- Remove command description override at `codex-overrides/config.sh:37`
- Update `README.md:131` (catalog row: replace command entry with skill entry)
- Update `scripts/test_docs.sh` (retired list at line 59 — add `_my_mental_model` so the test forbids a README mention of the old command; the skill's replacement row uses the new name)
- Update `scripts/uninstall-project.sh:108-114` (add the skill directory to the cleanup list)
- Rebuild `dist/codex/` (manifest currently lists `my-mental-model` under `command_skills` and `mental-model-builder.md` under `scripts` — both must go, replaced by the skill-directory entry)
- Verify all tests pass after removal

**Non-Goals / Out of Scope**:
- Changing the existing stage offers in `_my_concept_design_review` and `_my_epic_plan` — they reference `/_my_mental_model` by name, which still resolves to the skill
- Migrating the single feedback file at `.project/mental-alignment/feedback.md` — that's item 5's concern
- Implementing skill behavior — that's items 4 and 5

**Success / Done State**:
- [ ] No file named `_my_mental_model.md` exists in `claude-pack/commands/`; no `mental-model-builder.md` in `claude-pack/scripts/`
- [ ] `build-codex-pack.sh`, `setup-codex.sh`, `codex-overrides/config.sh` contain no references to the retired files
- [ ] `dist/codex/` manifest reflects the skill-directory entry, not the old command or script
- [ ] All existing tests pass (docs, pipeline-sync, codex-orchestrator, global-setup)

**Location**: `.project/active/v1-retirement/`

**Deliverables**:
- `.project/active/v1-retirement/spec.md`
- `.project/active/v1-retirement/design.md`
- `.project/active/v1-retirement/plan.md`

---

### Item 4: Coordinator + Synthesis Step

**Type**: Implementation
**Effort**: 1-1.5 days (spec 2h, design 3h, plan 1h, execute 4-6h)
**Dependencies**: Items 2 and 3 (the skill directory must exist with the build pipeline wired, and v1 must be retired)
**Required Reading**:
- `.project/concepts/mental-alignment-checkpoint.md` (SC1-SC5, SC8-SC11, SC13; Key Concepts §1-§4; Owner's Words on the three steps, clean room, carried policy)
- `.project/concepts/mental-alignment-skill-design.md` (Core Model: coordinator and synthesis agent; Design Principles §1-§2; Flow; How It Works)

**Objective**: Implement the coordinator's classification logic and the synthesis agent's thinking step, producing a readable synthesis markdown at a mandatory pause.

**Why This Is One Work Item**:
- The coordinator's classification (policy + shape) and the synthesis agent's behavior are tightly coupled through the spawn-prompt composition — the coordinator decides what goes in the prompt, and the synthesis agent acts on it
- The pause is the natural boundary: after this item, a question produces a synthesis and stops; the render step (item 5) picks up from there

**In Scope (High Level)**:
- Replace dummy `SKILL.md` with the real coordinator: classify context policy (carried / discovered / clean room) and output shape (checkpoint / plain document) from the request, state the classification, compose the spawn prompt
- Replace dummy `design_synthesis.md` with real synthesis instructions: how to think about a system, what to discover, how to structure the narrative, what the synthesis file contains (narrative + metadata + judgment)
- Author `feedback/synthesis.md` — the shared starter feedback body for synthesis (cross-project guidance, not empty)
- Synthesis agent reads `design_synthesis.md` + both synthesis feedback bodies, discovers evidence per policy, writes synthesis markdown to `.project/mental-alignment/runs/{YYYYMMDD-HHMMSS}_{slug}.md`
- Coordinator presents the synthesis at the mandatory pause
- Fork for carried policy (`subagent_type: "fork"`); fresh agent for discovered and clean room (with restriction restated and unenforced nature stated)

**Non-Goals / Out of Scope**:
- The render step, the switch, and the comparison — that's item 5
- The HTML feedback body — that's item 5
- The feedback recording and promotion workflow — that's item 5
- Classification wording details and the synthesis template section-by-section are spec concerns, not pre-decided here

**Success / Done State**:
- [ ] A question produces a synthesis markdown at `runs/` with narrative, metadata, and judgment sections
- [ ] The coordinator states its classification (policy + shape) before spawning
- [ ] Under carried policy, the synthesis agent is a fork and conversation reasoning reaches the output
- [ ] Under clean-room policy, restriction language is honored (fresh agent, restriction restated, unenforced nature stated)
- [ ] Every run pauses after the synthesis is presented; no HTML is built

**Location**: `.project/active/coordinator-synthesis/`

**Deliverables**:
- `.project/active/coordinator-synthesis/spec.md`
- `.project/active/coordinator-synthesis/design.md`
- `.project/active/coordinator-synthesis/plan.md`
- `claude-pack/skills/_my_mental_model/SKILL.md` (real coordinator)
- `claude-pack/skills/_my_mental_model/design_synthesis.md` (real instructions)
- `claude-pack/skills/_my_mental_model/feedback/synthesis.md` (shared starter)

---

### Item 5: Render + Switch + Feedback

**Type**: Implementation
**Effort**: 1-1.5 days (spec 2h, design 3h, plan 1h, execute 4-6h)
**Dependencies**: Item 4 (synthesis must exist for render to work); Item 1 (spike decides whether the switch has two shapes on Codex)
**Required Reading**:
- `.project/concepts/mental-alignment-checkpoint.md` (SC3, SC5-SC7, SC12; Key Concepts §2-§3, §5-§7; Owner's Words on skeleton/meat, execution shapes, feedback)
- `.project/concepts/mental-alignment-skill-design.md` (Core Model: render agent + feedback bodies; How It Works: comparison, edge cases)
- `.project/active/codex-resume-spike/spike-findings.md` (item 1 output — decides the Codex switch shape)

**Objective**: Implement the render paths (resumed and fresh), the owner's choice at the pause, the comparison mechanism, and the feedback system — completing the full end-to-end flow.

**Why This Is One Work Item**:
- The switch (resume vs. fresh), the comparison (both on one synthesis), and the feedback recording are all triggered at the same moment — the owner's answer at the pause
- This item exercises the composed whole: a successful run goes coordinator → synthesis → pause → choice → render → HTML → feedback, proving the two-agent shape works end-to-end

**In Scope (High Level)**:
- Replace dummy `visualize.md` with real render instructions: how to inherit the synthesis narrative and add a detail layer using what HTML can do (visuals, disclosure, color)
- Author `feedback/html.md` — the shared starter feedback body for HTML rendering
- Resume path: send follow-up message to the live synthesis agent (read `visualize.md` + HTML feedback, write HTML)
- Fresh path: spawn new agent given synthesis path (read `visualize.md` + HTML feedback, write HTML)
- Comparison: both paths sequential on one synthesis, distinct HTML names, wall-clock time and tokens reported in the terminal
- HTML output: paired to synthesis, inherits narrative, adds detail layer, lands in `runs/`
- Checkpoint shape: metadata + judgment render into the HTML; plain document shape: judgment read back in terminal
- Feedback recording: new feedback always lands project-local first (`feedback-synthesis.md`, `feedback-html.md`), attributed to run and HTML version
- Promotion workflow: owner-initiated, targets the shared feedback file in the skill directory (not the instruction file); copy-install edge case fails closed (records promotion candidate project-locally)
- Codex switch shape: if the spike found resume works, wire it; if not, Codex always takes the fresh path

**Non-Goals / Out of Scope**:
- Automated quality checks on the output — owner judges, feedback is the loop
- Moving HTML into `docs/` — that's the owner's manual act
- Migrating the old single feedback file — deprecated in place, new runs use the new system

**Success / Done State**:
- [ ] Both render paths (resumed agent, fresh agent) produce valid HTML paired to the synthesis
- [ ] The HTML inherits the synthesis narrative and adds a detail layer — not the same words in a different format
- [ ] Comparison produces two HTMLs from one synthesis, with wall-clock time and tokens reported
- [ ] New feedback lands project-local, attributed to run and HTML version; shared starters ship with the skill
- [ ] Promotion targets the shared feedback file; copy-install promotion fails closed

**Location**: `.project/active/render-switch-feedback/`

**Deliverables**:
- `.project/active/render-switch-feedback/spec.md`
- `.project/active/render-switch-feedback/design.md`
- `.project/active/render-switch-feedback/plan.md`
- `claude-pack/skills/_my_mental_model/visualize.md` (real instructions)
- `claude-pack/skills/_my_mental_model/feedback/html.md` (shared starter)

---

## Dependencies

**External**:
- Codex runtime: the spike (item 1) tests whether it supports agent resume
- Claude Code runtime: `SendMessage` continuation for the resume path, fork mechanism for carried policy

**Internal**:
- ADRs 0009 and 0010 (already filed) — item 2 implements the decisions they record

**Item Dependency Graph**:
```
Item 1 (no deps) ─────────────────────────────┐
Item 2 (no deps)                               │
  └─► Item 3 (depends on 2)                   │
        └─► Item 4 (depends on 2, 3)          │
              └─► Item 5 (depends on 4, 1) ◄──┘
```

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Codex cannot resume a spawned agent | Med | Item 1 (spike) de-risks early; fallback is Codex always takes the fresh path — the design already handles this |
| Directory-skill slash resolution doesn't work | High | Item 2 tests with dummy files before any behavior depends on it; `setup-global.sh` symlink behavior is already verified in the design |
| Fork doesn't carry conversation reasoning effectively | Med | Tested in use during item 4; the mechanism exists (`subagent_type: "fork"`); if quality doesn't improve, carried policy degrades to discovered, not to failure |
| V1 retirement misses a reference | Low | The design's Appendix has a verified file-by-file inventory; existing tests (docs, pipeline-sync) catch most gaps |

---

## Timeline

**Total Effort**: 4-5.5 days

| Item | Effort | Dependencies | Parallelizable |
|------|--------|--------------|----------------|
| Item 1: Codex Resume Spike | 0.5 days | None | Yes — runs parallel to Item 2 |
| Item 2: Directory-Skill Build Pattern | 1-1.5 days | None | Yes — runs parallel to Item 1 |
| Item 3: V1 Retirement | 0.5-1 day | Item 2 | Sequential after Item 2 |
| Item 4: Coordinator + Synthesis | 1-1.5 days | Items 2, 3 | Sequential after Item 3 |
| Item 5: Render + Switch + Feedback | 1-1.5 days | Items 4, 1 | Sequential after Item 4 |

**Shortest path (with parallelism)**: ~4 days (items 1 and 2 overlap).

---

## Lessons Learned (Post-Completion)

*Fill in after epic is complete*

**What Went Well**:
- TBD

**What Could Improve**:
- TBD

**Surprises**:
- TBD

---

**Last Updated**: 2026-08-20
**Next Action**: Approve epic, then begin Item 1 (spike) and Item 2 (build pattern) in parallel
