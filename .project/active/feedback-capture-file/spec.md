# Spec: Feedback Capture File

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-08-25 09:16
**Complexity:** LOW
**Branch:** mental-model-codex

---

## Problem

When the owner works an agent through several rounds to get a better artifact — pushing back on a spec, re-steering a design, rejecting a voice — the lesson exists only in that chat. Getting it into the command that produced the artifact means the owner remembering it later, in a different session, and translating it upstream by hand without the context that produced it. Most lessons don't survive the trip.

The agent is in the best position to record it: it is holding the correction, the artifact, and the reason at the moment the correction lands. Nothing today lets it write that down.

`/_my_mental_model` solved this for itself with two-tier feedback files and a promotion path (`claude-pack/skills/_my_mental_model/SKILL.md` Step 9). That mechanism is not the model here — the owner explicitly scoped this smaller. **[OWNER-VERBATIM]** "We do not need heavyweight machinery, literally just a fucking feedback file with a header so that I can say 'Given all these updates, please record your learnings as feedback in {file reference}'."

## Success Criteria

- [ ] In any repo with a `.project/`, the owner can ask the agent to record its learnings as feedback and the agent writes correctly formatted entries with no further instruction.
- [ ] Recording costs one small read. The agent never reads accumulated feedback in order to append to it.
- [ ] Every entry names the pack target it applies to.
- [ ] A line-oriented script can select all entries for a given target name without a markdown parser and without interpreting entry prose. Not built here — the format has to support it.
- [ ] Accumulated entries survive `scripts/init-project.sh --force`.
- [ ] A plain re-init of an existing project (`agentic-project-init`, `teasp-workspace`) picks up both files without disturbing anything else.

## Known Requirements

- **[NEED]** Two files, separate: one carrying the recording instructions, one carrying the entries. The owner's reason is the requirement — the agent must not have to read the whole entries file to record into it.
- **[NEED]** The instructions file is what the agent reads. It states the rules and names the entries file, so the owner's prose reference resolves to both.
- **[NEED]** Entries are appended. An existing entry is never rewritten.
- **[NEED]** Each entry is tagged with the **bare name** of the pack target — `_my_spec`, `_my_mental_model`, `working-voice` — with no folder path. Names are unique across `claude-pack/commands/`, `claude-pack/skills/`, and `claude-pack/rules/`; verified 2026-08-25, zero collisions between the installed command and skill namespaces.
- **[NEED]** The format is readily parseable, so going from "commands don't read feedback" to "a script filters feedback by command name" requires no rework of entries recorded before the script exists.
- **[HARD]** The entries file must be added to `USER_DATA_FILES` in `scripts/init-project.sh:117`. Without it, `--force` overwrites accumulated feedback with the empty template.
- **[HARD]** The instructions file must *not* be user data, so `--force` propagates improved rules to existing projects. This is the split's second payoff and it falls out of the same list.
- **[INFERRED]** One tag per entry. Feedback that applies to two targets is written as two entries — a single tag per entry is what keeps the future filter a one-line match.
- **[NEED]** An entry has two parts. First the specific error: what the agent did wrong and what the corrected version was. Then a generalized learning drawn from it — specific enough to be actionable, general enough to apply in many or most cases, not just the case that produced it.
- **[NEED]** The generalization is the agent's job, done at record time while it still holds the context. The owner is not transcribed and not quoted; the wrong/corrected pair carries the specifics instead.
- **[INFERRED]** Both files ship in `project-pack/` so `scripts/init-project.sh` seeds them on init and merges them into existing projects.

## Non-Goals

- **Commands do not read feedback.** Decided this session: the file exists so the owner can fix the commands upstream, and once fixed the entry is dead. Two sources of truth for how a command behaves is the failure mode being avoided. Revisiting this is the explicit "no → yes" step the format must not block.
- **No filter script.** It arrives with the "yes" step, if that step ever happens.
- **No promotion mechanism, cross-repo inbox, or global tier.** Considered and dropped as heavier than the problem.
- **No trigger command.** The owner asks in prose; there is no `/_my_feedback`.
- **No Codex build work.** `project-pack/` is copied by `scripts/init-project.sh` and is not part of `scripts/build-codex-pack.sh`, so both files reach a Codex session through the same `.project/` directory with no adapter changes.
- **`/_my_mental_model` keeps its own feedback files.** Not converted, not deprecated, not touched.

## Open Questions / Deferred to design

- The exact entry syntax. The constraint is fixed (line-oriented selection by tag, no markdown parsing, append-only); the delimiter and field spelling are not.
- File names and location — `.project/` root versus a `.project/feedback/` directory. Affects what the owner types when referencing it in chat, which is the only real criterion.
- How much the instructions file says about *how to generalize well* versus only *how to format*. The two-part entry shape is settled; how much coaching the agent needs to hit the right altitude on the generalization is not, and every line of coaching is a line read on every recording.
- Whether `project-pack/README.md`'s Key Files table and `scripts/test_docs.sh` need entries for the new files.

---

## Related Artifacts

- **Epic:** none — standalone item
- **Research:** none
- **Product lens:** not run — see Next Steps
- **Design:** `.project/active/feedback-capture-file/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design` — or straight to implementation if the open questions settle in review.
