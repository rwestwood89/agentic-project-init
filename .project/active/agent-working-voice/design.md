# Design: Agent Working Voice

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-06-23
**Branch:** mental-alignment

## Overview

Define the agent's working voice in one auto-loaded rule, rewrite the command prompts so they stop modeling the bad voice, and add a working-voice check to the two review commands that gate written artifacts.

## Related Artifacts

- **Spec:** `.project/active/agent-working-voice/spec.md`
- **Content source:** `/tmp/claude-writing-feedback.md` (the agent's own diagnosis — primary input for the rule's content)
- **Audit research:** summarized below in Research Findings

## Research Findings

I swept all 29 commands plus skills and agents, read the two review commands in full, and confirmed the Codex build mechanics.

**Voice guidance today is scattered and thin.** No file defines the working voice. The closest things are structural (`concept_design`'s register discipline, `spec`'s normative-language rules) or one-line "be clear" asides (`spec`, `research`). The decision-presentation format the user wants by hand exists nowhere as a standard, though `spec_review`'s finding-framing section (`_my_spec_review.md:73-91`) is a partial, good-quality instance of it.

**Several command prompts are themselves written in the dense register.** Confirmed dense or mixed: `_my_concept_design.md` (the "What You MUST NOT Do" block, ~lines 368-391), `_my_implement.md` (the all-caps "ABSTRACTION QUALITY" / "FAIL LOUDLY" blocks, ~lines 122-177), `_my_audit_implementation.md` (jargon: "god functions," "slop," ~lines 30-58), `_my_design.md` (anti-patterns, ~lines 327-374), `_my_review_design.md` (negation-stacked opening, lines 9-26). This is the lever the spec names: the agent mirrors the register of its instructions.

**Codex build:** `scripts/build-codex-pack.sh:323-331` concatenates every `rules/*.md` into `AGENTS.md`. A new rule propagates automatically. No command references the `rules/` dir by name, so pointing commands at the new rule is additive.

**Correction to the audit — the most important finding.** The sweep flagged ~12 files as "conflict-risk voice guidance" and named four "tensions" to reconcile (minimalism vs. justification, skepticism vs. confidence, etc.). That is wrong, and acting on it would break the commands. Those are differences in the *stance each command takes toward its job*, not differences in voice. A review command is told to be skeptical; a spec command to capture faithfully rather than invent; a concept command to push for simplicity. Those stances are correct and specific to each command, and the working-voice rule must not override them. What the rule owns is narrower: how the prose *reads* — plain or jargon-laden, one idea at a time or stacked, logical or tangled, and how decisions are presented. The real conflict set is therefore close to empty; the real work is rewriting the prompts that read badly, plus pointing a couple of decision-presentation references at the rule.

## Core Concept

One file defines the working voice. Everything else either points at it or is rewritten to embody it, and the review commands check artifacts against it.

The insight that makes this work — and the reason a rule alone has failed before — is that **the agent mirrors the register of its own instructions.** A rule that *describes* good voice while sitting next to prompts that *demonstrate* bad voice loses to the demonstration. So the design has three layers, each doing a different job:

- **The rule is the specification** of the voice (what good looks like, plus the decision format).
- **The rewritten prompts are the demonstration** — the in-context examples the agent actually imitates.
- **The review check is the backstop** — it catches artifacts that slipped through, at the one moment a human is already reviewing.

This is the right approach rather than "just write a stronger rule" because it attacks the mechanism (imitation) instead of only the symptom (output). It is proportional: no new tooling, no new commands, no enforcement machinery beyond a check in the two commands that already gate artifacts.

## Key Bets & Decisions

**Bet 1 — Rewriting prompts is the lever, not the rule.** The rule is necessary but weak on its own. Most of the effect comes from the prompts reading in the target voice. This is why deliverable #2 is in scope at all.

