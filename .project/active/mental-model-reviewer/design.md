# Design: Mental-Model Reviewer and the Prompt-versus-Feedback Split

**Status:** Approved 2026-09-02 (owner proceeded to plan)
**Owner:** Reid W
**Created:** 2026-09-02 12:55 PDT
**Branch:** main
**Base commit:** b10c114 (plus the uncommitted 2026-09-02 promotion drafts in `claude-pack/skills/_my_mental_model/`)

## Overview

Split the skill's instruction files (rules) from its feedback files (examples), and add a reviewer that reads each artifact against the prompt and the feedback and leaves notes for the writer, inside the synthesis step and inside the render step. The coordinator launches the reviewer and forwards a path; it reads neither feedback nor notes.

## Related Artifacts

- **Spec:** `.project/active/mental-model-reviewer/spec.md`
- **Spec review:** `.project/active/mental-model-reviewer/spec-review.md`
- **Product lens:** `.project/active/mental-model-reviewer/product-lens.md`
- **Decision record:** `.project/adr/0012-mental-model-prompt-feedback-split-and-reviewer.md`
- **Epic:** `.project/backlog/epic_mental_alignment_skill.md`, Item 6
- **Required Reading:** `.project/concepts/mental-alignment-checkpoint.md` (decision 7, Non-Goals, "Superseded (2026-09-02)"); `.project/active/mental-model-quality-ownership/change.md`
- **Adapter:** `.project/adr/0011-native-skill-codex-adapter.md`; `.project/active/render-switch-feedback/harness-phrases.md`

## The Point

The skill exists to rebuild the owner's mental model on demand, through a synthesis and a visual explanation, spending the owner's attention once at the pause rather than across many correction rounds **[OWNER]** (concept, decision 1; quality-ownership change 2026-08-26). It improves through feedback, and that loop has to work without loading the writer with a growing list or the coordinator with everything **[OWNER]** (2026-09-02: "the core prompt SHOULD be the rules"; "keep its context as light as possible"). This design serves that obligation by giving each kind of knowledge to the one agent that can act on it: rules to the writer, examples to a reviewer that never saw the sources, and a path to the coordinator.

## Research Findings

