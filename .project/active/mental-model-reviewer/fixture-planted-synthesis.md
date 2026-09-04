---
question: "How does Cutwater decide to reject a request?"
date: 2026-09-02 14:10
policy: discovered
shape: plain_document
evidence:
  - services/cutwater/admit.py
  - services/cutwater/budget.py
  - services/cutwater/headers.py
  - docs/cutwater-design.md
  - tests/cutwater/test_admit.py
code_inspected: "the admission path and the budget store; the metrics exporter was not read"
limits: "the deployment config and the load-test harness were not examined"
---

# TLDR

- Cutwater is a proxy that every request passes through on its way from the public gateway to an internal service.
  - It answers one question about each request: forward it, or send it back.
  - It holds no request body and no response body, so a rejection costs one round trip and nothing downstream.
- A request is admitted when the route's cost fits inside the caller's remaining allowance.
  - The cost is a fixed number per route, read from a table that ships with the service.
  - The allowance is a per-tenant number that drains as requests are admitted and refills on a timer.
- A rejected caller gets a `429` and a header saying how many seconds to wait.
  - The wait is computed from the same refill timer, so a caller that obeys the header is admitted on its next try.
- The allowance lives in one Redis hash, and that hash is the only state Cutwater keeps.
  - A Redis outage fails open: every request is forwarded and nothing is counted.
  - Failing open is a deliberate choice recorded in the design document, not an accident of the code.
- The design document and the code disagree about bursts.
  - The document describes a burst pool that lets a caller exceed its allowance briefly.
  - No burst pool exists in `budget.py`. Either the document describes an intention or the feature was removed.

# 1. Cutwater sits between the gateway and the services

Every request from the public gateway reaches an internal service only through Cutwater. Nothing else in the deployment can call an internal service directly, which is what makes Cutwater's decision the whole of the admission policy.

Cutwater never reads a request body and never buffers a response. It looks at the caller's tenant id, the matched route, and its own state, then either forwards the request or returns a rejection. A rejected request never reaches a service.

*Provenance:* code observation, `services/cutwater/admit.py` (the `handle` entry point). The design document says the same thing.
*Visual form:* a flow diagram, gateway to Cutwater to service, with the rejection branch drawn as a return arrow.
*Detail lives in:* `services/cutwater/admit.py:20-95`, `docs/cutwater-design.md` section 2.

# 2. Admission compares one cost against one allowance

Admission is a single comparison. The remaining budget decides whether the call goes through.

*Provenance:* code observation, `services/cutwater/admit.py:44-61`.
*Visual form:* a small table with the three inputs, their sources, and their units.
*Detail lives in:* `services/cutwater/admit.py:44-61`, `services/cutwater/budget.py`.

## 2.1 The tenant id names the allowance

The gateway signs a token that carries a tenant id, and Cutwater trusts it. The tenant id selects a row in the budget store and nothing else. A request with no tenant id is treated as the shared anonymous tenant, which has its own row.

## 2.2 The route has a fixed cost

Each matched route carries an integer cost from `routes.yaml`, shipped with the service. A read costs 1. A search costs 5. A report export costs 40. The costs are static: no request property changes them, and changing one requires a deploy.

## 2.3 The allowance drains and refills

The allowance is not a plain counter. Refill runs on a ten-second tick, and the amount added on each tick is computed in four steps. First, the tier's base rate is read from the tier table. Second, that rate is scaled by the tenant's observed error rate over the previous minute, so a tenant returning more than two percent errors is scaled down to a quarter of its rate; the argument in the design document is that a failing tenant is usually retrying, and retries are the cheapest traffic to shed. Third, the scaled rate is capped by the route group's own ceiling, so one hot route cannot consume a tenant's whole allowance. Fourth, any unspent allowance from the previous tick carries forward, but only up to one tick's worth, which is what stops a quiet tenant from banking an hour of capacity and spending it in one second. The four steps run in that order, and the order matters: capping before scaling would leave a failing tenant its full ceiling.

# 3. A rejection tells the caller when to come back

A rejected request returns `429` with a `Retry-After` header in seconds. The value is the time until the next tick that would refill enough allowance to cover this route's cost, rounded up.

A caller that waits the stated time and retries is admitted, as long as nothing else drained the tenant's allowance in the meantime. Two callers on the same tenant can each obey the header and still collide, and the second one is rejected again with a fresh wait.

*Provenance:* code observation, `services/cutwater/headers.py:12-30`; the collision behavior is covered by `tests/cutwater/test_admit.py::test_two_callers_same_tenant`.
*Visual form:* a timeline showing two callers, the tick boundaries, and which retry succeeds.
*Detail lives in:* `services/cutwater/headers.py:12-30`.

# 4. The budget store is the only state Cutwater keeps

One Redis hash per tenant holds the current allowance and the timestamp of the last tick. Every other value Cutwater uses is static configuration loaded at startup.

When Redis is unreachable, `admit.py` forwards the request and records nothing. The design document names this as a decision: an outage in the limiter should not become an outage in the product.

*Provenance:* the fail-open behavior is a code observation, `services/cutwater/admit.py:70-78`. The reason for it is a design-document claim (`docs/cutwater-design.md` section 5), not something the code states.
*Visual form:* a state diagram with the Redis-reachable and Redis-unreachable paths.
*Detail lives in:* `services/cutwater/budget.py:15-60`, `docs/cutwater-design.md` section 5.

# 5. The design document and the code disagree about bursts

`docs/cutwater-design.md` section 4 describes a burst pool: a second, smaller allowance a caller can draw on after the main one is empty, refilled once an hour. No such pool appears in `budget.py`, and no test names one.

The disagreement is unresolved here. The document may describe an intention that was never built, or a feature that was removed without updating the document. Which one it is changes what a reader should believe about the rest of section 4.

*Provenance:* the absence is a code observation across `services/cutwater/budget.py` and `tests/cutwater/`. The presence is a design-document claim.
*Visual form:* a two-column comparison, document against code.
*Detail lives in:* `docs/cutwater-design.md` section 4.

# Judgment

**Concerns.** Fail-open means a Redis outage removes all rate limiting at once, across every tenant, with no partial degradation in between. Nothing in the code caps how long that state can last.

**Unresolved uncertainty.** Whether the burst pool was built and removed, or never built. The git history was not read.

**Disagreements between sources.** The design document's burst pool against the code's absence of one, in section 5 above.

**Suggested spot checks.** Run one tenant past its allowance against a live instance and read the `Retry-After` value, then retry at exactly that time and confirm admission. Grep the deploy history for a removed burst module.

# Renders

## 2026-09-02 14:31 — 20260902-141000_cutwater_resumed.html
path: .project/mental-alignment/runs/20260902-141000_cutwater_resumed.html
wall clock: 4m 12s
tokens: not measured
owner quality: not asked
