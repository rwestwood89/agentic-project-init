# Spec: Directory-Skill Build Pattern

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-20 10:24
**Complexity:** MEDIUM
**Branch:** anchor-on-the-point
**Epic:** MENTAL-ALIGN-V2, **Item 5** — written as Item 2, moved last by the 2026-08-20 restructure
(see the epic's "Restructure" section). The move changed two things in this spec, marked below:
the allowlist entry became in-scope, and the throwaway-name decision lost its original purpose.

---

## Problem

The pack ships each capability as a command file in `claude-pack/commands/` that delegates to a
shared prose spec in `claude-pack/scripts/`. ADR 0009 replaces that shape: a capability becomes a
skill directory — `SKILL.md` entry point plus sibling instruction and feedback files, shipped and
versioned as one unit. That decision is owner-graded and already recorded.

Neither install lane can ship such a directory today.

- `build-codex-pack.sh:395` finds directory skills with `find ... -mindepth 2 -maxdepth 2 -type f
  -name 'SKILL.md'`. It copies the entry point and nothing else. A nested subdirectory such as
  `feedback/` is not even discovered by that walk.
- `setup-codex.sh:267` has the same shape, so the install repeats the omission.
- `NATIVE_SKILL_ALLOWLIST` (`codex-overrides/config.sh:58`) is opt-in — a skill directory missing
  from it is dropped from the Codex build with no error.

Claude is fine: `setup-global.sh:126-134` symlinks whole skill directories, so siblings arrive
with the skill. That asymmetry is what makes this dangerous. The first directory skill would work
on Claude and arrive on Codex as an entry point pointing at instruction files that were never
copied — a silent half-install, discovered only when someone runs the skill on Codex.

There is a second, quieter problem. `claude-pack/skills/example-skill.md` is a flat `.md` file,
and flat files never register as skills in Claude Code. Two prior designs recorded it as inert
and deliberately left it alone (`.project/active/pipeline-guide/design.md:41`). So the pack's only
skill example is a non-functional file in a form nobody should copy — exactly the pattern-matching
failure ADR 0009 exists to prevent.

The mental-alignment skill is the first capability that needs this plumbing, and the plumbing is
generic — every future command→skill migration uses it.

**Ordering, changed 2026-08-20.** This item was originally first in the epic, proving the lane with
a placeholder before any real skill existed. The owner moved it last: the skill gets built and
proven on Claude first, and this item then ships it to Codex. So by the time this runs,
`claude-pack/skills/_my_mental_model/` already exists with an instruction sibling and a nested
`feedback/` directory, and it is this item's real test subject rather than a stand-in.

## Success Criteria

- [ ] A skill directory containing sibling files **and** a nested subdirectory installs complete
      on both runtimes: every file reaches `dist/codex/skills/<name>/` and then
      `~/.agents/skills/<name>/`, and the Claude install places the whole directory.
- [ ] Invoking the example skill on Claude works, and a sibling file it references is readable
      from inside that invocation.
- [ ] `claude-pack/skills/_my_mental_model/` reaches Codex as `my-mental-model` — dist directory
      name and generated frontmatter name both — and is present in the Codex build rather than
      silently excluded from it.
- [ ] The pack ships a directory-skill example in the correct form, so a future author copying it
      gets the right shape. `example-skill` is no longer inert on Claude.
- [ ] The new sibling-copying behavior has a regression check, so a later change that drops
      siblings fails a test rather than shipping.
- [ ] Anyone who installed the old flat `example-skill.md` does not keep a stale symlink at
      `~/.claude/skills/example-skill.md` after re-running the installer.
- [ ] The existing suite passes: docs, pipeline-sync, codex-orchestrator-pack, global-setup, adr.

## Known Requirements

- **[HARD]** A Claude skill's name is its directory name. The runtime rejects parentheses,
  commas, control characters, a leading `/`, surrounding whitespace, backslashes, and
  wildcard-suffix names. Underscores are permitted. (Read from the installed runtime,
  `claude-code 2.1.237`, 2026-08-20 — this is what makes a future `_my_mental_model` directory a
  legal skill name.)
- **[HARD]** Native skills take their Codex description from their own frontmatter; there is no
  override map for them (`build-codex-pack.sh:243-255`). Codex's YAML parse fails on a leading
  `*`, so the description must be plain prose.
- **[HARD]** A skill directory absent from `NATIVE_SKILL_ALLOWLIST` is silently excluded from the
  Codex build (`codex-overrides/config.sh:58`).
- **[HARD]** A flat `.md` file in `claude-pack/skills/` never registers as a skill in Claude Code.
  Any skill that must actually load has to be a directory with a `SKILL.md`.
- **[NEED]** `example-skill` is converted from its flat file to directory form and kept in the
  pack. (Owner, 2026-08-20.) *Premise changed by the restructure:* the owner chose this as a
  throwaway subject so the lane could be proven without creating `_my_mental_model` prematurely.
  Under the new ordering the real skill exists first and is the subject, so the conversion no
  longer carries the proof. The decision stands on its remaining merits — it retires a file two
  prior designs recorded as inert dead weight, and it leaves the pack a copyable directory-skill
  example, which is what ADR 0009 exists to protect. It is now droppable at the owner's discretion
  rather than load-bearing.
- **[NEED]** The pattern is not proven under `_my_mental_model` *before* that skill exists.
  (Owner, 2026-08-20.) Satisfied by construction now: the skill is built in epic Item 3, and this
  item ships it.
- **[INHERITED]** Sibling copying must reach files nested inside subdirectories, not only flat
  siblings — the real skill's `feedback/` directory is the case that breaks a flat walk.
  (`.project/concepts/mental-alignment-skill-design.md:252`.)
- **[INHERITED]** No sanitization pass exists for native skill bodies. Both the entry point and
  its siblings must be written in runtime-neutral delegation language. (ADR 0010.)
- **[INHERITED]** The three Codex changes are: copy siblings in the build, install siblings, and
  add the directory to the allowlist. (`.project/concepts/mental-alignment-skill-design.md:112-113`,
  ADR 0010.)
- **[INFERRED]** The example skill's content stays a placeholder. It demonstrates the shape — an
  entry point that reads a sibling — and carries no real capability.

## Non-Goals

- The mental-alignment coordinator, synthesis, or render behavior. Epic Items 3 and 4.
- Deleting the two v1 authored files (`claude-pack/commands/_my_mental_model.md`,
  `claude-pack/scripts/mental-model-builder.md`). Epic Item 2. Their **remaining build wiring,
  docs, and test references are in scope here** — see "Added to scope by the restructure" below.
- Creating `claude-pack/skills/_my_mental_model/` and its instruction and feedback files. Epic
  Item 3.
- Widening the runtime-neutrality scan to cover sibling files. ADR 0010 left this to spec; the
  decision is not to widen it, so sibling neutrality stays convention-only
  (owner, 2026-08-20). The scan remains `test_codex_orchestrator_pack.sh:336-338`, globbed
  `-g 'SKILL.md'`.
- Migrating the remaining `_my_*` commands to skills, or moving the prose specs out of
  `claude-pack/scripts/`. Deferred by ADR 0009's scope note.
- Proving that a `/_my_*` slash invocation resolves to a directory skill on **Claude**. That
  happens in epic Item 3, which creates the real directory and invokes it, and the epic's risk
  table is re-pointed there. Proving it on **Codex** is in scope here. (product-lens spec-F3.)

## Added to scope by the restructure (2026-08-20)

Moving this item last pulled three things in that were previously someone else's:

- **[INHERITED]** Add `_my_mental_model` to `NATIVE_SKILL_ALLOWLIST`. The entry must be the
  **pack-side** directory name `_my_mental_model`, not the Codex name `my-mental-model` — the check
  is keyed on the source directory (`build-codex-pack.sh:370`). A missing entry excludes the skill
  from the Codex build with no error. This was a Non-Goal when the item ran first and no such
  directory existed. (product-lens spec-F2.)
- **[INHERITED]** The remaining v1 wiring cleanup, which old epic Item 3 owned: the path rewrite at
  `build-codex-pack.sh:138`, the shared-spec copy at `:426`, the description override at
  `codex-overrides/config.sh:37`, the `README.md:131` catalog row, the `scripts/test_docs.sh`
  retired list, and the `scripts/uninstall-project.sh:108-114` skill list. Each was verified
  harmless if left in place, which is why the deletes could ship separately as epic Item 2.
- **[INHERITED]** Wiring the Codex resumed-render path, using epic Item 1's confirmed finding that
  Codex can continue a spawned agent. Item 1 also found Codex reports no per-agent token count.

## Open Questions / Deferred to design

- ~~**How the `_my_x` → `my-x` mapping gets proven.**~~ **Resolved by the restructure.**
  `_my_mental_model` exists before this item runs, so every build exercises the mapping and the
  nested-sibling copy for real. The design's answer to this question (parameterize the build's
  roots so a fixture pack can be built in a tmpdir) lost its purpose and is recorded as rejected.
