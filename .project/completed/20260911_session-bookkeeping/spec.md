# Spec: Session Bookkeeping

**Status:** Implementation In Progress (Phases 1-4 complete; Phase 5 is the behavioral pass)
**Owner:** Reid W
**Created:** 2026-09-10 14:15
**Complexity:** MEDIUM
**Branch:** mental-model-reviewer

---

## Problem

`/_my_wrap_up` is the pipeline's only session-end stage, and it currently spends that position on the wrong things. It is optional — `claude-pack/rules/workflow-accountability.md:30-31` suggests it, and ADR 0002 treats it as skippable — which bounds what this item can promise. It sends the agent into `docs/` to update architecture, command, and operations documentation from a session summary — **[OWNER-VERBATIM]** "this encourages slop on documents that are valued to stay tight (unlike \"feedback\" and \"changelog\" which are cheap record). changes to docs happen through the work item lifecycle." It commits without being asked (`claude-pack/commands/_my_wrap_up.md:60-66`). And its stated purpose still routes session learnings at `CLAUDE.md` and `.claude/rules/` (`:14`), a home the owner ruled out at owner grade — **[OWNER-VERBATIM]** "Agents tend to be REALLY BAD at what is worth saving for memories. especially execution facts. so I definitely DON'T want them writing to CLAUDE.md directly." That last one is carried unresolved from Item 2, which named it as this item's to fix (`.project/completed/20260910_execution-register/design.md` Non-Goals; `design-review.md` m7).

The read side has the matching problem. `.project/CURRENT_WORK.md` is the first file every session reads, and 113 of its 241 lines are history: a `Recently Completed` section holding 15 entries back to 2025-12-30, and a `Session Notes` section whose newest entry is from June. The template carries both, plus an "Any notable learnings" bullet (`project-pack/CURRENT_WORK.md:35`) that no command mentions. Nothing in the pack says when any of it should be trimmed; it has been trimmed once in eight months, by a wrap-up acting on its own.

Deleting the history sections costs something real, and the reason to keep them is owner-stated: **[OWNER-VERBATIM]** "the reason for including \"Recently Completed\" is that reading it gives a better picture of the state of things. Knowing we just edited something or closed out an epic could be super helpful context." So the completion history has to survive the cut somewhere the boot read can reach at a cost that does not grow as the archive does. `completed/CHANGELOG.md` already holds that history in a richer form, written by `/_my_close`.

Finally, work that never becomes a tracked work item leaves no trace in the project record at all. It does not reach `close`, so it does not reach the CHANGELOG, so a cold agent cannot see it. `/_my_wrap_up` is the only stage positioned to catch it.

## Success Criteria

- [ ] A fresh session's boot read names the most recent completed work through the standard session-start reads alone — without browsing item folders under `completed/` and without running `git log` — and its cost is the same whether the CHANGELOG holds 7 entries or 70.
- [ ] `/_my_wrap_up` writes no file under `docs/`, and makes no commit unless asked.
- [ ] When `/_my_wrap_up` runs, important work that finished without going through `close` reaches the boot history in the lighter entry shape, after the owner confirms it. Wrap-up stays optional, so this is a contract for when it runs, not a guarantee that every such change is captured.
- [ ] `.project/CURRENT_WORK.md` and `project-pack/CURRENT_WORK.md` hold Active Work and Up Next, and nothing else.
- [ ] An agent that learned an execution fact is prompted for it at session end, and the register's own rules no longer state that `close` is the only trigger.
- [ ] No pack instruction routes session learnings at `CLAUDE.md` or `.claude/rules/`.
- [ ] Reading the boot excerpt alone, without opening another file, tells whether an entry was written by `close` or by `wrap_up`.
- [ ] The wrap-up skill reaches Codex with the new scope, and its Codex prefix no longer tells the agent to update docs.

## Known Requirements

### Forced by existing systems

