# Design: Session Bookkeeping

**Status:** Implemented (Phases 1-4); Phase 5 behavioral pass outstanding
**Owner:** Reid W
**Created:** 2026-09-10 14:33 PDT
**Branch:** mental-model-reviewer
**Base commit:** 78ea3b5
**Spec:** `.project/active/session-bookkeeping/spec.md`

---

## Overview

Rewrite `/_my_wrap_up` to write only cheap records — current state, an uncaptured completion, an execution fact — and give session boot the newest completions through a bound that is a command rather than an instruction.

## Related Artifacts

- **Spec:** `.project/active/session-bookkeeping/spec.md`
- **Epic:** `.project/backlog/epic_knowledge_homes.md` — Item 3 of KNOWLEDGE-HOMES
- **Required Reading:** `.project/concepts/agent-knowledge-and-enforcement.md`, `.project/adr/0001-decision-records-convention.md`, `.project/adr/0002-adr-touch-points.md`, `.project/adr/0008-product-ledger-touch-points.md`
- **Upstream items:** `.project/completed/20260910_execution-register/`, `.project/completed/20260910_retire-hidden-memories/`
- **Product lens:** `.project/active/session-bookkeeping/product-lens.md` — gate CLEAR

## The Point

Session end must write cheap records and never curated documents, and a cold agent's boot read must still show current work plus what just shipped, at a cost that does not grow with the archive. **[OWNER]** — concept Success Criteria 5, 6 and 7, with the reasons stated verbatim: documents that are valued to stay tight are damaged by session-summary edits, while "feedback" and "changelog" are cheap record; and completion history stays at boot because **[OWNER-VERBATIM]** "reading it gives a better picture of the state of things. Knowing we just edited something or closed out an epic could be super helpful context."

This ladders up to the epic's obligation: every place an agent is told to write knowledge points at a tracked file that exists. Item 1 removed the untracked homes, Item 2 built the one that was missing, and this item is where the every-session command stops pointing at the wrong ones and starts feeding the boot read that makes the whole loop visible.

## Research Findings

**The command as it stands** (`claude-pack/commands/_my_wrap_up.md`, 80 lines). Five steps: review, update `CURRENT_WORK.md`, update `docs/`, report, commit. Three defects the spec names, all verified: `:14` routes session learnings at `CLAUDE.md` and `.claude/rules/`; `:37-46` is the docs step; `:60-66` commits without asking. A fourth, found by the spec's product lens: `:31` moves completed items into `Recently Completed`, a section this item deletes.

**The other writer of that section** is `claude-pack/commands/_my_close.md:83`. Nothing else references it (`grep -rn "Recently Completed" claude-pack/ project-pack/` returns those two lines plus the template heading).

**No rule file contains a shell command.** Six rule files, 233 lines total, all prose. This matters for the boot-read bound — see D1.

**`check_wired` already exists** in `scripts/test_docs.sh:80-92`: a guard asserting that a needle stays present in a named file, used four times for ADR 0008's touch points, including `check_wired "execution/ENTRIES.md" "claude-pack/commands/_my_close.md"`. The pattern this item needs is already there.

**The Codex prompt prefix exists for a reason that has since died.** `codex-overrides/prompt-prefixes/wrap-up.md` is the only prompt prefix in the repo. Its original text (commit `fbcfea5`) put "Memory capture, transcript indexing, and `MEMORY.md` updates" out of scope and told the agent to ignore instructions requiring `/_my_capture`, `/_my_memorize`, or auto-memory. Item 1 deleted all of that from the command. What survives is a restatement of the command's own steps, one of which ("update existing docs if needed") is the step this item removes. Nothing asserts the file's existence; `scripts/build-codex-pack.sh:418-420` already handles its absence.

**The CHANGELOG is a read contract now, and the template breaks it.** `project-pack/completed/CHANGELOG.md:7-18` ships a placeholder entry, `## [YYYY-MM-DD] - [Epic/Item Name]`, with all four fields filled by brackets. Any bounded read of "the newest entries" surfaces it as a completion in a freshly initialized project.

