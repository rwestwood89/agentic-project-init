# Design: Spike and Learning-Test Commands

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02 09:02
**Branch:** workflow-orchestrator
**Git Hash:** 0a6aac2

---

## Overview

Two new lightweight `_my_*` commands — `/_my_spike` and `/_my_learning_test` — that let an
agent write throwaway or exploratory code to learn how something actually behaves, then feed
the learning back into the pipeline. Plus soft-suggestion wiring in the shaping/spec/design
commands so agents reach for them when uncertainty is high, and Codex + docs exposure.

---

## Related Artifacts

- **Spec:** `.project/active/spike-and-learning-test-commands/spec.md`
- **Epic:** none — standalone work item.
- **Pattern references:** `claude-pack/commands/_my_research.md` (closest kin, read-only),
  `claude-pack/commands/_my_quick_edit.md` (lightweight staged command).

---

## Research Findings

**Command file convention** (`claude-pack/commands/_my_*.md`): a header block
(`**Purpose:** / **Input:** / **Output:**`), an Overview, a staged Process, Guidelines, and
a `**Related Commands:**` + `**Last Updated**:` footer. `_my_quick_edit.md` is the model for a
lightweight staged command; `_my_research.md` for an investigation command that writes a
findings doc.

**`/_my_research` is read-only** (`_my_research.md:29-45`): it spawns Explore/general-purpose
subagents to analyze *existing* code and writes `.project/research/{ts}_{topic}.md`. It never
writes probe code. This is the gap the two new commands fill, and the boundary to cross-link.

**Codex pipeline** (`CLAUDE.md` "Codex Compatibility Layer", `codex-overrides/config.sh`):
every non-excluded command needs a key in `COMMAND_SKILL_DESCRIPTIONS` (`config.sh:24-46`),
then `./scripts/build-codex-pack.sh` + `./scripts/setup-codex.sh --copy`. The excluded set
(`config.sh:6-11`) is only commands that depend on Claude-only hooks/transcript machinery —
spike and learning test have no such dependency, so they are **included** (get description
keys), not excluded.

**Wiring anchors already exist in the target commands:**
- `_my_concept_design.md` Next-Stage Handoff has a **"First risk to de-risk"** bullet
  (`_my_concept_design.md:326`) — the natural place to suggest a spike.
- `_my_spec.md` Stage 2 has **"Offer research, don't guess"** (`_my_spec.md`, questioning
  loop) — extend it to offer a spike/learning test when the unknown is behavioral.
- `_my_design.md` REFLECT step asks **"What am I assuming? Do these need validation?"** and
  the **Key Bets** section already frames unvalidated beliefs with "if false → what fails" —
  the anchor for suggesting a spike to validate a cheap-to-test bet.
- `_my_epic_plan.md` Stage 3 reasons about **Required Reading** and risks per item — the anchor
  for surfacing a de-risking spike as an early item.

**Metadata:** commands reference `.project/scripts/get-metadata.sh` (present in target projects
via `project-pack/`, absent in this meta-repo) with a git+date fallback.

---

## Core Concept

The pipeline is top-down and assumes the mechanism is known. These two commands are the
**escape hatch to bottom-up learning**: when you can only find out how something behaves by
running code, you stop planning and write code to find out. They are the write-code-to-learn
counterpart to `/_my_research`'s read-code-to-understand.

The two commands split on **two axes at once**, which is why they are separate and not one
command with a flag:

| | Intent | Output that survives |
|---|---|---|
| **`/_my_spike`** | de-risk a *known* goal (confirm an assumption) | a findings doc; scratch scripts thrown away |
| **`/_my_learning_test`** | *discover* how an unfamiliar surface behaves | a findings doc **+ real tests** kept in the repo's test suite |

Both share one discipline — the thing that makes hands-on work pay off instead of vanishing:

1. **Reproducible.** Everything you do is captured so it can be re-run. No un-recorded
   manual pokes.
