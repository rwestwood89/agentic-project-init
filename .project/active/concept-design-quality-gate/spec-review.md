# Spec Review: Concept-Design Architectural Quality Gate

**Spec:** `.project/active/concept-design-quality-gate/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/concept-design-quality-gate/spec-review.md`
**Date:** 2026-08-07

---

## Reality Check

**Sound.** The spec is about the right work item and its Problem section is accurate. The gap
is real and I verified it: the product-lens now runs at `epic_plan`, `spec`, `design_review`,
and `audit` (product-lens spec §1; ADR 0005), but **not** at `concept_design` — the one stage
that makes the largest architectural calls. The pipeline shape confirms there is no review
between `concept_design` and `epic_plan` (`claude-pack/rules/pipeline.md`, shape line). So the
stage that sets boundaries and invariant ownership is only self-reviewed before its shape
becomes inherited context. Closing that is a defensible, correctly-scoped item. Requirements
are directionally right and design would not be badly misled. Proceeding to the full audit.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim (favorable):** The four `[NEED]` requirements trace cleanly to the
owner's fresh ask (all dated 2026-08-07), and nothing is invented. The `[INHERITED]` items all
cite sources, and I checked the load-bearing one: the ADR 0002-amended / 0005-active claim
(spec lines 96–102) is accurate — 0002 is `status: amended`, 0005 is `status: active` and
supersedes 0004. The product-lens ledger shows this was caught (spec-F1) and fixed. Provenance
structure is clean; no item is marked settled/do-not-relitigate that shouldn't be.

**L1-2 · Question to the user:** The Problem section tags the seven-step diagnosis as
`[REFERENT] Owner-designated agent diagnosis, quoted verbatim` (spec line 26), and NEED #5
makes that quote the **acceptance referent** the whole feature is validated against. Two things
worth confirming. First, the content is *agent*-authored but *owner*-designated as the bar —
that is legitimate, and the spec is honest about it. Second, "quoted verbatim" has no durable
source I can locate — the quote appears to live only here. That is not fatal (the spec is
itself a durable artifact), but since the fixture and review behavior will all be built to
match this referent, **is this spec now the canonical home of the referent text, or does it
quote something upstream I should be able to check it against?** If it is the canonical home,
consider dropping "quoted verbatim" (there is nothing to be verbatim *to*) and just owning it
as the referent.

### Lens 2 — Problem & Approach

**L2-1 · If-then tradeoff (headline):** The central move — NEED #3, a new
`my-concept-design-review` stage — runs straight at a warning in both upstream artifacts. The
concept says plainly: *"Not another review stage… Adding a ninth reviewer adds another
inheritor"* (`anchor-on-the-point.md`, "What this is deliberately not"). The research rejects
*"Add another review stage"* as the primary fix, because *"another reviewer reading the same
narrowed artifacts inherits the same oracle"*
(`20260803-210317_pipeline-product-truth-control-review.md`).

The spec knows this and threads the needle: the `[INHERITED]` requirement (lines 104–108)
forbids claiming success from stage presence and demands independent problem derivation plus a
behavioral fixture. That is a real reconciliation. The bet is: *this* review is different
because it is oracle-first, spawns a mandatory ponytail, and is validated against a planted
failure — so it does not inherit the concept's framing the way a generic reviewer would.

**This** is right **if** you read "another review stage" as the concept did — a redundant
*item-level* reviewer re-reading narrowed artifacts. The new stage is the *first* review of a
shaping stage that currently has none, and it is required to derive from SOURCES, not inherit.
**It is the wrong shape if** the cheaper path gets you the same thing: adding the product-lens
+ loud-judgment pattern *into* `concept_design`'s own review loop, exactly as was done for
`design_review` (`_my_design_review.md:42–53`), instead of standing up a whole new command,
skill, Codex surface, and pipeline-shape entry. The concept's moves 2 and 3 were "lens +
judgment *in the existing stages*," not new stages. Which is it — a genuinely independent fresh
session is worth a new stage, or is this coverage the already-shipped product-lens sites can
absorb? This is the one bet I most want you to bless explicitly.

**L2-2 · Question to the user:** Related but narrower: the very next stage, `epic_plan`,
already runs the product-lens (ADR 0005). What does a `concept_design` review catch that
`epic_plan`'s lens does not? The defensible answer is *the architecture-shaping failure* — the
seven-step "add compensating mechanism around a semantic defect" pattern manifests at
concept-design time, before any per-item spec exists, and epic_plan may already have inherited
the enlarged system as fixed. If that is the argument, it holds. Worth stating it in one line so
design knows the marginal value it is buying and does not rebuild what `epic_plan` covers.

