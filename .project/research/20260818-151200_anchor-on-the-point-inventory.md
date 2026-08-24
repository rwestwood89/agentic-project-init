---
date: 2026-08-18T15:12:00-07:00
researcher: Claude
topic: "Anchor on the point — inventory of every mechanism in the pipeline"
tags: [research, pipeline, comprehension, point-anchoring]
status: complete
last_updated: 2026-08-18
---

# Research: Where Does the Pipeline Try to Anchor on the Point?

**Date**: 2026-08-18
**Research Type**: Pipeline Architecture

## Research Question

Where in the pipeline (commands, hooks, agents, rules) do we try to get the agent to understand
and hold the purpose/problem/strategy of the work? For each instance: the mechanism, whether
it's enforceable or just an exhortation, and where a comprehension-pumping hook might fit.

## Summary

- **26 instances** across 13 commands + 1 script + 2 rules try to anchor on the point.
- **Every single one is either an instruction or a template slot.** None produces a checkable
  artifact whose wrongness would be visible without human review.
- The product-lens is the closest thing to an automated check — it runs contradiction detection
  against source docs. But it checks the *artifact's* framing, not the *agent's* understanding.
  An agent that extracts and stamps citations passes the lens without having processed meaning.
- The pipeline has **zero transfer tasks** — questions whose answers require synthesis, not
  extraction. Every "state the point" instruction can be satisfied by copying a quotable line.
- **Three structural gaps** where a comprehension-pumping gate would have the highest leverage:
  (1) orchestrator orientation, (2) handoff writing, (3) deliverable writing.

## Detailed Findings — The Full Inventory

Each entry: **[MECHANISM]** what it is, **[ENFORCEABLE?]** whether skipping it is silent or
visible, **[WORDING]** the key instruction.

---

### Tier 1: Shaping (concept, concept_design, concept_design_review, epic_plan)

#### `_my_concept` — concept.md:48-84

1. **[INSTRUCTION]** Stage 2 enforces "Level 1: The Problem (WHY)" before solutions.
   **Enforceable?** No — the command says "do not discuss solutions yet" and "stay on the
   problem until the user is satisfied you understand it." But the agent self-certifies when
   to advance levels. The user is the only gate.
   **Wording:** "Do NOT discuss solutions yet. Stay on the problem until the user is satisfied
   you understand it."

2. **[INSTRUCTION]** "Self-certify understanding" is in the MUST NOT list (concept.md:252).
   **Enforceable?** No — an exhortation. Nothing checks whether the agent actually re-grounded
   after a correction.
   **Wording:** "Never say 'now I understand' and proceed."

#### `_my_concept_design` — concept_design.md:34-36, 49-63

3. **[TEMPLATE SLOT]** The two-register rule (concept_design.md:49-79): upper half describes
   the *world* (no code identifiers), lower half describes the *code*.
   **Enforceable?** Partially — the self-review rubric checks register leakage mechanically
   (scan for backticks in Problem/Goals). But register discipline is about comprehension form,
   not about the *point* being correct. An agent can write a perfectly register-clean document
   about the wrong problem.

4. **[RUBRIC ITEM]** "Cold-reader test passes" (concept_design.md:542).
   **Enforceable?** Self-checked. The agent grades itself.
   **Wording:** "Imagine a colleague on another team reading the upper half. Do they finish
   Problem and Goals knowing what's wrong and what we want?"

#### `_my_concept_design_review` — concept_design_review.md:18-27

5. **[INSTRUCTION]** Governing question: "Are we actually solving the right problem?"
   **Enforceable?** The reviewer is a fresh agent, so it re-derives from sources. But its
   judgment is still LLM pattern-matching, not verified comprehension.
   **Wording:** "Do not reward a concept for accurately documenting an enlarged or broken
   system."

6. **[GATE]** Mandatory ponytail challenge (concept_design_review.md:56-86).
   **Enforceable?** Yes — structural. A subagent must return a written challenge. But the
   ponytail checks *architecture minimality*, not *point comprehension*. It asks "does this
   machinery need to exist?" not "does this machinery serve the stated purpose?"

#### `_my_epic_plan` — epic_plan.md:44

7. **[OFFER]** Mental-model checkpoint after decomposition.
   **Enforceable?** No — it's an offer the user can decline. Skipped in orchestration
   (NON-INTERACTIVE marker). Even when accepted, it explains the agent's current model — it
   does not verify the model is correct.