2. **A living findings doc.** Write it as you go, updating as you learn — not a report bolted
   on at the end.
3. **Summary last, on top.** Just before finishing, write a findings summary at the *top* of
   the doc, so the next reader gets the answer first.
4. **Close the loop.** On completion, write a reference to the findings doc back into whatever
   upstream artifact triggered the work (concept, spec, epic). The learning re-enters the
   pipeline instead of dead-ending in an orphan report.

That shared discipline is the real design. The two commands are two front doors to it, differing
only in intent framing and where their durable output lands.

---

## Key Bets

- **B1.** The spike-vs-learning-test distinction is legible enough that an agent, mid-pipeline,
  picks the right one from the situation. *If false → the two commands blur, agents invoke
  them interchangeably, and the split that justifies two commands collapses into confusion.*
- **B2.** A soft suggestion embedded at the right pipeline moment is enough to get the technique
  used; it does not need to be a gate. *If false → the commands exist but are never reached for,
  and de-risking stays ad hoc.*
- **B3.** Writing a back-reference into the upstream doc is enough to re-integrate the learning.
  *If false → findings docs accumulate unread and the pipeline keeps planning on stale
  assumptions despite the spike having been run.*

## Key Decisions

- **D1. Two separate command files**, not one with a mode. *Rejected: single `/_my_probe` with
  a `--mode` flag (the intent×output split is the whole point; one command would force the
  agent to carry the distinction in prose anyway, losing the legibility of B1).*
- **D2. Spike findings + scripts co-locate in the work-item folder**, or in a command-created
  `active/spike-{topic}/` when no work item exists. *Rejected: a global `.project/spikes/` area
  (scatters a spike's scripts away from the item it de-risks; the folder-per-spike keeps
  everything for one question together and greppable).*
- **D3. Learning-test findings doc goes in `.project/research/`** (`{ts}_{topic}.md`, matching
  `_my_research`), while the *tests* go in the repo's existing test directory. *Rejected:
  work-item folder (a learning test maps a surface and is usually not tied to one item; its
  discovery notes belong with other investigation output, and its durable artifact is the test,
  not the doc).*
- **D4. Learning tests never live under `.project/`.** The command instructs the agent to
  locate the repo's real test directory and place tests there; it hardcodes no path. *Rejected:
  a fixed `tests/` path (repos differ; a hardcoded path would be wrong in most projects).*
- **D5. Both commands are Codex-included**, with description keys `spike` and `learning-test`.
  *Rejected: excluding them (they have no Claude-only dependency, unlike the capture/recall set).*
- **D6. Wiring is soft suggestion at existing anchors**, phrased to distinguish the two cases.
  *Rejected: adding a mandatory de-risk gate to the pipeline (contradicts the spec non-goal and
  B2; would add friction at exactly the creative moments).*

---

## Architecture

Two artifact types, one shared discipline, and a set of one-way suggestion pointers into the
existing pipeline.

```
                 (soft suggestions, not gates)
  concept_design ─┐
  spec ───────────┼──► /_my_spike ──────► findings doc + scratch scripts
  design ─────────┤        │              in active/{item}/ or active/spike-{topic}/
  epic_plan ──────┘        │
                           └─► close the loop: back-ref into upstream doc
  concept_design ─┐
  spec ───────────┼──► /_my_learning_test ─► findings doc in .project/research/
  design ─────────┘        │                 + real tests in the repo's test dir
                           └─► close the loop: back-ref into upstream doc

  research ◄───► spike / learning_test   (cross-reference: read-only vs write-to-learn)
```

**Data flow for a spike:**
1. Agent (or user) invokes `/_my_spike` with a question/assumption to de-risk.
2. Command determines its home: active work-item folder if one is in play, else create
   `active/spike-{topic}/`.
3. Agent probes — tries approaches, writes scratch scripts into that folder, records each step
   in a living findings doc so it is reproducible.