### Lens 3 — Pipeline Risk

**L3-1 · Question to the user:** The spec's own posture is "conservative about the solution —
capture the outcome, leave the mechanism to design." NEED #4 + SC6 (lines 66–68, 84–85) break
that posture on purpose: they mandate a **specific mechanism** — spawn a `my-ponytail`
subagent — on *every* concept-design review, and forbid reducing it to a checklist. The outcome
underneath is well-stated as an `[INFERRED]` item (lines 124–127): the review must challenge
whether the work needs to exist, whether machinery can be removed, whether the fix belongs
upstream. That is the *outcome*. "Spawn a ponytail subagent" is *one mechanism* to reach it.

You own this — it is an owner-stated `[NEED]`, not an agent invention, so it is not a
faithfulness fault. But it is worth a deliberate call: **do you want to hard-freeze the
mechanism (a ponytail subagent, always), or freeze the challenge-outcome and name ponytail as
the expected vehicle?** The concept warns that mandatory ceremony is itself the disease
("slot-bloat is the reward signal that beats the point"). A mechanism mandated on every run is
the shape most likely to decay into the checkbox the concept indicts. Freezing the outcome and
letting design choose how to guarantee it keeps the spec conservative; freezing the mechanism is
fine if you specifically want ponytail and no substitute.

**L3-2 · Direct claim:** There is a latent contradiction the design will inherit unless you
resolve the framing now. NEED #4 / SC6 require a ponytail **subagent** that "presents and
dispositions its challenge" — i.e. something that *returns a reviewable result*. But
`_my_ponytail.md` is defined as a **session mode**: *"sets a mode, not a pipeline stage,"*
output is *"a mode directive… not a document"* (lines 5, 13–15). A mode that governs how you
write code does not, as written, produce a challenge artifact a reviewer dispositions. Open
Question 3 correctly defers *how* to instantiate it — but the deferral hides a fork the design
must be told to pick: does "ponytail subagent" mean (a) run ponytail's ladder/rules as a
fresh subagent's instruction set that *returns findings*, or (b) something that modifies what
`_my_ponytail.md` is? SC6's "presents and dispositions its challenge" implies (a). Making that
explicit in the spec (or in the Open Question) stops design from guessing and possibly editing
the ponytail command by accident.

**L3-3 · If-then tradeoff (headline):** SC7's fixture criterion (lines 69–71) — "An adversarial
fixture matching the referent is rejected" — is written like a binary, testable checkbox. But
what it actually asserts is that a **prompt-driven agent review** *chooses* to reject an
adversarial concept, and that is inherently non-deterministic. The concept names this exact
crux (Q1): the finding can be made incorruptible, but *the response is not mandatory* — the
main agent can still ignore the lens. The research's own recommendation 3 frames the fixture as
"expected result: a surfaced conflict that blocks," not as a deterministic unit test.

The risk: if design/plan read SC7 as "the fixture passes once → proven," they will build a
one-shot behavioral check and treat a single green transcript as assurance — which is
*precisely* the "a green test became the oracle" failure this whole feature exists to kill. The
spec should say what counts as passing given model non-determinism: **a single canonical
transcript? N runs with an M/N rejection bar? human-judged?** Without that, the feature's
headline validation criterion is itself the trap it is meant to catch. This needs a decision
before design, not after.

