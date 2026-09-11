# Implementation Plan: Retire Dead Pack Content

**Status:** Certified.
**Created:** 2026-09-09
**Last Updated:** 2026-09-10

## Source Documents

- **Spec:** `.project/active/retire-hidden-memories/spec.md`
- **Product lens:** `.project/active/retire-hidden-memories/product-lens.md` (latest gate CLEAR; audit-F6 and audit-F7 resolved)
- **Epic:** `.project/backlog/epic_knowledge_homes.md` (KNOWLEDGE-HOMES, Item 1)
- **No design document.** Skipped by owner decision, 2026-09-09: the item has no architecture, no interfaces, and one mechanism worth five lines of jq. The mechanism decisions design would have made are carried inline in this plan, under *Decisions carried from design*.

## The Point

The pack tells agents to write knowledge into places that are hidden, empty, or nonexistent, and ships 1008 lines of subsystem built to solve a problem that no longer exists.

Two stores are hidden from the owner: the native memory directory sits outside git, and `.project/memories/` is gitignored and empty. Four always-on or command references point at things that do not exist — a `feedback_*` glob that never matched a file, a "Recent Decisions" section that is not in the file it targets, an auto-memory read for a store nothing writes. `example-rules.md` spends 31 lines of every session's always-on budget on unedited template boilerplate. And because this is a distributable template, the README walks a new user through installing hooks that will not exist and troubleshooting one that cannot run.

The obligation this serves, at owner grade: **nothing an agent writes lives outside git, and every instruction, installed artifact, and shipped document pointing at the hidden stores stops existing — including where the pack is already installed.** That last clause is what makes this more than a deletion. A machine that installed the pack before this change keeps a `PreCompact` registration pointing at a script that is gone.

This is Item 1 of three. It delivers value alone: four misdirecting references stop misdirecting, one rule file stops costing every session, and a whole subsystem stops needing maintenance. Nothing downstream depends on it being right, which is why it goes first.

---

## Implementation Strategy

**Phasing Rationale**

The only new code is the installer cleanup step, and it edits the user's global `settings.json` — so it goes first, test-first, and it goes *before* the hook scripts are deleted. Clean the settings while the files still exist and a wrong filter is recoverable; clean them after and the environment is already running a dangling hook.

Phase 2 lands the migration decision everywhere it has to reach. That is product-lens finding spec-F1: the amendment currently lives only in the spec, while seven upstream lines still require the migration the owner retracted, in artifacts that Items 2 and 3 read and this spec is not. Doing it early means a stall after Phase 2 leaves the record correct.

Phases 3 through 5 are the bulk, split by what verifies them: pack content by grep, installers by running them, Codex and docs by rebuild plus the doc tests.

**Critical Path**

Phase 1 → Phase 3 is the only hard ordering constraint (prove the settings cleanup before deleting what it points at). Phase 2 is independent and placed early for the stall-safety reason above. Phases 4 and 5 follow Phase 3 because they remove the plumbing and prose that describe what Phase 3 deletes.

**First Proof Point**

The Phase 1 fixture: a `settings.json` holding a user `PreToolUse` entry and a pack `PreCompact` entry, run through the new filter, asserting the first survives byte-for-byte and the second is gone.

**Overall Validation Approach**

- Phase 1 is genuinely test-first — a new automated case before the function exists.
- Phases 2, 3 and 5 are deletion and prose work. Their tests are the spec's grep criteria, written here as assertion stencils. That is honest about what the work is, not a shortcut.
- **Run the full grep set at the end of every phase, not only at the end.** The dominant failure mode in this item is a missed file across ~25 surfaces.

---

## Decisions carried from design

Four questions the spec left open, decided here per the approved strategy.

**D1 — The filter matches the script name, not the directory.** `uninstall-global.sh:68` selects PreCompact entries whose command contains `/.claude/hooks/`. That is too broad for an installer: a user's own hook living in that directory would be removed. Match `precompact-capture.sh` instead — exactly what the pack wrote, and nothing else has that name.

**D2 — `init-project.sh` gets the same cleanup.** It writes the same block into each project's `.claude/settings.json`, and eleven projects on this machine have used the pack. Same function, different target path.

**D3 — Ordering.** Settled by Phase 1 preceding Phase 3.

**D4 — `EXCLUDED_HOOKS` and the hook-translation path in `build-codex-pack.sh` are removed, not left as empty scaffolding.** AOP-005 rebuilds what it needs from a clean slate, and empty scaffolding is the same dead content this item exists to delete.

---

## Phase 1: The installer cleanup step (test-first)

### Goal

`setup-global.sh` and `init-project.sh` can strip a pack-written `PreCompact` registration from an existing `settings.json` without touching anything else.

### Assumption Under Test

That a filter can be written narrow enough to catch the pack's registration and nothing else — specifically, that it leaves a user's own hooks alone even when they live in the same directory.

### Test Stencil (Write This First)

Add to `scripts/test_global_setup.sh`. Four cases; the fourth is the reason for D1.

```bash
# Case 1: pack PreCompact removed, user PreToolUse untouched, unrelated keys intact
cat > "$tmp/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [{"matcher":"Read|Edit","hooks":[{"type":"command","command":"/home/u/.claude/hooks/auto-approve-paths.sh"}]}],
    "PreCompact": [{"matcher":"auto","hooks":[{"type":"command","command":"/home/u/.claude/hooks/precompact-capture.sh"}]}]
  },
  "model": "claude-opus-5"
}
JSON
cleanup_legacy_hooks "$tmp/settings.json"
assert_eq "absent" "$(jq -r '.hooks.PreCompact // "absent"' "$tmp/settings.json")"
assert_eq "/home/u/.claude/hooks/auto-approve-paths.sh" \
          "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$tmp/settings.json")"
assert_eq "claude-opus-5" "$(jq -r '.model' "$tmp/settings.json")"

# Case 2: pack hook was the only hook -> .hooks key removed entirely, file still valid JSON
# Case 3: no hooks at all -> no-op, file unchanged byte-for-byte
# Case 4: a USER PreCompact hook pointing at their own script -> SURVIVES (this is what D1 buys)
```

