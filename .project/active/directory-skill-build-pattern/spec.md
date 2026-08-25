# Spec: Directory-Skill Codex Adapter

**Status:** Draft (revision 4)
**Owner:** Reid W
**Created:** 2026-08-20 10:24 · **Revised:** 2026-08-20 (rev 3 → rev 4, incorporating the cwd spike)
**Complexity:** HIGH
**Branch:** anchor-on-the-point
**Epic:** MENTAL-ALIGN-V2, **Item 5**

---

## Revision note

**Revision 1 → 2.** The epic was restructured so the skill got built on Claude first, which made
`claude-pack/skills/_my_mental_model/` this item's real test subject and pulled the allowlist entry
and the v1 wiring cleanup in. Then the owner reversed ADR 0010: skill directories now go through the
same Codex adapter as commands. Everything revision 1 inherited from 0010 — the no-rewriting rule,
byte-identical siblings, the decision not to widen the neutrality scan — was deleted rather than
qualified.

**Revision 2 → 3**, from `spec-review.md` (verdict Revise) and the owner walkthrough recorded in its
Resolutions:

- The working-directory premise flipped from a constraint to a **defect to fix**. Revision 2 treated
  "Codex runs a skill with the skill directory as cwd" as `[HARD]` and designed around it. The owner:
  the project directory is the correct behavior, so find out why it changes and prevent it.
- **Item 4 is Claude-only; this item owns all Codex adaptation.** That replaces revision 2's
  wording-not-behavior boundary, which was wrong.
- The gloss revision 2 attached to *"if the build fails, the build fails"* was an agent inference
  wearing an owner quote's authority. Deleted. No new failure conditions are added.
- `example-skill.md` is deleted rather than converted, which removes a `[NEED]`, a success criterion,
  and an open question.
- The phrase inventory stops claiming a count. Item 4 landed mid-session and grew `SKILL.md` from 98
  to 277 lines.

`design.md` is still revision 1 and now contradicts this spec in more places than before — its
byte-identical-siblings invariant, its "the generated `SKILL.md` is the only file the build rewrites"
decision, its `example-skill` decision (D7), and its flat-lane decision (D6, now settled by the
owner). It needs its own revision pass.

**Revision 3 → 4**, from `cwd-spike-findings.md`: the blocking working-directory premise was
disproved. Activating a Codex skill preserves the session working root. `-C/--cd` controls that
root, and the skill reaches siblings from the absolute `SKILL.md` path Codex supplies in its skills
inventory. The eight project-relative paths need no rewrite, and the shipped command-derived skills
do not share a defect. The earlier spike's B5 conclusion is corrected in place.

---

## Problem

A pack capability is a skill directory — an entry point plus the instruction and feedback files it
reads, shipped as one unit (ADR 0009, `[OWNER]`). The Codex lane ships one file out of it.
`build-codex-pack.sh:395` and `setup-codex.sh:267` both walk
`find … -mindepth 2 -maxdepth 2 -name 'SKILL.md'`, so siblings are dropped and a nested `feedback/`
directory is never even discovered. Claude symlinks the whole directory
(`setup-global.sh:126-134`), so it works there. Codex gets an entry point referencing files nobody
copied, with no error on either side. This matters because the split instruction files are the whole
repair for the failed v1 — an agent given the thinking job cannot see the rendering job only if the
two live in separate files that actually ship.

**Why ADR 0010's rule couldn't hold.** It required skill bodies to be written in runtime-neutral
language, because no translation pass existed for them. The first real skill has to state things that
differ per harness — where its own directory is, and how to spawn an agent that inherits the
conversation — so the requirement is unmeetable. Commands never hit this: a command is a single file
with nothing beside it, so no pack file had ever needed to locate itself. The command lane has
absorbed harness differences since it was written, through a substitution dictionary in
`sanitize_command_body_for_skill` (`build-codex-pack.sh:133-160`). The fix is to point that lane at
skill directories too, which is ADR 0011.