---

### Tier 2: Specification (spec, spec_review)

#### `_my_spec` — spec.md:3, 9, 14-17

8. **[POSTURE]** "Aggressive about the problem. Conservative about the solution."
   **Enforceable?** No — a posture instruction. The spec's structure (Problem, Success Criteria,
   Known Requirements) channels the agent toward capturing the problem, but the agent can fill
   the template with extracted content.

9. **[INSTRUCTION]** "Read Required Reading from the epic" (spec.md:29).
   **Enforceable?** No — an instruction that can be silently skipped. The agent that skipped
   the concept doc in the crisis session is the proof.

10. **[GATE]** Product-lens at spec stage (spec.md:141-153).
    **Enforceable?** Yes — structural. A subagent runs contradiction detection against source
    docs. But it checks text-vs-text, not comprehension. An artifact that never mentions the
    point passes (no contradiction), which is exactly what happened.

#### `_my_spec_review` — spec_review.md:17-24, 30-56

11. **[POSTURE]** Devil's advocate — "assume the spec agent paraphrased the user into something
    adjacent."
    **Enforceable?** Partially — the review is a fresh session with access to sources. But the
    review checks faithfulness to the user's *stated* ask, not to the broader purpose.

12. **[LENS]** Lens 2: Problem & Approach — "Is this the right problem, framed correctly?"
    **Enforceable?** No — a judgment call by the review agent. No mechanical check.
    **Wording:** "What bet is this spec making? Is it articulated, or is it silently baked in?"

---

### Tier 3: Design (design, design_review)

#### `_my_design` — design.md:88-89, 124-143, 293-299

13. **[TEMPLATE SLOT]** "The Point" section in the design document (design.md:293-299).
    **Enforceable?** Partially — the template has the slot, so the agent must write *something*.
    But there's no check that what's written matches the concept/spec. The product-lens doesn't
    run at design-authoring time (it runs at design-review and audit).
    **Wording:** "The product obligation this work serves — the problem, and how it ladders up
    to the bigger goal — stated in full, not reduced to a pointer."

14. **[INSTRUCTION]** Core Concept gate: "Do NOT proceed to REFINE until the concept is
    articulated. If you can't explain the design in one paragraph, you need more research."
    (design.md:133)
    **Enforceable?** No — the agent self-certifies when the concept is "articulated."

15. **[INSTRUCTION]** Anchor-back during REFINE (design.md:137-142): "Re-read the Core Concept
    before drafting. If a section starts to introduce mechanisms not foreshadowed by the Core
    Concept, STOP."
    **Enforceable?** No — self-policed. The agent decides whether drift occurred.

16. **[REFLECTION]** "Business Goals" check in REFLECT (design.md:174).
    **Enforceable?** No — a self-directed question. "Does this design serve the business goals
    stated in the spec?" The agent answers it internally.

#### `_my_design_review` — design_review.md:35-55

17. **[GATE]** Product-lens at design review (design_review.md:42).
    **Enforceable?** Yes — structural. "Derive the point independently — do not inherit the
    design's framing." Runs contradiction detection. But same limitation: text-vs-text, not
    comprehension.

18. **[TEMPLATE SLOT]** "The Point" section in the design review (design_review.md:182-188).
    **Enforceable?** Partially — must be filled in. But can be copy-pasted from the design.
    **Wording:** "The full problem this work serves, carried from the design's 'The Point' and
    the spec — stated legibly here, not a pointer."

19. **[SMELL CHECK]** Smell 2 and 7 from product-lens §4 (design_review.md:43-44).
    **Enforceable?** Partially — mechanical tripwires, but they check architecture patterns
    (consumer compensating for producer, ownership change), not point-alignment.

---

### Tier 4: Implementation (implement, plan)

#### `_my_implement` — implement.md:7-18, 189-199

20. **[INSTRUCTION]** "CRITICAL: Do NOT blindly follow the plan." Stage 0 is "Understanding
    Before Action" — mandatory, read design and spec FULLY, understand WHY.
    **Enforceable?** No — the agent self-certifies that it understood. The bold, caps, and
    "MANDATORY" framing did not prevent the crisis failure.
    **Wording:** "Understand WHY before implementing WHAT."

