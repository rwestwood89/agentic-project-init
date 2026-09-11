# Design Review: Execution Register, Write-Only

**Design:** `.project/active/execution-register/design.md`
**Spec:** `.project/active/execution-register/spec.md`
**Review File:** `.project/active/execution-register/design-review.md`
**Product-lens ledger:** `.project/active/execution-register/product-lens.md` (two design-hop blocks appended 2026-09-10 — an in-session run and the isolated lens subagent's, which returned late; both gates DISPOSED; smell 7 fired in both, smell 2 fired in the lens's)
**Date:** 2026-09-10

---

## The Point

An agent that learns how this codebase or environment actually behaves has exactly one named, git-tracked place to write it, and can tell in one read that the fact belongs there rather than in the decision log, the promise ledger, or the pack-feedback log. **[OWNER]** — concept Success Criteria 3-4 and *Next-Stage Handoff*, "the execution register sits beside them and absorbs neither."

Two obligations sit under that, both owner-grade.

- **The owner reviews what an agent wrote before it carries authority.** **[INHERITED: `.project/concepts/mental-alignment-checkpoint.md:369`]** "I need git tracking. 95% of the time the feedback an agent writes is REALLY bad and needs a revision to be generalized and useful." This is why the register is tracked, append-only, and read by nothing.
- **The register's contents are the evidence for a decision the owner has not made yet** — whether an agent-learning loop is worth building at all. **[OWNER-VERBATIM]** 2026-09-09: "my temptation would be 'D: just don't save durable facts'. But before deciding, I want to at least see *what they would save*."

The consequence the design states about itself, and the standard this review holds it to: a register whose instructions cannot separate an execution fact from a decision produces a log that measures the instructions rather than the agents, and the owner's decision gets made on bad evidence.

---

## Fundamental Assessment

**Concerns.** The work is right and the approach is right. Two structural defects sit on the exact seam the design names as load-bearing — the boundary between homes. One can null the deliverable without anyone noticing; the other sends the owner's own triage into registers that, in five of six target repos, do not exist.

**Is this the right piece of work?** Yes, and the authority is unambiguous — concept SC3 and the *Next-Stage Handoff* are `[OWNER]`, the epic's Item 2 carries them, and the spec's requirements trace to five owner-verbatim quotes. The product-lens design run returns no owner-grade contradiction. Nothing in this review reopens that.

**Is the approach right?** Yes. The register is a copy of `.project/feedback/`, the write beat is a copy of the promise beat, the installer change is a copy of the feedback register's, and the tests are copies of Test 8 and the `check_wired` guard. There is no new machinery anywhere, no invented abstraction, and no premature generality. A senior engineer reading this would not ask "why is this so complicated" — the design's own summary, "two files and a habit," is accurate. Every factual claim in it was checked against the code and every one holds.

**The escalated smell — smell 7, fires.** *The proposed solution changes who owns an invariant without saying so.* The Integration Strategy states: "It changes no existing register's subject and absorbs none of them." That is not true of the ADR register today.

- `.project/adr/0010:35-39` files what it openly calls "Two adjacent gotchas this record preserves": an unlisted skill is silently excluded from `NATIVE_SKILL_ALLOWLIST`, and a leading `*` in a description crashes Codex's YAML parse. Both are pure execution facts by the concept's own test — cost real time, invisible in the code, still true next month, no decision attached.
- `CLAUDE.md:53` holds a third: "Codex silently refuses to register a skill whose `SKILL.md` is a symlink."

So execution facts in this repo were never homeless. They were absorbed by the two homes the design says it is not changing, and after this ships the correct home moves. The design asserts the opposite.

**A second defect on the same seam, from the isolated lens.** The triage is told to file into `.project/adr/` and `.project/product/` and is given no route to either register's filing rules — Seam 4 points only at the execution README, whose Bad examples say "it goes in `.project/adr/`" and stop. ADR 0001 is `[OWNER]` and active: ids are stamped by `adr.sh`, and **Why** is a required body section, "the reasoning a future challenge re-derives against." A one-line memory description has no Why to carry.

