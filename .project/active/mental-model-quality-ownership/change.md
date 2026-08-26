# Feature Change: Mental-Model Coordinator Owns End Quality

**Status:** Complete
**Owner:** Reid W
**Created:** 2026-08-26 08:59 PDT
**Last Updated:** 2026-08-26 08:59 PDT
**Git Branch:** mental-model-quality-ownership
**Git Hash:** 463366e (base)

## Overview

The `_my_mental_model` coordinator now owns the quality of everything it hands the owner, and enforces the written standard by sending work back to the agent that produced it. Two new review gates — one on the synthesis before the owner sees it, one on the rendered HTML before the owner gets the link — plus a correction gate that now serves the coordinator's own findings as well as the owner's.

The value: the skill exists to spend the owner's attention once instead of five times. A coordinator that finds defects and forwards them as a list spends that attention anyway. This closes the gap between finding a defect and fixing it.

## Problem Statement

- A real run surfaced the failure. The coordinator read the synthesis, found three defects against the written standard, and presented both the synthesis and the defect list to the owner. The owner confirmed all three, and the coordinator then sent them back to the synthesis agent — a round of owner attention spent on findings the coordinator already had in hand.
- The skill told the coordinator what to **route** and never said it **owns** what it routes. The role paragraph read "classify, spawn, present, route, record. You do not write the synthesis or the HTML yourself" — a real constraint that reads as the limit of the coordinator's involvement with content.
- Step 4 went straight from "read the synthesis file it wrote" to "Present the full synthesis to the owner." No review beat between the two.
- "Confirming a render" said a render is complete when the file exists at the assigned path. That is a path check, and it was the only check the skill ever asked for on the HTML.
- Nothing barred the coordinator from reviewing. The gap was that nothing required it, so a defect list read like diligence.

## Related Artifacts

- Epic `MENTAL-ALIGN-V2`, Items 3 and 4 — the coordinator/synthesis step and the render paths this change amends.
- `.project/active/render-switch-feedback/` — the design that built Steps 5–9 (now 6–10). Its step numbers are a historical record and were deliberately not rewritten.
- `.project/active/directory-skill-build-pattern/` — ADR 0011 and the `harness-block` adapter this change had to stay compatible with.
- Transcript of the run that surfaced the failure: `.project/mental-alignment/runs/20260825-075304_lofi-runner-architecture.md` (the synthesis under review).

## Changes

One source file: `claude-pack/skills/_my_mental_model/SKILL.md`, 290 → 369 lines. Regenerated output: `dist/codex/skills/my-mental-model/SKILL.md` and `dist/codex/manifest.json` (build stamps only).

### Role paragraph (`SKILL.md:12-17`, new)

Adds the accountability statement. The coordinator owns the quality of everything that reaches the owner; it never writes content, which is "a constraint on your hands, not on your accountability"; its lever is the executing agent. The owner sees a defect the coordinator already found only after it was sent back and the agent could not fix it. Closes on "Flagging is not a substitute for fixing when you control the next step."

### Step 3, "Read the standard first" (`SKILL.md:67-76`, new subsection)

The coordinator reads `design_synthesis.md` and both feedback files itself before composing the spawn prompt. Previously it pointed the synthesis agent at files it had never opened, so it had no standard to review against.

### Step 4, "Review the synthesis" (`SKILL.md:108-134`, new step)

Sits between the spawn and the owner pause. The `read-synthesis-file` harness block moved here from the old Step 4 — same key, no adapter change. Checks against three named sources: `design_synthesis.md` (four regions, the narrative-body standard, the four named failures), the feedback files (a recorded lesson is a rule for this run), and the project writing rules already in context.

Two guardrails. **Sweep, don't spot-fix**: one instance found means the whole class gets checked before anything is sent back. **Enforce the standard, not your taste**: a violation of something written down goes back to the agent, while a disagreement about the content's judgment is not a defect and goes to the owner at the pause.

### Step 5, "The correction gate" (`SKILL.md:136-164`, moved up from old Step 5 and generalized)

