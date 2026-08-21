# Product-Lens Ledger — directory-skill-build-pattern

Append-only. Newest block at the bottom.

Epic: MENTAL-ALIGN-V2 (`.project/backlog/epic_mental_alignment_skill.md`) — epic gate at
authoring: **CLEAR** (epic_plan block, `Findings: none`). Ship gates and audit resolve this
reference against the epic's live gate, not against this line.

---

## spec — 2026-08-20 — rev `.project/active/directory-skill-build-pattern/spec.md` (untracked, branch `anchor-on-the-point`)

Point (re-derived): A pack capability **is** a skill directory (`SKILL.md` + siblings), installed on Claude as one symlink and reaching the Codex build and install **with all of its files**, under the `my-<name>` mapping of its `_my_<name>` directory; the allowlist is opt-in and silently drops anything absent from it. [source: `.project/adr/0009-directory-skills-pattern.md` (active, `[OWNER]`) + `.project/adr/0010-native-skill-codex-lane.md` (active, `[AGENT]` ratified by owner 2026-08-20), grade: owner/`[HARD]` for the shape and install, agent/ratified for the Codex lane]

Falsifier: The point is violated if, after this item, either (a) a capability's non-`SKILL.md` files can go missing on one runtime without a test failing, or (b) the *wrong* shape still installs successfully on either runtime, or (c) an obligation the epic assigned to Item 2 is exercised by no item at all.

Findings:

- **spec-F1 [DO]** The spec leaves the flat-skill build lane with no disposition. `build-codex-pack.sh:365` is a **second native-skill lane** (`find claude-pack/skills -maxdepth 1 -type f -name '*.md'`) that is how `example-skill.md` reaches `dist/codex/skills/example-skill/SKILL.md` today — verified present in `dist/`. Converting `example-skill` to directory form removes that lane's only user in the pack, but the lane survives, allowlist-checked and functional. After this item a future author who drops a flat `.md` into `claude-pack/skills/` gets a **working Codex skill and a dead Claude skill** — the same silent per-runtime asymmetry the spec's own Problem section names as the danger, in the mirror direction. This directly undercuts SC4 ("a future author copying it gets the right shape"): the wrong shape still builds clean. The spec's Problem section does not mention this lane, and no Open Question asks whether it stays. It is also smell-1-shaped (two representations of "how a native skill reaches Codex", kept in step by hand). — `scripts/build-codex-pack.sh:335-365` against ADR 0009's shape decision (`[OWNER]`) — grade: `[AGENT]`/`[INFERRED]` (ADR 0009 decides the shape, not that the build must reject the old one) — disposition: **add the flat lane to Open Questions or to Non-Goals with a stated reason** (remove it, or keep it and guard it). Falsifier: add `claude-pack/skills/zz-flat-probe.md` + its allowlist entry, run the build — a `dist/codex/skills/zz-flat-probe/SKILL.md` appears while Claude registers nothing.

- **spec-F2 [DO]** The allowlist opt-in step is exercised by no item and handed to none. `example-skill` is **already** in `NATIVE_SKILL_ALLOWLIST` (`codex-overrides/config.sh:59`), so owner decision 2 means Item 2's proof never performs an allowlist addition — the third of ADR 0010's three named Codex changes, and one of the two "adjacent gotchas this record preserves" (silent exclusion). The spec captures the fact as `[HARD]` and re-states the three changes as `[INHERITED]`, but no Success Criterion covers it, and the directory lane keys the check on the **pack-side** directory name (`build-codex-pack.sh:390`, `contains "$base"`), so Item 4 must add the literal `_my_mental_model` — not `my-mental-model`. Epic Item 4's In Scope does not mention the allowlist; it assumes Item 2 created the directory. This is the epic obligation the supersession leaves uncovered. — `.project/adr/0010-native-skill-codex-lane.md` + `.project/backlog/epic_mental_alignment_skill.md:166` — grade: **agent/ratified** — disposition: **record the forward handoff** (one line in the spec's Non-Goals naming the allowlist entry as Item 4's, and grow Item 4's In Scope to match) — nothing else needed here. Falsifier: create the real skill directory without the allowlist entry; the build exits 0 and the skill is absent from `dist/`.

