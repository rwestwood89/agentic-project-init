# Design: Execution Register, Write-Only

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-09-10 08:23
**Branch:** mental-model-reviewer
**Commit at drafting:** 78ea3b5

## Overview

One more instance of a register shape the pack already has, plus the boundary text that lets an agent pick between four homes in one read, plus a throwaway prompt for triaging the memories that accumulated before it existed.

## Related Artifacts

- **Spec:** `.project/active/execution-register/spec.md`
- **Product-lens ledger:** `.project/active/execution-register/product-lens.md` (gate DISPOSED; F1's reframe still `[AGENT]`)
- **Epic:** `.project/backlog/epic_knowledge_homes.md`, Item 2 of KNOWLEDGE-HOMES
- **Required Reading:** `.project/concepts/agent-knowledge-and-enforcement.md`, `.project/feedback/README.md`, `.project/completed/20260826_feedback-capture-file/spec.md`
- **Upstream item:** `.project/active/retire-hidden-memories/{spec,audit}.md`
- **Decision records consulted:** 0001, 0002 (amended), 0008, 0009, 0011

## The Point

An agent that learns how this codebase or environment actually behaves has exactly one named, git-tracked place to write it, and can tell in one read that the fact belongs there rather than in the decision log, the promise ledger, or the pack-feedback log. **[OWNER]** — concept Success Criteria 3-4 and *Next-Stage Handoff*, "the execution register sits beside them and absorbs neither."

Two things that obligation ladders up to, both owner-grade:

- **The owner can review what an agent wrote before it carries authority.** **[INHERITED: `.project/concepts/mental-alignment-checkpoint.md:369`]** "I need git tracking. 95% of the time the feedback an agent writes is REALLY bad and needs a revision to be generalized and useful." This is why the register is tracked, append-only, and read by nothing.
- **The register's contents are the evidence for a decision the owner has not made yet** — whether an agent-learning loop is worth building at all. **[OWNER-VERBATIM]** 2026-09-09: "my temptation would be 'D: just don't save durable facts'. But before deciding, I want to at least see *what they would save*."

What that means for this design: the boundary text is the load-bearing part, not the plumbing. A register whose instructions cannot separate an execution fact from a decision produces a log that measures the instructions rather than the agents, and the owner's decision gets made on bad evidence.

**And the log alone cannot be read.** It has three independent ways to come out uninterpretable — filled with junk (B1 false), empty because close is the only beat until Item 3 (B2 false), or thin because agents kept writing to the native store (B3 false) — and reading the file tells you nothing about which happened. The disambiguator is the owner-run triage: it reads every entry in every repo and files it, so it says what agents actually saved, independently of what this register received. Owner disposition, 2026-09-10. The register's contents and the triage's results are one instrument with two readings, and neither is interpretable alone.

## Research Findings

**The shape to copy already exists.** `.project/feedback/` is a two-file register: `README.md` carries the rules, `ENTRIES.md` carries the log. The split exists for one reason — `scripts/init-project.sh:122-127` lists `feedback/ENTRIES.md` in `USER_DATA_FILES`, so `--force` refreshes the rules and never touches the entries. `scripts/test_init_project.sh:228-265` (Test 8) asserts both directions in one run, and its comment at `:229-231` states the failure mode.

**Close already has the rhythm this beat needs.** `claude-pack/commands/_my_close.md` runs two scans of the same artifacts with two different questions — emergent decisions at Step 2.4, product promises at Step 2.5 — surfaces both as candidates in Step 3, and files them in Step 4b before `git mv` moves the sources. The promise scan states its own posture at `:50-53`: "Zero is the common case; close proceeds on 'none' — this is never a gate."

**The field being removed has three live homes**, verified 2026-09-10: `claude-pack/commands/_my_close.md:98`, `project-pack/completed/CHANGELOG.md:19`, and five sections in `.project/completed/CHANGELOG.md` (`:22`, `:43`, `:67`, `:86`, `:104`). `dist/codex/skills/my-close/SKILL.md:105` follows from a rebuild. `project-pack/epic_template.md:144` is a different artifact and stays (Item 3 non-goal).

**Doc touch points are guarded by test.** `scripts/test_docs.sh:73-84` has a `check_wired <pattern> <file> <description>` helper, used three times to assert the product ledger's touch points stay wired — the pattern established by ADR 0008. Register mentions live at `README.md:27`, `README.md:276`, `project-pack/README.md:60`, `project-pack/README.md:84`. `docs/STRUCTURE.md` names no register and needs no edit.

**Delivery forms for a prompt, and what governs them.** ADR 0009 (active, `[OWNER]`) rules that a *pack capability* is a skill directory under `claude-pack/skills/<name>/`, and explicitly rejects "command file in `claude-pack/commands/` delegating to a spec in `claude-pack/scripts/`" as the shape for new capabilities. ADR 0011 puts skill directories through the Codex adapter. `claude-pack/scripts/product-lens.md:3` is the surviving instance of the older shape and says of itself, "This is not a slash command and not an always-on rule"; the Codex build copies it by name at `scripts/build-codex-pack.sh:559-563`.

**The Codex description override needs no change.** `codex-overrides/config.sh:19` describes close by its tracking-file updates and names no scan, so adding a third scan does not make it wrong.

## Core Concept

The register is two files and a habit, and almost nothing here is new.

The two files are a copy of `.project/feedback/`: rules in `README.md`, log in `ENTRIES.md`, split because `--force` has to refresh one and never touch the other. The habit is a third scan in `_my_close.md`, sitting beside the decision scan and the promise scan, reading the same artifacts with a third question and reporting "none found" as a normal answer.

The one part that required actual thought is the boundary. The pack now has four registers whose subjects sit close together, and the concept's US-2 asks that an agent holding a fact tell in one read which one it belongs to. So the register's rules are written as a bar plus a worked set of examples — two that qualify, four that belong to a named neighbour — because that is the difference between the two registers with real use and the one with none. `.project/adr/README.md:16-30` and `.project/product/README.md` both state a bar with a worked pair and have 12 and 0 entries respectively; `.project/feedback/README.md` states no bar and has 0. The bar does not explain the entries alone, but it is the only lever this design holds over what gets filed.

Everything else follows: the log ships empty so its contents mean something, nothing reads it because the owner has not decided a reader is worth building, and the entries that already exist in the harness's own store get triaged into the four homes by a prompt the owner carries to each repo once.

## Key Bets

- **B1.** An agent at close, handed a density bar with worked good/bad examples naming all four homes, files an execution fact in the right register more often than not. *If false → the log fills with decisions and project context, and its contents measure the quality of the instructions rather than what agents chose to save, which is the wrong input to the owner's decision.*
- **B2.** A write beat attached to close is a strong enough trigger to produce entries at all. *If false → the log stays empty and "nothing was worth saving" is indistinguishable from "the trigger was too weak."* **The evidence cuts both ways and the favorable half is not the whole of it.** The concept's Appendix A credits `.project/adr/`'s 12 entries to an unskippable write gate **and an enforced read**, and `.project/adr/0002:24` calls the enforced read "the only read enforcement that works." This register ships with no read path by owner decision, so its nearest precedent is not ADR — it is the promise beat: same command, same shape, no read, live since 2026-08-09, and 0 entries across the two closes since. Two closes cannot falsify anything, but the owner will read this log against that precedent, not against ADR's. Partly hedged: Item 3 adds the wrap_up beat.
- **B3.** A line in the register's rules telling agents not to use the native memory store measurably reduces split writes, even though the harness instructs the opposite in every session's system prompt. *If false → facts keep landing in the untracked store, the log under-counts, and the owner reviews a biased sample. This is the weakest bet in the design.* A stronger instrument does exist and was rejected on cost: a line in `claude-pack/rules/` or a project's `CLAUDE.md` would reach an agent *before* it writes a memory rather than at close. The concept is scathing about the always-on budget (263 lines, 14 mechanisms that catch nothing) and concept SC4 keeps the register's *write* out of rules, so the trade was declined — not unavailable.
- **B5.** The artifacts close reads contain execution facts at all. *If false → the strong trigger harvests a surface that does not carry the payload, and the class reaches the register only through the weak, optional wrap_up beat in Item 3.* This is the bet with the most evidence against it: every execution fact this work has measured — the `/mnt/c` NTFS venv timeout, subagent registration by launch directory, PDF transcription errors in load-bearing numerals — is a debugging-session fact that never reached a `plan.md` or an `audit.md`, and all of them were written unprompted, in session, to the native store. D5 answers it by asking the session as well as reading the artifacts.
- **B4.** Execution facts arise in real projects often enough to be worth the instructions they cost. *If false → the register is dead weight and the honest answer to the owner's question is "don't save durable facts." Evidence is stronger than the spec's survey suggested: beyond four unambiguous and five defensible facts across ten projects, three are local, verified, and pre-existing — the two Codex build gotchas at `.project/adr/0010:36-40` and the symlinked-`SKILL.md` refusal at `CLAUDE.md:53`. The concept scoped this repo's homeless-fact population to zero; the class was in fact absorbed by two registers that had write beats.*

## Key Decisions

- **D1.** Two files — `.project/execution/README.md` for the rules, `ENTRIES.md` for the log — mirroring `.project/feedback/`. *Rejected: one file (the `--force` split collapses, and an agent would have to read the whole log to append to it, which the adjacent register's owner-stated reason forbids).*
- **D2.** Entry format is a tagged heading plus two fields, **Fact** and **Evidence**. A triage-filed entry carries a third, **Source**. *Rejected: the feedback register's Wrong/Right/Learning triple (there is no wrong answer to record here — the fact is the payload); a free-form paragraph (destroys the line-oriented selection the spec requires).*
- **D3.** The tag names the surface the fact is about — a script, a tool, a data format — free-form, in brackets, as the heading's second whitespace-separated token so the adjacent register's `awk` one-liner works unchanged. *Rejected: tagging the work item that produced the fact (a future reader looks for facts about a file, not about a ticket); a closed vocabulary (no closed set of surfaces exists, unlike pack targets).*
- **D4.** The triage prompt ships as `project-pack/TRIAGE_MEMORIES.md`, landing at `.project/TRIAGE_MEMORIES.md` in every initialized project, and is used by direct reference in prose. Owner decision, 2026-09-10. It is not user data, so `--force` propagates improved instructions. *Rejected: a skill directory under `claude-pack/skills/` (owner: "it is really one-time, so not worth muddying the skills folder" — ADR 0009 would govern the shape if it were a capability, and it is not); a command in `claude-pack/commands/` (also a permanent capability, and contradicts ADR 0009's invariant); a file in this work item only (the owner has to carry it to each repo by hand, and seeding costs nothing since the installer's `copy_file` already creates destination directories).* Placed at the `.project/` root rather than inside `.project/execution/` because it files into all four homes, not just the register's. **What seeding costs, stated honestly (m5):** `copy_file` re-adds a missing template file on any plain `init-project.sh` run, so a prompt deleted after use comes back on the next re-init. That is the price of seeding it as a template rather than carrying it by hand, and it is acceptable for a file that stays accurate.
- **D5.** The record scan reads the artifacts close already reads — `plan.md` deviation notes, `audit.md` findings, `product-lens.md` — **and additionally asks the session directly when that session did the implementation.** *Rejected: introspection alone (close is frequently run by a session that did not implement and has nothing to introspect); artifacts alone (see B5 — the artifacts do not reliably carry this class).* The two together cost one conditional clause and cover both cases.
- **D8.** Close's Step 2 becomes **one record scan with three destinations**, replacing the separate decision and promise scans. Owner decision, 2026-09-10, chosen from three options with their costs. *Rejected: adding the register as a third scan (the decision scan runs first and its own text claims "workarounds against another component or repo's behavior" at `_my_close.md:29`, which is the register's headline class — the register would receive nothing); narrowing the decision scan's text instead (works, but the boundary then lives in the scan and in the register's rules, two places that must be kept in agreement by hand).* One scan is also the only shape where adding a fifth home later is an edit to one paragraph.
- **D9.** The bar gains a seventh example, the confusable case that D8's boundary exists for. Authored under the owner's delegation 2026-09-10 ("I'll handle the example wording myself" / "A"), and an addition to — not a rewording of — the six ratified examples:

  > - **Good:** "A skill directory left out of `NATIVE_SKILL_ALLOWLIST` is silently excluded from the Codex build." How the build behaves, learned the hard way. A decision record may sit nearby — the decision was to use an allowlist at all — but the behavior is the fact, and the fact belongs here.

  It is drawn from `.project/adr/0010:36-40`, which currently holds this exact fact for want of a home. *Rejected: leaving the bar at six (the ADR-adjacent case is the one an agent gets wrong, and it is the one with live precedent in this repo).*
- **D6.** `scripts/test_docs.sh` gains one `check_wired` guard asserting the close touch point stays wired, mirroring `:84`'s guard on `product.sh`. *Rejected: no guard (the pack's own history is that unwired touch points rot silently — four such references were the reason Item 1 existed).*
- **D7.** The five live `Lessons Learned` sections in `.project/completed/CHANGELOG.md` are deleted with nothing migrated. *Rejected: migrating the one section that meets the bar (the owner chose ship-empty, and the fact is already recorded at `scripts/test_init_project.sh:229-231`, cited by the spec's own `[HARD]` requirement).*

## Architecture

Four seams, no new machinery in any of them.

**Seam 1 — the register itself.** `project-pack/execution/{README.md,ENTRIES.md}` are the templates; `.project/execution/` is this repo's live copy. `README.md` is a normal template file, so `--force` refreshes it. `ENTRIES.md` joins `USER_DATA_FILES`, so `--force` never rewrites it. This is the same asymmetry the feedback register runs on, and it is the only reason the register is two files rather than one.

**Seam 2 — the write trigger, restructured.** Close's Step 2 today runs two scans over one artifact set: emergent decisions (`:29`) and product promises (`:30-36`). They are replaced by **one record scan with three destinations**. It reads the same artifacts — `plan.md` deviation notes, `audit.md` findings, `product-lens.md` — asks once whether the item produced anything worth recording, and routes each finding to exactly one home:

- **a decision we made, and the reasoning a future challenge re-derives against** → `.project/adr/`
- **a promise the product now makes** → `.project/product/`
- **how a component, tool, or data format actually behaves, discovered while working** → `.project/execution/`

Candidates surface together in the Step 3 confirmation, and approved entries are filed in Step 4b before `git mv` moves the sources. Removing the `Lessons Learned` auto-population from Step 4d happens in the same edit, which is what keeps one command from prompting for a learning twice.

**Why one scan and not a third one.** Three homes with adjacent subjects need the boundary stated once. Added as a third scan, the register receives nothing: the decision scan runs first and its own text claims "workarounds against another component or repo's behavior" (`:29`), which is the register's headline class. Narrowing the decision scan instead would work, but puts the boundary in two places — the scan and the register's rules — that then have to be kept in agreement by hand.

**Seam 3 — the installer.** `scripts/init-project.sh` takes two edits that carry behavior — `execution/ENTRIES.md` into `USER_DATA_FILES` (`:122-127`), and the `--help` text (`:46-47`) that enumerates the protected files — plus `execution` into both required-subdirectory loops (`:194`, `:209`) for consistency with how `feedback` is handled. The loops are belt-and-braces here rather than load-bearing: `copy_file` already runs `mkdir -p` on each destination, so the directory arrives with its README either way.

**Seam 4 — the triage.** `.project/TRIAGE_MEMORIES.md` arrives through the same recursive template copy as everything else in `project-pack/`, and needs no installer change — `copy_file` at `scripts/init-project.sh:167` already runs `mkdir -p` on the destination. Nothing invokes it; the owner references it in prose, the way they reference the feedback register.

**It has a prerequisite, and the prerequisite is unmet where the memories actually are.** Measured 2026-09-10 across the repos holding native memory entries: five of the six with a `.project/` have no `adr/`, no `product/`, and no `adr.sh` or `product.sh` — `rhb-dispatch-proto` (6 entries), `flex-sim` (1), `Controls-SW-Architecture` (20), `OT-Systems/flow` (14), `flow` (8). Only `echo-workspace` (16) has them, and it has no `execution/` yet. `flow/flow-workflow` (2) has no `.project/` at all. So the prompt states, as its first step: re-run `scripts/init-project.sh` in the target repo — **plain, not `--force`** — which merges the missing registers and scripts in and leaves user data alone.

**Filing route.** The triage files through each home's own rules, not through the register's: `.project/adr/README.md` and `adr.sh` for a decision, `.project/product/README.md` and `product.sh` for a promise, `.project/feedback/README.md` for a pack correction, `.project/execution/README.md` for a behavior fact. Two rules keep it inside existing invariants: ids are never hand-minted (`_my_close.md:78` already says so), and an entry whose ADR **Why** cannot be reconstructed from the memory note becomes a ticket in this repo instead — the escape hatch the owner already specified for facts with no home. Every entry the triage files carries a `Source:` line.

**One-time, not a standing write path.** Owner, 2026-09-10: "it is really one-time, so not worth muddying the skills folder." A once-per-repo sweep does not extend the write maps ADR 0002 and 0008 protect, and no supersession is needed. Recorded here because ADR 0008's rejected alternative is precisely "silent extension of the touch-point map without this record."

**Data flow, one pass:** agent finishes work → close scans artifacts → candidate surfaced in confirm → owner approves → entry appended to `ENTRIES.md` → owner sees it in the diff, since close leaves changes staged and does not commit. Nothing reads the file back at any point.

## Required Invariants

- `execution/ENTRIES.md` is in `USER_DATA_FILES`; `execution/README.md` is not. Both directions are asserted by test.
- No pack instruction reads `execution/ENTRIES.md`. Checkable: a repo-wide grep for the path returns only writes and rules, never a read step.
- Exactly one place in the pack prompts for a learning at close. Checkable by the spec's `Lessons Learned` grep returning nothing.
- Entries are appended; an existing entry's body is never rewritten.
- Nothing is written to the log to record that there was nothing to save. "None found" is reported in the confirmation and leaves no trace in `ENTRIES.md`.
- The bracketed tag is the heading line's second whitespace-separated token, so selection stays a one-liner.
- The register's rules name its three neighbouring registers by path — `.project/adr/`, `.project/product/`, `.project/feedback/ENTRIES.md` — and the two non-register wrong homes: `CLAUDE.md` and the native memory store. Five named destinations, not "four homes."
- Close's record scan and the register's rules state the same three-way boundary, and the scan is the only place it is defined for the write path.

## Component Overview

- **`project-pack/execution/README.md`** — the rules: what belongs here, the density bar with its worked examples, the entry format, the four-way boundary, the native-store line, and the statement that nothing reads the log. Refreshable.
- **`project-pack/execution/ENTRIES.md`** — the log. Header only, zero entries. Protected user data.
- **`.project/execution/`** — this repo's live register, seeded from the above, empty.
- **`claude-pack/commands/_my_close.md`** — gains the scan, the confirm bullet, and the Step 4b write; loses the `Lessons Learned` auto-population.
- **`scripts/init-project.sh`** — seeds the directory and protects the log.
- **`scripts/test_init_project.sh`** — one new test mirroring Test 8: seeded on init, entry survives `--force`, rules refreshed by `--force`.
- **`scripts/test_docs.sh`** — one `check_wired` guard on the close touch point.
- **`README.md` and `project-pack/README.md`** — the register joins the register lists and directory trees, beside the feedback entries at `README.md:27`, `:276` and `project-pack/README.md:60`, `:84`. **Both rows are reworded to name their subject (M8).** Today `feedback/` reads "append-only log of agent learnings" in both files; adding the register as a sibling with the same description defeats the boundary on the one surface a cold agent reads before opening any register README. Feedback holds corrections to the pack's own prompts; execution holds how this codebase and environment behave. `TRIAGE_MEMORIES.md` gets its own row too (m6).
- **`project-pack/TRIAGE_MEMORIES.md`** → **`.project/TRIAGE_MEMORIES.md`** — the triage instructions, seeded into every project and refreshed by `--force`. Referenced directly by the owner; invoked by nothing.
- **`dist/codex/skills/my-close/SKILL.md`** — regenerated, not hand-edited.

## Non-Goals

- Any read or discovery path for the log. Owner decision.
- The `wrap_up` beat. Item 3 owns that file; the measurement is incomplete until it lands.
- Ids, a lifecycle script, or a generated index — the adjacent register's inherited standard is a file with a header.
- Agent-backfilled entries. The template and this repo's log ship empty; the owner-run triage is the deliberate exception and marks what it files.
- Deleting the other repos' native memory directories, or preventing the harness from recreating them.
- `project-pack/epic_template.md`'s epic-retrospective section.
- **Fixing `_my_wrap_up.md:14`, which still routes session learnings at `CLAUDE.md` and `.claude/rules/`** — a home the owner ruled out at owner grade ("I definitely DON'T want them writing to CLAUDE.md directly"). Item 3 owns that file. Carried forward, not fixed here, which means the boundary is not complete until Item 3 ships (m7).

## Implementation Notes

- **Order matters in one place.** Remove the `Lessons Learned` auto-population and add the execution-note beat in the same edit to `_my_close.md`. Between those two changes, close either prompts twice or not at all.
- **The template CHANGELOG edit does not propagate.** `completed/CHANGELOG.md` is protected user data, so removing the section from `project-pack/` reaches new projects only. Existing projects stop accruing the field because the instruction changed. Do not write a migration.
- **Rebuild, never hand-edit `dist/`.** `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy`, per CLAUDE.md. The close description override at `codex-overrides/config.sh:19` was checked against the new scope and needs no change.
- **The five live CHANGELOG sections** are at `.project/completed/CHANGELOG.md:22`, `:43`, `:67`, `:86`, `:104`. Two are the literal `[TODO: Add lessons learned]`.
- **Entry format, for the plan to copy verbatim:**

```markdown
## [init-project.sh] 2026-09-10

**Fact:** `--force` never rewrites `completed/CHANGELOG.md` — it is protected user data, so template edits to it reach new projects only.
**Evidence:** `scripts/init-project.sh:122-127`; asserted by `test_init_project.sh` Test 8.
**Source:** migrated from the native memory store, triaged 2026-09-10.   ← triage-filed entries only
```

- **The tag is normalized** so a future filter can predict it: the file basename, tool name, or format name as it appears in the repo (`init-project.sh`, `flow-mcp`, not `the installer`). Positioned for parseability and free-form in value is not enough on its own (m2).
- **The inherited parseability constraint travels whole:** the second-token rule *and* `.project/feedback/README.md:23`'s "no body line starts with `## [`". The `awk` one-liner's `/^## \[/` anchor is what makes the second rule load-bearing, so carrying only the first silently mis-selects (m8).

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| The log fills with decisions and project context (B1 false) | High — corrupts the evidence the owner decides on | Four-way boundary with worked examples; junk is itself a readable result, and the owner sees every entry in a staged diff |
| The log stays empty because close is the only beat (B2 false) | Med | Item 3 adds the wrap_up beat; until then, emptiness is not yet interpretable and the design says so |
| Three failure modes look identical in the log (B1/B2/B3 indistinguishable) | High — the owner's decision rests on reading it | The triage's results are the disambiguator; the register is not read alone. Stated in *The Point* |
| Close's record scan sends a behavior fact to `.project/adr/` anyway | High — silently empties the log for the wrong reason | One scan, one boundary, three named destinations; the seventh bar example is the confusable case (`.project/adr/0010:36-40`) |
| The triage files into a register that does not exist in the target repo | Med — hand-minted ids against an `[OWNER]` invariant | Plain re-init as step one; never hand-mint; no reconstructable **Why** → a ticket here instead |
| Agents keep writing to the native store instead (B3 false) | Med — biased sample | One line in the rules; no stronger instrument exists inside the pack. Surfaced in the spec as unresolved |
| The triage seeds other repos' logs and blurs the measurement | Med | `Source:` line on every triage-filed entry, so agent-chosen and owner-migrated entries stay distinguishable |
| `--force` clobbers an accumulated log | High — silent data loss | `USER_DATA_FILES` entry plus a test asserting both directions, copied from the precedent that caught this before |
| A future edit to close silently drops the beat | Low | `check_wired` guard in `test_docs.sh` |

## Integration Strategy

The register joins three existing ones and takes the shape of the newest, but it does not arrive into empty space. **Two existing homes stop being the fallback for behavior facts.** `.project/adr/0010:36-40` files what it calls "Two adjacent gotchas this record preserves" — an omission from `NATIVE_SKILL_ALLOWLIST` silently excluding a skill from the Codex build, and a leading `*` crashing Codex's YAML parse. `CLAUDE.md:53` holds a third: Codex silently refuses a skill whose `SKILL.md` is a symlink. All three are behavior facts with no decision attached, filed where they are because there was nowhere else. After this ships, the correct home for that class moves, which is why Step 2 is restructured rather than extended.

The write map itself is unchanged and needs no supersession: close remains the single normal write point for `.project/adr/` (ADR 0002) and `.project/product/` (ADR 0008). What changes is the subject boundary inside close's own scan — an ownership change for one class of fact, which this design settles and which files its own decision record at acceptance.

The rest is additive. The only edit to an existing register's data is the removal of the `Lessons Learned` field, which the owner ordered deleted rather than repointed. An item with nothing to record closes exactly as it does today, with "none" reported.

The close beat is additive and non-blocking: an item with no execution fact closes exactly as it does today, with "none found" reported. Existing projects pick up the register on their next `init-project.sh` run and the rules on every `--force` after that.

## Validation Approach

- **Automated.** New test in `test_init_project.sh`: the register is seeded on init; an appended entry survives `--force`; `README.md` is refreshed by `--force`. New `check_wired` guard in `test_docs.sh`. The spec's `Lessons Learned` grep returns nothing. Full suite green, including `test_codex_orchestrator_pack.sh` against the rebuilt `dist/`.
- **Manual.** Run `/_my_close` on a real item and confirm it prompts for an execution note exactly once, that "none" is accepted without a gate, and that a written entry conforms to the format.
- **The register's own acceptance is deferred by design.** Whether agents file good entries is what the log answers over months, not something this item can verify at close.

## Next-Stage Handoff

**Fixed for the plan:** the two-file layout and their `USER_DATA_FILES` asymmetry; the entry format above; the close beat's placement across Steps 2, 3, and 4b; the `Lessons Learned` deletion in three places; the installer edits (two behavioral, two for consistency); the two new test assertions; rebuild rather than hand-edit for `dist/`.

**Open:** nothing structural. D4 and D8 were both settled by the owner 2026-09-10.

**Decision record to file at acceptance.** D8 narrows what `.project/adr/` owns: behavior facts leave the decision register. That is an ownership change for a class of fact, which the product-lens spec §2 names as the one disposition that files an ADR. Per this command's Stage 3, `adr.sh new` runs after design approval, with owner-ratified provenance, and the product-lens ledger finding cites the entry id. The write map itself is unchanged, so neither ADR 0002 nor ADR 0008 is superseded.

**Riskiest part, and it is not code:** the routing boundary in close's record scan, which is new text and has no precedent to copy. The density bar's six examples are owner-ratified payload and are carried **verbatim** — the plan must not reword them for style (capture-fidelity §2); the seventh example added to close C1 was ratified separately.

---
**Next Step:** After approval → `/_my_plan`.
