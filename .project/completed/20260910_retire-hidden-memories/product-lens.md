# Product Lens — retire-hidden-memories

Append-only ledger. Newest block at the bottom. Do not rewrite existing blocks.

```
Epic: KNOWLEDGE-HOMES

Epic findings, referenced not restated — the epic file stays the source of truth
(.project/backlog/epic_knowledge_homes.md, Product-Lens section). Grades preserved as recorded there:

- epic_plan-F1 — two homes for one subject at /_my_close. Owner-dispositioned 2026-09-09
  ("remove this. I do not want this at all"). RESOLVED. Claimed by Item 2, not this item.
- epic_plan-F2 — doc sweep wider than the epic first scoped (README, docs/STRUCTURE.md, CLAUDE.md,
  the hooks dir and its symlink). agent-grade, DISPOSE-and-proceed. RESOLVED. Absorbed into this
  item's scope as [INHERITED].
- epic_plan-F3 — the product-ledger skim in context-loading.md must survive. agent/ratified
  (ADR 0008). DISPOSE-and-proceed. RESOLVED. Carried here as a success criterion.
- epic_plan-F4 — Recently Completed is cut while its replacement is measurably thinner.
  agent-grade with an owner-verbatim reason. OPEN by design, assigned to Item 3's spec.
  Does not bear on this item.

Epic gate at spec time: CLEAR.
```

