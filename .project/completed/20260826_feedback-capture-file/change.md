# Feature Change: Feedback Capture File

**Status:** Complete
**Owner:** Reid W
**Created:** 2026-08-26 09:19
**Last Updated:** 2026-08-26 09:19
**Git Branch:** feedback-capture-file
**Git Hash:** 10d2473 (base commit this work sits on)

## Overview

Two files ship in `project-pack/feedback/` so every project with a `.project/` has a place for the agent to record what it learned when the owner corrected it. The owner asks in prose — "record your learnings as feedback" — and the agent reads the rules file and appends to the entries file. Nothing reads the entries back.

The value is that a correction stops dying in the chat it happened in. The agent writes it down at the moment it holds the correction, the artifact, and the reason, and the owner can later fix the pack target upstream.

## Problem Statement

- A lesson from several rounds of pushback exists only in that chat session.
- Getting it upstream means the owner remembering it later, in a different session, and translating it by hand without the context that produced it.
- The agent is best placed to record it and had nowhere to write.
- `/_my_mental_model` solved this for itself with two-tier feedback files and a promotion path. The owner scoped this deliberately smaller: a file with a header, nothing else.

## Related Artifacts

- **Spec:** `.project/active/feedback-capture-file/spec.md` — the contract this was built against.
- **Contrast case:** `claude-pack/skills/_my_mental_model/SKILL.md` Step 9 — the heavier mechanism explicitly not adopted here.
- **Design/plan:** none. Ran through `/_my_quick_edit`; the spec's four open questions were settled in review with the owner.

## Changes

**`project-pack/feedback/README.md`** (new, ~30 lines) — the instructions the agent reads on every recording. Covers the append-only rule, the bracketed-tag heading, the three body fields, and one worked example that carries the altitude of a good generalization. Documents the canonical selector. States that `ENTRIES.md` is user data and this file is not.

**`project-pack/feedback/ENTRIES.md`** (new) — header only, points back at `README.md`.

**`scripts/init-project.sh`** — four edits:
- `:123` — `feedback/ENTRIES.md` added to `USER_DATA_FILES`, so `--force` never overwrites accumulated entries.
- `:46-47` — the `--help` protected-file listing, split across two lines to fit the new name.
- `:191` — `feedback` added to the merge-path required-subdirectory loop.
- `:206` — `.project/feedback` added to the fresh-init `mkdir -p`.

The instructions file is deliberately absent from `USER_DATA_FILES`, so `--force` propagates improved rules to existing projects.

**`project-pack/README.md`** `:60`, `:83` — Key Files row and folder-structure entry.

**`README.md`** `:28`, `:290` — project-pack bullet and post-init tree.

**`scripts/test_init_project.sh`** — Test 8: init seeds both files; an accumulated entry survives `--force`; the instructions file gets refreshed. Failure messages name the stake and point at `USER_DATA_FILES`.

### Decisions settled during review

- **Entry format** — `## [_my_spec] 2026-08-25` with `**Wrong:** / **Right:** / **Learning:**` beneath. The bracketed tag is the delimiter, chosen over a bare tag so a quoted markdown heading in an entry body cannot be mistaken for an entry boundary.
- **Selector** — `awk -v t='[_my_spec]' '/^## \[/{k=($2==t)} k' ENTRIES.md`. Documented in the instructions file so a future filter copies it rather than inventing a naive one.
- **Names frozen** — `.project/feedback/README.md` and `.project/feedback/ENTRIES.md`. `is_user_data` matches the exact relative path, so the entries filename is a contract; the ALL-CAPS-is-user-data convention already in the pack is stated in the instructions file.
- **`uninstall-project.sh` left alone** — it deletes `.project/` wholesale, feedback included, exactly as it already does for `CURRENT_WORK.md`, `BACKLOG.md`, and memories. Pre-existing posture, not widened here.

## Validation

- `scripts/test_init_project.sh` — 8 tests pass.
- **Test 8 confirmed non-vacuous.** Deleted the `USER_DATA_FILES` line, reran, got `FAIL: --force destroyed accumulated feedback entries`. Restored and re-verified.
- `scripts/test_docs.sh` — all checks pass, including the stage-restatement grep that scans `project-pack/`.
- `scripts/test_uninstall.sh` — all pass.
- **Selector verified on a realistic file.** Three entries across two tags, with a bare `## Open Questions` line inside one body. Selecting `[_my_spec]` returned both its entries intact; the stray heading did not break the boundary.
- **Re-init on `agentic-project-init`** — added both feedback files plus two `memories/` template files missing for unrelated reasons (gitignored here). Nothing overwritten.
- **Re-init on `echo-workspace`** — added exactly the two feedback files, nothing else.
- **Not run: `teasp-workspace`.** Dry run confirms both files land with zero overwrites, but an actual run would also install `adr/`, `product/`, and two scripts that project has never had. Left to the owner.
