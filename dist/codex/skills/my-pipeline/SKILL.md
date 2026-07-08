---
name: my-pipeline
description: The canonical map of the project workflow: stage order, branches, and when/how to use each stage. Use to see the current pipeline or check which stage comes next; other docs point here instead of restating the flow.
---

Generated from `claude-pack/commands/_my_pipeline.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Pipeline Command

**Purpose:** The canonical, current map of the project workflow — the stage order, the branches, and
when and how to use each stage. This is the single source; other docs and commands point here rather
than restating the flow.
**Input:** None. When invoked, present this overview and guide.
**Output:** No artifact. This command is reference, not an action — it does not run the pipeline.

When invoked, present the pipeline overview and, if the user asks about a specific stage, the guide
line for it. For per-stage mechanics, point at that stage command's own doc — never restate it here.

## Overview — the stage map

<!-- pipeline-shape -->
`research`/`concept`/`concept_design` → `epic_plan` → `spec` → `spec_review` → [`product_design`] → `design` → `design_review` → `plan` → `implement` → `audit` → `pre_pr` → `close`

How to read it:

- **Entry point depends on the work.**
  - A fuzzy idea starts in **shaping**: `research`, `concept`, and/or `concept_design`.
  - A body of work that splits into many items starts at `epic_plan`, which produces a scoped epic;
    each item then runs the pipeline from `spec` onward, in dependency order.
  - A single, clear item skips shaping and starts at `spec`.
- **Reviews pair with the artifact they check:** `spec_review` after `spec`, `design_review` after
  `design`. Feed the must-fix points back into the artifact; don't chase a reviewer indefinitely.
- **`[product_design]` is optional** — run it between `spec` and `design` only when the item has a
  consumer-facing surface (UX, an API, an interface) whose experience should be settled first.
- **``my-quick-edit`` is the escape hatch** — a small, scoped, implementation-ready change skips the
  pipeline entirely.
- **De-risking is available at any stage, not just shaping.** When a stage rests on an unverified
  bet about how something behaves, ``my-spike`` and ``my-learning-test`` write code to find out.
  They're optional tools, not pipeline stages — reach for them when uncertainty is high, then feed
  the finding back into the stage that needed it.
- The tail — `audit` → `pre_pr` → `close` — certifies the work, ships the PR, and archives the item.

## Guide — when and how to use each stage

Shaping (optional, for fuzzy ideas):

- **``my-research``** — deep codebase exploration and feasibility analysis. Use before design when you
  need to understand an area or de-risk an approach. See `_my_research.md`.
- **``my-concept``** — develop a feature concept with success criteria, user stories, and scope. Use
  to define an idea before specifying it. See `_my_concept.md`.
- **``my-concept-design``** — a critiqueable architecture/responsibilities sketch. Use when a design
  area needs a conceptual pass before detailed design. See `_my_concept_design.md`.

De-risking (optional, any stage — write code to learn):

- **``my-spike``** — de-risk a *known* assumption with a throwaway probe; output is a findings doc,
  the script is scratch. Use when you have a clear goal and one thing to confirm. See `_my_spike.md`.
- **``my-learning-test``** — *discover* how an unfamiliar surface behaves by writing real, kept
  tests; findings doc plus tests in the repo's own test suite. Use when the goal is fuzzy and
  you're mapping a surface. See `_my_learning_test.md`.

Scoping an epic:

- **``my-epic-plan``** — bridge shaping to scoping: turn concept/concept-design/research into a scoped
  epic with backlog items and Required Reading. Use when the work is more than one item. See `_my_epic_plan.md`.

Per item:

- **``my-spec``** — uncover and capture the problem, success criteria, and known requirements. The
  contract for everything downstream. See `_my_spec.md`.
- **``my-spec-review``** — adversarial review of the spec before it becomes that contract. See `_my_spec_review.md`.
- **``my-product-design``** *(optional)* — flesh out the experience for a consumer-facing surface
  before technical design. See `_my_product_design.md`.
- **``my-design``** — the technical design: architecture, interfaces, decisions, tradeoffs. See `_my_design.md`.
- **``my-design-review``** — critical review of the design before implementation. See `_my_design_review.md`.
- **``my-plan``** — a phased implementation plan, test-first, with continuous validation and checkboxes
  for multi-session work. See `_my_plan.md`.
- **``my-implement``** — execute the approved plan, one phase at a time, with validation. See `_my_implement.md`.

Closing out:

- **``my-audit``** — certify the item or epic against its upstream artifacts; write findings, update
  tracking. Don't self-certify the implementing session's work — run this fresh. See `_my_audit.md`.
- **``my-pre-pr``** — run project quality checks and submit the PR. See `_my_pre_pr.md`.
- **``my-close``** — archive the completed item or epic to `completed/` and update tracking files. See `_my_close.md`.

## Keeping this current

The bare shape line above (marked `pipeline-shape`) is duplicated in `claude-pack/rules/pipeline.md`
for always-on awareness. `scripts/test_pipeline_sync.sh` asserts the two stay identical. Per-stage
detail lives in each command's own doc, linked above — this guide never restates it.

**Last Updated:** 2026-07-06

