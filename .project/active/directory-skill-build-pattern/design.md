# Design: Directory-Skill Build Pattern

**Status:** Draft (revision 3)
**Owner:** Reid W
**Created:** 2026-08-20 10:30 · **Revised:** 2026-08-21 (rev 2 → rev 3, the adapter decided)
**Branch:** anchor-on-the-point
**Commit at authoring:** 7739a5f
**Spec:** `.project/active/directory-skill-build-pattern/spec.md` (revision 4)
**Epic position:** MENTAL-ALIGN-V2 **Item 5**. Authored as Item 2 (first), moved last the same day.
D5 is rejected — its premise went with the reordering.

---

## Revision note

**Revision 1 → 2.** Revision 1 was written under ADR 0010, which forbade rewriting native skill
files at all. The owner reversed that on 2026-08-20 (ADR 0011): skill directories go through the same
Codex adapter as commands, applied to every file in the directory. Three things revision 1 built on
0010 are deleted, not qualified:

- siblings arrive byte-identical to their pack source;
- the generated `SKILL.md` is the only file the build rewrites;
- the harness-neutrality scan stays pointed at `SKILL.md` only, because sibling neutrality was
  convention rather than obligation.

Four more changes:

- **`example-skill` is deleted, not converted** (owner: *"delete it."*). Every place revision 1 made
  it the reference directory skill, the proof subject, or a test fixture, that role is gone. The real
  skill `claude-pack/skills/_my_mental_model/` is the only subject.
- **D6 is no longer a decision to argue.** Deleting the flat single-file skill lane is an owner
  decision, carried by the spec.
- **D2 is real work, not a no-op.** Revision 1 and `spike-findings.md` both said the build already
  writes the derived Codex name. It does not — `build-codex-pack.sh:386` writes whatever the source
  frontmatter says, which is `name: _my_mental_model`.
- **The Codex-side unknowns are answered** by three probes on 2026-08-20: packaging, working
  directory, and context-inheriting spawn. B3 stops being a bet, the install-strategy choice reopens,
  and the Codex spawn mechanism is now a known constraint. See Research Findings.

**Revision 2 → 3.** Revision 2 corrected the doc but left the adapter undesigned. The owner walked
the five open questions on 2026-08-21 and answered all of them. New decisions D8, D9, D10; D1 gains
its file-type rule; D3 is confirmed against the symlink alternative it was re-opened against. No open
design questions remain.

One of the five answers was owner-originated rather than a choice among options offered: delimiting
the harness-specific spans so the adapter can find them structurally. That is D9.

---

## Overview

Make a skill directory ship as one unit on both runtimes: the Codex build and install stop
enumerating `SKILL.md` and start mirroring the whole directory, and a skill's Codex name becomes a
function of its pack directory name — and every file in the directory goes through the Codex adapter
on the way. Proven against the real skill, `claude-pack/skills/_my_mental_model/`: an entry point,
two instruction siblings, and a nested `feedback/` directory.

## Related Artifacts

- **Spec:** `.project/active/directory-skill-build-pattern/spec.md`
- **Product-lens ledger:** `.project/active/directory-skill-build-pattern/product-lens.md`
  (spec pass: DISPOSED, three findings, all folded into this design)
- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` — MENTAL-ALIGN-V2, Item 5
  (see its "Restructure" section for the old→new item mapping)
- **Required Reading:**
  - `.project/active/directory-skill-build-pattern/spike-findings.md` — the packaging probes
  - `.project/active/directory-skill-build-pattern/cwd-spike-findings.md` — Codex preserves the
    session working root and hands the skill its own `SKILL.md` path
  - `.project/active/directory-skill-build-pattern/fork-spike-findings.md` — Codex's
    context-inheriting spawn (`spawn_agent` with `fork_turns`)
  - `.project/active/codex-resume-spike/spike-findings.md` — epic Item 1, the resumed-render path
  - `.project/active/render-switch-feedback/harness-phrases.md` — Item 4's dictionary handoff
  - `.project/concepts/mental-alignment-skill-design.md` (Distribution lane, Appendix),
    `.project/concepts/mental-alignment-skill-design-review.md` (ADR candidate 3, m4)
  - `.project/adr/0009-directory-skills-pattern.md`,
    `.project/adr/0011-native-skill-codex-adapter.md` (superseding
    `0010-native-skill-codex-lane.md` — read 0010 only for what changed)

---

## The Point

A pack capability **is** a skill directory: a `SKILL.md` entry point plus the sibling instruction
and feedback files it reads, shipped and versioned as one unit, installed on Claude as a single
symlink to the pack directory. That is ADR 0009, owner-graded, owner-originated ("this feels like
the right time to start migrating the Claude 'commands' to skills", 2026-08-19). ADR 0011 carries
it to the Codex seam: the build and install copy **every** file of an allowlisted skill directory,
and the Codex adapter translates every one of them. That reversed ADR 0010, which had required skill
bodies to be runtime-neutral because no translation pass existed for them — a requirement the first
real skill cannot meet, since it has to say where its own directory is and how to spawn an agent that
inherits the conversation. 0011 is owner-graded.

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
lane's only effect is to make a shape that is dead on Claude build clean on Codex. With
`example-skill.md` deleted it has no user at all.

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

**And the build currently reads frontmatter, so at HEAD the name is wrong.**
`build-codex-pack.sh:375` takes the name from frontmatter and `:386` writes it straight into the
generated entry point. Build the pack today and the real skill ships as
`dist/codex/skills/_my_mental_model/` carrying `name: _my_mental_model`. Two live commands then
offer the owner a handle nothing answers to, because the command lane rewrites their
`/_my_mental_model` mentions to `my-mental-model` (`_my_epic_plan.md:44`,
`_my_concept_design_review.md:219`, rewrite at `build-codex-pack.sh:155-158`). D2 is code to write.

**The allowlist is keyed pack-side.** `contains "$base" …` at `build-codex-pack.sh:370` tests the
*source directory* basename against `NATIVE_SKILL_ALLOWLIST` (`codex-overrides/config.sh:58`).
`example-skill` is already listed. A missing entry drops the skill with no error.

**Existing precedent for stale-link cleanup.** `setup-codex.sh:199-240` already has
`remove_path_if_managed` plus a `cleanup_legacy_prompts` sweep — remove a target if it is a
symlink pointing into a path prefix we manage. `setup-global.sh` has no equivalent.

**The probes answered every Codex-side unknown** (2026-08-20, three findings docs, all Required
Reading above):

- *Packaging.* Codex reads flat, nested, twice-nested and non-markdown siblings, and tolerates stray
  files without warning — B3 is confirmed, not a bet. It registers the frontmatter `name` and does
  not answer to the directory name, which makes the generated entry point mandatory. It loads a
  symlinked skill *directory* but silently refuses a skill whose `SKILL.md` is itself a symlink,
  which makes `build-codex-pack.sh:521` and `CLAUDE.md:53` false and reopens the install-strategy
  choice.
- *Working directory.* Skill activation preserves the session working root; `-C/--cd` is what moves
  it. Codex hands the skill its own absolute `SKILL.md` path in the skills inventory, so siblings
  resolve from that locator rather than from cwd. The skill's eight project-relative output paths
  need no rewrite, and neither do the command-derived skills.
- *Context-inheriting spawn.* The live collaboration surface's `spawn_agent` takes a `fork_turns`
  parameter. With `"all"` a worker recovered a nonce that existed only in its parent's completed
  conversation turn; with `"none"` it could not. So carried policy has a real Codex mechanism, and
  `followup_task` against the returned agent identity is the resumed-render path. Two constraints
  ride along. **The defaults are inverted:** `fork_turns` defaults to `all`, where Claude's default
  spawn is fresh — so discovered and clean room have to pass `"none"` explicitly or they silently
  inherit the conversation, which under clean room breaks a restriction the owner stated in their own
  words. And the spawn returns a runtime-assigned identity (`/root/<parent>/<task_name>`), so the
  coordinator must keep what it got back instead of rebuilding the handle from a slug the way
  `SKILL.md:81` and `:115` do on Claude.

**Decision records checked.** ADR INDEX read; 0009 and 0011 are directly on point and this design
implements them without contradiction. 0010 is superseded. No other active entry touches these
seams. No new ADR is expected — every decision below is a mechanism choice inside the lane 0009 and
0011 already settled.

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
- **B3.** ~~Codex loads sibling files placed beside `SKILL.md`.~~ **Settled by probe, 2026-08-20 —
  no longer a bet.** Codex read a flat sibling, two nested ones, and a non-markdown file, and
  tolerated stray files with no warning (`spike-findings.md`, B4/B8). The one refinement: sibling
  paths must be joined to the absolute `SKILL.md` path Codex supplies, not left bare and relative
  (`cwd-spike-findings.md`).

No bets are left open in this item. Every mechanism it depends on has been run.

---

## Key Decisions

- **D1. The build copies the source skill tree, then runs the adapter over it.**
  `cp -R` the pack directory into `dist/codex/skills/<codex-name>/`, then transform what landed
  there: the entry point becomes computed frontmatter + provenance header + body with frontmatter
  stripped, and the siblings get the same substitution pass. *Rejected: extending the `find` walk to
  enumerate siblings* — it forces a depth choice, a file-type choice, and an exclusion list, and the
  same choices then have to be made again and kept in step in `setup-codex.sh`.
  **File types:** the pass transforms `.md` files and copies everything else through byte-for-byte.
  Every file in every pack skill directory is markdown today, so this costs nothing now and keeps a
  future script or asset from being mangled.

- **D2. A directory skill's Codex name is derived from its pack directory name; frontmatter `name`
  is no longer consulted for it.** The rule: a directory starting with `_my_` becomes
  `my-` + the rest with underscores turned to hyphens (`_my_mental_model` → `my-mental-model`,
  reusing `strip_command_prefix` and `to_hyphen_name`); any other directory name passes through
  unchanged (`show-me` → `show-me`). **This is unimplemented today** — the build reads frontmatter
  (`build-codex-pack.sh:375`, written out at `:386`), so at HEAD the skill would ship as
  `_my_mental_model`. `spike-findings.md` says the build already does this; that claim is wrong and
  is corrected in place there. *Rejected: keep reading frontmatter* — Claude requires the frontmatter
  name to match the directory, so trusting it makes the Codex name unsettable, and it leaves two
  sources of truth for one identity.

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
  pointed at the real skill in `dist/`.

- **D6. Delete the flat native-skill build lane** (`build-codex-pack.sh:338-365`). **Owner
  decision, carried by the spec** — not a call this design makes. With `example-skill.md` deleted the
  lane has no user, and its only remaining effect would be to let a future author's flat `.md` build
  a working Codex skill while registering nothing on Claude — the same silent one-sided failure this
  item exists to remove, mirrored. With the lane gone a flat file produces no skill on either
  runtime, which is the honest answer under ADR 0009. Raised by product-lens spec-F1.

- **D7. `claude-pack/skills/example-skill.md` is deleted.** **Owner decision** (*"delete it."*),
  replacing revision 1's conversion-to-directory-form. Consequences: `uninstall-project.sh:108-114`
  drops its `example-skill.md` entry and gains `_my_mental_model` to its directory loop, and
  `setup-global.sh` needs the D4 sweep so the already-installed
  `~/.claude/skills/example-skill.md` symlink actually goes away. The pack loses its example of the
  directory-skill shape; `_my_mental_model` and `show-me` are what a future author copies from.
  *Revision 1 argued for conversion* on the grounds that it gave the pack a copyable example. The
  owner chose deletion over that.

- **D8. Substitutions are per-lane, over a shared common pass.** The build gains
  `sanitize_skill_body_for_codex` beside the existing command and rule sanitizers. Entries common to
  all three — the `~/.claude/scripts/…` path rewrites, `$ARGUMENTS`, the Claude agent-tool vocabulary
  — move into one `apply_common_substitutions` that every lane pipes through; lane-specific entries
  stay in their lane. *Rejected: reusing the command list on skill bodies* — it does not just read
  untidily, it corrupts content. The command rule that rewrites `/_my_x` as a slash-command mention
  fires inside the real path at `_my_mental_model/SKILL.md:265`, turning
  `` `claude-pack/skills/_my_mental_model` `` into `` `claude-pack/skills`my-mental-model`` ``. The
  skill lane omits that rule; the skill body contains no slash-command mentions. *Rejected: an
  external table both lanes read* — the entries are perl substitutions carrying regex metacharacters,
  and one is an embedded code block, so a table needs an escaping layer and a parser for no gain.
  *Rejected: keying entries to a specific source file* — machinery for a second skill that does not
  exist. Revisit when one needs a sentence-level rewrite.

- **D9. Harness-specific spans are delimited in the pack file, and the adapter substitutes them by
  key.** `[OWNER]` — owner-originated: *"adding some clear delimiters around those phrases is also a
  good idea."* The form is a block-level comment pair carrying a key:

  ```markdown
  <!-- harness-block: agent-dispatch -->
  …Claude text…
  <!-- /harness-block -->
  ```

  The skill lane replaces the enclosed lines with the Codex text registered under that key. This is
  the point of the mechanism: a text-keyed substitution stops firing the moment someone rewords the
  sentence it matched, and nothing notices. A key survives rewording. Two accepted costs. Claude's
  agent reads the markers, because Claude reads the pack file live through the install symlink with no
  build step — an HTML comment reading `harness-block` should be inert, but it is noise in an
  instruction file. And a block with no registered Codex text passes through unchanged and silently,
  which matches the owner's standing call that no new failure conditions are added. *Rejected: an
  inline marker form for mid-sentence spans* — a second, worse syntax for no gain; blocks only.

- **D10. The Claude prose keeps the agent handle it was given, instead of rebuilding it from the
  slug.** Today the coordinator names its agent `synthesis-{slug}` (`SKILL.md:81`) and then
  reconstructs that name to address it (`:115`, `:170`). Codex hands back an identity at spawn
  (`/root/<parent>/<task_name>`) and `followup_task` needs that value. Rewriting the Claude side to
  record-and-reuse leaves vocabulary as the only difference (`SendMessage` → `followup_task`), and is
  more correct on Claude too — it drops the assumption that the requested name is the assigned name.
  Behavior on Claude is unchanged, so a manual `/_my_mental_model` run confirms it. *Rejected:
  leaving the Claude prose alone and translating all three sentences* — three fragile entries in the
  part of the skill most likely to be reworded next. D9 and D10 compound: D9 makes a substitution
  survive rewording, D10 reduces how much has to be substituted at all.

- **D3 confirmed against the symlink alternative.** The probe reopened the option of pointing
  `~/.agents/skills/<name>` at `dist/codex/skills/<name>` and letting the filesystem converge, by
  falsifying the claim it had been dismissed on. Still rejected, for two reasons that the probe did
  not remove: the install would depend on the repo staying put, and `dist/` is wiped at the start of
  every build (`build-codex-pack.sh:258`), so every rebuild leaves a window where the installed skill
  points at nothing — and Codex's tolerance for a dangling skill symlink is unmeasured (A10 tested
  Claude). Copy also keeps one story for how every Codex asset installs.

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
                                              adapter pass over every file   ← D1
                                                       │
                                              setup-codex.sh
                                                mirror dist dir ──► ~/.agents/skills/<codex-name>/
                                                managed? ask the entry point  ← D3
```

