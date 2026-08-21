# Epic: Mental Alignment Skill v2

**Epic ID**: MENTAL-ALIGN-V2
**Status**: In progress (Item 1 done)
**Priority**: P0
**Created**: 2026-08-20
**Restructured**: 2026-08-20 — see "Restructure" below
**Estimated Effort**: 3-4.5 days remaining (0.5 days spent)

---

## Executive Summary

Replace the failed single-agent mental-alignment command with a two-agent, one-pause skill that
makes the thinking step visible, correctable, and improvable. The v1 shipped one fresh agent with
one instruction set covering discovery, thinking, and rendering; it skipped the thinking, dropped
the owner's reasoning, and forced one output shape. This epic builds the v2 skill directory with two
agents (synthesis and render) separated by a mandatory human pause, three context policies
classified from the request, and two feedback bodies across two tiers.

**Build and prove the skill on Claude first. Runtime parity comes last, as one item.**

**Critical Success Factor**: The synthesis step produces a readable, correctable skeleton before any
HTML exists, and the owner's reasoning from conversation reaches it when policy says it should.

---

## Restructure (2026-08-20, owner decision)

The original decomposition put the distribution plumbing first: prove the directory-skill build
lane (old Item 2), retire v1 completely (old Item 3), then build the skill (old Items 4, 5). In
practice that front-loaded a long chain of Claude-versus-Codex packaging questions ahead of the
capability the epic exists to deliver, and the owner stopped it: *"I want to start testing the
fucking skill, using claude is fine."*

The dependency that justified the original order turned out to be one file deletion. Verified
against the working tree:

- Item 3's "must happen atomically" framing was overcautious. The only thing the skill items need
  from v1 retirement is that `/_my_mental_model` resolve to the skill rather than the old command —
  two `rm`s, now Item 2.
- Leaving the rest of the v1 wiring in place breaks nothing. `build-codex-pack.sh:138` is a perl
  substitution that stops matching; `:426` is guarded by `[ -f ]`; `codex-overrides/config.sh:37`
  becomes an unused map key; `test_docs.sh` requires a README catalog row only for command files
  that **exist**, and `_my_mental_model` is not in that test's retired-names list, so the leftover
  README row does not fail either.
- The Claude install needs no build change at all: `setup-global.sh:126-134` already symlinks whole
  skill directories, so siblings arrive with the skill.

**Old → new item mapping**, so the Product-Lens block and the source documents below stay readable:

| Old | New | Change |
|---|---|---|
| Item 1 — Codex resume spike | Item 1 | Done 2026-08-20 |
| Item 2 — Directory-skill build pattern | **Item 5** | Moved last, absorbed old Item 3's cleanup |
| Item 3 — V1 retirement | **Item 2** (the two deletes) + **Item 5** (the wiring) | Split |
| Item 4 — Coordinator + synthesis | **Item 3** | Claude-only now |
| Item 5 — Render + switch + feedback | **Item 4** | Claude-only now |

The spec, design, and product-lens ledger already written for old Item 2 live at
`.project/active/directory-skill-build-pattern/` and are now Item 5's artifacts. The three owner
decisions recorded there still stand; one of them has a narrowed rationale, noted in Item 5.

**Do not rebuild `dist/codex/` before Item 5.** Leaving it alone keeps the installed Codex copy of
the v1 skill working in the meantime. Rebuilding after Item 2's deletes would remove the Codex side
of `/_my_mental_model` with nothing replacing it.

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

Claude-first (Items 2-4):

