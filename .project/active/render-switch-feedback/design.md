# Design: Render + Switch + Feedback (Claude)

**Status:** Approved by owner 2026-08-20 — revised per design-review (DR-1, DR-2, DR-3 all applied); implemented
**Owner:** Reid W
**Created:** 2026-08-20
**Branch:** anchor-on-the-point
**Commit at authoring:** 67d8991
**Spec:** `.project/active/render-switch-feedback/spec.md`
**Epic:** MENTAL-ALIGN-V2, Item 4

---

## Overview

Everything past the mandatory pause: two render paths off one synthesis, the owner's switch between them,
a comparison that records what it can honestly measure, and a two-body two-tier feedback loop with manual
promotion. Five new coordinator steps and two new authored files. No new state anywhere — the synthesis
file is the run record.

## Related Artifacts

- **Spec:** `.project/active/render-switch-feedback/spec.md`
- **Spec review:** `.project/active/render-switch-feedback/spec-review.md` (verdict Revise, all findings dispositioned)
- **Product lens:** `.project/active/render-switch-feedback/product-lens.md` (gate CLEAR)
- **Epic:** `.project/backlog/epic_mental_alignment_skill.md` (Item 4)
- **Required Reading (epic):**
  - `.project/concepts/mental-alignment-checkpoint.md` — concept
  - `.project/concepts/mental-alignment-skill-design.md` — concept-design
  - `.project/active/codex-resume-spike/spike-findings.md` — Item 1
- **Predecessor:** `.project/active/coordinator-synthesis/spec.md` (Item 3 — defines the seam)
- **Design review:** `.project/active/render-switch-feedback/design-review.md` (verdict Rework; DR-1,
  DR-2, DR-3 dispositioned by the owner and applied in this revision)
- **Decision records read:** ADR 0009 (directory skills) and **ADR 0011** (skill directories go through
  the Codex adapter), which supersedes ADR 0010. Neither active record is contradicted. ADR 0011 is what
  removes cross-runtime correctness from authored prose and puts it in the adapter (D13).

---

## The Point

The owner cannot read every artifact in the chain, so recovering the mental model of one system means
reconstructing it from five to ten documents written at different levels and times. The mental-alignment
skill exists to close that gap on demand, from one question.

Item 3 built the thinking half: a question produces a readable synthesis and stops at a mandatory pause.
This item builds everything past the pause, and its governing obligation is threefold.

