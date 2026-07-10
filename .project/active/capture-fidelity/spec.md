# Spec: Capture Fidelity

**Status:** Reviewed — revisions incorporated (see `spec-review.md` Resolutions)
**Owner:** Reid W
**Created:** 2026-07-10 08:50
**Complexity:** HIGH
**Branch:** main (branch before implementation)

---

## Problem

The pipeline converts conversation → concept → spec → design → execution, and each
hop is an agent writing an artifact that later agents treat as ground truth. Forensics
on a real failed run (the echo-workspace band-hyperparameter study; traced in this
session) showed the conversion is systematically lossy in three ways, and the losses
compound across hops:

1. **Provenance flattening.** Once written down, the owner's decisions, an agent's
   operationalizations, and machinery inherited from prior work all read with equal
   authority. "Settled / do not re-litigate" lists fuse them, so executors end up
   forbidden from questioning things the owner never decided. In the traced failure,
   an agent-inferred quarantine line wearing owner authority fenced off exactly the
   question that would have saved the study.

2. **Compression loss with inverted survival.** What survives the chat→artifact hop is
   what's easy to codify (thresholds, gates, procedure); what attenuates is the owner's
   qualitative payload — the examples they gave, the referent they pointed at, the
   texture of what they actually want. In the traced failure the owner pointed at a
   concrete exemplar report and gave several examples of what the studies should look
   like; none of it survived into the concept, while agent-added procedural rules
   survived with full fidelity. Execution then optimizes the scaffolding and misses the
   point. The mirror failure also occurs: an owner's *example* gets hardened into *the*
   required form.

3. **Correction metastasis.** When the owner corrects something, agents overcorrect and
   then document the overcorrection: a retracted requirement becomes a paragraph about
   what is not required, which the next agent reads as an anti-requirement; a frustrated
   correction becomes a fortress of ALL-CAPS prohibitions aimed at the last failure.
   Emphasis ratchets monotonically across correction cycles and crowds out the goal.
   The owner has feedback memories about this in nearly every project; attitude-level
   instructions ("don't overcorrect") have demonstrably not fixed it.

Downstream, `/_my_orchestrate` flattens the decision tiers: "make the most defensible
call, record it loudly, and keep going. Don't stop and wait" (`_my_orchestrate.md:63-64`)
treats an owner-reserved decision the same as an execution detail. A goal-vs-rule
collision discovered mid-run gets recorded at best, but resolved without the owner —
in the traced failure, toward compliance with a rule the owner never made.

The fix must meet the repo's standing bar: **generalization**. The devices were recently
cleansed of failure-specific checks; this work must not re-accrete them. It must also
work in both operating modes: precisely-specified deliverables (specificity keeps its
teeth) and fuzzy concepts where the deliverable is legitimately determined during
execution (no forced early concretization).

## Success Criteria

- [x] A single always-loaded rule states the capture-fidelity laws (provenance,
      compression, correction, surfacing) in general form. Devices reference it;
      none restates it. It stays small (~40 lines, same order as `working-voice.md`'s
      sections) and contains no failure-specific checklists.
- [x] Decision-carrying content in shaping artifacts (settled lists, ground rules,
      prohibitions, non-goals) carries a provenance grade, and "settled /
      do-not-re-litigate" status is structurally restricted to owner-grade items.
      An executor reading any pipeline artifact can tell what binds absolutely,
      what is challengeable scaffolding, and what is inherited-and-never-validated.
- [x] A concept sourced from a live conversation preserves the owner's key statements
      verbatim, and owner-given examples/referents (paths, links, named standards)
      survive into the artifact with their force marked — illustrative example vs
      binding referent. When force is unclear, the capturing agent asks rather than
      guessing in either direction.
- [x] A correction to any artifact shrinks or amends it. Test: after the owner retracts
      or downgrades something, the artifact contains no new compensating prose about
      the retraction, and no emphasis markers beyond what the owner expressed.
