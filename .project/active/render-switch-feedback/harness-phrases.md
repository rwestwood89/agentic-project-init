# Harness-Specific Phrases Added by Item 4

**Status:** Complete for Item 4's authored files
**Owner:** Reid W
**Created:** 2026-08-20
**Source design:** `.project/active/render-switch-feedback/design.md` (D13, Implementation Notes)
**Consumer:** MENTAL-ALIGN-V2 Item 5 — `.project/active/directory-skill-build-pattern/`

---

## What this is

ADR 0011 puts cross-runtime correctness in the Codex adapter, not in authored prose. So Steps 5–9 and
`visualize.md` are written in the pack's Claude-native vocabulary, and this file is the bookkeeping
that obligation creates: the list of harness-specific phrases Item 4 introduced, handed to Item 5 as
input to its substitution dictionary
(`scripts/build-codex-pack.sh:132-160`).

Nothing checks for this list. An unlisted phrase ships clean and surfaces only when the skill runs on
Codex — ADR 0011 accepts that, so the list is the only mitigation there is.

**Scope:** phrases *Item 4 added*. The seven pre-existing spots in Steps 1–4 are already tabled in
Item 5's spec (`.project/active/directory-skill-build-pattern/spec.md:143-153`). Item 4's edits above
line 87 replaced text line-for-line, so those seven line numbers are still correct.

## The phrases

| Where | Phrase | What it means, for translation |
|---|---|---|
| `SKILL.md:115` | "by name (`synthesis-{slug}`) using `SendMessage`" | Send a follow-up turn to a still-live named subagent. Codex's equivalent is Item 1's follow-up-task resume (`.project/active/codex-resume-spike/spike-findings.md`). |
| `SKILL.md:170` | "`SendMessage` to `synthesis-{slug}`" | Same mechanism, second use site — the resumed render dispatch. |
| `SKILL.md:171-172` | "the `Agent` tool with no `subagent_type` — … so never `fork`" | Spawn a fresh agent with a clean window. Same shape as the existing `SKILL.md:77-78` spot, which already fails the dist scan. |
| `SKILL.md:172` | "Name it `render-{slug}-fresh`" | Naming a subagent so it stays addressable. Pairs with the existing `SKILL.md:80` spot. |
| `SKILL.md:174` | "the wall clock at dispatch and at completion" | Lifecycle timing owned by the coordinator: when it sent the work, when the runtime signalled the agent was done. |
| `SKILL.md:183` | "a named agent's turn output does not reliably reach you" | A runtime fact about Claude (design Appendix A). Item 1 found the same on Codex, so the claim holds on both — but the phrasing is Claude's. |
| `SKILL.md:197, 206` | "what the runtime stated" / "Neither runtime reports a per-agent count today" | Already runtime-aware and true on both. Listed so the adapter leaves it alone rather than rewriting it into a Codex-only claim. |

## Phrases added by Item 6 (the reviewer pass)

Item 6 added two harness-block spans to `SKILL.md`, both registered in `CODEX_SKILL_HARNESS_BLOCKS`
(`scripts/build-codex-pack.sh`). Unlike the Item 4 rows above, these substitute rather than ship
Claude wording, so the table records what each span means rather than what needs translating later.

| Where | Phrase | What it means, for translation |
|---|---|---|
| `SKILL.md` Step 4, `harness-block: reviewer-spawn` | "the `Agent` tool with no `subagent_type` … and `model: \"sonnet\"`" | Spawn a fresh agent on a chosen model. Codex's equivalent is `spawn_agent` with `fork_turns: "none"` plus `model`, which is valid only alongside `"none"` or a turn count. The size is load-bearing, not incidental: the Phase 1 fixture runs showed a small model matches stated rules and does not match recorded examples, so the Codex text says "a mid-size model" rather than "the smallest available". |
| `SKILL.md` Step 4, `harness-block: notes-relay` | "`SendMessage`, addressed to the handle you recorded at its spawn or dispatch" | Send a follow-up turn to a still-live named subagent. Same mechanism as the Item 4 correction and resumed-render rows; third use site. The sentence it carries is fixed text and must survive substitution intact. |

`review.md` needs no entries. Like `visualize.md`, the reviewer's instruction file names no tool and
no agent mechanic — it is about what to read, what to look for, and what to write — so it reads the
same on either runtime.

## `visualize.md` needs no entries

The render agent's instruction file names no tool and no agent mechanic. It is about what to read,
what to add, and what not to do — all of which reads the same on either runtime. That is a property
of the file, not a rule for future ones: an instruction file that has to name a tool should name it,
and add a row here.
