# Spec: Execution Register, Write-Only

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-09-10 08:02
**Complexity:** MEDIUM
**Branch:** mental-model-reviewer

---

## Problem

Nothing records what an agent learned about this codebase or environment while executing. `.project/adr/` holds decisions, `.project/product/` holds implemented promises, `.project/feedback/ENTRIES.md` holds corrections to the pack's own prompts. The fourth subject — how the thing actually behaves, learned by doing — has no home, and three slots that gesture at it are all unowned: wrap-up's auto-memory step (deleted by Item 1), the `Lessons Learned` field in `completed/CHANGELOG.md`, and an "Any notable learnings" bullet in the `CURRENT_WORK.md` template.

The `Lessons Learned` field is worse than absent. Two of its five live sections are the literal `[TODO: Add lessons learned]`, and the owner removed the field outright: **[OWNER-VERBATIM]** 2026-09-09, "remove this. I do not want this at all." Leaving it in place while adding a register would give one command two homes for one subject in one run — the defect the epic's product-lens blocked on (epic_plan-F1, owner-dispositioned).

**Measured this session, and it reframes what the register is for.** The native memory store holds 71 files across ten other projects — 10 index files and 61 entries, typed by the harness as 23 `feedback`, 15 `project`, 5 `reference`, 1 `user`. Reading the 15 `project`-typed descriptions against the concept's execution-fact test: four are unambiguous execution facts (an MCP server timing out because its venv imports off `/mnt/c` NTFS; subagents registering only when launched from a particular directory; PDF-derived markdown carrying transcription errors in load-bearing numerals; script-driving gotchas), five are defensible environment facts, and six belong in registers this pack already has — two decisions with reasoning, one set of requirements, two research notes, one line of project context.

**[AGENT]** — the reframe in this paragraph is agent-derived and awaits owner disposition; see Open Questions. Nothing in the concept is falsified by that. The concept scoped its zero-count to this repo — **[INHERITED: `.project/concepts/agent-knowledge-and-enforcement.md`]** "the population of genuinely homeless execution facts in this repo is zero" — and named the caveat in the same sentence. What changes is the question the register answers. It is no longer *would agents save anything at all*, which the ten projects answer with "yes, roughly one to four per project over months." It is *when prompted, will agents file an execution fact in the right home at the right density* — and the answer turns on the boundary, because roughly half of what agents already saved belongs somewhere else.

Two facts make the boundary harder than the concept assumed, both carried here unresolved from Item 1 (`.project/active/retire-hidden-memories/spec.md` *Carried to Item 2*; `audit.md` *Surfaced*):

- **The native store regenerates and keeps competing.** It exists again at `~/.claude/projects/-home-rwestwood-agentic-project-init/memory/`, recreated empty by the harness after Item 1 deleted it. The harness instructs agents to write there every session, with a type vocabulary (`user`/`feedback`/`project`/`reference`) that overlaps three of the pack's four registers. No pack edit removes that instruction.
- **So concept SC1's headline is not reachable by pack edits alone.** Its operational body — "No pack instruction points at the native memory directory" — is satisfied and stays satisfied. Its headline, "No agent-written knowledge lives outside git," is not, and cannot be from inside the pack. Surfaced per capture-fidelity §4, dependent conclusions parked; this item does not resolve it and does not pretend to.

## Success Criteria

- [ ] An agent running `/_my_close` on a real item is prompted for an execution note exactly once, and either writes a conforming entry or reports that there was nothing to save.
- [ ] Nothing in the pack hands an agent the register's existing contents.
- [x] The register's instructions state the density bar with a worked good/bad pair, and name the native memory store as the wrong home.
- [x] `scripts/init-project.sh` seeds the register in a fresh project, and `--force` leaves an existing log untouched while refreshing the instructions.
- [x] `scripts/test_init_project.sh` covers both the seeding and the protection.
- [ ] `grep -rn "Lessons Learned" claude-pack/ project-pack/completed/ dist/ .project/completed/CHANGELOG.md` returns nothing.
- [x] The log ships with zero entries, in `project-pack/` and in this repo's `.project/`.
- [x] Every initialized project carries a triage prompt under `.project/` that the owner can reference directly to sort that repo's native memory entries into `.project/` homes, with a stated rule for what becomes a ticket in this repo and a provenance line on every entry the triage files.

## Known Requirements