- [x] `/_my_orchestrate` front-loads alignment: after Orient, one synchronous
      checkpoint at launch (the owner is present by construction — they just invoked
      the run) resolves meaning-of-work ambiguity, records the owner's reserved
      decision gates, surfaces provenance gaps and cross-document conflicts, and
      questions suspect hard requirements ("do you literally want X, or are you
      solving for Y?") — before any stage runs. Mid-run behavior is tiered: work
      blocked on a reserved gate is parked while non-dependent work continues; the
      run hard-halts only when everything remaining depends on an answer.
- [x] Audit verdicts state their own scope — what was checked and what was not. A
      Certify with unstated limits is incomplete.
- [x] Reviews (`spec_review`, `design_review`) check the structural discipline —
      settled items trace to owner-grade tags, verbatim quotes exist where claimed,
      inherited items cite their source, owner-given referents from upstream artifacts
      survived, and correction-discipline static signatures (prohibition-mode phrasing,
      negation-shaped requirements, content redundant with a Non-Goal) are flagged —
      without gaining failure-specific rubric items.
- [x] Handoffs distinguish verified claims from carried ones by default.

## Known Requirements

- **[NEED]** (owner, this session) **Provenance grading.** Every recorded decision,
  constraint, or ground rule in a pipeline artifact is attributable to one of:
  owner-verbatim (quoted), owner (their decision, paraphrase the owner has seen),
  agent (this or a prior agent's inference/operationalization), or inherited (carried
  from prior work, never independently validated; source cited). Exact tag syntax is
  design's.
- **[NEED]** (owner, this session) **The settled rule.** Only owner-grade items may be
  marked settled/non-negotiable. Agent/inherited items are challengeable when evidence
  warrants; inherited items are never settled by default.
- **[NEED]** (owner, this session) **The surfacing duty.**
  - Triggers: following a recorded rule would work against the recorded goal; or
    genuine surprise produces evidence against a premise the plan or its conclusions
    rest on. (The traced failure's "evaluation frame" is one instance of the latter —
    the frame was a premise the conclusions rested on.)
  - Response: surface the conflict — to the owner when reachable, otherwise loudly in
    the artifact, with dependent conclusions parked.
  - Never resolve it silently, in either direction.
- **[NEED]** (owner, this session) **Compression protection.** Owner-given examples,
  referents, numbers, and named standards are payload: they survive capture verbatim
  or by path, at the owner's emphasis, with their force marked (illustrative vs
  binding). An example must not be hardened into the required form; a binding referent
  must not be softened into a vibe. Unclear force → ask.