**And the write map it extends is itself a recorded decision.** `.project/adr/0008` (active, ratified) states the ledger is "read-only orientation for every stage except `/_my_close`, the single normal write point"; its **Why** says "extending it silently is a premise-conflict failure (the anchor-on-the-point audit BLOCKed exactly that)"; and its **Rejected alternatives** list ends with "Silent extension of the touch-point map without this record." `.project/adr/0002` is parallel for the decision record. The triage is a fifth writer to `.project/adr/` and a second to `.project/product/`, and *Integration Strategy* says "the only edit to an existing register's machinery is the removal of the `Lessons Learned` field." That is the named rejected alternative of a live ratified ADR, not loose phrasing.

I measured how bad this is in the repos the triage actually targets. Of the six memory-holding repos that have a `.project/`, **five have no `adr/`, no `product/`, and no `adr.sh` or `product.sh` at all** — `rhb-dispatch-proto` (6 entries), `flex-sim` (1), `Controls-SW-Architecture` (20), `OT-Systems/flow` (14), `flow` (8). Only `echo-workspace` (16) has them. The triage would be filing decisions into a register that isn't there, with no script to mint an id, in exactly the situation `_my_close.md:78` already has a rule for: "If a script is missing (repo not re-initialized), note the gap; don't hand-mint ids."

**Smell 2 — the lens fires it; I did not.** Its reading: B3's one prose line telling agents away from the native memory store is the pack compensating for a platform facility it cannot switch off. Mine: the harness issues a competing *instruction*, not a *guarantee* being compensated for. Both are defensible, both end at the same disposition — disclosed at spec, the strongest lever foreclosed by concept SC4 — and neither moves the gate. I am recording the disagreement rather than resolving it, because the part that survives either reading is what matters: B3 is one of three independent reasons an empty log cannot be read.

**Why this is escalated but not Rework.** The command's Stage 0 says a fired smell recommends Rework. I am not calling it that, and the reason is worth stating plainly rather than leaving the rubric quietly overridden. Rework means the foundation is wrong. Here the foundation is right and copied from working precedent; what is wrong is one paragraph of self-description and one uncovered routing case. The fix is additive and bounded — a clause in close's decision scan, a Bad example in the bar, and an honest sentence in the Integration Strategy. Throwing out a design that is otherwise entirely correct would cost the item a cycle and buy nothing.

**One thing the design undersells, and it is good news.** B4 says the evidence that execution facts arise is thin. The three facts above are local, verified, and pre-existing — they are proof that the class is real in this repo, which the concept had scoped to zero. Cite them; they raise B4 from "thin evidence across ten projects" to "demonstrated here."

---

## Dimensional Review

### 1. Spec Compliance
**Assessment:** Concerns

Every spec requirement maps to a design element, and the acceptance criteria are addressable. The `[HARD]` `USER_DATA_FILES` pair, the `Lessons Learned` removal in three named places, the ship-empty log, the append-only rule, and the four-way boundary all land somewhere concrete. Four gaps.