4. Before finishing, agent writes the findings summary at the top of the doc.
5. Agent closes the loop: adds a reference to the findings doc in the upstream artifact that
   motivated the spike.

**Data flow for a learning test:** same shape, except the durable output is a set of real tests
placed in the repo's own test directory (agent locates it), and the findings doc lands in
`.project/research/`.

---

## Required Invariants

- **Reproducibility.** Anything done during a spike/learning test is recorded such that a reader
  could re-run it. No untracked manual steps that leave no trace.
- **Summary-on-top.** The findings doc's top section is a summary written last.
- **Loop closure.** A completed spike/learning test always leaves a back-reference in the
  triggering upstream doc (or, if none exists, tells the user there was nothing to link and why).
- **Spike code stays with its item.** Spike scripts live in the work-item or `spike-{topic}/`
  folder — never scattered elsewhere.
- **Learning tests are real tests in the real test dir.** Never scratch scripts, never under
  `.project/`.
- **Suggestions never block.** Pipeline wiring offers the technique; it never halts the pipeline
  waiting on one.

---

## Component Overview

**New command files** (in `claude-pack/commands/`):

- **`_my_spike.md`** — Purpose: de-risk a known assumption with a throwaway probe. Staged
  process: (1) understand the question; (2) locate/create the home folder; (3) probe, writing
  reproducible scratch scripts + a living findings doc; (4) summary-on-top; (5) close the loop.
  Output: findings doc + scripts in `active/{item}/` or `active/spike-{topic}/`.
- **`_my_learning_test.md`** — Purpose: discover how an unfamiliar surface behaves by writing
  real tests. Same staged shape; output: findings doc in `.project/research/` + tests in the
  repo's test directory (agent locates it; prompt states this explicitly).

**Modified command files** (add a short soft-suggestion block at the named anchor):

