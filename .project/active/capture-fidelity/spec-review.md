# Spec Review: Capture Fidelity

**Spec:** `.project/active/capture-fidelity/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/capture-fidelity/spec-review.md`
**Date:** 2026-07-10

---

## Reality Check

**Sound.** The spec is about the right work item — the pipeline's chat→artifact→artifact conversion loses provenance, payload, and correction intent, and downstream stages treat lossy artifacts as ground truth. The problem is grounded: the exemplar report the owner pointed at (`dynamic-capacity-explainer`) exists, and the "evaluation frame as an unquestioned premise" surfacing case is confirmed by the repair handoff (`/tmp/handoff-20260710-band-study-audit-repair.md:29`, `:75` — the terminal-energy accounting frame "sailed through" the audit). The code-facing claims about the devices in scope check out. Design would not be misled by treating this as the contract. Proceeding to the full audit.

One limit worth stating plainly: this spec was written from a live session, and every `[NEED]` is tagged "(owner, this session)." I can't verify verbatim traceability to that conversation — no downstream agent can, which the spec itself concedes in its last `[INFERRED]` bullet. So this review checks internal soundness, code claims, and the forensic grounding, not whether the owner's words were captured faithfully. That verification is the owner's to do on the owner-tagged items.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim:** The Problem section says `/_my_orchestrate` resolves a mid-run goal-vs-rule collision "silently ... toward compliance with a rule the owner never made," and quotes `_my_orchestrate.md:64` as *"make the most defensible call ... and keep going. Don't stop and wait."* The ellipsis drops the middle of the actual line: "make the most defensible call, **record it loudly**, and keep going" (`_my_orchestrate.md:63`). The current command already tells the agent to record the call loudly, so "resolved silently" overstates today's gap. The real gap is narrower and still valid — orchestrate records the call but doesn't *stop* for it, and doesn't tier owner-reserved decisions differently from execution details. Recommend rewording the problem framing to attack "records-but-never-stops," not "silent," so the motivation doesn't rest on a claim the code contradicts.

**L1-2 · Question to the user:** The second `[INFERRED]` requirement (`spec.md:135`) has audit "state what it did **not** check (scope honesty)." This maps almost one-to-one onto the repair handoff's section "What the existing 'Certify' audits did NOT check" (`handoff:73`) — i.e., it reads as derived from the band-study audit that certified a report whose accounting frame was never questioned. That's exactly the shape the spec's own **Generalization bar** (`spec.md:126`) forbids: a device gaining a check that only makes sense for the traced failure. Is "audit states its own scope gaps" a general law of pipeline capture, or a reaction to this one audit? If it's general, say why in general terms; if it's failure-specific, it should be cut or moved to Open Questions. (See also L3-2 — this item also has no success criterion behind it.)

### Lens 2 — Problem & Approach

**L2-1 · Question to the user:** The orchestrate front-loading requirement (`spec.md:74`, `:121`) assumes an owner is present to answer. The post-Orient checkpoint "resolves meaning-of-work ambiguity" and "questions suspect hard requirements ('do you literally want X, or are you solving for Y?')," and mid-run "owner-reserved decisions stop the run." But orchestrate's whole identity is the opposite: "No user checkpoints — you're handed an objective and run to the end" (`_my_orchestrate.md:9`), and the Non-Goals defer away-from-keyboard notification to a separate feature (`spec.md:152`) — which implies the owner often *isn't* reachable during a run. So: when orchestrate is launched autonomously and no owner is there, what does the front-loading checkpoint actually do — resolve what it can and record the rest, or block? And does "stop the run" mean halt-and-wait-for-a-human (a real change to "run to the end"), or fail fast? This is the spec's sharpest unresolved tension. The spec acknowledges half of it ("Mid-run behavior is tiered instead of 'never stop'") but not the interaction-model half. Worth settling now, because design will build a very different checkpoint depending on the answer.

