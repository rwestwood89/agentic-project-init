# Spec: Discount Code at Checkout

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Complexity:** MEDIUM
**Branch:** N/A (no git repository initialized in this sandbox)

---

## Problem

Checkout has no way to accept a promotional discount code. The business can create and distribute codes through other channels (email campaigns, partner offers, support), but a customer holding one has no way to redeem it at checkout to get money off. Without redemption, those codes are worthless no matter how they were generated.

## Success Criteria

- [ ] A logged-in customer who enters a valid, active code at checkout sees the order total reduced by the correct amount — a fixed dollar amount or a percentage, per the code's configuration — before payment.
- [ ] A customer who enters a code that is expired, has hit its total redemption cap, has already been redeemed by that customer, or is applied to an order below its minimum value sees a specific reason for the rejection, and the order total is unaffected.
- [ ] Applying a second code to an order that already has one applied does not combine the two discounts (only one code is ever active on an order).
- [ ] Once a customer redeems a one-per-customer code, a later attempt by that same customer to redeem it again is rejected — including back-to-back or concurrent attempts.
- [ ] A code's total redemption count never exceeds its cap, even when multiple customers try to redeem it at the same moment.

## Known Requirements

- **[HARD]** The feature validates a customer-supplied code at checkout and, if valid, reduces the order total before payment. Creating, editing, deactivating, or importing codes is out of scope — codes are provisioned by another system.
- **[HARD]** Redemption requires an identified customer account (logged in). Guest checkout does not support code redemption.
- **[HARD]** Only one discount code may be applied to an order; codes cannot be combined.
- **[NEED]** A code's discount can be expressed as either a fixed amount off the order or a percentage off the order.
- **[NEED]** A code stops being redeemable after its expiration date.
- **[NEED]** A code stops being redeemable once it reaches its maximum total redemption count.
- **[NEED]** A code cannot be redeemed more than once by the same customer.
- **[NEED]** A code can require a minimum order value to qualify.
- **[NEED]** A rejected code gives the customer a specific reason (expired, redemption limit reached, already used, order below minimum) rather than a generic failure.
- **[INFERRED]** Percentage discounts are calculated against the pre-tax merchandise subtotal, excluding tax and shipping — the standard retail default; not stated explicitly and open to correction at design.
- **[INFERRED]** Code matching is case-insensitive (e.g., "SAVE10" and "save10" behave identically) — otherwise a valid code could appear to fail purely from a casing mismatch.
- **[INFERRED]** Redemption-cap and one-per-customer enforcement must be correct under concurrent attempts (two simultaneous checkouts can't both succeed when only one redemption slot remains) — implied by having caps and per-customer limits at all; without this, the limits wouldn't reliably hold.

## Non-Goals

- Creating, editing, deactivating, or bulk-importing discount codes (admin/management tooling) — codes are provisioned by another system.
- Guest (non-logged-in) checkout redemption.
- Combining multiple discount codes on a single order.
- Free or discounted shipping as a discount type.
- Reporting or analytics dashboards on code usage or redemption trends — not requested.
- Multi-currency support — no stated need; single currency assumed.

## Open Questions / Deferred to design

- Whether a code can be restricted to specific products or categories, and if so how — explicitly deferred; not decided as in- or out-of-scope for this iteration.
- Whether customer-identity/account infrastructure for enforcing the logged-in, one-per-customer requirement already exists in the checkout system, or needs to be introduced as part of this work.
- Whether support staff need any read-only visibility into a code's redemption status (e.g., to answer "why didn't my code work"), even though creating/managing codes is out of scope.
- Exact rejection messaging/copy for each failure reason.
- Real-time (as-you-type) vs. on-submit validation of the code field.

---

## Related Artifacts

- **Design:** `.project/active/discount-code/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
