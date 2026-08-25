# Implementation Plan: Directory-Skill Codex Adapter

**Status:** In Progress
**Created:** 2026-08-21
**Last Updated:** 2026-08-21
**Branch:** anchor-on-the-point
**Epic:** MENTAL-ALIGN-V2, Item 5

## Source Documents

- **Spec:** `.project/active/directory-skill-build-pattern/spec.md` (revision 4)
- **Design:** `.project/active/directory-skill-build-pattern/design.md` (revision 3) ← component
  detail, decisions D1-D10, invariants, risks
- **Probes:** `spike-findings.md` (packaging), `cwd-spike-findings.md` (working directory),
  `fork-spike-findings.md` (context-inheriting spawn), `.project/active/codex-resume-spike/spike-findings.md`
  (resume)
- **Dictionary input:** `.project/active/render-switch-feedback/harness-phrases.md`
- **Existing Codex spawn guidance:** `codex-overrides/rules/collaboration.md` — the Codex text
  written in Phase 2 matches this file rather than inventing phrasing, because it already ships to
  Codex inside `AGENTS.md`

## The Point

A pack capability is a skill directory: an entry point plus the instruction and feedback files it
reads, shipped and versioned as one unit. Claude installs that with a single symlink to the pack
directory, so it works there. Codex ships one file out of it — both the build and the install walk
`find … -mindepth 2 -maxdepth 2 -name 'SKILL.md'`, so siblings are dropped and a nested `feedback/`
directory is never discovered. Codex ends up with an entry point that references files nobody
copied, and neither side reports an error.

Why that matters beyond plumbing: the mental-alignment skill exists because the owner cannot read a
system's whole artifact chain to recover its mental model. Its entire repair for the failed v1 is
that the thinking instructions and the rendering instructions live in **separate files**, so an
agent handed the thinking job cannot see the rendering job and race to it. That repair only works if
sibling files actually ship. Today they don't ship to Codex, and the failure is silent and
one-sided.

Second half of the point: the skill can't be written to dodge this. It has to say where its own
directory is and how to spawn an agent that inherits the conversation, and those differ per harness.
ADR 0010 required skill bodies to be runtime-neutral, which is unmeetable for a real skill, so the
owner reversed it — ADR 0011 sends skill directories through the same Codex adapter as commands,
applied to every file. This item builds that adapter, and every future command→skill migration rides
it.

## Implementation Strategy

**Phasing Rationale**

The mechanism is proven — three probes on 2026-08-20 answered every Codex-side unknown, so nothing
here is a bet on runtime behavior. What is still unproven is the *content*: whether the skill's
harness differences separate cleanly into delimited blocks, and whether the whole capability actually
runs on Codex from a copy-installed directory. So the phases move payload first, content second,
behavior third, cleanup last.

**Critical Path**

Build produces a complete tree under the derived name → the skill's harness spans are marked and
substituted → the install mirrors it and Codex runs it → leftovers.

**First Proof Point**

`dist/codex/skills/my-mental-model/feedback/synthesis.md` exists after a build. That one path proves
the derived name (D2), the recursive copy (D1), and the allowlist key all at once, and it is the
thing that has never worked.

**Overall Validation Approach**

- Each phase starts by writing its assertions into `scripts/test_codex_orchestrator_pack.sh`.
- Phases 1 and 2 are automated-provable. Phase 3 is the first behavioral proof and is manual by
  owner decision (no automated behavioral tests of the skill on either runtime).
- The full suite runs at the end of Phase 4: docs, pipeline-sync, adr, global-setup,
  codex-orchestrator-pack.

---

## Phase 1: The build produces a complete, correctly named tree

### Goal

`dist/codex/skills/my-mental-model/` contains every file of the pack skill directory at the same
relative paths, `feedback/` included, with `name: my-mental-model` in the generated frontmatter.

### Assumption Under Test

A tree copy plus a derived name is all the build needs — no file-at-a-time enumeration survives
anywhere in the lane.

### Test Stencil (Write This First)

```bash
# scripts/test_codex_orchestrator_pack.sh
SKILL_DIST="$ROOT/dist/codex/skills/my-mental-model"

[ -d "$SKILL_DIST" ] || fail "derived skill dir missing: $SKILL_DIST"
[ -d "$ROOT/dist/codex/skills/_my_mental_model" ] && fail "pack-side name leaked into dist"
for f in SKILL.md design_synthesis.md visualize.md feedback/synthesis.md feedback/html.md; do
  [ -f "$SKILL_DIST/$f" ] || fail "sibling missing from dist: $f"
done
contains "$SKILL_DIST/SKILL.md" 'name: my-mental-model'
contains "$MANIFEST" '"my-mental-model"'
does_not_contain "$MANIFEST" 'example-skill'
pass "directory skill tree and derived name"
```

### Changes Required

**See `design.md` for:** the lane's shape → `design.md#architecture`; D1 (copy then transform), D2
(name derivation), D6 (flat lane), D7 (`example-skill` deletion), D8 (per-lane substitutions) →
`design.md#key-decisions`; the gotchas → `design.md#implementation-notes`.