**L2-2 · If-then tradeoff:** The spec introduces a provenance axis (owner-verbatim / owner / agent / inherited) that must live alongside the existing force axis (`[HARD]/[NEED]/[INFERRED]`). Open Questions frames the risk as syntax — "without doubling every line" (`spec.md:162`). It's deeper than syntax: these are two orthogonal axes that apply unevenly across artifact types. At spec level they partly collapse — the spec notes `[INFERRED]` "already covers the agent-inference grade" (`spec.md:134`) — but a concept's ground rules or an orchestrate settled-list have no force tag, only provenance. So design has to decide where the two axes coexist, where one subsumes the other, and where only provenance applies. **If** you treat this as a formatting problem, you'll get a tag soup that fights the existing vocabulary; **if** you treat it as an ontology decision (which axis governs which artifact), it stays clean. Recommend the spec flag this as a conceptual-model decision for design, not a syntax nicety.

**L2-3 · Question to the user:** Complexity is marked MEDIUM (`spec.md:6`), but the surface is: one new always-loaded rule, a change to the spec tag vocabulary, touches to eight commands, a behavioral overhaul of orchestrate (new checkpoint + tiering), and audit changes. That reads HIGH to me. More importantly, it may want splitting: (1) the capture laws + provenance grading + the settled-restriction, which is the coherent core; (2) orchestrate front-loading + tiers, which is a separable behavior change with its own risk (L2-1); (3) the review/audit/handoff structural checks. Shipping these as one item means one design and one plan spanning the whole pipeline. Is that the intent, or should orchestrate split off given it carries the biggest open question?

### Lens 3 — Pipeline Risk

**L3-1 · Question to the user:** Correction discipline is the problem the spec says is most stubborn — attitude instructions "have demonstrably not fixed it" (`spec.md:42`) — but it's the one law with no assigned enforcer. The enforcement model (`spec.md:140`) rests on reviewers verifying structure, and the reviews success criterion (`spec.md:79`) lists what they check: settled ⊆ owner-grade, quotes present, inherited cites source, referents survived. Correction discipline is absent from that list. And it's intrinsically hard to check from a review: a reviewer sees the current artifact, not the diff, so they can't tell that a correction *failed* to shrink it or *added* compensating prose. The correction success criterion (`spec.md:71`) states the test ("after the owner retracts... the artifact contains no new compensating prose") but assigns no one to run it. So the least-tractable problem gets a law and a test but no checkpoint. How does correction discipline actually get enforced — at the correcting agent's write time, by a diff-aware check, or is it accepted as best-effort? The spec should be honest about this, because the whole bet is "checkability," and here the checker is missing.

**L3-2 · Direct claim:** Success-criterion / requirement asymmetry on audit. Audit is in scope (`spec.md:168`, `:184`) and carries an `[INFERRED]` requirement (`spec.md:135`), but no success criterion covers the audit change — the seven criteria cover the rule, provenance grading, concept capture, correction, orchestrate, reviews, and handoffs, but not audit. Either audit's change deserves a success criterion (what does a fidelity-aware audit produce that today's doesn't?), or the audit `[INFERRED]` is speculative scope that should move to Open Questions. This reinforces L1-2: an unbacked `[INFERRED]` that also smells failure-specific is the most likely thing in this spec to be scope creep.

**L3-3 · Rewrite request:** Deferrals are mostly accurate — tag syntax, one-file-vs-extend, per-command wording, and parked-conclusion recording are genuine design-stage questions. Good. One is arguably spec-stage, not design-stage: the Codex-export question (`spec.md:170`) — whether the laws need a Codex representation — is a scope decision the owner can make now (the precedent is stated right there: `spec_review` references `working-voice.md` by path and that degrades gracefully). Consider resolving it in the spec rather than deferring, so design isn't left holding a scope call.

### Lens 4 — Hygiene

No material findings. The spec follows the lean core, keeps one home per idea, and — notably — practices its own compression-protection law by carrying the owner's BAD/GOOD contrast pair verbatim as a marked example (`spec.md:115`) rather than paraphrasing it. That's the right instinct, not a hygiene fault.

### Lens 5 — Reader Comprehension