**The working-directory premise was false.** A controlled relative-write probe launched the same
Codex skill with two different `-C` roots. Each write landed in the selected launch root, and neither
landed in the skill directory. Skill activation does not change cwd. Codex supplies the selected
skill's absolute `SKILL.md` path in its skills inventory, which is how the skill reaches siblings
without coupling them to project-relative paths. The eight project-relative output paths therefore
remain correct, and the roughly thirty command-derived skills have no shared cwd defect. Evidence:
`.project/active/directory-skill-build-pattern/cwd-spike-findings.md`.

**The leftovers.** Epic Item 2 deleted the two v1 authored files; three references remain in the
tree: the path rewrite at `build-codex-pack.sh:138`, the shared-spec copy at `:426`, and the
description override at `codex-overrides/config.sh:37`. A fourth is the stale `README.md:131`
command-catalog row, which nothing catches any more — `test_docs.sh`'s completeness check stopped
requiring that row the moment the command file was deleted. `dist/codex/` is also deliberately
stale. Separately, `build-codex-pack.sh:338-365` is a second lane that turns a flat `.md` into a
working Codex skill while Claude registers nothing — the same one-sided silent failure, mirrored.

## Success Criteria

- [ ] Every file under an allowlisted skill directory reaches `dist/codex/skills/<name>/` and then
      `~/.agents/skills/<name>/`, at the same relative paths, nested directories included
- [ ] The Codex adapter runs over every file in the skill directory, not only `SKILL.md`
- [ ] **The skill's harness-specific inventory is re-derived from the files at execution time**, as
      exact source strings rather than paraphrases, and every entry is either a dictionary
      substitution or an edit to the skill. No count is fixed in advance
- [ ] `my-mental-model` runs on Codex end to end: it locates its own directory, reads
      `design_synthesis.md`, `visualize.md`, and both `feedback/` bodies, spawns a context-inheriting
      agent under carried policy, resumes that agent for the render, and **writes its run artifacts
      into the project** rather than into the installed skill directory
  - **[INFERRED] Resolved mechanism, 2026-08-20:** the live collaboration surface's
    `spawn_agent` accepts `fork_turns: "all"`; a digest-controlled probe confirmed that it carries
    completed parent conversation turns, while `fork_turns: "none"` does not. Material produced
    during the parent's still-running turn was not carried in this probe. Use the collaboration
    spawn for the synthesis agent. `codex exec resume` is a same-thread continuation after the
    active writer exits, not a concurrent worker. See `fork-spike-findings.md` and
    `fork-spike/evidence/`.
- [ ] The Codex comparison reports the missing per-agent token count honestly rather than estimating
      it (epic Item 1 found no supported source)
- [ ] `/_my_mental_model` on Claude does what it did before this item: locates its directory, the
      synthesis agent reads its instruction files, carried policy forks, and runs land in
      `.project/mental-alignment/runs/`. Most of the edited lines live in the file Claude reads live
      through the install symlink, so this item is editing a working capability
- [ ] The skill reaches Codex as `my-mental-model` — dist directory and generated frontmatter name
      both — and is present in the build rather than silently excluded from it
- [ ] Documents that still steer future work no longer cite ADR 0010 as live guidance; historical and
      append-only records keep their 0010 citations (see the `[OWNER]` item on supersession)
- [ ] The two false claims about Codex and symlinks are corrected — `build-codex-pack.sh:521` and
      `CLAUDE.md:53` — whichever install strategy is chosen
- [ ] Re-running either installer converges: added files appear, changed files update, files removed
      from the pack disappear from the target
- [ ] No v1 surface remains, and no script or test references one
- [ ] The existing suite passes: docs, pipeline-sync, adr, global-setup, codex-orchestrator-pack

## Known Requirements

**Owner decisions, 2026-08-20**

- **[OWNER]** Skill directories go through the same Codex adapter as commands, applied recursively
  over every file in the directory. Owner: *"it seems like the only good solution is just extending
  the same 'codex adapter' pattern from 'command' to 'skill'."*