- **Harness-block adapter.** `scripts/build-codex-pack.sh:187-231` holds `CODEX_SKILL_HARNESS_BLOCKS`, keyed by marker name. The substitution loop (`:236-262`) replaces a registered span with its Codex text, deletes a span registered empty, and **leaves the Claude wording in place for an unregistered key**. The dist scan (`scripts/test_codex_orchestrator_pack.sh:374-378`) then fails on `subagent_type`, `` `Agent` tool ``, or `general-purpose (subagent|agent)`. So every new harness-specific span needs a registered key. Existing keys: `skill-base-directory`, `synthesis-spawn`, `read-synthesis-file`, `correction-dispatch`, `render-dispatch`, `carried-fork`.
- **Codex can pick a model.** `spawn_agent` accepts `model?: string` (`.project/active/directory-skill-build-pattern/fork-spike-findings.md:74-78`), valid only with `fork_turns: "none"` or a turn count (`codex-overrides/rules/collaboration.md`). A fresh small-model reviewer therefore has a mechanism on both runtimes. The Codex model name is not known here.
- **Test assertions the split must not break.** `test_codex_orchestrator_pack.sh:349-357` asserts the dist `design_synthesis.md` still contains `fork_turns` (the `carried-fork` block must survive the rewrite) and the dist `SKILL.md` still contains the literal path `claude-pack/skills/_my_mental_model` (Step 10's promotion check) and `fork_turns: "none"`.
- **Coordinator step map.** `SKILL.md` has ten steps; cross-references to step numbers sit at `:25, :75, :116, :132, :136, :164, :168, :187, :191, :223-224, :248, :272, :316, :349`. The quality-ownership change renumbered once already; the harness-phrase table in `harness-phrases.md` records line numbers as history and is not maintained.
- **Existing send-back and confirmation pattern.** Step 5 (`SKILL.md:134-164`) sends a message to a recorded handle, asks the agent to amend and confirm, then re-reads the file. Step 7's "Confirming a render" (`:254-277`) says a named agent's turn output does not reliably reach the coordinator, so file existence is checked directly. Both patterns carry over unchanged to the review pass.
- **Fixture pattern.** `.project/active/anchor-on-the-point/fixture-planted-input.md` and `fixture-expected-findings.md` are the precedent for one-time planted-artifact acceptance evidence.
- **ADR 0009** (`.project/adr/0009-directory-skills-pattern.md`): long, improvable instructions live in sibling files the entry references. A reviewer instruction file is a sibling by that rule.
- **Source content for the split.** The 2026-09-02 drafts: `feedback/synthesis.md` (15 rules, 3 checks, 8 example groups) and `feedback/html.md` (9 rules, 3 checks, 6 examples). Appendix A maps every item to its destination.

## Core Concept

Three roles, three read sets, one relay. The **prompt** (`design_synthesis.md` for the synthesis, `visualize.md` for the HTML) is the contract and the only thing the writer has to satisfy; it now holds every generalized rule, each stated so it binds without an example. **Feedback** is a list of observed instances, pattern first, then a Bad and a Good, kept for a **reviewer** that never saw the sources. The reviewer runs once per artifact, inside the step that produced it, reads the artifact, the prompt, and both feedback tiers, and writes notes to a file beside the artifact. The **writer** reads the notes and amends as it sees fit. The **coordinator** launches the reviewer, forwards the notes path in one fixed sentence, waits for the writer to say it is done, and then runs its own check against the prompt alone.

The insight is that the two kinds of knowledge have different consumers. A rule is something the writer must always satisfy, so it goes where the writer looks. An example is evidence that a pattern has recurred, so it goes where a clean pair of eyes can match it. Mixing them made the writer read a list it could not converge on and made the coordinator carry everything. Separating them also gives promotion a job: a recurring reviewer hit is the signal that an example has earned its place as a rule.

The design composes with what exists. The correction gate (Step 5) is how any send-back travels, including the notes relay. The harness-block adapter carries the two new Claude-specific spans to Codex. The two-tier feedback files stay; recording (Step 10) gets a new entry shape, and promotion leaves the skill to become a two-line convention in the shared feedback headers. The runs directory already holds one file per artifact and gains one more. The planted-fixture pattern from anchor-on-the-point supplies the acceptance evidence.

## Key Bets

- **B1.** A model given only an artifact, the prompt, and the feedback list recognizes recorded patterns and prompt-structure misses at a useful rate. *If false → the pass adds a round-trip and no value; the planted-artifact check fails and the item stops there.* **Tested 2026-09-02:** true on sonnet (both plants, three entries cited by name, plus true unplanted defects); false on haiku (no example entry cited in any of four runs). The bet holds and D6 carries the size it needs.
- **B2.** Every rule that matters can be stated so it binds without an example beside it. *If false → the prompt fills with examples or the writer needs the feedback file again, and the split collapses back into one list.*
- **B3.** The writer, holding the notes and its own source context, makes better take-or-decline calls than the coordinator would from the notes alone. *If false → real findings get declined and reach the owner at the pause. The owner accepted this risk in spec-review L1-2.*
- **B4.** One pass per artifact captures most of the value. *If false → recurring defects survive to the pause more often than expected; a second pass is one more reviewer call and an owner decision.*

## Key Decisions

- **D1.** The reviewer's instructions live in a new sibling, `review.md`, in the skill directory. *Rejected: an inline brief in `SKILL.md` (long, needed twice, and ADR 0009 puts long improvable instructions in siblings).*
- **D2.** Notes go to a file beside the artifact, `{artifact stem}.review.md` in `.project/mental-alignment/runs/`, and stay there. *Rejected: a temporary file deleted after the writer reads it (destroys the only trail of recurring hits, which is what promotion to a rule needs). Rejected: returning notes in the reviewer's reply (passes through the coordinator's context, and delivery is unreliable per Step 7).*
- **D3.** The coordinator relays the path in one fixed sentence and never opens the file. *Rejected: coordinator reads and forwards content (heavy context; violates L1-2).*
- **D4.** Completion signal is the writer's reply, as in Step 5 today: the writer amends and replies that the artifact is final, without saying what changed. *Rejected: polling the artifact's modification time (fragile, and a no-change outcome is indistinguishable from not done).*
- **D5.** The reviewer brief carries the owner's question verbatim, taken from Step 2. *Rejected: reading it from the artifact (absent from the HTML under plain-document shape).*
- **D6.** Model selection sits in a new `reviewer-spawn` harness block: Claude uses the `Agent` tool with `model: "sonnet"`; the Codex substitution uses `spawn_agent` with `fork_turns: "none"` and `model` set to a mid-size model, name left to Item 5. **Amended at implementation 2026-09-02 (owner):** this decision read `haiku` / "the smallest available model" until the Phase 1 fixture runs measured it. *Rejected: the smallest available model — it matches stated rules but not recorded examples, which is most of the pass (six-run evidence in `fixture-expected-notes.md`). Rejected: default model, unmeasured.*
- **D7.** The coordinator reads `design_synthesis.md` before spawning the writer and `visualize.md` before dispatching a render, and nothing else. Its checks are the ones written in those files. *Rejected: narrowing the render check below the four items it has today (all four are in `visualize.md`, so dropping one means the final gate misses a prompt violation).*
- **D8.** Rules move into a `## Rules` section of each prompt file; the "Before delivering" checks move into the prompt as the writer's self-check. The reviewer reads the prompt, so it runs the same checks with fresh eyes. *Rejected: checks in the reviewer only (the writer's self-check is free and catches the obvious before a round-trip).*
- **D9.** One entry shape in both tiers: a pattern heading, a direction marker (`Avoid.` or `Prefer.`) with one line saying what to do, a Bad, a Good, and a `From:` line. **Amended at implementation 2026-09-02 (owner), twice.** The direction marker was added because a bare pattern heading over a situation description reads the same whether the pattern is wanted or unwanted, and every entry today is an `Avoid`. The `From:` line carries the date and the register (`synthesis` / `HTML render`) rather than a run path: the paths pointed into the owner's workspace and did not resolve from the pack repo, and the recurrence signal promotion uses is the date. *Rejected: today's date-plus-path heading with owner words and an `[AGENT]` line (not pattern-first; harder for a reviewer to match against a page).*
- **D10.** Promotion leaves the coordinator. Step 11 keeps recording only, in the D9 shape, plus a two-line pointer saying promotion happens outside a run in the pack repo (`claude-pack/skills/_my_mental_model/feedback/`). The convention itself lives in each shared feedback file's header: a rule goes into the prompt file, an example stays in the shared file, and the entry leaves the project-local file. No agent inside the skill writes to a prompt file or a shared feedback file. *Rejected: the coordinator-run promotion procedure the skill has today (owner, 2026-09-02: promotion happens with a different agent in a different context; the procedure described a workflow the owner does not use).*
- **D11.** No re-review after owner corrections at the pause, and no re-review after the writer amends. *Rejected: a second pass after amendment (B5; one more decision for the owner if B5 proves wrong).*
- **D12.** Acceptance evidence is a planted synthesis fixture and an expected-notes file in this item's directory, run by hand once against the reviewer alone. *Rejected: any check wired into the skill or the test suite (concept non-goal; ADR 0012 invariant).*
- **D13.** If the reviewer fails or writes no file, the coordinator says so in one sentence and proceeds to its own check. *Rejected: retrying or stopping the run (the reviewer is advisory; a missing pass costs nothing but the pass).*
- **D14.** The coordinator orchestrates the pass even though the writer could. A probe (Appendix C) shows a Claude subagent has both the `Agent` tool and `SendMessage`, so the writer could spawn the reviewer itself and the coordinator would never touch the pass. Chosen anyway for two reasons: the pass is guaranteed to run when the coordinator owns it, where a writer under context pressure can skip or shorten it; and the writer never learns the shared feedback path, so "the writer does not read shared feedback" is structural rather than trusted. The cost is two spawns and one relay of bookkeeping per artifact, with no content in the coordinator's context. *Rejected: writer self-review (invisible to the coordinator, but the read-set invariant becomes a promise and the pass becomes optional in practice).*

