# Pipeline Shape

The project workflow runs as a sequence of `/_my_*` stages. This is the shape, for orientation.
It is the only place the sequence appears besides `/_my_pipeline` — don't restate it elsewhere.
Stages are quality tools, not mandatory ceremony. Use the smallest set of stages that can produce
high-quality, auditable work for the risk in front of you.

<!-- pipeline-shape -->
`research`/`concept`/(`concept_design` → `concept_design_review`) → `epic_plan` → `spec` → `spec_review` → [`product_design`] → `design` → `design_review` → `plan` → `implement` → `audit` → `close` → `pre_pr`

- **Entry follows the question "how well do you understand the problem?"** Not well: shape it
  (`research`/`concept`/`concept_design`); many shippable pieces: `epic_plan`; a single clear
  item: straight to `spec`.
- **`[product_design]`** is optional — for consumer-facing surfaces; runs off a concept
  (shaping tier) or a spec (single item), same function either way.
- **`pre_pr` is the branch gate, run after `close`** — when the item is shippable on its own;
  for items that ship together, run it once at the end of the epic. Never per-phase or mid-item.
- **Reviews pair with their artifact when they add confidence:** `concept_design_review` after
  `concept_design`, `spec_review` after `spec`, and `design_review` after `design`. For minor,
  objectively verifiable fixes, record the verification and continue instead of rerunning a
  reviewer just to replace an old verdict.
- When the owner explicitly invokes `/_my_quick_edit`, a small, scoped code change can skip the pipeline. Do not use it for routine documentation or `.project` artifact edits.

**For the full flow and when/how to use each stage, run `/_my_pipeline`** (or read
`~/.claude/commands/_my_pipeline.md`).