### Changes Required

**Reference:** spec.md *Known Requirements → Installer*, and D1/D2 above.

#### 1. Test file (write first)
**File:** `scripts/test_global_setup.sh`
- [x] Add the four cases above with a temp-dir fixture
- [x] Confirm they fail before the function exists

#### 2. The cleanup function
**File:** `scripts/setup-global.sh`
- [x] Add `cleanup_legacy_hooks()` taking a settings path and matching only the historical `precompact-capture.sh` path per D1, so near-name user hooks such as `my-precompact-capture.sh` survive
- [x] Back the file up before writing, as the uninstaller does
- [x] Drop `.hooks.PreCompact` when the array empties; drop `.hooks` when the object empties
- [x] Guard on `jq` being present, matching the existing scripts' behavior when it is not
- [x] Call it on `$TARGET_DIR/settings.json`

#### 3. Same function for project installs (D2)
**File:** `scripts/init-project.sh`
- [x] Call the same cleanup against the project's `.claude/settings.json`

### Validation

**Automated:**
- [x] `./scripts/test_global_setup.sh` → all four cases pass
- [x] `jq empty` on each fixture output → valid JSON

**Manual:**
- [~] `jq '.hooks' ~/.claude/settings.json` before and after a real `setup-global.sh` run → `PreToolUse` identical, `PreCompact` gone — **deferred to Phase 4**, run against a copy instead; see deviations

**What We Know Works After This Phase:** the settings surgery is safe to run against the owner's live config, before anything it points at is deleted.

**Implementation note:** the inherited filter calls `.command | contains(...)`, which errors if a hook entry has no `command` key. `test()` has the same exposure. Same risk as the existing uninstaller — do not solve it speculatively, but do not widen it either.

---

## Phase 2: The migration decision, landed everywhere

### Goal

Everything that follows from "nothing migrates": the two pack edits that replace it, the seven upstream lines that retract it, and this repo's six native memory files deleted.

### Assumption Under Test

None. This is a writing phase — its risk is wording, not mechanism.

### Verification Stencil

```bash
# The retracted obligation is gone from the artifacts downstream items actually read
grep -n "ENTRIES.md" .project/concepts/agent-knowledge-and-enforcement.md \
                     .project/backlog/epic_knowledge_homes.md
# Expect: only the register's subject boundary at concept :116. No line requiring four entries.

grep -ci "pause when you are done writing" claude-pack/commands/_my_handoff.md  # expect 1 (sentence-initial capital)
ls /home/rwestwood/.claude/projects/-home-rwestwood-agentic-project-init/memory/ # expect: no such directory
```

### Changes Required

**Reference:** spec.md *Why nothing migrates*, and *Known Requirements → Migration*.

#### 1. The two pack edits that replace the migration
**File:** `claude-pack/commands/_my_handoff.md`
- [x] Add the owner's line verbatim: *"pause when you are done writing and wait for further instruction"* — after step 4, where the command currently just ends

**File:** `claude-pack/rules/working-voice.md`
- [x] In the existing "Presenting a decision" section, add that the shape is walked through in prose, not presented through the multiple-choice question tool

#### 2. The seven upstream lines (spec-F1)
Each is **rewritten to state what is now true**, carrying a path-cite to this spec for the reasoning. Not annotated with a note about the change — capture-fidelity §3.

**File:** `.project/concepts/agent-knowledge-and-enforcement.md`
- [x] `:52` — Success Criterion 1, drop the migration clause
- [x] `:232` — Item B decomposition, drop the migration sentence
- [x] Leave `:116` alone. The register's subject boundary is unchanged by this item.

**File:** `.project/backlog/epic_knowledge_homes.md`
- [x] `:42` (Future State), `:54` (Success Criteria), `:112` (Item 1 In Scope), `:127` (Item 1 Done State), `:134` (Item 1 Deliverables)

#### 3. The native memory files
- [x] Delete the six files in `~/.claude/projects/-home-rwestwood-agentic-project-init/memory/`
- [x] The other ten projects' directories are **out of scope** — 71 unread entries, carried to Item 2 per spec *Carried to Item 2*

### Validation

**Automated:**
- [x] The greps above return what the stencil expects

**Manual:**
- [x] Read each of the seven rewritten lines and confirm it reads as a statement of what is true, not as a record of a change
- [x] Start a fresh session in this repo → no memory entries load — the directory itself is gone, so there is nothing left to load; confirm on the next session boot

**What We Know Works After This Phase:** a stall here still leaves the record correct. No downstream agent inherits a retracted requirement.

---

## Phase 3: Delete the subsystem and the dead rule

### Goal

The bulk removal, and the four references that only become wrong once the deletions land.

### Assumption Under Test

That nothing outside the epic's own artifacts still depends on any of it.

### Verification Stencil

```bash
grep -rn "_my_capture\|_my_memorize\|_my_recall\|_my_review_compact\|precompact-capture\|parse-transcript\|query-transcript\|capture\.sh\|example-rules" \
  --exclude-dir=.git . | grep -v "^\./\.project/"
# Expect: nothing outside .project/ artifacts

ls -L .claude/hooks   # expect: No such file or directory (gone, not dangling)
grep -n "product/INDEX.md" claude-pack/rules/context-loading.md  # expect: still present (ADR 0008)
```