Data flow, once per allowlisted skill directory: the directory name produces the Codex name; the
tree produces the payload; the entry point produces the frontmatter and the managed marker. Nothing
else is consulted, and nothing is enumerated file by file.

Integration points, in the order a change touches them: `build-codex-pack.sh` (directory lane
rewritten to copy-then-transform, flat lane deleted, v1 path rewrite and shared-spec copy removed),
`setup-codex.sh` (skills install becomes a directory mirror), `setup-global.sh` (dead-symlink sweep),
`codex-overrides/config.sh` (gains the `_my_mental_model` allowlist entry, loses the v1 description
override at `:37`), `claude-pack/skills/_my_mental_model/` (phrase edits only),
`claude-pack/skills/example-skill.md` (deleted), `scripts/uninstall-project.sh` (entry swap),
`scripts/test_codex_orchestrator_pack.sh` (sibling and adapter assertions).

---

## Required Invariants

- Every file under an allowlisted pack skill directory appears in `dist/codex/skills/<codex-name>/`
  and then in `~/.agents/skills/<codex-name>/`, at the same relative path.
- The Codex adapter runs over every file in the tree, not only the entry point (ADR 0011).
- A skill's Codex name is a pure function of its pack directory name — same input, same output, no
  other file consulted.
- Re-running either installer converges: files added in the pack appear, changed files update,
  files deleted from the pack disappear from the target.