**Bet 2 — The rule owns how prose reads, not the command's stance or structure.** It governs voice and how decisions are presented. It does not govern whether a command is skeptical or faithful (the command's stance toward its job, left to the command) or what sections an artifact has (structure, left to the command). This keeps the rule from conflicting with legitimate command instructions, which was the user's stated fear. (Decided.)

**The rewrite principle (settled).** The goal is plain, explicit, readable prose — not "less density." The failure mode is density reached by hiding behind loaded jargon. The fix is a method, not a word count: break complexity into simple ideas, present one idea at a time, in a logical order. When something is genuinely complex, don't cut it — give the reader a mental model or framework to hang the pieces on. Prose that is already plain and explicit, including blunt, terse instructions, passes as-is; this is not a license to pad.

**Decision B — Where the review check lives and how high its bar (confirmed with user).** Two sub-decisions:
- *Which commands.* Only `_my_spec_review` and `_my_review_design` — the two that gate written artifacts a human reads. `code_review` reviews code, not prose; `review_compact` reviews a machine summary. Those inherit the voice through the global rule without a dedicated check. (Recommendation; open to adding a lighter check later.)
- *How it's framed.* In `spec_review`, the check is **not** Lens 4 Hygiene — that lens explicitly says keep prose comments minimal. Instead, anchor it to the primary audience the command already names: the human reviewer is ~75% of the audience (`_my_spec_review.md:9`). A spec the human can't skim has failed its main job. So the check fires only when voice **materially blocks comprehension**, not on awkward sentences. In `review_design`, add it as a readability dimension tied to the design's stated purpose (mental alignment), sharpening the existing "ignore style unless it affects clarity" guideline (`_my_review_design.md:210`) into the working-voice standard.

**Presenting decisions is an example, not a mandated format (decided).** Walking the user through a decision — the situation, the crux, the options and why, the recommendation — is the clearest case of good-versus-bad writing, so the rule uses it as a *worked example* to illustrate the principles. It is not framed as "the one format for decisions." Reach for that shape in proportion to the decision's weight; a one-line answer stays one line. This keeps the rule from making short exchanges ceremonial.

## Architecture

Three artifacts, one new and the rest edited.

**1. The rule — `claude-pack/rules/working-voice.md` (new).** Auto-loaded every session; propagated to Codex via the existing build. Structure, kept short and example-driven (length is itself a voice failure):

- *Scope line.* Owns the working voice for chat and internal workflow artifacts. Not external explainers. Not the command's stance toward its job. Not artifact structure.
- *The method.* Plain, explicit, readable. Break complexity into simple ideas; present one idea at a time, in a logical order. When something is genuinely complex, give the reader a mental model or framework to hang the pieces on rather than cutting it. Don't reach density by hiding behind loaded jargon. Define terms on first use and anchor a precise term in parentheses; no coined labels reused as if shared; caveats earn their place. Keep identifiers out of the flowing prose but always give a reference — name code with its `file:line`, never bare. Decompose into points and avoid block text (hard to read, especially in a terminal): most explanation breaks into discrete points, so use bullets, short paragraphs, and line breaks by default for reasoning, not just fact-lists, with the structure mirroring the logic.
- *Precision is the work behind it.* Plain writing requires understanding; vague or jargon-heavy prose is the tell that the work wasn't done. Verify details against the source before writing them, be exact (simplifying never erases a real distinction), and when unsure, say so plainly rather than hiding it.
- *Presenting a decision — a worked example.* A before/after of walking the user through a decision (situation, crux, options and why, recommendation), used to illustrate the method. Framed as a good-vs-bad example, not a mandatory template.
- *Texture / anti-tells.* The register to avoid — hedging, "not just X but Y" parallelism, inflated stakes, nominalized verbs, em-dash triplets, "robust/leverage/seamless" vocabulary — each with a short before/after.

