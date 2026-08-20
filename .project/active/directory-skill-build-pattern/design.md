# Design: Directory-Skill Build Pattern

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-20 10:30
**Branch:** anchor-on-the-point
**Commit at authoring:** 7739a5f
**Spec:** `.project/active/directory-skill-build-pattern/spec.md`
**Epic position:** MENTAL-ALIGN-V2 **Item 5**. Authored as Item 2 (first), moved last the same day.
The reordering changed three things below, each marked: **D5 is rejected** (its premise is gone),
**D7's rationale narrows**, and the Claude-side sibling bets are now proven upstream in epic Item 3
rather than here.

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
- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` — MENTAL-ALIGN-V2, Item 5
  (see its "Restructure" section for the old→new item mapping)
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

Every future command→skill migration reuses this lane. It was originally scheduled first, proven
against a placeholder; the owner moved it last so the capability could be built and used on Claude
without waiting on packaging. So the lane now gets proven against the real skill — instruction
sibling, nested `feedback/` directory and all — which is stronger evidence than a placeholder could
have given.

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
  from `claude-code 2.1.237`, plus underscore-prefixed probe skills observed registering on
  2026-08-20. Proven live in epic Item 3, upstream of this item.
- **B2.** A skill invoked on Claude can read a sibling file from its own directory. *If false →
  the split-instruction-file shape that is the entire repair for the failed v1 does not work, and
  epic Items 3 and 4 need a different carrier for `design_synthesis.md` and `visualize.md`.*
  Settled upstream: epic Item 3's done-state requires reading a flat and a nested sibling and
  recording the working reference form. By the time this item runs, B2 is a known fact, not a bet —
  and if it came out false, this item's shape changes with it.
- **B3.** Codex loads sibling files placed beside `SKILL.md` in `~/.agents/skills/<name>/` when the
  entry references them by relative path. *If false → Codex parity needs the instructions inlined
  into the entry point, which reintroduces exactly the "render instructions visible while
  thinking" failure on one runtime.*

B3 is the one that still lives here, and it is why the example skill's content is not decorative:
something in `dist/` must actually reference and read both a flat sibling and a nested one on Codex,
or the bet stays untested. The real skill does that too, but it does it as part of doing its job —
the example is the version a test can assert on cheaply.

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

- **D5. ~~Parameterize the build's roots for a fixture build.~~ REJECTED — premise removed by the
  restructure (2026-08-20).** The plan was to make `CLAUDE_PACK`, `OVERRIDES_DIR` and `DIST_DIR`
  environment-overridable so the pack test could build a tmpdir fixture pack containing a
  `_my_probe/` skill and assert `my-probe/` came out with every file. That existed for one reason:
  when this item ran *first*, no `_my_`-prefixed skill directory shipped in the pack, so nothing
  exercised D2's name mapping or D1's nested copy at HEAD. Running last, `_my_mental_model` is
  already there, with an instruction sibling and a nested `feedback/` directory, so every build
  exercises both for real. Three lines of indirection in a build script to reach a fixture that
  duplicates the real subject is not worth it. *What is kept instead:* the assertions themselves,
  pointed at the real skill and at `example-skill` in `dist/`.

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
  reader to open both. `uninstall-project.sh:108-114` gains `example-skill` and `_my_mental_model`
  to its directory loop and keeps `example-skill.md` in its file loop, so projects vendored before
  this change still get cleaned. *Rejected: a new throwaway directory beside the inert file* — it
  would ship a second example in the pack and leave the known-dead one in place.
  *Rationale narrowed by the restructure:* the owner picked this conversion as the throwaway subject
  for proving the lane, and the real skill is now that subject. What remains is still worth doing —
  it retires a file two prior designs called dead weight, and it gives the pack a copyable
  directory-skill example, which is the pattern-matching failure ADR 0009 exists to prevent. But it
  is now droppable at the owner's discretion, not load-bearing for any proof.

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
  lane deleted per D6; the v1 path rewrite at `:138` and shared-spec copy at `:426` removed.
  Owns: what reaches `dist/`, and each skill's Codex name.
- **`scripts/setup-codex.sh`** — the skills install becomes a directory mirror per D3. Owns:
  convergence of `~/.agents/skills/<name>/`, and the user-authored-content guard at directory
  granularity.
- **`scripts/setup-global.sh`** — gains the dead-managed-symlink sweep per D4. Owns: `~/.claude/`
  reflecting the pack, including removals.
- **`claude-pack/skills/example-skill/`** — the pack's reference directory skill: entry point, one
  flat sibling, one nested sibling. Owns: demonstrating the shape to a future author, and being the
  cheap assertable subject for B3.
- **`claude-pack/skills/_my_mental_model/`** — not built here (epic Item 3 owns its content), but it
  is this item's real test subject: the first `_my_`-prefixed skill directory, with a nested
  `feedback/` directory, so it exercises D1's nesting and D2's name mapping every build.
- **`scripts/test_codex_orchestrator_pack.sh`** — gains sibling-presence assertions against both
  skills in `dist/`. Owns: the regression guard on everything above.
- **`scripts/uninstall-project.sh`** — directory-form cleanup entries per D7.
- **`codex-overrides/config.sh`** — gains the `_my_mental_model` allowlist entry, keyed pack-side,
  and loses the v1 command description override at `:37`.

---

## Non-Goals

Carried from the spec, not restated: mental-alignment behavior (epic Items 3, 4); the two v1 file
deletions (epic Item 2); creating `_my_mental_model/` and its instruction files (epic Item 3);
widening the runtime-neutrality scan (owner decision); migrating the remaining commands. Plus,
decided here:

- No sanitization or rewriting of sibling file content, ever. ADR 0010 forbids it.
- No change to how `NATIVE_SKILL_ALLOWLIST` is **keyed** — pack-side directory name — though this
  item does add an entry to it.
- No proof of `/_my_*` slash resolution **on Claude** here; that is epic Item 3's, upstream
  (product-lens spec-F3). Codex-side resolution is in scope.

---

## Implementation Notes

- **Order matters in the build:** copy the tree first, then write the generated `SKILL.md` over it.
  Writing first and copying second silently reinstates the un-sanitized pack entry point.
- **`dist/` is wiped at build start** (`build-codex-pack.sh:258`), so the build needs no stale-file
  logic of its own. Only the install does.
- **`cp -R` of a symlinked source:** in this repo `.claude/` symlinks to `claude-pack/`, but the
  build reads `claude-pack/` directly, so no symlink dereferencing question arises. Keep it that
  way — do not route the build through `.claude/`.
- **The manifest's `skills` array should read `["example-skill", "my-mental-model", "show-me"]`**
  when this item is done — `example-skill` unchanged by the conversion, `my-mental-model` newly
  present. Anything else means the name derivation or the allowlist key drifted.
- **The allowlist entry is the easiest thing in this item to forget,** and forgetting it fails
  silently — `build-codex-pack.sh:370` tests the *pack-side* directory basename against
  `NATIVE_SKILL_ALLOWLIST`, so `_my_mental_model` absent from that list means the build exits 0 and
  the skill simply is not in `dist/`. It is the gotcha ADR 0010 exists to preserve. The manifest
  assertion below is the guard.
- **Codex description constraint:** `description_for_native_skill` (`build-codex-pack.sh:243-255`)
  reads only frontmatter and there is no override map, so `example-skill`'s description must stay
  plain prose. A leading `*` crashes Codex's YAML parse.

---

## Potential Risks

| Risk | Impact | Mitigation |
|---|---|---|
| The directory mirror deletes a file a user hand-added inside an installed skill dir | Med | Mirror only when the target entry point is managed or absent; an unmarked entry point skips the whole directory. The concept already accepts that copy-install edits are lost — that is why promotion from a copy install fails closed. |
| Deleting the flat lane breaks a consumer with an allowlisted flat skill | Low | `example-skill` was the only flat entry in the allowlist, and it converts in the same change. |
| B3 turns out false — Codex won't read siblings | High | Checked by manual invocation inside this item. If false, Codex parity needs the instructions inlined into the entry point, which reintroduces the v1 failure on one runtime; that is a real decision for the owner, not something to paper over. Claude is unaffected and already shipping by then. |
| The allowlist entry is omitted | Med | Fails silently — build exits 0, skill absent from `dist/`. Guarded by the manifest assertion in Validation. |
| Arriving here to find B2 was false upstream | High | Epic Item 3 settles it long before this item runs. If it was false, this design's shape changes with it and should be re-read, not applied. |
| The Claude runtime validates frontmatter `name` against the directory more strictly than assumed | Low | `example-skill` keeps `name: example-skill`, matching its directory; the pack always sets them equal. Only the Codex-side name diverges, and that name is generated. |

---

## Integration Strategy

This is the epic's last item, so it inherits a working skill rather than enabling one. On Claude
nothing changes except that `/example-skill` becomes invocable where it previously did nothing. On
Codex, `/_my_mental_model` gains a working implementation for the first time since epic Item 2
deleted the v1 command — which is why the epic forbids rebuilding `dist/` before this item: doing
so earlier would strip the Codex side with nothing to replace it. Every later command→skill
migration under ADR 0009 rides the same lane.

Sequencing inside the item: build lane first (the real skill is already there to copy), then the
install, then the `example-skill` conversion, then the sweep, then the v1 wiring cleanup, then the
tests. Rebuild `dist/` and refresh both global installs at the end, as the repo's convention
requires — and this is the rebuild the epic has been deferring.

---

## Validation Approach

**Automated** — `scripts/test_codex_orchestrator_pack.sh`:
- `dist/codex/skills/example-skill/` contains the entry point, the flat sibling, and the nested
  sibling; the entry point carries generated frontmatter and the flat sibling is byte-identical to
  its pack source.
- `dist/codex/skills/my-mental-model/` exists — not `_my_mental_model/` — and contains
  `design_synthesis.md`, `visualize.md`, and `feedback/` with both starter bodies. This is the
  mapping proof (D2) and the nesting proof (D1), against the real skill.
- `dist/codex/manifest.json`'s `skills` array is exactly `["example-skill", "my-mental-model",
  "show-me"]` — the guard against a silently omitted allowlist entry.
- A flat `.md` dropped in `claude-pack/skills/` yields no skill directory (D6).
- Temp-`HOME` install places every file of both skills under `~/.agents/skills/`.
- Convergence: install twice; the second run updates rather than skipping, and a file removed from
  dist between runs disappears from the target.
- The existing `-g 'SKILL.md'` neutrality scan still passes, unchanged.

**Manual** — B3, and the D4 cleanup:
- `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`, then run both
  `my-mental-model` and `example-skill` on Codex and confirm each reads its flat sibling and its
  nested one.
- `./scripts/setup-global.sh`, fresh Claude session, invoke `/example-skill` and confirm it reads
  both siblings. (The same check on `/_my_mental_model` already happened in epic Item 3.)
- Confirm `~/.claude/skills/example-skill.md` is gone after re-running `setup-global.sh` (D4).

**Existing suite**: docs, pipeline-sync, adr, global-setup, codex-orchestrator-pack.

---

## Next-Stage Handoff

**Fixed:** the directory-as-unit concept and D1, D2, D3, D4, D6, D7. The invariants above. D5 is
rejected — do not reintroduce build-root parameterization without a new reason.

**Open for the plan:** exact sibling filenames and the example's prose; whether the install mirror
is `rsync`-style bash or a delete-then-copy; where the new assertions sit in the test file; the
order of the v1 wiring deletions.

**Risky, do first:** the Codex-side unknowns, before writing the install mirror. Does Codex load a
symlinked skill directory, and does it tolerate a frontmatter `name` that differs from the directory
name? If both are yes, the native-skill install could be N renamed symlinks instead of a copy tree,
and D1/D3 shrink considerably. A prepared probe prompt sits at
`/tmp/directory-skill-spike-prompt.md`, sections B1–B8; its Claude-side half (A1–A10) is superseded
by epic Item 3. The copy-tree design here is the fallback, so a negative answer costs nothing.

**Read this before applying the design.** It was written when this item ran first. If epic Item 3
found that a Claude skill cannot read its siblings, or that the reference form is cwd-dependent,
this design needs re-reading rather than executing — the whole lane exists to ship files that turn
out to be unreachable.

**Resolved since authoring** (product-lens spec-F2, spec-F3): the epic now names the
`_my_mental_model` allowlist entry in this item's In Scope, and its High risk on directory-skill
slash resolution points at epic Item 3. No owner action outstanding.

---

**Next Step:** After approval → `/_my_plan`