- A flat `.md` file in `claude-pack/skills/` produces no skill on either runtime.
- `NATIVE_SKILL_ALLOWLIST` continues to be keyed on the pack directory name, not the Codex name.
- A non-inheriting spawn in the adapted text names `fork_turns: "none"` explicitly. Omitting it
  means inheritance on Codex — the opposite of Claude's default, and a silent breach of clean room.
- Every harness-specific span in a skill file sits inside a keyed `harness-block` marker, and the
  adapter substitutes by key, never by matching sentence text (D9).
- The Claude-side capability behaves as it did before this item.
- No new build-time failure condition is added (owner decision).

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
- **`claude-pack/skills/_my_mental_model/`** — its Claude behavior belongs to epic Items 3 and 4, but
  it is this item's only subject: the first `_my_`-prefixed skill directory, with instruction siblings
  and a nested `feedback/` directory, so every build exercises D1's nesting and D2's name mapping.
  This item edits its harness-specific phrasing and nothing else.
- **`claude-pack/skills/example-skill.md`** — deleted per D7.
- **`scripts/test_codex_orchestrator_pack.sh`** — gains sibling assertions against the skill in
  `dist/`, and loses whatever referenced `example-skill`. Owns: the regression guard on everything
  above.
- **`scripts/uninstall-project.sh`** — drops the `example-skill.md` entry, gains the skill directory,
  per D7.