- **[HARD]** The log file is listed in `USER_DATA_FILES` in `scripts/init-project.sh:122-127`. Without it, `--force` replaces accumulated entries with the empty template. This is the same forcing constraint the adjacent register hit, and the failure mode is written down at `scripts/test_init_project.sh:229-231`.
- **[HARD]** The instructions file is *not* user data, so `--force` propagates improved rules into existing projects. The two-file split exists for this reason and for no other.
- **[NEED]** The log ships with no entries. Nothing from the `Lessons Learned` sections is migrated into it, so every entry it ever holds was written by an agent that chose to write it. Owner decision, 2026-09-10: **[OWNER-VERBATIM]** "ok yeah option 1, ship empty." This amends the epic's Item 2 In-Scope line, which said content meeting the density bar migrates into the register before the sections are stripped.
- **[NEED]** The `Lessons Learned` field is removed outright — not repointed at the register, not reduced to a pointer. Owner, 2026-09-09: **[OWNER-VERBATIM]** "remove this. I do not want this at all." Three places: the instruction at `claude-pack/commands/_my_close.md:98`, the example at `project-pack/completed/CHANGELOG.md:19`, and the five live sections in `.project/completed/CHANGELOG.md`.
- **[NEED]** The write is prompted at `close`. Not in an always-on rule, and not left to owner prose. Source: concept Success Criteria 3-4 (owner), and the concept's recorded reason — the register with an unskippable write gate has 12 entries, the one triggered by owner prose has 0 (`.project/concepts/agent-knowledge-and-enforcement.md` Appendix A).
- **[NEED]** The register ships in `project-pack/` so it reaches every initialized project, not only this one. Source: concept Assumptions (owner) — this repo is a meta-project and a test confined to it measures the wrong thing.
- **[NEED]** The owner can run a memory triage in any repo without writing the instructions themselves. For each native memory entry, the triage decides which `.project/` home the fact belongs in — decision, promise, pack-prompt correction, or execution fact — files it there, and drops what carries no value. Owner, 2026-09-10: **[OWNER-VERBATIM]** "then we should provide a prompt that I can take to each individual repo to triage the memories and file them in `.project/`."
- **[NEED]** An entry that is genuinely important and fits no existing home becomes a new ticket in this repo. Owner, 2026-09-10: **[OWNER-VERBATIM]** "If there are any which guinely don't fit elsewhere but are still important, that turns into a new ticket for this repo." The reasoning it encodes: a fact with no home is evidence of a missing home, and the homes are pack concerns, so the finding belongs in the pack's backlog rather than in the repo that surfaced it.
- **[NEED]** The triage prompt ships as a generic template seeded into every project's `.project/`, and is used by direct reference rather than by any command or skill. Owner, 2026-09-10: **[OWNER-VERBATIM]** "`triage-prompt.md` should just be a generic file which gets unpacked, somewhere under `.project/`", "it needs direct reference to get used", "it is really one-time, so not worth muddying the skills folder." It is not user data, so improved instructions reach existing projects on `--force`.
- **[INFERRED]** A triage-filed entry names its provenance — migrated from the native memory store, with the date — so the log stays readable as evidence. Without it, owner-curated migrations and agent-written entries are indistinguishable, and the register's contents no longer answer what agents chose to save.
- **[INFERRED]** (ratified by owner, 2026-09-10: "agreed") The register is `.project/execution/`, two files: `README.md` for the rules, `ENTRIES.md` for the log. It mirrors `.project/feedback/` exactly, so an agent that has seen one knows the shape of the other.
- **[INFERRED]** (ratified by owner, 2026-09-10: "that looks good") The density bar is stated with a worked good/bad pair, in the shape `.project/adr/README.md:16-30` uses. The approved draft, to be carried into the README with wording changes only for fit:

  > **What gets an entry — the density bar**
  >
  > An entry exists only if a future agent doing similar work would otherwise spend real time rediscovering it.
  >
  > - **Good:** "The MCP server times out on startup because its venv imports off `/mnt/c` NTFS. Use a venv on native ext4." Cost real time, invisible in the code, still true next month.
  > - **Good:** "Markdown extracts of the P&IDs may carry transcription errors from low-res PDF rendering. Verify against the PDF whenever a numeral is load-bearing." A property of the data, not of the code.
  > - **Bad:** "The v1 data campaign is superseded; v2 locked envelope clipping option A." That is a decision with reasoning behind it. It goes in `.project/adr/`.
  > - **Bad:** "This repo is a personal workspace, not a shared team repo." Project context, not learned by doing. It belongs in `CLAUDE.md`.
  > - **Bad:** "I graded every constraint the owner mentioned as a requirement; only the ones they stated should have been." That is a correction to a pack prompt. It goes in `.project/feedback/ENTRIES.md`.
  > - **Bad:** "`--force` never overwrites a project's accumulated entries." That is a promise the pack makes. It goes in `.project/product/`.

  The last two were raised by the product-lens (spec-F2) and ratified by the owner 2026-09-10: **[OWNER-VERBATIM]** "I'm good with those examples." The first four guarded `.project/adr/` and `CLAUDE.md`; they left the two homes an agent is measurably most likely to mis-file into unguarded. Feedback is the largest measured mis-file class in this spec's own evidence: 23 of the 61 native entries are `feedback`-typed, against 0 in `.project/feedback/ENTRIES.md`.

