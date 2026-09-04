# Spec Review: Mental-Model Reviewer and the Prompt-versus-Feedback Split

**Spec:** `.project/active/mental-model-reviewer/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/mental-model-reviewer/spec-review.md`
**Date:** 2026-09-02

---

## Reality Check

Sound. The spec describes the right work item, and its code-facing constraints match the current adapter and dist scan (`scripts/build-codex-pack.sh:184-259`; `scripts/test_codex_orchestrator_pack.sh:342-378`). It needs three targeted corrections before design.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim:** The spec and product-lens ledger still say the owner-directed amendments await confirmation (`spec.md:27-31`; `product-lens.md:7-17`), but the owner has now confirmed them. The reviewer runs on every artifact inside the existing synthesis or rendering stage; generalized rules belong in the prompt; the writer does not read shared feedback; and the reviewer reads the prompt plus both feedback tiers. The spec agent must record these as current owner decisions and clear the product-lens block through its stated resolution path.

**L1-2 · Direct claim:** The spec requires reviewer notes to reach the owner and requires the writer to record reasons for declined feedback (`spec.md:39,41,66`). The owner rejected both. The writer decides internally what feedback to apply. The reviewer is not an audit or gate, and neither its notes nor writer dispositions reach the owner or coordinator.

### Lens 3 — Pipeline Risk

**L3-1 · Direct claim:** The live-run criterion requires at least one reviewer note to change the artifact (`spec.md:44`). A correct first draft would therefore fail acceptance. The same criterion also does not prove the required two-direction behavior: catching an anti-pattern and noticing a missed useful technique (`spec.md:57`). Replace it with evidence that exercises both directions when applicable without requiring every live artifact to contain a defect.

---

## Engagement Summary

**Overall take:** The work item is sound. The current spec has three actual problems: it still treats confirmed decisions as pending, it wrongly puts reviewer feedback in the owner's loop, and its behavioral validation rewards finding a defect rather than proving the reviewer works.

**What the spec agent needs to change:**

1. **[L1-1]** Record the confirmed owner decisions and clear the stale product-lens block.
2. **[L1-2]** Keep reviewer feedback inside the writer-reviewer exchange; the writer decides, and the owner and coordinator see none of its notes or dispositions.
3. **[L3-1]** Fix the behavioral validation so a good first draft can pass and both review directions are exercised.

---

## Resolutions

- **[L1-1]** The owner confirms the prompt-versus-feedback split and an advisory reviewer pass on every artifact inside the existing synthesis or rendering stage.
- **[L1-2]** The writer decides internally what feedback to apply. The reviewer provides feedback, not an audit. The owner and coordinator receive no reviewer notes or dispositions.

---

**Verdict:** Revise
**Next Steps:** Resolutions are recorded. Re-run `my-spec` (or return to the spec-agent session) and point it at this review to revise the spec. The reviewer does not edit the spec.