**Entry-format arithmetic, measured 2026-09-10.** `.project/completed/CHANGELOG.md` holds 7 entries at 13-21 lines each. Heading through `Summary` is 5 non-blank lines per entry; the bounded read of five entries emits 40 lines including blanks, 25 without. The deleted `Recently Completed` section spends 87 lines on 15 completions.

**On-demand CHANGELOG readers are unaffected.** `_my_status.md:21` and `_my_project_find.md:71` read the file whole, on request, not at boot. Neither needs a change beyond `_my_status.md:16`'s stale description of what `CURRENT_WORK.md` contains.

## Core Concept

Session bookkeeping is one loop with two halves: what a session writes when it ends, and what the next session reads when it starts. Both halves are currently aimed wrong. The write half aims at curated documents and commits unasked; the read half opens a file that spends 113 of its 241 lines on history.

The design turns wrap-up into a writer of records only — three of them, each with a home that already exists. Current state goes to `CURRENT_WORK.md`. A completion the pipeline never captured goes to `completed/CHANGELOG.md` in a lighter shape. A fact learned by doing goes to `.project/execution/ENTRIES.md`. It proposes all three, waits, writes what was confirmed, then stages and shows rather than committing. On the read side, `CURRENT_WORK.md` loses its history sections and `context-loading.md` gains one bounded read of the newest completions, placed after the product-ledger skim that ADR 0008 pins to that file.

**The insight that keeps this small: nothing here is new.** Every home exists. Every beat has a sibling — `_my_close.md` already runs scan, then confirm, then file, against the same three registers. The design creates no artifact and no abstraction; it deletes two sections, redirects three writes, and adds one read.

**The one genuinely new thing is that the read bound is a command, not a sentence.** "Bounded" and "stated" are different claims. A rule that says "read the newest five entries" leaves the actual cost to whatever the agent's next tool call does, and that cost grows with the file — which is precisely what the spec's success criterion forbids. A one-line `awk` makes the cost the same at 7 entries and at 70. It buys determinism of cost, not compliance; see B2, where that limit is stated rather than papered over.

## Key Bets

- **B1.** A CHANGELOG heading plus its `Summary` is enough for a cold agent to know what just shipped. *If false → the boot read spends 25 lines and delivers no orientation, and the owner's stated reason for keeping completion history goes unserved while the section that served it is gone.*
- **B2.** Agents comply with read instructions in `context-loading.md`. *If false → the bound is irrelevant because the read never happens, and the boot history is lost outright rather than merely thinned.* **The evidence is mixed and the favorable half is the nearer one.** The inventory research graded 14 always-on instructions as catching nothing (`.project/research/20260818-151200_anchor-on-the-point-inventory.md:245-258`), and embedding a command does not change the rung — it is still prose an agent can skip, not a harness event. Against that: the `CURRENT_WORK.md` read at `context-loading.md:5` is the same rung in the same file and is observably followed by every session, which is the closest available precedent.
- **B3.** Work that skips `close` is rare enough that agent discretion plus owner confirmation keeps the CHANGELOG a record of completions rather than a session diary. *If false → the newest five entries fill with session-level noise and the boot read stops showing what shipped, which is the failure the read bound was sized to prevent.*
- **B4.** Asking the session directly at wrap-up reaches execution facts that close's artifact scan cannot. *If false → the register stays empty for the reason Item 2's design feared, and the epic's measurement is inconclusive.* Inherited from `.project/completed/20260910_execution-register/design.md` B5: every execution fact this epic measured was a debugging-session fact that never reached a `plan.md` or an `audit.md`.

## Key Decisions