- [ ] A question produces a readable synthesis markdown (narrative + metadata + judgment) before any HTML, and the owner sees it at a mandatory pause
- [ ] The owner's conversation reasoning reaches the synthesis under carried policy (fork), and clean-room restrictions are honored
- [ ] Both render paths (resumed agent, fresh agent) produce HTML that inherits the synthesis narrative and adds a detail layer — not the same words in a different format
- [ ] Comparison works: both renders on one synthesis, sequential, with wall-clock time reported (see Item 1's token-measurement finding)
- [ ] Feedback lands project-local first, attributed to the run; shared starters ship with the skill; promotion targets the shared file
- [ ] `/_my_mental_model` resolves to the skill directory on Claude, with instruction files and feedback reachable

Parity and cleanup (Item 5):

- [ ] The skill resolves and runs equivalently on Codex, with its sibling files reachable there
- [ ] Every v1 surface is gone and every reference to it updated
- [ ] Existing tests pass; the build pipeline handles the directory-skill sibling pattern generically

---

## Epic Strategy

**Value Delivery Path**:
- First release the name (two deletes), so the skill can own `/_my_mental_model`.
- Then build the highest-value slice: the coordinator + synthesis step, which is useful on its own
  (the owner can take just the markdown) and which proves the sibling-file mechanics by using them.
- Then the render step + switch + feedback, which exercises the composed whole.
- Last, packaging: the Codex native-skill lane, the name mapping, and the v1 cleanup — one item, by
  which point the real skill is a working subject to test the lane against.

**Critical Path**: Item 2 → Item 3 → Item 4 → Item 5. Item 1 is done.

**Decomposition Logic**:
- Item 2 is the minimum unblock: the name. Nothing else about v1 retirement gates the skill work.
- Items 3 and 4 split at the mandatory human pause, which is a real architectural seam. The
  synthesis is independently valuable; the render step exercises the composed whole and owns the
  feedback system.
- Item 5 is isolated as the reusable packaging pattern — it proves the Claude skill → Codex skill
  pipeline for directory skills, independent of mental-alignment behavior, and future skill
  migrations reuse it directly. Running it last means it has a real skill with real siblings to
  prove itself against instead of a placeholder.
- Spec details intentionally deferred: the synthesis template (section-by-section contents), the
  pairing mechanism (filename stem vs. metadata pointer), classification wording, comparison
  naming, spawn-prompt composition, feedback file formats, the promotion procedure.

**De-risking**:
- Item 1 (done) confirmed Codex can resume a spawned agent, so the render switch has both shapes on
  both runtimes. It also found Codex reports no per-agent token count — a constraint on the
  comparison, recorded in Item 4.
- The fork bet (carried policy improves synthesis quality) is tested in use during Item 3, judged by
  the owner — not requiring its own spike.
- The sibling-file mechanics on **both** runtimes are answered, by a probe run against throwaway
  skills on 2026-08-20. Findings: `.project/active/directory-skill-build-pattern/spike-findings.md`.
  Siblings are readable flat, nested, and through a symlink, on Claude and on Codex; underscore-
  prefixed directory skills register on both. The one rule that came out of it: reference a sibling
  by **bare filename in prose**, never by a path containing the skill's own directory name — each
  runtime resolves relative paths differently and that is the only portable form.
- Two things the probe did not settle. Whether a **typed** `/_my_*` reaches a skill directory stays
  Item 3's proof, unchanged. Whether a same-named command file shadows a skill is moot if Item 2
  runs first — see Risks.

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

### Post-restructure note (2026-08-20)

The block above was written against the original numbering; read it through the mapping table in
"Restructure". Its gate stands CLEAR. Observation 1's "items 4 and 5" are now Items 3 and 4;
observation 2's "item 4" is now Item 3 and its "item 2" is now Item 5; observation 3's "item 2" is
now Item 5. Observation 2(c) improves under the new order: the directory-skill lane's first real
invocation now happens in Item 3, *before* the build lane is touched, so the lane is proven against
a real skill rather than a placeholder.

Two forward handoffs from the spec-stage lens on old Item 2
(`.project/active/directory-skill-build-pattern/product-lens.md`, gate DISPOSED) land in this file:

- **spec-F2** — the `NATIVE_SKILL_ALLOWLIST` entry is an easy step to lose, because a missing entry
  excludes the skill from the Codex build with no error, and the check is keyed on the **pack-side**
  directory name (`_my_mental_model`, not `my-mental-model`). Now explicit in Item 5's In Scope.
- **spec-F3** — the "does a `/_my_*` slash invocation resolve to a directory skill" proof is now
  owned by **Item 3**, which creates the real directory and invokes it. The risk table below is
  re-pointed accordingly.

---

## Backlog Items

### Item 1: Codex Resume Spike — DONE (2026-08-20)

**Type**: Research
**Effort**: 0.5 days (spent)
**Location**: `.project/active/codex-resume-spike/`
**Deliverable**: `.project/active/codex-resume-spike/spike-findings.md`

**Outcome**: **Confirmed.** Codex can continue a spawned agent after its first turn completes. A
follow-up task to the same canonical agent identity started a second turn that recovered a nonce
held only in the agent's first-turn context, verified by digest. So Item 4 can implement the Codex
resumed-render path by retaining the synthesis agent's identity; the fresh-agent fallback is still
needed when the live agent is unavailable.

**Constraint discovered, carried into Item 4**: the Codex collaboration surface reported **no
per-agent token usage** — spawn, completion, follow-up, wait, and status results exposed identity,
lifecycle state, and final text, but no token count. The design's premise that the completion
notification supplies the comparison's token measure does not hold on Codex. Item 4 must either
find a supported measurement source or report that token comparison is unavailable there. It must
not estimate.

---

### Item 2: Release the Name

**Type**: Cleanup
**Effort**: ~10 minutes
**Dependencies**: None
**Required Reading**:
- `.project/concepts/mental-alignment-skill-design.md` (Appendix: "Retiring the v1 surfaces")

**Objective**: Delete the two v1 authored files so `/_my_mental_model` resolves to the skill
directory Item 3 creates, and nothing else.

**Why This Is One Work Item**:
- It is the only part of v1 retirement that gates the skill work, and it is two deletions
- Splitting it from the rest of the cleanup is what lets Items 3 and 4 proceed without touching the
  Codex lane at all
- Running it **before** Item 3 is not optional. Precedence between a same-named user command and a
  user skill is unverified (`.project/active/directory-skill-build-pattern/spike-findings.md`, A3),
  so deleting the command first is what guarantees `/_my_mental_model` reaches the skill

**In Scope**:
- Delete `claude-pack/commands/_my_mental_model.md`
- Delete `claude-pack/scripts/mental-model-builder.md`
- **Remove the two installed symlinks the deletes strand**: `~/.claude/commands/_my_mental_model.md`
  and `~/.claude/scripts/mental-model-builder.md`. Deleting the pack files does not remove them —
  `setup-global.sh` has no removal sweep (that is D4, deferred to Item 5), so both persist as
  dangling symlinks. Observed dangling 2026-08-20. Leaving the command one in place means Item 3's
  first invocation of `/_my_mental_model` faces a stale command symlink **and** a real skill
  directory under the same name, which is precisely the command-versus-skill precedence question the
  probe could not settle (`.project/active/directory-skill-build-pattern/spike-findings.md`, A3).
  Two `rm`s close it; the alternative is discovering A3's answer in production
- Confirm the suite still passes (docs, pipeline-sync, adr, global-setup, codex-orchestrator)

**Non-Goals / Out of Scope**:
- Every other v1 reference — build wiring, `config.sh` override, README row, `test_docs.sh` retired
  list, `uninstall-project.sh` list, `dist/` rebuild. All Item 5. Each is verified harmless if left
  in place; see "Restructure".
- Rebuilding `dist/codex/`. Explicitly deferred so the installed Codex copy keeps working.

**Success / Done State**:
- [ ] Neither file exists
- [ ] Neither stale symlink exists under `~/.claude/` — `test -e` passes on nothing
- [ ] Full existing suite passes with them gone
- [ ] `dist/codex/` untouched

---

### Item 3: Coordinator + Synthesis Step (Claude)

**Type**: Implementation
**Effort**: 1-1.5 days (spec 2h, design 3h, plan 1h, execute 4-6h)
**Dependencies**: Item 2
**Required Reading**:
- `.project/concepts/mental-alignment-checkpoint.md` (SC1-SC5, SC8-SC11, SC13; Key Concepts §1-§4; Owner's Words on the three steps, clean room, carried policy)
- `.project/concepts/mental-alignment-skill-design.md` (Core Model: coordinator and synthesis agent; Design Principles §1-§2; Flow; How It Works)
- `.project/active/directory-skill-build-pattern/spike-findings.md` — **read "Relative paths resolve differently" before authoring any instruction file.** The Claude-side sibling mechanics this item was going to discover are already measured (A1, A4-A10)

**Objective**: Implement the coordinator's classification logic and the synthesis agent's thinking
step, producing a readable synthesis markdown at a mandatory pause — running on Claude.

**Why This Is One Work Item**:
- The coordinator's classification (policy + shape) and the synthesis agent's behavior are tightly coupled through the spawn-prompt composition — the coordinator decides what goes in the prompt, and the synthesis agent acts on it
- The pause is the natural boundary: after this item, a question produces a synthesis and stops; the render step (Item 4) picks up from there

**In Scope (High Level)**:
- Create `claude-pack/skills/_my_mental_model/` with the real coordinator `SKILL.md`: classify context policy (carried / discovered / clean room) and output shape (checkpoint / plain document) from the request, state the classification, compose the spawn prompt
- Author `design_synthesis.md`: how to think about a system, what to discover, how to structure the narrative, what the synthesis file contains (narrative + metadata + judgment)
- Author `feedback/synthesis.md` — the shared starter feedback body for synthesis (cross-project guidance, not empty)
- Synthesis agent reads `design_synthesis.md` + both synthesis feedback bodies, discovers evidence per policy, writes synthesis markdown to `.project/mental-alignment/runs/{YYYYMMDD-HHMMSS}_{slug}.md`
- Coordinator presents the synthesis at the mandatory pause
- Fork for carried policy (`subagent_type: "fork"`); fresh agent for discovered and clean room (with restriction restated and unenforced nature stated)
- Write every sibling reference as a **bare filename in prose** — `design_synthesis.md`, `feedback/synthesis.md` — never as a path containing the skill's own directory name. On Claude the invocation prepends `Base directory for this skill: <absolute path>` and the agent joins from there; on Codex the working directory already *is* the skill directory. Bare-filename prose is the only form that resolves on both. Evidence: `.project/active/directory-skill-build-pattern/spike-findings.md`, A8 and B5. **Rationale corrected 2026-08-20:** this line previously argued the rule was what kept Item 5 from needing a rewrite pass "it is forbidden to have (ADR 0010)". The owner reversed 0010 — skill directories now go through the Codex adapter, so a rewrite pass exists (`.project/adr/0011-native-skill-codex-adapter.md`). Bare-filename prose is still the better form where it fits, on its own merits, but it is a preference now rather than a constraint
- Install with `./scripts/setup-global.sh` (no script change needed — it already symlinks whole skill directories, `setup-global.sh:126-134`) and invoke by `/_my_mental_model`

**Non-Goals / Out of Scope**:
- The render step, the switch, and the comparison — Item 4
- The HTML feedback body, feedback recording, and promotion — Item 4
- Anything Codex: the allowlist entry, the name mapping, the sibling build/install lane, runtime-neutral phrasing enforcement — Item 5
- Classification wording details and the synthesis template section-by-section are spec concerns, not pre-decided here

**Success / Done State**:
- [x] A question produces a synthesis markdown at `runs/` with narrative, metadata, and judgment sections
- [x] The coordinator states its classification (policy + shape) before spawning
- [ ] Under carried policy, the synthesis agent is a fork and conversation reasoning reaches the output
- [ ] Under clean-room policy, restriction language is honored (fresh agent, restriction restated, unenforced nature stated)
- [x] Every run pauses after the synthesis is presented; no HTML is built
- [x] **`/_my_mental_model` resolves to the skill directory on Claude and the coordinator reads its sibling instruction file and nested feedback file.** This is the epic's directory-skill-resolution proof (product-lens spec-F3). The working form of the sibling reference is already measured, not open: Claude prepends `Base directory for this skill: <absolute path>` to the invocation, every relative form fails, and `pwd` is the *project* directory, not the skill's (`.project/active/directory-skill-build-pattern/spike-findings.md`, A8). Confirm it holds for this skill; do not re-derive it.

**Location**: `.project/active/coordinator-synthesis/`

**Deliverables**:
- `.project/active/coordinator-synthesis/{spec,design,plan}.md`
- `claude-pack/skills/_my_mental_model/SKILL.md`
- `claude-pack/skills/_my_mental_model/design_synthesis.md`
- `claude-pack/skills/_my_mental_model/feedback/synthesis.md`

---

### Item 4: Render + Switch + Feedback (Claude)

**Status**: Implemented 2026-08-20, first validation run passed. V1 was a resumed render on a
clean-room, checkpoint-shape question, run in `echo-workspace` through the global symlink install —
the owner got their artifact and the detail layer is labelled and real (spec `## Success Criteria`
carries the evidence). Still untested: the fresh path, the comparison, plain-document shape, the
correction gate, feedback recording, and promotion. Phrase list for Item 5:
`.project/active/render-switch-feedback/harness-phrases.md`.

**Type**: Implementation
**Effort**: 1-1.5 days (spec 2h, design 3h, plan 1h, execute 4-6h)
**Dependencies**: Item 3
**Required Reading**:
- `.project/concepts/mental-alignment-checkpoint.md` (SC3, SC5-SC7, SC12; Key Concepts §2-§3, §5-§7; Owner's Words on skeleton/meat, execution shapes, feedback)
- `.project/concepts/mental-alignment-skill-design.md` (Core Model: render agent + feedback bodies; How It Works: comparison, edge cases)
- `.project/active/codex-resume-spike/spike-findings.md` (Item 1 output — resume confirmed; no per-agent token count on Codex)

**Objective**: Implement the render paths (resumed and fresh), the owner's choice at the pause, the
comparison mechanism, and the feedback system — completing the full end-to-end flow on Claude.

**Why This Is One Work Item**:
- The switch (resume vs. fresh), the comparison (both on one synthesis), and the feedback recording are all triggered at the same moment — the owner's answer at the pause
- This item exercises the composed whole: a successful run goes coordinator → synthesis → pause → choice → render → HTML → feedback, proving the two-agent shape works end-to-end

**In Scope (High Level)**:
- Author `visualize.md`: how to inherit the synthesis narrative and add a detail layer using what HTML can do (visuals, disclosure, color)
- Author `feedback/html.md` — the shared starter feedback body for HTML rendering
- Resume path: send follow-up message to the live synthesis agent (read `visualize.md` + HTML feedback, write HTML)
- Fresh path: spawn new agent given synthesis path (read `visualize.md` + HTML feedback, write HTML)
- Comparison: both paths sequential on one synthesis, distinct HTML names, wall-clock time reported in the terminal. **Token reporting: available on Claude via the completion notification's usage report; Item 1 found no per-agent token count on Codex, so the spec must decide what Codex reports and must not estimate.**
- HTML output: paired to synthesis, inherits narrative, adds detail layer, lands in `runs/`
- Checkpoint shape: metadata + judgment render into the HTML; plain document shape: judgment read back in terminal
- Feedback recording: new feedback always lands project-local first (`feedback-synthesis.md`, `feedback-html.md`), attributed to run and HTML version
- Promotion workflow: owner-initiated, targets the shared feedback file in the skill directory (not the instruction file); copy-install edge case fails closed (records promotion candidate project-locally)

**Non-Goals / Out of Scope**:
- Automated quality checks on the output — owner judges, feedback is the loop
- Moving HTML into `docs/` — that's the owner's manual act
- Migrating the old single feedback file — deprecated in place, new runs use the new system
- Wiring the Codex resumed-render path — Item 5. Item 1 proved it works; the wiring waits for the lane.

**Success / Done State**:
- [ ] Both render paths (resumed agent, fresh agent) produce valid HTML paired to the synthesis
  — resumed confirmed by V1; fresh untested
- [x] The HTML inherits the synthesis narrative and adds a detail layer — not the same words in a different format
- [ ] Comparison produces two HTMLs from one synthesis, with wall-clock time reported and the token story stated honestly per runtime
  — never run; V1 did confirm the readings mechanism on a solo render (`wall clock: 10m 44s`, `tokens: not measured`)
- [ ] New feedback lands project-local, attributed to run and HTML version; shared starters ship with the skill
  — starters ship; recording untested
- [ ] Promotion targets the shared feedback file; copy-install promotion fails closed

**Location**: `.project/active/render-switch-feedback/`

**Deliverables**:
- `.project/active/render-switch-feedback/{spec,design,plan}.md`
- `claude-pack/skills/_my_mental_model/visualize.md`
- `claude-pack/skills/_my_mental_model/feedback/html.md`

---

### Item 5: Packaging — Codex Parity and V1 Cleanup

**Type**: Code/Integration
**Effort**: 1-1.5 days
**Dependencies**: Items 2, 3, 4 (the real skill directory, with siblings and a nested feedback
directory, is this item's test subject)
**Required Reading**:
- `.project/active/directory-skill-build-pattern/spike-findings.md` — **read first.** 16 of 18 packaging assumptions answered against both runtimes, 2026-08-20. Two of its findings change D1-D4; the section "What this changes in the design" names them.
- `.project/active/directory-skill-build-pattern/spec.md` (written 2026-08-20 as old Item 2)
- `.project/active/directory-skill-build-pattern/design.md` (D1-D7)
- `.project/active/directory-skill-build-pattern/product-lens.md` (gate DISPOSED, three findings)
- `.project/concepts/mental-alignment-skill-design.md` (Distribution lane, Appendix)
- `.project/adr/0009-directory-skills-pattern.md`, `.project/adr/0011-native-skill-codex-adapter.md` (which supersedes `0010-native-skill-codex-lane.md` — read 0010 only for what changed)

**Objective**: Ship the skill directory on Codex with all of its files, and remove every remaining
v1 surface. Establish the reusable directory-skill packaging pattern that every future migration
uses.

**Why This Is One Work Item**:
- The build-script changes, install-script changes, allowlist entry, and name mapping are tightly coupled — testing any one requires the others
- The remaining v1 cleanup is a file-by-file checklist over the same scripts, so doing it separately would touch the same lines twice
- Running last means the lane is proven against the real skill instead of a placeholder

**In Scope (High Level)**:
- Extend `build-codex-pack.sh` to copy sibling files, including nested directories (`build-codex-pack.sh:395` matches only `SKILL.md` at `-mindepth 2 -maxdepth 2`, so `feedback/` is not even discovered)
- Extend `setup-codex.sh` to install sibling files (`setup-codex.sh:267` installs only `SKILL.md`), and fix the re-install gap: `install_path`'s managed-file check (`setup-codex.sh:19-22`) greps for `Generated from`, which a verbatim-copied sibling lacks, so siblings would be skipped on every install after the first
- Add `_my_mental_model` to `NATIVE_SKILL_ALLOWLIST` (`codex-overrides/config.sh:58`). **The entry must be the pack-side directory name `_my_mental_model`, not `my-mental-model` — the check is keyed on the source directory (`build-codex-pack.sh:370`), and a missing entry excludes the skill with no error** (product-lens spec-F2)
- Apply the `_my_x` → `my-x` name mapping for the dist directory and generated frontmatter
- Keep the SKILL.md frontmatter description plain prose (Codex YAML parse chokes on a leading `*`); native skills have no description override lane (`build-codex-pack.sh:243-255`)
- Wire the Codex resumed-render path per Item 1's findings
- **The Codex-side unknowns are resolved — no probe needed in this item** (`.project/active/directory-skill-build-pattern/spike-findings.md`, B1-B8). Codex loads a symlinked skill *directory*, but silently refuses to register a skill whose `SKILL.md` is a symlink. It reads flat, twice-nested, and non-markdown siblings, and tolerates stray files with no warning. Its working directory during a run **is** the skill directory. It accepts underscore-prefixed names. And it registers the **frontmatter `name`**, not the directory name — which kills the renamed-symlink simplification and makes D1's generated entry point mandatory rather than convenient. The derived Codex name must land in the generated frontmatter; `build-codex-pack.sh:386` already writes it, so the work here is to not simplify it away
- **Reopened by the same findings:** `~/.agents/skills/<name>` → `dist/codex/skills/<name>` as a whole-directory symlink would converge with no mirror logic at all. The design dismissed that on `build-codex-pack.sh:521`'s claim that "Codex reads copies, not symlinks", which the probe shows is false. Choose between it and D3's mirror deliberately, and correct that line plus `CLAUDE.md:53` either way. Hard constraint if symlinking: whole directory only, never `SKILL.md` alone
- **D4 rescoped, not dropped:** the stale-managed-symlink sweep in `setup-global.sh` is hygiene rather than a hazard. A dangling symlink in `~/.claude/skills/` is inert — absent from the listing, no warning, the rest of the skill set unaffected (`.project/active/directory-skill-build-pattern/spike-findings.md`, A10). Prioritise it as tidiness
- Remaining v1 cleanup: path rewrite at `build-codex-pack.sh:138`, shared-spec copy at `:426`, description override at `codex-overrides/config.sh:37`, `README.md:131` catalog row, `scripts/test_docs.sh` retired list, `scripts/uninstall-project.sh:108-114` skill list
- Rebuild `dist/codex/` and refresh both installs
- Convert `claude-pack/skills/example-skill.md` to directory form (`example-skill/SKILL.md` + a flat sibling + a nested sibling) and add a stale-managed-symlink sweep to `setup-global.sh`. **Rationale narrowed by the restructure**: the owner chose this conversion (2026-08-20) as the throwaway probe for the build lane, and the real skill is now the probe instead. The conversion still earns its place as the pack's copyable directory-skill example and as a regression fixture, and it retires a file two prior designs recorded as inert dead weight (`.project/active/pipeline-guide/design.md:41`) — but it is now droppable at the owner's discretion rather than load-bearing.

**Non-Goals / Out of Scope**:
- Any change to skill behavior — Items 3 and 4 own that
- ~~Widening the runtime-neutrality scan to sibling files; sibling neutrality stays convention-only per ADR 0010.~~ **Superseded 2026-08-20.** The owner reversed ADR 0010 (`.project/adr/0011-native-skill-codex-adapter.md`): skill bodies may carry harness-specific phrasing and the adapter translates every file. Sibling neutrality is no longer an obligation, so there is nothing to scan for. The owner also rejected any test that enumerates harness-specific phrases. Whether the existing scan survives at all is an Open Question in the revised spec
- Migrating the remaining `_my_*` commands to skills, or relocating the prose specs out of `claude-pack/scripts/` — deferred by ADR 0009's scope note
- Filing new ADRs. 0009 stands; 0010 was reversed by the owner and superseded by **0011** (filed 2026-08-20 at spec time, so it would not steer Items 3 and 4 while reversed). Item 5 implements 0009 and 0011, and updates the documents still citing 0010

**Success / Done State**:
- [ ] Every file of the skill directory reaches `dist/codex/skills/my-mental-model/` and then `~/.agents/skills/my-mental-model/`, at the same relative paths
- [ ] The skill resolves and runs on Codex, reading its sibling instruction file and its nested feedback file
- [ ] Re-running either installer converges: added files appear, changed files update, removed files disappear
- [ ] No v1 surface remains, and no script or test references one
- [ ] The pattern is generic: another directory skill with siblings works the same way, guarded by a regression check
- [ ] Existing tests pass

**Location**: `.project/active/directory-skill-build-pattern/`

**Deliverables**:
- `.project/active/directory-skill-build-pattern/plan.md` (spec, design, product-lens already written)

---

## Dependencies

**External**:
- Claude Code runtime: `SendMessage` continuation for the resume path, fork mechanism for carried policy
- Codex runtime: agent resume confirmed by Item 1; per-agent token reporting is absent

**Internal**:
- ADRs 0009 and 0011 (0011 supersedes 0010, reversed by the owner 2026-08-20) — Item 5 implements the decisions they record

**Item Dependency Graph**:
```
Item 1 (done) ──────────────────────────────┐
Item 2 (no deps)                            │
  └─► Item 3                                │
        └─► Item 4 ◄─────────────────────────┘
              └─► Item 5
```

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Directory-skill slash resolution doesn't work | High | Now proven in **Item 3**, on the real skill, before any packaging work depends on it (was Item 2; re-pointed per product-lens spec-F3). `setup-global.sh` symlink behavior is already verified, and underscore-prefixed skill directories were observed registering on Claude 2026-08-20. |
| A skill can't read its sibling files, or the reference form is cwd-dependent | **Resolved** | Answered by probe 2026-08-20 (`.project/active/directory-skill-build-pattern/spike-findings.md`, A6-A9, B4-B5). Siblings are readable on both runtimes — flat, nested, and through a symlink — so the split-instruction-file shape works and needs no other carrier. The reference form **is** cwd-dependent, and differently on each runtime, so the authoring rule is now fixed in Item 3's In Scope: bare filename in prose, never a path containing the skill's own directory name. Item 3 confirms rather than discovers. |
| Fork doesn't carry conversation reasoning effectively | Med | Tested in use during Item 3; the mechanism exists (`subagent_type: "fork"`); if quality doesn't improve, carried policy degrades to discovered, not to failure |
| Codex can't be measured for the token comparison | Low | Confirmed already by Item 1. Item 4 states the limitation instead of estimating. |
| Codex won't load symlinked skill directories or tolerate a name mismatch | **Resolved** | Probe run 2026-08-20 (`.project/active/directory-skill-build-pattern/spike-findings.md`, B1-B3). Symlinked directories load, and a name mismatch is tolerated — but Codex keys on the frontmatter name, so the simplification is dead and the copy-tree design (D1-D3) stands as written. A symlinked `SKILL.md` alone silently fails to register; never ship that shape. |
| A same-named command file shadows a new skill directory | Low | Unverified. The probe did not settle precedence between a user command and a user skill (`.project/active/directory-skill-build-pattern/spike-findings.md`, A3). Item 2 deletes the v1 command before Item 3 creates the skill, so ordering makes it moot — keep that order and the question never has to be answered. |
| V1 retirement misses a reference | Low | The concept-design's Appendix has a verified file-by-file inventory; existing tests (docs, pipeline-sync) catch most gaps. Item 2's two deletes are verified harmless on their own. |

---

## Timeline

**Total Effort**: 3-4.5 days remaining

| Item | Effort | Dependencies |
|------|--------|--------------|
| Item 1: Codex Resume Spike | done | — |
| Item 2: Release the Name | ~10 min | None |
| Item 3: Coordinator + Synthesis | 1-1.5 days | Item 2 |
| Item 4: Render + Switch + Feedback | 1-1.5 days | Item 3 |
| Item 5: Packaging | 1-1.5 days | Items 2, 3, 4 |

Strictly sequential now. The parallelism in the original plan existed only because the spike ran
alongside the build-pattern item; both of those are resolved or moved.

---

## Lessons Learned (Post-Completion)

*Fill in after epic is complete*

**What Went Well**:
- TBD

**What Could Improve**:
- Front-loading distribution plumbing ahead of the capability. The original decomposition led with
  the Codex build lane on the reasoning that it was reusable infrastructure; in practice it stalled
  the epic on packaging questions, and the dependency it was protecting turned out to be a single
  file deletion. Worth checking, next time, whether a claimed hard dependency survives reading the
  code.

**Surprises**:
- TBD

---

**Last Updated**: 2026-08-20
**Next Action**: Item 2 — delete the two v1 files — then `/_my_spec` for Item 3