### Changes Required

**Reference:** spec.md *Known Requirements → Deletions*.

#### 1. Commands, agent, hooks, rule
- [x] `git rm` the four commands: `_my_capture.md`, `_my_memorize.md`, `_my_recall.md`, `_my_review_compact.md`
- [x] `git rm claude-pack/agents/recall.md`
- [x] `git rm -r claude-pack/hooks/` (all four files, then the directory)
- [x] `git rm .claude/hooks` — tracked as a symlink blob, mode 120000; deleting the target is not enough
- [x] `git rm claude-pack/rules/example-rules.md`
- [x] Remove the installed symlinks: `~/.claude/rules/example-rules.md`, `~/.claude/agents/recall.md`, and the four in `~/.claude/hooks/` — plus the four dangling command symlinks in `~/.claude/commands/`, see deviations

#### 2. Memory stores
- [x] `git rm -r project-pack/memories/`
- [x] `rm -rf .project/memories/` (gitignored, untracked)
- [x] Remove `.gitignore:18` (`.project/memories`)

#### 3. The four stale references
- [x] `claude-pack/rules/context-loading.md:9` — delete the auto-memory item. **The product-ledger skim at `:6-7` survives** (ADR 0008, guarded by `test_docs.sh:82`)
- [x] `claude-pack/commands/_my_implement.md:152` — delete the `feedback_*` paragraph outright, per spec
- [x] `claude-pack/commands/_my_audit.md:92` — delete the `feedback_*` line outright
- [x] `claude-pack/commands/_my_wrap_up.md` — remove step 3 (`:37-54`) and its traces at `:3`, `:14`, `:74`. **Nothing else in this file.** Its final shape is Item 3

### Validation

**Automated:**
- [~] The grep above returns nothing outside `.project/` — **not yet, by design**: the ten remaining files are Phase 4's and Phase 5's own work, listed in the notes below
- [x] `ls -L .claude/hooks` fails with "No such file"

**Manual:**
- [x] Open `_my_wrap_up.md` and confirm step 4 (docs) and step 6 (commit) are untouched — those belong to Item 3
- [x] Confirm `context-loading.md` still has the product-ledger skim

**What We Know Works After This Phase:** no pack instruction points at either store, and the subsystem is gone from the source tree.

---

## Phase 4: Installer, settings, and test surgery

### Goal

The four scripts stop installing and removing what no longer exists, both `settings.json` files are clean, and the test suite tracks reality.

### Assumption Under Test

That the installers still run clean once every hook path is removed, and that the owner's `PreToolUse` hook survives all of it.

### Verification Stencil

```bash
./scripts/setup-global.sh --dry-run           # no hook output, no errors
./scripts/init-project.sh --dry-run           # no hook output, no memories dir
jq '.hooks.PreToolUse' ~/.claude/settings.json    # expect: the auto-approve-paths entry, unchanged
jq '.hooks.PreCompact' ~/.claude/settings.json    # expect: null
./scripts/test_init_project.sh                     # includes tracked-backup and tracked-executable guards
```

### Changes Required

**Reference:** spec.md *Known Requirements → Installer* and *Constraints on verification*.

#### 1. `scripts/setup-global.sh`
- [x] Drop `hooks` from the subdir loops at `:89` and `:126`
- [x] Delete the hook symlink block at `:147-153`
- [x] Delete `configure_hooks()` (`:199-243`) — the cleanup from Phase 1 replaces it
- [x] Delete `write_hook_paths()` (`:259-283`)
- [x] Update the header comment at `:3`

#### 2. `scripts/init-project.sh`
- [x] Remove `memories/index.json` from `USER_DATA_FILES` (`:122`) — spec-F2
- [x] Remove `memories` from the dir lists at `:191` and `:206`, and the echo at `:47`
- [x] Drop `hooks` from the subdir loops at `:227` and `:236`
- [x] Delete the hook config block (`:264-293`) and the hook-paths block (`:303-323`)

#### 3. The uninstallers
- [x] `uninstall-global.sh:54` — drop `hooks` from the loop; `:83` — drop `.hook-paths.json`; keep the settings.json cleaning, it is still correct for old installs
- [x] `uninstall-project.sh:95` — drop `recall.md`; `:100-103` — delete the hook-file block; `:116` — drop `example-rules.md`; `:125-127` — delete the hook-paths removal

#### 4. Settings files
- [x] `.claude/settings.json` — remove the `hooks` block, **keep `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`**
- [x] `~/.claude/settings.json` — run the Phase 1 cleanup against it

#### 5. Tests
- [x] `test_global_setup.sh:63` — drop `hooks` from the dir loop
- [x] `test_init_project.sh:77` — drop `memories`; `:198` — delete the `.project/memories` assertion
- [x] `test_rename.sh:51-60` — delete the hook-file check block; `:40` and `:66` — drop `capture|recall|memorize|review-compact` from the old-name patterns

### Validation

**Automated:**
- [x] `test_global_setup.sh`, `test_init_project.sh`, `test_rename.sh`, `test_uninstall.sh` → pass
- [x] Both installers `--dry-run` clean

**Manual:**
- [x] Run `setup-global.sh` for real, then confirm `jq '.hooks' ~/.claude/settings.json` shows `PreToolUse` only

**What We Know Works After This Phase:** a fresh install ships no hooks, an existing install gets cleaned, and the owner's own hook is untouched.

---

## Phase 5: Codex layer and docs sweep

### Goal

The last two surfaces: the Codex build, and every document that presents the subsystem as shipped.

### Assumption Under Test

