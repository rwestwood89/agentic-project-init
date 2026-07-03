# Spec: Pipeline Guide (shipped, canonical)

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Complexity:** MEDIUM
**Branch:** workflow-orchestrator (candidate for its own branch)

---

## Problem

There is no up-to-date, canonical description of the pipeline available at runtime where consumers
need it. Discovered while building the workflow-orchestrator command: an agent running in a target
project has nothing current to point at.

What ships today:
- **`claude-pack/` → `~/.claude/`** (commands, hooks, agents, rules, scripts, skills): has **no
  pipeline overview** at all.
- **`project-pack/README.md` → `.project/`** per project: has a **partial, stale** flow
  (Spec→Design→Plan→Implement→"Review") — missing `audit`, `pre_pr`, `close`, and
  `concept`/`concept_design`/`product_design`, and it still lists retired memory commands.
- **`docs/guide.md`, `docs/working-with-claude.md`**: live in **this repo only** — not installed,
  not copied to target projects, so an agent elsewhere can't read them.

The result: every consumer either has nothing, or a wrong/partial flow, or duplicates a half-flow
inline (which then diverges — exactly what happened while drafting the orchestrator prompt).

## Success Criteria

- [ ] A single canonical overview+guide of the pipeline ships with `claude-pack` and is present at
      runtime in any project (installed to `~/.claude/`).
- [ ] It reflects the **current** pipeline, with no retired commands:
      `research`/`concept`/`concept_design` → `epic_plan` → `spec` → `spec_review` →
      [`product_design`] → `design` → `design_review` → `plan` → `implement` → `audit` → `pre_pr` → `close`.
- [ ] It is the **single source** other commands and docs point to for the flow — nothing duplicates
      the stage sequence inline.
- [ ] `project-pack/README.md`'s flow points at this canonical source instead of carrying its own
      stale version.
- [ ] An agent (e.g. the orchestrator) can reach the full guide at runtime, and every session has at
      least a lightweight awareness of the pipeline shape.

## Known Requirements

- **[HARD]** It must ship through a `claude-pack/` subdir that `setup-global.sh` already installs
  (`rules/`, `commands/`, `agents/`, `hooks/`, `scripts/`, or `skills/`) — a plain top-level doc would
  not install without changing the installer.
- **[NEED]** **Hybrid delivery (decided with the user):** a short always-on **rule** carrying the
  pipeline *shape* plus a pointer, and a richer on-demand artifact carrying the full overview+guide.
  Always-on awareness, on-demand depth, no per-session context bloat.
- **[NEED]** The on-demand artifact is a **user-invocable command** (`/_my_pipeline`), not a skill.
  A command installs with no installer change (`commands/*.md` is already symlinked), is human-invokable,
  and is reachable by an agent (by path via the rule's pointer, or through the Skill tool). Chosen over
  a skill, which would need `setup-global.sh` to symlink skill directories — a change that brushed a
  non-goal — for only marginal auto-invocation benefit the always-on rule already covers.
- **[NEED]** The always-on rule stays lightweight — it is context weight on every session, including
  ones unrelated to the pipeline.
- **[NEED]** The command carries both an **overview** (the stage map — order, entry points, optional
  stages, the review pairings, the epic-vs-single-item branch) and a **guide** (when/how to use each
  stage).
- **[NEED]** For per-stage detail, it points at each command's own doc rather than restating it, so
  the guide can't drift from the commands.
- **[INFERRED]** The rule and the command must not duplicate the flow between themselves either — the
  rule carries only the bare stage shape (for always-on awareness); the command is the fuller source.
  The bare shape is the one unavoidable duplication; a check keeps the two in sync. One place per fact
  otherwise, or we reintroduce the divergence this item exists to kill.

## Non-Goals

- Not rewriting `docs/guide.md` or `docs/working-with-claude.md` (repo-only human onboarding docs).
  Aligning them with the canonical source is possible future work, not this item.
- Not changing what `setup-global.sh` installs — use the existing `rules/` + `skills/` mechanism.
- Not building the orchestrator command (separate item); this is the source it will point at.

## Open Questions / Deferred to design

- The exact split: what minimal content lives in the always-on rule vs. the command.
- How the flow stays in sync with the commands over time — a check/test, or convention. (The item's
  whole value is being *canonical and current*, so how it's kept current matters.)
- How `project-pack/README.md` references a `~/.claude/`-installed artifact cleanly (it lives in
  `.project/`, the rule/command live in `~/.claude/`) — by name, path, or a short restated pointer.
- Naming of the rule and the command.

---

## Related Artifacts

- **Motivating consumer:** `.project/active/workflow-orchestrator/` (the orchestrator command points here)
- **Stale doc to rewire:** `project-pack/README.md`
- **Existing human docs (out of scope, for reference):** `docs/guide.md`, `docs/working-with-claude.md`
- **Design:** `.project/active/pipeline-guide/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