```
## spec — 2026-09-09 — rev .project/active/retire-hidden-memories/spec.md @ 78ea3b5

Point (re-derived): Nothing an agent writes lives outside git, and every pack instruction,
installed artifact, and shipped document that pointed at the hidden stores or the transcript
stack stops existing — including where the pack is already installed.
  [source: .project/concepts/agent-knowledge-and-enforcement.md — Success Criteria 1, 2, 8 +
   Owner's Words ("Let's kill hidden memories.", "we should kill `example-rules.md`");
   grade: owner]
  [secondary: README "What's Included"/Troubleshooting, docs/STRUCTURE.md "What Ships"
   (INHERITED/aspirational); .project/adr/0008 active, "[AGENT] (ratified 2026-08-09)"
   pins the product-ledger skim inside context-loading.md (agent/ratified)]

Falsifier: after the item, an agent reading the concept or the epic is still told four
feedback entries must exist in `.project/feedback/ENTRIES.md`; or a grep of README /
STRUCTURE / CLAUDE / guide still presents hooks, memories, recall or auto-memory as shipped;
or `context-loading.md` no longer skims the product ledger; or a machine that already ran
`setup-global.sh` still fires a `PreCompact` hook pointing at a deleted script.

Findings:

- spec-F1 [DO] The amendment is recorded only in this spec, while the retracted obligation
  stays live in five upstream places. Concept Success Criterion 1 (`[OWNER]`) still says the
  four entries "have been moved into `.project/feedback/ENTRIES.md`", and the epic asserts it
  four times: success criterion 3 (`epic_knowledge_homes.md:54`), Item 1 In Scope (`:112`),
  Item 1 Done State (`:127`), Item 1 Deliverables (`:134`). The spec names only "the epic's
  third success criterion" and requires no edit to either artifact. Items 2 and 3 carry the
  *concept* as Required Reading and never read this spec, so every downstream agent still
  inherits the migration as a requirement, and epic-scope audit/close will check Item 1
  against a done-state the owner retracted.
  — source: concept SC1 (owner) + capture-fidelity §3, "a correction deletes or amends the
    corrected content", which governs every artifact write — disposition: DISPOSE-and-proceed.
    Required: make amending concept SC1 and all four epic sites part of this item's scope and
    success criteria, carrying the owner's 2026-09-09 words and the entry-by-entry reasoning
    by path-cite. Owner authority for the change is already recorded and quoted, so this is
    propagation, not authority — it does not BLOCK.
  Falsifier: after the item, `grep -n "ENTRIES.md" .project/concepts/agent-knowledge-and-
  enforcement.md .project/backlog/epic_knowledge_homes.md` still returns lines requiring four
  migrated entries.

- spec-F2 [DO] `memories/index.json` stays in the installer's user-data protection list.
  `scripts/init-project.sh:122` lists it in `USER_DATA_FILES`; the epic named removing it
  (`epic_knowledge_homes.md:106`), and the spec's requirements, success criteria and
  verification constraints never mention it. After `project-pack/memories/` is deleted, the
  one list a future agent reads to learn what `--force` must never clobber names a path the
  template no longer ships.
  — source: epic Item 1 In Scope `:106` (agent/ratified) — disposition: DISPOSE-and-proceed.
    Add it to the deletion requirement at spec.md:51 and to the grep success criterion.
  Falsifier: `grep -n "memories" scripts/init-project.sh` returns the USER_DATA_FILES entry
  after the item.

- spec-F3 [DO] Existing installs keep a live hook the item deletes. The only cleanup path is
  a new step in `setup-global.sh` (spec.md:65), but README's "Updating" section tells users
  "Changes are instantly available via symlinks - no need to re-run setup." A user who pulls
  gets deleted hook scripts plus a surviving `~/.claude/settings.json` PreCompact entry
  pointing at a now-dangling `~/.claude/hooks/precompact-capture.sh`, firing on every
  autocompact. The spec's open question frames this as a design call about `init-project.sh`
  only, not about the README promise that makes the cleanup unreachable.
  — source: README "Updating" (INHERITED/aspirational), backed by concept SC2 "both PreCompact
    registrations ... are all removed" (owner) — disposition: DISPOSE-and-proceed. Cheapest
    fix is one README line making this update the exception that requires re-running
    `setup-global.sh`; alternatively state in the spec that stale third-party installs are
    accepted and why.
  Falsifier: on a machine that installed the pack before this change, git pull then start a
  session — `jq '.hooks.PreCompact' ~/.claude/settings.json` still returns an entry.

Smells fired:
- Smell 1 — two representations must be manually kept synchronized. The concept/epic and this
  spec now state contradicting done-states for the same item, with nothing keeping them
  consistent. Fires on spec-F1; escalates into the spec's judgment there.

Checked, no finding:
- The "nothing migrates" amendment itself. Owner-originated, dated, quoted entry by entry, and
  the point's headline still holds after it: two corrections land in git as pack edits
  (`_my_handoff.md`, `working-voice.md`), one duplicates CLAUDE.md, one dies by owner
  decision with a verbatim reason. Verified against `.project/feedback/README.md` — its "once
  fixed the entry is dead" rule and its bare pack-target tag requirement support both the
  `voice-plain-writing` and `feedback-answer-questions-dont-act` dispositions.
- ADR 0008's product-ledger skim survives (spec.md:35). ADR 0001's no-current-state-doc
  rejection is not touched.
- The added scope is required by the point, not drift. The `setup-global.sh` cleanup closes a
  registration the concept requires removed; the `[HARD]` PreToolUse survival is asserted as a
  testable criterion (spec.md:37).
- The spec correctly retires an inherited-but-wrong risk: `jq -s '.[0] * .[1]'`
  (`scripts/setup-global.sh:231`) merges objects recursively, so `.hooks.PreToolUse` was never
  threatened. Verified.
- Leaving 71 native memory files across ten other projects technically leaves agent-written
  knowledge outside git. Handled per capture-fidelity §4 — surfaced, quantified, parked as a
  non-goal that is "not a permanent decision", with its evidence value carried to Item 2.
- No unresolved BLOCK carries in from the epic ledger: epic_plan-F1/F2/F3 are RESOLVED;
  epic_plan-F4 is OPEN by design and assigned to Item 3's spec, not this item.

Gate: DISPOSED (spec-F1, spec-F2, spec-F3)
```

## Dispositions applied to the spec, 2026-09-09