- **The load-bearing invariant is not checkable as written.** "The register's rules name all four neighbouring homes, plus the native memory store" — which four? The concept's Key Concept 1 names four *subjects*, one of which is the register itself, so it has three neighbouring registers. The spec's `[INFERRED]` requirement inherits the same slip. The plan resolved it as `adr/` + `product/` + `feedback/ENTRIES.md` + `CLAUDE.md`, which is a reasonable guess but a guess. An auditor checking the item's load-bearing invariant should not have to guess what it counts.
- **The handoff invites the plan to reword owner-ratified payload.** *Next-Stage Handoff*: "If the plan phase has time to spend anywhere, spend it there" — "there" being the density bar and the boundary. But the spec commits to carrying the bar "with wording changes only for fit," the owner ratified all six examples 2026-09-10 ("I'm good with those examples"), and the lens's spec-F2 disposition already said a change beyond that goes back to the owner. Capture-fidelity §2 puts owner payload beyond an agent's discretion to improve. The plan happened to get this right (`plan.md:87`, "verbatim from the spec's approved draft"), but the design told it the opposite.
- **The triage prerequisite is unstated, and unmet where the memories are.** Seam 4 reads as though the prompt "arrives in every project" automatically. It arrives only in re-initialized projects. Measured 2026-09-10: `echo-workspace` (16 entries) has `feedback/` but no `execution/`; `rhb-dispatch-proto` (6), `flex-sim` (1), `Controls-SW-Architecture` (20), `OT-Systems/flow` (14) and `flow` (8) all carry a `.project/` predating the feedback register; `flow/flow-workflow` (2) has no `.project/` at all. `copy_file` at `scripts/init-project.sh:167` merges missing files on a plain re-run, so this is one sentence of sequencing, not a mechanism.
- **The entry-format block the plan is told to copy verbatim omits the `Source:` field** that D2 requires for triage-filed entries. Minor, but the block is labelled "for the plan to copy verbatim."
- **The inherited parseability constraint is carried only half.** D3 and the Required Invariants carry the second-token rule. They omit the other half the `awk` one-liner depends on: `.project/feedback/README.md:23`, "**No body line starts with `## [`.** That sequence marks the start of an entry." The one-liner's `/^## \[/` anchor is what makes that prohibition load-bearing, so "the adjacent register's `awk` one-liner works unchanged" is true only if both rules travel together. Capture-fidelity §2 — an inherited constraint carried partially is carried wrong.

### 2. Pattern Consistency
**Assessment:** Pass

This is the design's strongest dimension, and I checked every claim rather than taking it on faith.

- The two-file split and its `--force` asymmetry match `.project/feedback/` exactly, and the reason is real: `USER_DATA_FILES` at `scripts/init-project.sh:122-127`, `is_user_data` matching on exact `rel_path`.
- The tag-as-second-token rule matches `.project/feedback/README.md:30-33`, and the `awk` one-liner there does work unchanged.
- The close beat's Step 2 / Step 3 / Step 4b placement matches the promise beat exactly, including its posture — `_my_close.md:50-53` does say "Zero is the common case; close proceeds on 'none' — this is never a gate."
- The new `test_init_project.sh` case mirrors Test 8 (`:228-265`) in both directions, and the `check_wired` guard mirrors `test_docs.sh:84`.
- No script, no ids, no index — matching the feedback register rather than ADR/product, which is what the spec and epic non-goals require.
- `project-pack/TRIAGE_MEMORIES.md` at the `.project/` root has a standing precedent in `project-pack/EPIC_GUIDE.md`, a root-level uppercase instruction doc referenced by path.
- D4's placement call is authorized. ADR 0009 governs `claude-pack/` capabilities; a `project-pack/` template is outside its scope, and the owner decided the form directly.

### 3. Abstraction Quality
**Assessment:** Pass

There are no new abstractions to justify. Two markdown files, one scan added to an existing command's existing rhythm, two list entries in a shell script, two test cases. Removing any of them makes something worse: drop the two-file split and `--force` eats the log; drop the `USER_DATA_FILES` entry and the same; drop the test and the pack repeats a failure it has already had once. The design also correctly declines the abstraction a weaker version would have reached for — a shared "register" template or a `execution.sh` lifecycle script — and the non-goal is stated with its reason.

### 4. Duplication Avoidance
**Assessment:** Concerns

Four registers now ship four rule documents with the same shape, and the design chooses that deliberately. That is the right call — a shared abstraction over four markdown READMEs would be worse than the duplication. Two drift risks the design does not name.

