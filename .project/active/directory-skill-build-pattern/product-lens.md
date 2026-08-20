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
