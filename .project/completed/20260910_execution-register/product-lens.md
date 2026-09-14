# Product-Lens Ledger: execution-register

Append-only. Each block is one product-lens run, in the format of `claude-pack/scripts/product-lens.md` §3.

**Epic: KNOWLEDGE-HOMES** (`.project/backlog/epic_knowledge_homes.md`, Item 2). Ship gates and audit resolve this reference against the epic's live Product-Lens gate, which is the source of truth. Epic findings that exist as of this item's creation, referenced at their original source grades:

- `epic_plan-F1` — grade: **owner** — BLOCK, dispositioned by the owner 2026-09-09; the fix is claimed by this item.
- `epic_plan-F2` — grade: **INHERITED/aspirational** — RESOLVED in the epic by correcting Item 1's scope.
- `epic_plan-F3` — grade: **agent/ratified** — RESOLVED in the epic.
- `epic_plan-F4` — grade: **owner-verbatim reason vs. agent-measured counts** — OPEN by design; carried into Item 3's spec, not this one.

---

## spec — 2026-09-10 — rev .project/active/execution-register/spec.md (uncommitted)

Point (re-derived): Execution facts get exactly one named, git-tracked home that ships with
write instructions and no reader, seeded into every initialized project, whose instructions let
an agent tell in one read that a fact belongs there and not in a neighbouring register — and
whose contents are what answers the owner's question, "what would they save."
  [source: .project/concepts/agent-knowledge-and-enforcement.md — Success Criteria 3-4,
   Non-Goals, Next-Stage Handoff ("sits beside them and absorbs neither"), Owner's Words
   2026-09-09; grade: owner]
  [secondary: docs/guide.md:9 "each kind of decision has a home and a written record"
   (INHERITED); .project/adr/0002 Why — a write attaches to a gate the item cannot skip
   (agent/ratified)]

Falsifier: the register's instructions name fewer than the neighbouring registers an agent could
mis-file into, so an agent at close cannot tell in one read which of four homes a fact belongs
in; or the spec states, in its own voice, a different question than the owner's as the thing the
register's contents will answer.

Findings:

