# Expected Notes — mental-model reviewer fixture

Acceptance evidence for design bet **B1**: a small model given only an artifact, the prompt, and the feedback list flags recorded anti-patterns and prompt-structure misses, with a citation for each, at a rate worth a round trip. One-time evidence for this item, never a shipped check (spec Non-Goals; ADR 0012 invariant).

This file and `fixture-planted-synthesis.md` were written together, before `review.md` existed. **The fixture is never adjusted to make a run pass.** If a run misses a plant, `review.md` changes; the plant does not.

## The scenario

`fixture-planted-synthesis.md` is a plausible synthesis in the `design_synthesis.md` shape — frontmatter, `TLDR`, a five-section numbered body, `Judgment`, and a trailing `# Renders` block — about an invented rate-limiting proxy called Cutwater. The reviewer has no way to know whether anything it says about Cutwater is true, which is the point: it judges form, not conclusions.

Two defects are planted, one in each direction the reviewer is asked to look. Everything else in the file is written to be clean, so the plants stand out. Extra true notes are fine and expected; they are not failures.

## Plants

### P1 — commission: an abstraction performing a verb

- **Where:** section 2, the second sentence of the opening paragraph — `The remaining budget decides whether the call goes through.`
- **Why it is a defect:** "the remaining budget" is an abstraction, and it is the subject of "decides". The recorded pattern is the same shape as the entry's Bad line, `stored energy decides the check`.
- **What it must cite:** the shared synthesis feedback — rule 5 (`A concrete subject does a concrete thing. Never an abstraction performing a verb.`) or the `Abstraction performing a verb` example group. Either citation counts.
- **Direction:** things to reconsider.

### P2 — omission: a multi-step concept decomposed in place

- **Where:** section 2.3, `The allowance drains and refills` — the four-step refill calculation (base rate, error-rate scaling, route-group cap, carry-forward, plus why the order matters) is decomposed inside the subsection.
- **Why it is a defect:** `design_synthesis.md` says a concept whose backing is itself multi-step reasoning gets its own numbered section further down, pointed to from the step that raised it, and is not decomposed in place. The refill is exactly that concept, and section 2.3 does exactly that.
- **What it must cite:** the `design_synthesis.md` rule on multi-step concepts — the writing-the-narrative bullet ending `do not decompose it in place`.
- **Direction:** either list. The technique the artifact passed up is "give it its own numbered section and point to it"; whether the reviewer files that under things to reconsider or techniques worth considering does not matter, as long as it names the miss and cites the rule.

## What a passing run looks like

- The notes file exists at the path the brief named.
- Both plants appear, each with a citation that resolves to a real line in the prompt or the feedback file.
- Ten items or fewer, most important first.
- No item is a judgment about whether Cutwater's design is any good, whether fail-open is wise, or whether the burst-pool disagreement is real. Those are the content's conclusions, and the reviewer has no sources.
- Nothing in the notes reviews the trailing `# Renders` block. That is coordinator bookkeeping and `review.md` says to skip it.

## Citation strings the stencil greps

The greps are deliberately loose about wording and strict about which rule is being named.

| Plant | Case-insensitive pattern |
|---|---|
| P1 | `abstraction performing\|abstraction the actor\|abstraction as the actor\|concrete subject does a concrete thing` |
| P2 | `multi-step\|own numbered section\|decompose it in place` |

## Run log

`review.md` was adjusted twice during Phase 1 and never after; the fixture was never adjusted at all.

| Run | Model | `review.md` | Files reviewed against | P1 | P2 | Notes | Cites an entry by name |
|---|---|---|---|---|---|---|---|
| 1 | haiku | v1 | draft (rules + examples in feedback) | miss | miss | 2 | no |
| 2 | haiku | v2 three-pass method | draft | miss | miss | 4 | no |
| 3 | haiku | v3 sentence sweep fixed | draft | hit | miss | 5 | no |
| sonnet | sonnet | v3 | draft | hit | hit | 9 | yes |
| post-split | haiku | v3 | post-split (rules in prompt, examples only in feedback) | miss | miss | 2 | no |
| post-split | sonnet | v3 | post-split | hit | hit | 7 | yes, three times |

Across all six runs every note cited a rule or entry that exists, none invented a standard, none judged the invented system's conclusions, none reviewed the trailing `# Renders` block, and every run respected the cap and the file format.
