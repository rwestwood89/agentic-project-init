# Design: Pipeline Guide (shipped, canonical)

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Branch:** workflow-orchestrator (candidate for its own branch)
**Commit at design time:** e18c093

---

## Overview

Ship one canonical, current description of the pipeline with `claude-pack`, so any agent in any
project can reach it at runtime. Deliver it as a lightweight always-on **rule** (the stage shape +
a pointer) plus a fuller on-demand **command** `/_my_pipeline` (the overview + guide).

## Related Artifacts

- **Spec:** `.project/active/pipeline-guide/spec.md`
- **Motivating consumer:** `.project/active/workflow-orchestrator/` (points here instead of restating the flow)
- **Stale doc to rewire:** `project-pack/README.md`
- **Existing human docs (out of scope):** `docs/guide.md`, `docs/working-with-claude.md`

## Research Findings

- **Rules install and auto-load.** `setup-global.sh:137-143` symlinks every `claude-pack/rules/*.md`
  into `~/.claude/rules/`. These load into every session (context-loading.md, working-voice.md, etc.
  already do). A new rule ships with no installer change.
- **Commands install and are invokable — no installer change.** `setup-global.sh:99-103` symlinks
  every `claude-pack/commands/*.md` into `~/.claude/commands/`. A command is invokable by a human
  (`/_my_pipeline`) and surfaced to an agent through the Skill tool (the `_my_*` entries in the
  available-skills list). An agent can also `Read` it directly by path.
- **Commands are the currency the orchestrator already uses.** The orchestrator spawns headless
  subagents by running `/_my_<stage>` commands via `orchestrate-stage.sh` (`_my_orchestrate.md:17-28`).
  A `/_my_pipeline` command fits that mechanism with nothing new.
- **A skill was rejected.** A real Claude Code skill is a *directory* with `SKILL.md`
  (`~/.claude/skills/flex-study-helper/SKILL.md:1-5`); `setup-global.sh:127-131` symlinks skills with
  `[ -f "$file" ] || continue`, skipping directories, so a skill would need an installer change that
  brushed a spec non-goal. Its one edge over a command — spontaneous model auto-invocation — is
  marginal here because the always-on rule already carries awareness and the pointer. (The lone flat
  `skills/example-skill.md` is symlinked but never registers; it is unrelated dead weight, left as-is.)
- **The stale flow is one table, not the whole README.** `project-pack/README.md:36-45` carries the
  stale `Spec→Design→Plan→Implement→Review` sequence. The command index below it
  (`README.md:100-140`) is reasonably current. Only the flow table diverges.
- **The orchestrator already restates the flow inline.** `_my_orchestrate.md:36-44` lists
  `spec→design→plan→implement→audit→pre_pr` with the review pairings — the inline half-flow the spec
  wants to kill. Rewiring it belongs to the orchestrator item (spec Non-Goal); this design only makes
  the source it points at.

## Core Concept

There is exactly one authored description of the pipeline, and it lives in the **command**
(`claude-pack/commands/_my_pipeline.md`). The command holds both layers the spec asks for: an
**overview** (the stage map — order, entry points, optional stages, review pairings, the epic-vs-
single-item branch) and a **guide** (when and how to use each stage). For per-stage depth the command
points at each stage command's own doc, so it can never drift from the commands.

The **rule** (`claude-pack/rules/pipeline.md`) exists only to make every session aware the pipeline
exists and where to find it. It carries the bare stage *shape* — one compact ordered line — and a
pointer: run `/_my_pipeline` (or read its doc) for the full flow. The shape is the minimum an agent
needs to orient; the command is the source for everything else.