## Architecture

The pipeline shape is unchanged: synthesis, pause, render. Each step gains one internal pass between the writer finishing and the coordinator's own check.

```mermaid
sequenceDiagram
    participant O as Owner
    participant C as Coordinator
    participant W as Writer (synthesis or render agent)
    participant R as Reviewer (small model, fresh)

    O->>C: question
    Note over C: classify · read the prompt file only
    C->>W: question + prompt + local feedback (+ sources)
    W-->>C: artifact written
    C->>R: brief: artifact, question, prompt, shared + local feedback, notes path
    Note over R: structure vs prompt · patterns vs feedback, both directions<br/>no sources, no conversation
    R-->>C: notes file exists (path only)
    C->>W: one sentence: notes at <path>; apply what you judge right; reply when final
    W-->>C: "final"
    Note over C: own check: prompt compliance only
    C->>W: defects via correction gate (2 rounds max)
    C->>O: artifact · pause
```

**Read sets.**

| | Writer | Reviewer | Coordinator |
|---|---|---|---|
| Prompt file | yes | yes | yes |
| Project-local feedback | yes, binding | yes | no |
| Shared feedback | no | yes | no |
| Sources, conversation | yes (per policy) | no | as today |
| Notes file | yes | writes it | never opens it |

**Where the pass sits in `SKILL.md`.** A new Step 4, "The review pass", follows the synthesis spawn and precedes the coordinator's review (old Step 4, now Step 5). In the render step (old Step 7, now Step 8), the same pass runs after each render's file exists and before "Confirming a render"; on a comparison it runs once per HTML. Appendix B lists the renumbering.