1. **The HTML inherits the synthesis narrative and adds a second layer of detail** using what HTML can
   do — visuals, disclosure, color. It must never be the same words in a different format.
   [source: concept SC3; owner-verbatim *"synthesis.md = skeleton … HTML = the meat"* and *"I DO NOT WANT
   THE HTML JUST TO BE THE SAME WORDS IN A DIFFERENT FORMAT"*; grade `[OWNER-VERBATIM]`]
2. **The owner chooses at the pause** between resuming the same agent, using a fresh one, or both on one
   synthesis for a side-by-side comparison measured on wall-clock time, tokens when the runtime exposes
   them, and the owner's own read of quality.
   [source: concept SC12; grade `[OWNER]`]
3. **Two feedback bodies across two tiers.** New feedback lands project-local first, attributed to the
   run or the specific HTML; promotion is owner-initiated, targets the shared feedback file and never the
   instruction files; promotion from a copy install fails closed.
   [source: concept SC7, concept-design §Core Model; grade `[OWNER]`]

The falsifier: this design violates the point if a render can reproduce the synthesis in an HTML wrapper,
if either render path is missing, if the owner's choice is defaulted away, or if new feedback lands
directly in the shared file.

---

## Research Findings

**The seam is narrower than expected.** `SKILL.md` (98 lines) ends at Step 4 — present the synthesis,
offer the three options, stop. Item 4 replaces that one terminal sentence with Steps 5–9 and changes
nothing above it.

**The synthesis file already carries everything a render needs, and its pointers are where the detail
layer comes from.** The one real run (`runs/20260820-131155_ralph-loop.md`, 282 lines) shows the shape
holding in practice: YAML frontmatter, an H1 narrative whose sections close with an italic *Provenance …
Visual: …* line, then `# Judgment` and `# Appendix` as trailing H1s. Six of its seven narrative sections
carry both a provenance line and a named visual form, and the body cites 23 distinct `file:line` pointers.
That is what makes "add the meat" operational rather than aspirational — the render agent follows those
pointers and reads what the skeleton deliberately left out. It is also why it must keep repo read access
(D6). The render agent parses nothing; it reads a conventional markdown file.

**Resume works on Claude, probed rather than assumed.** `SKILL.md:87` already names the synthesis agent
(`synthesis-{slug}`), which is what makes it addressable later. A mirror of Item 1's Codex probe confirmed
a named subagent resumed after completing its first turn still held that turn's private context. Two
secondary findings changed the design: no token figure is available, and an agent's returned text does not
reliably reach the coordinator (D11). Full log in Appendix A.

**The v1 builder is the prior art for `visualize.md`.** `claude-pack/scripts/mental-model-builder.md`
(deleted this branch, at `git show HEAD:`) has four inheritable parts: the two-layer rule with its
register/provenance discipline and accessibility line (§3), the hard safety limits (§4), and the "return
little" posture (§6). Its §2 discovery and §5 metadata block are the synthesis agent's job now and must
not be duplicated — the concept anticipated exactly this split.

**Two existing conventions get reused rather than reinvented.** The pack's append-only ledger idiom
(`claude-pack/scripts/product-lens.md:103-124`: `## <stage> — <date> — rev <artifact>`, appended, scanned
in full) becomes the feedback entry shape (D4). And `scripts/setup-global.sh:126-134` symlinks the whole
skill directory while Claude reports the base directory *unresolved* (spike A8, A9) — so promotion must
resolve the path before deciding whether it holds the authored source (D7), distinguishing
`<repo>/claude-pack/skills/_my_mental_model` from a vendored `.claude/` copy and from Codex's
`~/.agents/skills/my-mental-model`.

**No migration burden.** No `feedback.md` exists anywhere in the tree and no prior HTML run. The spec's
"deprecated in place" non-goal is satisfied by doing nothing.

---

## Core Concept

**The synthesis file is the run record, and every render is a child of it.**

Item 3 made the synthesis the *input* to rendering. This design makes it the *whole state of the run*.
There is no index, no manifest, no database, no sidecar. Three things hang off one markdown file:

- **Renders** are named by prefixing its filename stem and suffixing the path that produced them, so the
  family is one `ls` and the provenance of each HTML is in its own name.
- **Readings** — wall clock, whatever the runtime says about tokens, the owner's quality call — are
  appended back onto that same file as a trailing `# Renders` section, because they describe the run.
- **Feedback** entries in the project-local files are headed by the artifact they reviewed: the synthesis
  path for synthesis feedback, the specific HTML path for HTML feedback.

The second idea is that **the two render paths differ only in who is holding the pen, never in what the
job is.** One render brief — synthesis path, output path, shape, reading list, reporting rule — goes to
both. The resumed agent gets a two-sentence envelope reminding it that the file may have been corrected
since it wrote it; the fresh agent gets a two-sentence envelope telling it to inherit a narrative it did
not write. Everything else is identical text. That is what makes the comparison a fair test of the *path*
rather than of two differently-worded prompts, and it is why the comparison is worth running at all.

The third idea is that **correction happens before the fork, not after it.** The pause is a correction
gate: if the owner changes anything, the synthesis file is amended and saved before any render starts, so
both paths consume the same authority. A render never reads a synthesis the owner has already rejected.

---

## Key Bets

- **B1. A live subagent can be resumed after it completes, with its context intact.** The whole resumed
  path rests on this. **Confirmed on both runtimes** — Item 1 on Codex, Appendix A on Claude — so this is
  a bet only in the sense that a future runtime change could take it away.
  *If false → the resumed path collapses, the comparison never runs, and the item degrades to fresh-only
  rendering. The switch and its trade-off become a documented non-feature.*
- **B2. The detail layer comes from following the synthesis's own pointers.** The synthesis names where
  detail lives; a render agent that follows those references has real material to expand with.
  *If false → the render agent has nothing to add but formatting, and every HTML becomes the restatement
  the concept forbids, regardless of how `visualize.md` is worded.*
- **B3. The owner's read of quality is the measurement that matters; wall clock and tokens are context
  for it.** No automated check is worth building here.
  *If false → the comparison produces two numbers and no verdict, the owner cannot tell the paths apart,
  and the switch stays a coin flip forever.*
- **B4. Feedback written in the owner's own words, project-local, is worth promoting later.** The two-tier
  loop assumes local lessons generalize.
  *If false → the shared bodies stay empty, and the skill never improves across projects — the loop is
  ceremony, and the instruction files are doing all the work.*

## Key Decisions

- **D1. HTML filename is `{stem}_{path}.html`, always** — `20260820-131155_ralph-loop_resumed.html`,
  `…_fresh.html`, collisions taking `-2`, `-3`. The stem prefix carries the Item 3 pairing mechanism; the
  suffix carries the path attribution the spec requires; the whole family is one glob.
  *Rejected: bare `{stem}.html` for solo renders, suffixed only for comparisons — a filename would then
  fail to say which path produced it, and a later second render would have to rename the first.*
- **D2. One render brief, two envelopes** (above). *Rejected: separate instruction text per path — it
  makes the comparison measure prompt wording instead of path, and doubles what has to be kept in step.*
- **D3. Readings are appended to the synthesis as a trailing `# Renders` section, written once after all
  renders of the invocation finish.** *Rejected: extending the YAML frontmatter (in-place YAML editing is
  fragile and the synthesis agent owns that block); a separate readings file (a second artifact to pair,
  for three lines of data).*
- **D4. Feedback entries reuse the pack's ledger idiom** — `## <YYYY-MM-DD> — <artifact path>`, appended,
  never rewritten. The owner's words are recorded verbatim as the entry body; any agent generalization is
  a separate line marked `[AGENT]`, so the promotion review can see which is which.
  *Rejected: a structured schema with fields — feedback is prose the owner will rewrite at promotion
  anyway, and a schema invites the coordinator to invent content to fill it.*
- **D5. Fail-closed promotion marks the existing entry in place** with `Promotion requested: <date> —
  blocked (copy install at <resolved path>); apply by hand to feedback/html.md`. *Rejected: a separate
  `promotion-candidates.md` — it duplicates the entry text, which the correction law warns against, and
  splits attribution across two files for a rare path.*
- **D6. The render agent gets no tool restrictions.** It needs repo reads to follow the synthesis's
  pointers (B2) and one file write. The one-file rule is stated as an instruction, not enforced.
  *Rejected: read-only-plus-one-write tooling — it would forbid exactly the reads that produce the detail
  layer.*
- **D7. Copy-install detection is one resolved-path test:** the shared feedback file is the authored
  source iff the skill's base directory, resolved through symlinks, ends with
  `claude-pack/skills/_my_mental_model` and sits inside a git work tree. *Rejected: checking git-tracked
  status alone — a vendored `.claude/` copy is also tracked, so it would promote into a copy.*
- **D8. Resume availability is discovered by attempting the send, not by pre-checking.** `ListAgents` did
  not list the in-process subagent during the probe, so there is nothing reliable to pre-check. A failed
  or context-less resume is reported plainly and the fresh path is offered.
  *Rejected: a pre-flight availability check — it would report absence for a healthy agent.*
- **D9. Clean room constrains the synthesis, not the render — and the owner can say otherwise at the
  pause.** By default the render agent explores freely, because that is what lets it add a detail layer
  at all. When the run was classified clean room, the coordinator states this default as part of the
  render choice and offers the override; if the owner takes it, the restriction is restated in the render
  brief and the HTML says on its face that its detail is bounded by the stated sources. Under either
  branch the HTML names the sources its detail layer drew on, so the owner can see the reach.
  [owner decision, design-review DR-1, 2026-08-20]
  *Rejected: carrying the restriction automatically — it was the design's own recommendation and the
  owner overruled it, on the ground that clean room governs what shapes the thinking, not what
  illustrates it.*
- **D10. The owner's quality reading is asked for after a comparison and offered after a single render.**
  Comparison requires it (spec SC5); making it mandatory on every run would be the ceremony the concept
  rules out.
- **D11. The coordinator confirms a render by reading the file at the path it assigned, never by relying
  on the agent's returned text.** The probe showed a named background agent's turn output does not
  reliably surface to its caller — the coordinator sees a lifecycle signal, not content. The render brief
  still asks for a short report, but nothing depends on it. This is already how Item 3's Step 4 works, so
  the seam stays consistent. *Rejected: parsing the agent's report for the output path — it makes the
  coordinator's bookkeeping depend on the least reliable channel in the system.*
- **D12. Feedback capture is offered at two moments, not one.** Synthesis feedback is offered at the
  pause, where the owner is already reading the synthesis; HTML feedback after a render. A correction is
  *not* silently converted into a feedback entry — the coordinator asks whether the correction is also a
  lesson for future runs, because a fix to this synthesis and a rule for the next one are different
  things. *Rejected: auto-recording corrections as feedback — it manufactures agent-written lessons the
  owner never asked for, which is exactly what the manual-promotion posture exists to prevent.*
- **D13. Steps 5–9 and `visualize.md` are written in the pack's Claude-native vocabulary, and every
  harness-specific phrase they introduce is recorded for the adapter.** Cross-runtime correctness belongs
  to the Codex adapter, which translates every file of an allowlisted skill directory recursively
  (ADR 0011, superseding 0010). Authored prose does not own it. So the new steps say what they mean in the
  clearest terms available, and this item ships a short list of the harness-specific phrases it added —
  a hand-off input to Item 5's dictionary work, not a build change made here.
  [ADR 0011; design-review DR-2, 2026-08-20]
  *Rejected: runtime-neutral phrasing as an invariant — that was ADR 0010's rule, and 0011 supersedes it
  precisely because the first real skill directory cannot be written that way.*
- **D14. When the synthesis agent cannot be resumed to apply a correction, the coordinator reports the
  failure and stops.** It does not edit the synthesis, and it does not hand the correction to a different
  agent. Synthesis content has one owner — the agent that wrote it — and a correction is a change to
  synthesis content no matter how literally it is transcribed. The synthesis file stands on disk as it was.
  [owner decision, design-review DR-3, 2026-08-20]
  *Rejected: coordinator transcription of the owner's exact words (the design's earlier fallback) — calling
  an edit transcription does not move the ownership boundary; and a fresh synthesis-editor agent, which
  invents a third agent role to cover a rare failure.*