21. **[INSTRUCTION]** During implementation: "Does this serve the business goals in the spec?"
    **Enforceable?** No — a self-directed check at implementation time.

---

### Tier 5: Certification and Close (audit, close)

#### `_my_audit` — audit.md:37-52, 109-111

22. **[GATE]** Product-lens at audit (audit.md:37-52).
    **Enforceable?** Yes — structural. Independent re-derivation of the point. Blocks
    certification if owner/HARD contradiction found.
    **Wording:** "Derive the point independently — do not inherit the spec's or design's
    framing."

23. **[TEMPLATE SLOT]** "The Point" in audit.md (audit.md:109-111).
    **Enforceable?** Partially — must fill the slot. But again, can be carried from design.
    **Wording:** "The full problem this work serves, carried from the design's 'The Point' and
    the spec — stated legibly here, not a pointer."

24. **[JUDGMENT]** Holistic "is this the right piece of work?" judgment (audit.md:49-52).
    **Enforceable?** Partially — gates certification. But it's an LLM judgment call, not a
    mechanical check.

---

### Tier 6: Orchestration (orchestrate, handoff)

#### `_my_orchestrate` — orchestrate.md:19, 46-55

25. **[INSTRUCTION]** "Stay on intent" — one of the two things that matter most.
    **Enforceable?** No — a posture instruction to the orchestrator.
    **Wording:** "Keep the objective and its broader context in view the whole way."

26. **[CHECKPOINT]** Align message at launch — "the meaning of the work as you read it."
    **Enforceable?** Partially — requires sending the message and waiting for the owner's reply.
    But the owner's review is optional attention, not a gate. The orchestrator can write a wrong
    Align, get a thumbs-up, and proceed.
    **Wording:** "do you literally want X, or are you solving for Y?"

#### `_my_handoff` — handoff.md

27. **[TEMPLATE]** The handoff has no "The Point" section. It has "Focus" and "Context."
    **Enforceable?** No — the handoff has no structural requirement to carry the point. The
    crisis failure: the orchestrator wrote a handoff that promoted its own compressed frame to
    ground truth, without pointing at the concept doc. The template doesn't prevent this.

---

### Cross-cutting: Rules and Scripts

#### `capture-fidelity.md` — rules/capture-fidelity.md

28. **[RULE]** "Authority comes from the source, not from being written down." Provenance grades.
    **Enforceable?** Partially — provenance tags are checked at review stages. But provenance
    tracks *who said it*, not *whether the agent understood it*. An agent that stamps
    `[OWNER: concept :18-23]` five times without reading the concept satisfies provenance.

#### `product-lens.md` — scripts/product-lens.md

29. **[SCRIPT]** The oracle-first protocol: "Read SOURCES first. Derive the point and write it
    down before you look at the WORK."
    **Enforceable?** Yes — the protocol is structural and the subagent runs independently. But
    it's a contradiction detector, not a comprehension test. It catches "the handoff says X, the
    concept says Y." It does not catch "the handoff says nothing about the point."

---

## The Pattern

Every mechanism falls into one of four categories:

| Category | Count | Catches wrong point? | Catches missing point? |
|---|---|---|---|
| **Instruction** ("read this," "understand why") | 14 | No | No |
| **Template slot** ("fill in The Point section") | 5 | No — extraction satisfies | No |
| **Product-lens gate** (contradiction detection) | 4 | Yes — text mismatch | No — absence isn't contradiction |
| **Posture / reflection** (self-directed questions) | 4 | No — self-graded | No |

