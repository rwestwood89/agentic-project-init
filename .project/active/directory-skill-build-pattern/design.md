# Design: Directory-Skill Build Pattern

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-20 10:30
**Branch:** anchor-on-the-point
**Commit at authoring:** 7739a5f
**Spec:** `.project/active/directory-skill-build-pattern/spec.md`

---

## Overview

Make a skill directory ship as one unit on both runtimes: the Codex build and install stop
enumerating `SKILL.md` and start mirroring the whole directory, and a skill's Codex name becomes a
function of its pack directory name. Proven by converting `example-skill` from an inert flat file
into the pack's reference directory skill.

## Related Artifacts

- **Spec:** `.project/active/directory-skill-build-pattern/spec.md`
- **Product-lens ledger:** `.project/active/directory-skill-build-pattern/product-lens.md`
  (spec pass: DISPOSED, three findings, all folded into this design)
- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` — MENTAL-ALIGN-V2, Item 2
- **Required Reading:** `.project/concepts/mental-alignment-skill-design.md` (Distribution lane,
  Appendix), `.project/concepts/mental-alignment-skill-design-review.md` (ADR candidate 3, m4),
  `.project/adr/0009-directory-skills-pattern.md`, `.project/adr/0010-native-skill-codex-lane.md`

---

## The Point

A pack capability **is** a skill directory: a `SKILL.md` entry point plus the sibling instruction
and feedback files it reads, shipped and versioned as one unit, installed on Claude as a single
symlink to the pack directory. That is ADR 0009, owner-graded, owner-originated ("this feels like
the right time to start migrating the Claude 'commands' to skills", 2026-08-19). ADR 0010 carries
it to the Codex seam: the build and install copy **every** file of an allowlisted skill directory,
and in exchange native skill bodies stay runtime-neutral because no sanitization pass exists for
them. That record is agent-graded, ratified by the owner on 2026-08-20.

Why it matters beyond plumbing: the mental-alignment skill exists because the owner cannot read a
system's whole artifact chain to recover its mental model. Its whole repair for the failed v1 is
that the thinking instructions and the rendering instructions live in **separate files**, so an
agent given the thinking job cannot see the rendering job and race to it. That repair is only
possible if sibling files ship. Today they do not ship to Codex, and the failure is silent and
one-sided — Claude works, Codex gets an entry point pointing at files that were never copied.

Every future command→skill migration reuses this lane, so it is proven on its own, under a
throwaway name, before any real capability depends on it.

---

## Research Findings

**Claude lane already works, and its shape tells us the unit.** `setup-global.sh:126-134` symlinks
whole entries under `claude-pack/skills/` — files and directories both — so a directory skill
arrives complete with one symlink. `init-project.sh:253` vendors with `cp -Rp`, so the
`--include-claude` copy path already handles directories too. Neither needs a change.

**The Codex lane enumerates one file per skill, in two places.**
- `build-codex-pack.sh:368-395` — directory skills: `find … -mindepth 2 -maxdepth 2 -type f -name
  'SKILL.md'`. Copies the entry point only. A nested `feedback/` directory is not discovered at
  all, by depth.
- `setup-codex.sh:263-267` — same walk over `dist/`, installs `SKILL.md` only.

**There is a second, older native-skill lane.** `build-codex-pack.sh:338-365` walks *flat* `.md`
files in `claude-pack/skills/` and synthesizes a `dist/codex/skills/<name>/SKILL.md` from each.
This is how `example-skill.md` reaches `dist/` today, verified in `dist/codex/manifest.json:7`.
Flat `.md` files never register as skills in Claude Code, which is why two prior designs recorded
`example-skill.md` as inert dead weight (`.project/active/pipeline-guide/design.md:41`). So the
lane's only effect is to make a shape that is dead on Claude build clean on Codex.

**The install's managed-file guard blocks sibling updates.** `install_path`
(`setup-codex.sh:78-141`) decides whether it may overwrite an existing target via
`is_managed_file`, which greps the first 20 lines for `Generated from` (`setup-codex.sh:19-22`).
The generated `SKILL.md` carries that marker at line 6, so it re-installs fine. A sibling copied
verbatim from the pack carries no marker, so on the **second** install it is classified
user-authored and skipped with a `--force` hint. Sibling edits in the pack would never reach an
existing install. There is also no path that removes a target file after its pack source is
deleted.

**Name resolution has two sources of truth.** The directory lane takes the skill name from the
frontmatter `name` (`build-codex-pack.sh:375`), falling back to the directory basename. But the
Claude runtime keys a skill's identity on its **directory name** — read out of
`claude-code 2.1.237`: the validator rejects parentheses, commas, control characters, a leading
`/`, surrounding whitespace, backslashes and wildcard suffixes, and its message states that skill
names match the skill's directory name. Underscores are not in the forbidden set. So a pack
directory `_my_mental_model` must carry `name: _my_mental_model` for Claude, while Codex needs
`my-mental-model`. Reading frontmatter cannot produce both.

**The allowlist is keyed pack-side.** `contains "$base" …` at `build-codex-pack.sh:370` tests the
*source directory* basename against `NATIVE_SKILL_ALLOWLIST` (`codex-overrides/config.sh:58`).
`example-skill` is already listed. A missing entry drops the skill with no error.

**Existing precedent for stale-link cleanup.** `setup-codex.sh:199-240` already has
`remove_path_if_managed` plus a `cleanup_legacy_prompts` sweep — remove a target if it is a
symlink pointing into a path prefix we manage. `setup-global.sh` has no equivalent.

**Decision records checked.** ADR INDEX read; 0009 and 0010 are directly on point and this design
implements them without contradiction. No other active entry touches these seams. No new ADR is
expected — every decision below is a mechanism choice inside the lane 0009 and 0010 already
settled.

---

## Core Concept

**A skill directory is a unit, so treat it as a unit at every hop.**

Today three separate places enumerate individual files: the build finds one `SKILL.md`, the install
copies one `SKILL.md`, and the install's overwrite guard inspects one file. Each of those is a
file-at-a-time decision standing in for a directory-at-a-time question, and each one loses the
siblings.

Replace all three with the directory as the operand:

- **Build**: copy the source tree, then overwrite the entry point with the generated one. Nesting,
  new file types, and future siblings need no further thought — they are already inside the tree.
- **Install**: mirror the dist tree onto the target — add, overwrite, and remove extras — so a
  re-install converges instead of accumulating.
- **Managed check**: ask the *directory* whether it is ours, by looking at its entry point. One
  answer governs every file in the tree.
- **Name**: derive it from the pack directory name, because that is the one thing both runtimes
  agree identifies the skill.

Two smaller things fall out of the same idea rather than needing their own reasoning. A flat `.md`
is not a unit, so it is not a skill — the flat lane goes. And a symlink whose pack source no longer
exists is not a unit either, so the installer sweeps it.

The reason this is the right shape and not merely a working one: the file-at-a-time code has to
decide, for each new kind of sibling, whether it is in scope. Every such decision is a place the
two runtimes can drift, and the drift is silent because Claude symlinks the directory and cannot
notice. Making the directory the operand removes the category of decision instead of answering it
once.

---

## Key Bets

- **B1.** A Claude skill's identity is its directory name, and an underscore-prefixed directory
  name is legal. *If false → `_my_mental_model` cannot be a skill at all, and ADR 0009's promise
  that slash invocation survives a command→skill migration needs a shim command in front of every
  migrated skill.* Evidence: the runtime's own validator message and forbidden-character list, read
  from `claude-code 2.1.237`. Not yet proven by a live `_my_*` invocation — that is Item 4's proof
  (spec Non-Goals, product-lens spec-F3).
- **B2.** A skill invoked on Claude can read a sibling file from its own directory. *If false →
  the split-instruction-file shape that is the entire repair for the failed v1 does not work, and
  Items 4 and 5 need a different carrier for `design_synthesis.md` and `visualize.md`.* Proven or
  disproven by invoking `example-skill` after install — the cheapest real check in this item.
- **B3.** Codex loads sibling files placed beside `SKILL.md` in `~/.agents/skills/<name>/` when the
  entry references them by relative path. *If false → Codex parity needs the instructions inlined
  into the entry point, which reintroduces exactly the "render instructions visible while
  thinking" failure on one runtime.*

B2 and B3 are why the example skill's content is not decorative: it must actually reference and
read both a flat sibling and a nested one, or the bets stay untested.

---

## Key Decisions

- **D1. The build copies the source skill tree, then overwrites the entry point.**
  `cp -R` the pack directory into `dist/codex/skills/<codex-name>/`, then write the generated
  `SKILL.md` (computed frontmatter + provenance header + body with frontmatter stripped) over the
  copied one. *Rejected: extending the `find` walk to enumerate siblings* — it forces a depth
  choice, a file-type choice, and an exclusion list, and the same choices then have to be made
  again and kept in step in `setup-codex.sh`.

- **D2. A directory skill's Codex name is derived from its pack directory name; frontmatter `name`
  is no longer consulted for it.** The rule: a directory starting with `_my_` becomes
  `my-` + the rest with underscores turned to hyphens (`_my_mental_model` → `my-mental-model`,
  reusing `strip_command_prefix` and `to_hyphen_name`); any other directory name passes through
  unchanged (`show-me` → `show-me`, `example-skill` → `example-skill`). *Rejected: keep reading
  frontmatter* — Claude requires the frontmatter name to match the directory, so trusting it makes
  the Codex name unsettable, and it leaves two sources of truth for one identity.

- **D3. The install mirrors the dist skill directory onto the target, and asks the entry point
  whether the directory is managed.** If the target `SKILL.md` is absent or carries the
  `Generated from` marker, the whole directory is ours: copy every file in, overwrite what differs,
  delete what dist no longer has. If the target `SKILL.md` exists without the marker, skip the
  directory whole and print the `--force` hint, as today. *Rejected: (a) stamping a marker into
  every copied sibling* — it mutates shipped content, cannot work for non-markdown assets, and
  still never removes a deleted sibling; *(b) a per-file flag that bypasses the user-authored
  guard* — same stale-file gap, and it silently weakens the guard for files nobody checked.

- **D4. `setup-global.sh` gains a generic sweep for managed symlinks whose pack source is gone.**
  For each entry in `~/.claude/<subdir>`, if it is a symlink pointing into this repo's
  `claude-pack/` and its target no longer exists, remove it. *Rejected: a targeted
  `rm ~/.claude/skills/example-skill.md`* — it is dead code one release later, and ADR 0009
  explicitly promises more command→skill migrations, so removals and renames are a recurring event.
  The pattern already exists on the Codex side (`setup-codex.sh:199-240`).

- **D5. The build's three roots become environment-overridable so the pack test can run the real
  build end-to-end against a fixture pack.** `CLAUDE_PACK`, `OVERRIDES_DIR` and `DIST_DIR` default
  to exactly today's values; the test points all three at a tmpdir holding a minimal fixture pack
  with a `_my_probe/` skill directory, a nested sibling, and its own `config.sh` allowlist, then
  asserts `my-probe/` appears with every file. This is what proves D2's mapping and D1's nesting at
  HEAD, given no `_my_*` skill directory ships in this item. *Rejected: (a) extracting the naming
  rule into a sourced helper for a unit test* — a new file, and it proves the function rather than
  the lane; *(b) deferring the mapping proof to Item 4* — leaves the code that Item 4 depends on
  unexercised, which is the thing this whole item exists to avoid.

- **D6. Delete the flat native-skill build lane** (`build-codex-pack.sh:338-365`). After
  `example-skill` converts, it has no user in the pack, and its only remaining effect would be to
  let a future author's flat `.md` build a working Codex skill while registering nothing on Claude
  — the same silent one-sided failure this item exists to remove, mirrored. *Rejected: keep the
  lane and make it warn or fail* — that keeps a second representation of "how a native skill
  reaches Codex" alive to serve zero users; with the lane gone, a flat file simply produces no
  skill on either runtime, which is the honest answer under ADR 0009. Raised by product-lens
  spec-F1.

- **D7. `example-skill` becomes the reference directory skill and the regression fixture.** Entry
  point plus one flat sibling plus one nested sibling, with the entry actually instructing the
  reader to open both. `uninstall-project.sh:108-114` gains `example-skill` to its directory loop
  and keeps `example-skill.md` in its file loop, so projects vendored before this change still get
  cleaned. *Rejected: a new throwaway directory beside the inert file* — it would ship a second
  example in the pack and leave the known-dead one in place.

---

## Architecture

```
claude-pack/skills/<dir>/            ← the unit; <dir> is the identity
        │                              SKILL.md + flat siblings + nested dirs
        │
   ┌────┴─────────────────────────────────────────┐
   │ Claude lane (unchanged)                      │ Codex lane (this item)
   ▼                                              ▼