- **spec-F1 — accepted, scope widened.** Amending the retracted obligation at every live site is now a requirement and a success criterion. Verified count is larger than the finding stated: seven lines, not five — concept `:52` and `:232`, epic `:42`, `:54`, `:112`, `:127`, `:134`. Concept `:116` is explicitly excluded, since the register's subject boundary is unchanged by this item. No ADR triggered: the owner's amendment is already recorded at owner grade, so this is propagation, not a new contract decision.
- **spec-F2 — accepted.** `memories/index.json` removal from `USER_DATA_FILES` (`scripts/init-project.sh:122`) added to the deletion requirement, with a grep success criterion.
- **spec-F3 — accepted.** `README.md:319` verified to read "Changes are instantly available via symlinks - no need to re-run setup." Marking this update as the exception that requires re-running `setup-global.sh` is now a requirement and a success criterion. The alternative the finding offered — accepting stale third-party installs — was not taken, since the concept requires both PreCompact registrations removed at owner grade.

```
## audit — 2026-09-09 — rev working tree over 78ea3b5

Point (re-derived): The pack's installed surfaces are the product — a Claude install under
`~/.claude/` and a Codex install under `~/.agents/`+`~/.codex/`. When a capability is deleted
from `claude-pack/`, the deletion must reach both installed surfaces, leave no pack-written
machine state behind, and touch nothing the user put there themselves; the repo's durable
descriptions must stop advertising what no longer ships.
  [source: .project/concepts/agent-knowledge-and-enforcement.md SC1/SC2/SC8 (owner) for the
   substance; README "Updating" :303-305, "Script Reference → uninstall-global.sh" :247
   ("preserves user files"), docs/STRUCTURE.md (INHERITED/aspirational); .project/adr/0011
   active [OWNER] for two-lane parity]

Falsifier: on a machine installed before this change, `git pull` then run the installers —
a pack-written registration or file survives, a user-written one is destroyed, a deleted
capability is still invokable, or a fresh `build-codex-pack.sh` does not reproduce the
committed `dist/codex/`.

Findings:

- audit-F1 [DON'T] `uninstall-global.sh:68` deletes a PreCompact hook the user wrote
  themselves. Its filter matches `contains("/.claude/hooks/")`; after this change the pack
  never places anything in `~/.claude/hooks/`, so that matcher can now only ever hit user
  hooks. The item introduced `scripts/lib/settings-hooks.sh`, whose header (`:16-18`) states
  the opposite invariant — "a PreCompact hook the user wrote themselves survives even when it
  lives in the same directory" — and whose Case 4 test asserts it
  (`scripts/test_global_setup.sh:211-227`), but the uninstaller was not moved onto the helper.
  Verified: a fixture HOME whose only registration is `$HOME/.claude/hooks/my-own-precompact.sh`
  loses its entire `.hooks` object to `uninstall-global.sh`.
  — source: README:247 + Script Reference "preserves user files" (INHERITED/aspirational),
    contradicted against the item's own documented invariant (AGENT) — disposition:
    DISPOSE-and-proceed. Fix is one line: call `cleanup_legacy_hooks` from `uninstall-global.sh`
    instead of the inline jq, and extend `test_uninstall.sh` (which has zero settings.json
    coverage today).
  Falsifier: `HOME=<fixture> ./scripts/uninstall-global.sh` on a settings.json whose only
    PreCompact entry is a user script under `.claude/hooks/` — the entry is gone afterward.

- audit-F2 [DO] The deletion does not reach existing installs beyond the settings.json entry.
  Claude lane: `hooks` was dropped from both `setup-global.sh:92` (dead-symlink sweep) and
  `uninstall-global.sh:54` (removal loop), so a legacy machine keeps dead symlinks in
  `~/.claude/hooks/` that no installer path will ever remove — verified with a fixture: they
  survive `setup-global.sh` while `commands/_my_recall.md`, `agents/recall.md` and
  `rules/example-rules.md` are correctly swept. Codex lane is worse, because installs are
  copies, not links: verified that `setup-codex.sh --copy` leaves
  `~/.agents/skills/my-recall/SKILL.md`, `~/.codex/agents/recall.toml` and
  `~/.codex/hooks/capture.sh` untouched — all three carry the pack's own `Generated from`
  marker, so they are pack-managed, and `my-recall` stays invokable, instructing the agent to
  query a transcript database the pack no longer ships. `mirror_skill_dir`
  (`setup-codex.sh:256`) only prunes files inside skill directories still present in `dist/`;
  a skill directory absent from `dist/` is never visited.
  — source: concept SC1/SC2 (owner) for the substance; the item already accepted the
    reach-existing-installs obligation for the settings.json half (spec-F3 disposition,
    README:305) and stopped there. Extension to the install footprint is my inference —
    (INHERITED/aspirational) — disposition: DISPOSE-and-proceed. Cheapest fix: restore
    `hooks` to the two Claude-lane loops for one release, and add a stale-skill-directory
    sweep to `setup-codex.sh` keyed on the `Generated from` marker.
  Falsifier: the two fixture runs above. On THIS machine all four Codex residue paths are
    verified ABSENT and `~/.claude/hooks/` holds only the user's own auto-approve-paths.sh —
    the finding is latent for other installs, resting on the fixture, not observed here.

- audit-F3 [DO] `docs/STRUCTURE.md:64` still lists "Memory storage structure" as part of what
  `project-pack/` becomes. Sibling bullets in the same list were updated; this one was missed.
  It is the only surviving reference across README, docs/, CLAUDE.md, claude-pack/,
  project-pack/ and .gitignore.
  — source: docs/STRUCTURE.md (INHERITED/aspirational) — disposition: DISPOSE-and-proceed,
    one-line deletion.
  Falsifier: `grep -n "Memory storage" docs/STRUCTURE.md` returns a line.

- audit-F4 [DON'T] `scripts/setup-codex.sh:367-380` still carries the hook-installation block:
  copies `dist/codex/hooks/*` to `~/.codex/hooks/`, installs `hooks.json`, warns when
  `config.toml` lacks `codex_hooks`. Its producer was deleted from `build-codex-pack.sh`, so
  it is dead today, guarded by a `dist/codex/hooks` directory the build no longer creates. It
  is live code in the shipped installer of a pack whose stated point is now "no hooks"; the
  Claude lane's equivalent was removed, so the lanes were treated asymmetrically.
  — source: concept SC2 (owner) for substance, CLAUDE.md "Codex Compatibility Layer" + ADR
    0011 for parity (INHERITED/aspirational) — disposition: DISPOSE-and-proceed.

Smells fired:
- Smell 1 — two representations must be manually kept synchronized. The same settings.json
  surgery now exists twice, at `scripts/lib/settings-hooks.sh:35` and
  `scripts/uninstall-global.sh:68`, with nothing keeping them consistent — and they are
  already divergent on the one behavior the item cared enough to test. Fires on audit-F1;
  escalates into the audit's judgment there.
- Smell 6 — a test passes only because it selects one route. `test_global_setup.sh` Case 4
  asserts "a user PreCompact hook in the same directory survives" by unit-testing the new
  helper; the other route to the same surgery violates it and `test_uninstall.sh` has no
  settings.json coverage at all. This is why the divergence went undetected. Fires on
  audit-F1.

Checked, no finding:
- All three prior spec findings landed. spec-F1: concept SC1 and epic `:54`/`:127` now carry
  "Nothing is migrated", amended rather than accreted. spec-F2: `memories/index.json` is gone
  from `USER_DATA_FILES`. spec-F3: README:303-305 carries the re-run-setup exception.
- `dist/codex/` reproduces byte-for-byte from a fresh `build-codex-pack.sh` (only manifest
  `generated_at`/`revision` differ). No smell 1 on the dist lane.
- All 10 `scripts/test_*.sh` pass.
- SC1 met: this repo's native memory dir is empty; the `.gitignore` line and the repo's
  `.claude/settings.json` PreCompact registration are gone, its `env` block survives.
- SC8's `~/.claude/rules/` clause met — `setup-global.sh` sweeps `example-rules.md` on a
  legacy machine (fixture-verified); `~/.codex/rules/` carries no copy.
- The two in-pack corrections (`_my_handoff.md:5`, `working-voice.md:47`) are positive
  instructions, not prohibitions naming the rejected behavior. Capture-fidelity §3 compliant.
- `context-loading.md` keeps the product-ledger skim (ADR 0008 / epic_plan-F3).
- `~/.codex/memories/` is Codex harness state, not pack-installed — the concept's parked
  non-goal, not this item's to remove.
- No unresolved BLOCK carries in: epic block CLEAR, spec block DISPOSED, all three spec
  findings dispositioned.

Gate: DISPOSED (audit-F1, audit-F2, audit-F3, audit-F4)
```

```
## audit — 2026-09-10 — rev working tree over 78ea3b5

Point (re-derived): Hidden memories and the transcript stack are retired completely: no shipped command, agent, hook, installer path, installed pack surface, or durable description may keep the deleted capability alive, while user-owned files and configuration remain untouched. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Owner's Words, Success Criteria 1–2, and Next-Stage Handoff Item B; grade: owner]

Falsifier: upgrade or uninstall a prior Claude and Codex installation; a deleted memory/transcript capability remains invokable, hook residue survives, a user-authored hook is removed, or shipped documentation still advertises memory storage.

Findings:

- audit-F1 [DON'T] remains open: `scripts/uninstall-global.sh:68` still performs its own broad `/.claude/hooks/` filter instead of calling `cleanup_legacy_hooks`, and `scripts/test_uninstall.sh` still has no settings.json case. A fixture with a user-authored PreCompact command under `.claude/hooks/` loses that registration during uninstall. — source: `README.md` uninstall contract, "preserves user files" (INHERITED/aspirational) — disposition: DISPOSE-and-proceed; no FIXED resolution.
- audit-F2 [DO] remains open: `hooks` is still absent from the cleanup loops at `scripts/setup-global.sh:92` and `scripts/uninstall-global.sh:54`, and `scripts/setup-codex.sh` still has no sweep for removed managed skill directories or other absent top-level assets. A fixture legacy Claude hook symlink survives setup, while copied Codex `my-recall`, recall-agent, and hook assets have no removal route. — source: owner retirement obligation, with existing-install convergence inferred from `README.md` Updating guidance (AGENT/INFERRED) — disposition: DISPOSE-and-proceed; no FIXED resolution.
- audit-F3 [DO] remains open: `docs/STRUCTURE.md:64` still advertises "Memory storage structure" under what `project-pack/` becomes. — source: `docs/STRUCTURE.md` (INHERITED/aspirational) — disposition: DISPOSE-and-proceed; no FIXED resolution.
- audit-F4 [DON'T] remains open: `scripts/setup-codex.sh:367-382` still contains the hook-installation path for `dist/codex/hooks`, `hooks.json`, and `codex_hooks`, despite the build no longer producing those assets and the retired product surface having no hooks. — source: owner retirement obligation, with complete removal of this dormant generic installer path inferred from that obligation (AGENT/INFERRED) — disposition: DISPOSE-and-proceed; no FIXED resolution.

Smells fired:

- Smell 1 — two representations must be manually kept synchronized. The shared surgery in `scripts/lib/settings-hooks.sh` and the duplicate inline surgery in `scripts/uninstall-global.sh` remain divergent on preserving user-authored PreCompact hooks. Fires on audit-F1 and remains unresolved.
- Smell 6 — a test passes only because it selects one route. `scripts/test_global_setup.sh` tests the safe helper route, while `scripts/test_uninstall.sh` omits the unsafe uninstall route; both test scripts pass although uninstall destroys the protected user configuration. Fires on audit-F1 and remains unresolved.

Gate: DISPOSED (audit-F1, audit-F2, audit-F3, audit-F4)
```

```
## audit — 2026-09-10 — rev working tree over 78ea3b5

Point (re-derived): Hidden memories and the transcript stack must be retired completely: no pack instruction, shipped executable, installer path, or installed surface may preserve them, and agent-written knowledge must not live outside git. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Owner's Words and Success Criteria 1–2; grade: owner]

Falsifier: inspect every tracked executable installer, then exercise upgrade and uninstall fixtures; any route creates or retains `.claude/hooks`, `.project/memories`, a transcript tool, or a memory command, or removes user-owned configuration.

Findings:

- audit-F5 [DON'T] The tracked executable `scripts/init-project.sh.bak` still creates a `.claude/hooks` symlink and ensures `.project/memories` exists, so the shipped repository retains a second initializer that recreates both retired surfaces. — `.project/concepts/agent-knowledge-and-enforcement.md` Success Criteria 1–2 (owner) — falsifier: enumerate every tracked executable under `scripts/` and assert none contains `claude-pack/hooks`, `.claude/hooks`, or a `memories` project-directory initializer; the backup fails that assertion — disposition: BLOCK

Smells fired:

- Smell 6 — a test passes only because it selects one duplicate, one route, or one interpretation. `scripts/test_init_project.sh` exercises `scripts/init-project.sh` but ignores the tracked executable `scripts/init-project.sh.bak`, whose behavior contradicts the same retirement obligation. Fires on audit-F5 and escalates into the BLOCKED judgment.

Gate: BLOCKED (audit-F5)

Resolves:

- audit-F1: FIXED — authority: INHERITED — basis: global uninstall now calls the shared narrow cleanup helper, and its fixture proves the pack hook is removed while a user-authored PreCompact hook survives unchanged.
- audit-F2: FIXED — authority: AGENT — basis: setup and uninstall sweep legacy Claude hook symlinks, legacy vendored assets are removed by explicit name while user files survive, and repository history disproved the inferred Codex-residue premise.
- audit-F3: FIXED — authority: INHERITED — basis: the stale “Memory storage structure” description is deleted and a documentation regression assertion covers it.
- audit-F4: FIXED — authority: AGENT — basis: the dormant Codex hook installer and its `codex_hooks` path are deleted and guarded by the Codex pack test.
```

```
## audit — 2026-09-10 — rev working tree over 78ea3b5

Point (re-derived): Hidden memories and the transcript stack must be retired completely: the four memory commands, recall agent, hook and transcript tools, installed pack surfaces, and `example-rules.md` no longer exist, while user-owned files and configuration survive cleanup. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Owner's Words, Success Criteria 1–2 and 8, and Next-Stage Handoff Item B; grade: owner]

Falsifier: create an installation with the prior vendored pack, rerun `init-project.sh --include-claude`, and find any retired command, agent, hook, transcript tool, or rule still invokable, or any unrelated user file or hook removed.

Findings:

- audit-F6 [DO] The documented vendored-upgrade path leaves all four retired commands installed. `cleanup_legacy_vendored_files` removes the recall agent, example rule, and four hook files, but omits `_my_capture.md`, `_my_memorize.md`, `_my_recall.md`, and `_my_review_compact.md`; rerunning `init-project.sh --include-claude` skips those existing command files, so each remains invokable. The acceptance fixture makes the same omission while reporting that the vendored upgrade removes retired files. — `.project/concepts/agent-knowledge-and-enforcement.md` Success Criterion 2 and Next-Stage Handoff Item B (owner) — falsifier: seed a marked vendored install with all eleven retired copied files, rerun `init-project.sh --include-claude`, and assert every retired path is absent while unrelated user files remain — disposition: BLOCK

Smells fired:

- Smell 1 — two representations must be manually kept synchronized. The retired-path array in `scripts/lib/legacy-vendored-files.sh` and the acceptance list in `scripts/test_init_project.sh` duplicate the cleanup contract and have drifted together away from the owner's complete eleven-file list. Fires on audit-F6 and escalates into the BLOCKED judgment.
- Smell 6 — a test passes only because it selects one duplicate, one route, or one interpretation. The vendored-upgrade test checks seven retired files but omits the four retired commands, allowing the upgrade claim to pass while those commands remain installed. Fires on audit-F6 and escalates into the BLOCKED judgment.

Gate: BLOCKED (audit-F6)

Resolves:

- audit-F5: FIXED — authority: owner — basis: the tracked executable backup is deleted, and `scripts/test_init_project.sh` now rejects tracked script backups and scans every tracked non-test executable for code that recreates the retired hook or memory surfaces.
```

```
## audit — 2026-09-10 — rev working tree over 78ea3b5

Point (re-derived): Hidden memories and the transcript stack must be retired completely across shipped, upgrade, uninstall, and installed surfaces: the four memory commands, recall agent, hook and transcript tools, and `example-rules.md` no longer exist, while user-owned files and configuration survive cleanup. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Owner's Words, Success Criteria 1–2 and 8, and Next-Stage Handoff Item B; grade: owner]

Falsifier: seed a prior marked vendored install with all ten retired files plus a near-name user hook and a user-authored `_my_` command, rerun `init-project.sh --include-claude`, then uninstall; any retired file survives or either user file is removed.

Findings: None.

Smells fired: None. The upgrade fixture independently enumerates the fixed, closed ten-file retirement surface and now fails if the shared cleanup list omits any member; the near-name hook and user-authored command assertions cover the ownership boundary.

Gate: CLEAR

Resolves:

- audit-F6: FIXED — authority: owner — basis: the shared cleanup now removes all ten owner-retired vendored files, including the four commands previously omitted; the upgrade fixture seeds and checks all ten while proving a near-name hook and user-authored `_my_custom.md` survive.
```

```
## audit — 2026-09-10 — rev working tree over 78ea3b5

Point (re-derived): Hidden memories and the transcript stack must be retired completely across all four installer paths: both pack-written PreCompact registrations and every retired file are removed, while user-owned files and configuration survive cleanup. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Success Criterion 2 and Next-Stage Handoff Item B; grade: owner]

Falsifier: seed a marked vendored project with `.claude/settings.json` containing the retired `precompact-capture.sh` registration, run `uninstall-project.sh --force`, and find that registration still present after the retired hook file is deleted.

Findings:

- audit-F7 [DO] Project uninstall deletes the retired vendored hook file but leaves its pack-written PreCompact registration in `.claude/settings.json`. `uninstall-project.sh` never calls the shared settings cleanup, and its acceptance fixture seeds all ten retired files without seeding the project-local registration, so uninstall can report success while leaving a dangling hook that fires on later compaction. — `.project/concepts/agent-knowledge-and-enforcement.md` Success Criterion 2 and Next-Stage Handoff Item B (owner) — falsifier: the marked-vendored-project uninstall fixture above retains `.hooks.PreCompact` — disposition: BLOCK

Smells fired:

- Smell 6 — a test passes only because it selects one route. `test_uninstall.sh` proves global uninstall removes a PreCompact registration and separately proves project uninstall removes retired files, but never composes the project-uninstall route with its project-local registration. Fires on audit-F7 and escalates into the BLOCKED judgment.

Gate: BLOCKED (audit-F7)
```

```
## audit — 2026-09-10 — rev working tree over 78ea3b5

Point (re-derived): Hidden memories and the transcript stack must be retired completely across all four installer paths: both pack-written PreCompact registrations and every retired file are removed, while user-owned files and configuration survive cleanup. [source: `.project/concepts/agent-knowledge-and-enforcement.md` Success Criterion 2 and Next-Stage Handoff Item B; grade: owner]

Falsifier: seed a marked vendored project with retired and user-owned PreCompact commands plus unrelated settings, run `uninstall-project.sh --force`, and find the retired registration still present or user state changed.

Findings: None.

Smells fired: None. The project-uninstall fixture now exercises the composed route and a direct legacy-project probe confirms that only the retired registration and script disappear.

Gate: CLEAR

Resolves:

- audit-F7: FIXED — authority: owner — basis: project uninstall now calls the shared settings cleanup before deleting vendored files; the focused fixture and direct probe prove the retired registration is removed while the user hook and unrelated settings survive.
```