- **`codex-overrides/config.sh`** — gains the `_my_mental_model` allowlist entry, keyed pack-side,
  and loses the v1 command description override at `:37`.

---

## Non-Goals

Carried from the spec, not restated: what the skill does on Claude (epic Items 3, 4); the two v1
file deletions (epic Item 2); creating `_my_mental_model/` and its instruction files (epic Item 3);
a general-purpose detector for harness-specific phrases (owner decision); new build-time checks or
failure conditions (owner decision); automated behavioral tests of the skill on either runtime;
migrating the remaining commands. Plus, decided here:

- No change to `sanitize_rule_body_for_codex` or the rules and agents lanes.
- No change to how `NATIVE_SKILL_ALLOWLIST` is **keyed** — pack-side directory name — though this
  item does add an entry to it.
- No proof of `/_my_*` slash resolution **on Claude** here; that is epic Item 3's, upstream
  (product-lens spec-F3). Codex-side resolution is in scope.

---

## Implementation Notes

- **Order matters in the build:** copy the tree first, then transform what landed there. Writing
  first and copying second silently reinstates the untranslated pack entry point.
- **`dist/` is wiped at build start** (`build-codex-pack.sh:258`), so the build needs no stale-file
  logic of its own. Only the install does.
- **`cp -R` of a symlinked source:** in this repo `.claude/` symlinks to `claude-pack/`, but the
  build reads `claude-pack/` directly, so no symlink dereferencing question arises. Keep it that
  way — do not route the build through `.claude/`.
