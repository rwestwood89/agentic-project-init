# Spec Review: Spike and Learning-Test Commands

**Spec:** `.project/active/spike-and-learning-test-commands/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/spike-and-learning-test-commands/spec-review.md`
**Date:** 2026-07-02

---

## Reality Check

**Sound.** The spec is about the right work item, the Problem section is accurate, and the
core requirements are directionally correct. I checked the load-bearing code claims and they
hold: `/_my_research` really is read-only (it spawns Explore/general-purpose agents to analyze
existing code, never writes probe code — `_my_research.md:29-45`), the symlink and Codex build
steps match `CLAUDE.md`, and `_my_concept_design.md:318-328` even has a "First risk to de-risk"
handoff slot that is a natural wiring point. Nothing here needs a rework. The findings below are
about one under-argued bet and a couple of ambiguities that will bite design if left as-is.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim:** The spike-location requirement is tagged `[HARD]`
(`spec.md:61-63`: "Spike scripts live with the work item…") but it isn't hard in the sense the
contract means. `[HARD]` is "forced by an interface, physics, or an existing system"
(`_my_spec.md:96`). File placement is a choice — scripts could just as well live in
`.project/research/`, a scratch dir, or the work-item folder. The user may have decided this
firmly, which is fine, but that makes it a `[NEED]` (a stakeholder outcome the user wants), not
a `[HARD]`. Retag it so the reader doesn't read a preference as an external constraint. Low
stakes, but the tags are the spec's main honesty signal.

**L1-2 · Direct claim (positive):** The `[INFERRED]` wiring targets (`spec.md:70-74`,
`/_my_epic_plan` and the `/_my_research` cross-reference) are tagged honestly and marked "to
confirm at review." That is exactly the behavior the contract wants — probing and honestly
tagged inference, not invented requirements. No action; noting it so the retag in L1-1 isn't
mistaken for a faithfulness problem across the board.

### Lens 2 — Problem & Approach

