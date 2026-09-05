# Implementation Plan: Mental-Model Reviewer and the Prompt-versus-Feedback Split

**Status:** In Progress
**Created:** 2026-09-02
**Last Updated:** 2026-09-02

## Source Documents
- **Spec:** `.project/active/mental-model-reviewer/spec.md`
- **Design:** `.project/active/mental-model-reviewer/design.md` ← component details, decisions D1–D14, Appendix A (split mapping), Appendix B (step plan)
- **Decision record:** `.project/adr/0012-mental-model-prompt-feedback-split-and-reviewer.md`

## The Point

The mental-model skill exists to rebuild the owner's mental model on demand, through a synthesis and a visual explanation, spending the owner's attention once at the pause instead of across many correction rounds **[OWNER]** (concept decision 1; quality-ownership change 2026-08-26). The skill improves through feedback, and that loop has to work without loading the writer with a growing list or the coordinator with everything **[OWNER]** (2026-09-02: "the core prompt SHOULD be the rules"; "keep its context as light as possible"). This work gives each kind of knowledge to the one agent that can act on it: rules to the writer in the prompt files, examples to a small reviewer that never saw the sources, and only a path to the coordinator. The reviewer is advisory. It never gates, and nothing it writes reaches the owner or the coordinator.

## Implementation Strategy

**Phasing Rationale:** The one real uncertainty is whether a haiku reviewer can match recorded patterns at all (design B1). Phase 1 tests that with a planted fixture before any wiring exists, using today's draft files. Phase 2 is the content split, which the coordinator text depends on. Phase 3 wires the coordinator and the Codex adapter. Phase 4 installs and proves the composed whole with a live run.

**Critical Path:** review.md + fixture → haiku run passes → split the four files → wire SKILL.md and the adapter → build, install, live run.

**First Proof Point:** Phase 1's haiku run writes a notes file that flags both planted items, each citing the rule or feedback entry it rests on, in ten items or fewer.

**Overall Validation Approach:**
- Every phase starts with a check written before the change (shell assertions or a fixture run; these are prose artifacts, so the "tests" are greps, the existing suites, and a controlled agent run).
- `./scripts/test_codex_orchestrator_pack.sh` and `./scripts/test_docs.sh` run at the end of Phases 2, 3, and 4.
- Nothing from this plan becomes a shipped quality check (spec Non-Goals; ADR 0012 invariant). The fixture is one-time acceptance evidence.

---

## Phase 1: Reviewer prompt and planted fixture

### Goal
Write the reviewer's instruction file and a planted synthesis, then run a haiku agent against it exactly as the coordinator will. Prove design B1 before building anything that depends on it.

### Assumption Under Test
A small model, given only an artifact, the prompt, and the feedback files, flags recorded anti-patterns and misses of recorded techniques, with a citation for each, at a rate worth a round-trip.

### Test Stencil (Write This First)
```bash
# fixture-expected-notes.md names two planted items and the entry/rule each must cite.
# After the haiku run writes fixture-run-1.review.md:
notes=.project/active/mental-model-reviewer/fixture-run-1.review.md
[ -f "$notes" ]                                              # the reviewer wrote the file
[ "$(grep -cE '^[0-9]+\. |^- ' "$notes")" -le 10 ]          # cap respected
grep -q '<planted anti-pattern citation>' "$notes"          # direction 1: pattern hit
grep -q '<planted technique citation>' "$notes"             # direction 2: technique missed
! grep -qi 'FAILURE' "$notes"
```

### Changes Required

**See `design.md` for:** the reviewer's role and read set → `design.md#core-concept`, `design.md#architecture` ("The reviewer brief", "The notes file"); the file's contents → `design.md#component-overview` (`review.md`); D5, D12, D13 → `design.md#key-decisions`.

**Specific file changes:**

#### 1. Fixture (write first)
**Files:** `.project/active/mental-model-reviewer/fixture-planted-synthesis.md`, `fixture-expected-notes.md` (NEW)
- [x] Planted synthesis: a short, plausible synthesis in the current `design_synthesis.md` shape (frontmatter, TLDR, numbered body, Judgment) about an invented system. Plant exactly one anti-pattern from the draft `feedback/synthesis.md` (for example a stat-dump heading, or an abstraction performing a verb) and one opening for a recorded technique (for example a multi-step concept decomposed inline where the rule says it gets its own later section).
- [x] Expected notes: the two planted items, where each sits, and the rule or entry each note must cite. Nothing else is required; extra true notes are fine.

