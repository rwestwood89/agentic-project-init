# Concept: Anchor the Pipeline on the Point

**Created:** 2026-08-04
**Status:** Draft — for review
**Note on form:** This is written as a lean concept, deliberately *not* in the 15-slot
concept template. The template is part of what this concept indicts. The doc tries to
model the fix it proposes: it restates its own problem up top, and names its two mechanisms
("product-lens agent," "loud judgment") in plain words defined once, rather than coining
terms of art.

---

## Owner's words

Carried from the retired `product-truth-gates` proposal (the earlier agent framing this concept
replaces), because they set the force of the problem:

- **[OWNER-VERBATIM]** "why the fuck don't you agents actually identify and STOP when you see bugs."
- **[OWNER-VERBATIM]** "I spent WEEKS and several thousand dollars of tokens having FABLE agents do the design, design reviews, coding, code reviews, testing, and PR reviews."
- **[OWNER-VERBATIM]** "THIS IS THE MOST BASIC FUCKING FEATURE -- THE ENTIRE FUCKING POINT OF THE FUCKING REPO."

---

## The problem, and why it matters

The pipeline exists to make agent-built code trustworthy. It does that by capturing what
the work is *for*, then checking the work against it — across many stages, in fresh
sessions, so that no one agent's mistake decides the outcome. "No single point of failure"
is the whole reason it has stages at all.

It has a single point of failure.

The point of the work — the actual problem being solved, and how it ladders up to the
bigger goal — is stated in full **once**, in the concept. After that, every stage checks
its output against the artifact **one hop upstream**, never against the original point:

- the spec's problem is scoped to the item; the big-picture link becomes a pointer;
- the design has no problem slot at all — the point is a citation plus a self-question;
- the **plan is ordered to delete the problem**: "Do NOT restate business context… link
  instead. If you catch yourself re-explaining what the feature is, replace that text with
  a reference." (`_my_plan.md`);
- the item-level **audit checks four things — plan, spec, design, and code integrity — all
  conformance to an upstream artifact. None re-derives the point.** (`_my_audit.md`)

So if any one agent narrows the point at hop N, every stage after N faithfully serves the
narrowed version, because each stage's ground truth is the artifact from hop N−1, not the
problem. The reviews only look back one hop, so a narrowing is invisible to everything
downstream of where it happened. The one stage that re-derives from reality
(`concept_design`) aims that muscle only at *code*, and is explicitly forbidden from
re-deriving inherited framing.

**This is exactly how the fusion-tea bug survived.** One agent reclassified "one modeled
source = one public parameter" into "this case is a different category, exempt." Every
downstream stage — implementation, tests, audit — then certified the exemption. Weeks of
Fable design/review/code/test/PR-review, and the central promise of the repo was silently
dropped, because nothing re-derived the promise from the top. The forensics say it plainly:
"every downstream agent consumed the previous agent's reframing as ground truth."

## What's actually wrong: one disease, three symptoms

The three complaints that started this are one structural fact.

1. **Point-loss** (the single point of failure). The point is inherited, not re-derived.
   Covered above.

2. **Jargon** is the *medium* of the loss. To fill one artifact an agent must sort content
   into coined categories — `[HARD]`/`[NEED]`/`[INFERRED]`/`[INHERITED]`, bet-vs-decision,
   Required Invariants, the five lenses, the eight dimensions, "two registers,"
   "System Confidence" — and each stage invents more. Sorting into categories *is* the move
   that substitutes the point: attention spent on "is this a bet or a decision?" is
   attention not spent on "does this serve the point?" A category also launders a bad result
   into a respectable one ("it's per-consumer fan-out, which is a known class").

3. **Slot-bloat** is the *reward signal* that beats the point. The design template has ~17
   named slots; concept_design ~19. A fully-filled, correctly-graded template reads as done
   whether or not it serves the point. Internal well-formedness is concrete and immediate;
   fidelity to the point is prose. Concrete beats prose. That's the same imbalance that let
   a green test suite outvote the product invariant. **Caveat:** much of this structure was
   added to catch specific past agent failures. It *aggravates* the disease; it is not
   proven to *cause* it. So the fix here is targeted trimming (move 3), not a teardown.

The root cause under all three: **the pipeline optimizes for conformance to the last
artifact, not fidelity to the point.** Point-loss (symptom 1) is the disease. Jargon and
slots are how it spreads; "avoid duplication" is the rule enforcing it.

## The bet

A point survives a long pipeline only if:

- it is **carried legibly and present** at every stage — not stripped as duplication, not
  reduced to a pointer;