**2. Command prompt edits.** Two kinds, both narrow:
- *Pointer (additive).* Where a command already gives decision-presentation guidance (`spec_review`'s finding framings, `quick_edit`, `code_review`'s presentation step), add a one-line reference to the rule rather than restating it. No content removed.
- *Voice rewrite (the real work).* Rewrite the prompt prose identified above into the target voice, applying the rewrite principle: where it hides behind jargon or stacks ideas, break it into simple ideas one at a time in logical order; build a mental model where the complexity is real. The command's stance toward its job and its structural rules stay untouched.

**3. Review-command checks.** A focused working-voice check added to `_my_spec_review` and `_my_review_design` per Decision B.

## Required Invariants

- The rule reads in the voice it defines. If it doesn't, that's the first bug.
- A prompt rewrite changes how the prose reads only — never the instruction's meaning, never the command's stance toward its job, never its structural rules.
- The review check fires only when voice materially blocks comprehension, never on stylistic preference.
- `concept_design` register discipline, `spec` normative language, and all external-explainer guidance remain byte-for-byte unchanged.

## Component Overview

- `claude-pack/rules/working-voice.md` — new rule; the voice specification and decision format.
- `claude-pack/commands/_my_*.md` — edited: dense prompts rewritten in register; decision-format references pointed at the rule. Posture/structure preserved.
- `claude-pack/commands/_my_spec_review.md`, `_my_review_design.md` — gain a working-voice check anchored to comprehension.
- `scripts/setup-global.sh`, `scripts/build-codex-pack.sh` — unchanged; re-run to symlink the new rule and propagate it to Codex.

## Non-Goals

- Reconciling the different stances commands take toward their jobs (skeptical reviewer vs. faithful capturer vs. simplicity-pusher). Legitimate; left alone.
- Touching artifact structure (what sections a doc has).
- External-explainer guidance and external-audience writing.
- A forced per-command voice self-review pass.
- New tooling, commands, or a linter.

## Potential Risks

- **Over-flattening or padding.** Plain and explicit does not mean longer. Blunt, terse instructions already pass; the rewrite breaks up jargon and stacked ideas, it doesn't add words. Mitigated by reviewing each prompt diff for meaning drift.
- **The rule becomes a style bible nobody internalizes.** Mitigated by brevity and leaning on before/after examples over abstract rules.
- **The voice check devolves into prose nitpicking.** Mitigated by anchoring it to the primary-audience comprehension bar, with awkward-sentence findings explicitly out of scope.
- **Scope creep from the audit's over-flagging.** Mitigated by Bet 2: a command's stance toward its job is not a conflict; the real edit set is the ~5 prompts that read badly plus a few pointer lines.

## Integration Strategy

Additive. The rule joins the existing `rules/` set and loads the same way the others do. `setup-global.sh` symlinks it; `build-codex-pack.sh` folds it into `AGENTS.md`. Command edits are in-place. Nothing changes about how commands are invoked or how the pipeline flows.

## Validation Approach

- **Rule self-consistency:** read the finished rule as a skeptical first-time reader — does it obey itself?
- **Prompt diffs:** each rewritten prompt diffed to confirm register changed and meaning/posture/structure did not.
- **Untouched-files check:** confirm `concept_design` register discipline and external guidance are unchanged.
- **Build/install:** `build-codex-pack.sh` + `setup-codex.sh` run clean; the rule appears in `AGENTS.md`; `setup-global.sh` symlinks it into `~/.claude/rules/`.
- **End-to-end:** run `/_my_spec` or `/_my_design` on a real item and confirm the output reads in the working voice without a rescue prompt.

## Next-Stage Handoff

**Fixed:** three-layer approach (rule + prompt rewrites + review check); rule owns how prose reads, not the command's stance or structure (Bet 2); the rewrite principle (plain, explicit, one idea at a time, mental models for real complexity); decisions presented as a worked example, not a mandated format; enforcement limited to the two review commands (Decision B).

**Open:** nothing structural. The exact text of the rule and the per-prompt edits are drafting work for the plan/implement stage.

**De-risk first:** write the rule itself first and pressure-test its voice. Everything downstream imitates it, so if it's wrong, the rewrites inherit the error.

---

**Next Step:** `/_my_plan`.