- **[HARD]** `CURRENT_WORK.md` is listed in `USER_DATA_FILES` (`scripts/init-project.sh:124-130`), so cutting the template reaches newly initialized projects only and `--force` never rewrites an existing project's file. No migration is written for existing projects; what propagates to them is the changed commands, which stop writing to the deleted sections. Same asymmetry Item 2 hit with `completed/CHANGELOG.md`.
- **[HARD]** `dist/` is regenerated and wiped at the start of every build, so the Codex wrap-up skill changes by rebuilding (`./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy`), never by hand-editing (`CLAUDE.md`, *Codex Compatibility Layer*).
- **[INHERITED]** `.project/adr/0002-adr-touch-points.md` and `.project/adr/0008-product-ledger-touch-points.md` both rejected giving `_my_wrap_up` a write duty — "optional-stage write duties defeat the control." The departure is deliberate, agreed with the owner 2026-09-09, and needs no new ADR; the reasoning is recorded in the concept's *Note for reviewers*. The decision-record and product-ledger write maps themselves are untouched by this item.
- **[INHERITED]** Per `.project/adr/0008-product-ledger-touch-points.md`, the product-ledger skim at `claude-pack/rules/context-loading.md:6-7` is a recorded invariant placed in exactly that file. It survives, and the new CHANGELOG read goes after it so the ledger read does not start reading as optional. Resolves epic finding `epic_plan-F3`.

### What wrap-up writes