- **[OWNER]** **This item owns all Codex adaptation; Item 4 owns none of it.** Owner: *"Item 4 is not
  going to worry about Codex whatsoever. Item 4's job is to ship a usable claude skill. that's it.
  Item 5 needs to figure out how to make it work for codex."* So the boundary is: this item does not
  change what the skill does on Claude, and does whatever it takes to make the same capability work
  on Codex — the phrase edits, the working-directory problem, the resumed-render path, and the token
  reporting all land here.
- **[OWNER]** **The project directory is the correct working directory for a skill run.** Owner:
  *"it SHOULD be this — moving to the skill directory would be really dumb. so yes, we need to run a
  small probe to figure out why it would be changing directories and how to prevent it."* The intent
  is to fix the cause, not to adapt the skill to it. The probe found no runtime change to prevent:
  the earlier command had selected the skill directory, while normal skill activation preserves the
  project/session root. See `cwd-spike-findings.md`.
- **[OWNER-VERBATIM]** *"if the build fails, the build fails"* / *"if the build doesn't fail, I find
  out when the skill fails."* Meaning: no tolerance is built for failure, and **no new failure
  conditions are added**. `NATIVE_SKILL_ALLOWLIST` stays opt-in and silent. Owner, on the inference
  revision 2 attached to this quote: *"when I said that I meant 'if it fails for any reason'. we are
  not adding more checks. … I am not here to try and catch a one-time issue — we will test it, find
  out, fix it."*
- **[OWNER]** No test enumerates harness-specific phrases, because a phrase you can list is one you
  would have already put in the dictionary. The detector is the skill failing on the runtime.
- **[OWNER]** Every harness-specific phrase in the skill is either captured in the dictionary or the
  skill is adjusted. Per-phrase choice is design's.
- **[OWNER]** `claude-pack/skills/example-skill.md` is **deleted**, not converted to directory form.
  Owner: *"delete it."* Consequences: the flat native-skill lane (`build-codex-pack.sh:338-365`)
  loses its only user and is deleted rather than guarded, and
  `scripts/uninstall-project.sh:109` drops its `example-skill.md` entry.
- **[OWNER]** ADR 0010 is superseded, not deleted — the log is append-only per ADR 0001 and `adr.sh`
  has no delete verb. Filed at spec time rather than deferred to execution, because 0010 stayed
  `active` while epic Items 3 and 4 ran and its reversed invariant was steering how they authored
  skill files (product-lens spec-F4): `.project/adr/0011-native-skill-codex-adapter.md`, provenance
  `[OWNER]`, 0010 now `status: superseded`. Re-pointing citations covers only documents that still
  steer future work. `0010` and `0011` themselves, the `INDEX.md` superseded row, `spike-findings.md`
  as a dated record, and every append-only `product-lens.md` block keep their 0010 references.

**Forced by the runtimes** (probes of 2026-08-20 —
`.project/active/directory-skill-build-pattern/spike-findings.md` and `cwd-spike-findings.md`)

- **[HARD]** Codex registers the frontmatter `name` and does not answer to the directory name (B3).
  Claude displays the directory name and accepts both (A4). So the Codex entry point must be
  regenerated with the derived name written into its frontmatter.
- **[HARD]** Claude runs a skill with the project directory as the working directory and prepends
  `Base directory for this skill: <abs path>` (A8). No relative path containing the skill's own
  directory name resolves on either runtime.
- **[HARD]** Codex skill activation preserves the session working root. A relative write lands in
  the directory selected at launch; `-C/--cd` is the supported CLI control. Codex includes the
  skill's absolute `SKILL.md` path in its available-skills inventory, so siblings are resolved from
  that locator rather than cwd. Two controlled runs and their raw JSONL are in
  `cwd-spike-findings.md` and `cwd-spike/evidence/`. This corrects the earlier B5 inference.