- **The manifest's `skills` array should read `["my-mental-model", "show-me"]`** when this item is
  done — `example-skill` gone, `my-mental-model` newly present. Anything else means the name
  derivation or the allowlist key drifted.
- **The allowlist entry is the easiest thing in this item to forget,** and forgetting it fails
  silently — `build-codex-pack.sh:370` tests the *pack-side* directory basename against
  `NATIVE_SKILL_ALLOWLIST`, so `_my_mental_model` absent from that list means the build exits 0 and
  the skill simply is not in `dist/`. The manifest assertion below is the guard.
- **Codex description constraint:** `description_for_native_skill` (`build-codex-pack.sh:243-255`)
  reads only frontmatter and there is no override map, so the skill's own description must stay plain
  prose. A leading `*` crashes Codex's YAML parse. It is plain prose today
  (`_my_mental_model/SKILL.md:3`) — the constraint is to keep it that way.
- **Two phrases must survive the adapter untouched.** `harness-phrases.md` flags `SKILL.md:197` and
  `:206` as already runtime-aware and true on both harnesses. A substitution that fires on them
  turns a correct statement into a Codex-only claim.
- **The phrase inventory is re-derived at execution time,** from the files, as literal strings. The
  lists in the spec and in `harness-phrases.md` are inputs, not the inventory — they went stale the
  moment Item 4 landed and will go stale again.

---

## Potential Risks

| Risk | Impact | Mitigation |
|---|---|---|
| The directory mirror deletes a file a user hand-added inside an installed skill dir | Med | Mirror only when the target entry point is managed or absent; an unmarked entry point skips the whole directory. The concept already accepts that copy-install edits are lost — that is why promotion from a copy install fails closed. |
| Deleting the flat lane breaks a consumer with an allowlisted flat skill | Low | `example-skill` was the only flat entry in the allowlist, and it is deleted in the same change. |
| The adapted text omits an explicit `fork_turns: "none"` for discovered or clean room | High | `fork_turns` defaults to `all`, so omission inherits the conversation — the inverse of Claude's default. Under clean room that silently breaks a restriction the owner stated in their own words. Manual clean-room invocation on Codex is the check; the invariant above is the rule. |
| A `harness-block` has no registered Codex text, so Claude's wording ships to Codex | Med | Accepted, silently, per the owner's no-new-failure-conditions call. Manual invocation on Codex is the detector. Keys make this the only remaining miss mode — rewording no longer breaks a substitution. |
| The adapter rewrites a string that was already correct on both runtimes | Low | `SKILL.md:197` and `:206` are the known cases, and both sit outside any `harness-block`. Per-lane lists (D8) keep the command lane's rules off skill bodies. |
| The allowlist entry is omitted | Med | Fails silently — build exits 0, skill absent from `dist/`. Guarded by the manifest assertion in Validation. |
| A Claude-side break introduced by the phrase edits | Med | Most edited lines live in the file Claude reads live through the install symlink, so this item is editing a working capability. Fixed here, not handed back to Item 3 (spec, Non-Goals). Manual `/_my_mental_model` invocation is the check. |
| The Claude runtime validates frontmatter `name` against the directory more strictly than assumed | Low | The pack always sets them equal (`show-me`, `_my_mental_model`). Only the Codex-side name diverges, and that name is generated. |

---

## Integration Strategy

This is the epic's last item, so it inherits a working skill rather than enabling one. On Claude the
only intended change is the removal of the dead `example-skill.md`; the capability itself has to
behave exactly as it did before. On Codex, `my-mental-model` gains a working implementation for the
first time since epic Item 2 deleted the v1 command — which is why the epic forbids rebuilding
`dist/` before this item: doing so earlier would strip the Codex side with nothing to replace it.
Every later command→skill migration under ADR 0009 rides the same lane.