**L5-1 · Rewrite request (minor):** The surfacing-duty requirement (`spec.md:96`) is one sentence carrying two trigger conditions, a two-branch response (owner when reachable, else loudly in the artifact), a prohibition, and a parenthetical generalizing the traced failure. It's decodable but needs a second read. Ask the spec agent to break it into points — trigger(s), response, prohibition — per the "decompose into points" guidance in `working-voice.md`. Low stakes; the content is right, the packing is dense.

---

## Engagement Summary

**Overall take:** This is a strong, self-aware spec pointed at a real and well-grounded problem, and it largely practices what it preaches. It's not ready to be the contract yet for three reasons: the enforcement bet has a hole exactly where the hardest problem lives (correction discipline has no checker), the orchestrate changes assume an interaction model that contradicts orchestrate's autonomous identity, and one `[INFERRED]` item looks like it violates the spec's own generalization bar. None of these means rework — the work item is sound. They mean edits and a few owner decisions.

**Here's what I need you to weigh in on:**

1. **[L3-1]** Correction discipline is your most stubborn problem and the only law with no enforcer — reviewers see artifacts, not diffs, so they can't catch a correction that failed to shrink. Decide how it actually gets enforced, or state plainly that it's best-effort.
2. **[L2-1]** The orchestrate front-loading checkpoint assumes an owner is present to answer and can "stop the run," but orchestrate is defined as autonomous with no checkpoints and the owner is often unreachable. Settle what the checkpoint does when no one's there, and what "stop the run" means.
3. **[L1-2, L3-2]** The audit `[INFERRED]` ("state what it did not check") mirrors the band-study handoff almost verbatim, has no success criterion, and risks your own generalization bar. Keep it as a general law with a reason, or cut it / move it to Open Questions.
4. **[L2-3]** Sizing: marked MEDIUM but touches a rule + tag vocabulary + eight commands + an orchestrate overhaul + audit. Is this HIGH, and should orchestrate split into its own item given it carries the biggest open question?
5. **[L2-2]** The provenance axis vs the force axis is an ontology decision, not the "don't double every line" syntax problem the spec frames it as. Flag it to design as such.
6. **[L1-1]** The orchestrate quote drops "record it loudly," so "resolved silently" overstates today's behavior. Reword the framing to attack "records-but-never-stops."

---

## Resolutions

_Resolved with the owner, 2026-07-10. All incorporated into the spec._

- **[L1-1]** Accepted. Problem reworded to attack "records but never tiers"; the elided
  "record it loudly" restored; "silently" dropped.
- **[L1-2, L3-2]** Split, owner approved: audit scope honesty kept as a general
  requirement ("a certification states what it checked and what it did not") with a
  success criterion behind it; the item-level shaping-intent glance moved to Open
  Questions.
- **[L2-1]** Owner approved: the post-Orient checkpoint is synchronous at launch — the
  owner is present by construction, and declares their reserved gates there. Mid-run,
  work blocked on a reserved gate is parked while non-dependent work continues; the run
  hard-halts only when everything remaining depends on an answer. Away-from-keyboard
  notification stays a separate feature that later upgrades "wait" to "ping."
- **[L2-2]** Accepted. Open question reframed as the ontology decision (which axis
  governs which artifact type), not tag syntax.
- **[L2-3]** Owner approved: complexity is HIGH; stays one work item (the orchestrate
  touches consume the tags the laws define); revisit splitting at design time if the
  design balloons.
- **[L3-1]** Owner approved: correction-discipline enforcement stated honestly — static
  signatures primary (prohibition-mode phrasing, negation-shaped requirements, content
  redundant with a Non-Goal), git-diff check when warranted (`.project/` artifacts are
  committed), write-time law as best effort. Reviews success criterion updated to
  include the static signatures.
- **[L3-3]** Owner resolved now: no Codex-side representation of the laws; command
  references by path degrade gracefully (`working-voice.md` precedent). Moved from Open
  Questions to Non-Goals.
- **[L5-1]** Accepted. Surfacing-duty requirement decomposed into trigger / response /
  prohibition.

---

**Verdict:** Revise
**Next Steps:** Once resolutions are recorded here, re-run `/_my_spec` (or return to the spec-agent session) and point it at this review to incorporate. The reviewer does not edit the spec.