**Specific file changes:**

#### 1. Test assertions
**File:** `scripts/test_codex_orchestrator_pack.sh`
- [x] Add the stencil above near the existing skill assertions (`:336-343`)
- [x] Fix the manifest expectation to `["my-mental-model", "show-me"]`
- [x] Remove or repoint anything asserting on `example-skill`

#### 2. Build lane
**File:** `scripts/build-codex-pack.sh`
- [x] Directory-skill lane (`:366-395`): derive the Codex name from the **pack directory** name via
      `strip_command_prefix` + `to_hyphen_name`; stop reading frontmatter for it (D2 — this is new
      code, not a no-op; `:375` reads frontmatter and `:386` writes it today)
- [x] Replace the `find`-one-file walk with `cp -R` of the pack directory, then transform in place.
      Order matters: copy first, transform second (`design.md#implementation-notes`)
- [x] Add `apply_common_substitutions` and move the entries shared by all lanes into it; pipe the
      command and rule lanes through it (D8)
- [x] Add `sanitize_skill_body_for_codex` — **without** the `/_my_x` slash-command rule, which
      corrupts the real path at `_my_mental_model/SKILL.md:265` (D8)
- [x] Transform `.md` files; copy every other file byte-for-byte (D1)
- [x] Delete the flat native-skill lane (`:338-365`) (D6)

#### 3. Allowlist
**File:** `codex-overrides/config.sh:58`
- [x] Add `"_my_mental_model"` — the literal **pack-side** name; the check at
      `build-codex-pack.sh:370` is keyed on the source directory and a miss excludes the skill with
      no error
- [x] Remove `"example-skill"`

#### 4. Deletion
**File:** `claude-pack/skills/example-skill.md`
- [x] Delete (D7)

### Validation

**Automated:**
- [x] `./scripts/build-codex-pack.sh` → exits 0
- [x] `./scripts/test_codex_orchestrator_pack.sh` → new assertions pass
- [x] `./scripts/test_docs.sh` → passes (catalog rows)

**Manual:**
- [x] `find dist/codex/skills/my-mental-model -type f` → five files, `feedback/` nested
- [x] `grep -c 'name:' dist/codex/skills/my-mental-model/SKILL.md` → one frontmatter name, derived

**What We Know Works After This Phase**

The payload reaches `dist/` complete and under the name Codex will register. The flat lane is gone
and the manifest is final, so later phases assert against a stable expectation.

---

## Phase 2: The skill's harness differences are marked and substituted

### Goal

Every harness-specific span in the pack skill sits inside a keyed `harness-block` marker; the Claude
prose keeps the agent handle it was given rather than rebuilding it from a slug; the skill lane
substitutes each key with Codex text.

### Assumption Under Test

**The harness-specific content is block-shaped.** Some of it may not be — `SKILL.md:84` reads "read
the synthesis file it wrote using the `Read` tool (not `cat` via Bash)", where the harness detail is
mid-sentence inside a behavior instruction. If more than a couple of spots look like that,
block-only delimiters are insufficient, and the honest answers are a plain vocabulary substitution
for those spots or a return to D9's shape. Surface it rather than quietly mixing mechanisms.

### Test Stencil (Write This First)

```bash
# No marker may survive into dist — this is the adapter-ran proof, exact rather than a spot check
if grep -rn 'harness-block' "$SKILL_DIST"; then
  fail "unsubstituted harness-block reached dist"
fi
contains "$SKILL_DIST/SKILL.md" 'fork_turns'
does_not_contain "$SKILL_DIST/SKILL.md" 'subagent_type'
does_not_contain "$SKILL_DIST/SKILL.md" 'SendMessage'
# the adapter reached a sibling, not only the entry point
contains "$SKILL_DIST/design_synthesis.md" 'fork_turns'
pass "harness blocks substituted across the tree"
```

### Changes Required

**See `design.md` for:** D9 (keyed delimiters and their two accepted costs), D10 (handle retention),
the `fork_turns` invariant → `design.md#required-invariants`; the two phrases that must survive
untouched → `design.md#implementation-notes`.

**Specific file changes:**

#### 1. Re-derive the inventory first
- [x] Read the five pack skill files and list every harness-specific span **as literal strings**.
      The lists in `spec.md` and `harness-phrases.md` are inputs, not the inventory — both went
      stale when Item 4 landed. This is a spec success criterion, not bookkeeping

#### 2. Mark and restructure the pack skill
**File:** `claude-pack/skills/_my_mental_model/SKILL.md`
- [x] Wrap each harness-specific span in `<!-- harness-block: <key> --> … <!-- /harness-block -->`
- [x] Change the spawn/dispatch prose to record the handle returned at spawn and address it by that
      (`:81`, `:115`, `:170`) (D10)
- [x] Leave `:197` and `:206` alone — already runtime-aware and true on both harnesses
**File:** `claude-pack/skills/_my_mental_model/design_synthesis.md`
- [x] Mark the one spot if the re-derived inventory finds it needs marking (`:30` reads on both today)