- **[NEED]** `/_my_wrap_up` updates `.project/CURRENT_WORK.md`: active-item status, items started but not finished, and Up Next. The move of completed items into `Recently Completed` (`claude-pack/commands/_my_wrap_up.md:31`) goes with the section. Source: concept Success Criterion 7 (owner), which names `CURRENT_WORK.md` as the first of wrap-up's three writes.
- **[NEED]** `/_my_wrap_up` writes no file under `docs/`, in any form. Owner-stated with the reason quoted in *Problem*: records are cheap and tolerate a mediocre entry, documents are damaged by one, and documents change through the work-item lifecycle instead.
- **[NEED]** `/_my_wrap_up` does not commit unless asked. Source: concept Success Criterion 7 (owner).
- **[NEED]** Wrap-up stages **all** of the session's changes, then asks before committing. Owner, 2026-09-10: **[OWNER-VERBATIM]** "wrap up should stage ALL changes from the session, and then confirm before committing. that's it" This supersedes the `[INHERITED]` reading carried from the epic's Item 3 *In Scope* line (`.project/backlog/epic_knowledge_homes.md:207`, "the commit changed to stage-and-show"), which was implemented as staging only the files wrap-up itself wrote. That left the session's code unstaged under a summary reading "complete", and risked a light CHANGELOG entry being committed without the change it describes.
- **[NEED]** `/_my_wrap_up` prompts for an execution-register entry at session end. Source: concept Success Criterion 4 (owner) — the register's write is prompted at `close` and at `wrap_up`, and nowhere else. Item 2 shipped the `close` half; this is the other half, and until it lands the register's measurement is incomplete (`.project/completed/20260910_execution-register/design.md` Non-Goals).
- **[NEED]** `/_my_wrap_up` writes a light CHANGELOG entry for important changes that no work item captured. The judgement is the agent's, made against that guidance rather than a mechanical trigger, and the entry lands only after the owner confirms it. Owner, 2026-09-10: **[OWNER-VERBATIM]** "Agent's discretion based on guidance (\"Important changes not captured by work items\")" and **[OWNER-VERBATIM]** "Confirmation from user."
- **[NEED]** No pack instruction routes session learnings at `CLAUDE.md` or `.claude/rules/`. `_my_wrap_up.md:14` does today. Owner quote in *Problem*; surfaced as a carry-forward by Item 2's design review (m7).
- **[INFERRED]** `wrap_up`'s execution-note beat asks the session directly rather than scanning artifacts. Item 2's `close` beat reads `plan.md` deviation notes, `audit.md` findings, and `product-lens.md`, and its design review found that every execution fact this epic has actually measured — the MCP server timing out on a `/mnt/c` NTFS venv, subagents registering only when launched from a particular directory, PDF-derived markdown carrying transcription errors in load-bearing numerals — is a debugging-session fact that never reached any of those artifacts (`.project/completed/20260910_execution-register/design.md` B5, `design-review.md`). `wrap_up` is the beat that holds the session, so asking is the only route that reaches this class.
- **[NEED]** `--quick` stays a `CURRENT_WORK.md`-only status refresh and writes no records. It keeps the promise the flag makes today (`claude-pack/commands/_my_wrap_up.md:9`), and a quick mode that wrote records would not be quick.
- **[INFERRED]** When `close` and `wrap_up` both run in one session, the same fact is not filed twice. Both beats now point at the same register.

### The two CHANGELOG entry weights

- **[NEED]** The boot read takes the newest **5** CHANGELOG entries, heading through `Summary`, and stops before `Deliverables`. Owner, 2026-09-10: **[OWNER-VERBATIM]** "middle one is good, 5 is reasonable." Measured cost: 5 non-blank lines per entry, so about 25 lines for the five, against the 87 lines the deleted `Recently Completed` section spends on 15 completions. Alternatives declined in the same exchange: whole entries (17-21 lines each, so five costs ~90) and a one-line headline written by `close` (widest breadth, but it adds a field to close's entry and puts the same fact in one file twice). This settles the sizing call `epic_plan-F4` asked for; what it costs is the next line.
- **[INFERRED]** What the bound costs, stated rather than closed. Measured after Items 1 and 2 closed: the CHANGELOG holds 7 entries and the newest five reach back only to 2026-07-01, while the deleted section carries 15 completions. The CHANGELOG is sparse where the section was dense — nine completed items have no CHANGELOG counterpart at all. Those nine disappear from the boot read rather than moving into it — `docs-overhaul` (2026-08-08, committed `43bca3c`) is one, and it is the most recent of them. Backfilling is owner-excluded (see Non-Goals), so this is the residual of `epic_plan-F4`'s coverage axis: accepted at owner grade, not resolved.
- **[INFERRED]** The light entry carries only fields the boot read takes — heading, `Type`, and `Summary` — so the boot read works identically on both weights and needs no branch. It has no `Duration`, because there is no spec `Created` date to compute from, and no `Deliverables`, because untracked work has no artifact list.
- **[INFERRED]** A reader can tell the two weights apart from the entry alone, without opening another file. Both the distinct `Type` value and the absent `Duration`/`Deliverables` carry that signal; the exact token is a naming call for design.

### The read side

- **[NEED]** `.project/CURRENT_WORK.md` and `project-pack/CURRENT_WORK.md` hold Active Work and Up Next. `Recently Completed`, `Session Notes`, and the template's "Any notable learnings" bullet (`project-pack/CURRENT_WORK.md:35`) all go. Source: concept Success Criterion 5 (owner).
- **[INFERRED]** `claude-pack/commands/_my_close.md:83` writes an entry into `Recently Completed` and is the only other writer of that section. Deleting the section orphans that instruction, so `close`'s CURRENT_WORK step drops it and keeps only the removal from Active Work. This is not a change to what `close` writes to the CHANGELOG, which is out of scope.
- **[INFERRED]** `.project/execution/README.md` and `project-pack/execution/README.md` state that `/_my_close` prompts for an entry and "Nothing else triggers it" (`:5` in both). That becomes false when the `wrap_up` beat lands, so both files name both triggers.
- **[INFERRED]** Five places describe what `CURRENT_WORK.md` contains and go stale with the cut: `claude-pack/rules/context-loading.md:5` ("active work context, recent decisions, known issues"), `claude-pack/commands/_my_status.md:16` ("active items, recent completions, blockers"), `claude-pack/claude-md-checklist.md:14` ("active work, recent changes, decisions"), `project-pack/README.md:57`, and `docs/guide.md:136` (which also states wrap-up's old scope). Item 1's product-lens finding `epic_plan-F2` is the precedent: this is a distributable template, and a new user reads these descriptions.
- **[INFERRED]** `codex-overrides/prompt-prefixes/wrap-up.md` instructs the Codex agent to "update existing docs if needed" — the step being deleted — and `codex-overrides/config.sh:43` describes the skill as refreshing "`.project/CURRENT_WORK.md` or related docs." Both change with the scope.

## Non-Goals

- **A retention or pruning rule for any file.** The bound sits at the read, so nothing accumulates that needs pruning. Concept Key Concept 5.
- **Bounding Active Work — not by item count, not by entry depth.** The section holds 15 items and its entries run 3 to 22 lines, because `wrap_up` appends a status bullet per session. Both stay as they are. Owner, 2026-09-10, on items entering and never leaving: **[OWNER-VERBATIM]** "either is fine -- not your problem. that is the user's problem. and by having a more focused doc, such an issue is more obvious than what we have now (so long that no one reads the whole thing or minds that it is long)." And on entry depth, choosing to keep appending: **[OWNER-VERBATIM]** "A keep it like today." This amends concept Success Criterion 5's justification, which read "No section in it accumulates, so no retention rule is needed" — its operational half holds after the cut, and Active Work's growth is the owner's to manage, made visible by the shorter file.
- **Backfilling the completed items that have no CHANGELOG counterpart.** Owner-stated: they are months old and reachable from `git log` and `completed/`.
- **Any change to what `close` writes to the CHANGELOG.** Its structured entry keeps `Type`, `Duration`, `Summary`, and `Deliverables`. Only its `Recently Completed` write changes, which is a CURRENT_WORK edit, not a CHANGELOG one.
- **`project-pack/epic_template.md`'s `## Lessons Learned (Post-Completion)` section.** A different artifact with a different purpose — an epic retrospective, not a per-item field.
- **Editing the archived `20260701_close-command/` spec and design**, which record the original decision to use a `Lessons Learned` placeholder. Immutable historical entries.
- **Migrating existing projects' `CURRENT_WORK.md`.** Protected user data; the `[HARD]` requirement above states what reaches them instead.

## Open Questions / Deferred to design

- **How the boot read's bound is expressed mechanically**, and where the bound is stated so it stays visible. An instruction to read the newest five entries is honest but leaves the actual token cost to the agent's tool call; a bounded shell read makes it exact but hard-codes a shape. Either way the bound has to be legible in `context-loading.md`, not just implied.
- **The `Type` token for the light weight.** `Change` is the working candidate. It has to read as "this shipped but was never a tracked item" without implying a session diary.
- **Whether the two execution-note beats share one instruction text or carry their own.** `close`'s scans artifacts; `wrap_up`'s asks the session. The density bar and the four-way boundary live in `.project/execution/README.md` either way.
- **Where the light entry's confirmation sits** — folded into wrap-up's existing report step, or its own beat before it.
- **Step numbering.** `--quick` currently means "only do Steps 2, 4, and 5"; the step list changes, so the flag's step references need rewriting even though its scope is settled above.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_knowledge_homes.md` — Item 3 of KNOWLEDGE-HOMES
- **Required Reading:** `.project/concepts/agent-knowledge-and-enforcement.md`, `.project/adr/0001-decision-records-convention.md`, `.project/adr/0002-adr-touch-points.md`, `.project/adr/0008-product-ledger-touch-points.md`
- **Upstream item:** `.project/completed/20260910_execution-register/{spec,design,design-review}.md` — the register this item's second write beat targets, and the `_my_wrap_up.md:14` carry-forward
- **Product lens:** `.project/active/session-bookkeeping/product-lens.md`
- **Design:** `.project/active/session-bookkeeping/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
