---
name: my-audit
description: Certify a work item or epic: evaluate code against plan/spec/design, update checkboxes, write audit.md. Use after implementation is complete.
---

Generated from `claude-pack/commands/_my_audit.md`. This is a command-derived Codex skill. Rebuild it instead of editing it by hand.

# Audit Command

**Purpose:** Certify a work item or epic — evaluate code against upstream artifacts, write findings, update tracking checkboxes
**Input:** Work item name (folder in `active/`) or epic name (file in `backlog/`)
**Output:** `active/{item}/audit.md` and updated checkboxes in plan, spec, and epic

## Overview

You are a certification agent. Your job is to evaluate whether code delivers what was specified, write your assessment, and update tracking artifacts to reflect what you verified.

Two scopes:
- **Work item** (``my-audit` {item}`): evaluate one item against its plan, spec, and design.
- **Epic** (``my-audit` {epic}`): review all items in an epic and assess against source documents.

When invoked:
- If an item or epic name is provided, determine the scope and start.
- If not, ask what to audit.

---

## Work-Item Scope

### 1. Read upstream artifacts

Read everything available for this item:
- **Plan:** `.project/active/{item}/plan.md` — phases, checkboxes, deviation notes.
- **Spec:** `.project/active/{item}/spec.md` — success criteria, tagged requirements (`[HARD]`, `[NEED]`, `[INFERRED]`), non-goals.
- **Design:** `.project/active/{item}/design.md` — core concept, key bets, key decisions, required invariants, architecture.
- **Epic:** the parent epic in `.project/backlog/` if this item belongs to one.

Adapt to what exists. Spec is required — refuse to audit without one. Plan and design are optional; skip the corresponding evaluation area if they don't exist.

### 2. Evaluate

Use `Task` tool with `subagent_type=Explore` for broad code searches. Four areas:

#### Plan completion
Are all phases done? For each phase, verify the changes-required and validation items are genuinely complete. Flag placeholder code, TODOs, and partial implementations.

#### Spec conformance
For each success criterion and tagged requirement: does the code deliver it? Trace through the implementation with `file:line` references. Flag gaps, partial implementations, and requirements claimed done but not actually met. Check that non-goals were respected — nothing out of scope was built.

#### Design conformance
Does the code follow the architecture, key decisions, and required invariants? Are components where the design placed them? Were decisions actually followed or silently deviated from? Flag undocumented deviations.

#### Code integrity

**Abstraction quality (slop detection).** Flag these as design problems to fix now, not nitpicks to defer:

- God functions with implicit modes — one function doing 2+ unrelated jobs selected by a sentinel parameter. Telltale: parameters that only matter in some branches, or a signature you can't summarize in one sentence without "or."
- Policy in utilities — a utility making decisions about warnings, clipping, fallbacks, or defaults that should live at the call site.
- Parameter sprawl — a parameter list that accreted to serve multiple callers instead of each caller getting the function it needs.
- Leaky names — function name implies a narrow operation but implementation handles several.
- Deep nesting (3+ levels), copy-paste siblings, contract not readable from signature.

**Failure honesty.** Fallbacks and defensive defaults are how bad designs survive:

- Silent fallbacks on invariant violations — code that implies "something upstream broke" but returns a safe default instead of raising.
- `try/except Exception: return default` — broad excepts that swallow errors. Ask: what specific exception is handled, and why is every other one also OK to ignore?
- Backwards-compatibility shims with no current caller.
- Optional parameters papering over missing data — `foo=None` defaults that let callers skip data they should have.

For each finding: name `file:line`, say what's wrong, say what should change. Don't draft the fix.

**Check auto-memory** (`feedback_*` entries) for project-specific patterns previously rejected. Respect those as hard constraints.

### 3. Write audit.md

Write `.project/active/{item}/audit.md`:

```markdown
# Audit: [Item Name]

**Verdict:** Certify | Needs Work
**Audited:** [Date]
**Branch:** [Branch]
**Commit:** [Short hash]

---

## Summary

[2-3 sentences: overall assessment. What's solid, what's not.]

## Findings

### Plan completion
[Findings or "All phases verified." Each finding: file:line, what's wrong.]

### Spec conformance
[For each success criterion: verified or gap. For each tagged requirement: met or not.
 Keep it concise — one line per item when verified, a paragraph when there's a gap.]

### Design conformance
[Findings or "Implementation follows design." Flag deviations.]

### Code integrity
[Slop and failure-honesty findings, or "No issues found."]

---

## Certification

[List what was checked and what was marked. If partial, explain what's left open.]
```

### 4. Update tracking artifacts

Only mark what you verified. Partial certification is valid.

- **Plan:** mark `- [ ]` → `- [x]` for phases verified as complete.
- **Spec:** mark success criteria `- [ ]` → `- [x]` for criteria verified as met.
- **Epic:** if all spec success criteria pass, append ✅ to the item heading in the epic file and mark the item's success/done-state checkboxes `- [x]`. If partial, leave the heading as-is and note which checkboxes were marked.
- **CURRENT_WORK.md:** update the item's status to "certified" or "needs work — [summary of gaps]."

---

## Epic Scope

### 1. Read the epic and source documents

Read the epic file in `.project/backlog/`. Read the Source Documents listed at the top — these are the concept, concept-design, and research files the epic was built from.

### 2. Check item-level certification

For each backlog item in the epic:
- Does `active/{item}/audit.md` exist?
- Is the verdict "Certify" or "Needs Work"?
- Flag items without audits or with "needs work" verdicts.

If any items are uncertified, report the gaps and stop. Epic certification requires all items to pass first.

### 3. Assess against source documents

Read the Source Documents and answer: does the delivered work fulfill the original shaping-tier intent? This is a higher-level assessment than item-level audit — it checks whether the whole adds up to what the concepts and research envisioned.

Flag gaps where the shaping intent was lost, narrowed, or deviated from without justification.

### 4. Certify the epic

- Mark epic success criteria `- [ ]` → `- [x]` for criteria verified as met.
- Update CURRENT_WORK.md with the epic's certification status.
- Report the assessment to the user.

---

## Guidelines

- **Verify, then mark.** The audit.md is the evidentiary record. Write it before updating checkboxes. Never mark what you haven't verified.
- **Be skeptical.** Implementations often claim to satisfy requirements without doing so. Read the code; don't trust function names or comments alone.
- **Be proportional.** A simple item gets a short audit. A complex item gets a thorough one. Don't pad findings.
- **Findings need locations.** Every issue includes `file:line`, what's wrong, and what should change. No vague "this area could be improved."

---

**Related Commands:**
- Before audit: ``my-implement`` to complete plan phases
- After audit: ``my-pre-pr`` for automated quality checks, then ``my-close`` to archive

**Last Updated**: 2026-07-01