- `_my_concept_design.md` — at the "First risk to de-risk" handoff bullet.
- `_my_spec.md` — extend "Offer research, don't guess" to offer a spike/learning test.
- `_my_design.md` — at REFLECT / Key Bets, suggest a spike to validate a cheap-to-test bet.
- `_my_epic_plan.md` — surface a de-risking spike as a candidate early backlog item.
- `_my_research.md` — cross-reference: research is read-only; use spike/learning test to write
  code to learn. (Reciprocal pointers in the two new commands' Related Commands footers.)

**Config / build:**

- `codex-overrides/config.sh` — add `["spike"]=...` and `["learning-test"]=...` to
  `COMMAND_SKILL_DESCRIPTIONS`.
- Run `setup-global.sh`, then `build-codex-pack.sh` + `setup-codex.sh --copy`.

**Docs:**

- `CLAUDE.md` and `README.md` — document both commands and when to reach for each (spike =
  known goal/verify; learning test = fuzzy goal/probe). README command-reference table gets two
  rows.

---

## Non-Goals

- Not changing core pipeline stages; not making de-risking a mandatory gate.
- Not prescribing where kept learning tests live in a given project's layout (agent locates it).
- Not building runtime machinery to run, track, or clean up spikes. These are prompt definitions.
- Not designing a shared "include" mechanism for the common discipline — the platform has none
  for commands; the two files each carry the discipline (minor duplication, accepted).

---

## Implementation Notes

- **Findings-doc shape (both commands)** — the reference voice the user gave:
  ```
  # {Spike|Learning Test}: {topic}
  ## Summary of Findings   ← written last, sits on top
  ## Question / Goal
  ## Log                   ← living; appended as you go, reproducible steps + observations
  ## Reproduction          ← how to re-run everything
  ## Open Questions / Follow-ups
  ```
  Prompt language to carry through: "probe how this can work — take your time, try different
  approaches"; "document findings in a write-up, updating it as you go; everything you do
  should be reproducible"; "just before you finish, write a summary of findings at the top."
- **Close-the-loop instruction** — the command tells the agent to identify the triggering
  artifact from context (the concept/spec/epic it paused out of); if unclear, ask the user.
  Add the reference where that doc type keeps links: spec/design **Related Artifacts**, concept
  **Next-Stage Handoff**, epic **Source Documents** (or the item's Required Reading). Note what
  the spike resolved, not just the path.
- **Codex description keys** must be plain prose (no leading `*` / `**`) — the build parses YAML
  strictly (`CLAUDE.md` "Why the description override matters"). Pattern:
  `"<action>. Use when <trigger>."`
  - **Spike resolved (2026-07-03), see `findings.md`:** a leading `*`/`**` is confirmed to break
    the SKILL.md YAML (alias reference), and the build does *not* catch it — `build-codex-pack.sh:250`
    emits the description raw, unquoted, with no validation. But the rule is *narrower* than
    "plain prose": mid-value colons are safe (three shipped descriptions already contain them and
    load fine in Codex). The only real constraint for the two new keys is: do not start with `*`
    or `**`. The `"<action>. Use when <trigger>."` pattern already satisfies this.
- **`setup-global.sh` first**, or the new commands won't resolve in other sessions
  (`[HARD]` from spec; matches known gotcha).
- **Metadata:** follow the existing pattern — call `.project/scripts/get-metadata.sh`, fall back
  to git + system date. (Absent in this meta-repo; present in target projects.)

---

## Potential Risks

- **Blur between the two commands (B1).** Mitigation: each command's Overview opens with a
  one-line "use this when… / for the other case use …" contrast; the wiring blocks phrase the
  choice explicitly (clear goal → spike; fuzzy surface → learning test).
- **Suggestions ignored (B2).** Mitigation: place them at anchors agents already read
  (Key Bets, First risk to de-risk, Offer-research) rather than a new section they might skip.
- **Loop not closed (B3).** Mitigation: make loop-closure a Required Invariant and an explicit
  final stage in both commands, not a soft "consider."
- **Docs drift.** Adding commands means README table + CLAUDE.md + Codex config must all move
  together; the audit step should check they did.

---

## Integration Strategy

Additive. No existing command changes behavior — the five pipeline edits only add an optional
suggestion block. The two new commands slot beside `/_my_research` as the write-to-learn siblings
of read-to-understand. `/_my_close` already archives the work-item folder, so spike scripts
travel with the item on archive (the spec's open question — confirmed as acceptable here: they
are scratch and belong with the item that motivated them).

## Validation Approach

- **Commands available:** after `setup-global.sh`, `/_my_spike` and `/_my_learning_test` resolve
  in a fresh session.
- **Codex build clean:** `build-codex-pack.sh` + `setup-codex.sh --copy` produce
  `my-spike/SKILL.md` and `my-learning-test/SKILL.md` with valid YAML (no `*`-leading
  description).
- **End-to-end dry run:** invoke `/_my_spike` on a real small unknown (candidate: the
  workflow-orchestrator item's subagent-invocation spike, already queued in CURRENT_WORK.md) —
  confirm it creates the right folder, writes a reproducible living doc with summary-on-top, and
  writes a back-reference into the triggering doc.
- **Wiring reads right:** re-read the five modified commands; each suggestion is soft, correctly
  placed, and distinguishes the two techniques.
- **Docs consistent:** README table, CLAUDE.md, and Codex config all list both commands.

## Next-Stage Handoff

**Fixed:** two separate commands (D1); spike output location (D2); learning-test split of
findings→research, tests→repo test dir (D3, D4); Codex-included (D5); soft-suggestion wiring at
the four named anchors + research cross-ref (D6); the shared four-part discipline.

**Open for the plan:** exact command names (`_my_spike` / `_my_learning_test` proposed);
final findings-doc section headings; exact prose of each suggestion block and each Codex
description string.

**De-risk first:** the close-the-loop instruction — whether "identify the triggering artifact
from context, else ask" is reliable enough in practice. Worth exercising in the end-to-end dry
run before considering the pattern settled.

---

**Next Step:** After approval → `/_my_plan`.