That the Codex build succeeds with the exclusion lists emptied, and that no doc test depends on the removed content.

### Verification Stencil

```bash
./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy --dry-run
grep -n "example-rules" dist/codex/AGENTS.md          # expect: nothing
grep -inE "hook|memories|auto-memory|recall|transcript|memorize" \
  README.md docs/STRUCTURE.md CLAUDE.md docs/guide.md
# Expect: no line presenting any of them as a shipped component
./scripts/test_docs.sh && ./scripts/test_codex_orchestrator_pack.sh
```

### Changes Required

#### 1. Codex (D4)
- [x] `codex-overrides/config.sh` — empty `EXCLUDED_COMMANDS` (`:6-11`), `EXCLUDED_AGENTS` (`:13-15`), `EXCLUDED_HOOKS` (`:17-22`); remove the last if the build no longer reads it
- [x] `scripts/build-codex-pack.sh` — remove the hook-translation path (`:21-22`, `:402`, `:570-597`, `:621-622`, `:641-642`, `:652`)
- [x] Rebuild. `dist/` is wiped at the start of every build, so the dist changes follow — do not edit `dist/` by hand

#### 2. Docs
- [x] `README.md` — `:12`, `:29`, `:56`, the whole Legacy section `:137-146`, `:222`, `:224`, `:261`, `:291`, `:302`, `:347`, and the "Hook Not Running" troubleshooting section `:408-421`
- [x] `README.md:319` — **add the Updating exception** (spec-F3): this change is the one that requires re-running `setup-global.sh`, because the symlink story does not clean a stale registration
- [x] `docs/STRUCTURE.md` — `:8`, `:20`, `:30`, `:34`, `:58`, `:59`, `:84`, `:104`, `:106`, `:144`
- [x] `CLAUDE.md` — `:7`, `:10`, `:53`, `:75`, `:82`, `:94`, `:102`. `:53` describes `--copy` making hooks standalone files; with no hooks to copy, that clause goes. **Gitignored** (`.gitignore:6`), so these edits will not appear in the diff — verify in the working tree
- [x] `docs/guide.md:136` — drop "and auto-memory"

#### 3. The doc test's retired list
- [x] `scripts/test_docs.sh:59` — add `_my_capture _my_memorize _my_recall _my_review_compact` to `RETIRED`. The mechanism already exists; this is what makes the README removal enforced rather than hoped for

### Validation

**Automated:**
- [x] `test_docs.sh` → passes, including the widened `RETIRED` list and the ADR 0008 wired-guard at `:82`
- [x] `test_codex_orchestrator_pack.sh` → passes, including `does_not_contain "$AGENTS" 'auto-memory'` at `:370`
- [x] Full sweep: every grep in spec.md *Success Criteria*

**Manual:**
- [x] Read README's install and troubleshooting sections start to finish as a new user would — the failure this phase exists to prevent is a reader following text to a hook that is not there

**What We Know Works After This Phase:** the item is done. Every success criterion in the spec has been checked.

---

## Phase 6: Audit remediation

### Goal

Make upgrades and uninstallers converge on the retired state without touching user-owned files, then remove the stale documentation and dead Codex paths the audit found.

### Tests first

- [x] Cover legacy hook symlink cleanup during global setup and uninstall.
- [x] Cover a user-owned PreCompact hook, a partial global install, and legacy vendored project files in `test_uninstall.sh`.
- [x] Make the project merge test assert a directory the fixture did not create.
- [x] Guard the retired documentation and Codex paths in `test_docs.sh` and `test_codex_orchestrator_pack.sh`.

### Changes required

- [x] Route global uninstall through `cleanup_legacy_hooks`, make user-only cleanup a true no-op, and sweep legacy hook symlinks without aborting on absent directories.
- [x] Remove the exact retired files from legacy vendored projects, including the four retired commands, while preserving near-name hooks and user-authored `_my_*.md` commands.
- [x] Delete the stale memory-storage bullet, dormant Codex hook installer, and dead build substitutions.
- [x] Clarify SC1 to distinguish shipped surfaces from durable historical `.project/` records; do not rewrite history to erase old names.

### Validation

- [x] Run every `scripts/test_*.sh` under a temporary HOME.
- [x] Rebuild `dist/codex/`, confirm the generated tree is current, and run `git diff --check` plus the success-criteria greps.

---

## Phase 7: Fresh-audit remediation

### Goal

Remove the stale executable route and make every supported upgrade path converge on the retired state without hiding invalid configuration or removing user-owned hooks.

### Tests first

- [x] Reject tracked script backups and scan every tracked executable for code that creates the retired hook or memory surfaces.
- [x] Cover pack and user hooks grouped in one PreCompact entry.
- [x] Cover malformed settings JSON as an explicit unchanged failure.
- [x] Cover rerunning `init-project.sh --include-claude` over a legacy vendored install while preserving user files, including all four retired commands.

### Changes required

- [x] Delete `scripts/init-project.sh.bak`; git history is the backup.
- [x] Filter individual hook commands instead of whole PreCompact entries, and validate JSON before matching.
- [x] Give vendored project updates complete exact-name retired-file cleanup, including all four retired command files in the shared list.
- [x] Replace SC12's substring grep with the tracked-executable invariant, document the vendored update command, and correct the epic's legacy-cleanup wording.

### Validation

- [x] Run the retirement-owned setup, init, uninstall, documentation, and Codex tests under an isolated `HOME`.
- [x] Rebuild `dist/codex/`; run shell syntax checks, installer dry runs, manifest parsing, and `git diff --check`.

---

## Phase 8: Audit-F6 ownership-boundary remediation

### Goal