The key insight: **duplication is killed by direction, not by deletion.** We can't delete the shape
from the rule (then there's no always-on awareness) and we can't delete it from the command (the
command is the fuller source and must stand alone). So the shape appears in both — but it is the
*only* thing duplicated, it is a single short line, both files ship and are maintained together from
`claude-pack`, and a tiny test asserts they stay identical. Everything else — every consumer (the
stage commands, the project-pack README) — stops carrying its own copy and points here instead.

This composes with existing pieces, adding no new mechanism:
- **Rules loader** handles always-on awareness — we add one rule.
- **Commands loader** handles the on-demand guide — we add one command; it installs and is invokable already.
- **Each stage command's own doc** remains the source of per-stage detail — the guide references, never restates.

## Key Bets

- **B1.** A one-line stage shape in an always-on rule is enough orientation, and pointing to the
  command for depth is enough to keep sessions from bloating. *If false → either sessions lack the
  awareness the spec requires (shape too thin), or the rule grows until it is the context weight we
  were avoiding.*
- **B2.** An agent that needs the flow will follow the rule's pointer (read the command doc, or invoke
  it) and reach the guide at runtime. *If false → consumers keep inlining their own half-flows because
  reaching the canonical one is too indirect, and divergence returns.*
- **B3.** Per-stage detail belongs in each command's doc, and the guide referencing those docs keeps
  it current. *If false → the guide either goes stale (restating stage behavior) or is uselessly thin.*

## Key Decisions