- **The four-way map lives in one direction only.** `.project/execution/README.md` will name its neighbours; `.project/adr/README.md`, `.project/product/README.md` and `.project/feedback/README.md` say nothing about it. An agent that opens the execution README gets the map. An agent that reaches a fact through the decision scan never opens it. This is the structural face of the Critical finding below.
- **`_my_wrap_up.md:14` still routes learnings at CLAUDE.md** — "If session learnings aren't distilled into these auto-loaded files, the next session will re-research the same things," where "these" is CLAUDE.md and `.claude/rules/`. That is a live pack instruction pointing at a home the owner ruled out at `[OWNER]` grade ("I definitely DON'T want them writing to CLAUDE.md directly"). Item 3 owns that file, so this is a carry-forward, not a scope expansion — but the design's four-way boundary should not be described as complete while it stands.

### 5. Data Structure Clarity
**Assessment:** Concerns

The entry is well-defined: a tagged heading, **Fact**, **Evidence**, plus **Source** for triage-filed entries. Two frictions.

- **The tag's two justifications pull against each other.** D3 fixes the tag's *position* so a future line-oriented filter needs no parser, then makes the tag's *value* free-form ("a script, a tool, a data format"). A future reader with a working `awk` still cannot select reliably, because they cannot predict the token. One sentence of normalization (the file basename, tool name, or format name as it appears in the repo) closes it at no cost.
- **The `Source:` field is absent from the format block** the plan is told to copy verbatim, as noted above.

### 6. Route Safety
**Assessment:** Fail

Read as scan routing, this is where the Critical finding lands. Close will run three scans over one artifact set, in a fixed order, and the first one claims the new register's flagship case.

`_my_close.md:29` — the decision scan, Step 2.4, running before anything the design adds — instructs the agent to look for "discovered constraints, deviations from the design, **workarounds against another component or repo's behavior**." `.project/adr/README.md:74-78` then routes that class to the upholding repo's ADR plus a local pointer.

The execution bar's flagship Good example is: "The MCP server times out on startup because its venv imports off `/mnt/c` NTFS. Use a venv on native ext4."

That is a workaround against another component's behavior, discovered by a consumer. Both bars claim it, the ADR claim is read first, and the design changes nothing in the decision scan. The bar's first Bad example ("that is a decision with reasoning behind it") draws the line correctly — but only for an agent that has already opened the execution README, which an agent consuming the fact upstream never does.

**The same dimension, second case.** The triage routes facts into four homes and is handed the filing rules for one. In five of the six target repos those homes have no directory and no script, so the route terminates nowhere. The failure mode is the mirror of the first: instead of a fact landing in the wrong real register, a fact lands in a register that must be hand-fabricated against an `[OWNER]` invariant that forbids it.

The failure is silent and it lands on the deliverable: the fact files as an ADR, the execution log stays empty, and emptiness is exactly the signal the owner will read as "agents had nothing to save." The fallback behavior is not safe, because the wrong route produces a plausible-looking record in a real register rather than an error.

### 7. Bets & Decisions Integrity
**Assessment:** Concerns

The bets are genuine claims about reality, each with a stated "if false," and the decisions each name a rejected alternative with a reason. That is better than most. Three problems.

- **B2 cites the favorable half of its own source.** It reads "the trigger design that gave `.project/adr/` 12 entries while owner prose gave `.project/feedback/` 0." The concept's Appendix A attributes those 12 to two things together: "The register with an unskippable write gate **and an enforced read** has 12 entries." This register ships with no read path, by owner decision, and `.project/adr/0002:24` calls the enforced read "the only read enforcement that works." The nearest read-less precedent is the promise beat — same command, same shape, live since 2026-08-09 — at 0 entries across the two closes since. Two closes cannot falsify B2. But the design should state the precedent it actually resembles, because the owner will read the resulting log against it.
- **A hidden bet, and the isolated lens states it more sharply than I did: the artifacts close reads contain the facts.** D5 points the scan at `plan.md` deviation notes, `audit.md` findings, and `product-lens.md`, and rejects introspection with a good reason (close is often run by a session that did not implement). The consequence is that the scan can only find facts someone already wrote down. Every execution fact this work has actually measured is a debugging-session fact that never reaches those artifacts — the MCP venv on `/mnt/c` NTFS, subagent registration by launch directory, PDF transcription errors in load-bearing numerals — and all four were written unprompted, in session, to the native store. The bar's Good examples advertise exactly that class. So the design inverts its own trigger ladder: the strong trigger harvests the surface that does not carry the payload, and the weak one (`wrap_up`, Item 3, optional) carries it. This and the B2 point above are one defect seen from two sides. The lens offers a fix that does not fight D5's stated reason: scan the artifacts always, **and also** ask when the close session did the implementation.
- **B3's "no stronger instrument exists inside the pack" is asserted, not derived.** The pack has two always-on surfaces — `claude-pack/rules/` and the project's CLAUDE.md — where a don't-use-the-native-store line would reach an agent *before* it writes a memory, rather than at close when it is already writing to the register. There are good reasons not to spend the always-on budget (the concept is scathing about it, and concept SC4 keeps the *write* out of rules). But "we considered an always-on line and rejected it because the budget costs more than the bias" is a different claim from "no instrument exists," and only the first is true.