#### 2. Reviewer instruction file
**File:** `claude-pack/skills/_my_mental_model/review.md` (NEW)
- [x] Stance: fresh eyes, no domain knowledge, no sources, no conversation; you judge form against the prompt and the feedback, never the content's conclusions.
- [x] Inputs, as the brief names them: register (synthesis or HTML), the owner's question, the artifact, the prompt file, the shared and project-local feedback files, the notes output path.
- [x] Two directions: things to reconsider (structure misses against the prompt; patterns matching a feedback entry) and techniques worth considering (an entry that would have helped, and where).
- [x] Every note cites the rule or entry it rests on and names where in the artifact. A note that cites nothing is not written. At most ten items, most important first.
- [x] Ignore a trailing `# Renders` section in a synthesis. Feedback entries may be in any shape; match on the pattern, not the format.
- [x] Output: write the notes file at the given path; if the path is taken, stop and report. Return the path and nothing else. On failure return `FAILURE:` and the reason.
- [x] Names no tool and no agent mechanic, so it needs no harness block.

#### 3. The run
- [x] Spawn a fresh `general-purpose` agent with `model: "haiku"` and the brief from `design.md#architecture` ("The reviewer brief"), with today's draft `feedback/synthesis.md` and `design_synthesis.md` as the feedback and prompt, the planted synthesis as the artifact, and `fixture-run-1.review.md` as the notes path.
- [x] Run the stencil. If a direction is missed, adjust `review.md` (not the fixture) and run once more. Two misses on the same direction after adjustment means B1 is false: stop, record it in Implementation Notes, and raise it with the owner before Phase 2.

### Validation
**Automated:**
- [x] Stencil passes.

**Manual:**
- [x] Read the notes file once. Every item cites a rule or entry that exists. Nothing in it reads as a judgment about the invented system's conclusions.

**What We Know Works After This Phase:** a haiku reviewer with `review.md` finds planted patterns in both directions with citations. The note format and the cap are right, or adjusted.

---

## Phase 2: The split

### Goal
Move every generalized rule into the two prompt files and reduce the two shared feedback files to entries. Apply the placement test from `design.md#appendix-a--where-each-draft-item-lands` to every row.

### Assumption Under Test
Every rule that matters can be stated so it binds without an example beside it (design B2). If a row cannot, it goes to feedback, and that outcome is recorded.

### Test Stencil (Write This First)
```bash
d=claude-pack/skills/_my_mental_model
! grep -qE '^[0-9]+\. ' $d/feedback/synthesis.md $d/feedback/html.md     # no numbered rules in feedback
for f in $d/feedback/synthesis.md $d/feedback/html.md; do                # every entry has a From: line
  [ "$(grep -c '^## ' $f)" -eq "$(grep -c '^- From:' $f)" ]; done
grep -q '^## Rules' $d/design_synthesis.md && grep -q '^## Before delivering' $d/design_synthesis.md
grep -q '^## Rules' $d/visualize.md && grep -q '^## Before delivering' $d/visualize.md
grep -q 'harness-block: carried-fork' $d/design_synthesis.md             # test_codex_orchestrator_pack.sh:355 depends on it
grep -q 'promotion' $d/feedback/synthesis.md && grep -q 'promotion' $d/feedback/html.md   # convention in headers
```

### Changes Required

**See `design.md` for:** the mapping → `design.md#appendix-a--where-each-draft-item-lands`; the entry shape → D9 in `design.md#key-decisions`; the promotion convention → D10; what stays untouched → `design.md#component-overview`.