---

## Architecture

```
                    ══ PAUSE (Item 3, Step 4) ══
                    owner reads the synthesis
                              │
        ┌─────────────────────┴──────────────────────┐
        │ corrected?                                 │ no
        ▼                                            │
  Step 5 CORRECTION GATE                             │
  correction → synthesis agent → file amended  ──────┤
  (agent unavailable → report the failure, stop)     │
                                                     ▼
                              Step 6 ROUTE  ── resumed │ fresh │ both
                                        │      (clean-room runs: state the
                render brief + envelope  │       free-exploration default,
                                         │       offer the restrict override)
                                         ▼    (comparison: resumed, then fresh)
                        ┌────────────────┴───────────────┐
                        ▼                                ▼
              resumed synthesis agent            fresh render agent
              (re-reads the synthesis)           (inherits the narrative)
                        │  reads visualize.md + feedback/html.md
                        │        + feedback-html.md (if present)
                        │  follows the synthesis's file:line pointers
                        ▼                                ▼
              runs/{stem}_resumed.html         runs/{stem}_fresh.html
                        └────────────────┬───────────────┘
                                         ▼
                       Step 7  append `# Renders` to the synthesis
                               (wall clock, tokens-or-"not measured",
                                owner quality per HTML)
                                         │
                       Step 8  plain-document shape only:
                               read the judgment back in the terminal
                                         │
                       Step 9  feedback on request →
                               .project/mental-alignment/feedback-{synthesis,html}.md
                               promotion on request → feedback/{synthesis,html}.md
                                                      or marked blocked in place