### 8. Reader Comprehension
**Assessment:** Pass

A reader unfamiliar with this can skim it once and come away with the model. The Overview lands the whole thing in a sentence, *Core Concept* gives the frame ("two files and a habit") before any mechanism, and *The Point* states the obligation and the two things under it in plain words with their provenance. Terms are anchored where they are introduced, references carry locations rather than bare names, and the structure mirrors the logic. The one comprehension defect is the "four neighbouring homes" ambiguity in *Required Invariants*, already recorded under Dimension 1 — it is a counting slip, not dense prose, but it sits on the one invariant a reader most needs to be able to check.

---

## Issues by Severity

### Critical

- **C1 — The close decision scan claims the register's flagship class, first, over the same artifacts.** `_my_close.md:29` and `.project/adr/README.md:74-78` route "workarounds against another component or repo's behavior" to the ADR register; the execution bar's headline Good example is exactly that. Precedent confirms it is already happening: `.project/adr/0010:35-39` and `CLAUDE.md:53` hold execution facts filed for want of a home. The failure is silent, and it empties the log for the wrong reason. — Dimension 6, Dimension 4; product-lens design-F1; smell 7.

- **C2 — The triage has no route to the filing rules of three of the four homes it writes into, and in five of six target repos those homes do not exist.** ADR 0001 (`[OWNER]`, active) stamps ids via `adr.sh` and requires a **Why** a one-line memory note cannot supply; `rhb-dispatch-proto`, `flex-sim`, `Controls-SW-Architecture`, `OT-Systems/flow` and `flow` have no `adr/`, no `product/`, and no scripts. It also adds a writer to two register write maps that are themselves recorded decisions, while asserting nothing changed — the named rejected alternative of ADR 0008. — Dimension 6, Dimension 1; product-lens lens-F1; smell 7; subsumes M5.

### Major

- **M2 — "The register's rules name all four neighbouring homes" is not checkable as written.** The register has three neighbouring registers; the fourth slot is `CLAUDE.md`, which is not one of the concept's four homes, and the native store makes a fifth wrong home. Name them. — Dimension 1.
- **M3 — The handoff tells the plan to spend its effort rewording owner-ratified payload.** The bar's six examples were ratified by the owner and the spec commits to "wording changes only for fit." Capture-fidelity §2. — Dimension 1.
- **M4 — B2 borrows a precedent's number while dropping the enforced read its own source credits it to,** and omits the read-less precedent in the same command at 0 entries. This shapes how the owner reads the result, which is the item's deliverable. — Dimension 7; product-lens design-F2.
- **M5 — *(promoted into C2)*** The triage's re-init prerequisite is unstated and unmet in every repo holding memories. Kept as a separate line because its fix is separable: one sentence of sequencing. — Dimension 1; product-lens design-F3.
- **M7 — The log has three independent ways to become uninterpretable and no stated way to tell them apart.** B1 junk, B2 empty-because-close-is-the-only-beat, B3 written-to-the-native-store. The owner's own 2026-09-10 disposition already supplies the disambiguator — the triage's results confirm or correct the reading — but it lives only in the ledger, not in *The Point* or the risk table. The item otherwise ships an instrument whose readings are ambiguous by construction. — Dimension 7; product-lens lens-F3.
- **M8 — Two rows on the product's front door will both say "agent learnings."** `README.md:27` and `project-pack/README.md:60` already describe `feedback/` that way, and the register joins as a sibling row. That is the one surface a new user and a cold agent read before reaching any register README, so the four-way boundary is defeated at the door. The fix is to make both rows name their subject — pack-prompt corrections, versus how this codebase or environment behaves. — Dimension 4; product-lens lens-F4.
- **M6 — Hidden bet: the artifacts close reads contain execution facts.** D5's scan can only find what was already written down; both Good examples are the kind that get solved and never noted. — Dimension 7.