#### 3. Register the Codex text
**File:** `scripts/build-codex-pack.sh`
- [x] In `sanitize_skill_body_for_codex`, substitute each key with its Codex text
- [x] Carried policy → `spawn_agent` with `fork_turns: "all"`; discovered and clean room →
      `fork_turns: "none"` **stated explicitly**, because the Codex default is `"all"` and omission
      silently inherits the conversation (invariant; risk table)
- [x] Resumed render → `followup_task` against the returned identity
- [x] Phrase all of it consistently with `codex-overrides/rules/collaboration.md`, which already
      ships to Codex in `AGENTS.md`. Do not combine `fork_turns: "all"` with `agent_type`, `model`,
      or `reasoning_effort` — that file forbids it; the skill requests none of them today

### Validation

**Automated:**
- [x] `./scripts/build-codex-pack.sh && ./scripts/test_codex_orchestrator_pack.sh` → passes
- [x] Decide the fate of the dist neutrality scan (`test_codex_orchestrator_pack.sh:336-338`): keep
      it with the narrowed job of confirming the adapter ran, widen it, or delete it. Note its regex
      matches `subagent_type=` with an equals sign while the skill writes the colon form

**Manual:**
- [x] `./scripts/setup-global.sh`, fresh Claude session, run `/_my_mental_model` end to end →
      behaves as it did before this item. **This is the gate for the phase.** Claude reads the pack
      file live through the install symlink, so an error here is live, not staged
- [x] Confirm the `harness-block` comments do not confuse the Claude coordinator

**What We Know Works After This Phase**

The Codex entry point and siblings say what Codex does, the Claude capability still works, and no
marker escapes the build.

---

## Phase 3: Install mirror, then the first real Codex run

### Goal

`setup-codex.sh` mirrors the dist skill directory onto `~/.agents/skills/<name>/` and converges on
re-run; the capability then runs on Codex end to end.

### Assumption Under Test

Codex runs the whole capability from a copy-installed directory: locates itself from the supplied
`SKILL.md` path, reads all four instruction files, spawns with carried context, resumes that agent
for the render, and writes its artifacts into the project rather than into the installed skill
directory.

### Test Stencil (Write This First)

```bash
# temp-HOME install, then a second run for convergence
tmp_home="$(mktemp -d)"
HOME="$tmp_home" bash "$ROOT/scripts/setup-codex.sh" --copy >/dev/null
[ -f "$tmp_home/.agents/skills/my-mental-model/feedback/html.md" ] || fail "nested sibling not installed"

touch "$tmp_home/.agents/skills/my-mental-model/stale.md"
HOME="$tmp_home" bash "$ROOT/scripts/setup-codex.sh" --copy >/dev/null
[ -f "$tmp_home/.agents/skills/my-mental-model/stale.md" ] && fail "mirror did not remove a file absent from dist"
pass "install mirror converges"
```

### Changes Required

**See `design.md` for:** D3 (the mirror and its directory-level managed check, plus why the
whole-directory symlink stays rejected) → `design.md#key-decisions`; the guard's current behavior →
`design.md#research-findings`.

**Specific file changes:**

**File:** `scripts/setup-codex.sh`
- [x] Replace the `SKILL.md`-only skills walk (`:263-267`) with a directory mirror: add, overwrite,
      and remove files no longer in dist
- [x] Ask the **entry point** whether the directory is managed, once per directory: absent or
      carrying `Generated from` → ours, mirror it; present without the marker → skip the whole
      directory and print the `--force` hint. This is what makes verbatim-copied siblings
      re-installable; today `is_managed_file` (`:19-22`) classifies them user-authored from the
      second install onward
- [x] Leave `install_path` alone for every non-skill asset

### Validation

**Automated:**
- [x] `./scripts/test_codex_orchestrator_pack.sh` → mirror and convergence assertions pass
- [x] `./scripts/setup-codex.sh --dry-run` → reports the skill directory, no surprises

**Manual:**
- [x] `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`
- [ ] Run `my-mental-model` on Codex end to end. Confirm: it reads `design_synthesis.md`,
      `visualize.md`, and both `feedback/` bodies; the synthesis agent receives the conversation
      under carried policy; the render resumes that same agent; run artifacts land in
      `.project/mental-alignment/runs/` and **not** in `~/.agents/skills/my-mental-model/`
- [ ] Run it again under **clean room** and confirm the synthesis agent did *not* inherit the
      conversation. Nothing else catches an omitted `fork_turns: "none"`
- [ ] Confirm the comparison reports the missing per-agent token count honestly rather than
      estimating it (epic Item 1 found no supported source)

**What We Know Works After This Phase**

The capability works on Codex, which is the item's whole purpose, and re-installing converges.

---

## Phase 4: Leftovers and the rebuild

### Goal

No v1 surface remains, no script or doc states something false about Codex and symlinks, and both
installs are refreshed from a clean build.

### Assumption Under Test

None. This is cleanup, sequenced last because none of it gates the mechanism.

### Test Stencil (Write This First)