**The review pass, in order.** Confirm the artifact file exists at its path. Spawn the reviewer with the brief (D5, D6) and the notes path `{stem}.review.md`. Confirm the notes file exists; if not, D13. Send the fixed relay sentence (D3) to the handle recorded when that artifact's writer was spawned or dispatched: the synthesis agent for the synthesis and for a resumed render, the fresh render agent for a fresh render. Wait for the writer's reply (D4). Re-confirm the artifact exists. Proceed to the coordinator's own check.

**The reviewer brief.** Register (synthesis or HTML), the owner's question verbatim, absolute paths to the artifact, the prompt file, the shared feedback file, the project-local feedback file if present, and `review.md`, plus the notes output path. Nothing else: no source paths, no policy, no conversation.

**The notes file.** A heading naming the artifact, the question, and what it was reviewed against. Then two lists, most important first: things to reconsider (each cites the rule or feedback entry it rests on and names where in the artifact), and techniques worth considering (each cites the entry and says where it would apply). A cap of ten items total keeps the writer reading. A note that cites nothing is not a note; `review.md` says so.

**Recording only.** Step 11 (old 10) records project-local entries in the D9 shape. Its Promotion subsection shrinks to the two-line pointer in D10; the literal pack path stays so the existing dist assertion (`test_codex_orchestrator_pack.sh:357`) still holds.

## Required Invariants