The pipeline has strong coverage of *contradiction* (the product-lens fires at spec, design-review,
audit, and epic-plan). It has zero coverage of *absence* (the point is never stated → no
contradiction → passes) and zero coverage of *comprehension* (the point is stated by extraction
→ text matches → passes, but the agent doesn't understand it).

## Where a Comprehension-Pumping Hook Would Fit

The hook's job: force the agent to spend internal thinking cycles on the *meaning* of the work,
not just produce text about it. The mechanism: directed transfer questions that can't be answered
by extraction, iterated to force re-derivation from different angles.

### Three high-leverage insertion points

**1. Orchestrator orientation (orchestrate.md, step 1)**

Currently: "Read the concept and decide where to enter." This is the instruction the crisis
agent skipped. A hook here would fire before the Align message. It would inject the concept's
problem statement and require the agent to answer three transfer questions:
- What was broken before this work?
- What does the user do differently after?
- How does the strategy solve the problem?

**Enforceability:** The hook can inject the questions and reject the first two answers with
directed follow-ups. The third answer, connecting strategy to problem, requires synthesis. But
no automated grading — the output is visible in the Align message for the owner to check cheaply.

**2. Handoff writing (handoff.md)**

Currently: no structural requirement to carry the point. The handoff is the laundering step — where
compressed understanding becomes the next agent's ground truth. A hook here would fire before
writing the handoff. Same three transfer questions, but now grounded in what the session actually
did: "State the problem this work serves, how the session's output serves it, and what the next
agent must understand to continue without drifting."

**Enforceability:** Same as above. The output lands in the handoff document and is visible.

**3. Reader-facing deliverable writing (any artifact a human will read)**

Currently: the product-lens runs at review/audit time — after the artifact is written. A hook
here would fire *before* writing, at the moment the agent is about to produce the deliverable.
Transfer questions: "What is this work for, what was the problem before, and what should the
reader take away?"

**Enforceability:** Pre-artifact. If the answers are wrong, the artifact isn't written yet — cheapest
possible catch point.

### Why these three, not everywhere

Every pipeline stage already has "understand the purpose" instructions. Adding the hook to every
stage would be noise — most stages produce internal artifacts (specs, designs, plans) where
comprehension errors surface at the review stage. The three points above are where comprehension
errors are **most expensive and least caught**: orientation (where the frame is set), handoff
(where the frame is transferred), and deliverable writing (where the frame becomes the output).

## The Hook's Limitation

The hook forces re-derivation through iterated questions. It cannot verify comprehension — it can
only make *not comprehending* more expensive (three passes instead of zero). The output is visible
text the owner can check in seconds, which converts an invisible failure (the agent silently
doesn't understand) into a visible one (the agent's three-sentence summary is wrong, and the
owner sees it at Align or in the handoff).

The honest capability boundary: this is a probabilistic improvement, not a guarantee. An agent
that produces three plausible-sounding but wrong summaries still passes. The directed questions
(problem → impact → causal connection) make this harder than generic "explain what you're doing,"
but not impossible.

## Recommendations

1. **Prototype the hook as three fixed directed questions.** Not generic "explain what you're
   doing" — specific transfer questions that require different kinds of synthesis.
2. **Insert at the three high-leverage points**, not everywhere.
3. **Make the output visible**, not graded. The value is that the owner sees the agent's
   understanding early and cheaply, not that an automated system verifies it.
4. **The handoff template needs a structural fix regardless.** Add a required "The Point" section
   with source citations, and a "Required Reading for the next agent" section that lists concept
   and product-lens before record docs.

---

## Hook Implementation: How the Comprehension Pump Would Work

### The mechanism: Stop hook blocking

The Stop hook fires every time Claude finishes a turn. When it blocks (exit code 2), Claude sees
the blocking message, does NOT stop, and continues working. There's no built-in loop limit — the
hook manages its own pass counter via a state file.

This gives us the "reject twice no matter what" pattern:
1. Agent tries to stop → hook blocks with Q1
2. Agent answers Q1, tries to stop → hook blocks with Q2
3. Agent answers Q2, tries to stop → hook blocks with Q3
4. Agent answers Q3, tries to stop → hook allows (pass count ≥ 3)

### Scoping: when should it fire?

The Stop hook fires on EVERY turn — casual chat, quick edits, everything. The pump should only
fire during pipeline work. Solution: **state-file activation.**

Pipeline commands (`_my_orchestrate`, `_my_handoff`, deliverable-writing moments) write a marker
file at their start. The hook checks for the marker. If absent, exit 0 (allow stop). If present,
run the pump. The command cleans up the marker when done.

### Three implementation options

**Option A: Static command hook (recommended starting point)**

A shell script with three fixed directed questions and a state file counting passes. No LLM in
the loop. Each question forces a different kind of synthesis:

- Q1: "State in 3 sentences what problem existed before this work — what the user couldn't do."
- Q2: "That describes mechanics, not impact. What does the user do differently after? What
  capability do they gain?"
- Q3: "Connect those: how does the specific strategy/architecture solve the problem from Q1?
  Why this approach?"

Pros: Dead simple. Three static strings. Deterministic. Q3 can't be answered well without
processing Q1 and Q2. Cons: Generic — not tailored to the specific work. An agent can still
produce three plausible-sounding wrong answers.

**Option B: Prompt handler (model-judged)**

Uses `type: "prompt"` — sends the hook input to a Haiku-class model for single-turn judgment.
The model sees the transcript and decides whether the agent has demonstrated understanding of
WHY, not just WHAT.

Pros: Context-aware, can generate tailored questions. Cons: Sparsely documented, untested. Adds
cost per stop attempt. "Judge another LLM's comprehension" is arguably as hard as the original
problem.

**Option C: Agent handler (subagent verification)**

Uses `type: "agent"` — spawns a subagent that reads the concept doc and compares against the
agent's output. Closest to the "checker agent holding the concept" idea.

Pros: Can read source docs and do real comparison. Cons: Expensive (full subagent per stop),
slow (60s timeout), same LLM-judging-LLM limitation, poorly documented output schema.

### Architecture sketch (Option A)

```
Pipeline command (_my_orchestrate, _my_handoff, etc.)
  │
  ├── writes .claude/comprehension-pump-active
  │     (metadata: concept_path, stage name)
  │
  ├── agent does its work...
  │
  └── agent tries to Stop
        │
        Stop hook fires → comprehension-pump.sh
        │
        ├── reads .claude/comprehension-pump-active
        │   (if absent → exit 0, no pump)
        ├── reads state file for pass count (keyed by session_id)
        ├── pass 0: blocks with Q1 (what was broken?)
        ├── pass 1: blocks with Q2 (what changes for the user?)
        ├── pass 2: blocks with Q3 (how does strategy solve problem?)
        └── pass 3+: allows stop, cleans up state + marker files
```

### How blocking works (the mechanics)

Exit code 2 with stderr = Claude sees the message and keeps going:

```bash
echo "State the problem this work solves, in your own words." >&2
exit 2
```

Or structured JSON output with decision: "block":

```json
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "State the problem this work solves."
  }
}
```

### settings.json configuration

Would be added to the existing hooks in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [ ... existing ... ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/comprehension-pump.sh",
            "timeout": 10,
            "statusMessage": "Checking comprehension..."
          }
        ]
      }
    ]
  }
}
```

### Existing hook patterns in this project

The project already has one hook wired up:

- **PreCompact → precompact-capture.sh → capture.sh**: fires on auto-compaction, reads the
  hook input JSON from stdin (session_id, transcript_path, trigger), and writes a capture file
  to `.project/memories/`. Uses `jq` to parse the input. This is the pattern to follow for the
  comprehension pump — same stdin JSON parsing, same state-file approach.

### Open design questions

1. **Where does the marker file live?** `.claude/comprehension-pump-active` (project-level) or
   `/tmp/comprehension-pump-$SESSION_ID` (ephemeral)? Project-level risks stale markers if a
   session crashes. Ephemeral risks lost state across shell restarts.

2. **Who writes the marker?** The pipeline commands themselves (requires editing each command),
   or a UserPromptSubmit hook that detects `/_my_orchestrate` / `/_my_handoff` invocations?

3. **Should the pump fire per-stop or per-deliverable?** Per-stop is simpler (one hook) but
   means the agent gets pumped on every stop attempt during a long orchestration, not just at
   the deliverable moments. Per-deliverable would need the marker to be written and cleaned up
   at finer granularity.

4. **Should the agent's answers be captured?** The answers to Q1–Q3 are valuable diagnostic
   output — they show the agent's frame at a glance. Writing them to a file
   (`.project/active/*/comprehension-check.md`) would make them auditable. But the hook
   receives only its stdin JSON, not the agent's response text. Capturing would require parsing
   the transcript.

### Documentation references

- Official hooks reference: https://code.claude.com/docs/en/hooks
- Detailed guide (all events, blocking, exit codes): https://claudefa.st/blog/tools/hooks/hooks-guide
- Agent/prompt handler types: Medium codetodeploy series, part 3
- Existing project hook: `claude-pack/hooks/capture.sh` (pattern to follow)
- Hook settings format: `.claude/settings.json` (PreCompact already configured)