- **[NEED]** (owner, this session) **Correction discipline, stated as observable
  behavior.** A correction deletes or amends the corrected content at the owner's
  emphasis. Deleted means deleted — no documentation of the non-requirement. A rejected
  path that must be recorded to prevent re-adding gets one line in its designated home
  (Non-Goals, or a design's rejected-alternative note), phrased as a decision record,
  never as a behavioral instruction to future agents. This law governs all artifact
  writes, including memories and handoffs.
  The owner's contrast pair for recording a rejection — binding on the rule's wording,
  carried as its example:
  - BAD: suggestion → rejection → "WE MUST NOT \<suggestion\>". The prohibition anchors
    future agents on the suggestion in a way the owner never intended.
  - GOOD: suggestion → rejection → "Out of scope: \<suggestion\> is not required
    because \<reason\>". Context and color along a well-worn agent reasoning path.
- **[NEED]** (owner, this session + review resolution L2-1) **Orchestrate
  front-loading + tiers.** Work does not start until the meaning of the work is clear:
  one synchronous checkpoint at launch (post-Orient; the owner just invoked the run,
  so they are present), where the owner's reserved gates are recorded. Mid-run:
  owner-reserved decisions park their branch — non-dependent work continues, and the
  run hard-halts only when everything remaining depends on an answer; premise-level
  surprises invoke the surfacing duty; execution details proceed on the agent's
  judgment as today.
- **[NEED]** (owner, this session) **Generalization bar.** No device gains a check that
  only makes sense for the band-study failure. Each addition must be justifiable as a
  general law of chat→artifact→artifact pipelines.
- **[HARD]** Always-on placement means `claude-pack/rules/` — that is the existing
  mechanism by which rules load into every session (per `setup-global.sh` symlinking).
- **[INFERRED]** The spec tag vocabulary gains an inherited grade (a requirement
  absorbed from an upstream artifact, source cited) so absorbed constraints stop being
  rewritten as `[HARD]` with their origin erased. `[INFERRED]` already covers the
  agent-inference grade at spec level.
- **[NEED]** (owner, via review resolution L1-2) **Audit scope honesty.** A
  certification states its own scope — what was checked and what was not. This is a
  general law of certifications, not a reaction to one audit: a Certify with unstated
  limits reads as a blank check, and real-world audit opinions always state their
  basis and limitations.
- **[INFERRED]** Enforcement is honest about its limits: no downstream agent can verify
  conversation truth. The mechanism is (a) authority claims become explicit and
  falsifiable at capture time, (b) the owner's review attention is directed to exactly
  the owner-tagged claims, (c) reviewers verify structure (quotes present, settled ⊆
  owner-grade, inherited cites source, upstream referents survived), and (d) verbatim
  blocks give later reviewers something concrete to review against.
- **[NEED]** (owner, via review resolution L3-1) **Correction-discipline enforcement,
  stated honestly.** Primary: static signatures detectable in the artifact alone —
  prohibition-mode phrasing, negation-shaped requirements, content redundant with a
  Non-Goal (the reviews check these). Secondary: the git diff of the artifact, when a
  review has reason to inspect how a correction landed (`.project/` artifacts are
  committed). The write-time law itself is best effort — it is the layer that has
  historically failed alone, which is why the other two exist. No stronger enforcement
  is claimed.

## Non-Goals

- **A concept-review pipeline stage.** Concepts sourced from conversation often have
  nothing external to review against; the owner in-session is the reviewer. The
  verbatim/provenance discipline is what makes later review possible at all.
- **Mandatory exemplars for qualitative deliverables** — rejected; compression
  protection covers the case that actually failed (an owner-given referent got dropped).
- **Away-from-keyboard notification (e.g., email push) for orchestrate questions.**
  Real need, separate feature; candidate backlog item.
- **Eliminating the overcorrection disposition itself.** Prompt text narrows the
  channel and makes violations checkable; it does not patch the model. The laws are
  worded as structural, observable behaviors for exactly this reason.
- **Changing the pipeline shape** (stage order, new stages, `rules/pipeline.md`).
- **A Codex-side representation of the laws** — not required; command references by
  path degrade gracefully (precedent: `spec_review` references `working-voice.md` by
  path). Resolved at review (L3-3).

## Open Questions / Deferred to design

- The provenance axis vs the force axis is an **ontology decision, not tag syntax**
  (review L2-2): provenance (owner-verbatim/owner/agent/inherited) and force
  (`[HARD]/[NEED]/[INFERRED]`) are orthogonal and apply unevenly across artifact
  types — at spec level they partly collapse (`[INFERRED]` is the agent grade), while
  a concept's ground rules carry only provenance. Design decides which axis governs
  which artifact type, where one subsumes the other, and the resulting syntax.
- Whether item-level audits should include the shaping-intent glance that today exists
  only at epic scope (`_my_audit.md:135`) — moved here from requirements (review
  L1-2): plausibly general (it fills an asymmetry), but the least certain to
  generalize; design or a later item decides.
- Whether the laws live in one new rule file or extend `working-voice.md`
  (recommendation at spec time: separate file — working-voice governs prose style,
  this governs capture semantics — but design owns the call).
- Exact placement and wording of the per-command touches (`_my_concept`, `_my_spec`,
  `_my_spec_review`, `_my_design`, `_my_design_review`, `_my_orchestrate`,
  `_my_audit`, `_my_handoff`), honoring "devices reference the rule, never restate it."
- How orchestrate records parked conclusions and surfaced conflicts so the commit
  trail carries them (today's trail is commits + the run summary).

---

## Related Artifacts

- **Forensic source:** echo-workspace traced failure — concept lineage
  `~/echo-workspace/.project/concepts/{dispatch-value-exploration,dispatch-value-exploration-part2,band-hyperparameter-study}.md`,
  Item C fence/threshold (`~/echo-workspace/.project/active/dispatch-value-band-refinement/{spec,design,recommendation}.md`),
  study execution (`~/echo-workspace/.project/active/band-hyperparameter-study/round-log.md`),
  repair handoff (`/tmp/handoff-20260710-band-study-audit-repair.md`).
- **Devices in scope:** `claude-pack/rules/` (new rule), `claude-pack/commands/_my_{concept,spec,spec_review,design,design_review,orchestrate,audit,handoff}.md`.
- **Spec review:** `.project/active/capture-fidelity/spec-review.md` (verdict Revise;
  all resolutions incorporated 2026-07-10)
- **Design:** `.project/active/capture-fidelity/design.md` (to be created)

---

**Next Steps:** After approval, `/_my_spec_review`, then `/_my_design`.