- spec-F1 [DON'T] The Problem section re-answers, at agent grade with no provenance marker, the
  question the owner said the register exists to answer — "It is no longer *would agents save
  anything at all* ... It is *when prompted, will agents file an execution fact in the right home
  at the right density*" — against owner-verbatim "before deciding, I want to at least see *what
  they would save*." The reframe rests on 15 one-line descriptions read this session, and the
  spec's own Open Question 3 says a proper read of the 61 entries "would produce the judgement
  the concept deferred to its criterion 9 without waiting on the register to fill" — i.e. a
  cheaper route to the owner's actual question, parked in Open Questions. capture-fidelity §4
  puts the owner first and "loudly in the artifact" second; the owner was reachable, with two
  recorded exchanges in this drafting session, and got the layout and the density-bar text but
  not this.
  — source: concept Owner's Words 2026-09-09 + Key Concept 3 + Next-Stage Handoff ("judged by
    what agents put in it"), and claude-pack/rules/capture-fidelity.md §4 (owner)
  — disposition: DISPOSE-and-proceed. Not BLOCK: no requirement changes because of the reframe,
    and the spec explicitly declines to claim the concept is falsified ("Nothing in the concept
    is falsified by that"). Fix is two lines: mark the reframe [AGENT] pending owner
    disposition, and put Open Question 3 to the owner as a decision — read the 61 entries now,
    or ship and wait — rather than leaving it as a deferred research candidate.
  Observable: a downstream design or audit agent reads the Problem section as settled ground
  truth for what the register measures, and the owner judges the register's contents against a
  question they did not ask.

- spec-F2 [DO] The register's instructions guard two of the four homes. The owner-approved
  density bar's Bad examples point at `.project/adr/` and `CLAUDE.md`, and one [INFERRED] line
  points at the native memory store — nothing distinguishes an execution fact from a
  **pack-prompt correction** (`.project/feedback/ENTRIES.md`) or a **promise**
  (`.project/product/`). Feedback is the largest measured mis-file class in the spec's own
  evidence: 23 of 61 native entries are `feedback`-typed, against 0 in the feedback log. The
  spec states the test "turns on the boundary" and that "roughly half of what agents already
  saved belongs somewhere else," then ships boundary text covering half the boundary.
  — source: concept Next-Stage Handoff "[OWNER] ... absorbs neither" (owner); Key Concept 1
    "four homes, each with a boundary test against its neighbour" and US-2 (AGENT)
  — disposition: DISPOSE-and-proceed. The spec-level scope requirement is met (the register
    absorbs neither subject); what is missing is the write-time instruction text, which the
    design stage authors next. Carry as a named design requirement. Note the approved density
    bar is `[INFERRED] (ratified by owner)`, not owner-originated, so it is challengeable by
    re-deriving — but the spec commits to carrying it "with wording changes only for fit," so a
    third Bad example is a change beyond that and goes back to the owner.
  Observable: an agent at close holds "the spec command made me over-grade requirements," reads
  the register's README once, and files it as an execution fact.

- spec-F3 [DO] No requirement states entries are append-only. The concept's constraint is
  "git-tracked, append-only, and owner-promoted," rooted in the inherited 95% rule — the owner
  must see what the agent originally wrote in a diff, not a rewrite. The adjacent register made
  this an explicit [NEED] ("Entries are appended. An existing entry is never rewritten.");
  here it is carried only implicitly by "mirrors `.project/feedback/` exactly," which the spec
  states about the two-file shape.
  — source: concept Why This Shape, "Constraint to preserve downstream: the 95% rule" (AGENT,
    on [INHERITED] owner-verbatim "I need git tracking") — disposition: DISPOSE-and-proceed;
    one requirement line.

Smells fired: none. Smell 7 was considered and does not fire — the spec says in prose what it is
doing with the register's purpose, so the defect is an ungraded hop (F1), not a silent one.
Both smells from the epic block are cleared by this spec: smell 1 and smell 5 fired on
epic_plan-F1's two-homes-one-subject defect, and the field is removed outright here — not
repointed, not reduced to a pointer.

Resolves:
- epic_plan-F1: FIXED — authority: owner (2026-09-09, "remove this. I do not want this at all")
  — basis: spec [NEED] removes the field in three named places, verified live
  (`_my_close.md:98`, `project-pack/completed/CHANGELOG.md:19`, five sections in
  `.project/completed/CHANGELOG.md`), with SC6 as the grep. The one live section that meets the
  density bar is not orphaned by ship-empty: "Separate refreshable instructions from append-only
  user data when `--force` updates templates" is already recorded as the Test 8 comment at
  `scripts/test_init_project.sh:229-231`, which the spec's own [HARD] requirement cites. Of the
  other four, two are the literal `[TODO: Add lessons learned]` and two are retrospective taste
  notes below the bar. Nothing real dies undocumented — worth one line in the spec, since the
  epic's F1 disposition carried the clause "nothing real is deleted without a home."

Checked, no finding:
- Both recorded dispositions are graded correctly. Ship-empty is [NEED] carrying the
  owner-verbatim quote (capture-fidelity absorb mapping, [OWNER-VERBATIM] → [NEED]); the density
  bar is [INFERRED] (ratified by owner), which is right for an agent draft the owner approved —
  "that looks good" ratifies, it does not originate. The ship-empty reversal of the epic's
  In-Scope migration line is recorded as an amendment, and the rejected path has its designated
  home in Non-Goals ("Backfilling entries from existing knowledge"), phrased as a decision
  record, not an instruction — capture-fidelity §3 satisfied.
- Concept SC4's wrap_up half is parked, not dropped: the Non-Goal says so and states the
  consequence ("the measurement is not complete until Item 3 ships"). Honest decomposition, not
  a narrowing.
- No read path is introduced. The four density-bar examples are reworded from real native-store
  entries but live in the instructions file, never the log, and the spec reconciles this
  explicitly. The anchoring effect is real and the spec's reframe already accounts for it; the
  alternative (a bar with no worked pair) is the feedback register's shape, which has 0 entries.
- Every load-bearing citation verified: `init-project.sh:122-127` USER_DATA_FILES exact;
  `test_init_project.sh:229-231`; `_my_close.md:98` Lessons Learned default; the close beat's
  Step 2 / Step 3 / Step 4b structure and the promise scan's "close proceeds on none";
  `README.md:27` and `:276`, `project-pack/README.md:60` and `:84` all correct. SC6's grep
  narrowing to `project-pack/completed/` is right — `project-pack/epic_template.md:144` carries
  the Post-Completion section, so the epic's grep over all of `project-pack/` could never pass.

Gate: DISPOSED (spec-F1, spec-F2, spec-F3)

### Dispositions applied to the spec, 2026-09-10

- **spec-F1** — the reframe is marked `**[AGENT]**` in the Problem section with a pointer to Open Questions, and Open Question 3 is rewritten as an owner decision (read the 61 entries now, or ship and wait). **Open: needs the owner's disposition.**
- **spec-F2** — a named `[INFERRED]` requirement now says the instructions guard all four neighbouring homes, and two Bad examples (feedback, product) are drafted into the bar and flagged in the spec as an amendment beyond "wording changes only for fit." **Open: the two added examples need owner ratification.**
- **spec-F3** — carried as an `[INHERITED]` requirement: entries are appended, never rewritten, citing the concept's 95%-rule constraint and its inherited owner-verbatim source.
- **epic_plan-F1's "nothing real is deleted without a home" clause** — discharged in the spec's backfilling Non-Goal, naming where the one bar-meeting lesson already lives.

### Owner dispositions, 2026-09-10 (append)

- **spec-F1 — resolved as a decision, reframe still unratified.** The owner chose to proceed with implementation rather than read the 61 entries as a research item first, and added a deliverable that supersedes the read: a prompt they take to each repo to triage its native memory entries into `.project/` homes, with anything important that fits no home becoming a ticket in this repo. The reframe paragraph stays **[AGENT]** and unratified; the triage now carries its evidence route, so the triage's results confirm or correct it.
- **spec-F2 — ratified.** Owner 2026-09-10: "I'm good with those examples." The two added Bad examples (feedback log, product ledger) are part of the approved bar; the bar now guards all four neighbouring homes.
- **spec-F3 — closed at owner grade.** Owner 2026-09-10: "Yes, append-only is a requirement." Upgraded from `[INHERITED]` to `[NEED]`; the inherited 95%-rule authority is retained as upstream reasoning.
- **New premise recorded, not a finding against the spec.** The owner-run triage will file entries into other repos' logs, so those logs do not ship empty. The epic's blanket no-backfill non-goal is amended at owner grade, and a provenance line on every triage-filed entry is what keeps the register's contents readable as evidence of what agents chose to save.

---

## design — 2026-09-10 — rev .project/active/execution-register/design.md (uncommitted, drafted at 78ea3b5)

**Run provenance:** the call site spawned a `general-purpose` subagent per the command; it had not returned when this block was written, so the run was completed in-session against the same SOURCES/WORK split. **Corrected same day:** the subagent's verdict did arrive, and is recorded in the block below. This block was not produced by an isolated lens; that one was. Read them together.

Point (re-derived): Each kind of knowledge an agent produces has exactly one home and a written record, and the write attaches to a gate the item cannot skip. For execution facts specifically: one named, git-tracked place, which the agent knows exists without being handed its contents, sitting beside the decision log and the promise ledger and absorbing neither.
  [source: docs/guide.md:9 "The commands exist so that each kind of decision has a home and a written record" (INHERITED/aspirational); .project/concepts/agent-knowledge-and-enforcement.md Success Criteria 3 and Next-Stage Handoff "the execution register sits beside them and absorbs neither" (owner); .project/adr/0001 (live, [OWNER]) decisions are recorded append-only in .project/adr; .project/adr/0002:24 and 0008 — a write attaches to a gate the item cannot skip (agent/ratified)]

Falsifier: after this ships, a fact meeting the execution bar has more than one live pack instruction claiming it, so an agent at close routes it somewhere other than the register — and the log's emptiness cannot be read as "agents had nothing to save."

Findings:

- design-F1 [DO] The design leaves a live competing claim on the register's own subject, in the same command, over the same artifacts, in a scan that runs first. `_my_close.md:29` (the decision scan) claims "discovered constraints, deviations from the design, workarounds against another component or repo's behavior," and `.project/adr/README.md:74-78` routes that class to `.project/adr/` in the upholding repo plus a local pointer. The execution bar's flagship Good example — "The MCP server times out on startup because its venv imports off `/mnt/c` NTFS. Use a venv on native ext4" — is exactly that class. The design changes nothing in the decision scan and its Required Invariants do not cover the overlap. Not theoretical: `.project/adr/0010:35-39` records "Two adjacent gotchas this record preserves" (an unlisted skill is silently excluded from `NATIVE_SKILL_ALLOWLIST`; a leading `*` crashes Codex's YAML parse) — both pure execution facts by the concept's own test, filed into an ADR because no register existed. `CLAUDE.md:53` holds a third ("Codex silently refuses to register a skill whose `SKILL.md` is a symlink").
  — source: concept Key Concept 1 four-way boundary and US-2 "tell in one read" (AGENT, the execution-fact test is self-marked `[AGENT]`); spec's four-way requirement is `[INFERRED]`, the bar `[INFERRED] (ratified by owner)`
  — disposition: DISPOSE-and-proceed. Agent/ratified grade, not owner-originated, so not a BLOCK. Fix is bounded and additive: a clause in close's decision scan separating "a decision we made" from "how the thing behaves," and one Bad example in the bar covering a gotcha an ADR would otherwise absorb.
  Observable: an agent at close files the NTFS fact through the decision scan, the execution log stays empty, and the owner reads the emptiness as agents having nothing to save.

- design-F2 [DON'T] B2 borrows a precedent's number while dropping the feature its own source attributes that number to. The design's B2 reads "the trigger design that gave `.project/adr/` 12 entries while owner prose gave `.project/feedback/` 0." The concept's Appendix A attributes the 12 to two things together: "The register with an unskippable write gate **and an enforced read** has 12 entries." This register ships with no read path, by owner decision. The nearest read-less precedent is the promise beat — same command, same scan/confirm/file shape, live since `_my_close.md:122` (2026-08-09) — with 0 entries across the two closes since (`20260820_mental-alignment-design-v1`, `20260826_feedback-capture-file`). Two closes is not enough to falsify B2; it is enough that the design should not cite only the favorable half.
  — source: concept Appendix A (the concept's own measurement) and `.project/adr/0002:24` "the only read enforcement that works" (agent/ratified)
  — disposition: DISPOSE-and-proceed; two lines in the design. This protects the reading of the result, which is the item's whole deliverable.
  Observable: an empty log is reported to the owner as evidence about agents, when the design's own cited precedent predicts emptiness from a read-less trigger either way.

- design-F3 [DO] The triage deliverable's prerequisite is unstated and unmet where the memories actually are. Seam 4 reads as though the prompt "arrives in every project" automatically; it arrives only in projects that are re-initialized. Measured 2026-09-10 across the repos holding native memory entries: `echo-workspace` (16 entries) has `.project/feedback/` but no `execution/`; `rhb-dispatch-proto` (6), `flex-sim` (1), `Controls-SW-Architecture` (20), `OT-Systems/flow` (14) and `flow` (8) all carry a `.project/` predating the feedback register — no `feedback/`, no `execution/`; `flow/flow-workflow` (2) has no `.project/` at all. `scripts/init-project.sh:167` merges missing files on a plain re-run without `--force`, so the fix is one sentence, not a mechanism.
  — source: spec SC8 and its three owner-verbatim `[NEED]`s (owner obligation); the gap is the design's silence, graded INFERRED
  — disposition: DISPOSE-and-proceed; one line in Seam 4 naming the re-init step and the repo with no `.project/`.

Smells fired:

- **Smell 7 — FIRES.** The proposed solution changes who owns an invariant without saying so. Integration Strategy states "It changes no existing register's subject and absorbs none of them." The ADR register and `CLAUDE.md` are the de facto homes for execution facts today (`.project/adr/0010:35-39`; `CLAUDE.md:53` and `:60-66`), and after this ships that ownership moves to `.project/execution/`. The design asserts the opposite. Must escalate into the stage's leading judgment; escalation is not resolution.
- Smell 2 — considered, does not fire. The register's one-line counter to the harness's native-memory instruction is the pack answering a competing platform *instruction*, not compensating for a platform *guarantee*, and the spec surfaces the underlying premise conflict openly (concept SC1's headline, parked) rather than papering over it.

Checked, no finding:

- No read path is introduced. The design's invariant is checkable by grep, and the `check_wired` guard on the close touch point is a test reading the command, not a pack instruction reading the log.
- Ship-empty survives the triage. The owner-run triage will seed other repos' logs before any agent-written entry exists, but nothing reads the log, so no anchoring reaches a later agent, and the `Source:` line keeps the two classes distinguishable.
- Every load-bearing citation in the design verified live: `.project/feedback/README.md:30-33` (the `awk` one-liner and the second-token rule), `scripts/init-project.sh:122-127` and `:46-47`, `copy_file`'s `mkdir -p`, `scripts/test_init_project.sh:228-265` and its `:229-231` comment, `scripts/test_docs.sh:73-84` and its three `check_wired` uses, `_my_close.md:29`, `:50-53`, `:98`, `README.md:27` and `:276`, `project-pack/README.md:60` and `:84`, `docs/STRUCTURE.md` naming no register, the five CHANGELOG sections at `:22 :43 :67 :86 :104` with `:43` and `:67` the literal TODO, `codex-overrides/config.sh:19`, `scripts/build-codex-pack.sh:559-563`, ADR 0009's rejected-alternatives list. `.project/adr/` holds 12 entries, `.project/product/` and `.project/feedback/ENTRIES.md` hold 0. No claim in the design was found false.
- D4's placement call is authorized. ADR 0009 governs pack capabilities in `claude-pack/`; a `project-pack/` template is outside its scope, `project-pack/EPIC_GUIDE.md` is the standing precedent for a root-level instruction doc, and the owner decided the form directly.

Gate: DISPOSED (design-F1, design-F2, design-F3) — with smell 7 fired and escalated into the review's Fundamental Assessment.

---

## design_review (isolated lens subagent) — 2026-09-10 — rev .project/active/execution-register/design.md (uncommitted, base 78ea3b5)

**Run provenance:** the isolated `general-purpose` lens subagent spawned by `_my_design_review` Stage 0. It returned after the in-session block above was written. Its findings are independent of that block and are recorded here verbatim as received. **Its transmission truncated inside design-F2**; the missing tail is the F2 source/disposition lines, any further findings, the two smell evaluations, and its own Gate line. Findings design-F1 and design-F2 are complete enough to act on and are dispositioned below by the review. Renumbered to `lens-F1`/`lens-F2` to avoid colliding with the in-session block's ids.

Point (re-derived): Every class of agent-written durable knowledge has exactly one named, git-tracked home, reached through a write beat on a gate the item cannot skip — and the execution register ships write-only and cheap so that what agents actually choose to save is itself the evidence for whether a read path is ever built.
  [source: `.project/concepts/agent-knowledge-and-enforcement.md` — Success Criteria 1/3/4, Owner's Words 2026-09-09, Non-Goals; grade: owner]
  [secondary: `.project/adr/0001` (owner, active) — the durable-home convention and its script-only / required-Why invariants; `.project/adr/0002` Why + `0008` (agent/ratified) — trigger strength and the touch-point map as a recorded decision; [INHERITED] the 95% rule, `mental-alignment-checkpoint.md:369`]

Falsifier: the design would show an agent prompted to write a durable fact into a register without a route to that register's own filing rules; or the unskippable beat structurally unable to see the class of fact the register's own bar advertises; or a new writer added to a register whose write map is a recorded decision, while the design asserts nothing changed.

Findings:

- lens-F1 [DO] The triage writes into `.project/adr/` and `.project/product/` and the design gives it no route to either register's rules. Seam 4 says the triage "classifies each entry ... files it into that repo's `.project/`" and points only at `.project/execution/README.md`, whose Bad examples say "it goes in `.project/adr/`" and stop there. ADR 0001 (owner, active) makes id allocation script-only and the **Why** section required — "the reasoning a future challenge re-derives against" — and a one-line memory note has no recorded Why to carry. Nothing in D4, Seam 4, or the plan's Phase 3 names `adr.sh`/`product.sh`, a provenance grade for a migrated entry, or what happens when the Why cannot be reconstructed. Meanwhile Integration Strategy asserts the opposite: "It changes no existing register's subject ... the only edit to an existing register's machinery is the removal of the `Lessons Learned` field."
  — source: `.project/adr/0001` (owner); `.project/adr/0008` invariant "the single normal write point" and `0002`'s untouched-stages list (agent/ratified)
  — disposition: DISPOSE-and-proceed. Not BLOCK: an omission rather than a contradiction, and the triage is owner-run and owner-reviewed, so the 95%-rule control stays in force on everything it files.
  Fix, one clause in D4/Seam 4: the triage files through each home's own README and script, and an entry whose ADR Why cannot be reconstructed becomes a ticket — the escape hatch the owner already specified — not an ADR.
  Observable: a triage session in an unfamiliar repo hand-writes a `.project/adr/` entry with no Why and an invented id.

- lens-F2 [DO] D5 makes the only shipped beat artifact-mining, so the unskippable trigger cannot see the fact class the register exists for. The beat scans `plan.md` deviation notes, `audit.md` findings and `product-lens.md`, and D5 rejects the introspective ask outright because "close is frequently run by a session that did not do the implementation." But every execution fact this work has actually measured is a debugging-session fact that never reaches those artifacts — the MCP venv on `/mnt/c` NTFS, subagent registration by launch directory, PDF transcription errors in load-bearing numerals — and all four were written unprompted, in session, to the native store. The design's own bar advertises exactly that class in its Good examples. The only in-session catch is `wrap_up`, which is Item 3 and optional. That inverts the concept's own trigger ladder: the strong trigger harvests the surface that does not carry the payload, the weak one carries it.
  — source: concept *Why This Shape* second constraint + Appendix A (agent/ratified) — *transmission truncated here; disposition supplied by the review below*
  — disposition (review, 2026-09-10): DISPOSE-and-proceed. Agent/ratified grade. It is the same defect the in-session block records as design-F2 (B2's selective precedent), seen from the other side, and the two are merged in the review as one Major.

### Review verification of lens-F1, 2026-09-10

Measured, and it makes lens-F1 materially worse than stated. Of the six repos that hold native memory entries and have a `.project/`, five have **no `adr/` directory, no `product/` directory, and no `adr.sh` or `product.sh` at all**: `rhb-dispatch-proto` (6 entries), `flex-sim` (1), `Controls-SW-Architecture` (20), `OT-Systems/flow` (14), `flow` (8). Only `echo-workspace` (16) has them. `flow/flow-workflow` (2) has no `.project/`. So the triage as designed would be told to file decisions into a register that does not exist, with no script to stamp an id — while `_my_close.md:78` already states the pack's rule for exactly this case: "If a script is missing (repo not re-initialized), note the gap; don't hand-mint ids."

The fix is verified and cheap. A plain `scripts/init-project.sh` re-run with **no `--force`** seeds `scripts/adr.sh`, `scripts/product.sh`, `adr/README.md`, `product/README.md`, `feedback/README.md` and `feedback/ENTRIES.md` into a stale `.project/`, and leaves existing user data untouched (confirmed against a scratch repo with a stale `CURRENT_WORK.md`, which survived). One sentence of sequencing in Seam 4 closes both this and the in-session block's design-F3.

Gate: DISPOSED (lens-F1, lens-F2) — lens-F1 escalated to Critical in the review; its transmitted gate line was lost to truncation and is supplied here by the call site.

### Lens subagent block, continued — remainder received 2026-09-10

The truncated tail arrived. Recorded here in full; the block above is unchanged.

- lens-F2, completing the entry above — source: concept *Why This Shape* second constraint + Appendix A, and `.project/adr/0002` Why (agent/ratified). Disposition: DISPOSE-and-proceed. Fix that does not fight D5's stated reason: make the rejection conditional — scan the artifacts always; **also** ask when the close session did the implementation. Observable: an item where the implementer spent an afternoon on an environment gotcha closes with "none found," because the gotcha was never written into `plan.md`.

- lens-F3 [DO] The design says the register's contents are the evidence for the owner's decision, then names three independent ways those contents become uninterpretable — B1 junk, B2 empty because close is the only beat, B3 written to the native store instead — and states no way for the owner to tell them apart when they read the log. The spec's own owner disposition (2026-09-10) already settled this: the triage "carries its evidence route, so the triage's results confirm or correct" the reframe. The design does not carry that forward into The Point or the risk table, so the item ships an instrument whose readings are ambiguous by construction and whose disambiguator is documented only in the ledger.
  — source: owner disposition 2026-09-10 recorded in `product-lens.md`; concept *Next-Stage Handoff* "judged by what agents put in it" (owner) — disposition: DISPOSE-and-proceed
  Fix: one line in The Point or the risk table naming the triage as the read-time comparison.

- lens-F4 [DO] `README.md:27` already describes `feedback/` as "Append-only log of agent learnings," and the plan adds the new register as a row beside it. Two rows both reading "agent learnings" on the distributable product's front door defeats the four-way boundary at the one surface a new user and a cold agent both read before they reach any register README. Component Overview treats the doc edits as slot-filling.
  — source: `README.md` register list, `project-pack/README.md:60` Key Files (INHERITED/aspirational) — disposition: DISPOSE-and-proceed
  Fix: the two rows name their subjects — pack-prompt corrections, versus how this codebase or environment behaves — rather than both saying "learnings."

Smells fired (both design smells; each escalates into the stage's judgment):

- **Smell 2 — a consumer compensates for something the producer or platform guarantees. FIRES** (lens's reading). B3: the register's rules carry one prose line telling agents not to use the native memory store, against a harness instruction issued in every session's system prompt that no pack edit can remove. Disposed by disclosure, and the disposition is forced: the design names it its weakest bet, the risk table carries it, the spec surfaced it per capture-fidelity §4, and concept SC4 ("not in an always-on rule") forecloses the strongest lever the pack holds. What must not be lost with the disposition is the measurement consequence — it is one of the three reasons an empty log is ambiguous, which is lens-F3.
  — **Call-site note, recorded rather than reconciled away.** The in-session block above judged smell 2 *not* fired, on the reading that the harness issues a competing *instruction* rather than a *guarantee* the pack is compensating for. Both readings are defensible and both end at the same disposition — disclosed at spec, the strongest lever owner-foreclosed — and neither changes the gate. The consequence that survives either reading is lens-F3's: B3 is one of three independent reasons an empty log cannot be read.

- **Smell 7 — the solution changes who owns an invariant without saying so. FIRES**, on the triage, same root as lens-F1. The write maps for `.project/adr/` and `.project/product/` are recorded decisions (0002, 0008); 0008's Why names silent extension of that map as the failure the record exists to stop; the design adds a writer to both while Integration Strategy states that no existing register changes. Fix: say it — a line in the design, or an ADR if the owner reads the triage as a standing write path rather than a one-time migration.

### Review verification of smell 7 (write-map extension), 2026-09-10

Checked, and it is stronger than the lens states. `.project/adr/0008` (active, `[AGENT] (ratified by owner, 2026-08-09)`):

- **Why:** "ADRs 0002/0005/0006 established that the pipeline touch-point map is a recorded decision and that **extending it silently is a premise-conflict failure** (the anchor-on-the-point audit BLOCKed exactly that)."
- **Invariants established:** "The ledger is read-only orientation for every stage except `/_my_close`, **the single normal write point**."
- **Rejected alternatives:** "**Silent extension of the touch-point map without this record.**"

`.project/adr/0002` (amended, still binding) is parallel: "The record has exactly four pipeline touch points ... Audit, orchestrate, spec, epic-plan, and wrap-up are untouched."

The design's *Integration Strategy* states "the only edit to an existing register's machinery is the removal of the `Lessons Learned` field." The triage is a fifth writer to `.project/adr/` and a second to `.project/product/`. That is the named rejected alternative of a live ratified ADR, not an oversight in phrasing.

Grade stays agent/ratified, so DISPOSE-and-proceed, not BLOCK. But the disposition route is fixed by the lens spec §2 itself: a smell-7 ownership change is the one disposition that **files an ADR** (`adr.sh new`, owner-ratified provenance, the ledger finding citing the entry id). If the owner reads the triage as one-time, a design sentence suffices and the ADR is unnecessary; if it is a standing write path, the ADR is required. That is an owner call, surfaced in the review.

Gate (restated with the full block): DISPOSED (lens-F1, lens-F2, lens-F3, lens-F4) — smells 2 and 7 fired and escalated into the review's Fundamental Assessment; smell 7's disposition may require an ADR, pending the owner's read of the triage's lifetime.

---

## audit — 2026-09-10 — rev 78ea3b5 + uncommitted worktree

Point (re-derived): Execution facts have one git-tracked, append-only home, distinct from decisions, promises, and prompt feedback; it ships write-only so its contents can test whether a reader is worth building. [source: `.project/concepts/agent-knowledge-and-enforcement.md:34-36,48-55,64-70,179-182,210-217`, grade: owner]

Falsifier: An initialized project exposes accumulated execution entries to agents through a documented retrieval path, loses entries during refresh, or gives different routing answers across its writing surfaces.

Findings:

- audit-F1 [DON'T] `execution/README.md:53-61` ships a “Reading entries back” section and an exact `awk` retrieval command, contradicting the owner-grade requirement that this phase have no read or discovery path. The weaker statement at `:5` and `:55` that nothing reads the log “automatically” silently narrows “nothing reads it back.” — source: concept Non-Goals and Key Concept 3 (`:125-127,179-182`) (owner) — concrete falsifier: initialize a project, read `.project/execution/README.md`, and follow its supplied command to retrieve accumulated entries — disposition: BLOCK; remove the retrieval instructions or record an owner-authorized contract change that explicitly resolves `audit-F1`.
- audit-F2 [DO] Three prose representations of the routing boundary must be synchronized manually: `project-pack/execution/README.md:21-27`, `project-pack/TRIAGE_MEMORIES.md:19-25`, and `_my_close.md:29-34`. They already describe different destination sets, and no check compares their semantics. — source: concept SC3 and Next-Stage Handoff (`:54,215-216`) (owner); derived synchronization risk ([AGENT]/[INFERRED]) — concrete falsifier: change one destination’s meaning in any one surface; `test_docs.sh` remains green while agents receive conflicting routing instructions — disposition: DISPOSE-and-proceed after consolidation or an explicit synchronization control.
- audit-F3 [DO] The close wiring test at `scripts/test_docs.sh:92` merely greps for any `execution/ENTRIES.md` occurrence. It still passes if the Step 2 prompt is deleted because confirmation and filing contain duplicate matches. — source: concept SC4 (`:55`) (owner); test adequacy inference ([AGENT]/[INFERRED]) — concrete falsifier: remove `_my_close.md:32` while retaining `:48` or `:69`; the asserted “close prompts” check still passes — disposition: DISPOSE-and-proceed after a customer-shaped or structurally scoped close-beat check.

Smells fired:

- Smell 1 — Two representations must be manually kept synchronized. Fires on audit-F2 and escalates into the gate judgment.
- Smell 6 — A test passes only because it selects one duplicate, one route, or one interpretation. Fires on audit-F3 and escalates into the gate judgment.
- Smells 3, 4, and 5 did not fire.

Resolution citations: The prior owner disposition authorizes `TRIAGE_MEMORIES.md` as a one-time sweep (`product-lens.md:134-139`; `design.md:101-107`) and does not authorize a standing execution-log reader. The recorded deferral of the `wrap_up` beat (`product-lens.md:111-113`) avoids an omission finding for this item but does not resolve audit-F1.

Gate: BLOCKED (audit-F1); audit-F2 and audit-F3 also require visible disposition.

---

## resolution — 2026-09-11 — rev working tree

Resolves `audit-F1`, `audit-F2`, `audit-F3` from the audit block above (`product-lens.md:253-273`).

- `audit-F1` — fixed in code. The retrieval section is gone from both register READMEs; no reader exists anywhere in the pack.
- `audit-F2` — fixed in code. `project-pack/TRIAGE_MEMORIES.md:19` references the canonical boundary rather than restating it.
- `audit-F3` — withdrawn. The prompt-grep test it asked to strengthen was deleted instead, along with its five siblings (owner, 2026-09-11): a grep over prompt text cannot establish that an instruction is present.

Smell 1 and smell 6 are cleared by the same two changes.

Gate: CLEAR