Make upgrade and uninstall behavior follow explicit pack ownership: remove every retired pack file, preserve near-name and namespace-sharing user files, and make the tests enumerate the full retired surface.

### Tests first

- [x] Seed all ten retired vendored files in the project-update fixture and assert every one is removed.
- [x] Add a near-name `my-precompact-capture.sh` hook fixture and assert byte-for-byte preservation with no backup.
- [x] Seed a user-authored `_my_custom.md` command in the project-uninstall fixture and make preservation a hard assertion.

### Changes required

- [x] Add the four retired commands to the shared exact-name vendored cleanup list.
- [x] Match only the historical `precompact-capture.sh` command path, not arbitrary strings containing that filename.
- [x] Remove current commands by exact filenames enumerated from the pack source, then remove retired commands through the shared legacy list; never treat `_my_*.md` as proof of ownership.
- [x] Amend the two live shaping statements so they reflect the owner-approved disposition: nothing migrates to the feedback log.

### Validation

- [x] Run all ten `scripts/test_*.sh` scripts under one isolated `HOME`.
- [x] Run shell syntax checks, all three installer dry runs, the Codex build, manifest parsing, stale-shaping searches, and `git diff --check`.

---

## Phase 9: Project-uninstall registration cleanup

- [x] Seed project uninstall with retired and user-owned `PreCompact` commands plus unrelated user settings; confirm failure before the fix.
- [x] Call the existing shared settings cleanup before deleting vendored files.
- [x] Assert that only the retired registration disappears.
- [x] Run the complete repository suite and static checks.

---

## Environment Setup

**See CLAUDE.md.** Relevant here: `./scripts/setup-global.sh` after command changes, and `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy` in that order for the Codex layer.

---

## Risk Management

| Risk | Phase | Mitigation |
|---|---|---|
| The cleanup filter removes a hook it should not | 1 | Test-first with a four-case fixture; case 4 specifically asserts a user's own PreCompact hook survives. D1 narrows the match to `precompact-capture.sh`. The filter backs the file up first |
| A missed reference across ~25 surfaces | 3, 5 | Run the full grep set at the end of **every** phase, not only at the end |
| The amendment is written as an annotation instead of a rewrite | 2 | All seven lines named individually; manual validation reads each one back |
| `_my_wrap_up.md` gets edited beyond the auto-memory step | 3 | Explicit non-goal in the checklist; step 4 and step 6 confirmed untouched |
| `context-loading.md`'s product-ledger skim gets removed with the auto-memory line | 3 | ADR 0008 invariant, guarded automatically by `test_docs.sh:82` |
| CLAUDE.md edits are invisible in the diff | 5 | Gitignored — verify in the working tree, not in review |

---

## Implementation Notes

### Phase 1 Completion

**Completed:** 2026-09-09

**Actual Changes:**
- Created `scripts/lib/settings-hooks.sh` defining `cleanup_legacy_hooks()` — the jq filter from `uninstall-global.sh:68` with D1's narrower match on `precompact-capture.sh`. Backs the file up, drops `.hooks.PreCompact` when the array empties, drops `.hooks` when the object empties, warns and no-ops when `jq` is absent.
- Modified `scripts/setup-global.sh:22-23` to source the library, and added the call at `:199-208` as its own "Removing legacy hook registration" step, ahead of the `configure_hooks` block that Phase 4 deletes.
- Modified `scripts/init-project.sh:67-70` to hoist `SCRIPT_DIR` to the top and source the library, and added the call at `:224-233`, before the `--include-claude` branch.
- Added the four cases plus an `assert_eq` helper to `scripts/test_global_setup.sh` as Test 5 (`:15-23`, `:136-226`).

**Issues:**
- The plan's stencil calls `cleanup_legacy_hooks` directly from the test, which needs the function to be sourceable. `setup-global.sh` runs its install at top level, so sourcing it would perform an install. Resolved by putting the function in a sourced library — see deviations.

**Deviations:**
- **The function lives in `scripts/lib/settings-hooks.sh`, not inside `setup-global.sh`.** The plan named `setup-global.sh` as the file, but D2 requires `init-project.sh` to call "the same function" and the test stencil calls it directly. One definition with three consumers is the only shape that satisfies both. Sourcing a shared file follows the existing `codex-overrides/config.sh` pattern. Phase 4's checklist item "Delete `configure_hooks()`" is unaffected.
- **`SCRIPT_DIR` hoisted in `init-project.sh`.** It was computed inside the `if [ -z "$SOURCE_DIR" ]` branch; sourcing needs it at the top. The now-redundant inner assignment was removed — same value, computed once.
- **The manual real-run validation is deferred to Phase 4.** `configure_hooks()` still runs after the cleanup and re-writes the `PreCompact` entry, so a live `setup-global.sh` run is a net no-op on `~/.claude/settings.json` and cannot demonstrate the end state. The filter was instead validated against a copy of the owner's real `~/.claude/settings.json`: `PreCompact` removed, `PreToolUse` identical including its `timeout` field, all non-hook keys byte-identical, live file untouched.

**Superseded by Phase 7:** command-less user hook objects are preserved, invalid JSON fails visibly before any write, and mixed pack/user entries lose only the matching pack command.

**Carried to Phase 4:** deleting `configure_hooks()` will break `scripts/test_global_setup.sh:79` ("settings.json created" after a fresh install into an empty HOME), because nothing else writes that file. Phase 4's test-surgery list names only `:63`. Add `:79` to it.

### Phase 2 Completion

**Completed:** 2026-09-09

