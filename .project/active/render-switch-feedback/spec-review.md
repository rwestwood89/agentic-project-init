# Spec Review: Render + Switch + Feedback (Claude)

**Spec:** `.project/active/render-switch-feedback/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/render-switch-feedback/spec-review.md`
**Date:** 2026-08-20

---

## Reality Check

**Concerns, but the work item is sound.** The spec picks up at the correct seam and preserves the
owner's core render choice, skeleton-to-detail progression, and project-local-first promotion
posture. It is not ready to become the design contract because it drops synthesis feedback from a
system defined around two feedback bodies, drops the owner's quality reading from the comparison,
and leaves pause-time corrections able to reach the two render paths differently. These are
targeted revisions, not a reason to reshape the item.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim: the spec promises a two-body feedback system but specifies only HTML
feedback.**

The Problem says this item completes the two-body, two-tier feedback system
(`spec.md:20-33`). Concept SC7 defines those bodies as synthesis feedback and HTML feedback, each
with a project-local tier (`mental-alignment-checkpoint.md:56-59,170-178`). The epic assigns both
project-local files to Item 4 (`epic_mental_alignment_skill.md:345`).

The contract then narrows silently. SC6 requires feedback tied to a specific HTML
(`spec.md:52-53`); “Feedback — recording” names only `feedback-html.md` (`:168-182`); and the
coordinator offers feedback only after a render (`:217-222`). `feedback-synthesis.md` appears only
as a possible promotion target, with no route for new synthesis feedback to enter it. The spec
needs distinct outcomes for synthesis feedback, attributed to the synthesis/run, and HTML
feedback, attributed to the specific HTML. Otherwise one of the two owner-settled feedback bodies
cannot learn from a run.

**L1-2 · Direct claim: the comparison drops one of the owner's three readings.**

The owner settled comparison on wall-clock time, tokens, and their own read of quality (concept
SC12 at `mental-alignment-checkpoint.md:69-71`, repeated at `:127-138`). The Problem carries all
three (`spec.md:27-33`), but SC5 and the Comparison requirements stop at two HTML files, time, and
the token limitation (`:49-51,124-145`). Optional per-HTML feedback after rendering is tagged
`[INFERRED]` and does not require the comparison to capture or present the owner's quality
assessment (`:180-182,219-222`).

This is an owner-grade outcome, not an optional coordinator flourish. The comparison contract must
let the owner judge the two artifacts and preserve that reading per HTML, even if the format stays
open for design.

**L1-3 · Question to the user: the Claude token conclusion conflicts with the upstream record and
has no durable evidence.**

The epic says Claude's completion notification exposes usage and Codex does not
(`epic_mental_alignment_skill.md:342`). The spec reverses the Claude half: neither runtime exposes
tokens, so both report “not measured” (`spec.md:49-51,137-143,155-158,261-264`). That may be the
correct new observation, but the cited Codex spike only tested Codex and explicitly says it did not
test Claude (`codex-resume-spike/spike-findings.md`, Summary and Question / Goal). No Claude probe
or transcript is cited.

**Did you directly observe the Claude `Agent` completion and `SendMessage` results lacking usage
data?** If yes, preserve that evidence or at least identify the observed result so this premise
conflict is auditable. If not, token availability on Claude is still open and the spec should not
freeze “not measured” as the contract.

**L1-4 · Direct claim: several `[NEED]` tags harden agent-chosen mechanisms into owner-settled
requirements.**

- The render agent's ability to reach its files is the outcome. Requiring the coordinator to put
  resolved absolute paths in the render instruction (`spec.md:92-96`) is a mechanism. The cited
  predecessor resolution explicitly said “state the outcome, leave the mechanism to design”
  (`coordinator-synthesis/spec-review.md`, resolution L1-4).
- The owner settled that both paths can run on one synthesis. Sequential execution with resumed
  first (`spec.md:126-130`) comes from the concept-design's agent-authored flow, not the quoted
  owner statement. The outcome is `[NEED]`; the ordering is `[INHERITED]` or remains a design
  choice.
- If the Claude tool limitation is verified, it is an interface constraint and therefore
  `[HARD]`, not an owner-stated `[NEED]` (`spec.md:137-143`).

These grades decide what design may challenge. Separate the owner outcomes from the inherited or
forced mechanisms before the spec becomes the contract.

### Lens 2 — Problem & Approach

**L2-1 · Question to the user: what must happen to a synthesis correction before rendering?**

The pause exists so the owner can read, correct, and then choose; the live coordinator already
says the owner “may correct” the synthesis (`claude-pack/skills/_my_mental_model/SKILL.md:82-98`).
The render spec starts from the choice and never says how a correction changes the input. That
creates an asymmetric failure: a resumed agent may see a correction in the follow-up conversation,
while a fresh agent reads the unchanged synthesis file. The two comparison renders would no longer
be based on the same authority.

**Should an owner correction amend the saved synthesis before either render starts, making that
corrected file the input to both paths?** I recommend yes. It preserves the synthesis as arbiter
and keeps the A/B comparison controlled. If corrections are meant to be render-only instructions,
the spec needs to say that instead and explain how both paths receive the identical instruction.

### Lens 3 — Pipeline Risk

**L3-1 · Rewrite request: “valid HTML” is not an observable success condition.**

SC1 and SC2 require valid HTML (`spec.md:38-42`), but the spec never defines whether that means a
file with an `.html` suffix, markup a browser can open, structurally well-formed markup, or an
artifact satisfying the inherited safety posture. The Non-Goals correctly reject automated
quality checks; that does not require an ambiguous outcome. Ask the spec agent to state the minimum
human-observable condition that makes a render successful, without inventing a validator or a
style standard.

