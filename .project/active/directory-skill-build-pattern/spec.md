# Spec: Directory-Skill Build Pattern

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-20 10:24
**Complexity:** MEDIUM
**Branch:** anchor-on-the-point
**Epic:** MENTAL-ALIGN-V2, Item 2

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

The mental-alignment skill is the first capability that needs this plumbing, but the plumbing is
generic and every future migration uses it. It gets proven on its own, with a placeholder skill,
before any real behavior depends on it.

## Success Criteria

- [ ] A skill directory containing sibling files **and** a nested subdirectory installs complete
      on both runtimes: every file reaches `dist/codex/skills/<name>/` and then
      `~/.agents/skills/<name>/`, and the Claude install places the whole directory.
- [ ] Invoking the example skill on Claude works, and a sibling file it references is readable
      from inside that invocation.
- [ ] A `_my_`-prefixed skill directory would reach Codex under its `my-<name>` form — directory
      name and frontmatter name both.
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
- **[NEED]** The pattern is proven under a throwaway name, not under `_my_mental_model`. The real
  skill directory is created later, in Item 4, on an already-proven lane. (Owner, 2026-08-20.)
- **[NEED]** The throwaway is `example-skill`, converted from the flat file to directory form and
  kept in the pack afterwards, so the proof leaves behind both a durable regression fixture and
  the copyable example. (Owner, 2026-08-20.)
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

- The mental-alignment coordinator, synthesis, or render behavior. Items 4 and 5.
- Retiring the v1 command and builder, and their build wiring. Item 3.
- Creating `claude-pack/skills/_my_mental_model/`. Item 4, per the owner decision above.
- Widening the runtime-neutrality scan to cover sibling files. ADR 0010 left this to spec; the
  decision is not to widen it, so sibling neutrality stays convention-only
  (owner, 2026-08-20). The scan remains `test_codex_orchestrator_pack.sh:336-338`, globbed
  `-g 'SKILL.md'`.
- Migrating the remaining `_my_*` commands to skills, or moving the prose specs out of
  `claude-pack/scripts/`. Deferred by ADR 0009's scope note.
- Adding `_my_mental_model` to `NATIVE_SKILL_ALLOWLIST`. `example-skill` is already allowlisted
  (`codex-overrides/config.sh:59`), so this item performs no allowlist addition. Item 4 owns that
  step, and the entry must be the **pack-side** directory name `_my_mental_model`, not the Codex
  name `my-mental-model` — the check is keyed on the source directory (`build-codex-pack.sh:390`).
  A missing entry excludes the skill from the Codex build with no error. (product-lens spec-F2.)
- Proving that a `/_my_*` slash invocation resolves to a directory skill. Under the throwaway-name
  decision the live probe is `example-skill`, which has no `_my_` prefix, so the first live
  `/_my_*` directory-skill invocation is Item 4's proof. This item establishes the two weaker
  facts that de-risk it: underscores are legal in a Claude skill name, and a directory-form skill
  resolves and can read a sibling. The epic's High risk on this point needs re-pointing at Item 4.
  (product-lens spec-F3.)

## Open Questions / Deferred to design

- **How the `_my_x` → `my-x` mapping gets proven.** The pack will contain no `_my_`-prefixed skill
  directory when this item finishes, so the live probe cannot exercise the mapping. Design chooses:
  a temporary fixture inside the pack test's tmpdir, or accept that the first live proof is Item
  4's build.
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
- **Whether `uninstall-project.sh:109`** (which hardcodes `example-skill.md`) needs the directory
  form added here or belongs with Item 3's cleanup of that same list.
- **What happens to the flat native-skill build lane** (`build-codex-pack.sh:335-365`). Converting
  `example-skill` leaves it with no user in the pack, but it still works: a flat `.md` dropped in
  `claude-pack/skills/` would build a functioning Codex skill while registering nothing on Claude
  — the same silent per-runtime asymmetry as the problem above, mirrored. Delete the lane, or keep
  it and make it fail loudly. Design decides. (product-lens spec-F1.)

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2, Item 2)
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