- **spec-F3 [DO]** The `/_my_*`-resolves-to-a-directory-skill proof is now owned by no item. The design's unowned proof #3 and the epic's **High** risk both put it on Item 2 ("verified at first invocation after install"); under decisions 1 and 2 the live probe invokes `example-skill`, which has no `_my_` prefix. The spec substitutes a `[HARD]` runtime read establishing that underscores are *legal* skill names (`claude-code 2.1.237`) — that covers legality, not resolution. The Open Question parks only the **name-mapping** proof to Item 4, not this one. Codex-side live behavior likewise shrinks to file presence (SC1); no criterion has the skill load and read a sibling on Codex, which epic Item 2's In Scope asked for (its Done state did not, so this half is minor). — `.project/concepts/mental-alignment-skill-design.md:211`, `.project/backlog/epic_mental_alignment_skill.md:362` — grade: `[AGENT]` (the design and epic are agent-authored; ADR 0009's "slash invocation is preserved" is `[OWNER]` but this spec performs no migration, so it is not contradicted) — disposition: **name the deferral explicitly** — either take the tmpdir-fixture branch of the existing Open Question and extend it to cover resolution as well as mapping, or state in Non-Goals that the first `/_my_*` directory-skill invocation is Item 4's proof and re-point the epic's High risk at Item 4.

Smells: none fired. The frontmatter-`name`-vs-directory-name duplication (`build-codex-pack.sh:375` reads frontmatter first, but Claude requires name == directory) is smell-1-shaped; the spec correctly parks it as an Open Question for design rather than baking a shape in, so it is a watch item, not a fired smell. spec-F1's flat lane is the one place that duplication is already live in the tree.

Gate: **DISPOSED** (spec-F1, spec-F2, spec-F3)

Notes on the three owner decisions, so they are not re-litigated: all three are correctly recorded and correctly graded — decisions 1 and 2 as `[NEED]` with owner attribution and date, decision 3 as a Non-Goal exercising the choice ADR 0010 explicitly left to spec ("Whether to widen the scan is a spec-level follow-up"). None of them is a finding. The spec is also **stronger** than epic Item 2 in two places the epic never named: the sibling regression check (SC5) and the stale `~/.claude/skills/example-skill.md` symlink cleanup (SC6).

### Dispositions (spec author, 2026-08-20)

- **spec-F1 → accepted, raised to a design decision.** The flat native-skill lane
  (`build-codex-pack.sh:335-365`) loses its only user when `example-skill` converts. Whether it is
  deleted or kept-and-guarded is now an explicit design decision (design.md, D6) rather than an
  Open Question, because the answer changes what the build does. Spec Open Questions gains the
  pointer.
- **spec-F2 → accepted as recorded.** The allowlist entry for `_my_mental_model` is Item 4's step,
  now stated in the spec's Non-Goals as a forward handoff, keyed on the **pack-side** directory
  name. Epic Item 4's In Scope needs a matching line — flagged to the owner, not edited here.
- **spec-F3 → accepted as recorded.** The first live `/_my_*` directory-skill invocation is Item
  4's proof, now stated in the spec's Non-Goals. A tmpdir build fixture cannot prove slash
  resolution (that needs an installed skill in a live session), so extending the fixture would not
  have covered it. The epic's High risk needs re-pointing at Item 4 — flagged to the owner.
  Item 2 keeps the weaker but real evidence: underscores are legal skill names, and a
  directory-form skill resolves and reads a sibling (proven with `example-skill`).

### Follow-up: epic restructured, both handoffs landed (2026-08-20, same day)

The owner reordered the epic after these dispositions were written: this item moved from first to
last, and the skill itself is now built and proven on Claude before any packaging work. Item
numbering changed — this item is **Item 5**, not Item 2. The two forward handoffs above are no
longer outstanding:

- **spec-F2 resolved.** The `_my_mental_model` allowlist entry is now in *this* item's scope, stated
  in the spec's "Added to scope by the restructure" section and in the epic's Item 5 In Scope, keyed
  pack-side. It is also guarded by a manifest assertion in the design's Validation section, so
  omitting it fails a test instead of failing silently.
- **spec-F3 resolved.** The `/_my_*` slash-resolution proof is owned by epic Item 3, which creates
  the real directory and invokes it; the epic's risk table is re-pointed there. Item 3's done-state
  additionally requires recording the working form of a sibling reference.