**L2-1 · Question to the user:** The central bet of this spec is that spike and learning-test
are **two separate commands**, not one. The spec asserts this ("they differ enough to be separate
commands," `spec.md:27-28`) but never defends it. Argue the opposite and it doesn't obviously
fall apart: both write throwaway/probe code to learn how something behaves, both produce a
findings doc, both are "hands-on de-risking," and both get suggested from the same pipeline
points. The stated difference is goal clarity (clear vs. fuzzy) and output shape (scratch scripts
vs. real tests) — a difference of degree along one axis. Two commands means two command files,
two Codex skills, two description overrides, and two doc entries to keep in sync, plus a
standing "which one do I reach for?" decision for every user. **Is the goal-clarity / output-shape
difference worth a hard command boundary, or is this one `/_my_spike` command that adapts its
output to how well-defined the goal is?** This is the decision the rest of the spec rests on;
it should be argued, not stated. (Success criterion `spec.md:45-46` — "make its use case
unmistakable" — is *harder* to hit with two overlapping commands, not easier.)

**L2-2 · Question to the user:** What is the fate of a learning test's "real tests"? The spec
says the command produces "*real tests* (not scratch scripts)" (`spec.md:42-44`) and defers their
location, and a non-goal says it won't prescribe "where **kept** learning tests live"
(`spec.md:79-80`) — "kept" implies they join the suite. But a spike's scripts are explicitly
throwaway. So the real distinction between the two commands may not be goal-clarity at all — it
may be **throwaway vs. kept**. If learning tests are meant to survive into the test suite and
spikes are not, say that plainly; it's a cleaner line than "fuzzy goal vs. clear goal" and it
directly informs L2-1. If they're *not* kept, then "real tests" is misleading and should be
softened. Right now a reader can't tell which world we're in.

**L2-3 · If-then tradeoff:** This spec and the workflow-orchestrator spec were created together,
and the orchestrator spec says its "first deliverable is a de-risking spike on the subagent
invocation mechanism" (`workflow-orchestrator/spec.md:17,74`). If the `/_my_spike` command lands
first, the orchestrator's spike is the obvious first user of it — worth a one-line note so the two
efforts don't invent parallel notions of "spike." If the orchestrator spike runs first as a
one-off, that's fine too, but then this command should learn from it. Not a defect; a
sequencing question the two specs should acknowledge each other on.

### Lens 3 — Pipeline Risk

**L3-1 · Too vague:** "Real tests (not scratch scripts)" (`spec.md:42`) is the property that
separates the two commands, and it isn't defined. Both a spike script and a learning test are
code you write to observe behavior. What makes one "real" and the other "scratch"? Two engineers
would build materially different learning-test commands from this sentence: one produces
throwaway-but-well-formed test functions, another produces tests meant to be committed. This is
the same gap as L2-2, viewed from the design-risk side. Design needs a one-sentence definition
of "real test" here, or it will guess.

**L3-2 · Question to the user:** How will the wiring be certified? Three success criteria
(`spec.md:45-49`) are about prompt behavior — a command "makes its use case unmistakable," pipeline
commands "suggest the right technique at the right moment." These are prompt edits with no
runtime, so `/_my_audit` can't exercise them the way it can exercise code. That's not a reason to
drop them, but the spec should say how we'll judge them met — e.g., a reviewer reads the edited
prompt and confirms the suggestion fires on the right trigger and distinguishes the two cases.
Otherwise "the right moment" is untestable and the criterion can be checked off on faith.

**L3-3 · Missing content:** The Problem's real goal is that agents "notice uncertainty and
de-risk with hands-on code" so unknown-unknowns don't surface late (`spec.md:23-25`). That loop
only closes if the spike/learning-test **findings feed back into** the spec/design that triggered
them. No success criterion covers the return trip — that after the probe, the pipeline stage
consumes the findings doc and updates its assumptions. Consider whether "the findings doc re-enters
the triggering stage" belongs as a criterion, or is deliberately left implicit. As written, the
spec guarantees the commands exist and get suggested, but not that their output changes anything.

### Lens 4 — Hygiene

No material findings. The spec is clean, correctly scoped to four sections plus deferrals, and
each fact lives in one place.

### Lens 5 — Reader Comprehension

No findings. The spec reads in one pass — the spike/learning-test distinction is stated plainly
up front, and the voice matches `working-voice.md`. (The distinction being *clear to read* is
separate from its being *the right distinction* — that's L2-1/L2-2, not a comprehension problem.)

---

## Engagement Summary

**Overall take:** The spec is faithful, well-written, and correct about the codebase — the reality
check passes cleanly. But its load-bearing decision, splitting this into two commands, is asserted
rather than argued, and the property that's supposed to separate them ("real tests" vs. "throwaway
scripts") is left undefined. Settle those two and this is ready for design.

**Here's what I need you to weigh in on:**

1. **[L2-1]** Defend the two-command split, or collapse it. Spike and learning-test overlap heavily;
   the case for a hard command boundary vs. one adaptive `/_my_spike` needs to be made, not stated.
2. **[L2-2, L3-1]** Decide and state the real distinction: is it *throwaway vs. kept* (spike scripts
   die, learning tests join the suite), or *clear goal vs. fuzzy goal*? Define what "real test" means.
   This likely resolves L2-1 too.
3. **[L3-2]** Say how the prompt-wiring criteria get certified, given there's no runtime to test them.
4. **[L3-3]** Decide whether "findings re-enter the triggering stage" is a success criterion or a
   deliberate omission — it's the loop the Problem section is actually about.
5. **[L1-1]** Retag the spike-location requirement from `[HARD]` to `[NEED]` — it's a user choice,
   not an external constraint.

---

**Verdict:** Revise

**Next Steps:** Answer 1 and 2 (they're the same decision seen twice), make the quick calls on 3–5,
then re-run `/_my_spec` to fold them in. No re-review needed unless the answer to 1 changes the shape
of the work.