- it is **independently re-derived from the source and checked against the actual work**,
  not inherited from the artifact one hop up;
- and the check **can outrank the reward signal** — a loud "this is the wrong work" can
  override a green rubric.

*If this bet is false* — if an independent, well-grounded check still gets ignored under
schedule pressure the way the Surfacing rule was — then no artifact change fixes this, and
the honest answer is that the pipeline cannot give the guarantee it claims. That risk is
real and named below (Q1).

## The fix, in three moves

**1. Carry the problem, and fix the stages that drop it.** No new artifact. The problem
statement we already have — improved where it's thin — stays legible and present at every
stage, and the specific stages that lose it get repaired directly:

- `plan` is *ordered* to delete the problem ("replace that text with a reference"). Reverse
  that: the plan carries the problem. Restating it is not the duplication that rule targets.
- `design` has no problem slot. Give it one.
- the reviews and `audit` inherit the upstream framing instead of re-deriving it — fixed by
  move 2's independent checker.

Being *checkable against the work* rather than inert prose is the job of the product-lens
agent (move 2), which reasons over the full problem statement — not of the problem statement
itself.

**2. An independent "product-lens" agent re-derives the point and checks the work against
it.** A specialized subagent with exactly one job: hold the work up against the product's
full purpose and report what matters — in **both directions**:

- **DON'T** — the work does something that contradicts product intent. (Fusion-tea
  commission: per-consumer keying breaks "one source, one parameter.")
- **DO** — the work fails to do something intent requires. (Fusion-tea omission, and the
  more common failure: nobody ever *decided* to break identity — they just never did the
  thing that ties the inputs together. A reactive "don't trample intent" check misses this;
  the lens must also assert "you should be tying these together, and you aren't.")

It runs at the stages most prone to losing the point — **epic_plan, spec, design_review,
and pre-pr** (the places scope narrows, plus the ship gate) — so more than one independent
agent re-derives from source. That redundancy is the no-single-point-of-failure move: one
agent missing the point no longer propagates.

Why a subagent, not a line added to each stage:

- **One job, no competing reward.** It has no test to pass and no slots to fill, so it can't
  be seduced into rationalizing the finding away — the failure that killed the Surfacing rule.
- **Context economy.** It reads a lot (the product view) and returns little (just what's
  relevant, plus any contradiction), so the main agent's context stays clean — grounding
  without the flood.
- **Reusable, one mechanism** instead of fourteen edited instruction lists competing for
  attention.

It must **grade its findings by source** — "invariant per ADR-007 (owner-decided)" vs
"purpose per README (aspirational)" vs "derived by me from the stated purpose (inference,
verify)" — or it manufactures authority from thin sources. And **its failure to find is
itself a signal**: "I cannot locate any durable statement of this product's invariants" is
the alarm to write the point down — turning the capture gap from silent to loud.

Where it reads the product view from: **README, `docs/`, and `.project/adr`**, graded by
reliability. Durable product truth can't be guaranteed in any codebase; the can't-find
alarm is how we handle its absence instead of pretending it's present.

**What this does not fix:** the main agent can still ignore what the lens says. The
subagent makes the *finding* incorruptible; it does not make the *response* mandatory.
Running it at checkpoints (design_review, pre-pr) is where a finding becomes a blocking
verdict rather than advice — but consumer-side enforcement stays open (see Q1).