- **[NEED]** Entries are appended and never rewritten, so the owner sees what the agent originally wrote in a diff. Owner, 2026-09-10: **[OWNER-VERBATIM]** "Yes, append-only is a requirement." Upstream authority, unchanged: concept *Why This Shape*, "the register is git-tracked, append-only, and owner-promoted," resting on the inherited owner-verbatim **[INHERITED: `.project/concepts/mental-alignment-checkpoint.md:369`]** "I need git tracking. 95% of the time the feedback an agent writes is REALLY bad and needs a revision to be generalized and useful." The adjacent register carries the same rule as an explicit requirement (`.project/feedback/README.md`); relying on "mirrors `.project/feedback/`" to imply it was the gap the product-lens found (spec-F3), now closed at owner grade.
- **[INFERRED]** The instructions guard the boundary against all four neighbouring homes, not a subset. The concept's Key Concept 1 defines four subjects "each with a boundary test against its neighbour" and its US-2 asks that an agent tell in one read which of them a fact belongs to; instructions that name only some of the neighbours cannot deliver that. Source: product-lens spec-F2.
- **[INFERRED]** The examples above are reworded from real entries in the native memory store. They are examples in the instructions file, never entries in the log — which is what keeps them consistent with shipping empty.
- **[INFERRED]** The instructions file states the boundary against the native memory store in one line: execution facts go in the register, not in the memory directory. This is the only countermeasure available to the pack against a harness instruction it cannot remove, and it is honest about being partial.
- **[INFERRED]** The instructions file states plainly that nothing reads the log. Source: concept Key Concept 3 — the write-only shape is the experiment, not an unfinished feature, and an agent should not go looking for a reader.
- **[INFERRED]** The close beat mirrors the existing ADR and promise beats: a scan in Step 2, candidates surfaced in Step 3's confirm, the write in Step 4b. "None found" is a normal outcome and the beat is never a gate — the promise scan at `claude-pack/commands/_my_close.md:50-53` says so in as many words, and this beat is weaker, not stronger.
- **[INFERRED]** Nothing is written to the log to record that there was nothing to save. The confirm step reports it, the same way the decision and promise scans report "none found."
- **[INFERRED]** The entry's tag is one whitespace-delimited token on the heading line, so a future line-oriented filter needs no markdown parser. Inherited constraint from the adjacent register (`.project/completed/20260826_feedback-capture-file/spec.md` Success Criteria), which cost nothing there and costs nothing here.
- **[INFERRED]** The register directory is created in this repo's `.project/` as well as in `project-pack/`, with an empty log.
- **[INFERRED]** `README.md` and `project-pack/README.md` gain the register in their register lists and directory trees, beside the entries the feedback register already has at `README.md:27`, `README.md:276`, `project-pack/README.md:60`, and `project-pack/README.md:84`.
- **[INFERRED]** Removing the field from `project-pack/completed/CHANGELOG.md` reaches newly initialized projects only. That file is protected user data (`completed/CHANGELOG.md` in `USER_DATA_FILES`), so `--force` never rewrites an existing project's changelog and no migration is written for one. What propagates to existing projects is the instruction in `_my_close.md`, which is enough: they stop accruing the field.
- **[INFERRED]** The Codex pack is rebuilt so `dist/codex/skills/my-close/SKILL.md` carries the new beat and drops the removed field.

## Non-Goals