Consequence for the design, recorded so a later reviewer sees it was deliberate: decision **D5**
(parameterize the build's roots so a tmpdir fixture pack could prove the name mapping) is now
**rejected** — the real skill exercises the mapping and the nested copy every build, so the fixture
duplicated its subject. **D7**'s rationale narrowed from "the throwaway proof subject" to "the
pack's copyable example, plus retiring known dead weight," and is droppable at the owner's
discretion. Gate unchanged: **DISPOSED**.

---

## spec — 2026-08-20 — rev `.project/active/directory-skill-build-pattern/spec.md` (revision 2, untracked, branch `anchor-on-the-point`)

Point (re-derived): One authored pack capability — `claude-pack/skills/<name>/`, an entry point plus the files it reads — reaches **both** runtimes with all of its files and resolves under its invocation name there, with the user seeing no change from the command era. [source: `.project/adr/0009-directory-skills-pattern.md` (active, `[OWNER]`) invariants 1-3; Codex half from `.project/concepts/mental-alignment-checkpoint.md` Assumptions (`[INHERITED: docs/STRUCTURE.md]`) and the concept's `[OWNER-VERBATIM]` "keep `/_my_mental_model` as the user-invoked command/skill (identical in functionality)"; grade: **owner** for the shape, the one-symlink Claude install, and users-see-no-change; **INHERITED** for Codex parity as such]

Corollary (my inference, graded as such): a failure of that delivery must be loud. Every hazard this lane has produced is silent — allowlist omission excludes with no error (ADR 0010 gotchas), Codex refuses a symlinked `SKILL.md` silently (spike B2), a frontmatter/directory name mismatch errors on neither harness (A4/B3), `cat feedback/x.md` works on Codex and fails on Claude (spike finding 2), the flat lane builds a Codex skill Claude never registers (design D6). [grade: `[AGENT]`/`[INFERRED]`]

Falsifier: The point is violated if, after this item, (a) a criterion is satisfiable while one runtime gets a partial or non-resolving install, (b) the item's own edits can silently degrade the runtime that was already working, (c) a recorded decision is changed with no owner-visible supersession, or (d) a test enumerates harness-specific phrases (owner-rejected, 2026-08-20).

Findings:

- **spec-F4 [DO]** The ADR 0010 supersession is scheduled as work *inside* this item, so the reversed record stays `status: active` for the whole interval — and that interval contains epic Items 3 and 4, which run first and author skill body files. Epic Item 3's In Scope currently tells its author to write bare-filename prose because that "is what keeps Item 5 from needing a rewrite pass it is forbidden to have (ADR 0010)" (`.project/backlog/epic_mental_alignment_skill.md:293`). A live record the owner has reversed is therefore still steering the authoring rule for the two items that execute next. The write point is now, not at execution: the lens files a record when a finding is disposed as an intended contract change, at spec among its four touch points. — `.project/adr/0005-*.md` (active-binding, `[AGENT]` ratified 2026-08-05) for the timing, `.project/adr/0001-*.md` (active, `[OWNER]`) for the append-only record — grade: **agent/ratified** — disposition: **file the record now**, `.project/scripts/adr.sh new <slug>` then `adr.sh supersede 0010 <new-id>` with owner-ratified provenance (not a default `[AGENT]` entry); this spec's SC6 and Related Artifacts then cite the new id, and Item 3's line 293 rationale is corrected in the same pass. Falsifier: read `.project/adr/INDEX.md` at any point during Items 3-4 — 0010 lists as active and its runtime-neutrality invariant reads as binding.

- **spec-F5 [DO]** No criterion guards the runtime that already works. Six of the seven listed spots are Claude-runtime instructions in `claude-pack/skills/_my_mental_model/SKILL.md` — the file Claude reads **live**, since the Claude install is a symlink to the pack directory. SC4 permits resolving any of them by "rewritten in the skill", so this item edits a proven capability, and no success criterion re-verifies it: SC3 tests Codex only, SC10's suite (docs, pipeline-sync, adr, global-setup, codex-orchestrator-pack) never invokes the skill, and Non-Goals asserts these edits "change wording, not behavior" without anything checking. The coupled trio the spec itself flags — `SKILL.md:14` and `:62,64`, how the coordinator learns its own directory and the path template that consumes it — is exactly where a wrong Claude-side rewrite means the synthesis agent cannot find `design_synthesis.md`. That is falsifier (b): the item exists to remove one-sided silent failure and currently permits it in the Claude direction. — `.project/concepts/mental-alignment-checkpoint.md` (`[OWNER-VERBATIM]` "identical in functionality") and `.project/adr/0009-*.md` invariant 3 ("users see no change"), concrete observable at `.project/backlog/epic_mental_alignment_skill.md:106` — grade: **owner** (omission, not contradiction — DISPOSE-and-proceed per §2, but the strongest of the three) — disposition: **add a Claude-side success criterion** mirroring SC3 — after the phrase work, `/_my_mental_model` on Claude still locates its directory, reads `design_synthesis.md` and `feedback/synthesis.md`, and forks under carried policy. Falsifier: run a carried-policy request on Claude after the edits; the coordinator spawns a non-inheriting agent or the synthesis agent cannot read its instruction file, and nothing in the done state notices.

- **spec-F6 [DO]** SC6 requires the successor record to *exist*, not to *establish* anything. ADR 0010 was filed to stop a future skill author getting the Codex seam wrong; the reversal inverts that hazard rather than removing it — an author may now write harness-specific phrasing, and the failure mode becomes a phrase the dictionary does not know, shipping clean and surfacing only when the skill runs on Codex. The spike already flagged the sibling-reference convention as "new, not covered by any current decision — needs to land somewhere" (`spike-findings.md`, "What this changes in the design"), and the reversal changes what that convention should even be, since the adapter can now rewrite `{base_directory}/…`. As written SC6 is satisfiable by a record that voids 0010 and leaves the authoring rule homeless — reopening the gap 0010 closed. — `.project/adr/0001-*.md` (`[OWNER]`: decisions *and the contracts and invariants they establish across major seams* are recorded) and `.project/adr/0009-*.md` (`[OWNER]`: `_my_mental_model` "sets the shape for the rest") — grade: `[AGENT]`/`[INFERRED]` resting on owner-grade sources — disposition: **state what the successor must establish** — where harness-specific phrasing is permitted in an authored skill body, that the dictionary is its translation home, and that an unlisted phrase surfaces only at Codex runtime. Falsifier: a future author adds a directory skill, writes a Claude-specific phrase, and finds no record telling them the dictionary exists.

Smells: **smell 1 fires** — an authored skill body's harness-specific phrasing and the adapter's substitution dictionary are now two representations kept synchronized by hand, with nothing checking. Escalated, and **disposed by owner decision** (2026-08-20: "if we knew what they were, they would already be in the dictionary" / "if the build doesn't fail, I find out when the skill fails"). Not re-litigated; it is the reason spec-F6's successor record has to name the dictionary as the other half of the coupling. The spec independently names a second smell-1 instance — one dictionary shared by two lanes — and correctly parks it as an Open Question. **Smell 7 does not fire:** the reversal moves the runtime-neutrality obligation from the skill author to the build adapter, and the Problem section says so in as many words.

Gate: **DISPOSED** (spec-F4, spec-F5, spec-F6)

Resolves:
- spec-F1: **DEFERRED** — authority: this spec — basis: the flat native-skill lane is now named in the Problem and carried as an Open Question ("delete it, or keep it and make it fail loudly"); still open, still visible.
- spec-F2: **FIXED** — authority: this spec — basis: SC5 requires the skill to be "present in the build rather than silently excluded", and the `[HARD]` entry keys the allowlist on the literal pack-side `_my_mental_model`.
- spec-F3: **DEFERRED** — authority: owner (epic restructure, 2026-08-20) — basis: the first live `/_my_*` directory-skill invocation is epic Item 3's proof; the epic's risk row is re-pointed there.

Not findings, recorded so they are not re-litigated:
- The ADR 0010 reversal and the no-enumerating-test decision are owner-originated and correctly captured — decision 1 as `[OWNER]` with the quote, "if the build fails, the build fails" as `[OWNER-VERBATIM]`, the test rejection as `[OWNER]` with its reason. The accepted detection posture (manual Codex invocation; the skill failing is the detector) is an owner decision, not a gap.
- Every load-bearing citation I checked is accurate: the directory-skill lane at `build-codex-pack.sh:392-395` emits the body through `strip_frontmatter` with no sanitizer call; the flat lane is `:338-365`; `:370` keys the allowlist on the pack-side directory name; `:386` writes the frontmatter name; `:138` is the v1 path rewrite; `setup-codex.sh:267` installs `SKILL.md` only; the dist scan's regex does include `` `Agent` tool ``, so `SKILL.md:77-78` would trip it today.
- The seven-spot table is accurate **and** complete: a grep of the whole skill directory returns exactly those spots, `design_synthesis.md:30` as the only sibling hit, and `feedback/synthesis.md` clean — as the spec claims.
- `show-me`, the other allowlisted directory skill, contains no phrase the dictionary matches, so widening the adapter is a no-op on it. Checked, not a finding.
