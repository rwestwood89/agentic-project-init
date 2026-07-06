# Spec: Spike and Learning-Test Commands

**Status:** Implementation Complete
**Owner:** Reid W
**Created:** 2026-07-02 09:02
**Complexity:** MEDIUM
**Branch:** workflow-orchestrator

---

## Problem

Workflow v2 is top-down: need → architecture → work items → design → implement. That
sequence assumes "how things work" is known before you plan on top of it. It breaks down
when the mechanism is unclear — an unfamiliar package or tool, an opaque data format (an
AST whose exact structure is unknown), or an ambitious build carrying unknown-unknowns. In
those cases the right move is to stop planning and write throwaway code to learn how the
thing actually behaves.

The toolkit has no packaged command for this. `/_my_research` is the closest, but it is
read-only: it spawns Explore agents to analyze *existing* code and docs. It never writes
code to probe how something behaves. And nothing in the pipeline prompts an agent, mid-flow,
to notice uncertainty and de-risk with hands-on code. The result is that agents spec, plan,
and design on top of unverified assumptions, so unknown-unknowns surface late — during
implementation, where they are most expensive to absorb.

Two distinct hands-on techniques close this gap, and they differ enough to be separate
commands:

- **Spike** — a throwaway script to de-risk a *known* goal. You have a specific assumption to
  confirm and want to be sure you're not missing something. The script is scratch code; it gets
  thrown away once the question is answered.
- **Learning test** — a real test written to *discover* how an unfamiliar surface behaves. The
  goal is open-ended; you're mapping the surface to understand it. The output is a test that
  lives in the repo's own test suite, not scratch code.

The split is along two axes at once: **intent** (de-risk a known goal vs. discover an unknown
surface) and **output** (throwaway script vs. kept test). That's why they're separate commands,
not one with a mode.

## Success Criteria

- [x] A **spike** command exists, is symlinked into `~/.claude/`, and is available in sessions.
- [x] A **learning-test** command exists, is symlinked, and is available in sessions.
- [x] The spike command writes throwaway probe scripts plus a findings doc into the active
      work-item folder when one is in play; otherwise it creates `active/spike-{topic}/` and
      writes both there.
- [x] The learning-test command produces a findings doc and *real tests* — tests placed where
      the repo already keeps its tests, not scratch scripts and not under `.project/`. The command
      does not hardcode a path; the executing agent locates the repo's test directory.
- [x] On completion, both commands close the loop: the executing agent writes a reference to its
      findings report back into whatever upstream doc triggered the work (concept, spec, epic), so
      the learning re-enters the pipeline instead of dead-ending in a standalone report.
- [x] Each command makes its use case unmistakable: spike = clear goal, verify/de-risk;
      learning test = fuzzy goal, probe a surface to understand it.
- [x] Pipeline commands suggest the right technique at the right moment: `/_my_concept_design`
      (de-risk an architectural bet before planning an epic), and `/_my_spec` and `/_my_design`
      (when the agent observes high ambiguity or uncertainty).
- [x] `CLAUDE.md` and `README.md` document both commands and when to reach for each.
- [x] Both commands are exposed to Codex: added to `COMMAND_SKILL_DESCRIPTIONS`, then built
      and installed.

## Known Requirements

- **[HARD]** New commands are not available in other sessions until `./scripts/setup-global.sh`
  runs to create the `~/.claude/` symlinks.
- **[HARD]** Each new command needs a description override in `COMMAND_SKILL_DESCRIPTIONS`
  (`codex-overrides/config.sh`), then `./scripts/build-codex-pack.sh` followed by
  `./scripts/setup-codex.sh --copy`. Skipping the override is treated as a defect, not an option.
- **[NEED]** Spike scripts live with the work item: the active work-item folder if one exists,
  otherwise a command-created `active/spike-{topic}/`. The findings doc lives beside the scripts.
- **[NEED]** The learning-test command produces actual tests placed in the repo's existing test
  location. The command prompt tells the executing agent to find where the repo keeps its tests
  rather than hardcoding a path or writing under `.project/`.
- **[NEED]** Both commands close the loop. On completion the executing agent writes a reference to
  the findings report back into the upstream doc(s) that motivated the work (concept, spec, epic).
  The learning must re-enter the pipeline, not sit in an orphaned report.
- **[NEED]** The pipeline references are *suggestions the agent offers*, not mandatory gates.
  The pipeline commands prompt the agent to notice when hands-on de-risking is warranted and
  offer it; they do not block the pipeline.
- **[INFERRED]** Both commands follow existing `_my_*` conventions: the Purpose/Input/Output
  header, a staged process, and a Related Commands footer.
- **[INFERRED]** Wiring targets beyond the user's list, to confirm at review:
  - `/_my_epic_plan` — a de-risking spike can be surfaced as an early pre-work item or a first
    phase when an epic carries an unverified bet.
  - `/_my_research` — cross-reference the other direction: research is read-only analysis; when
    you need to *write code* to learn how something behaves, reach for spike or learning test.

## Non-Goals

- Not changing the core pipeline stages, and not making de-risking a mandatory gate.
- Not prescribing where kept learning tests live in a given project's test layout — that is
  per-project and decided at execution.
- Not building runtime machinery to run, track, or clean up spikes automatically. These are
  command/prompt definitions, not tooling.

## Open Questions / Deferred to design

- **Command names.** Working assumption `/_my_spike` and `/_my_learning_test`; confirm at design.
- **Learning-test findings-doc location.** `.project/research/` (investigation output, not
  tied to a work item) versus the work-item folder. Leaning `research/`; decide at design.
- **Exact prompt wording and placement** of the suggestion inside each pipeline command —
  where in `concept_design` / `spec` / `design` it fires, and how the trigger is phrased so it
  distinguishes the spike case from the learning-test case.
- **Interaction with `/_my_close`.** Spike scripts in a work-item folder get archived when the
  item closes (probably fine — they travel with the item); confirm this is the intended fate.

---

## Related Artifacts

- **Epic:** none — standalone work item. Could be promoted to an epic if the wiring grows.
- **Design:** `.project/active/spike-and-learning-test-commands/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`. Consider `/_my_spec_review` first
for an adversarial pass, since this spec drives changes across several pipeline commands.
