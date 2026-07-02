# Pipeline Shape

The project workflow runs as a sequence of `/_my_*` stages. This is the shape, for orientation.
It is the only place the sequence appears besides `/_my_pipeline` — don't restate it elsewhere.

<!-- pipeline-shape -->
`research`/`concept`/`concept_design` → `epic_plan` → `spec` → `spec_review` → [`product_design`] → `design` → `design_review` → `plan` → `implement` → `audit` → `pre_pr` → `close`

- **Entry depends on the work:** shaping (`research`/`concept`/`concept_design`) for a fuzzy idea,
  `epic_plan` for a multi-item epic, or straight to `spec` for a single clear item.
- **`[product_design]`** is optional — only for consumer-facing surfaces.
- **Reviews pair with their artifact:** `spec_review` after `spec`, `design_review` after `design`.
- Small, scoped changes can skip the pipeline via `/_my_quick_edit`.

**For the full flow and when/how to use each stage, run `/_my_pipeline`** (or read
`~/.claude/commands/_my_pipeline.md`).