- **Any read or discovery path.** Owner decision, carried from the concept: the write ships alone so its contents can decide whether a reader is worth building.
- **The `wrap_up` write beat.** Item 3 owns every change to `_my_wrap_up.md`. Concept SC4 asks for beats at both `close` and `wrap_up`; only the `close` half lands here, which means the measurement is not complete until Item 3 ships.
- **Ids, a lifecycle script, or a generated index.** The inherited standard for the adjacent register was a file with a header. Revisit only if the test earns it.
- **Agent-backfilled entries.** The pack template and this repo's log ship empty, and no agent seeds either from existing knowledge — including the `Lessons Learned` content. The owner-run triage is a deliberate exception at owner grade (2026-09-10) and is not agent backfill: it files owner-reviewed facts into other repos' logs, each carrying the provenance line above. Amends the epic's Item 2 non-goal, which excluded backfilling outright on the grounds that a seeded log would corrupt the result; the provenance line is what preserves the result instead. The epic's F1 disposition carried the clause "nothing real is deleted without a home," and it is discharged rather than waived: of the five live sections, the one that meets the density bar — separate refreshable instructions from append-only user data — is already recorded as the Test 8 comment at `scripts/test_init_project.sh:229-231`, which this spec's own `[HARD]` requirement cites; two are the literal `[TODO: Add lessons learned]`; two are retrospective taste notes below the bar.
- **Reading the other 61 native memory entries properly.** The 15 descriptions read this session were enough to ground the density bar. A full read is a research item about accumulated memory, not a blocker on shipping the register.
- **Deleting the ten other projects' native memory directories.** Item 1 scoped this out and it stays out; the store regenerates anyway, so cleaning it is not a one-time act.
- **The `## Lessons Learned (Post-Completion)` section in `epic_template.md`.** A different artifact with a different purpose — an epic retrospective, not close's per-item CHANGELOG field. The owner's removal was aimed at the field. This is why the success-criterion grep is scoped to `project-pack/completed/` rather than all of `project-pack/`, correcting the epic's Item 2 done-state grep, which as written could never pass.
- **The feedback register's trigger.** The 23 `feedback`-typed entries agents wrote into the hidden store, against 0 in `.project/feedback/ENTRIES.md`, are evidence that the trigger is the problem rather than the home. Real, and not this item's subject.

## Open Questions / Deferred to design

- **The entry format's fields.** The tag-plus-date heading and the parseability constraint are settled above. What the body carries is not. The concept's US-1 asks for "a provenance line," which suggests two fields — the durable fact, and how it was learned — against the adjacent register's three (Wrong / Right / Learning). Draft to review: `## [tag] YYYY-MM-DD`, then **Fact** (the durable statement) and **Evidence** (the run, error, or `file:line` that produced it).
- **What the tag names.** For the feedback register it is a pack target, drawn from a closed vocabulary. An execution fact has no equivalent closed set — candidates are the surface it concerns (`init-project.sh`, `flow-mcp`), or the work item that produced it. The first is more useful to a future reader and harder to validate.
- **~~The delivery form of the triage prompt.~~** Resolved by the owner 2026-09-10: a generic template under `.project/`, seeded by the installer, used by direct reference. Not a command and not a skill. What remains for design is only where under `.project/` it sits and how it avoids restating the register's four-way boundary test.
- **The reframe in the Problem section** — that the register's question narrows from *would agents save anything* to *right home, right density, when prompted*. Agent-derived from 15 one-line descriptions, marked **[AGENT]**, still unratified. Its evidence route changed: the owner-directed triage reads every entry in every repo and files it, which answers *what would they save* far better than the register's own contents ever would. So the triage's results either confirm or correct this paragraph, and nothing downstream should treat it as settled before then.
- **Concept SC1's headline against the regenerating native store.** Surfaced above, not resolved here. Whatever closes it is not a pack edit.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_knowledge_homes.md` — Item 2 of KNOWLEDGE-HOMES
- **Required Reading:** `.project/concepts/agent-knowledge-and-enforcement.md`, `.project/feedback/README.md`, `.project/completed/20260826_feedback-capture-file/spec.md`
- **Upstream item:** `.project/active/retire-hidden-memories/{spec,audit}.md` — the two facts carried here unresolved
- **Product lens:** `.project/active/execution-register/product-lens.md`
- **Design:** `.project/active/execution-register/design.md`
- **Plan:** `.project/active/execution-register/plan.md`

---

**Next Steps:** Design and plan are drafted. Implementation runs from `plan.md`.