Now runs twice — on the coordinator's findings before the owner sees the synthesis, on the owner's corrections after. Same mechanism both times. Owner corrections go back in the owner's own words; the coordinator's own findings name the rule, list the instances, and ask for the class to be swept.

"You never write synthesis content" and the unreachable-agent-stops-the-run rule are unchanged. Added a two-round limit: after two rounds on the same defect, stop sending and tell the owner what is still wrong and what was asked for. "Looping is not enforcing."

### Step 6, "Present the synthesis and pause" (`SKILL.md:166-191`, old Step 4 minus the read)

Presents the reviewed synthesis. Render options, clean-room render default, and the feedback offer are unchanged. Owner corrections loop back to Step 5, then on to Step 7.

### Step 7, "Confirming a render" (`SKILL.md:250-276`, rewritten)

File-exists is demoted to what it is — "bookkeeping, not confirmation." The coordinator then reads the HTML and checks it against `visualize.md`: the one failure that matters applied section by section, the output shape rule, the hard safety limits, and provenance carried through. Defects go back to the agent that wrote that render, addressed to the handle recorded at dispatch, with the same two-round limit. The owner gets the link when the coordinator would stand behind the page.

Also added to "The render brief" (`SKILL.md:224-225`): read `visualize.md` and the HTML feedback files before dispatching, for the same reason as Step 3.

### Renumbering

Old Steps 4–9 became 5–10. Cross-references updated at `SKILL.md:25` (promotion, Step 9 → 10), `:187` (feedback format, Step 9 → 10), `:222` (clean-room override, Step 4 → 6), `:247` (readings, Step 7 → 8), `:315` (feedback offer, Step 4 → 6). No file outside `SKILL.md` references the skill's step numbers.

## Validation

- **Step integrity.** `grep -n "Step [0-9]"` over `SKILL.md`: ten step headings present in order, every cross-reference resolves to the right step, no stale number.
- **`./scripts/test_codex_orchestrator_pack.sh`** — 11 checks pass, including "harness blocks substituted across the tree" (the scan that fails on any unsubstituted marker reaching dist, and on `SendMessage` or `subagent_type` appearing in the dist `SKILL.md`).
- **`./scripts/test_docs.sh`** — all checks pass.
- **Adapter output inspected by hand.** All seven new requirements survive into `dist/codex/skills/my-mental-model/SKILL.md` (they were kept outside `harness-block` spans by design). No `SendMessage`, `subagent_type`, or `harness-block` marker leaked. `followup_task` and `fork_turns` substituted correctly, including the `fork_turns: "none"` the clean-room policy depends on.
- **Installs refreshed.** `./scripts/build-codex-pack.sh` then `./scripts/setup-codex.sh --copy`; `~/.agents/skills/my-mental-model/SKILL.md` confirmed carrying the new steps. Claude needed nothing — `~/.claude/skills/_my_mental_model` is a directory symlink.
- **`build-codex-pack.sh` untouched.** The render send-back points at Step 5's mechanism rather than naming a tool, so no new harness-block key was needed.
- **Not validated: a live run.** No end-to-end `/_my_mental_model` invocation has exercised the new Step 4 or the render review. The behavior change is prose the coordinator follows, and nothing automated can test it. That is the same gap the skill has always had — the epic records "no automated checks anywhere" as a known design position.

## Notes

- **Depends on PR #32.** The `harness-block` machinery this edit relies on lives in commit `463366e` on `mental-model-codex`, which is still open as PR #32. `main` has no harness-block markers and no `CODEX_SKILL_HARNESS_BLOCKS` table, so this branch is based on `mental-model-codex` and its PR targets that branch, not `main`.
- **Line wrapping.** `SKILL.md` is hard-wrapped at ~100 columns, which conflicts with the markdown-authoring rule's one-line-per-paragraph requirement. The existing file and both sibling instruction files already use that convention, so this change matched it. Reformatting the file would have made every line a diff and buried the behavior change. Worth a separate pass if the rule should win.
- **Deliberately not covered.** No review beat on the Step 2 classification (owner call during the proposal). The Step 4 review does not touch the classification, only the synthesis.