```bash
does_not_contain "$ROOT/scripts/build-codex-pack.sh" 'mental-model-builder'
does_not_contain "$ROOT/README.md" 'mental_model'   # stale catalog row
grep -rn 'Codex reads copies, not symlinks' "$ROOT" && fail "false symlink claim still present"
pass "v1 surfaces retired"
```

### Changes Required

**Specific file changes:**

- [x] `scripts/build-codex-pack.sh:138` — v1 path rewrite removed
- [x] `scripts/build-codex-pack.sh:426` — v1 shared-spec copy removed
- [x] `codex-overrides/config.sh:37` — v1 description override removed
- [x] `README.md:131` — stale command-catalog row removed (nothing catches this any more;
      `test_docs.sh`'s completeness check stopped requiring it when the command file was deleted)
- [x] `scripts/build-codex-pack.sh:521` and `CLAUDE.md:53` — correct "Codex reads copies, not
      symlinks"; Codex loads a symlinked skill *directory* and refuses only a symlinked `SKILL.md`
- [x] `scripts/uninstall-project.sh:108-114` — drop `example-skill.md`, add the skill directory
- [x] `scripts/setup-global.sh` — add the dead-managed-symlink sweep (D4), which is what actually
      removes the now-dangling `~/.claude/skills/example-skill.md`
- [x] Re-point ADR 0010 citations in documents that still steer future work. Leave them in
      `.project/adr/INDEX.md`, 0010 and 0011 themselves, `spike-findings.md`, and every
      `product-lens.md` block — see the spec's `[OWNER]` item on supersession for the scope rule
- [x] `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy && ./scripts/setup-global.sh`

### Validation

**Automated:**
- [x] Full suite: `test_docs.sh`, `test_pipeline_sync.sh`, `test_adr.sh`, `test_global_setup.sh`,
      `test_codex_orchestrator_pack.sh` → all pass
- [x] `git diff --check` → clean

**Manual:**
- [x] `~/.claude/skills/example-skill.md` is gone after `setup-global.sh`
- [x] `grep -rn '_my_mental_model' dist/` → nothing but provenance headers

**What We Know Works After This Phase**

The item is shippable: both runtimes install from one pack, and nothing in the tree references a v1
surface or asserts something false about Codex.

---

## Environment Setup

**See CLAUDE.md.** Build and install always run in order:

```bash
./scripts/build-codex-pack.sh     # claude-pack/ → dist/codex/
./scripts/setup-codex.sh --copy   # dist/codex/ → ~/.agents/skills/ and ~/.codex/
./scripts/setup-global.sh         # claude-pack/ → ~/.claude/ symlinks
```

Tests are `scripts/test_*.sh`, run directly.

---

## Risk Management

**See `design.md#potential-risks` for the full table.**

**Phase-specific mitigations:**

- **Phase 1** — the name derivation is new code and a missing allowlist entry fails silently
  (build exits 0, skill absent). The manifest assertion is the guard.
- **Phase 2** — this phase edits a capability in active use, and Claude reads the pack file live
  through the install symlink, so a mistake is immediate rather than staged. The manual
  `/_my_mental_model` run is the gate, not the suite. A `harness-block` with no registered Codex
  text ships Claude's wording silently; accepted per the owner's no-new-failure-conditions call,
  detected by running the skill on Codex in Phase 3.
- **Phase 3** — the directory mirror could delete a file someone hand-added to an installed skill.
  D3's rule holds: an entry point without the marker skips the whole directory.
- **Phase 4** — the ADR citation re-pointing has a scope rule. Editing an append-only ledger block
  breaks the property that makes it trustworthy.

**Intermediate state, Phases 1-4:** `~/.claude/skills/example-skill.md` is a dangling symlink until
Phase 4's sweep. Inert per probe A10 — absent from the skill listing, no warning, rest of the set
unaffected.

---

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
**Completed:** 2026-08-21

**Actual Changes:**
- `scripts/build-codex-pack.sh` — split the substitution dictionary per D8:
  `apply_common_substitutions` (stdin→stdout: the two `~/.claude/scripts/*` path rewrites, the
  Claude agent-tool vocabulary, `$ARGUMENTS`); `sanitize_command_body_for_skill` now pipes through
  it and keeps the ponytail path rewrite and the `/_my_x` slash rule as its own lane pass;
  `sanitize_rule_body_for_codex` pipes through it too. Added `sanitize_skill_body_for_codex` (no
  slash rule) and `adapt_skill_file_in_place`.
- `scripts/build-codex-pack.sh` — added `codex_name_for_skill_dir`, a pure function of the pack
  directory name (D2). Rewrote the directory-skill lane to iterate directories, `cp -R` the tree,
  adapt every `.md` in place, then regenerate the entry point's frontmatter from the copy. Deleted
  the flat native-skill lane (D6).
- `codex-overrides/config.sh` — `NATIVE_SKILL_ALLOWLIST` is now `_my_mental_model` + `show-me`,
  with a comment recording that it is keyed pack-side.
- `claude-pack/skills/example-skill.md` — deleted (D7).
- `scripts/test_codex_orchestrator_pack.sh` — new `SKILL_DIST` var and a directory-skill assertion
  block: tree completeness including `feedback/`, no pack-side name in dist, derived frontmatter
  name, exact manifest array via `jq`, no `example-skill`, and a source assertion that the flat
  lane's walk is gone.

**Issues Encountered:**
- **The plan's stencil would have exited the script under `set -e`.** `[ -d … ] && fail …` returns
  1 when the test is false, which aborts a `set -euo pipefail` script. Written as an `if` block.
- **`strip_command_prefix` + `to_hyphen_name` alone derive `mental-model`, not `my-mental-model`.**
  The `my-` prefix comes from `COMMAND_SKILL_PREFIX`, and it has to, because that is the constant
  the command lane uses when it rewrites `/_my_mental_model` mentions. `show-me` must not get the
  prefix. Both cases live in `codex_name_for_skill_dir`.
- **The dist neutrality scan has never run.** `test_codex_orchestrator_pack.sh:353` calls `rg`,
  which is not on `PATH` inside the script; the run prints `rg: command not found` and the `if` is
  simply false, so `fail` is unreachable. Two spots in the untranslated skill body
  (`dist/…/my-mental-model/SKILL.md:80`, `:174`) match its regex on `` `Agent` tool `` — so the
  scan would have tripped had it executed, which is stronger than the spec's note about the
  `subagent_type=` equals form. Carried into Phase 2, which owns the decision.
- The manifest assertion is exact (`jq -e '.included.skills == […]'`) rather than a substring
  check, per the design's guard against a silently omitted allowlist entry.

**Deviations:**
- The flat-lane deletion (D6) is proved by a source assertion that the `-maxdepth 1 -type f` walk
  is gone, not by dropping a flat `.md` into the pack and rebuilding. The behavioral version would
  have to mutate `claude-pack/` mid-test.
- Staged temp files are written beside their target (`<file>.codex-adapt`,
  `SKILL.md.codex-frontmatter`) rather than via `mktemp`, so the adapted files keep the umask mode
  the rest of `dist/` has. `set -e` aborts the build if a stage fails, and `dist/` is wiped at the
  start of every build.

**Validation:**
- `./scripts/build-codex-pack.sh` → exit 0, "Native skills: 2 included, 0 excluded".
- `dist/codex/skills/my-mental-model/` holds all five files with `feedback/` nested; no
  `_my_mental_model/` directory in dist; one `^name:` line, reading `my-mental-model`.
- `dist/codex/manifest.json` `included.skills` is exactly `["my-mental-model", "show-me"]`.
- `git diff --stat dist/` shows no command skill and no `AGENTS.md` change, so the sanitizer split
  is behavior-preserving on the two lanes that already existed.
- Suites: `test_codex_orchestrator_pack.sh`, `test_docs.sh`, `test_pipeline_sync.sh`,
  `test_adr.sh`, `test_global_setup.sh` → all pass.

### Phase 2 Completion
**Completed:** 2026-08-21 (automated validation; the two manual gates are the owner's)

**The re-derived inventory — 6 spans marked, 6 spots deliberately left alone.**
Derived from the files, as literal strings, not from `spec.md` or `harness-phrases.md`.

Marked:

| key | file:lines (pre-edit) | the harness-specific string |
|---|---|---|
| `skill-base-directory` | `SKILL.md:14` | "The skill preamble gives this skill's base directory." |
| `synthesis-spawn` | `SKILL.md:75-80` | "use `subagent_type: \"fork\"`" / "the `Agent` tool with no `subagent_type` (or `subagent_type: \"general-purpose\"`)" / "Give the agent a descriptive name like `synthesis-{slug}`" |
| `read-synthesis-file` | `SKILL.md:84-85` | "using the `Read` tool (not `cat` via Bash — that clutters the terminal)" |
| `correction-dispatch` | `SKILL.md:115` | "by name (`synthesis-{slug}`) using `SendMessage`" |
| `render-dispatch` | `SKILL.md:170-172` | "`SendMessage` to `synthesis-{slug}`" / "the `Agent` tool with no `subagent_type` … so never `fork`. Name it `render-{slug}-fresh`" |
| `carried-fork` | `design_synthesis.md:30` | "you are a fork of the conversation" |

Left alone, with the reason:

- `SKILL.md:26`, `:34` — "Use a fork so that reasoning arrives without re-derivation", "a fork with
  a read-nothing-new instruction". These describe the *policy*, and Codex's `fork_turns` is
  literally a fork of turns. True on both.
- `SKILL.md:153`, `:256`, `:260` — downstream references to "the base directory from Step 1". Step 1
  resolves it per harness; every later mention is neutral.
- `SKILL.md:183` — "a named agent's turn output does not reliably reach you". `harness-phrases.md`
  records that Item 1 found the same on Codex, and Codex's `task_name` makes "named agent" accurate
  there too. Substituting it would trade a true claim for a Claude-flavored one.
- `SKILL.md:197`, `:206` — the token-reporting sentences. Already runtime-aware; the design forbids
  touching them.
- `SKILL.md:265` — `claude-pack/skills/_my_mental_model` is the authored-source path and is correct
  on both. Protected by the skill lane omitting the command lane's `/_my_x` rule (D8), which is the
  thing that would corrupt it.
- `visualize.md`, `feedback/synthesis.md`, `feedback/html.md` — zero hits, as `harness-phrases.md`
  predicted. Confirmed by sweep, not assumed.

**On the assumption under test: the content is block-shaped.** Only one span was mid-sentence —
`SKILL.md:84`, the `Read`-not-`cat` parenthetical. Rather than let a block swallow two neutral
sentences, the pack prose was split so the parenthetical became its own line. Three blocks were
shrunk this way (`skill-base-directory`, `read-synthesis-file`, `correction-dispatch`) on one
principle: **a neutral sentence inside a block has to be duplicated in the Codex text, and the two
copies are then kept in step by nobody** — the failure mode D8 rejected an external table over. So
blocks are sufficient, and no second mechanism was mixed in.

**Actual Changes:**
- `claude-pack/skills/_my_mental_model/SKILL.md` — five `harness-block` spans; the D10 handle change
  inside three of them (record the handle the spawn returns at Step 3; address that handle at Step 5
  and Step 6 instead of rebuilding `synthesis-{slug}`). Prose split at Steps 1, 4 and 5 so each
  block holds only harness-specific text.
- `claude-pack/skills/_my_mental_model/design_synthesis.md` — one span, `carried-fork`.
- `scripts/build-codex-pack.sh` — `CODEX_SKILL_HARNESS_BLOCKS`, a keyed table of Codex text written
  as quoted heredocs (no escaping layer, so the prose stays editable); `substitute_harness_blocks`,
  a line-oriented pass that replaces a span by key and always drops the markers;
  `sanitize_skill_body_for_codex` now runs `apply_common_substitutions | substitute_harness_blocks`.
- `scripts/test_codex_orchestrator_pack.sh` — the Phase 2 stencil, plus two additions: an explicit
  `fork_turns: "none"` assertion (the invariant nothing else catches at build time) and an assertion
  that `claude-pack/skills/_my_mental_model` survives intact in dist.

**Issues Encountered:**
- **The `followup_task` name is inherited, not captured.** `fork-spike/evidence/collaboration-surface.txt`
  documents `spawn_agent` only; the resume spike describes "the follow-up-task mechanism" without
  recording a literal tool name, and `followup_task` comes from `design.md` D10 and this plan. The
  Codex text therefore phrases it as "send a follow-up task (`followup_task`)", so the instruction
  still reads correctly if the surface names it differently. **Phase 3's Codex run is what verifies
  the literal name.**
- **The dist neutrality scan never ran, and now does.** Decision: keep it with the narrowed job
  (confirm the adapter ran), and three fixes — `grep -rnE` instead of `rg`, which is not on `PATH`
  inside the script; `subagent_type` bare instead of `subagent_type=`, so the colon form is caught;
  scope widened from `-g 'SKILL.md'` to every `.md` under dist skills, because ADR 0011 makes all of
  them adapter output. Verified no false positives across the 29 command skills before widening.
- **Ordering choice inside the adapter:** the shared pass runs first, then the block substitution, so
  the registered Codex text ships exactly as authored rather than being re-scanned by the Claude
  dictionary.
- Two wording passes on the Codex text after reading it in place: `skill-base-directory` was
  reworded so the following neutral sentence ("Record the absolute path") has an unambiguous
  referent, and `carried-fork` was reworded to stop repeating "in your context".

**Deviations:**
- `read-synthesis-file` is registered as the **empty string**, which deletes the span. Codex reads
  files through its shell, so there is no quieter tool to prefer and no honest Codex sentence to
  write. `substitute_harness_blocks` distinguishes registered-empty (delete) from unregistered
  (leave the Claude wording, silently, per D9).
- Blocks live in a bash associative array of quoted heredocs rather than inline perl literals. The
  Codex text is prose with apostrophes, backticks and double quotes in it; a quoted heredoc needs no
  escaping at all, where a perl `q{}` or double-quoted literal would. This is still one lane
  function's dictionary, inline in the build script — not the external table D8 rejected.

**Validation:**
- `./scripts/build-codex-pack.sh && ./scripts/test_codex_orchestrator_pack.sh` → pass, including the
  new `harness blocks substituted across the tree` block.
- No `harness-block` marker anywhere in `dist/`; no `subagent_type`, `SendMessage`, `` `Agent` tool ``
  or `` `Read` tool `` anywhere under `dist/codex/skills/my-mental-model/`.
- The four substituted regions read coherently in place in dist, checked by eye.
- Suites: codex-orchestrator-pack, docs, pipeline-sync, adr, global-setup → all pass.
- **Not yet done (owner's gates):** the manual `/_my_mental_model` run on Claude, and confirming the
  `harness-block` comments do not confuse the Claude coordinator. `~/.claude/skills/_my_mental_model`
  is a live symlink to the pack directory, so the edited file is already what Claude reads.

### Phase 3 Completion
**Completed:** 2026-08-21 (install mirror + automated validation; the Codex runs are the owner's)

**Actual Changes:**
- `scripts/setup-codex.sh` — four new functions and a rewritten skills walk:
  - `skill_dir_is_managed` — the directory-level check (D3). The entry point answers for the whole
    tree: absent, carrying `Generated from`, or still a symlink into `dist/codex/`. The symlink case
    also covers a *dangling* symlink from an older symlink-mode install, which `is_managed_file`
    would otherwise classify user-authored forever.
  - `install_skill_file` — copies one file with no per-file guard, because the directory decision is
    already made. Reports `Already current` when the bytes match, so a re-install stays quiet and
    the counters keep meaning something.
  - `remove_stale_skill_file` — removes a target file that dist no longer has.
  - `mirror_skill_dir` — the add/overwrite/remove pass over one directory.
  - The walk is now `find "$DIST_DIR/skills" -mindepth 1 -maxdepth 1 -type d`. `install_path` is
    untouched and still handles agents, scripts, hooks, and `AGENTS.md`.
- `scripts/test_codex_orchestrator_pack.sh` — an `install mirror converges` block covering four
  things: the nested and flat siblings install; a hand-edited sibling is restored on re-install
  (**this is the actual bug D3 fixes** and the plan's stencil did not test it); a file absent from
  dist is removed; and an entry point without our marker leaves its whole directory alone,
  hand-added file included.

**Issues Encountered:**
- **The plan's stencil would have exited the script under `set -e`,** same shape as Phase 1:
  `[ -f … ] && fail …` returns 1 when the file is absent. Written as `if` blocks.
- **`~/.agents/skills/example-skill/` is orphaned and nothing removes it.** D4 gives `setup-global.sh`
  a sweep for dead managed symlinks on the Claude side, but there is no equivalent for a Codex skill
  *directory* whose dist source is gone — the mirror only visits directories that still exist in
  dist. So Codex will keep offering `example-skill` from the stale copy installed before this item.
  Left for Phase 4 (Leftovers) rather than fixed here; it needs its own decision, because removing
  an installed directory outright is a bigger hammer than removing a dangling symlink.
- Empty directories are not pruned when their last file is removed. The invariant names files, and
  no pack skill has ever dropped a subdirectory, so a `-delete` sweep would be defensive code for a
  case that does not exist.

**Deviations:**
- Skills are always copied, never symlinked, regardless of `--copy`. That matches the old behavior
  (`install_path … "copy"`) and the constraint behind it: Codex silently refuses to register a skill
  whose `SKILL.md` is a symlink.

**Validation:**
- `./scripts/test_codex_orchestrator_pack.sh` → `install mirror converges` passes, including the
  sibling-update and unmanaged-directory cases.
- `./scripts/setup-codex.sh --copy` → installed all five files, `feedback/` nested:
  `Summary: 5 installed, 35 skipped, 0 removed`. **This is the first time the sibling files have
  ever reached a Codex install.**
- Re-run `--dry-run` → all five report `Already current`, so the mirror converges.
- The installed entry point carries `name: my-mental-model` and the `Generated from` marker; no
  `harness-block` marker in any installed file.
- Suites: codex-orchestrator-pack, docs, pipeline-sync, adr, global-setup → all pass.
- **Not yet done (owner's gates):** the end-to-end `my-mental-model` run on Codex, and the clean-room
  run that checks `fork_turns: "none"` actually kept the conversation out. Nothing automated catches
  either.

### Phase 4 Completion
**Completed:** 2026-08-24

**Actual Changes:**
- `scripts/build-codex-pack.sh` — dropped the `mental-model-builder.md` path rewrite from
  `apply_common_substitutions` and from the shared-spec copy loop (the loop's `[ -f ]` guard had
  already made it a no-op since Item 2 deleted the source, but the name was still there to mislead).
  Corrected the closing NOTE: skills install as copies because Codex silently refuses a skill whose
  `SKILL.md` is a symlink, not because Codex cannot read symlinks at all.
- `CLAUDE.md` — same correction, and the sentence now also states the Phase 3 behavior: `--copy`
  governs agents, scripts and hooks; skills are always copied either way.
- `codex-overrides/config.sh` — removed the v1 `["mental-model"]` command description override.
- `README.md` — removed the `/_my_mental_model` command-catalog row.
- `scripts/uninstall-project.sh` — the flat-skill-file loop is gone (no flat skills exist any more);
  the directory loop now covers `_my_mental_model` and `show-me`.
- `scripts/setup-global.sh` — `sweep_dead_symlinks` per D4, run after the symlink passes.
- `.project/backlog/epic_mental_alignment_skill.md:176` and
  `.project/active/coordinator-synthesis/spec.md:154` — the only two documents that cited ADR 0010 as
  **live guidance**, per the spec-review's scope rule.
- `scripts/test_codex_orchestrator_pack.sh` — a `v1 surfaces retired` block.

**On the ADR 0010 re-pointing — two edits, not fifteen.** The scope rule is "documents that still
steer future work", and most of the 56 mentions already read correctly:

- **Edited:** the epic's "Observations for spec authors" told a future item to reference 0010; it now
  names 0011 and records that the observation originally named 0010. Item 3's spec justified its
  bare-filename requirement with "a rewrite pass it is forbidden to have (ADR 0010)" — that
  justification is now false, so it was amended. The requirement itself survives on a better reason:
  Codex resolves siblings from the `SKILL.md` path it supplies.
- **Left alone, correct as written:** `CURRENT_WORK.md`, this item's spec and design, and all three
  `render-switch-feedback/design.md` mentions already say 0011 supersedes 0010.
- **Left alone, records not guidance:** `adr/INDEX.md`, 0010 and 0011 themselves, `spike-findings.md`,
  every `product-lens.md` block (the plan's exclusion list), plus the two review documents
  (`coordinator-synthesis/spec-review.md`, `render-switch-feedback/design-review.md`) — one of which
  quotes the spec sentence verbatim, where an edit would falsify the record.
- **Left alone, a judgment call worth naming:** `.project/concepts/mental-alignment-skill-design.md:133`
  says "At acceptance this design filed ADR 0009 … and ADR 0010". That is a true authoring-time
  record, not live guidance, so it falls on the same side as `spike-findings.md`. It is the one
  0010 mention a future reader could take at face value without seeing the supersession.

**Issues Encountered:**
- **`setup-global.sh --dry-run` has been broken, silently, for a long time.** It exited 1 straight
  after the banner. `create_dir` ended with `[ ! -d "$dir" ] && echo …`, which returns 1 when the
  directory already exists; the function inherits that status, and `set -e` kills the script at the
  first call. Fixed by restructuring `create_dir` to match `ensure_dir` in `setup-codex.sh`. **Out of
  plan scope, fixed anyway:** the D4 sweep has a dry-run branch that would otherwise be unreachable,
  and shipping an unexercised branch is the third instance in this item of the exact pattern it
  exists to remove.
- **The stencil's `grep -rn … "$ROOT"` matched itself.** The test file lives in `scripts/` and
  contains the searched string in its own assertion. Scoped with `--exclude='test_*.sh'`, and
  narrowed from `$ROOT` to `scripts/` + `CLAUDE.md` — `.project/` records quote the false claim as
  dated evidence and keep it on purpose.
- **The sweep found three more dead symlinks than expected:** `scripts/git-copy-custom.sh`,
  `git-manage-README.md`, and `git-merge-clean.sh` have been dangling in `~/.claude/scripts/` since
  they were removed from the pack. This is D4's premise landing exactly as argued — removals are a
  recurring event, not a one-off.
- **A second orphan, on the Codex side:** `~/.codex/scripts/mental-model-builder.md`, the v1 builder
  contract, installed before Item 2 deleted its source. `setup-codex.sh` has no removal path for a
  script absent from dist, the same gap as the `example-skill` skill directory. Removed by hand
  under the owner's standing "delete it" call, since Phase 4's goal is that no v1 surface remains.
  **The gap itself is not closed:** neither installer removes an orphaned top-level asset.

**Deviations:**
- **The `CLAUDE.md` correction is working-copy-only: `CLAUDE.md` is gitignored here**
  (`.gitignore:5`), so it is not tracked and the fix will not reach a fresh clone. The correction is
  applied and the assertion checks it when the file is present (`grep -rns`, so a fresh clone with
  no `CLAUDE.md` does not produce grep noise). Whether this repo should track its own `CLAUDE.md` is
  a separate call — flagged, not taken.
- **`_my_mental_model` was not added to `test_docs.sh`'s `RETIRED` list.** That list asserts a name
  is dead. `/_my_mental_model` still resolves — as a skill rather than a command — so the assertion
  would be false, and it would misfire on anyone who later documents the skill in the README. The
  row was removed because it sat in a *command* catalog and described v1's shape, not because the
  name is retired.
- **Consequence worth flagging:** the README now documents no skills at all, so `/_my_mental_model`
  and `show-me` are undocumented there. Adding a skills catalog is a real gap but not this item's
  call.

**Validation:**
- Full suite — codex-orchestrator-pack, docs, pipeline-sync, adr, global-setup → all pass.
- `git diff --check` → clean.
- `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy && ./scripts/setup-global.sh` →
  all three succeed; the Codex install reports `0 installed, 40 skipped, 0 removed` (converged), and
  `setup-global.sh` removed four dead symlinks including `skills/example-skill.md`.
- `grep -rn '_my_mental_model' dist/` → two hits, both intended: the provenance header and the
  authored-source path check at `SKILL.md:275`, which the skill lane deliberately leaves intact.
- No orphans left in either install: nothing in `~/.agents/skills/` or `~/.codex/scripts/` is absent
  from dist, and no dangling symlink remains under `~/.claude/`.

---

**Status**: In Progress — all four phases implemented and automated-validated. The Claude gate passed (owner, 2026-08-24). Outstanding: the two Codex behavioral gates in Phase 3 (end-to-end run, and a clean-room run confirming `fork_turns: "none"`).