Sequencing inside the item: build lane first (the real skill is already there to copy), then the
adapter pass over the tree, then the install, then the `example-skill.md` deletion and the sweep,
then the v1 wiring cleanup, then the tests. Rebuild `dist/` and refresh both global installs at the
end, as the repo's convention requires — and this is the rebuild the epic has been deferring.

---

## Validation Approach

**Automated** — `scripts/test_codex_orchestrator_pack.sh`:
- `dist/codex/skills/my-mental-model/` exists — not `_my_mental_model/` — and contains
  `design_synthesis.md`, `visualize.md`, and `feedback/` with both bodies. This is the mapping proof
  (D2) and the nesting proof (D1), against the real skill.
- The entry point carries generated frontmatter with `name: my-mental-model`.
- No `harness-block` marker survives into `dist/` for an allowlisted skill — every key was
  substituted. This is the adapter-ran proof, and it is exact rather than a spot check.
- The adapter ran over a **sibling**, not only the entry point: a known translated string in
  `design_synthesis.md` differs between pack source and dist.
- `dist/codex/skills/my-mental-model/SKILL.md` contains `fork_turns` and contains no
  `subagent_type`.
- `dist/codex/manifest.json`'s `skills` array is exactly `["my-mental-model", "show-me"]` — the guard
  against a silently omitted allowlist entry.
- A flat `.md` dropped in `claude-pack/skills/` yields no skill directory (D6).
- Temp-`HOME` install places every file of the skill under `~/.agents/skills/`.
- Convergence: install twice; the second run updates rather than skipping, and a file removed from
  dist between runs disappears from the target.
- The existing `-g 'SKILL.md'` neutrality scan: keep it with a narrowed job (did the adapter run),
  widen it, or delete it. Spec Open Question. Note its regex matches `subagent_type=` with an equals
  sign while the skill writes the colon form, so exactly one current spot would trip it.

**Manual** — the only behavioral verification there is (owner decision: no automated behavioral
tests):
- `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`, then run `my-mental-model` on
  Codex end to end: it locates its own directory, reads both instruction siblings and both `feedback/`
  bodies, spawns the synthesis agent with carried context, resumes that agent for the render, and
  writes its run artifacts into the project rather than into the installed skill directory.
- A clean-room run on Codex, confirming the synthesis agent did **not** inherit the conversation.
  This is the `fork_turns` default trap; nothing else catches it.
- `./scripts/setup-global.sh`, fresh Claude session, run `/_my_mental_model` and confirm the
  capability still does what it did before this item.
- Confirm `~/.claude/skills/example-skill.md` is gone after re-running `setup-global.sh` (D4).

**Existing suite**: docs, pipeline-sync, adr, global-setup, codex-orchestrator-pack.

---

## Next-Stage Handoff

**Fixed:** the directory-as-unit concept, D1's copy-then-transform order, D2, D3, D4, D6, D7, D8,
D9, D10, and the invariants above. D5 is rejected — do not reintroduce build-root parameterization without a new
reason.

**Nothing owed by design.** The five questions revision 2 left open were answered by the owner on
2026-08-21 and are recorded as D1's file-type rule, D8, D9, D10, and the D3 confirmation.

**Open for the plan:** whether the install mirror is `rsync`-style bash or delete-then-copy; where
the new assertions sit in the test file; the order of the v1 wiring deletions.

**No probes outstanding.** All three ran on 2026-08-20 and are Required Reading.

**Resolved since authoring** (product-lens spec-F2, spec-F3): the epic now names the
`_my_mental_model` allowlist entry in this item's In Scope, and its High risk on directory-skill
slash resolution points at epic Item 3. No owner action outstanding.

---

**Next Step:** After approval → `/_my_plan`