**Actual Changes:**
- `claude-pack/commands/_my_handoff.md:19` — new step 5 carrying the owner's line, plus the substance of the correction it replaces: what comes next belongs in the Focus section, not in this session.
- `claude-pack/rules/working-voice.md:47` — new paragraph in "Presenting a decision", placed before the shape so the reader gets *when* a decision deserves this, then *that it is prose*, then the shape and its examples.
- Concept `:52` and `:232` rewritten; `:116` untouched as required.
- Epic `:42`, `:54`, `:112`, `:127`, `:134` rewritten.
- Deleted `~/.claude/projects/-home-rwestwood-agentic-project-init/memory/` (6 files). The other projects' directories are untouched — 71 files still present, matching the spec's count exactly.

**Issues:**
- The verification stencil's `grep -c "pause when you are done writing"` returns 0 because the instruction opens a sentence, so the word is capitalized. The owner's phrase is otherwise verbatim. Stencil changed to `grep -ci`; no content change.

**Deviations:**
- None to the seven-line scope.

**Surfaced, not acted on:** the epic's Deliverables list at `:132` still names `.project/active/retire-hidden-memories/design.md`, which will never exist — design was skipped by owner decision, 2026-09-09. Same class of stale line as the seven, but outside the scope Phase 2 names. Awaiting the owner's call.

**Validation:** all nine test scripts pass. `.project/feedback/ENTRIES.md` unmodified in git. `grep -n "ENTRIES.md"` across the concept and epic returns no line requiring four migrated entries; the register's subject boundary at concept `:116` still stands.

### Phase 3 Completion

**Completed:** 2026-09-09

**Actual Changes:**
- `git rm`: the four commands, `claude-pack/agents/recall.md`, `claude-pack/hooks/` (four files + directory), the `.claude/hooks` symlink blob, `claude-pack/rules/example-rules.md`, `project-pack/memories/` (SPEC.md + index.json).
- `rm -rf .project/memories/`; removed the `.project/memories` line from `.gitignore`.
- Removed ten installed symlinks under `~/.claude/`. `~/.claude/hooks/auto-approve-paths.sh` is a real file, not a pack symlink, and survives — the directory now holds only it.
- `context-loading.md` — auto-memory item deleted; the product-ledger skim at `:6` survives.
- `_my_implement.md`, `_my_audit.md` — the `feedback_*` paragraph and line deleted outright.
- `_my_wrap_up.md` — step 3 and its three traces removed, steps 4/5/6 renumbered to 3/4/5, and the `--quick` line's step references updated to match. The docs and commit step bodies are byte-identical; only their heading numbers changed.

**Issues:**
- The phase's grep stencil filters `.project/` with `grep -v "^\./\.project/"`, but the paths it was filtering carry no `./` prefix, so the filter matched nothing and the check drowned in 1MB of output. Re-ran as `grep -rln ... --exclude-dir=.git --exclude-dir=.project --exclude-dir=dist`, which gives the real list.

**Deviations:**
- **Four extra symlinks removed.** The checklist named the rule, agent, and four hook symlinks but not `~/.claude/commands/_my_{capture,memorize,recall,review_compact}.md`, which dangle once their targets are gone. `sweep_dead_symlinks` would clear them on the next `setup-global.sh`; removing them now keeps four broken commands from being offered in the meantime.

**Two sites the plan's checklists do not cover, found by the corrected grep:**
1. **Fixed here.** Two more lines carried the retracted migration, phrased as "the feedback log" rather than "ENTRIES.md", which is why the Phase 2 grep missed them: `.project/backlog/BACKLOG.md:153` and `.project/backlog/epic_knowledge_homes.md:96` (Item 1 Objective). Both rewritten in the Phase 2 style. The spec's requirement is "amended at every live site", so this is that requirement applied to sites the seven-line count missed, not new scope. The migration obligation is now gone from every `.project` artifact.
2. **Carried to Phase 5.** `codex-overrides/prompt-prefixes/wrap-up.md` tells Codex to ignore `/_my_capture`, `/_my_memorize`, auto-memory, and transcript persistence. Once none of those exist, that prefix is instruction about a non-requirement — capture-fidelity §3's failure shape. It is not in Phase 5's checklist. Its build output is `dist/codex/skills/my-wrap-up/SKILL.md:16`.

**Still referencing the removed names, all scheduled:** `.claude/settings.json` and `scripts/{setup-global,init-project,uninstall-project}.sh` (Phase 4); `README.md`, `docs/STRUCTURE.md`, `codex-overrides/config.sh` and the wrap-up prefix above (Phase 5). Two are permanent and correct: `scripts/lib/settings-hooks.sh` and the Phase 1 fixtures in `scripts/test_global_setup.sh` both name `precompact-capture.sh` because stripping that registration is what they exist to do. **Phase 5 must not read the spec's first success criterion as requiring their removal.**

**Validation:** all nine test scripts pass. `ls -L .claude/hooks` fails with "No such file or directory". `context-loading.md` still skims `.project/product/INDEX.md`.

### Phase 4 Completion

**Completed:** 2026-09-09

**Actual Changes:**
- `setup-global.sh` — header comment, both subdir loops, the hook symlink block, `configure_hooks()` and its call, `write_hook_paths()` and its call. Only the Phase 1 cleanup step still mentions hooks, which is what it is for.
- `init-project.sh` — `memories/index.json` out of `USER_DATA_FILES` and the `--help` text, `memories` out of both directory lists, `hooks` out of both vendoring loops, the hook config block and the hook-paths block deleted.
- `uninstall-global.sh` — `hooks` out of the symlink loop, `.hook-paths.json` out of the metadata list. The settings.json cleaning stays, still correct for old installs.
- `uninstall-project.sh` — `recall.md` dropped, the hook-file block, the rule-file block and the hook-paths removal deleted. The rule-file block went whole because `example-rules.md` was its only entry and an empty `for` list is a syntax error.
- `.claude/settings.json` — now holds only the `env` block.
- `~/.claude/settings.json` — cleaned. A real `setup-global.sh` run afterwards left it byte-identical: `PreToolUse` present with its `timeout`, no `PreCompact`, every unrelated key untouched.
- Tests: `test_global_setup.sh` dir loop, `test_init_project.sh` dir loop and the merge-strategy assertion, `test_rename.sh` hook-file block and both old-name patterns.