**L3-2 · Rewrite request: “Coordinator changes” duplicates earlier requirements under weaker
grades.**

The four bullets at `spec.md:212-222` repeat render routing, timing, feedback recording, and
comparison behavior already specified at `:101-182`. Earlier versions are `[NEED]` or
`[INHERITED]`; the duplicates are `[INFERRED]`. This violates the spec contract's one-home rule and
gives design two authority grades for the same behavior. Remove the duplicate summary or retain
only genuinely new coordinator obligations in their single proper sections.

**L3-3 · Direct claim: the timing-record option may violate the no-overwrite invariant.**

The inherited artifact requirement says run files are never overwritten (`spec.md:162-166`). The
timing requirements call the synthesis metadata the natural durable home (`:149-154`), and the
open question explicitly allows appending readings to the existing synthesis (`:254-256`). A
design cannot tell whether “never overwritten” prohibits all post-creation mutation or only
clobbering a prior artifact with a new run.

Clarify the invariant before offering design the append option. Either later annotations are
allowed and “never overwritten” means “never replaced by another run,” or timing must live in a
separate durable artifact.

### Lens 4 — Hygiene

**L4-1 · Rewrite request:** The resolved token question remains in Open Questions as struck-through
history (`spec.md:261-264`) while the same conclusion already lives in Known Requirements. Delete
the resolved entry. Correction history belongs in its source artifact or review, not in the active
contract, and retaining it makes the unsupported conflict in L1-3 look more settled than it is.

### Lens 5 — Reader Comprehension

No material comprehension finding. The spec is long, but its section names and render-path split
let a reviewer find the relevant decisions on one pass. The problems above are contract defects,
not voice defects.

---

## Engagement Summary

**Overall take:** The work item and its central bet are right. The spec needs revision because it
currently implements one of two feedback bodies, measures only two of the owner's three comparison
readings, and does not guarantee that resumed and fresh renders consume the same corrected
synthesis. The remaining findings tighten provenance and remove downstream ambiguity.

**Here's what I need you to weigh in on:**

1. **[L2-1]** Decide whether a pause-time correction must update the saved synthesis before either
   renderer runs. I recommend yes so both render paths consume the same authority.
2. **[L1-1]** Restore synthesis feedback to this item. The current contract only records HTML
   feedback even though the governing model has two feedback bodies.
3. **[L1-2]** Restore the owner's quality assessment as a first-class comparison reading, recorded
   per HTML alongside the available machine readings.
4. **[L1-3]** Confirm whether the missing Claude token data was directly observed. The only durable
   spike cited by the spec covers Codex, while the epic says the opposite about Claude.
5. **[L1-4]** Re-grade path composition, render ordering, and any verified tool limitation so
   agent mechanisms do not become owner-settled needs.
6. **[L3-1, L3-3]** Define the minimum successful HTML outcome and clarify whether later timing
   annotations are compatible with “never overwritten.”

---

## Resolutions

Recorded 2026-08-20. All findings are dispositioned.

- **[L2-1] — Update the synthesis before rendering.** The pause is a correction gate. When the
  owner gives feedback on the synthesis, the coordinator passes it straight back to the synthesis
  agent. That agent updates the saved synthesis before any render starts. Both the resumed and
  fresh render paths then use the corrected file. Owner's reasoning: “why would we move to render
  with a bad synthesis?”

- **[L1-3] — Claude token availability remains open until the first real render.** The owner does
  not recall directly observing the Claude completion or follow-up results. Remove the unsupported
  claim that Claude reports no usage data. The contract is honest reporting per runtime: report
  token usage when the mechanism exposes it; otherwise state “not measured.” Record what the first
  real Claude render actually returns.

- **[L1-1] — Restore both feedback bodies; no new owner choice required.** The concept already
  settles this. Synthesis feedback lands in the project-local synthesis feedback file and is
  attributed to the synthesis/run. HTML feedback lands in the project-local HTML feedback file
  and is attributed to the specific HTML. Both remain eligible for owner-initiated promotion.

- **[L1-2] — Restore the owner's quality reading; no new owner choice required.** The comparison
  presents both HTMLs for owner judgment and preserves the assessment per HTML. Wall-clock time,
  available token data, and owner-assessed quality are the three comparison readings.

- **[L1-4] — Correct the provenance grades.** Keep owner outcomes as needs. Keep path composition
  and render ordering as inherited mechanisms or design choices. Treat an observed runtime limit
  as a hard interface constraint only after it is verified.

- **[L3-1] — Make render success observable without adding a validator.** Replace “valid HTML”
  with the minimum outcome: a standalone HTML file that opens locally in a browser and presents
  the intended content. This does not add automated quality checks or a style standard.

- **[L3-2] — Remove the duplicate coordinator summary.** Each behavior keeps one home and one
  authority grade.

- **[L3-3] — Clarify the no-overwrite rule.** A later run never replaces an earlier run artifact.
  Post-render annotations belonging to the same run, such as timing data, may update that run's
  synthesis. Design still chooses the exact representation.

- **[L4-1] — Delete the struck-through token question.** The active spec carries the current
  requirement only; correction history stays in this review and its source artifacts.

---

**Verdict:** Revise

**Review status:** Final — every finding is dispositioned (2026-08-20).

**Next Steps:** Resolve the findings above, then re-run `my-spec` (or return to the spec-agent
session) and point it at this review to incorporate. The reviewer does not edit the spec.
