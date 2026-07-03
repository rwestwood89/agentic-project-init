# Spec: `/_my_design_review` Rename

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-01
**Complexity:** LOW
**Branch:** workflow-v2

---

## Problem

The design review command is named `_my_review_design`, which is inconsistent with `_my_spec_review`. The naming convention for review commands should be `_{thing}_review`, not `_review_{thing}`.

The command also produces only conversational output — the review disappears when the session ends. `_my_spec_review` writes a persistent `spec-review.md` artifact to the work item directory. The design review should do the same, so the review is part of the project record and available to downstream commands.

## Success Criteria

- [ ] Command exists as `/_my_design_review` (renamed from `_my_review_design`)
- [ ] Writes `design-review.md` artifact to the work item directory

## Known Requirements

- **[HARD]** Rename the file: `claude-pack/commands/_my_review_design.md` → `claude-pack/commands/_my_design_review.md`.
- **[HARD]** Add instruction to write the review output to `.project/active/{feature-name}/design-review.md`, matching the pattern in `_my_spec_review` which writes to `spec-review.md`.
- **[HARD]** Update Codex skill description in `codex-overrides/config.sh`: old key `review-design` → new key `design-review`.
- **[NEED]** The review methodology, lenses, and posture remain unchanged. This is a rename and artifact addition, not a rewrite.
- **[INFERRED]** The old file `_my_review_design.md` should be deleted after the new one is created. (Final deletion happens in Item 9's cleanup sweep, but the new file should exist first.)

## Non-Goals

- Changing the review methodology or dimensions.
- Updating cross-references in other commands (that's Item 9).
- Updating symlinks in `~/.claude/` for the old name (setup-global.sh handles this, and the old symlink gets cleaned up in Item 9).

## Open Questions / Deferred to design

None. This is mechanical.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_workflow_v2.md` (Item 8)
- **Current command:** `claude-pack/commands/_my_review_design.md`
- **Pattern reference:** `claude-pack/commands/_my_spec_review.md` (writes `spec-review.md` artifact)
- **Codex config:** `codex-overrides/config.sh` (key `review-design` to rename)

---

**Next Steps:** After approval, proceed directly to implementation.