setup-global.sh                             build-codex-pack.sh
  one symlink per entry                       allowlist? (keyed on <dir>)
  ~/.claude/skills/<dir> ──► pack             codex-name = f(<dir>)          ← D2
  + sweep dead managed symlinks    ← D4       cp -R tree ──► dist/…/<codex-name>/
                                              overwrite SKILL.md (generated) ← D1
                                                       │
                                              setup-codex.sh
                                                mirror dist dir ──► ~/.agents/skills/<codex-name>/
                                                managed? ask the entry point  ← D3
```

Data flow, once per allowlisted skill directory: the directory name produces the Codex name; the
tree produces the payload; the entry point produces the frontmatter and the managed marker. Nothing
else is consulted, and nothing is enumerated file by file.

Integration points, in the order a change touches them: `build-codex-pack.sh` (directory lane
rewritten, flat lane deleted, roots parameterized), `setup-codex.sh` (skills install becomes a
directory mirror), `setup-global.sh` (dead-symlink sweep), `codex-overrides/config.sh` (unchanged —
`example-skill` is already allowlisted), `claude-pack/skills/example-skill.md` → `example-skill/`,
`scripts/uninstall-project.sh` (directory-loop entry), `scripts/test_codex_orchestrator_pack.sh`
(sibling assertions + fixture build).

---

## Required Invariants

- Every file under an allowlisted pack skill directory appears in `dist/codex/skills/<codex-name>/`
  and then in `~/.agents/skills/<codex-name>/`, at the same relative path.
- Siblings are byte-identical to their pack source. The generated `SKILL.md` is the only file the
  build rewrites. (ADR 0010: no sanitization pass for native skills.)
- A skill's Codex name is a pure function of its pack directory name — same input, same output, no
  other file consulted.
- Re-running either installer converges: files added in the pack appear, changed files update,
  files deleted from the pack disappear from the target.
- A flat `.md` file in `claude-pack/skills/` produces no skill on either runtime.
- `NATIVE_SKILL_ALLOWLIST` continues to be keyed on the pack directory name, not the Codex name.
- The runtime-neutrality scan keeps its `-g 'SKILL.md'` glob (owner decision; sibling neutrality
  stays convention-only per ADR 0010).

---

## Component Overview

- **`scripts/build-codex-pack.sh`** — directory-skill lane rewritten per D1/D2; flat native-skill
  lane deleted per D6; `CLAUDE_PACK` / `OVERRIDES_DIR` / `DIST_DIR` become overridable per D5.
  Owns: what reaches `dist/`, and each skill's Codex name.
- **`scripts/setup-codex.sh`** — the skills install becomes a directory mirror per D3. Owns:
  convergence of `~/.agents/skills/<name>/`, and the user-authored-content guard at directory
  granularity.
- **`scripts/setup-global.sh`** — gains the dead-managed-symlink sweep per D4. Owns: `~/.claude/`
  reflecting the pack, including removals.
- **`claude-pack/skills/example-skill/`** — the pack's reference directory skill: entry point, one
  flat sibling, one nested sibling. Owns: demonstrating the shape to a future author, and being the
  live subject of B2 and B3.
- **`scripts/test_codex_orchestrator_pack.sh`** — gains sibling-presence assertions and the fixture
  build of D5. Owns: the regression guard on everything above.
- **`scripts/uninstall-project.sh`** — directory-form cleanup entry per D7.

---

## Non-Goals

Carried from the spec, not restated: mental-alignment behavior (Items 4, 5); v1 retirement
(Item 3); creating `_my_mental_model/` and its allowlist entry (Item 4); widening the
runtime-neutrality scan (owner decision); migrating the remaining commands. Plus, decided here:

- No sanitization or rewriting of sibling file content, ever. ADR 0010 forbids it.
- No change to how `NATIVE_SKILL_ALLOWLIST` is keyed or consulted.
- No proof of `/_my_*` slash resolution in this item (Item 4; product-lens spec-F3).

---

## Implementation Notes

- **Order matters in the build:** copy the tree first, then write the generated `SKILL.md` over it.
  Writing first and copying second silently reinstates the un-sanitized pack entry point.
- **`dist/` is wiped at build start** (`build-codex-pack.sh:258`), so the build needs no stale-file
  logic of its own. Only the install does.
- **`cp -R` of a symlinked source:** in this repo `.claude/` symlinks to `claude-pack/`, but the
  build reads `claude-pack/` directly, so no symlink dereferencing question arises. Keep it that
  way — do not route the build through `.claude/`.
- **The manifest's `skills` array should stay `["example-skill", "show-me"]`** after conversion. A
  change there means the name derivation or the allowlist key drifted.
- **D5's fixture must supply its own `config.sh`,** because the allowlist is sourced from
  `OVERRIDES_DIR` and a fixture skill absent from it is silently excluded — the exact gotcha
  ADR 0010 preserves.
- **Codex description constraint:** `description_for_native_skill` (`build-codex-pack.sh:243-255`)
  reads only frontmatter and there is no override map, so `example-skill`'s description must stay
  plain prose. A leading `*` crashes Codex's YAML parse.

---

## Potential Risks

| Risk | Impact | Mitigation |
|---|---|---|
| The directory mirror deletes a file a user hand-added inside an installed skill dir | Med | Mirror only when the target entry point is managed or absent; an unmarked entry point skips the whole directory. The concept already accepts that copy-install edits are lost — that is why promotion from a copy install fails closed. |
| Overridable build roots let a test write into the real `dist/` | Low | Defaults unchanged; the test sets all three together. Assert in the test that its `DIST_DIR` is under its tmpdir before running. |
| Deleting the flat lane breaks a consumer with an allowlisted flat skill | Low | `example-skill` was the only flat entry in the allowlist, and it converts in the same change. |
| B2 or B3 turns out false | High | Both are checked by manual invocation inside this item, before Items 4 and 5 commit to the two-file shape. This is the cheapest place to find out. |
| The Claude runtime validates frontmatter `name` against the directory more strictly than assumed | Low | `example-skill` keeps `name: example-skill`, matching its directory; the pack always sets them equal. Only the Codex-side name diverges, and that name is generated. |

---

## Integration Strategy

This replaces nothing user-visible. `/example-skill` becomes invocable where it previously did
nothing; every other skill and command is untouched. The change is a prerequisite for Item 3
(v1 retirement) and Item 4 (the real skill directory), and every later command→skill migration
under ADR 0009 rides the same lane.

Sequencing inside the item: convert `example-skill` first so the new build has a real subject,
then the build, then the install, then the sweep, then the tests. Rebuild `dist/` and refresh both
global installs at the end, as the repo's convention requires.

---

## Validation Approach

**Automated** — `scripts/test_codex_orchestrator_pack.sh`:
- `dist/codex/skills/example-skill/` contains the entry point, the flat sibling, and the nested
  sibling; the entry point carries generated frontmatter and the flat sibling is byte-identical to
  its pack source.
- The fixture build (D5): a tmpdir pack with `_my_probe/` yields `dist/skills/my-probe/` with the
  nested file present — proving the `_my_x` → `my-x` mapping and nesting together.
- A flat `.md` in the fixture pack yields no skill directory (D6).
- Temp-`HOME` install places all three `example-skill` files under `~/.agents/skills/`.
- Convergence: install twice; the second run updates rather than skipping, and a file removed from
  dist between runs disappears from the target.
- The existing `-g 'SKILL.md'` neutrality scan still passes, unchanged.

**Manual, and it is the part that matters** — B2 and B3:
- `./scripts/setup-global.sh`, start a fresh Claude session, invoke `/example-skill`, confirm it
  reads the flat sibling and the nested one.
- `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`, run the skill on Codex,
  confirm the same.
- Confirm `~/.claude/skills/example-skill.md` is gone after re-running `setup-global.sh` (D4).

**Existing suite**: docs, pipeline-sync, adr, global-setup, codex-orchestrator-pack.

---

## Next-Stage Handoff

**Fixed:** the directory-as-unit concept and D1–D7. The invariants above. The manual B2/B3 checks
are not optional — they are the only evidence that the two-instruction-file shape works at all.

**Open for the plan:** exact sibling filenames and the example's prose; whether the install mirror
is `rsync`-style bash or a delete-then-copy; the fixture pack's minimal contents; where the new
assertions sit in the test file.

**Risky, do first:** invoke the converted `example-skill` on Claude as soon as it exists, before
writing any build code. If B2 is false, the rest of the item's shape changes.

**Carried forward, needs owner action outside this item** (product-lens spec-F2, spec-F3): epic
Item 4's In Scope should name the `_my_mental_model` allowlist entry, and the epic's High risk on
directory-skill slash resolution should re-point from Item 2 to Item 4.

---

**Next Step:** After approval → `/_my_plan`