- **D1. Ship the on-demand guide as a `/_my_pipeline` command, not a skill.** Commands are already
  symlinked by the installer, are human-invokable, and are reachable by an agent (by path or via the
  Skill tool). *Rejected: a `pipeline-guide` skill — needs `setup-global.sh` to symlink skill
  directories (brushes the spec's non-goal), for only marginal auto-invocation benefit the always-on
  rule already covers. Also rejected: a flat `.md` under `skills/` or a second always-on rule — the
  former never registers as anything useful, the latter is per-session context weight the spec forbids.*
- **D2. Shape in the rule, shape + annotations + guide in the command; nothing else duplicates it.**
  *Rejected: rule points to command with no shape of its own (kills always-on awareness, a spec
  Success Criterion); and command points to rule for the shape (command must stand alone as the
  fuller source).*
- **D3. A convention plus a small grep test keeps rule and command in sync.** A `scripts/test_*.sh`
  check asserts the rule's stage tokens match the command's overview. *Rejected: convention only (the
  item's whole value is staying current — an unenforced convention is what let the README drift); and
  a generator that emits the rule from the command (over-built for one short line).*
- **D4. `project-pack/README.md` drops its flow table and points at `/_my_pipeline`.** Replace the
  stale section-3 table with a short pointer; leave the command index. *Rejected: keeping a corrected
  copy of the flow in the README (reintroduces the divergence this item exists to kill).*

## Architecture

Two shipped artifacts, one authored source, consumers that point rather than copy.

```
claude-pack/
  rules/pipeline.md            # always-on: stage shape (one line) + branch + "run /_my_pipeline for more"
  commands/_my_pipeline.md     # on-demand: overview (stage map) + guide (when/how per stage)
                               #            per-stage detail → link to each stage command's doc

setup-global.sh                # already symlinks rules/*.md and commands/*.md — NO change needed
  → ~/.claude/rules/pipeline.md
  → ~/.claude/commands/_my_pipeline.md

consumers point here, don't copy:
  project-pack/README.md       # flow table → pointer to /_my_pipeline
  _my_orchestrate.md           # (orchestrator item) inline process → pointer to /_my_pipeline
```

Data flow at runtime:
1. Session starts → rules loader reads `~/.claude/rules/pipeline.md` → agent knows the shape + where the guide is.
2. Agent (or human) needs depth → runs `/_my_pipeline` or reads its doc → gets overview + guide.
3. Agent needs one stage's mechanics → the guide points it at that stage command's own doc.

## Required Invariants

- **I1.** The pipeline stage sequence is authored in exactly two files — the rule (bare shape) and the
  command (annotated) — and nowhere else. No other command or doc restates the sequence inline.
- **I2.** The rule's stage tokens and the command's overview stage tokens are identical (enforced by the D3 test).
- **I3.** The guide never restates a stage command's per-stage behavior; it links to that command's doc.
- **I4.** The rule stays lightweight — target under ~25 lines — because it loads on every session.
- **I5.** `/_my_pipeline` follows the `_my_` command convention so it installs and is invokable like the rest.

## Component Overview

- **`claude-pack/rules/pipeline.md`** — always-on rule. The ordered stage shape on one line, the
  epic-vs-single-item branch in a phrase, and a pointer: "run `/_my_pipeline` for the full flow and
  when/how to use each stage." Nothing else.
- **`claude-pack/commands/_my_pipeline.md`** — the guide command. Follows the `**Purpose:**` header
  style of the other commands. Body has two parts: **Overview** (stage map with entry points, optional
  stages `product_design`/`concept*`, the review pairings — `spec_review` after `spec`, `design_review`
  after `design` — and the epic branch via `epic_plan`), and **Guide** (a short when/how line per
  stage, each linking to that command's doc). It presents the guide; it does not run the pipeline.
- **`scripts/test_pipeline_sync.sh`** (new, small) — asserts I2: rule shape tokens == command overview tokens.
- **`project-pack/README.md`** (modified) — section-3 flow table replaced by a pointer to `/_my_pipeline`.

## Non-Goals

- Rewriting `docs/guide.md` / `docs/working-with-claude.md` (repo-only human docs).
- Rewiring `_my_orchestrate.md` — that edit belongs to the orchestrator item; this design only makes the source it points at.
- Any change to `setup-global.sh` — rules and commands already install; nothing new is needed.
- Touching `skills/example-skill.md` — unrelated dead weight, out of scope.
- Shipping the guide to Codex (`build-codex-pack.sh`) — the command will flow through the normal command→skill build; no special handling designed here.

## Implementation Notes

- Match the existing command file shape: a `# ... Command` title and a `**Purpose:** / **Input:** /
  **Output:**` header block, so it reads like its siblings and the Codex build extracts a sane description.
- The command is reference, not an action — its body is the guide itself. Keep an explicit line up top
  that when invoked it presents the pipeline overview, so an agent doesn't try to "run" anything.
- The sync test should tokenize on stage command names (`spec`, `spec_review`, `design`, …) and compare
  the set/order the rule lists against the command's overview. Keep it a plain grep/sort/diff.
- After adding files under `claude-pack/`, re-run `setup-global.sh` for the symlinks (per CLAUDE.md).
- Add a `COMMAND_SKILL_DESCRIPTIONS` override for `pipeline` in `codex-overrides/config.sh` (per
  CLAUDE.md's Codex section) so the Codex build gets a clean description.

## Potential Risks

- **Rule/command shape drift.** Two copies of the shape can diverge. Mitigated by I2 + the D3 test.
- **A reference-only command is unusual here.** Every other `_my_` command is an action; this one is a
  guide. Cosmetic — the `_my_` convention and file shape carry it, and the up-top "presents the
  overview" line removes ambiguity about what invoking it does.
- **The Codex build may need the description override to avoid a thin/auto-extracted description.**
  Addressed in Implementation Notes; low risk.

## Integration Strategy

- Replaces the stale flow table in `project-pack/README.md` with a pointer to `/_my_pipeline`.
- The orchestrator (separate item) will point at `/_my_pipeline` instead of its inline "recommended process."
- Complements, does not replace, each stage command's own doc — the guide is the map, the command docs are the detail.

## Validation Approach

- Re-run `setup-global.sh`; confirm `~/.claude/commands/_my_pipeline.md` and `~/.claude/rules/pipeline.md` resolve.
- Start a fresh session: confirm the rule loads (shape visible, no full guide → no bloat) and `/_my_pipeline` is invokable and shows the overview + guide.
- Run `scripts/test_pipeline_sync.sh` — passes when rule and command list the same stages; fails if edited apart.
- Grep the repo: no command or doc other than the rule and `/_my_pipeline` restates the stage sequence.

## Next-Stage Handoff

- **Fixed:** hybrid rule + `/_my_pipeline` command; command is the single authored source; rule carries
  only the shape; consumers point here; per-stage detail links to command docs; no installer change.
- **Open:** the exact wording of the rule's one-line shape and the command's per-stage guide lines —
  content, not structure. Settle while drafting.
- **De-risk first:** nothing load-bearing is unproven — rules and commands are known-good install paths.
  First plan step is simply authoring the command, then the rule, then the sync test, then the README rewire.

---
Next Step: After approval → `/_my_plan`
