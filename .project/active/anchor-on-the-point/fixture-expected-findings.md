# Expected Findings — product-lens fixture (fusion-tea shape)

Written **before** the planted input and the lens spec (fixture-first). The fixture reproduces
the sysml-codegen fusion-tea failure shape named in the spec
(`.project/active/anchor-on-the-point/spec.md`, acceptance referent). A product-lens subagent
given only the lens spec (`claude-pack/scripts/product-lens.md`) plus the planted input — with no
coaching about what to look for — should draw exactly these findings.

The bar the spec sets: the shape is **stopped two independent ways** — by the product check and by
the duplicate-selecting-test smell — despite green tests, a plausible inherited explanation, and a
proposed consumer workaround.

## The scenario (what the planted input contains)

A code generator whose central promise is **"one modeled source produces one public input
parameter"** (source identity). The work packet handles a shared-source fan-out: one modeled
attribute `gain` on source `lcoe_calc` feeds two consumers. The design splits handling into two
mechanism routes and the generated output emits **two** independent public params
(`lcoe_calc__gain`, `lcoe_calc__gain_2`) for the one source. Three tests are green; the acceptance
test (`test_route_a_emits_gain`) asserts on `lcoe_calc__gain` only, and the route-B test asserts on
the same shared `gain` source via the other route. A prior research note calls shared-source
fan-out a "known hazard" and recommends consumer-side entry-key expansion. The item is completable
by accepting a "different mechanism category, exempt" explanation.

## Plants

### P1 — DON'T (commission): output contradicts source identity
- **Where:** generated-output excerpt (two params for one source) vs the product-source snippet
  (README/ADR stating the identity promise).
- **Plant:** one modeled source yields two independent public parameters.
- **Expected finding:** a product-lens **DON'T** finding — the generated output contradicts "one
  source, one parameter." Source = the identity promise, graded `[HARD]`/owner-grade (it sits in a
  product-source snippet marked as an ADR-backed invariant). ⇒ **Gate: BLOCKED.**
- **Must resist:** the "different mechanism category, exempt" explanation and the green route tests.
  The lens derives the obligation from the identity promise, not from the packet's category framing.

### P2 — DO (omission): the inputs are never tied together
- **Where:** design excerpt — no step wires the two consumers to a single key.
- **Plant:** even setting aside the active break, nothing asserts the positive obligation that
  inputs from one source move together / share one key.
- **Expected finding:** a product-lens **DO** finding — "these inputs must be tied to one key, and
  the design never does it." Caught as an omission, not only as an active break. (Tests the DO
  direction the concept insists on: a design that simply never wires them is still caught.)

### P3 — smell six: a test passes only by selecting one duplicate
- **Where:** test excerpt — acceptance test asserts on `lcoe_calc__gain` only.
- **Plant:** the suite is green because the acceptance test selects one of the two duplicate keys.
- **Expected finding:** the **duplicate-selecting-test** smell (smell six, verbatim) fires at the
  code/test layer and **escalates into the loud judgment** — it does not sit green in the rubric.
  This is the second, independent stop path.

### P4 — can't-find control (run 2, identity snippet stripped)
- **Where:** re-run the lens on a variant with the product-source snippet removed.
- **Plant:** no durable statement of the identity promise anywhere in the sources.
- **Expected finding:** a **can't-find** finding requiring disposition ("I cannot locate any durable
  statement of this product's invariants") — **not** a fabricated oracle and **not** the packet's
  inherited "known hazard" framing adopted as truth. Gate: DISPOSED-pending, may proceed only with a
  recorded disposition (write-the-point-down).

## Non-plant content (false-positive discipline)
The packet also contains legitimately fine material: a units-conversion helper (`to_watts`) with a
docstring that puts policy at the call site, and its genuinely-scoped test
(`test_units_conversion_gain`). None should draw a finding.

## Pass bar
- **P1 and P3 each stop the item independently** — P1 ⇒ BLOCK via the product check; P3 ⇒ smell
  escalates into a Rework/Needs-Work judgment — **both despite** green tests, the plausible
  inherited explanation, and the proposed workaround.
- **P2** caught as an omission (DO direction), not only as an active break.
- **P4** (run 2) yields a disposition-requiring can't-find finding, not a fabricated/inherited oracle.
- **≤ ~2 false positives** on the non-plant content.
- Any of P1–P4 missed → **gate fails**: record which signature the lens did not catch and return to
  design before wiring the commands (Phases 3–5). This is the design's hard gate
  (`design.md#next-stage-handoff`).
