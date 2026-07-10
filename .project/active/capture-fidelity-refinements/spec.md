# Spec: Capture Fidelity Refinements

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-10
**Complexity:** MEDIUM
**Branch:** after `capture-fidelity` merges (builds on its rule and touches)

---

## Problem

The first full pipeline run under the capture-fidelity devices (the capture-fidelity
feature itself) worked, and its meta-assessment found the next layer of loss. Three gaps,
in the order they matter:

1. **Approval fatigue mints false provenance.** As a run progresses, the owner's
   engagement legitimately decays from substantive answers to "sure, follow your lead" —
   but every approval currently mints the same owner-grade authority. The owner's own
   words: things they *literally say* feel distinctly different from things they *"ok"*
   (buried in an approved artifact or a long chat). The current `[OWNER]` grade can't
   tell them apart, so a skim-ratified agent recommendation can enter a settled list
   wearing full owner authority — the flattening failure, one level up.

2. **Two conventions this run relied on are implicit.** Reviews only worked because the
   owner ran them in fresh sessions (a reviewer sharing the author's context inherits the
   author's blind spots) — no device says so, except for audit. And review→artifact
   incorporation is self-attested: the author records "resolved, incorporated" and edits
   the artifact with nobody tasked to compare; a review's verdict never changes state, so
   "Revise then fixed" and "Revise, ignored" look identical.

3. **Two trust hops leave no trace.** Template adaptation (this run translated
   "test-first" into "fixture-first" — correctly, but silently-by-default; a wrong silent
   substitution is invisible) and orchestrate's per-stage briefs (the owner's trust flows
   through guidance that evaporates at process exit).

## Success Criteria

- [ ] A recorded decision distinguishes owner-*originated* (the owner said it) from
      owner-*ratified* (the owner approved an agent's recommendation), and only
      originated decisions are settled-eligible. A downstream agent reading a ratified
      item knows how to challenge it: re-derive against the recorded reasoning, rather
      than treating it as the owner's will or interrupting the owner.
- [ ] When a spec or design is presented for approval, the presentation leads with the
      provenance being minted — the short list of claims the approval will ratify — so
      the owner's scarce attention lands on exactly the items that will carry their
      authority.
- [ ] The review commands state that reviews run in a fresh session, and orchestrate
      says the same for the review stages it drives.
- [ ] Incorporating a review ends with a per-finding mapping (finding ID → where the fix
      landed), presented to the owner, and the artifact header records the review
      verdict + incorporation state — so "Revise then fixed" is distinguishable from
      "Revise, ignored" without re-deriving the comparison.
- [ ] Deviating from a command template is free, but the substitution is declared —
      what replaced what, serving which purpose — so reviews can judge the adaptation
      instead of not seeing it.
- [ ] An orchestrate run leaves its per-stage briefs on disk (committed alongside the
      stage artifacts), so the guidance the owner trusted is auditable after the fact.

## Known Requirements

- **[NEED]** **Origination vs ratification.** The owner stated the gap ("it does feel
  distinctly different: things that I literally say myself, and things I 'ok'") and asked
  for the fix. The outcome: the distinction is visible in the artifact and settled
  eligibility follows origination. Note the spec register already conforms — the
  sharpened `[NEED]` (owner-*stated*) makes a ratified recommendation `[INFERRED]` by
  definition — so the gap is the shaping register's `[OWNER]` grade and the annotation
  form for ratification.
- **[HARD]** **The rule's own budget.** `capture-fidelity.md` states "≤ ~40 lines of
  substance; a correction lands as a sharper existing law, never as a new one"
  (`claude-pack/rules/capture-fidelity.md:7-8`). Everything this item adds to the rule
  must land as sharpened wording of law 1, within budget.
- **[NEED]** **Fresh-session reviews.** Owner-originated this session: "reviews are
  meant to be fresh-session. that is how I always run it, and SHOULD BE the instructions
  for the `my_orchestrate` agent. we should make it explicit."
- **[INFERRED]** (recommended this session; owner directed this spec) **Incorporation
  mapping.** The convention lands in the two review commands' hand-off phrasing: the
  incorporating agent presents finding-ID → landing-site, and stamps the artifact header
  with verdict + incorporation state. No re-review round by default — the mapping makes
  drift visible for near-zero cost; git holds the diff if a mapping smells wrong.
- **[INFERRED]** (recommended; owner directed this spec) **Minted-provenance
  presentation.** At spec/design final approval, the presentation leads with the
  to-be-ratified claims. Scope deliberately narrow: final approvals only — applying it
  to every checkpoint would recreate the fatigue it fights.
- **[INFERRED]** (recommended; owner directed this spec) **Declared adaptation.** One
  sentence, placed once (candidate home: `_my_pipeline.md`'s guide, since it is a
  property of every stage): deviate from a template freely; declare the substitution and
  the purpose it serves. Silent template-filling is the failure mode; the declaration is
  what reviews can check.
- **[INFERRED]** (recommended; owner directed this spec) **Durable briefs.** Orchestrate
  commits each stage's brief alongside the stage's artifact. Also resolves the
  design-review m3 residue from the parent item (ephemeral stdin had no checker).
- **[NEED]** **Generalization bar carried forward** `[INHERITED:
  .project/active/capture-fidelity/spec.md]` — no device gains a failure-specific check;
  each addition must hold as a general law of the pipeline. (Inherited but re-affirmed by
  the owner throughout this session's feedback.)

## Non-Goals

- **Measuring owner engagement** — no device can verify how hard the owner looked;
  origination is checkable at capture time, attention is not. The fix routes authority,
  it does not grade the owner.
- **A default re-review round after incorporation** — cost exceeds the drift it would
  catch; the mapping convention is the proportionate check.
- **New tags beyond the ratification annotation** — the existing vocabularies absorb all
  six changes; tag growth was rejected throughout the parent item.
- **Away-from-keyboard notification** — still its own future item; the Align checkpoint
  and reserved-gate halts are unchanged here.

## Open Questions / Deferred to design

- The ratification annotation's exact form (parent design used `[AGENT] (ratified by
  owner, date)` as the working sketch) and where the rule's law-1 wording absorbs it
  within budget.
- Where the declared-adaptation sentence lives (`_my_pipeline.md` guide vs each
  template-heavy command) — one home, design picks it.
- Brief-commit mechanics: commit message vs a `briefs/` file next to the stage artifact,
  and whether `orchestrate-stage.sh` does it or the orchestrator does.
- Whether the minted-provenance presentation also applies to concept approval (the
  richest capture point) or only spec/design.

---

## Related Artifacts

- **Parent item:** `.project/active/capture-fidelity/` (spec, design, reviews, audit —
  Certify 2026-07-10). This item is the meta-assessment follow-up from the parent's own
  pipeline run.
- **Rule under refinement:** `claude-pack/rules/capture-fidelity.md`
- **Design:** `.project/active/capture-fidelity-refinements/design.md` (to be created)

---

**Next Steps:** After the parent item merges: `/_my_spec_review`, then `/_my_design`.