### Minor

- **m1 — The entry-format block "for the plan to copy verbatim" omits the `Source:` field** D2 requires. — Dimension 5.
- **m2 — The tag is positioned for parseability and valued free-form.** One normalization sentence closes it. — Dimension 5.
- **m3 — B3's "no stronger instrument exists inside the pack" overstates.** Two always-on surfaces exist; say they were rejected on budget, not that they are absent. — Dimension 7.
- **m4 — B4 understates its own evidence.** ADR 0010 and `CLAUDE.md:53` are local, verified proof that the class arises and was homeless. — Dimension 7.
- **m8 — D3 carries half of the inherited parseability constraint.** Add `.project/feedback/README.md:23`'s "no body line starts with `## [`" alongside the second-token rule, or the `awk` one-liner silently mis-selects. — Dimension 1, Dimension 5.
- **m5 — `TRIAGE_MEMORIES.md` is undeletable in practice.** `copy_file` re-adds a missing template file on any plain `init-project.sh` run, so a one-time prompt deleted after use comes back. D4's "seeding costs nothing" should say what it does cost. — Dimension 2.
- **m6 — `TRIAGE_MEMORIES.md` is not added to the layout doc.** The component list updates the register lists and folder trees in `README.md` and `project-pack/README.md` for the register but not for the new root-level file. — Dimension 1.
- **m7 — `_my_wrap_up.md:14` still points session learnings at CLAUDE.md.** Item 3's file; carry it forward rather than describing the boundary as complete. — Dimension 4.

---

## Recommendations

1. **Close C1 in the design, not the plan.** Three small edits: a clause in close's decision scan separating a decision we made from how the thing behaves and pointing the second at the register; a Bad example in the bar covering a gotcha an ADR would otherwise absorb (`.project/adr/0010:35-39` is the ready-made case); and an honest sentence in *Integration Strategy* replacing "changes no existing register's subject" with what actually happens — the ADR register and CLAUDE.md stop being the fallback home for this class. The new Bad example is a change beyond "wording changes only for fit," so it goes to the owner, which is the right route for it anyway.
2. **Name the four homes explicitly in the invariant** (M2), and drop the "spend time on the wording" line from the handoff in favour of "carry the ratified bar verbatim" (M3).
3. **Fix B2's evidence** (M4) and add the artifacts-contain-the-facts bet (M6). Both are two-line edits and both protect the reading of the result rather than the mechanism.
4. **Close C2 with two sentences in D4/Seam 4.** First, sequencing: the owner re-runs `scripts/init-project.sh` in the target repo before triaging — **no `--force`**, which I verified seeds `adr.sh`, `product.sh`, `adr/README.md`, `product/README.md` and the feedback pair into a stale `.project/` while leaving user data untouched. Second, the filing route: the triage files through each home's own README and script, and an entry whose ADR **Why** cannot be reconstructed becomes a ticket in this repo — the escape hatch the owner already specified — rather than a hand-minted ADR.
5. **Put one question to the owner: is the triage one-time, or a standing write path?** It decides smell 7's disposition. One-time, and a sentence in the design is enough. Standing, and the product-lens spec §2 is explicit that a smell-7 ownership change is the one disposition that files an ADR — `adr.sh new`, owner-ratified provenance, the ledger finding citing the entry id.
6. **Carry the disambiguator into the design** (M7) and **make the two front-door rows name their subjects** (M8). Both are one-liners with outsized effect: the first is what lets the owner read the result at all, the second is where a cold agent forms the boundary before it ever opens a README.
7. **Sweep the Minors in one pass** — they are all one-liners, and m4 makes the design's own case stronger.
8. **Note for sequencing:** `plan.md` was drafted before this review. Resolutions that change the design need to reach the plan too. The plan is in good shape and already got M3 right on its own.