- **Where the Codex skill name comes from.** The build currently reads the frontmatter `name`
  (`build-codex-pack.sh:375`) and falls back to the directory name. On Claude the frontmatter name
  has to match the directory, so for a `_my_`-prefixed skill the build cannot trust frontmatter —
  it has to derive `my-<name>`. Design settles whether that is a new helper or the existing
  `strip_command_prefix` / `to_hyphen_name` pair.
- **What the sibling walk includes and excludes.** Depth, dotfiles, whether non-markdown files
  (scripts, assets) are in scope.
- **How the stale `~/.claude/skills/example-skill.md` symlink is removed** — a targeted cleanup in
  `setup-global.sh`, or a general "managed symlink whose source no longer exists" sweep.
- **What the regression check asserts.** Sibling presence in `dist/`, in a temp-HOME Codex
  install, or both.
- **What `uninstall-project.sh:108-114` should list.** It hardcodes `example-skill.md` in its
  file loop and `show-me` in its directory loop. Both the converted `example-skill` and
  `_my_mental_model` need directory entries, and the flat `example-skill.md` entry should stay for
  projects vendored before this change. One list, one edit — no longer split across two items.
- **What happens to the flat native-skill build lane** (`build-codex-pack.sh:335-365`). Converting
  `example-skill` leaves it with no user in the pack, but it still works: a flat `.md` dropped in
  `claude-pack/skills/` would build a functioning Codex skill while registering nothing on Claude
  — the same silent per-runtime asymmetry as the problem above, mirrored. Delete the lane, or keep
  it and make it fail loudly. Design decides. (product-lens spec-F1.)

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2, Item 5)
- **Required Reading:**
  - `.project/concepts/mental-alignment-skill-design.md` — Distribution lane, Appendix
    (Codex build/install changes, Claude install)
  - `.project/concepts/mental-alignment-skill-design-review.md` — ADR candidate 3 assessment,
    m4 disposition
  - `.project/adr/0009-directory-skills-pattern.md`
  - `.project/adr/0010-native-skill-codex-lane.md`
- **Product-lens ledger:** `.project/active/directory-skill-build-pattern/product-lens.md`
- **Design:** `.project/active/directory-skill-build-pattern/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