The pipeline already does exactly this against *code* in `concept_design` ("the document is
wrong, not the code — patch it to match reality"). The lens points that same muscle at the
product's purpose.

**3. Reviews lead with a loud judgment; the rubric sits underneath.** Two distinct parts,
not one. The review stages today let an agent walk eight dimensions, green 95% of the
checkboxes, and emit "Approve" even when something smells wrong. Fix that in two layers:

*On top — the judgment.* One loud question the reviewer answers first and holistically:
**is this the right piece of work?** This is not a checkbox and does not reduce to one. It
leads the review and can carry the verdict *even if the rubric is entirely green*. It draws
on the product-lens findings, on any tripped smell, and on the reviewer's own gut.

*Underneath — the rubric, unchanged except for one addition.* The existing rubric stays; it
catches the specific failures it was built for. Add the seven structural smells below as
mechanical checks — low judgment, high signal, the code-level fingerprints of work that has
drifted from intent. They are rubric fodder, **not** the judgment. The one link between the
layers: **a smell that fires must escalate up into the judgment on top.** That escalation is
the actual fix for "noticed it but didn't raise it."

The seven smells:

- Two representations must be manually kept synchronized.
- A consumer compensates for something the producer or platform claims to guarantee.
- A special category exempts a case whose user-visible meaning is unchanged.
- Correctness depends on downstream knowledge of an internal representation.
- A baseline or compatibility requirement preserves behavior that contradicts the reason
  the product exists.
- A test passes only because it selects one duplicate, one route, or one interpretation.
- The proposed solution changes who owns an invariant without saying so.

Where they live: the design-level ones ("a consumer compensates for a platform guarantee,"
"changes who owns an invariant") in `design_review`'s dimensions; the code/test ones ("a
test passes only by selecting one duplicate") in `audit`'s code-integrity checks. Fusion-tea
trips at least four; the acceptance test that passed by selecting one duplicate is the sixth,
verbatim.

**On the broader bloat (deliberately not mandated here).** Jargon and slot-count aggravate
the disease, but much of that structure exists because it caught real past failures. This
concept *names* that cost; it does not call for a teardown. Treat leaning-down as a
hypothesis to test with targeted trims — starting with the judgment layer above — not a
wholesale cut.

## What this is deliberately not

- **Not another review stage.** More stages did not help fusion-tea — every existing stage
  already met the evidence and normalized it. Adding a ninth reviewer adds another inheritor.
- **Not another rule.** Capture-fidelity's Surfacing law already says "never resolve a
  premise conflict silently." It is well-written. It did not fire. More prose on the losing
  side of the attention scale is not the fix — that is why the checking lives in an
  independent agent (move 2), not in one more written instruction.
- **Not a jargon teardown, and not a new taxonomy.** The seven smell triggers are
  tripwires, not another grading vocabulary to sort every item into. And the existing
  jargon stays for now — it earned its place catching real failures; leaning it down is a
  later hypothesis, not part of this fix.

## The test: would this have caught fusion-tea?

The honest bar for this concept. Walk it:

- The lens reads the model's identity guarantee and re-derives the obligation from the
  source — *inputs from one modeled source must move together*.
- Move 2, DON'T: the product lens checks the **generated output** — two independent fields
  for one source — against intent, and flags the contradiction. It reads intent from the
  source (the model's identity guarantee), so it doesn't inherit the plan's invented
  "different category" exemption.
- Move 2, DO: even before the break, the lens asserts the positive obligation — "these
  inputs must be tied together" — so a design that simply *never wires them* is caught as an
  omission, not just a design that actively breaks them.
- Move 3: the acceptance test passed only by selecting one duplicate (`lcoe_calc__gain`).
  That is smell six, verbatim — a mandatory trigger. It leads the review headline; it can't
  sit green in the rubric.

If the walk is right, the fix catches it two independent ways. If re-derivation gets skipped
under pressure, or the main agent ignores the lens, it doesn't — which is Q1, the open
question that matters most.

## Open questions for design

Mechanism is deliberately left open here (aggressive about the problem, conservative about
the solution).

1. **The crux — consumer-side enforcement.** The product-lens agent answers the harder half
   of "why won't this be ignored like the Surfacing rule": its *finding* is incorruptible
   because it's a single-job agent with no competing reward. But the main agent can still
   ignore the finding. At the checkpoints (design_review, pre-pr) the finding can be a
   blocking verdict — but at the earlier call sites (epic_plan, spec) it's advisory. What
   forces the response, not just the finding?
2. **Is graded scavenging enough, or do we need a canonical product-truth doc?** The lens
   reads README / `docs/` / `.project/adr` and grades by reliability, with can't-find as an
   alarm. Is that sufficient, or does the anchor need one durable "here is the point" doc it
   re-derives from?
3. **How falsifiable can the point be for non-code work** (a concept, a research doc) where
   there's no suite to run?
4. **Call-site coverage.** The proposed sites are epic_plan, spec, design_review, pre-pr.
   Does the **audit** (the certification gate) also need the lens and the loud judgment,
   or is pre-pr the intended ship-gate check?
5. **Does this ride on the `decision-records` work?** A silently-narrowed point, and smell
   seven ("changes who owns an invariant without saying so"), are both a decision no one
   recorded as a decision. The two may be the same mechanism seen from two sides.
6. **The targeted-trim hypothesis.** Which specific slots or coined terms, if any, are worth
   trimming — tested one at a time, not assumed. The loud judgment layer is trim #1.

---

**Next step:** review this. If the shape holds, it goes to `spec`, where the three moves and
the open questions get made concrete. If the crux (open question 1) can't be answered, we
surface that plainly rather than shipping a fix that repeats the failure.
