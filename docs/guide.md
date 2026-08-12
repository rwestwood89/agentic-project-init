# Building Production Codebases with Claude Code

A practical guide for developers who want to ship top-tier, professional-grade software with Claude Code, not just vibe code.

## Why this exists

Claude Code is excellent at writing code, but multi-day features fall apart for process reasons: sessions are ephemeral, requirements drift when they live only in chat history, and the same agent that wrote something will happily "review" it and agree with itself. This repo fixes that with persistent artifacts — specs, designs, plans, findings — that survive across sessions, plus adversarial reviews that run with fresh eyes.

**This is not a strict pipeline.** It is a set of patterns and flows that you adapt to the nature of the problem. The commands exist so that each kind of decision has a home and a written record — which ones you run, and in what order, follows from a few questions about the problem in front of you.

---

## Start with one question

> **How well do you understand the problem you are trying to solve?**

**If the answer is "well"** — you know what the work is and roughly what done looks like — skip shaping entirely and go straight to [the work-item flow](#the-work-item-flow) below. (And if the change is small and scoped, skip that too: `/_my_quick_edit`.)

**If the answer is "not that well"**, start with **`/_my_concept`**: a research partner that helps you work out what problem matters, what success looks like, and what's deliberately out of scope. You drive; the agent explores the codebase and asks questions. Then ask three follow-up questions:

**"Is there a clear user experience we need to understand?"**
If yes, run **`/_my_product_design`** — think from the consumer's perspective (an end user, an API caller, an engineer reading CLI output) and settle the interaction and interface decisions before technical work starts. It runs off the concept here; for a single work item with a consumer-facing surface it runs off the spec instead — same function, the tier depends on the size of the work.

**"How big of an impact does this have?"**
If high, nail down the major architectural decisions in **`/_my_concept_design`** — boundaries, responsibilities, invariant ownership, the abstractions later work will inherit. To support it, do **`/_my_research`** first: really understand what exists, both in the codebase and outside it (proven tools and approaches, via web search). Big architectural bets deserve a fresh-session challenge before they harden: **`/_my_concept_design_review`**.

**"How much work is there? Should we break this down into shippable pieces?"**
If big, turn it into an epic with **`/_my_epic_plan`** — decompose into backlog items sliced around provable behaviors, each carrying Required Reading back to the shaping documents so downstream stages inherit the original intent.

However you got here, you now hold a **work item** with a reasonable understanding of the problem: either you understood it from the start, or concept (plus research) settled a small piece of work, or the epic gave you items to pick up one at a time.

---

## The work-item flow

<!-- Owner-directed flow statement (2026-08-08); keep consistent with /_my_pipeline -->
`spec` → [`spec_review`] → [`research`] → `design` → [`design_review`] → `plan` → `implement` → `audit` → `close`

Bracketed stages are judgment calls — include them when the item's risk or complexity earns them. Shipping (`pre_pr`) sits *after* the flow, at the branch level — see its entry below.

- **`/_my_spec`** — what must be true when this item is done. Aggressive about the problem, conservative about the solution: requirements are captured as outcomes, graded by who decided them (`[HARD]`/`[NEED]`/`[INFERRED]`/`[INHERITED]`), and mechanism questions are deliberately left open for design.
- **`/_my_spec_review`** — an adversarial fresh-session read before the spec becomes the contract. Worth it when the item is large, ambiguous, or the spec makes code-facing claims.
- **`/_my_design`** — how we'll build it: the core concept, the bets (claims about reality that sink the design if false), the decisions (mechanism choices with rejected alternatives), and the invariants. Research the codebase first if the area is unfamiliar.
- **`/_my_design_review`** — a skeptical fresh-session review before implementation. Its first question outranks the checklist: is this the right piece of work at all?
- **`/_my_plan`** — phases in de-risking order, each starting with a test stencil and ending with "what we know works." Checkboxes make it resumable across sessions.
- **`/_my_implement`** — execute phase by phase, reading spec and design first so it understands *why*, checking off progress and recording deviations in the plan as it goes.
- **`/_my_audit`** — fresh-eyes certification against the whole chain: plan complete, spec satisfied (traced `file:line`), design followed, no slop or silent fallbacks. Never let the implementing session certify its own work.
- **`/_my_close`** — archive to `completed/`, update the books, and file any decisions that emerged during implementation as ADRs — and any implemented product promises to the promise ledger — before their context is archived.
- **`/_my_pre_pr`** — the branch gate, run **after close** and once per PR: project checks, lint, tests, then PR submission. Run it after closing an item that ships on its own; when items ship together, run it once at the end of the epic. It is not an item stage — never run it per-phase or mid-item.

---

## The supporting patterns

### When to research

**`/_my_research`** reads existing code (and the outside world) to produce a findings doc in `.project/research/` that any later stage can reuse. Reach for it:

- before `concept_design`, to ground architectural decisions in what actually exists;
- before `spec` or `design` in an unfamiliar area;
- any time a question in any stage could be answered by reading instead of guessing.

### When to write code to learn

Reading doesn't settle behavioral questions — how a library, tool, or format *actually* acts. Two commands write code to find out, from any stage:

- **`/_my_spike`** — you have one known assumption to confirm ("does this API actually stream partial results?"). Throwaway probe script, kept findings doc.
- **`/_my_learning_test`** — the goal is fuzzy and you're mapping an unfamiliar surface. The output is real tests that stay in the suite, plus a findings doc.

Use them the moment a stage is about to build on an unverified bet. A wrong assumption caught in a spike costs an hour; caught in the audit, it costs the item.

### When architectural decisions get codified (ADRs)

Load-bearing decisions get durable records in `.project/adr/` so future agents don't re-derive the wrong thing or relitigate settled questions:

- `concept_design` reads the ADR index (prior art) and flags **candidates**;
- accepted decisions are filed when the concept or design is accepted;
- `close` files decisions that **emerged during implementation**, before their context is archived;
- later designs cite or explicitly supersede entries — never silently contradict them.

### Where agents learn what the product is for (the promise ledger)

Agents reliably learn what work is *active*; the promise ledger tells them what the product
*promises*. Major implemented promises — use cases, public surfaces, cross-cutting contracts a
cold agent could miss or undo — get sparse entries in `.project/product/` (convention and
density bar: its README). Every session skims the generated `INDEX.md` at start and opens only
relevant entries; `close` scans for new promises and files them via `product.sh`; entries are
orientation with cited authority, not proof — and nothing gates on the ledger.

### When to make sure the agent is keeping you in the loop

You cannot steer what you can't parse. Two mode commands govern the agent for the rest of the session:

- **`/_my_slop`** — the agent's writing has become dense, jargon-heavy, or hard to follow: reset it. Plain language, one idea per sentence, lead with the point.
- **`/_my_ponytail`** — the agent's *code* is drifting toward over-engineering: force lazy-senior-dev mode, where the best code is the code never written.

### Using reviews to manage consistency across complexity

The review commands share one design: a **fresh session** that assumes the artifact is wrong, attacks it, and records findings in a review doc — never editing the artifact. You resolve the findings; the authoring session incorporates them. The fresh session is the point: it defeats the author agreeing with itself.

- **`/_my_concept_design_review`** — challenges the architecture before it becomes the shape of an epic, including a mandatory ponytail-role subagent whose deletion-first challenge must be answered.
- **`/_my_spec_review`** — stress-tests whether the spec captures what you actually said and whether it will produce good downstream work.
- **`/_my_design_review`** — attacks the abstractions, the hidden bets, and the "is this the right work at all" question before implementation.
- **`/_my_audit`** — the same adversary pointed at finished code.
- **The product-lens** runs inside `epic_plan`, `spec`, `design_review`, and `audit` automatically: an independent subagent re-derives the product's point from durable sources and can block work that contradicts it — a second line of defense that doesn't inherit the artifact chain's framing.

Reviews are for managing risk, not ceremony. A small clear item can go spec → design → implement with no reviews at all; a high-impact architectural change deserves every gate.

---

## The model in summary

Four jobs, and which commands do them:

- **Making sure you understand the problem**
  - at the abstract level: `concept`, `product_design`
  - understanding the constraints: `research`, `spike`, `learning_test`
  - at the architectural level: `concept_design`, ADRs
  - at the unit-of-work level: `spec`
- **Breaking down and planning work**: `epic_plan` (across items), `plan` (within an item)
- **Being honest about success criteria**: `concept`, `product_design`, and `concept_design` state them; `spec` and `design` carry them forward graded by who decided; `audit` verifies them against the code.
- **Using reviews to manage consistency and good design across complexity**: `concept_design_review`, `spec_review`, `design_review`, `audit` — plus `ponytail` and the product-lens.

Adapt the set to the problem. The commands are quality tools; the questions decide which ones earn their keep.

---

## Between sessions

The artifacts exist because sessions die. A few commands manage the boundary:

- **`/_my_wrap_up`** — run at the end of every session. Updates `.project/CURRENT_WORK.md` and auto-memory; the next session boots by reading them (the `context-loading` rule points it there). Thirty seconds now saves ten minutes of archaeology tomorrow.
- **`/_my_handoff`** — mid-task transfer: writes a brief so a *fresh* agent can continue right now.
- **`/_my_status`** — orientation at session start: what's active, what's stale, what's next.
- **`/_my_project_find`** — quick lookups of project state.

For running the flows autonomously, **`/_my_orchestrate`** drives the stages itself — one headless subagent per stage, a single alignment checkpoint at launch, a commit trail you audit afterward.

---

## Where everything lives

- **Stage mechanics:** each command's own doc in `claude-pack/commands/`; `/_my_pipeline` is the canonical in-session stage map.
- **Command catalog:** the repo README's Command Reference.
- **`.project/` layout and epic methodology:** `.project/README.md` and `.project/EPIC_GUIDE.md`.