- **D1.** The boot read's bound is an `awk` one-liner in `context-loading.md`, given alongside the prose that says what it is for. *Rejected: prose alone (the cost then grows with the file, and the spec's success criterion forbids exactly that); a line bound such as `head -60` (truncates an entry mid-sentence, which is the concept's own stated reason for bounding by entries rather than lines); a separate recent-completions file maintained by `close` (a second representation of one fact — smell 1 — and the owner already declined the headline variant of it).* This is the first shell command in any rule file, which is why the alternative is named rather than assumed away.
- **D2.** Wrap-up keeps five steps, and both record writes share one propose-and-wait beat. *Rejected: a confirmation per register (two interruptions at session end for two cheap records); writing first and showing after (the owner required confirmation).* This mirrors `_my_close.md`'s scan → confirm → file, so the pack has one shape for record writes rather than two.
- **D3.** The light weight is `**Type**: Change`. *Rejected: `Session` (reads as a diary, which is the failure mode B3 names); `Untracked` (collides with git's vocabulary for a different thing).*
- **D4.** The light entry's fields are heading, `Type`, and `Summary` — a strict subset of what the boot read takes, so the read needs no branch and no knowledge of which weight it is looking at. *Rejected: a `Duration` measured from the session (there is no spec `Created` date to anchor it, and a session's length is not a work item's duration).*
- **D5.** Delete `codex-overrides/prompt-prefixes/wrap-up.md` rather than reword it. *Rejected: rewording (its purpose was keeping Claude-only memory machinery out of scope, and Item 1 removed that machinery from the command, leaving a step restatement whose docs line this item deletes).* This removes the repo's only prompt prefix and one runtime divergence.
- **D6.** The register's density bar and four-way boundary stay in `.project/execution/README.md`. Each command says only how it finds candidates. *Rejected: restating the bar in wrap-up (two homes for one rule — the defect Item 2's audit found across three surfaces).*
- **D7.** The reader anchors its heading match on a digit, and the template CHANGELOG's placeholder entry is removed as well. The anchor is the primary protection because it is the only one that reaches projects initialized before this change — their `completed/CHANGELOG.md` is protected user data that `--force` will never rewrite. The template removal is secondary and still worth doing, because `_my_status` and `_my_project_find` read the file whole and a human reads it too. *Rejected: template removal alone (leaves every existing project's boot read showing a placeholder until five real entries bury it); a placeholder-aware filter richer than one character class (weight in the one line that has to stay readable).*
- **D8.** `test_docs.sh` gains two `check_wired` guards and one negative sweep. *Rejected: no test (the orphaning this item fixes is the class the spec's product lens caught by hand; the guard is three lines and catches it mechanically next time).*

## Architecture

**The write side — `/_my_wrap_up`, five steps.**

1. **Review** what changed: the conversation as source of truth, cross-checked against `git diff --stat` and `git log --oneline -5`, then read `.project/CURRENT_WORK.md`. Unchanged from today except that its framing no longer promises to distil learnings into auto-loaded files.
2. **Update `CURRENT_WORK.md`**: active-item status, items started but unfinished, and Up Next. Entries keep appending, by owner decision. The move into `Recently Completed` goes with the section.
3. **Propose records, and wait.** Two candidates, either or both possibly absent: a light CHANGELOG entry for an important change no work item captured, and an execution-register entry for a fact learned by doing. A fact `close` already filed this session is skipped, since both beats point at the same register. "Nothing to record" is a normal outcome and leaves no trace. This step ends by waiting.
4. **Write** what was confirmed: the light entry inserted at the **top** of `completed/CHANGELOG.md`, above the newest existing entry, and the execution note appended to the **end** of `.project/execution/ENTRIES.md` in the format its README defines. The two registers order oppositely and the difference is load-bearing — the CHANGELOG is read newest-first from the top, the register is never read at all.
5. **Stage, show, report.** `git add` the files written, show the owner what is staged, and summarize. No commit unless asked.

`--quick` runs steps 1, 2 and 5: state hygiene, no records.

**The read side — `claude-pack/rules/context-loading.md`, four reads in order.**

1. `.project/CURRENT_WORK.md` — active work and what is up next.
2. `.project/product/INDEX.md` if present — the implemented-promise skim. Pinned to this file and this position by ADR 0008.
3. The newest 5 entries of `.project/completed/CHANGELOG.md` if present — what just shipped, heading through `Summary`, via the bounded one-liner.
4. The relevant docs for the area being worked in.

**The three homes, and who writes to each.**

| Home | Heavy write | Light write | Read |
|---|---|---|---|
| `CURRENT_WORK.md` | `close` removes from Active Work | `wrap_up` updates status | boot, whole file |
| `completed/CHANGELOG.md` | `close`, four fields | `wrap_up`, three fields | boot, newest 5 bounded; `status` and `project_find` whole, on demand |
| `execution/ENTRIES.md` | `close`, artifact scan | `wrap_up`, asks the session | nothing |

**Data flow, one session:** agent works → wrap-up reviews → `CURRENT_WORK.md` updated → candidates proposed → owner confirms → the light entry inserted at the top of the CHANGELOG, the execution note appended to the register → files staged and shown → owner commits when ready → next session's boot read sees current work plus the newest five completions, one of which may be the light entry just written.

## Required Invariants

- **`completed/CHANGELOG.md` is ordered newest-first, and both writers insert at the top.** The bounded read takes the first five entries, so insertion position is correctness-critical, not cosmetic: an entry added at the bottom is invisible to the boot read. `close` already does this in practice but has never been told to; this item states it in three places — the clause in `_my_close.md`, the clause in `_my_wrap_up.md`, and the template's file header, which is the one home both writers see.
- A CHANGELOG entry's heading starts at line start with `## [` followed by a digit, and `### Deliverables` is the last section of a heavy entry. The bounded read depends on both, so the entry format is a read contract, not house style.
- No body line inside a CHANGELOG entry starts with `## [`. Same inherited constraint the execution register carries (`.project/execution/README.md`).
- `context-loading.md` keeps the product-ledger skim, before the CHANGELOG read. ADR 0008 places it in that file as a recorded invariant.
- `CURRENT_WORK.md` and `completed/CHANGELOG.md` stay in `USER_DATA_FILES` (`scripts/init-project.sh:124-130`), so `--force` never rewrites an accumulated file.
- No pack surface names a `CURRENT_WORK.md` section that does not exist. Guarded by test.
- Nothing in the pack reads `.project/execution/ENTRIES.md`. Item 2's invariant, unchanged: a repo-wide grep for that path returns writes and rules only.
- `/_my_wrap_up` writes no path under `docs/` and runs no `git commit`.

## Component Overview

**Rewritten**

- `claude-pack/commands/_my_wrap_up.md` — the five steps above. Purpose line and *Why This Exists* rewritten to point at `CURRENT_WORK.md`, the CHANGELOG, and the register instead of `CLAUDE.md` and `.claude/rules/`.

**Edited**

- `claude-pack/rules/context-loading.md` — read 3 added with its bound; `:5`'s description of `CURRENT_WORK.md` corrected.
- `claude-pack/commands/_my_close.md` — the `Recently Completed` write at `:83` dropped; its CHANGELOG write untouched except for a clause naming the insertion position, which states existing behavior rather than changing it.
- `.project/CURRENT_WORK.md`, `project-pack/CURRENT_WORK.md` — `Recently Completed` and `Session Notes` removed, and with the template's copy, the orphaned "Any notable learnings" bullet at `:35`.
- `project-pack/completed/CHANGELOG.md` — placeholder entry removed (D7); file header gains the newest-first line that both writers see.
- `.project/execution/README.md`, `project-pack/execution/README.md` — `:5` names both triggers instead of asserting close is the only one.
- `claude-pack/commands/_my_status.md:16`, `claude-pack/claude-md-checklist.md:14`, `project-pack/README.md:57`, `docs/guide.md:136` — stale descriptions of what `CURRENT_WORK.md` holds and what wrap-up does.
- `codex-overrides/config.sh:43` — the wrap-up skill description, which currently promises "related docs."
- `scripts/test_docs.sh` — two `check_wired` guards and the negative sweep (D8).

**Deleted**

- `codex-overrides/prompt-prefixes/wrap-up.md` (D5).

**Regenerated**

- `dist/codex/skills/my-wrap-up/SKILL.md` and `dist/codex/manifest.json`, by rebuild.

## Non-Goals

- Bounding Active Work, by item count or entry depth. Owner decision, recorded in the spec's Non-Goals.
- Reshaping the template's per-item Active Work block (`project-pack/CURRENT_WORK.md:9-26`). The cut is to sections, not to the block's fields.
- Any change to what `close` writes to the CHANGELOG. Its four fields stand.
- Backfilling completions with no CHANGELOG counterpart.
- A retention or pruning rule for any file.
- Migrating existing projects' `CURRENT_WORK.md` or `completed/CHANGELOG.md`. Both are protected user data.
- Changing `_my_status` or `_my_project_find`'s CHANGELOG reads, which are on-demand and whole by design.
- Converting any read to a harness event. B2 states the limit; the ladder work is `[AOP-005]`.

## Implementation Notes

**The bounded read, verbatim.** Tested against this repo's CHANGELOG and against a mixed-weight fixture:

```bash
awk '/^## \[[0-9]/{n++; p=1} n>5{exit} /^### Deliverables/{p=0} /^---$/{p=0} p' .project/completed/CHANGELOG.md
```

Emits 40 lines including blanks for five heavy entries, and 25 non-blank. Three details are load-bearing. A light entry has no `### Deliverables`, so the `/^---$/` clause is what stops it — carrying only the first clause would print separators for one weight and not the other. The `[0-9]` in the heading anchor is what makes the reader skip a template placeholder heading (`## [YYYY-MM-DD] - [Epic/Item Name]`), which is the only protection that reaches projects initialized before this change, since their CHANGELOG is protected user data. And the count is of entries, not lines, so no entry is ever truncated mid-sentence.

**Order matters in one place.** Delete `Recently Completed` from `CURRENT_WORK.md` in the same pass that removes the write instructions at `_my_wrap_up.md:31` and `_my_close.md:83`. Between those changes, one command writes to a section that is gone.

**Two copies of the register README.** `.project/execution/README.md` is not user data, so `--force` refreshes it from `project-pack/`. Edit both directly rather than editing the template and re-seeding — Item 2's plan recorded that `--force` in this repo also refreshes unrelated stale files, and a one-line change does not justify that diff.

**Rebuild, never hand-edit `dist/`.** `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy`. Confirm the built `SKILL.md` carries no prefix block once D5 lands.

**The light entry's shape**, for the plan to copy:

```markdown
## [2026-09-11] - explicit-skill-scopes

**Type**: Change

### Summary
Made the workflow shortcut skills explicit-only so they stop firing on unrelated prompts.
```

**Verified line numbers** as of `78ea3b5` plus working-tree changes: `_my_wrap_up.md` `:14`, `:31`, `:37-46`, `:58`, `:60-66`; `_my_close.md:83`; `context-loading.md:5`, `:6-7`; `project-pack/CURRENT_WORK.md:30`, `:35`, `:47`; `_my_status.md:16`; `claude-md-checklist.md:14`; `project-pack/README.md:57`; `docs/guide.md:136`; `codex-overrides/config.sh:43`; `init-project.sh:124-130`; `test_docs.sh:80-92`.

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| The boot read is skipped entirely, command or not (B2 false) | High — the history is lost rather than thinned | Same rung as the `CURRENT_WORK.md` read, which is observably followed; a `check_wired` guard keeps the line present, which is all a test can prove |
| The CHANGELOG becomes a session diary (B3 false) | High — the newest five stop showing completions | Owner confirms every light entry; the guidance names work items as the boundary; the owner sees each entry in a staged diff |
| A boot read shows the template placeholder | Low, after D7 — bracketed metavariables, not a plausible completion | The reader's `[0-9]` heading anchor skips it outright, in new and existing projects alike. The template removal handles the whole-file readers. **An earlier draft of this row claimed one real close would push the placeholder past position five; that was wrong — it takes five, which is why the anchor and not attrition is the fix** |
| The `awk` mis-selects after a CHANGELOG format change | Med — silent under- or over-reading | The format is named as a Required Invariant, and the one-liner ships beside the prose that says what it should return |
| Wrap-up's confirmation step makes the command feel heavy, so it gets skipped | Med — no records at all | One wait for both records (D2), and "nothing to record" is an explicit normal outcome rather than a prompt to fill |
| An execution fact is filed twice when `close` and `wrap_up` run in one session | Low — a duplicate entry in an append-only log | Wrap-up's step 3 says to skip a fact `close` already filed this session |
| Deleting the Codex prefix changes Codex wrap-up behavior in an unnoticed way | Low | The prefix's live content is a restatement of the command's own steps; the rebuilt `SKILL.md` is inspected once |

## Integration Strategy

The pipeline shape does not change. `close` remains the gate that archives an item and writes the structured CHANGELOG entry; `wrap_up` remains optional, session-scoped, and now catches the two things `close` structurally cannot — a completion that was never a work item, and a fact that never reached an artifact. ADR 0002's and 0008's write maps for decisions and promises are untouched; the departure is the one the concept already recorded and the owner already agreed, and it needs no new entry.

On the read side, `context-loading.md` stays the single always-on read list, which is the placement ADR 0008 chose deliberately over a new rule file. The rule grows by two lines and the boot read shrinks by roughly a hundred, since `CURRENT_WORK.md` loses 113 lines of history and gains a 40-line bounded CHANGELOG read.

## Validation Approach

**Mechanical.**

- `bash -n` on nothing new; the only executable change is `test_docs.sh`.
- `./scripts/test_docs.sh` passes, including the two new `check_wired` guards and the negative sweep for `Recently Completed` and `Session Notes` across `claude-pack/` and `project-pack/`.
- `grep -rn "Recently Completed\|Session Notes" claude-pack/ project-pack/` returns nothing.
- `grep -rn "docs/" claude-pack/commands/_my_wrap_up.md` returns no write instruction, and `grep -n "git commit" claude-pack/commands/_my_wrap_up.md` returns nothing.
- The one-liner, run against this repo's CHANGELOG, returns five entries and no `Deliverables` line.
- `./scripts/build-codex-pack.sh` and `./scripts/setup-codex.sh --copy` succeed; `dist/codex/skills/my-wrap-up/SKILL.md` carries the new steps and no prefix block.
- `./scripts/test_init_project.sh` still passes — a fresh init produces a `CURRENT_WORK.md` with two sections and a CHANGELOG with no placeholder entry.

**Behavioral, and it is the criterion that matters.** Run `/_my_wrap_up` on a real session in this repo: confirm it proposes rather than writes, waits, touches no `docs/` file, stages without committing, and that the `CURRENT_WORK.md` it leaves has no history section. Then start a fresh session and confirm its boot read names the most recent completed work through the standard session-start reads alone — no browsing item folders under `completed/`, no `git log`. That end-to-end pass is the epic's own falsifier for this item and cannot be replaced by a grep.

## Next-Stage Handoff

**Fixed.** The five-step shape and `--quick`'s meaning (D2). The one-liner and its position after the ledger skim (D1, ADR 0008). `Type: Change` and the three light fields (D3, D4). The bar staying in the register README (D6). The prefix deletion (D5). The template placeholder removal (D7).

**Open for the plan.** Whether the stale-description sweep is one pass or folded into each file's edit. Exact wording of wrap-up's *Why This Exists*. Whether the negative sweep in `test_docs.sh` is a new function or an inline `grep` beside the existing retired-name check at `:58`.

**One decision record to file at acceptance, if the owner agrees.** Session boot now takes its history from a bounded read of `completed/CHANGELOG.md`, which makes that file's entry format a read contract rather than house style. Nothing records that coupling today, and a future agent reordering or renaming close's entry sections would plausibly break the boot read without knowing it — which is the ADR density bar (`.project/adr/README.md:15-16`). ADR 0008 is the precedent: a touch-point map recorded for one artifact so silent extension is catchable. The write-duty departure itself needs no entry; the concept recorded it and the owner waived one.

**De-risk first.** The behavioral pass, and specifically B2. Everything mechanical here is a prose edit that a grep can verify; the only claim a test cannot reach is whether a real session actually runs the bounded read and comes away oriented. Run one `/_my_wrap_up` and one fresh boot before treating the item as done.

---

**Next Step:** After approval → `/_my_plan`.
