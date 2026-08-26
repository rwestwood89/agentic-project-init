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
`research`/`concept`/(`concept_design` → `concept_design_review`) → `epic_plan` → `spec` → `spec_review` → [`product_design`] → `design` → `design_review` → `plan` → `implement` → `audit` → `close` → `pre_pr`

This is not a strict pipeline — it is a set of patterns and flows adapted to the nature of the
problem. Which stages to run follows from a few questions:

- **"How well do you understand the problem you're trying to solve?"**
  - *Well* — skip shaping. A single, clear item starts at `spec`; when the owner explicitly invokes `/_my_quick_edit`, a small, scoped code change skips the pipeline entirely. Do not use it for routine documentation or `.project` artifact edits.
  - *Not that well* — start at `concept` to work out the problem, success criteria, and scope.
    Then ask the three questions below.
- **"Is there a clear user experience we need to understand?"** If yes, run `product_design`.
  It works off the concept at shaping tier, or off a spec for a single item — same function;
  the tier depends on the size of the work.
- **"How big of an impact does this have?"** If high, nail down the major architectural
  decisions in `concept_design` — with `research` first, to ground them in what exists (codebase
  and proven external approaches) — and pressure-test them with `concept_design_review` before
  they become the shape of an epic.
- **"How much work is there — should it break into shippable pieces?"** If yes, `epic_plan`
  produces a scoped epic; each item then runs the pipeline from `spec` onward, in dependency
  order.
- **Reviews pair with the artifact they check:** `concept_design_review` after `concept_design`,
  `spec_review` after `spec`, and `design_review` after `design` — each in a **fresh session**, never
  the session that authored the artifact. Feed the must-fix points back into the artifact; don't
  chase a reviewer indefinitely. Include a review when the artifact's risk or complexity earns it.
- **De-risking is available at any stage, not just shaping.** When a stage rests on an unverified
  bet about how something behaves, `/_my_spike` and `/_my_learning_test` write code to find out.
  They're optional tools, not pipeline stages — reach for them when uncertainty is high, then feed
  the finding back into the stage that needed it.
- **The tail** — `audit` → `close` — certifies the work and archives the item. **`pre_pr` runs
  after `close`**, and only when there is actually something to ship: after closing an item that
  is shippable on its own, or once at the end of the epic when its items ship together. It is a
  branch gate (project checks + PR submission), not an item stage — never run it per-phase or
  mid-item.

## Guide — when and how to use each stage

Shaping (optional, for fuzzy ideas):

- **`/_my_research`** — deep codebase exploration and feasibility analysis. Use before design when you
  need to understand an area or de-risk an approach. See `_my_research.md`.
- **`/_my_concept`** — develop a feature concept with success criteria, user stories, and scope. Use
  to define an idea before specifying it. See `_my_concept.md`.
- **`/_my_concept_design`** — a critiqueable architecture/responsibilities sketch. Use when a design
  area needs a conceptual pass before detailed design. See `_my_concept_design.md`.
- **`/_my_concept_design_review`** — pressure-test the concept's system shape, invariant ownership,
  and abstractions before epic decomposition. See `_my_concept_design_review.md`.
- **`/_my_product_design`** — settle the interaction and interface decisions for a consumer-facing
  surface, from the consumer's perspective. Runs off the concept at this tier, or off a spec for a
  single item. See `_my_product_design.md`.

De-risking (optional, any stage — write code to learn):

- **`/_my_spike`** — de-risk a *known* assumption with a throwaway probe; output is a findings doc,
  the script is scratch. Use when you have a clear goal and one thing to confirm. See `_my_spike.md`.
- **`/_my_learning_test`** — *discover* how an unfamiliar surface behaves by writing real, kept
  tests; findings doc plus tests in the repo's own test suite. Use when the goal is fuzzy and
  you're mapping a surface. See `_my_learning_test.md`.

Scoping an epic:

- **`/_my_epic_plan`** — bridge shaping to scoping: turn concept/concept-design/research into a scoped
  epic with backlog items and Required Reading. Use when the work is more than one item. See `_my_epic_plan.md`.

Per item:

- **`/_my_spec`** — uncover and capture the problem, success criteria, and known requirements. The
  contract for everything downstream. See `_my_spec.md`.
- **`/_my_spec_review`** — adversarial review of the spec before it becomes that contract. See `_my_spec_review.md`.
- **`/_my_product_design`** *(optional)* — flesh out the experience for a consumer-facing surface
  before technical design. Runs off this item's spec, or off a concept at shaping tier. See `_my_product_design.md`.
- **`/_my_design`** — the technical design: architecture, interfaces, decisions, tradeoffs. See `_my_design.md`.
- **`/_my_design_review`** — critical review of the design before implementation. See `_my_design_review.md`.
- **`/_my_plan`** — a phased implementation plan, test-first, with continuous validation and checkboxes
  for multi-session work. See `_my_plan.md`.
- **`/_my_implement`** — execute the approved plan, one phase at a time, with validation. See `_my_implement.md`.

Closing out:

- **`/_my_audit`** — certify the item or epic against its upstream artifacts; write findings, update
  tracking. Don't self-certify the implementing session's work — run this fresh. See `_my_audit.md`.
- **`/_my_close`** — archive the completed item or epic to `completed/` and update tracking files. See `_my_close.md`.
- **`/_my_pre_pr`** — the branch gate: run project quality checks and submit the PR. Run it **after
  `close`** — per item when the item is shippable on its own, otherwise once at the end of the
  epic. See `_my_pre_pr.md`.

## Keeping this current

The bare shape line above (marked `pipeline-shape`) is duplicated in `claude-pack/rules/pipeline.md`
for always-on awareness. `scripts/test_pipeline_sync.sh` asserts the two stay identical. Per-stage
detail lives in each command's own doc, linked above — this guide never restates it.

**Last Updated:** 2026-08-08 — reframed the overview around the entry questions (owner model);
`product_design` now runs off a concept or a spec.