**Issues:**
- **Two fresh-install assertions broke, as predicted in Phase 1.** With `configure_hooks()` and the vendored hook block gone, nothing writes `settings.json`, so `test_global_setup.sh:79` and `test_init_project.sh:149` both failed on "settings.json not created". Phase 4's checklist named neither. Both are now inverted to assert the opposite — a fresh install and a vendored install must **not** write `settings.json` — which is a direct test of the spec's criterion that the installers register nothing.
- The original `grep -n "memories" scripts/init-project.sh` criterion returned one hit from the work-item path in a comment rather than from memory behavior. Phase 7 replaced it with tracked-tree checks for backup scripts and retired surface creation.

**Deviations:**
- None to the checklist. The two inverted test assertions are additions, not changes to what the plan asked for.

**Surfaced — the plan is inconsistent about `.hook-paths.json`.** It keeps the uninstaller's settings.json cleaning because it "is still correct for old installs", then drops the `.hook-paths.json` removal line one clause later. Old installs need that line for exactly the same reason. As it stands, `setup-global.sh` no longer writes the file, `uninstall-global.sh` no longer removes it, and nothing else will: any machine that installed the pack keeps a stale `.hook-paths.json` forever, which contradicts concept SC2 and the spec's `[NEED]` ("`.hook-paths.json` ... removed"). Nothing in the repo reads it — only `.project` artifacts mention it. **Deleted from this machine** to satisfy the requirement here; the distribution question is the owner's call. Two candidate fixes, both one line: restore the uninstaller's removal line, or add `rm -f "$TARGET_DIR/.hook-paths.json"` beside the installer's PreCompact cleanup, which is the pattern spec-F3 already established for this exact problem.

**Validation:** all nine test scripts pass. Both installers `--dry-run` clean. Live `~/.claude/settings.json`: `PreCompact` null, `PreToolUse` unchanged. `~/.claude/hooks/` holds only the user's own `auto-approve-paths.sh`.

### Phase 5 Completion

**Completed:** 2026-09-09

**Actual Changes:**
- `codex-overrides/config.sh` — `EXCLUDED_COMMANDS` and `EXCLUDED_AGENTS` emptied, `EXCLUDED_HOOKS` removed entirely (D4).
- `scripts/setup-codex.sh` — the `EXCLUDED_HOOKS` reporting loop removed, since the array is gone.
- `scripts/build-codex-pack.sh` — array declarations, the `dist/codex/hooks` mkdir, the hook copy loop, the `hooks.json` emitter, both manifest fields, and the summary line.
- `codex-overrides/prompt-prefixes/wrap-up.md` — the two lines naming deleted machinery removed (the Phase 3 finding). Its scope restriction stays: that also excludes the commit step, which this item did not decide.
- `README.md` — nine sites plus the whole Legacy command table and the "Hook Not Running" troubleshooting section, and the Updating exception added (spec-F3).
- `docs/STRUCTURE.md` — nine sites across both directory trees, the "What Ships" list, and the FAQ.
- `CLAUDE.md` — seven sites, including the `--copy` clause and the Codex-exclusions paragraph, now describing two empty lists rather than naming deleted commands.
- `docs/guide.md` — "and auto-memory" dropped from the `wrap_up` line.
- `scripts/test_docs.sh` — `RETIRED` widened by the four command names.

**Issues:**
- **The first rebuild produced invalid JSON.** Removing the `hooks` field from the manifest's `excluded` block left the preceding `agents` field emitting a trailing comma. Caught by `jq -e` on `dist/codex/manifest.json`, fixed, rebuilt. Worth noting because `test_codex_orchestrator_pack.sh` passed against the broken manifest — nothing in the suite parses it.

**Deviations:**
- **`scripts/setup-codex.sh` edited, which Phase 5's checklist does not name.** Unavoidable: it read `EXCLUDED_HOOKS` at `:400`, and D4 removes that array.

**Validation:** all ten test scripts pass. `setup-codex.sh --copy --dry-run` clean. `dist/codex/AGENTS.md` has no `example-rules` section; the manifest is valid JSON with all three exclusion lists empty; `dist/codex/hooks/` and `hooks.json` are gone. README's install, updating and troubleshooting sections read start to finish with no path to a hook that is not there.

**Full success-criteria sweep — all pass.** Three files still name the removed scripts, all three load-bearing and flagged in Phase 3: `scripts/lib/settings-hooks.sh` and the Phase 1 fixtures in `test_global_setup.sh` name `precompact-capture.sh` because stripping that registration is what they do, and `test_docs.sh`'s `RETIRED` list must name the four commands — that list is the mechanism enforcing their absence from the README. The one `memories` hit in `init-project.sh` is a comment citing this work item's own folder path.

### Phase 6 Completion

**Completed:** 2026-09-10

**Actual Changes:**
- Global setup and uninstall now remove legacy dangling hook symlinks, and global uninstall uses the shared settings cleanup instead of a second broader jq implementation.
- The shared settings cleanup detects a matching pack hook before writing, so a user-only PreCompact configuration remains byte-identical and gets no backup file.
- Project uninstall removes only the named retired hook, recall-agent, and example-rule files from legacy vendored installs while preserving user-owned files.
- The stale structure bullet, dormant Codex hook installer, dead build substitutions, vacuous merge assertion, and missing regression guards were removed or corrected.
- SC1 now distinguishes executable and shipped product surfaces from durable historical `.project/` evidence. Historical records were not rewritten.