```

**Boundaries.** The coordinator owns paths, timing, routing, and every write outside `runs/*.html`. The
render agent owns exactly one file and returns three lines. The synthesis agent owns the synthesis file's
content, including corrections. Nothing else writes anywhere.

**Data flow into a render.** Four inputs, all paths: the synthesis, `visualize.md`, the shared HTML
feedback, the project-local HTML feedback. Two values: the output path and the output shape. The
coordinator resolves all six; the render agent resolves nothing.

**Degradation.** Two shapes, and they are deliberately different. A failed **resume at the render step**
costs a capability, not the run: the coordinator says so plainly and offers the fresh path, and a
comparison so degraded becomes a fresh-only render — reported as that, never as a comparison. A failed
resume at the **correction gate** ends the run: the coordinator reports the failure and stops, because
the only agent allowed to change synthesis content is unreachable and no substitute is authorized (D14).
The synthesis file stands on disk unchanged.

Separately, because the fresh path needs nothing but a synthesis path, a later invocation can render from
any past synthesis, including one whose pause the owner walked away from. That falls out of the design
rather than being added to it.

---

## Required Invariants

- The synthesis file on disk is corrected **before** any render of that invocation begins; both paths of a
  comparison read the same file.
- Every HTML filename begins with its synthesis's stem, and names the path that produced it.
- No HTML is ever overwritten. A later run writes new files; a repeat of the same path takes `-2`.
- The `# Renders` section is coordinator bookkeeping. It is written after all renders of an invocation
  complete, and a render agent that encounters it ignores it as narrative source.
- A render agent writes exactly one file, at the path the coordinator gave it.
- A render counts as complete when the file exists at that path — not when the agent says so.
- New feedback is written project-local first, headed by the artifact it reviewed. The shared bodies
  change only on owner-initiated promotion.
- Promotion targets a feedback file. It never edits `visualize.md` or `design_synthesis.md`.
- Promotion into a resolved path that is not the authored pack source does not write to the shared file.
- Under checkpoint shape the HTML carries metadata and judgment; under plain-document shape it carries
  neither and the coordinator reads the judgment back in the terminal.
- The coordinator never writes synthesis content. Only the agent that authored a synthesis amends it.
- On a clean-room run, the coordinator states the render's free-exploration default and offers the
  restrict override before any render starts. Silence is not consent in either direction.
- Every HTML names the sources its detail layer drew on.
- Every sibling reference in an authored file is a bare filename in prose — never a path containing
  `_my_mental_model`. This is a correctness fact on both harnesses, not a portability policy: Claude runs
  with the project directory as cwd and Codex with the skill directory as cwd, so a path carrying the
  skill's own directory name resolves on neither (spike A8/B5).

---

## Component Overview

**`claude-pack/skills/_my_mental_model/SKILL.md`** *(modify — Steps 5–9 replace the terminal stop)*
Steps 1–4 unchanged. Step 5 the correction gate. Step 6 routing and the render brief. Step 7 timing and
the `# Renders` write-back. Step 8 the plain-document judgment read-back. Step 9 feedback and promotion.
All the run's mechanism lives here rather than in the instruction files, written in the pack's
Claude-native vocabulary (D13). Harness-specific phrases it introduces are listed for the adapter.

**`claude-pack/skills/_my_mental_model/visualize.md`** *(new — the render agent's instruction file)*
The long, improvable half of the render step, and the sibling of `design_synthesis.md`. Its spine: your
input is a skeleton and your job is the second layer; the per-section test is "name what this HTML has
that the synthesis does not"; the material comes from following the synthesis's pointers; act on the
synthesis's visual cues without a mandated catalog; carry register, provenance grade, and unreconciled
disagreements through from the synthesis; obey the shape rule; name the sources the detail layer drew on,
and say so plainly when the brief restricted them; the hard safety limits; accessibility; write one file
and report little.

**`claude-pack/skills/_my_mental_model/feedback/html.md`** *(new — shared starter)*
Header and stated purpose only, matching `feedback/synthesis.md`. It fills from real runs by promotion.

**`.project/mental-alignment/feedback-html.md`, `feedback-synthesis.md`** *(new, created on first write)*
Project-local feedback bodies. Two-line purpose header, then appended dated entries. Absence is empty.

**`.project/mental-alignment/runs/{stem}_{path}.html`** *(new output)*
One standalone HTML per render, paired to its synthesis by stem.

---

## Non-Goals

- Automated quality checks, HTML validation, a style guide, or a visual design system. The owner judges.
- Any Codex wiring — the allowlist entry, the name mapping, the recursive adapter pass over the skill
  directory, and the dictionary entries for the phrases this item introduces are all Item 5. This design
  produces the phrase list; it does not touch the build.
- Promotion into `docs/`, and migrating a v1 `feedback.md` (none exists).
- A catalog of required visual forms. The concept rules it out and the synthesis already names a form
  per section.
- Any second copy of the synthesis's metadata or judgment content. The HTML renders them or omits them;
  it never restates them elsewhere.

---

## Implementation Notes

**Write Claude-native, and keep the phrase list as you go** (ADR 0011). The adapter translates every file
of the skill directory recursively, so authored prose does not carry cross-runtime correctness. Say what
you mean. The obligation this creates is bookkeeping, not restraint: when a step names something
harness-specific, add the phrase to a running list in the plan, and hand that list to Item 5 as the input
to its dictionary work (`scripts/build-codex-pack.sh:133-160`). An unlisted phrase ships clean and
surfaces only when the skill runs on Codex — ADR 0011 accepts that, so the list is the only mitigation
there is.

**Sibling references stay bare filenames in prose** — `visualize.md`, `feedback/html.md`. The coordinator
resolves them against the base directory from Step 1 and passes absolute paths in the brief. Never write
a path containing `_my_mental_model`: it resolves on neither harness (spike A8/B5). This survives ADR
0011 unchanged, because it is about how paths resolve, not about how prose is translated.

**The resumed agent must be told to re-read the synthesis.** It wrote the file and will assume it knows
the contents; the correction gate may have changed them. One sentence in the resumed envelope.

**Wall clock is the coordinator's own measurement**, dispatch to completion signal, cross-checked against
the output file appearing. Tokens are transcription only: report what the runtime states, write
`not measured` when it states nothing (which is the current answer on both runtimes). Never estimate.

**Report back little, and depend on it not at all.** The agent returns the path, one or two lines on what
the detail layer added, and any safety limit it could not meet — commentary, not the completion signal (D11).

**Feedback file creation.** Both project-local files are created on first write with a two-line header; a
missing file is empty, never an error, and never a reason to skip a run.

Render brief skeleton (values resolved by the coordinator):

```
synthesis:     <abs path>            output: <abs path to {stem}_{path}.html>
shape:         checkpoint | plain document
read:          <base>/visualize.md
               <base>/feedback/html.md
               .project/mental-alignment/feedback-html.md   (if present; absence = empty)
report back:   the output path, 1-2 lines on what the detail layer added, any safety limit unmet
```

---

## Potential Risks

- **The HTML restates the synthesis anyway.** The central risk, and prose alone may not prevent it. The
  mitigations are structural: the per-section "name what this adds" test in `visualize.md`, the pointer-
  following instruction that gives the agent material, and the feedback loop as the correction path. The
  first real run is the check.
- **Resume fails in a way that looks like success** — the agent responds but has lost its context and
  silently re-derives. Mitigation: the resumed envelope asks it to re-read the synthesis, so a
  context-less resume degrades into a fresh render rather than a broken one; and the coordinator says
  plainly when a resume errored.
- **Tokens are unavailable on both runtimes** — Item 1 found none on Codex, and the probe found none on
  Claude. The comparison ships with two readings, not three, and every `# Renders` block will say
  `tokens: not measured` until a runtime starts reporting them. Acceptable: wall clock and the owner's
  judgment are the ones that decide. The spec's open question is now closed, with a negative answer.
- **The `# Renders` section leaks into a later render's narrative.** Mitigated by writing it only after
  all renders of an invocation, plus the explicit ignore instruction in `visualize.md`.
- **Comparison cost.** Two renders on one question is roughly double the work. It is owner-initiated only
  and never a default.

## Integration Strategy

This is the second half of one skill; it lands entirely inside
`claude-pack/skills/_my_mental_model/` plus the project-local files a run creates. Installation is
unchanged — `setup-global.sh` already symlinks the whole directory, so both new files arrive with the
next run of it, and no build or script change is needed on the Claude side. Nothing outside the skill
directory is modified. Item 5 picks up the Codex lane against the finished directory.

## Validation Approach

No automated checks — the concept forbids them here. Validation is a set of manual runs against the spec's
success criteria:

1. **Solo fresh render on the existing ralph-loop synthesis** (SC2). Cheapest first test — its agent is
   long gone, so only the fresh path applies, which also proves rendering from a past synthesis. Confirms
   D1 naming, the reading list, and D11's file-is-the-signal rule.
2. **A full live run to the pause, then a resumed render** (SC1). The first exercise of resume in anger,
   and the first informal read on whether the two paths differ.
3. **Skeleton-vs-meat check** (SC3): for three narrative sections, name what the HTML has that the
   synthesis does not. Any section answering "nothing" is a failure of that section.
4. **Shape check** (SC4): one run each; metadata and judgment render under checkpoint, are absent under
   plain document, and the judgment is read back in the terminal.
5. **Comparison** (SC5): two distinct files, a `# Renders` block with wall clock for each, `tokens: not
   measured`, and the owner's quality reading preserved per HTML.
6. **Correction gate** (SC10): correct at the pause, then render both ways; the saved file changes first
   and both HTMLs reflect it. Separately, confirm that a correction with the synthesis agent unreachable
   reports the failure and stops, leaving the file untouched (D14).
7. **Clean-room render** (D9): a clean-room run reaches the pause and the coordinator states the
   free-exploration default and offers the override. Take the override once and confirm the HTML says its
   detail is bounded; take the default once and confirm the HTML names the wider sources it drew on.
8. **Feedback and promotion** (SC6, SC8): one entry against a specific HTML, promoted, landing as an
   uncommitted pack edit. Then a simulated copy install, where promotion refuses and marks the entry.
9. **Reachability** (SC7, SC9): both new files present in the installed symlinked directory and read
   during a real run.

## Next-Stage Handoff

**Fixed:** the nine-step coordinator shape; naming (D1); one brief, two envelopes (D2); readings in a
trailing `# Renders` section (D3); the ledger-style feedback entry (D4); fail-closed marking in place
(D5); no tool restrictions (D6); the resolved-path promotion test (D7); attempt-don't-pre-check (D8); the
file as completion signal (D11); Claude-native prose plus a phrase list for the adapter (D13).

**Fixed by owner decision at design review, not open to re-derivation:** clean room does not constrain
the render by default, with the override offered at the pause (D9, DR-1); an unreachable synthesis agent
at the correction gate stops the run (D14, DR-3); cross-runtime correctness belongs to the adapter under
ADR 0011, not to authored prose (D13, DR-2).

**Open by design:** the prose of `visualize.md` and the header wording of `feedback/html.md` — authored
deliverables rather than plan items.

**Also carried to the plan:** the running list of harness-specific phrases introduced by Steps 5–9 and
`visualize.md`. It is Item 5's input and nothing checks for it, so the plan must name it as an artifact
rather than leaving it as an intention.

**De-risk first:** write `visualize.md` and Step 6, then run validation step 1 before building Steps 7–9.
It is cheap, it needs no live synthesis agent, and it hits the design's central risk — whether the HTML
adds a real second layer — while everything downstream is still easy to change.

---

## Appendix A — Resume and token probe (Claude, 2026-08-20)

Mirror of Item 1's Codex probe, run during this design to close two open questions.

**Method.** Spawned a named subagent (`probe-resume-01`) with a trivial first turn: generate a random hex
nonce, write it to a scratchpad file, memorize it, report only `DONE`. Read the nonce independently
(`9abceb41`). After completion, sent a second turn by name asking it to recall the nonce from memory with
no file reads or commands.

**Result: resume confirmed.** The second turn returned `9abceb41`, matching the independently-read file.
The agent held first-turn context across a completed turn boundary and recovered a value it had been told
not to report the first time. Same outcome as Item 1's Codex probe.

**Three secondary findings, all of which changed the design.**

1. **No token or usage figure was available.** The coordinator saw lifecycle signals only —
   `idle_notification` with `idleReason: available`, carrying identity and state, no input, output, or
   total count. Structurally identical to the Codex finding. This closes the spec's last open question
   with a negative answer: on Claude as on Codex, `tokens: not measured`.
2. **`ListAgents` did not list the in-process subagent** at any point, before or after completion. There
   is no reliable pre-flight check for resume availability, which is why D8 attempts the send instead.
3. **The agent's turn output did not reach the coordinator.** Turn 1's `DONE` and turn 2's first answer
   were both invisible; the answer arrived only after a third message told the agent to report explicitly.
   The coordinator must therefore treat the output file as the completion signal (D11) — which is what
   Item 3's Step 4 already does, so the seam was right by accident and is now right on purpose.

**What the probe does not establish.** It used a trivial one-tool agent, not a long synthesis agent with a
large window. Resume after context compaction is untested and stays in the degradation path: the spec
already requires the coordinator to handle an unavailable agent by offering the fresh path.

---

## Appendix B — Open questions from the spec, and where each is answered

| Spec open question | Answer |
|---|---|
| HTML naming for comparisons | D1 |
| Render-agent prompt composition | D2, Implementation Notes brief skeleton |
| Render-agent tool restrictions | D6 (none by default); D9 for the clean-room override |
| Feedback entry format | D4 |
| Promotion candidate format | D5 |
| Durable recording of readings | D3 |
| Whether `visualize.md` prescribes visual forms | No catalog; Component Overview names the spine |
| Claude token data availability | Appendix A — none available; `not measured` on both runtimes |