- **[HARD]** Codex silently refuses to register a skill whose `SKILL.md` is a symlink (B2). It does
  load a symlinked skill *directory* (B1) — which makes `build-codex-pack.sh:521` and `CLAUDE.md:53`
  ("Codex reads copies, not symlinks") false.
- **[HARD]** A skill directory absent from `NATIVE_SKILL_ALLOWLIST` (`codex-overrides/config.sh:58`)
  is excluded from the Codex build with no error. The check is keyed on the **pack-side** directory
  name (`build-codex-pack.sh:370`), so the entry must be the literal `_my_mental_model`.
- **[HARD]** Native skills take their Codex description from their own frontmatter; there is no
  override map (`build-codex-pack.sh:243-255`). A leading `*` crashes Codex's YAML parse, so the
  description must be plain prose.
- **[HARD]** A flat `.md` file in `claude-pack/skills/` never registers as a skill on Claude.
- **[HARD]** `setup-codex.sh`'s overwrite guard greps each file's first 20 lines for `Generated from`
  (`:19-22`). A file without that marker is classified user-authored and skipped from the second
  install onward.

**The harness-specific inventory — two classes, no fixed count**

As of 2026-08-20 the skill is `SKILL.md` (277 lines), `design_synthesis.md`, `visualize.md`, and two
`feedback/` bodies. `visualize.md` and `feedback/html.md` are clean. `design_synthesis.md:30` ("you
are a fork of the conversation") reads on both harnesses. Everything else is in `SKILL.md`, and it
splits into two classes that need different answers:

- **Vocabulary** — tool and parameter names, and sentences about how the harness hands the skill its
  own directory. Around a dozen spots as of Item 4's landing, including the base-directory sentences,
  `subagent_type: "fork"`, the `Agent` tool, `SendMessage`, and the `Read`-not-`cat` instruction.
  Item 4 handed over its own list at `.project/active/render-switch-feedback/harness-phrases.md`.
  These are what a dictionary is for.
- **Project-relative paths** — eight of them, `SKILL.md:51`, `:54`, `:66`, `:132`, `:134`, `:148`,
  `:231`, `:233`. They already resolve under the Codex session's project working root and need no
  adaptation. Sibling-file references are separate: Codex supplies the selected `SKILL.md` path,
  and the adapted instruction must resolve `design_synthesis.md`, `visualize.md`, and `feedback/`
  from that directory.

Both lists are stale the moment the skill is edited again, which is why the criterion above requires
re-deriving them at execution time, as literal strings.

**Absorbed from upstream**

- **[INHERITED]** Sibling copying must reach files nested inside subdirectories, not only flat
  siblings — the skill's `feedback/` directory is the case that breaks a flat walk.
  (`.project/concepts/mental-alignment-skill-design.md:252`.)
- **[INHERITED]** The `_my_x` → `my-x` mapping applies to native skills, for the dist directory and
  the generated frontmatter name. (ADR 0011 invariants;
  `.project/concepts/mental-alignment-skill-design.md:255`.) This is not tidiness — ship the native
  skill as `_my_mental_model` and two live commands break: `claude-pack/commands/_my_epic_plan.md:44`
  and `_my_concept_design_review.md:219` reference `/_my_mental_model`, which the command lane
  rewrites to `` `my-mental-model` `` (`build-codex-pack.sh:155-158`). Their Codex skills would offer
  the owner a name nothing answers to.
- **[INHERITED]** Codex can continue a completed spawned agent, so the resumed-render path exists
  there; the collaboration surface reports no per-agent token count.
  (`.project/active/codex-resume-spike/spike-findings.md`.)

## Non-Goals

- **Changing what the skill does on Claude.** Items 3 and 4 own its behavior. This item edits the
  skill only as far as Codex adaptation requires, and a Claude-side break introduced here is fixed
  here.
- Adding build-time checks or new failure conditions. Owner decision, above.
- A general-purpose detector for harness-specific phrases. Owner decision, above.
- Automated behavioral tests of the skill on either runtime. Verification is manual invocation.
- Deleting ADR 0010's file, or re-pointing historical and append-only records away from it.
- Migrating the remaining `_my_*` commands to skills, or relocating the prose specs out of
  `claude-pack/scripts/`. Deferred by ADR 0009's scope note.
- Widening the adapter to `claude-pack/rules/` or agents. `sanitize_rule_body_for_codex` already
  exists and is untouched here.

## Open Questions / Deferred to design

**Resolved by `/_my_spike`, 2026-08-20:**

- **A Codex skill run does not change the working directory.** The controlled probe answered all
  three questions: (1) a relative write lands in the `-C` launch root; (2) `-C/--cd` controls the
  session root, while supported skill metadata exposes no cwd field; and (3) Codex supplies the
  selected skill's absolute `SKILL.md` path, so the skill resolves siblings from its containing
  directory. The eight project-relative paths remain unchanged. No follow-up item is needed for the
  command-derived skills. See `cwd-spike-findings.md` and its raw `cwd-spike/evidence/`.

**The rest:**

- **Which files the adapter transforms.** Markdown only, or every text file? What happens to a script
  or a binary asset sitting in a skill directory.
- **Whether substitutions are global or scoped per source file.**
  `sanitize_command_body_for_skill` applies every rule to every body it processes. Stock vocabulary
  belongs there, but a one-off sentence from a single skill turns the dictionary into a patch table
  that fires on any body containing the string. That changes the shape of the answer, not just where
  the dictionary lives — so it pairs with the next question.
- **Whether the dictionary stays inline** in `sanitize_command_body_for_skill` or becomes a table
  both lanes read. Two hand-maintained copies of the same list, kept in step by nobody, is the
  failure mode to avoid (product-lens smell 1).
- **Where the `Generated from` marker goes.** If every transformed file carries it, the install's
  per-file guard works as-is. A non-markdown sibling can't carry a markdown marker, so a
  directory-granularity guard may still be needed for those.
- **Whether the existing dist scan survives** (`test_codex_orchestrator_pack.sh:336-338`). Its only
  defensible job now is confirming the adapter *ran*, not detecting phrases nobody listed. Note its
  regex matches `subagent_type=` with an equals sign while the skill uses the colon form, so exactly
  one current spot would trip it. Keep it with that narrowed job, widen it, or delete it.
- **Install strategy.** Copy mirror, or a whole-directory symlink from `~/.agents/skills/<name>` into
  `dist/`. The probe reopened the symlink option by falsifying the claim it was dismissed on; note
  that `dist/` is wiped at the start of every build (`build-codex-pack.sh:258`).
- **Ordering of the v1 wiring deletions.**

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (MENTAL-ALIGN-V2, Item 5)
- **Spec review:** `.project/active/directory-skill-build-pattern/spec-review.md` — verdict Revise,
  findings L1-1…L5-1 with owner resolutions; this revision incorporates it
- **Required Reading:**
  - `.project/active/directory-skill-build-pattern/spike-findings.md` — the packaging probes
  - `.project/active/directory-skill-build-pattern/cwd-spike-findings.md` — confirms Codex preserves
    the project working root and resolves sibling files from the supplied skill path
  - `.project/active/render-switch-feedback/harness-phrases.md` — Item 4's dictionary handoff
  - `.project/active/codex-resume-spike/spike-findings.md` — epic Item 1
  - `.project/concepts/mental-alignment-skill-design.md` — Distribution lane, Appendix
  - `.project/adr/0009-directory-skills-pattern.md`
  - `.project/adr/0011-native-skill-codex-adapter.md` — filed 2026-08-20, superseding
    `0010-native-skill-codex-lane.md` (now `status: superseded`)
- **Product-lens ledger:** `.project/active/directory-skill-build-pattern/product-lens.md`
  (spec revision 2 pass: DISPOSED, findings spec-F4/F5/F6)
- **Design:** `.project/active/directory-skill-build-pattern/design.md` (revision 1 — needs a
  revision pass; see the Revision note)

---

**Next Steps:** Revise `design.md` from this spec, then continue with `/_my_design`.