**Issues:**
- The first no-op implementation compared jq-formatted output with the original file, which rewrote semantically identical JSON. The match check now runs before the transformation, so an unmatched file is not opened for writing.

**Deviations:**
- No Codex stale-asset cleanup shim was added. Commit `fbcfea5` shows the retired assets were excluded from the first Codex installer release, so there is no historical installed state for such a shim to clean.

**Validation:** all ten `scripts/test_*.sh` scripts pass under a temporary `HOME`; `scripts/build-codex-pack.sh` succeeds; shell syntax checks, `jq -e . dist/codex/manifest.json`, `git diff --check`, and the success-criteria greps pass.

### Phase 7 Completion

**Completed:** 2026-09-10

**Actual Changes:**
- Deleted the tracked executable `scripts/init-project.sh.bak` and added guards that reject tracked script backups and inspect every tracked executable for code that creates `.claude/hooks` or `.project/memories`.
- Changed `cleanup_legacy_hooks()` to validate JSON before inspection and to remove matching commands inside each PreCompact entry. User commands sharing the same entry now survive, empty entries and containers are still removed, and malformed files fail unchanged with a clear error.
- Added one exact-name vendored-file cleanup helper shared by project update and uninstall. `init-project.sh --include-claude` invokes it only when the pack's vendoring marker exists, so unrelated `.claude` trees are not touched.
- Updated README's upgrade exception to cover global and vendored installs, and corrected the epic wording so installers create no retired state while update and uninstall remove known legacy pack state.
- Replaced SC12's literal substring grep with the tracked-backup and tracked-executable checks that caught the actual duplicate route.

**Issues:**
- The first direct `test_init_project.sh` run reached its source-auto-detection case with the real sandboxed `HOME` and failed when it tried to write metadata there. The test passes under the required isolated `HOME`.
- The complete ten-script loop currently stops in `test_docs.sh` on an unrelated `execution-register` assertion added by that separate active item's unfinished implementation. Every retirement-specific assertion in `test_docs.sh` passes, and the other nine scripts pass under one isolated `HOME`.

**Deviations:**
- The audit asked for a safe vendored update path but did not prescribe code sharing. The exact retired-file list now lives in `scripts/lib/legacy-vendored-files.sh` and is called by both init and uninstall so those paths cannot drift again.
- SC12 was amended instead of deleting a useful source comment merely to satisfy `grep "memories"`. The replacement checks behavior across every tracked executable and rejects tracked backup scripts.

**Validation:** `test_global_setup.sh`, `test_init_project.sh`, `test_uninstall.sh`, `test_codex_orchestrator_pack.sh`, and the other retirement-independent scripts pass under an isolated `HOME`; all retirement checks inside `test_docs.sh` pass before its unrelated execution-register failure. `scripts/build-codex-pack.sh`, `bash -n scripts/*.sh scripts/lib/*.sh`, all three installer dry runs, `jq -e . dist/codex/manifest.json`, and `git diff --check` pass.

### Phase 8 Completion

**Completed:** 2026-09-10

**Actual Changes:**
- `scripts/lib/legacy-vendored-files.sh` now holds the complete ten-file retired vendored inventory, including all four retired commands. Project update and uninstall consume the same list.
- `cleanup_legacy_hooks()` now recognizes only the exact historical relative path or a path ending in `/.claude/hooks/precompact-capture.sh`. A user hook such as `my-precompact-capture.sh` is not a match.
- `uninstall-project.sh` enumerates current pack command filenames from `claude-pack/commands/` and uses the shared legacy list for retired commands. It no longer deletes every `_my_*.md` file.
- The concept and epic statements that still assigned all four corrections to the feedback log were amended to the approved disposition: two were already fixed or dead, two became direct pack edits, and nothing migrates.
- The init and uninstall fixtures now seed all ten retired files. The hook fixture covers a hostile near-name collision, and the uninstall fixture proves a user-authored `_my_custom.md` survives.

**Issues:**
- The first exact-hook implementation compared jq-formatted output to the original bytes, so a valid user-only file appeared changed because of formatting. The final implementation compares the parsed JSON values, preserving the original file byte-for-byte when no retired command exists.

**Deviations:**
- The settings cleanup uses one jq transformation followed by semantic comparison instead of duplicating the exact-path predicate in a separate detection pass. This keeps one ownership rule in one place while retaining byte-for-byte no-op behavior.

**Validation:** all ten `scripts/test_*.sh` scripts pass under one isolated `HOME`. `bash -n scripts/*.sh scripts/lib/*.sh`, `scripts/build-codex-pack.sh`, all three installer dry runs, `jq -e . dist/codex/manifest.json`, the stale-shaping search, and `git diff --check` pass.

### Phase 9 Completion

**Completed:** 2026-09-10

**Changes:** `uninstall-project.sh` now applies the existing `cleanup_legacy_hooks()` function to `.claude/settings.json` before removing vendored files. The composed uninstall fixture proves the retired registration is removed while the user hook and unrelated settings survive.

**Validation:** the composed assertion failed before the cleanup call and passes afterward. The complete repository suite and static checks pass.

---

## Item status

All nine phases were executed and independently certified. Audit-F6 and audit-F7 are resolved.

**Still parked for Item 2:** the native memory directory is recreated by the harness after deletion, so cleaning it is not a one-time act.

---

**Status**: Certified