- The writer's spawn prompt and the render brief never name a shared feedback path.
- The reviewer brief never names a source file, a policy, or the conversation, and the reviewer is never a fork.
- The coordinator never opens a `*.review.md` file. Its send-backs cite the prompt file and nothing else.
- Neither the notes nor the writer's decisions are presented to the owner. The file exists on disk and the skill does not hand it over.
- Every entry in both feedback tiers carries a `From:` line naming the run and artifact.
- No agent inside the skill writes to a prompt file or a shared feedback file. Promotion is done outside a run.
- A rule in a prompt file stands without an example beside it.
- Every new Claude-specific span in `SKILL.md` sits inside a keyed `harness-block` with a registered substitution; `review.md` names no tool and needs none.
- The dist `design_synthesis.md` still contains the `carried-fork` block; the dist `SKILL.md` still contains `claude-pack/skills/_my_mental_model` and `fork_turns: "none"`.
- The reviewer never blocks a run. A missing or failed pass is reported in one sentence and the run continues.
- One notes file per artifact. If the path is taken, the reviewer stops and reports, as the render agent does for HTML.

## Component Overview

- **`SKILL.md`** (coordinator). Step 3 reads the prompt only and the spawn prompt drops the shared feedback. New Step 4 runs the review pass. Old Steps 4-10 become 5-11. Step 8 adds the same pass per render. Step 11 keeps recording in the D9 shape; its Promotion subsection becomes the two-line pointer (D10). Two new harness blocks: `reviewer-spawn` (D6) and `notes-relay` (the relay sentence names the message tool).
- **`design_synthesis.md`** (synthesis prompt). Gains `## Rules` and `## Before delivering`, absorbing the rules from the draft feedback file per Appendix A. Regions, limits, judgment, and the `carried-fork` block are unchanged.
- **`visualize.md`** (render prompt). Gains `## Rules` and `## Before delivering` per Appendix A. Safety, shape, provenance, and sources sections are unchanged.
- **`review.md`** (new, reviewer prompt). The stance (fresh eyes, no domain), the inputs, the two directions, the citation requirement, the note format and cap, the output rule (write the file, return the path and nothing else), and what it never does (read sources, edit anything, judge the content's conclusions).
- **`feedback/synthesis.md`, `feedback/html.md`** (shared examples). A short header defining an entry and stating the promotion convention (D10), then entries in the D9 shape. No rules.
- **`scripts/build-codex-pack.sh`.** Two new `CODEX_SKILL_HARNESS_BLOCKS` keys.
- **`scripts/test_codex_orchestrator_pack.sh`.** One presence assertion for the dist `review.md`.
- **`.project/active/render-switch-feedback/harness-phrases.md`.** Two new rows for the phrases the new blocks introduce.
- **Fixtures** in `.project/active/mental-model-reviewer/`: `fixture-planted-synthesis.md`, `fixture-expected-notes.md`.

## Non-Goals

- Reviewing the coordinator's own prose, the spawn prompts, or the briefs.
- Scoring, grading, or ranking artifacts. Notes are suggestions with citations, nothing more.
- Promotion mechanics of any kind inside the skill. Promotion is a convention followed outside a run.
- Validating the reviewer on Codex, or naming the Codex model. Item 5.
- Pruning the echo-workspace project-local files.
- Changing the pause, the render switch, the comparison, or the `# Renders` bookkeeping.

## Implementation Notes

- **Renumber carefully.** Fourteen in-file cross-references to step numbers (Research Findings). Update every one; the quality-ownership change is the precedent and did not touch `harness-phrases.md` line numbers.
- **Markers on their own lines.** `substitute_harness_blocks` matches a whole line equal to `<!-- harness-block: key -->`. Indented or inline markers survive into dist and fail the marker scan.
- **The relay sentence is fixed text.** Something close to: "Review notes for `<artifact>` are at `<path>`. Read them, apply what you judge right, and reply when the file at `<artifact path>` is final. Do not say what you changed." Vary nothing per run except the paths.
- **`review.md` must tell the reviewer to ignore a trailing `# Renders` section** in a synthesis, as `visualize.md` does for the render agent.
- **Keep the split honest.** For each item in Appendix A, apply the placement test: state it without its example; if it still binds, it is a rule. Where the test is close, feedback wins, because a rule that needs an example is the failure the owner named.
- **Spawn prompt and render brief.** Remove `<base>/feedback/synthesis.md` and `<base>/feedback/html.md` from both; keep the project-local paths. The render brief added this morning also lists the synthesis feedback files; both shared entries go, the local one stays.
- **Codex rebuild is allowed.** The epic's "do not rebuild dist before Item 5" note lapsed when the 2026-08-26 change rebuilt and reinstalled.

## Potential Risks

- **Reviewer noise.** A small model may produce many weak notes and the writer stops reading. Mitigation: the ten-item cap, most-important-first ordering, and the citation requirement in `review.md`. A note with no rule or entry behind it is dropped by definition.
- **Invented rules.** The reviewer flags something that is in neither the prompt nor the feedback. Same mitigation: every note cites its source; the writer is told uncited notes carry no weight.
- **Silent decline.** The writer ignores every note and nobody knows. Accepted by the owner (L1-2). The notes file on disk is the only trail, and it is there for the owner to open when a pattern recurs.
- **Codex model unknown.** The substitution names "the smallest available model" without an identifier. Item 5 resolves it; until then Codex runs the reviewer on whatever `spawn_agent` picks for that phrase, which may be the default.
- **Prompt bloat.** Moving rules into the prompt files makes them longer. Mitigation: one line per rule, no examples, and the placement test.

## Integration Strategy

The pass slots between two existing beats in each step and touches nothing outside them. Claude picks up the change immediately through the directory symlink. Codex needs `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy`, as before. The echo-workspace project-local files keep working unchanged; new entries there use the D9 shape from the next recording onward, and the reviewer reads old and new entries alike.

## Validation Approach

1. **Fixture first, before wiring.** Write `fixture-planted-synthesis.md` with one known anti-pattern from the shared feedback and one opening for a recorded technique. Run a haiku agent with `review.md` and the two feedback files against it. It flags both, with citations. This is B1's test and the cheapest thing to fail on.
2. **Build checks.** `./scripts/test_codex_orchestrator_pack.sh` and `./scripts/test_docs.sh` pass; `git diff --check` clean; the dist `SKILL.md` and `review.md` inspected by hand for leaked tool names.
3. **Live run in echo-workspace.** One `/_my_mental_model` run with the reviewer in the loop on the synthesis and at least one render. The coordinator's transcript shows it read `design_synthesis.md`, `visualize.md`, and the artifacts, and no feedback file and no notes file. The reviewer is not required to find anything.
4. **Split audit.** Every Appendix A row landed where it says. No numbered rule remains in a feedback file. Every rule in a prompt file passes the placement test on a read-through.

## Next-Stage Handoff

- **Fixed (owner, 2026-09-02):** the coordinator runs the pass (D14); notes persist beside the artifact (D2); promotion leaves the coordinator (D10). Also fixed: the three read sets; `review.md` as a sibling; the relay sentence and the writer's reply; one pass per artifact; the D9 entry shape; the two harness-block keys; the fixture as one-time evidence.
- **Open:** the Codex model identifier (Item 5); the exact cap on notes if ten proves wrong in the fixture run; whether the writer should be told at spawn time that a review pass follows, or only at relay (relay only is the default).
- **Overturned upstream:** the spec inferred that subagents cannot address each other. The probe says they can (Appendix C). The design keeps the relay by choice (D14); the spec line is amended to match.
- **De-risk first:** the fixture run (Validation step 1). If haiku cannot flag a planted pattern with the feedback file in hand, B1 is false and the rest of the item should not be built.

## Appendix A — Where each draft item lands

Placement test: state it without its example. Still binds → rule (prompt). Needs the example → feedback.

**From the draft `feedback/synthesis.md`** (rule numbers as written this morning):

| Item | Destination |
|---|---|
| 1 stop-anywhere order | `design_synthesis.md` Rules (merges with "important things first") |
| 2 heading shape; owner's outline words; no counts unless the finding; vary shape | `design_synthesis.md` Rules ("just say the thing") |
| 3 distinct-meaning test | `design_synthesis.md` Rules |
| 4 engineer voice; subject and verb; define terms first | `design_synthesis.md` Rules |
| 5 abstraction performing a verb | `feedback/synthesis.md` entry, with its Bad/Good |
| 6 document as subject; announcing what comes next | `feedback/synthesis.md` entry |
| 7 clause the reader already has | `feedback/synthesis.md` entry |
| 8 negative clause for rhythm | `feedback/synthesis.md` entry (owner's example of a non-rule) |
| 9 purpose before mechanism | `design_synthesis.md` Rules |
| 10 structure before members; name the members | `design_synthesis.md` Rules; the category-by-count pair → `feedback/synthesis.md` entry |
| 11 ground in code shape | `design_synthesis.md` Rules |
| 12 layer discipline | `design_synthesis.md` Rules |
| 13 define or measure, never both | `design_synthesis.md` Rules; the headlined-by-a-result instance → `feedback/synthesis.md` entry |
| 14 reader's confusion is the spec | `design_synthesis.md` Rules (governs amendments) |
| 15 medium switch past three or four phrases | `design_synthesis.md` Rules |
| Before delivering (3 checks) | `design_synthesis.md` Before delivering |
| Heading pairs, fragments | `feedback/synthesis.md` entries (stat-dump headings; fragments) |

**From the draft `feedback/html.md`:**

| Item | Destination |
|---|---|
| 1 fewest words; detail ahead of the answer | `visualize.md` Rules |
| 2 numbered outline; never collapse main flow | `visualize.md` Rules |
| 3 structural headings `TLDR`, `Judgment`, `Appendix` | `visualize.md` Rules |
| 4 collapse placement, two kinds of detail | `visualize.md` Rules |
| 5 lead with figures | already in `visualize.md`; dropped from feedback |
| 6 one visual grammar | `visualize.md` Rules |
| 7 figure explanation in body; short caption | `visualize.md` Rules |
| 8 section ids; anchor links | `visualize.md` Rules |
| 9 persistent navigation | `visualize.md` Rules |
| Before delivering (3 checks) | `visualize.md` Before delivering |
| Outline shape block | `visualize.md` Rules, as the schema for item 2 |
| Collapsed page, caption, dropdown summary, structural heading, cross-link | `feedback/html.md` entries |

The five orphaned rules from the deprecated 2026-08-18 file are items 9, 10, 11, 12, 14 above and land in the prompt.

## Appendix B — `SKILL.md` step plan

| Today | After | Change |
|---|---|---|
| 1 Note the skill directory | 1 | none |
| 2 Classify | 2 | none |
| 3 Prepare and spawn | 3 | "Read the standard first" reads `design_synthesis.md` only; spawn prompt drops item 5 (shared feedback) |
| — | **4 The review pass** | new: spawn reviewer (`reviewer-spawn`), confirm notes file, relay (`notes-relay`), wait for the writer's reply |
| 4 Review the synthesis | 5 | sources: `design_synthesis.md` and the writing rules only; feedback-file bullet deleted |
| 5 Correction gate | 6 | none beyond renumbering |
| 6 Present and pause | 7 | none |
| 7 Route the render | 8 | brief drops both shared feedback paths; a review pass per render before "Confirming a render"; the coordinator reads `visualize.md` only |
| 8 Record the readings | 9 | none |
| 9 Judgment read-back | 10 | none |
| 10 Feedback and promotion | 11 | D9 entry shape for recording; Promotion subsection reduced to a two-line pointer that keeps the pack path |

## Appendix C — Probe: can a Claude subagent launch or message agents?

Run 2026-09-02 from this session: a fresh `general-purpose` agent on `haiku`, told to take no action and report from its tool list only. It answered YES to both questions and listed `Agent` and `SendMessage` among its tools. The probe checked the tool list, not an actual nested spawn, so execution is unexercised. It is enough to remove the necessity claim: the relay through the coordinator is a decision (D14), not a constraint. The spec's inferred item on this point is corrected there.

---
Next Step: After approval → `/_my_plan`