---

## Resolutions

Recorded 2026-09-10 by the design agent. All findings incorporated into `design.md`; design changes carried into `plan.md` per Recommendation 8.

- **C1 — RESOLVED, by restructuring rather than narrowing.** Owner chose, from three options with their costs, that close's Step 2 becomes **one record scan with three destinations** replacing the separate decision and promise scans (`design.md` D8, Seam 2). Rejected in the same call: a third scan (receives nothing, since `_my_close.md:29` claims the class first) and narrowing the decision scan (boundary in two places). Integration Strategy rewritten to state what actually changes, naming `.project/adr/0010:36-40` and `CLAUDE.md:53` as the existing instances. A seventh bar example added (D9), authored under owner delegation, drawn from the ADR 0010 case. The write map is unchanged, so ADR 0002 and 0008 stand; the ownership change files its own ADR at acceptance.
- **C2 — RESOLVED.** Seam 4 now states the prerequisite (plain `init-project.sh` re-run in the target repo, never `--force`), the filing route through each home's own README and script, the never-hand-mint rule citing `_my_close.md:78`, and the no-reconstructable-**Why** → ticket escape hatch. The measured five-of-six gap is recorded in the design. One-time versus standing settled at owner grade ("it is really one-time"), so no supersession.
- **M2 — RESOLVED.** The invariant now names five destinations by path — three registers plus `CLAUDE.md` and the native store — and drops "four homes."
- **M3 — RESOLVED.** The handoff no longer invites rewording; it says the six ratified examples are carried verbatim per capture-fidelity §2, and names the routing boundary as the actual risk.
- **M4 — RESOLVED.** B2 now states the enforced read its source credits, and names the promise beat (same command, no read, 0 entries across two closes) as the precedent this register actually resembles.
- **M5 — RESOLVED into C2** as the sequencing sentence.
- **M6 — RESOLVED.** Added as **B5** ("the artifacts close reads contain execution facts at all") with the evidence against it, and D5 amended to the lens's fix: scan the artifacts always, and also ask the session when that session did the implementation.
- **M7 — RESOLVED.** The disambiguator is now in *The Point* and the risk table: the register's contents and the triage's results are one instrument with two readings, neither interpretable alone.
- **M8 — RESOLVED.** Both front-door rows are reworded to name their subject — feedback holds pack-prompt corrections, execution holds how the codebase and environment behave.
- **m1, m2, m8 — RESOLVED.** The format block gains `Source:`, a tag-normalization rule, and the second half of the inherited parseability constraint (`.project/feedback/README.md:23`).
- **m3 — RESOLVED.** B3 now says the always-on instrument was rejected on budget rather than absent.
- **m4 — RESOLVED.** B4 cites the three local pre-existing facts.
- **m5 — RESOLVED.** D4 states what seeding costs: `copy_file` re-adds the prompt on any plain re-init.
- **m6 — RESOLVED.** `TRIAGE_MEMORIES.md` gets its own doc row.
- **m7 — RESOLVED as a carry-forward.** `_my_wrap_up.md:14` is named in Non-Goals as Item 3's, with the consequence stated: the boundary is not complete until Item 3 ships.
- **Smell 2 disagreement — left as recorded.** Neither reading moves the gate, and what survives both is M7's point, which is now in the design.

---

**Overall:** Revise
**Next Steps:** Once resolutions are recorded here, re-run `/_my_design` (or return to the design-agent session) and point it at this review to incorporate, then carry any design changes into `plan.md`. The reviewer does not edit the design.