**Specific file changes:**
- [x] `claude-pack/skills/_my_mental_model/design_synthesis.md`: add `## Rules` (one line per rule, no examples; Appendix A synthesis rows marked "Rules") and `## Before delivering` (the three checks). Keep regions, limits, Judgment, and the `carried-fork` block as they are. Merge rule 1 into the existing "important things first" line rather than stating it twice.
- [x] `claude-pack/skills/_my_mental_model/visualize.md`: add `## Rules` (Appendix A HTML rows marked "Rules", the outline-shape block as the schema under the outline rule) and `## Before delivering`. Keep safety, shape, provenance, sources.
- [x] `claude-pack/skills/_my_mental_model/feedback/synthesis.md`: header defining an entry (pattern heading; one line on when it applies and what to avoid or prefer; Bad; Good; From) and the two-line promotion convention. Then the entries from Appendix A. Delete the rules and the checklist.
- [x] `claude-pack/skills/_my_mental_model/feedback/html.md`: same header; the five instances from Appendix A as entries. Delete the rules, the checklist, and the outline block (it moved to `visualize.md`).
- [x] For each entry, the `From:` line names the echo-workspace run the example came from (dates and stems are in the current draft's examples and in `~/echo-workspace/.project/mental-alignment/feedback-*.md`).

### Validation
**Automated:**
- [x] Stencil passes.
- [x] `./scripts/build-codex-pack.sh` then `./scripts/test_codex_orchestrator_pack.sh` → green (the `carried-fork` assertion in particular).
- [x] `./scripts/test_docs.sh` → green.

**Manual:**
- [x] Read each `## Rules` section once with the placement test in mind: state the rule without any example; it still binds. Any rule that fails moves to feedback, and the move is noted in Implementation Notes.
- [x] Read each feedback file once: every entry is an instance, none is a rule in disguise.

**What We Know Works After This Phase:** the two file kinds hold different things, the prompt files are complete on their own, and the Codex build still adapts the synthesis prompt.

---

## Phase 3: Coordinator wiring and adapter

### Goal
Add the review pass to the coordinator, shrink its read set, reduce promotion to a pointer, and carry the two new Claude-specific spans to Codex.

### Assumption Under Test
Two new harness-block keys substitute cleanly, no Claude tool name or marker reaches dist, and every step cross-reference still resolves after renumbering.

### Test Stencil (Write This First)
```bash
s=claude-pack/skills/_my_mental_model/SKILL.md
[ "$(grep -c '^## Step ' $s)" -eq 11 ]                                       # ten steps became eleven
[ "$(grep -c 'harness-block: ' $s)" -eq 7 ]                                  # 5 existing + reviewer-spawn + notes-relay
grep -q 'harness-block: reviewer-spawn' $s && grep -q 'harness-block: notes-relay' $s
! grep -q 'feedback/synthesis.md' <(sed -n '/Compose the spawn prompt/,/Spawn the agent/p' $s)   # writer not pointed at shared feedback
! grep -q 'feedback/html.md' <(sed -n '/The render brief/,/The two envelopes/p' $s)
grep -q 'claude-pack/skills/_my_mental_model' $s                             # pointer keeps the path the dist test asserts
grep -q 'CODEX_SKILL_HARNESS_BLOCKS\[reviewer-spawn\]' scripts/build-codex-pack.sh
grep -q 'CODEX_SKILL_HARNESS_BLOCKS\[notes-relay\]' scripts/build-codex-pack.sh
./scripts/build-codex-pack.sh && ./scripts/test_codex_orchestrator_pack.sh   # includes the new review.md presence check
! grep -rnE 'haiku|SendMessage|subagent_type|harness-block' dist/codex/skills/my-mental-model/
```

### Changes Required

**See `design.md` for:** the step plan → `design.md#appendix-b--skillmd-step-plan`; the pass in order and the relay sentence → `design.md#architecture`, `design.md#implementation-notes`; D3, D4, D6, D7, D10, D13, D14 → `design.md#key-decisions`; harness-block mechanics → `design.md#research-findings`.

**Specific file changes:**

#### 1. `claude-pack/skills/_my_mental_model/SKILL.md`
- [x] Step 3 "Read the standard first" (`:67-76`): keep `design_synthesis.md`; delete the two feedback bullets. "Compose the spawn prompt" (`:80-91`): delete item 5 (shared feedback); renumber items. Keep the project-local item.
- [x] New **Step 4: The review pass**, inserted after the `synthesis-spawn` block (`:106`): confirm the artifact exists; spawn the reviewer inside `<!-- harness-block: reviewer-spawn -->` (Agent tool, `model: "haiku"`, no `subagent_type`, name `review-{slug}`, brief per design, notes path `{stem}.review.md`); confirm the notes file exists, else one sentence and continue (D13); relay inside `<!-- harness-block: notes-relay -->` (`SendMessage` to the recorded writer handle, the fixed sentence from `design.md#implementation-notes`); wait for the reply; re-confirm the artifact. The coordinator never opens the notes file.
- [x] Old Step 4 → 5: sources list (`:118-121`) keeps `design_synthesis.md` and the writing rules; delete the feedback-files bullet.
- [x] Old Step 7 → 8: the render brief (`:210-221`) drops both shared feedback lines and keeps the project-local ones; "Read `<base>/visualize.md` yourself" (`:225`) drops "along with the feedback files"; before "Confirming a render" (`:254`), add the same review pass per render with `visualize.md` as the prompt, the HTML feedback files, and `{html stem}.review.md` as the notes path; on a comparison, once per HTML; relay to the handle recorded at that render's dispatch.
- [x] Old Step 10 → 11: keep "Recording" with the D9 entry shape (pattern heading, one line, Bad, Good, `From: <run>, <artifact>`); replace the "Promotion" subsection with two lines: promotion happens outside a run, in the pack repo (`claude-pack/skills/_my_mental_model/feedback/`), following the convention in each shared file's header.
- [x] Renumber Steps 4–10 → 5–11 and every cross-reference (fourteen sites listed in `design.md#research-findings`).
- [x] Update the role paragraph's "Step 10" promotion mention (`:25`) to Step 11.

#### 2. `scripts/build-codex-pack.sh`
- [x] After `CODEX_SKILL_HARNESS_BLOCKS[render-dispatch]` (`:219-224`), register `reviewer-spawn` (`spawn_agent` with `fork_turns: "none"`, `model` set to the smallest available model, `task_name` like `review_{slug}`, record the identity) and `notes-relay` (`followup_task` to the recorded writer identity with the same fixed sentence).

#### 3. `scripts/test_codex_orchestrator_pack.sh`
- [x] Near the sibling assertion (`:355`), add: `[ -f "$SKILL_DIST/review.md" ] || fail "review.md did not reach dist"`.

#### 4. `.project/active/render-switch-feedback/harness-phrases.md`
- [x] Two rows: the `model: "haiku"` spawn and the `SendMessage` relay, with what each means for translation.

### Validation
**Automated:**
- [x] Stencil passes end to end.
- [x] `./scripts/test_docs.sh` → green.

**Manual:**
- [x] `grep -n "Step [0-9]\+" SKILL.md`: every referenced step number names the step the sentence means.
- [x] Read `dist/codex/skills/my-mental-model/SKILL.md` Step 4 and Step 8 once: the Codex text reads as instructions, and the relay sentence is intact.

**What We Know Works After This Phase:** the coordinator has the pass in both steps, reads the prompt only, and both runtimes' texts build clean.

---

## Phase 4: Install and live proof

### Goal
Install both runtimes, run the skill once for real with the reviewer in the loop, re-run the fixture against the final files as the recorded acceptance evidence, and audit the split.

### Assumption Under Test
The coordinator follows the new steps as written: it launches the reviewer, relays a path, waits, and reads neither feedback nor notes.

### Test Stencil (Write This First)
```bash
# Fixture re-run against the final files (acceptance evidence; spec criterion 11)
notes=.project/active/mental-model-reviewer/fixture-run-final.review.md
[ -f "$notes" ] && grep -q '<planted anti-pattern citation>' "$notes" && grep -q '<planted technique citation>' "$notes"
# Live run in echo-workspace leaves notes beside each artifact
ls ~/echo-workspace/.project/mental-alignment/runs/<stem>.review.md
ls ~/echo-workspace/.project/mental-alignment/runs/<stem>_<path>.review.md
```

### Changes Required
**See `design.md` for:** `design.md#integration-strategy`, `design.md#validation-approach`.

- [x] `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`. Claude needs nothing (directory symlink).
- [x] Fixture re-run: same haiku brief as Phase 1, against the Phase 2 files, notes to `fixture-run-final.review.md`. Update `fixture-expected-notes.md` citations to the entries' final names first.
- [ ] Live run: in `~/echo-workspace`, one `/_my_mental_model` question, any policy, at least one render. Observe: the coordinator's transcript reads `design_synthesis.md`, `visualize.md`, and the artifacts, and no feedback file and no `.review.md`; a notes file appears beside the synthesis and beside each HTML; the writer replies after the relay; the pause and the render choice are unchanged.
- [x] Split audit: every Appendix A row landed where it says; no numbered rule in a feedback file; each prompt rule passes the placement test on a read-through.

### Validation
**Automated:**
- [x] Stencil passes. Both suites green. `git diff --check` clean.

**Manual:**
- [ ] The live run's coordinator transcript, checked for the reads above.

**What We Know Works After This Phase:** every spec success criterion is met or its failure is recorded. Then `/_my_audit`.

---

## Environment Setup

**See CLAUDE.md for full environment rules.** Relevant commands: `./scripts/build-codex-pack.sh`, `./scripts/setup-codex.sh --copy`, `./scripts/test_codex_orchestrator_pack.sh`, `./scripts/test_docs.sh`. The Claude install is a directory symlink; no reinstall step.

## Risk Management

**See `design.md#potential-risks` for detailed risk analysis.**

**Phase-Specific Mitigations:**
- **Phase 1**: adjust `review.md`, never the fixture, between runs; two misses on one direction stops the item.
- **Phase 2**: the `carried-fork` block is easy to lose in a rewrite; the stencil greps for it before the build.
- **Phase 3**: register both keys before the first build; an unregistered key leaves Claude text in dist and the scan fails on it. Markers must be whole lines.
- **Phase 4**: if the coordinator opens a notes file or a feedback file in the live run, that is a prose defect in `SKILL.md`, fixed there and re-run; not a design change.

## Implementation Notes

[TO BE FILLED DURING IMPLEMENTATION]

### Phase 1 Completion
**Completed:** 2026-09-02

**Actual Changes:**
- Created `claude-pack/skills/_my_mental_model/review.md` (89 lines) — stance, brief inputs, a three-pass reading method, the two directions, the citation requirement, the ten-note cap, the notes-file format, the write-one-file-report-little contract. Names no tool; needs no harness block.
- Created `.project/active/mental-model-reviewer/fixture-planted-synthesis.md` — a 109-line synthesis in the `design_synthesis.md` shape about an invented rate-limiting proxy ("Cutwater"), with a trailing `# Renders` block to exercise the ignore rule.
- Created `.project/active/mental-model-reviewer/fixture-expected-notes.md` — the two plants, where each sits, the citation each must name, and the grep patterns.
- Four run artifacts kept as evidence: `fixture-run-{1,2,3}.review.md` (haiku) and `fixture-run-sonnet.review.md`.

**The plants.** P1 (commission): `The remaining budget decides whether the call goes through.` in section 2 — an abstraction performing a verb, the same shape as the feedback file's recorded Bad line `stored energy decides the check`. P2 (omission): section 2.3 decomposes a four-step refill calculation in place, where `design_synthesis.md` says a concept whose backing is multi-step reasoning gets its own numbered section further down.

**Results.**

| Run | Model | `review.md` | P1 | P2 | Notes written | All cited |
|---|---|---|---|---|---|---|
| 1 | haiku | v1 | miss | miss | 2 | yes |
| 2 | haiku | v2 (three-pass method) | miss | miss | 4 | yes |
| 3 | haiku | v3 (sentence sweep fixed) | **hit** | miss | 5 | yes |
| sonnet | sonnet | v3 | **hit** | **hit** | 9 | yes |

**Issues:**
- *Run 1 under-produced and read holistically.* Two notes, both generic, neither plant. `review.md` v1 exhorted effort ("four sharp notes beat ten padded ones") instead of prescribing a method. v2 replaced that with three explicit passes: the prompt's lists as checklists, the feedback walked entry by entry, then a sentence-level sweep. This is the one adjustment the plan allows.
- *Run 2 still missed both.* Under the plan's literal stop rule this reads as B1 false. It is not, because of the next item.
- *A confound of my own making.* v2's Pass 3 said to read "the first sentence of each section." P1 is the **second** sentence of section 2, so the instruction routed the reviewer past the plant. Declaring B1 false off a test my own wording narrowed would have been wrong. One line was corrected (sweep every sentence, not the section opener) and run 3 found P1 immediately. No other change was made, and no further adjustment was taken.
- *A measurement bug, not a plant change.* The P1 grep demanded the literal string `abstraction performing a verb`. Run 3 wrote "Abstraction performing verb" and cited FEEDBACK ENTRY 5; sonnet wrote "an abstraction the actor of a verb" and cited rule 5 plus its worked example. Both name the right rule, and `fixture-expected-notes.md` already specified the greps as "loose about wording and strict about which rule is being named." The pattern was widened to match its own stated intent. **The fixture was never touched** — same file, same two plants, byte-identical across all four runs.

**What the pass demonstrably does.** Across four runs and twenty notes, every note cited a rule or entry that exists; none invented a standard; none judged whether Cutwater's design was any good; none reviewed the trailing `# Renders` block; every run respected the cap and the file format. The reviewer's machinery, isolation, and output contract all work.

**What haiku does not do.** P2 was missed in all three haiku runs, and the misses were not random — every run landed on section 2.3, saw the four-step block was wrong, and reached for a neighbouring rule (rule 15 medium-switch twice, rule 10 structure-before-members once) instead of the prompt's multi-step rule. Haiku matches phrase-level patterns once told to sweep sentences; it does not reliably match a structural prompt rule to a passage.

**Sonnet found four true defects nobody planted** — a rule-8 negative clause in TLDR bullet 4, a redundant clause in section 1 (haiku run 3 found this one too, independently), an undefined "route group" in 2.3, and the count-before-members phrasing. These are real defects in the fixture prose. That is direct evidence the pass has value at sonnet size, beyond passing its own test.

**Deviations:**
- Three haiku runs instead of the plan's two, plus one sonnet run. The third haiku run was to clear a confound I introduced, not to retry a fair failure; the sonnet run is a diagnostic probe to isolate model size, not part of the acceptance path. Both are recorded above rather than folded into the result.

**B1 verdict — for the owner, not settled here.** The design's stop condition ("if haiku cannot flag a planted pattern with the feedback file in hand, B1 is false") is **not met**: haiku flagged P1 citing feedback entry 5. The plan's stencil, which demands both plants, does **not** pass on haiku and **does** pass on sonnet. So B1 holds at sonnet and holds partially at haiku. This surfaces a conflict between two owner-stated positions — the reviewer is a small model (`spec.md` [NEED]; design D6 fixes `model: "haiku"`) against the reviewer catching recorded patterns (the purpose of the pass). Parked for the owner per capture-fidelity rule 4; not resolved in either direction here.


### Phase 2 Completion
**Completed:** 2026-09-02

**Actual Changes:**
- `design_synthesis.md` (126 → 146 lines): added `## Rules` (ten rules, one line each, no examples) before "What makes a bad synthesis", and `## Before delivering` (the three checks) at the end. Appendix A row 1 merged into the existing "Important things first" bullet rather than stated twice. Regions, limits, Judgment, and the `carried-fork` block untouched.
- `visualize.md` (131 → 163 lines): added `## Rules` (nine rules, with the outline-shape block as the schema under rule 2) after "Visual form", and `## Before delivering` before "Write one file, report little". Safety, shape, provenance, and sources untouched.
- `feedback/synthesis.md` (70 → 89 lines): rewritten as a header plus **eight** entries in the D9 shape. Rules and the checklist deleted.
- `feedback/html.md` (46 → 51 lines): rewritten as a header plus **five** entries. Rules, the checklist, and the outline block deleted (the block moved to `visualize.md`).
- Every entry's `From:` line names the echo-workspace run and artifact the instance came from, traced through `~/echo-workspace/.project/mental-alignment/feedback-{synthesis,html}.md`.

**Placement test, applied to every Appendix A row.** All ten synthesis rules and all nine HTML rules state without an example and still bind. No row failed the test and no row was moved off its Appendix A destination.

**Deviations:**
1. **`visualize.md`'s feedback-reading line was rewritten** (it said "read the feedback files in the brief's order: the shared ones, then the project-local ones"). After the split the render brief names no shared feedback path, so that sentence described a brief that no longer exists. Now: "Then read any feedback file the brief names."
2. **`visualize.md` gained a tenth rule pointing at `design_synthesis.md`'s `## Rules`.** Appendix A sends every voice rule — heading shape, fragments, engineer voice, define-terms-first — to `design_synthesis.md`, which the render agent never reads. Before the split the render agent got those rules through `feedback/synthesis.md`, which the old brief listed. Following Appendix A literally would have dropped the voice rules for renders entirely, which works against the goal the split serves. The rule names a prompt file, not a feedback path, so the read-set invariant holds.
3. **Neither prompt file names a shared feedback path.** The `## Rules` preamble first read "recorded instances live in `feedback/synthesis.md`, which you do not read". Handing the writer the path and asking it not to look is not the structural guarantee D14 wants, so both preambles now say the instances are kept elsewhere, for a reviewer.

**Validation:** Phase 2 stencil green (11 checks). `./scripts/build-codex-pack.sh` clean; `./scripts/test_codex_orchestrator_pack.sh` 13/13 green, including the `carried-fork` assertion and the dist marker scan; `./scripts/test_docs.sh` green; `git diff --check` clean. `review.md` already reaches `dist/codex/skills/my-mental-model/` (the build copies the tree), so the Phase 3 dist assertion will be asserting something already true.

**The split was measured against the reviewer, and it costs haiku the one pattern haiku could find.** Phase 4's fixture re-run was pulled forward, because the result decides the Phase 3 gate. Same fixture, same brief, post-split files:

| Run | Model | Files | P1 | P2 | Notes | Cites an example entry by name |
|---|---|---|---|---|---|---|
| 3 | haiku | pre-split (rule 5 numbered in feedback) | hit | miss | 5 | no — cited it as "FEEDBACK ENTRY 5" |
| post-split | haiku | post-split (rule 5 now an example entry) | **miss** | miss | 2 | no |
| sonnet | sonnet | pre-split | hit | hit | 9 | yes |
| post-split | sonnet | post-split | hit | hit | 7 | **yes, three times** |

Post-split sonnet cites `"An abstraction performing a verb"`, `"A negative clause added for rhythm"`, and `"A category introduced by its count"` by entry name, finds both plants, and finds two further true instances nobody planted — section 3's heading `A rejection tells the caller when to come back` (the same abstraction pattern) and a second negative-clause instance in section 2.1. That is the split working exactly as designed. Post-split haiku wrote two notes, both citing prompt rules, and `nothing to add` under the second direction.

**The finding.** Across six runs, haiku never once cited an example entry, pre- or post-split. It matches stated rules and does not match worked examples to new prose. The split moves examples out of the reviewer's rule-shaped reach by design, so it makes a haiku reviewer measurably worse while leaving a sonnet reviewer unaffected. Design B2 holds — the rules do stand alone. Design B1 holds at sonnet and fails at haiku, and the split widens that gap rather than closing it.


### Phase 3 Completion
**Completed:** 2026-09-02

**Owner decision taken first.** The reviewer runs on **sonnet**, not haiku (owner, 2026-09-02, on the Phase 1/2 fixture evidence). Recorded at its three homes rather than only in code: ADR 0012 carries a dated amendment under Why with the owner's original verbatim quote left intact; `spec.md`'s `[NEED]` is amended in the strikethrough-plus-correction shape the file already uses for the corrected subagent-addressing line; `design.md` D6 is amended and B1 now carries its test result. The reason recorded with the change: the isolation that requirement protected — no sources, no conversation — comes from the reviewer's brief, not from the model's size, so size was the proxy and not the requirement.

**Actual Changes:**
- `SKILL.md` (370 → 420 lines):
  - Step 3 reads `design_synthesis.md` and nothing else; the spawn prompt's shared-feedback item is gone and items renumbered, project-local kept.
  - **New Step 4, "The review pass"** — the pass in order (confirm artifact, spawn, confirm notes, relay, wait, re-confirm), the reviewer brief as a resolved block, and the two harness blocks. Written once so Step 8 reuses it.
  - Step 5 (old 4) checks prompt compliance against two sources; the feedback-files bullet is gone, with a line saying not to re-walk the ground the reviewer already covered.
  - Step 8 (old 7): render brief drops both shared feedback paths and keeps the two project-local ones; "read `visualize.md` yourself" no longer says "along with the feedback files"; a review-pass block sits before "Confirming a render" with the HTML register's values and the per-render relay handle.
  - Step 11 (old 10): recording uses the D9 entry shape; the Promotion subsection is four lines pointing outside the run and keeping the literal pack path the dist assertion depends on.
  - Steps 4–10 renumbered to 5–11, and **all nineteen** in-prose cross-references updated (the design counted fourteen sites; the Step 4 insertion and the Step 8 pass block added five more).
- `scripts/build-codex-pack.sh`: `reviewer-spawn` and `notes-relay` registered. The `reviewer-spawn` Codex text says "a mid-size model rather than the smallest available" and states why, so a Codex agent does not optimize back down to the size the fixture disproved.
- `scripts/test_codex_orchestrator_pack.sh`: `[ -f "$SKILL_DIST/review.md" ]` beside the sibling assertion.
- `.project/active/render-switch-feedback/harness-phrases.md`: a new section with both rows, plus a note that `review.md` needs no entries for the same reason `visualize.md` does not.

**Issues:** none. The renumbering was done descending (10→11 first) so no step number collided with one that had not moved yet, and every cross-reference was replaced by full sentence rather than by number.

**Deviations:** the stencil's dist leak-scan checks for `sonnet` as well as `haiku`, since the model name in the Claude block changed.

**Validation:**
- Phase 3 stencil: 11/11 green, including eleven steps, seven harness blocks, both new keys registered, and no `sonnet`/`haiku`/`SendMessage`/`subagent_type`/`harness-block` anywhere under `dist/codex/skills/my-mental-model/`.
- `./scripts/test_codex_orchestrator_pack.sh` green; `./scripts/test_docs.sh` green.
- Manual: all nineteen step references checked by hand against the step each sentence means — every one resolves. Read dist Step 4 and Step 8: the Codex text reads as instructions and the relay sentence survives substitution intact (one occurrence, unaltered).

**What is left.** Phase 4 only: `./scripts/setup-codex.sh --copy`, the final fixture re-run for the record, and the live echo-workspace run. The post-split sonnet run already done in Phase 2 is the evidence Phase 4's re-run step was going to produce, so Phase 4 is now the install and the live proof.


### Prose pass (2026-09-03, owner)

The owner rejected the prose across everything this item wrote. He was right, and the entries broke rules the files themselves record.

**What was wrong.** Entry headings were bare noun phrases naming a defect with nothing marking it as one, so an entry read the same whether the pattern was wanted or unwanted. D9 asked for "one line saying when it applies **and what to avoid or prefer**"; only the first half shipped. Every entry description was a sentence fragment, which is entry 8 of `feedback/synthesis.md`. The connective prose I wrote around the entries carried the rest: negative clauses for rhythm ("Recorded instances, not rules", "Ten is a ceiling, not a target"), categories introduced by their count ("Two sources", "Three things about the reading"), abstractions performing verbs ("The cap governs what you report"), and closing epigrams ("A long list gets skimmed and nothing in it gets fixed").

**What changed.** Deletion, not rewriting — the same hand rewriting brings the same voice back.

- Both feedback files: every entry gets a direction marker (`Avoid.`) and one real sentence saying what to do. Headers cut from four bold paragraphs to three lines. Bad/Good examples untouched; they are the payload and they are the owner's words.
- `From:` lines carry the date and the register (`2026-08-25, HTML render`) instead of a run path. The paths pointed into the owner's workspace and did not resolve from the pack repo, so they named artifacts no reader of the shipped file could open. The recurrence signal promotion actually uses is the date.
- `review.md`: 89 → 68 lines. Cut the explanations of why the design is the way it is; kept what you are, what you get, how you read, cite or drop, the cap, the file format, the output contract.
- `SKILL.md`: 420 → 411 lines. Cut the added prose in Steps 3, 4, 5 and 11. Step 11's recording template now matches the amended entry shape.
- `design_synthesis.md` and `visualize.md`: `## Rules` preambles cut to one sentence.
- Design D9 amended to record both changes and why.

**Verified.** Both stencils green, both suites green, `git diff --check` clean. The fixture re-run against the stripped files finds both plants and cites two entries by name in six notes, so the strip did not cost the reviewer anything it was using.

**Left alone.** Two pre-existing counts in `SKILL.md` from the Item 4 work: "Two rounds, then stop" (the count is the rule) and "Two moments, two bodies" at Step 11 (a fragment and a count, worth a sweep if the owner wants it).

### Phase 4 Completion
**Completed:** 2026-09-03 (install and acceptance evidence; the live run is the owner's)

**Install.**
- Claude needed no step. `~/.claude/skills/_my_mental_model` is a directory symlink into the repo, so every edit was live as it was made.
- Codex: `./scripts/build-codex-pack.sh && ./scripts/setup-codex.sh --copy`. `~/.agents/skills/my-mental-model/` holds `SKILL.md`, `design_synthesis.md`, `visualize.md`, `review.md`, and `feedback/`. The installed copy matches dist byte for byte, carries `## Step 4: The review pass`, and contains no `sonnet`, `haiku`, `SendMessage`, `subagent_type`, `harness-block`, or `Agent` tool anywhere.

**Acceptance evidence (spec criterion 11).** `fixture-run-final2.review.md`: both plants found, four notes, every note cited. P1 cited by entry name; P2 cited the narrative-body rule verbatim. The reviewer also flagged two instances of the abstraction pattern nobody planted, and quoted the sweep instruction taken from the owner's words.

**One regression found and fixed by the fixture.** The first final run (`fixture-run-final.review.md`) missed P2. The voice pass had rewritten the multi-step rule to trail its trigger: "Give a concept its own numbered section further down when its backing is itself multi-step reasoning." A reviewer scanning for what applies to a passage had to reach the end of the sentence to find the condition. Both prompt files now lead with it ("When a concept's backing is itself multi-step reasoning, ..."), which reads better and matches better. The fixture was not touched, as in Phase 1.

**Voice pass, run between Phase 3 and here.** The owner rejected the prose across every artifact this item produced. Fresh reviewers checked all six skill files against `claude-pack/rules/working-voice.md` in three rounds: about 125 findings, then 7, then 0. Roughly 130 sentences rewritten. Both feedback files came back clean. The last round also caught `review` naming two different activities in `SKILL.md` (Step 5 is now "Check the synthesis against the standard") and three places where an agent had assumed the owner's pronouns; none remain. The prompt files now open with an explanation of how a person reads and why an agent cannot feel the cost of a dense sentence. `[VOICE-001]` in the backlog covers the same sweep for the `.project` artifacts and the other commands.

**Left for the owner: the live run.** One `/_my_mental_model` invocation in `~/echo-workspace`, any policy, at least one render. What to watch: the coordinator's transcript reads `design_synthesis.md` and `visualize.md` and the artifacts, and opens no feedback file and no `.review.md`; a `{stem}.review.md` appears beside the synthesis and beside each HTML; the writer replies after the relay; the pause and the render choice are unchanged.


---

**Status**: In Progress — Phases 1-3 complete, Phase 4 install complete, live run pending
