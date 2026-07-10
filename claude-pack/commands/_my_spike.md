# Spike Command

**Purpose:** De-risk a *known* assumption by writing a throwaway probe and feeding the finding back into the pipeline
**Input:** A question or assumption to confirm (e.g. "does this library actually stream partial results?")
**Output:** A findings doc + scratch scripts in the work-item folder, or in a created `active/spike-{topic}/`

## Overview

Use `/_my_spike` when you have a **clear goal and a specific assumption to confirm**, and the
only honest way to confirm it is to run code. You write a throwaway script, learn the answer,
and throw the script away. (If instead the goal is fuzzy and you're *mapping* an unfamiliar
surface to understand it, use `/_my_learning_test` — its output is real kept tests, not scratch.)

This is the write-code-to-learn counterpart to `/_my_research`, which is read-only. Research
reads existing code to understand it; a spike writes new code to find out how something behaves.

When invoked:
- If a question/assumption is provided: proceed to Stage 1.
- If none: ask "What assumption do you want to de-risk?" and wait.

## Process

### Stage 1: Understand the question

1. **Pin the assumption.** State in one sentence what you believe and what would prove or
   disprove it. A spike without a sharp question wanders.
2. **Note the source.** Identify the upstream artifact this spike serves — the concept, spec,
   design, or epic you paused out of. You'll write the answer back there in Stage 5, so find it
   now. If you can't tell what triggered the spike, ask the user before probing.

### Stage 2: Locate or create the home folder

Spike scripts and the findings doc live **together**, with the work item they de-risk.

1. **If an active work-item folder is in play** (`.project/active/{feature}/`), use it.
2. **Otherwise**, create `.project/active/spike-{topic}/` and work there.

Never scatter spike scripts elsewhere — everything for one question stays in one folder.

### Stage 3: Probe, reproducibly, with a living findings doc

Probe how the thing actually works — take your time, try different approaches. As you go,
keep a **living findings doc** in the home folder, updating it as you learn rather than writing
a report at the end.

1. **Write scratch scripts into the home folder.** Real, runnable probes — not manual pokes at a
   REPL that leave no trace.
2. **Record every step as you go.** Everything you do should be reproducible: a reader must be
   able to re-run your probes and see what you saw. Log commands, inputs, and what you observed.
3. **Start the findings doc** with this shape (leave the summary blank until Stage 4):

   ```markdown
   # Spike: {topic}

   ## Summary of Findings
   <!-- written last, in Stage 4 -->

   ## Question / Goal
   The assumption under test and what would confirm or disprove it.

   ## Log
   Living record, appended as you go: each approach tried, the command run,
   and what you observed. Reproducible steps.

   ## Reproduction
   How to re-run everything from scratch (setup, commands, expected output).

   ## Open Questions / Follow-ups
   What this spike did not settle.
   ```

### Stage 4: Write the summary, on top

Just before you finish, write a **Summary of Findings** at the *top* of the doc, so the next
reader gets the answer first. Lead with the verdict: was the assumption confirmed or not, and
what does that mean for the upstream work. Then the supporting detail.

### Stage 5: Close the loop

A spike that dead-ends in an orphan doc taught the pipeline nothing. Feed the learning back.

1. **Write a back-reference into the triggering upstream artifact** (the one you found in
   Stage 1). Prefer the spot where the reader meets the question the spike answered — the
   specific decision, bet, or bullet it resolved, so the answer sits in context. If there's no
   such spot, fall back to where that doc type keeps links:
   - spec / design → **Related Artifacts**
   - concept → **Next-Stage Handoff**
   - epic → **Source Documents** (or the item's Required Reading)
2. **Note what the spike resolved**, not just the path — e.g. "Spike confirmed the library
   streams partial results; see `active/spike-.../findings.md`." The reader should learn the
   answer from the back-reference alone.
3. **If there genuinely is no upstream doc to link**, tell the user there was nothing to link
   and why, so the gap is visible rather than silently skipped.

## Guidelines

### Metadata
For any dated artifact, get metadata the standard way:
```bash
.project/scripts/get-metadata.sh
```
If that script is absent, fall back to `git` for branch/hash and the system date.

### Required Invariants (never violate)
- **Reproducible.** No untracked manual steps. A reader can re-run everything.
- **Summary-on-top, written last.** The doc's first section is the answer, written in Stage 4.
- **Loop closed.** A completed spike always leaves a back-reference in the triggering doc, or
  tells the user why there was nothing to link.
- **Scripts stay with the item.** Spike scripts live in the work-item or `spike-{topic}/`
  folder — never scattered elsewhere. They are scratch; they travel with the item.

### Scope
- The scripts are throwaway. Don't polish them into production code — if the surface turns out
  to need real tests, that's a `/_my_learning_test`, not a spike.
- Keep it small. A spike answers one question. If it sprawls into many, split it.

---

**Related Commands:**
- Fuzzy goal, mapping a surface → `/_my_learning_test` (writes real, kept tests)
- Read-only investigation of existing code → `/_my_research`

**Last Updated**: 2026-07-03