**L3-4 · Direct claim (favorable):** The ADR-flagging requirement (NEED #2 / SC3) is well
guarded. `concept_design` already files ADRs at acceptance (ADR 0002's write point;
`_my_concept_design.md:444–451`), and NEED #2 adds *earlier* flagging of candidates so they can
be pressure-tested before filing. The spec surfaces the touch-point risk rather than silently
extending the map — the `[INHERITED]` item (lines 96–102) explicitly requires the design to
amend or supersede the live decision if the review creates a new ADR interaction. That is the
correct capture-fidelity move. No action needed; noted as a thing done right.

**L3-5 · Direct claim (favorable):** The boundary with `design_review` is clean. The
`[INFERRED]` item (lines 128–130) and the Non-Goal both scope the new review to cross-item
system shape, not per-item interfaces. That matches how `design_review` is actually defined
(item-level, spec+design+code inputs). No overlap risk.

### Lens 4 — Hygiene

**L4-1 · Rewrite request (minor, optional):** A few `[INFERRED]` items restate the Problem
rather than add a requirement — e.g. the byte-identity/preservation-evidence item (lines
118–120) largely re-states the referent quote, which NEED #5 already designates as the
acceptance bar. Not damaging, but it blurs "one home per idea." Consider whether each INFERRED
item is a *requirement design must satisfy* or *Problem restatement*; drop or tighten the ones
that are the latter. Low priority.

### Lens 5 — Reader Comprehension

No blocking finding. The spec leads with the point, the Problem section is readable cold, and
the tags are honest. The only drag is the length of the Known Requirements block (six INFERRED
items, several paragraph-long), which is the L4-1 point seen from the reader's side — worth a
trim but not a comprehension failure.

---

## Engagement Summary

**Overall take:** The spec is pointed at a real, correctly-scoped gap and captures the owner's
ask faithfully — I'd not send it back for Rework. But it makes one bet that runs against both
upstream artifacts, freezes a mechanism where its own posture says capture the outcome, and
states its headline validation criterion as if it were deterministic when it is not. Those are
Revise-level: fix them and the contract is solid.

**Here's what I need you to weigh in on:**

1. **[L2-1]** Bless the bet, or take the cheaper path. Both the concept and the research say
   "not another review stage." You are adding one. The spec justifies it (fresh session,
   oracle-first, fixture-validated) — but the alternative is adding the product-lens +
   loud-judgment pattern *into* `concept_design`'s own loop, as was done for `design_review`,
   with no new command/skill/surface. New stage or in-stage lens?

2. **[L3-3]** Decide what "the adversarial fixture is rejected" means when the reviewer is a
   non-deterministic agent. Single canonical transcript, N-runs-with-a-bar, or human-judged? If
   this stays a one-shot checkbox, the feature's own success criterion becomes the "green test =
   oracle" trap it exists to prevent.

3. **[L3-1]** Confirm you want to hard-freeze the mechanism (a ponytail subagent, every time)
   versus freezing the challenge-outcome and naming ponytail as the expected vehicle. Your call
   either way — but a mechanism mandated on every run is the shape the concept warns decays into
   ceremony.

4. **[L3-2]** Resolve the ponytail fork before design: `_my_ponytail.md` is a *mode*, not a
   subagent that returns a challenge. SC6 implies you want its rules run as a result-returning
   subagent. Say so, so design doesn't guess or accidentally rewrite the ponytail command.

5. **[L1-2]** Confirm this spec is the canonical home of the referent text. If it is, "quoted
   verbatim" has nothing to be verbatim to — own it as the referent instead.

---

## Resolutions

- **[L2-1]** Option A — a new, separate `concept-design-review` stage, not an in-stage check.
  Rationale (owner): this gate reviews **software architecture quality** (good design, right
  abstractions, not piling machinery around a defect), which is a **different axis** from the
  product-lens (which checks fidelity to product purpose). A separate independent review is
  wanted precisely because it is not the same check as the already-shipped product-lens.
- **[L2-2]** Dissolved by the L2-1 clarification. The finding assumed this gate overlapped the
  product-lens's coverage; it does not — different axis (architecture vs. product intent). No
  action.
- **[L3-3]** Owner rejects the adversarial-fixture proof requirement. Drop it. Spec agent:
  remove the fixture success criterion (spec lines 69–71), Open Question 6 (the
  adversarial/clean-control fixtures question), and the "behavioral evidence that it rejects
  the planted failure pattern" clause of the `[INHERITED]` research item (lines 104–108) — keep
  the rest of that item (independent problem derivation still stands). Recorded tradeoff: the
  gate's value now rests on the review being independent and the ponytail challenge being
  real, not on a behavioral test proving it rejects a planted defect. This overrides the
  inherited research guidance ("must not claim success from stage presence alone"); owner's
  call.
- **[L3-1]** The requirement is **the challenge** (is this over-built, can machinery be
  deleted, does it need to exist, is it the smallest architecture that owns the invariant). The
  mechanism is mandated: a subagent in the **ponytail role** must be spawned to be extremely
  critical of the concept design, and its output is used as **input to the generated
  concept-design-review**. So: outcome-as-requirement, delivered by a mandatory ponytail-role
  subagent whose critique feeds the review doc.
- **[L3-2]** Resolved by L3-1. Reading: option (a) — run ponytail's role/attitude as a fresh
  critical subagent that **returns a written challenge**; that challenge is an input the review
  consumes. Not a change to what the ponytail *mode* is. Design owns wiring the role into a
  result-returning subagent.
- **[L1-2]** Dismissed by owner. No action; drop the finding.

---

**Verdict:** Revise
**Next Steps:** Once resolutions are recorded here, re-run `/_my_spec` (or return to the
spec-agent session) and point it at this review to incorporate. The reviewer does not edit the
spec. The underlying work item is sound — these are targeted edits, not a re-scope.
