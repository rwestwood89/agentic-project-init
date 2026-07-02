# Spec Review: wordfreq CLI

**Spec:** `.project/active/wordfreq/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md` (not readable from this sandboxed session — review conducted against the generation criteria embedded in the spec-review command itself: HARD/NEED/INFERRED tagging, section shape, and traceability)
**Review File:** `.project/active/wordfreq/spec-review.md`
**Date:** 2026-07-02

---

## Reality Check

**Sound.** This is a small, self-contained spec for a standalone word-frequency CLI. There are no upstream artifacts to cross-check (Epic: None, Research: None), and the repo is empty (no code, no git history), so there's nothing in the codebase that could contradict a code-facing claim. The Problem section is coherent, the requirements plausibly trace back to it, and the scope (Non-Goals) is tight. This spec is pointed at the right work item.

One limitation on this review's confidence: I have no access to the original conversation between the user and the spec agent, so claims like "stated directly as a boundary condition" can't be independently checked against the user's actual words. I've treated those as plausible but unverified rather than as confirmed facts — see L1-2.

Proceeding to the full lens audit.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Rewrite request:** The `[INFERRED]` tokenization item ("words are runs of letters/digits (not ASCII-only)") states a tokenization *mechanism*, not an outcome, and its scope is ambiguous. Read narrowly, it covers accented Latin text (café, naïve) — a solid inference from the UTF-8 requirement. Read broadly, "or non-Latin words" in the justification implies coverage of any script, including ones that don't tokenize on whitespace/letter runs at all (CJK). The spec can't have it both ways, and as written it doesn't say which. Rewrite the outcome as something like "accented and non-ASCII Latin characters must not be corrupted or split by tokenization," and push script-coverage scope (how far past Latin this goes) into the existing "Tokenization edge cases" Open Question rather than asserting it as settled.

**L1-2 · Question to the user:** The `[HARD]` requirement "Standalone CLI with no dependency on any existing codebase" is annotated as "stated directly as a boundary condition." I can't verify that against the original conversation in this session. **Can you confirm you actually said this as a hard constraint, and not just "this happens to be a scratch project so there's nothing to depend on"?** Those are different claims — the first is a durable requirement, the second is incidental context that wouldn't survive if this code ever moved into a real codebase.

### Lens 2 — Problem & Approach

**L2-1 · Question to the user:** The spec's implicit bet is that "frequency count minus stopwords" is a good enough proxy for "what a document is about." That's a reasonable bet for prose (articles, notes, essays) but weak for structured or repetitive text — source code, logs, CSV dumps — where the highest-frequency non-stopword tokens are often boilerplate (`return`, variable names, timestamps) rather than topical content. **Is this tool meant only for prose-style text?** If so, it's worth one line in Non-Goals ("not intended for source code or structured/log data") so design and future users don't treat it as a general-purpose file summarizer.

### Lens 3 — Pipeline Risk

**L3-1 · Direct claim:** The `[INFERRED]` "ties broken alphabetically" item is a mechanism choice wearing an inference's clothes. The genuinely inferable need is *determinism* ("output must be stable and reproducible across runs on the same input") — that much follows from wanting a trustworthy at-a-glance tool. But "alphabetically" specifically is one of several ways to satisfy that (could just as easily be first-occurrence order, or reverse-alphabetical), and nothing in the Problem or the user's stated examples picks alphabetical over the alternatives. Recommend: keep "output must be deterministic" as the INFERRED requirement, and move the specific tie-break rule to Open Questions as a design pick (a sensible default, but not a requirement).

**L3-2 · Contradiction:** The Unicode-tokenization item flagged in L1-1 sits in tension with the stated Non-Goal "No multi-language stopword lists or locale-specific tokenization." If tokenization is meant to handle "non-Latin words" broadly, that's arguably locale-specific tokenization by another name — different scripts need different word-boundary logic. As written, a downstream design agent could reasonably resolve this either way (Latin-only with diacritics, vs. any whitespace-delimited script), and get a different result each time. Resolving L1-1's scope question resolves this too.

**L3-3 · Missing content:** No Success Criterion covers the `[HARD]` "standalone, no dependency on any existing codebase" requirement — nothing in the Success Criteria section would catch a violation of it. Given the sandbox has no other code to depend on, the risk is low today, but if this spec or its pattern gets reused in a real repo, the omission stops being harmless. Low priority given the current context; worth a one-line addition if this spec template gets reused elsewhere.

### Lens 4 — Hygiene

No material issues. Sections follow the expected shape, metadata (owner, date, complexity) is filled in and consistent with the sandbox context (branch "N/A" correctly reflects there being no git repo yet).

### Lens 5 — Reader Comprehension

No material issues. The spec is short, uses plain language throughout, and a reader can take in the whole thing in one pass. No jargon, no undefined terms, no buried decisions.

---

## Engagement Summary

**Overall take:** This is a sound, low-complexity spec for the right work item — nothing here suggests Rework. The issues are all in the same family: two `[INFERRED]` items assert a specific mechanism (a tokenization rule, a tie-break rule) instead of the outcome that actually follows from the user's ask, and one of those mechanisms quietly contradicts a stated Non-Goal. These are quick edits, not a re-scope.

**Here's what I need you to weigh in on:**

1. **[L1-1, L3-2]** Decide how far tokenization should reach past accented Latin text (Cyrillic/Greek? CJK?), or explicitly punt the whole question to design — either resolves the contradiction with the "no locale-specific tokenization" Non-Goal.
2. **[L3-1]** Decide whether "alphabetical" tie-breaking is a real requirement or just a reasonable default — if the latter, it should move to Open Questions rather than sit tagged as settled.
3. **[L1-2]** Confirm the "standalone CLI, no codebase dependency" HARD requirement is something you actually said as a durable constraint, not just incidental to this being a scratch project.
4. **[L2-1]** Confirm whether this tool is meant only for prose-style text — if so, worth a one-line Non-Goal.
5. **[L3-3]** Optional, low priority: add a Success Criterion (or acceptance note) that would catch a violation of the standalone-CLI requirement, in case this spec pattern gets reused in a non-sandbox repo.

---

**Verdict:** Revise
**Next Steps:** Resolve items 1–4 above (item 5 is optional), tighten the two `[INFERRED]` items per L1-1/L3-1, then re-run `/_my_spec` to fold the edits in before proceeding to `/_my_design`.
