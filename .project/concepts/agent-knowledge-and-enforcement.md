# Concept: Agent Knowledge Homes and Rule Enforcement

**Created:** 2026-09-08
**Status:** Draft — open questions resolved with the owner 2026-09-09; one remains, deferred by the owner.

---

## Problem Statement

The pack has three record registers with clean subject boundaries, and a fourth subject with no home. `.project/adr/` records decisions (12 entries, in real use). `.project/product/` records implemented promises (full machinery, zero entries, and `context-loading.md:6` sends every session to skim an `INDEX.md` that does not exist here). `.project/feedback/ENTRIES.md` records corrections to the pack's own prompts, tagged by pack target (zero entries in the 13 days since it shipped). Nothing records what an agent learned about the codebase or the environment while executing — the class of fact that makes the next session re-solve a solved problem. That gap was never considered and never rejected: "execution learnings" and "agent notes" appear nowhere in the repo, and the one mention of "execution notes" is a passing aside in an old review (`.project/research/20260419-081514_artifact-pipeline-alignment-review.md:348`).

Three abandoned slots gesture at the gap and none of them work. `_my_wrap_up.md:37-54` sends gotchas to `~/.claude/projects/*/memory/MEMORY.md` — outside the repo, untracked, capped at 200 lines, with an eviction rule. `_my_close.md:98` reserves a `Lessons Learned` field in `completed/CHANGELOG.md` whose template default is literally `[TODO: Add lessons learned]`. `project-pack/CURRENT_WORK.md:35` reserves an "Any notable learnings" bullet that no command mentions. Meanwhile both memory stores are hidden: the native one is untracked by design, and `.project/memories/` is gitignored (`.gitignore:18`), empty (`index.json` is `{}`), and served by the pack's only wired hook.

What the hidden store actually holds is the evidence that shaped this concept. All five entries in this repo's memory directory are typed `feedback` — corrections about how the agent should work, not facts about the code. Of the four pack-target corrections, two were already fixed or dead and two are fixed directly in the pack; nothing migrates into the feedback log (`.project/active/retire-hidden-memories/spec.md`, *Why nothing migrates*). The fifth, the `setup-global.sh` symlink fact, is already documented in CLAUDE.md. So the population of genuinely homeless execution facts in this repo is zero — with the caveat the owner raised, that this repo is a meta-project about the pack and is the least likely place for such facts to arise.

The read side has its own problem, and it points the opposite way. Seven rule files, 263 lines, auto-load into every session in every project. The inventory research graded the pipeline's "understand the point" mechanisms and found 14 of them are plain instruction, which catch neither a wrong point nor a missing one (`.project/research/20260818-151200_anchor-on-the-point-inventory.md:245-258`). So most of that always-on budget buys exhortation, one rule file is untouched template boilerplate, and any new register agents must carry makes the same budget worse. Separately, `CURRENT_WORK.md` grows with no rule governing it: 60 lines at its first commit, 227 today, net upward across eight months. It has been trimmed exactly once, by a wrap-up acting on its own (commit `fd7edc68`, 2026-02-08). Nothing in the pack or the template says when that should happen.

## Owner's Words

The five threads, as raised:

- **[OWNER-VERBATIM]** "I'd like to think through the division of reponsibilities, and whether we want a place for generic \"learnings\" from agents to live."
- **[OWNER-VERBATIM]** "Let's kill hidden memories."
- **[OWNER-VERBATIM]** "with have ADR for architecture/design, and we have the \"PDR\" (product/) for intent and functionalities."
- **[OWNER-VERBATIM]** "Do we want a route for execution-related notes, so that agents can learn from experience and not keep solving the same problems across sessions?"
- **[OWNER-VERBATIM]** "We need to make calls on `/_my_wrap_up`. Reviewing CURRENT_WORK.md does seem like the last remaining use, although fwiw most agents are good about keeping it up to date."
- **[OWNER-VERBATIM]** "We need to figure out when and how CURRENT_WORK.md gets pruned. Right now it is a running timeline, at some point we need to delete old stuff."
- **[OWNER-VERBATIM]** "we should kill `example-rules.md`"
- **[OWNER-VERBATIM]** "as a general effort, at some point I'd like to see how we can turn \"rules\" into hooks+subagents. Basically, can we auto-trigger a dedicated, small subagent and then route any feedback to the main agent?"
- **[OWNER-VERBATIM]** "not all of them now" — **[AGENT]** read as: one shaping effort, worked as separate items.

The decisions, 2026-09-09:

- **[OWNER-VERBATIM]** "Agents tend to be REALLY BAD at what is worth saving for memories. especially execution facts. so I definitely DON'T want them writing to CLAUDE.md directly"
- **[OWNER-VERBATIM]** "my temptation would be \"D: just don't save durable facts\". But before deciding, I want to at least see *what they would save*."
- **[OWNER-VERBATIM]** "this is more of a test by which to judge whether creating the feedback loop is worthwhile at all"
- **[OWNER-VERBATIM]** on this repo as evidence: "I'm not sure if this repo's usage is a good indicator of \"usage\"."
- **[OWNER-VERBATIM]** on keeping completion history readable at boot: "the reason for including \"Recently Completed\" is that reading it gives a better picture of the state of things. Knowing we just edited something or closed out an epic could be super helpful context."
- **[OWNER-VERBATIM]** on cutting wrap-up's docs step: "this encourages slop on documents that are valued to stay tight (unlike \"feedback\" and \"changelog\" which are cheap record). changes to docs happen through the work item lifecycle."
- **[OWNER-VERBATIM]** on killing the transcript stack: "context windows are now 1M so I almost never fill them"; "compaction works way better than it used to"; "the capture, memorize, recall were all used to compensate for accidentally running out of context and hating the autocompaction"

Inherited owner statements that bind this concept:

- **[INHERITED: .project/concepts/mental-alignment-checkpoint.md:369]** "I need git tracking. 95% of the time the feedback an agent writes is REALLY bad and needs a revision to be generalized and useful."
- **[INHERITED: .project/completed/20260826_feedback-capture-file/spec.md:17]** "We do not need heavyweight machinery, literally just a fucking feedback file with a header so that I can say 'Given all these updates, please record your learnings as feedback in {file reference}'."
- **[INHERITED: .project/adr/0001-decision-records-convention.md:26]** no current-state doc maintenance — "waste of tokens and will never actually work."

## Success Criteria

When this work is complete:

1. **No agent-written knowledge lives outside git.** **[OWNER]** No pack instruction points at the native memory directory, `.project/memories/` is gone with its gitignore line, and this repo's native memory files are deleted. Nothing is migrated into `.project/feedback/ENTRIES.md`: of the four hidden entries, checked one by one, two were already fixed or dead and two are fixed directly in the pack instead (`.project/active/retire-hidden-memories/spec.md`, *Why nothing migrates*).
2. **The pack has no hooks and no transcript tooling.** **[OWNER]** `_my_capture`, `_my_memorize`, `_my_recall`, `_my_review_compact`, `capture.sh`, `precompact-capture.sh`, `parse-transcript.py`, `query-transcript.py`, the `recall` agent, both PreCompact registrations, and `.hook-paths.json` are all removed.
3. **An agent that learns something durable has one named place to write it, and knows the place exists without being handed its contents.** **[OWNER]** The register ships with instructions and no read path.
4. **The register's write is prompted at `close` and at `wrap_up`, and nowhere else.** **[OWNER]** Not in an always-on rule, and not left to owner prose alone.
5. **`CURRENT_WORK.md` holds only Active Work and Up Next.** **[OWNER]** **Amended 2026-09-10, owner:** the operational half stands; the justification that followed it — "no section in it accumulates, so no retention rule is needed" — does not hold for Active Work, and the owner took the duty rather than a rule. Items entering and never leaving is **[OWNER-VERBATIM]** "the user's problem", made more visible by a shorter file, and entry depth keeps appending a bullet per session (**[OWNER-VERBATIM]** "A keep it like today"). See `.project/active/session-bookkeeping/spec.md` Non-Goals.
6. **Session boot still shows recent completions, at bounded cost.** **[OWNER]** The boot read covers `CURRENT_WORK.md` plus the newest entries of `completed/CHANGELOG.md`, and the bound does not grow with the file.
7. **`wrap_up` writes records and never documents.** **[OWNER]** It writes `CURRENT_WORK.md`, a light CHANGELOG entry for work that skipped `close`, and an execution note when there is one. It does not touch `docs/`, and it does not commit without being asked.
8. **`example-rules.md` is gone** **[OWNER]** — from `claude-pack/rules/`, from `~/.claude/rules/`, and from the generated `dist/codex/AGENTS.md`.
9. **The test yields a judgement.** **[AGENT]** After a period of real use across more than one project, the register's contents answer whether agents save anything worth reading — and therefore whether a read path is worth building at all.

---

## Why This Shape

- **The bet: measure before building the expensive half.** A register that nothing reads is cheap to ship and cheap to abandon. A read path — a checker subagent, a discovery instruction, an index — is the expensive half, and it is only worth building if agents write things worth reading. So the write ships first, alone, and its contents decide whether the rest happens.
- **Why this shape is promising:** it converts the failure mode of the existing registers into the measurement. Two of three registers here sit empty, and an empty register is only a failure when something was counting on the loop. Here, emptiness is a result: it says agents had nothing to save, or would not save it unprompted. Junk is also a result. Four good facts is a result. Every outcome answers the question the owner actually asked, and none of them require the read path to exist first.
- **Why not put the facts in CLAUDE.md:** owner-stated, and it is the constraint that rules out the cheapest option. Agents judge durability badly, CLAUDE.md is auto-loaded, and it has no lifecycle — so a bad entry there costs every session forever.
- **Constraint to preserve downstream:** the 95% rule. Agent-written learnings are mostly bad and gain authority only after owner review, so the register is git-tracked, append-only, and owner-promoted. Nothing reads it back until the owner decides it has earned a reader.
- **Second constraint:** trigger design predicts use, and the evidence is in this repo. ADR attaches its write to `/_my_close`, a gate an item cannot skip, and has 12 entries. The feedback log attaches its write to owner prose and has 0. That is why the register's write sits at `close` and `wrap_up` rather than in a rule or in the owner's hands.

---

## User Stories

### Recording

**US-1: Record an execution fact where it will be found**
As an agent that just rediscovered something the code does not make obvious, I can write it to one named place with a provenance line, so the next session does not rediscover it.

**US-2: Know which register to use**
As an agent holding a fact, I can tell in one read whether it is a decision, a promise, a pack-prompt correction, or an execution fact, so I do not file it in three places or none.

**US-3: Never write knowledge the owner cannot see**
As the owner, every learning an agent records lands in a tracked file I can review in a diff, so I can rewrite the 95% that need rewriting before any agent treats them as authority.

**US-4: Judge the loop on evidence**
As the owner, I can read what agents actually chose to save and decide from that whether a discovery path is worth building, instead of guessing up front.

### Reading

**US-5: Boot from a file that is about now**
As an agent reading `CURRENT_WORK.md` at session start, I see current work, not eight months of completed history.

**US-6: See what just shipped without reading the whole archive**
As an agent orienting at session start, I see the most recent completions at a cost that does not grow as the archive does.

### Enforcement

**US-7: Get told what I missed while I can still fix it**
As an agent that just finished an artifact, I receive advisory notes citing the rules and recorded examples I missed, and I decide what to apply before handing the work on.

**US-8: Drop a rule without losing what it enforced**
As the owner, I can remove a rule from the always-on set and watch the check it was doing still happen, so shrinking the context does not mean lowering the standard.

---

## Key Concepts

### 1. The division of responsibilities

Four subjects, four homes, each with a boundary test against its neighbour.

- **Decision** — the chosen mechanism plus the reasoning a future challenge re-derives against. Home: `.project/adr/`. Test (existing, `.project/adr/README.md:17-18`): without the entry, would a future agent re-derive the wrong thing or relitigate?
- **Promise** — what the product guarantees, in plain language, once implemented. Home: `.project/product/`. Test (existing, `.project/product/README.md:20-24`): a major use case, public surface, or cross-cutting contract that a cold agent could reasonably miss or undo.
- **Pack-prompt correction** — the agent produced the wrong thing because a command, skill, or rule told it to. Home: `.project/feedback/ENTRIES.md`. Test (existing, by tag vocabulary): the subject is a pack target, and the fix is upstream in `claude-pack/`.
- **Execution fact** — how this codebase or environment actually behaves, learned by doing. Home: the new register. Candidate test, **[AGENT]**: a fact that cost real time to discover, that the code does not make obvious, and that will still be true next month.

The fourth is distinguishable from the other three by who acts on it. A decision constrains future design. A promise constrains future changes. A pack correction is fixed by the owner editing a prompt, and dies once fixed. An execution fact is consumed by the next agent doing similar work, and dies when the code changes.

### 2. Cheap records, tight documents

Owner-stated, and it is the test that decides what a session-scoped command may write. Records accumulate cheaply and tolerate a low bar: the feedback log, the changelog, the execution register. Documents are curated and expected to stay tight: `docs/`, CLAUDE.md, the rules. A record can absorb a mediocre entry; a document is damaged by one. So `wrap_up` may write records and never documents, and documents change through the work-item lifecycle instead.

### 3. Write-only, on purpose

The register ships with a write instruction and no reader. That is not an unfinished feature, it is the experiment: the owner's alternative to building the loop is not building it, and the only honest way to choose is to see what gets written first. Two consequences follow. The register's contents are the deliverable of this phase, not a byproduct. And item F — converting rules to automatic checks — no longer depends on the register at all, because there is no read path for a checker to feed from yet.

### 4. The trigger ladder

Four rungs, weakest to strongest, all present in the pack today.

- **Prose in an always-on rule** — skippable, and the inventory research found 14 of these catch nothing.
- **Prose in a command** — the product-lens call sites, the ponytail challenge. Runs when the command runs and the model complies.
- **An output that depends on the read** — a required Prior Art section. ADR 0002:24 calls this "the only read enforcement that works."
- **A harness event** — a hook. Runs regardless of model compliance. After item B the pack has none, and no hook it ever had injected text or spawned a subagent.

Item F is a proposal to move specific checks from rung one to rung four. What a hook can do here is unproven in this codebase, and the Codex hook path is dead code that would mislabel every event as `Stop` (`scripts/build-codex-pack.sh:589`).

### 5. Bound the read, not the file

`CURRENT_WORK.md` inherited append-only behaviour by accident, because the pack never separated current-state files from registers. The fix is not a prune rule. Cutting the file to sections that cannot accumulate, and bounding the history read to the newest N entries of the archive, gives the same orientation with no maintenance duty and nothing that can rot. A read bound is self-enforcing in a way a prune trigger never is, and it holds however large the archive grows.

---

## Scope of Behavior Changes

### New artifacts to create

- The execution-facts register: a directory with a README stating the density bar, the entry format, and the fact that nothing reads it. **[AGENT]** Whether it needs ids, a script, or an index is a design call; the inherited standard for the adjacent register was a file with a header.
- A write beat in `_my_close` and `_my_wrap_up`.
- A light CHANGELOG entry shape for the `wrap_up` path, distinct from close's structured entry.

### Existing artifacts to modify

- `claude-pack/rules/example-rules.md` — deleted.
- `claude-pack/rules/context-loading.md` — the auto-memory read at `:9` goes; the session-start read gains the bounded CHANGELOG entries.
- `claude-pack/commands/_my_wrap_up.md` — step 3 (auto-memory) and step 4 (docs) deleted; step 2 narrowed; CHANGELOG and execution-note beats added; step 6 becomes stage-and-show.
- `claude-pack/commands/_my_close.md` — gains the execution-note beat beside the existing ADR and promise scans.
- `claude-pack/commands/_my_implement.md:152` and `_my_audit.md:92` — both send the agent to read `feedback_*` auto-memory entries, a naming convention that was never used.
- `.project/CURRENT_WORK.md` and `project-pack/CURRENT_WORK.md` — Recently Completed and Session Notes removed, in the live file and the template.
- `project-pack/CURRENT_WORK.md:35` — the orphaned "Any notable learnings" bullet goes.
- `README.md:137` — the "Legacy (superseded by `/_my_wrap_up` + auto-memory)" section and all four commands under it.
- `docs/guide.md:136` — states wrap-up "Updates `.project/CURRENT_WORK.md` and auto-memory."
- `.claude/settings.json` and `~/.claude/settings.json` — both PreCompact registrations removed.
- `scripts/setup-global.sh`, `scripts/init-project.sh`, `scripts/uninstall-global.sh`, `scripts/uninstall-project.sh` — hook installation, `.hook-paths.json`, and hook removal all go.
- `codex-overrides/config.sh` — `EXCLUDED_COMMANDS` (`:6`), `EXCLUDED_AGENTS` (`:13`), and `EXCLUDED_HOOKS` (`:17`) all shrink to empty or near-empty as their targets are deleted.
- `scripts/build-codex-pack.sh` — the dead hook-translation path can go with the hooks.

### Behavior changes by workflow stage

- **Session start:** one fewer rule file, no auto-memory read, a shorter `CURRENT_WORK.md`, and a bounded read of recent completions.
- **During implementation:** an agent that learns something durable has a place to put it, though nothing hands it existing entries.
- **Close:** gains the execution-note beat; ADR and promise scans unchanged.
- **Wrap-up:** narrower in subject, two new write duties, no docs, no unprompted commit.

---

## Non-Goals / Out of Scope

- **[OWNER]** A read or discovery path for the new register. Out of scope by design: the write ships alone so its contents can decide whether a reader is worth building.
- **[OWNER]** Agents writing execution facts into CLAUDE.md. Out of scope because agents judge durability badly and CLAUDE.md is auto-loaded with no lifecycle.
- **[OWNER]** Keeping any part of the transcript stack, recall included. Out of scope: it existed to compensate for running out of context and disliking autocompaction, and 1M context windows plus better compaction removed the need.
- **[OWNER]** Backfilling the nine completed entries that have no CHANGELOG counterpart. Out of scope: they are eight months old and reachable from git log and the `completed/` folders.
- **[OWNER]** An ADR for wrap-up's new write duty. Out of scope: recorded here instead, as the reasoning below.
- **[AGENT]** A general-purpose hook framework. Out of scope: one converted check is the unit of evidence, and the mechanism is untested in this codebase.
- **[INHERITED: .project/completed/20260826_feedback-capture-file/spec.md:49]** Converting `/_my_mental_model`'s own feedback files to the new register. Recorded when the feedback log shipped: "Not converted, not deprecated, not touched." Inherited rather than settled, so challengeable if the register's shape makes revisiting it worthwhile.

### Note for reviewers: wrap-up's write duty

ADR 0002 and ADR 0008 both rejected giving `_my_wrap_up` a write duty, on the grounds that "optional-stage write duties defeat the control." Giving it the CHANGELOG and execution-note writes is a deliberate departure, agreed with the owner on 2026-09-09, and does not need a new ADR. The reasoning: those entries were protecting load-bearing records, where a skipped write loses a decision permanently. A skipped execution note costs nothing, and observing what gets written when nobody forces it is the point of the exercise. The ADR touch-point map for decisions and promises is untouched.

---

## Assumptions & Prerequisites

- The owner reviews and rewrites agent-written entries before they carry authority. Without that step, the 95% rule makes the register a liability.
- The register is exercised in projects beyond this one. This repo is a meta-project about the pack and generated zero homeless execution facts in eight months, so a test confined to it would measure the wrong thing.
- For item F only: Claude Code hooks can inject text or spawn a subagent whose findings reach the agent. **Unverified in this repo.** The inventory research called the prompt handler "sparsely documented, untested" (`:382`), and gave the agent handler — the option item F needs — a different set of costs: "expensive (full subagent per stop), slow (60s timeout), same LLM-judging-LLM limitation, poorly documented output schema" (`:392`).
- For item F only: a mid-size model is the floor for a checker subagent. ADR 0012's amendment records six planted-fixture runs where haiku never cited a recorded example and sonnet cited three by name.

## Open Questions

1. **How small can the checker subagent be, and what does it check first?** Deferred by the owner — item F is "at some point," not now. The owner asked for a "small" subagent; the inherited evidence says small was not enough for the mental-model reviewer's job. That may be job-specific, since matching prose against a rule list is easier than matching an artifact against recorded examples. Needs a spike, not an argument. Which rule to convert first is also open: `markdown-formatting.md` is the most mechanically checkable, `working-voice.md` the highest value and the hardest.

---

## Next-Stage Handoff

**Settled here:**

- **[OWNER]** `example-rules.md` is deleted.
- **[OWNER]** Hidden memories are killed, and so is the whole transcript stack — capture, memorize, recall, review-compact, both Python tools, the hook, and the hook-path indirection.
- **[AGENT]** The generalization behind it, consistent with the inherited "I need git tracking": agent-written knowledge does not live outside git.
- **[OWNER]** ADR keeps architecture and design decisions; `product/` (the "PDR") keeps intent and functionality. The execution register sits beside them and absorbs neither.
- **[OWNER]** The execution register exists, ships write-only, and is judged by what agents put in it. Its instructions live at `close` and `wrap_up`.
- **[OWNER]** Agents do not write execution facts into CLAUDE.md.
- **[OWNER]** `CURRENT_WORK.md` keeps Active Work and Up Next. The boot read gains the newest CHANGELOG entries; nothing needs pruning.
- **[OWNER]** `wrap_up` writes records, not documents, and does not commit unasked.
- **[OWNER]** The threads are worked as separate items, not as one — "not all of them now."

**Needs spec next:**

- The register's density bar, entry format, and where its instructions physically live so an agent meets them without a read path.
- The bound on the history read: **[AGENT]** bound it by entries rather than lines, since a line count truncates an entry mid-sentence. CHANGELOG entries run ~20 lines each against ~4-6 for the old Recently Completed entries, so either N is small or `close` writes a one-line headline the boot read takes instead. Unresolved.
- The light CHANGELOG entry shape for the `wrap_up` path, and how a reader tells the two weights apart.
- What replaces `feedback_*` in `_my_implement.md:152` and `_my_audit.md:92` — the feedback log, the new register, or nothing.

**Decomposition guidance:**

- **Item A — Delete `example-rules.md`.** No dependencies. Ships immediately. One rule file, one symlink, one generated `AGENTS.md` entry.
- **Item B — Kill hidden memories and the transcript stack.** No dependencies. Scope is now fully settled: both memory stores, four commands, one agent, two Python tools, two hook scripts, both PreCompact registrations, `.hook-paths.json`, the gitignore line, four installer scripts, three Codex exclusion lists, and the four stale references in `README.md`, `docs/guide.md`, `_my_implement.md`, and `_my_audit.md`. Migrates nothing on the way out: the four hidden entries are dispositioned in place, two of them as direct edits to `_my_handoff.md` and `working-voice.md` (`.project/active/retire-hidden-memories/spec.md`, *Why nothing migrates*).
- **Item C — The execution register, write-only.** Depends on nothing now that the read path is out of scope. Ships the register, its README, and the two write beats.
- **Item D — `wrap_up`'s scope.** Depends on B (removes the memory step) and C (adds the note beat). Also cuts the docs step and the unprompted commit.
- **Item E — `CURRENT_WORK.md` and the bounded history read.** Depends on D, since wrap_up is what writes both files. Touches the live file, the template, and `context-loading.md`.
- **Item F — Rule-to-check conversion.** Deferred. Needs a spike on hook capability before a spec is possible. No longer coupled to C.

Five threads, six items: thread 1 (a home for learnings) splits into B and C, because killing the hidden stores does not depend on building the new home. Thread 2 → D, thread 3 → E, thread 4 → A, thread 5 → F.

The dependency shape in one line: A, B, and C are independent and can ship now; C then D then E run in order; F is deferred and stands alone.

---

## Appendix A: Register maturity, measured

| | ADR | Product | Feedback | CURRENT_WORK | CHANGELOG |
|---|---|---|---|---|---|
| Rules doc | 91 lines | 130 lines | 33 lines | none | none |
| Script | `adr.sh` | `product.sh` | none | none | none |
| Density bar | quoted, worked pair | quoted, worked pair | none | none | none |
| Lifecycle verbs | 4 | 5 | 0 | 0 | 0 |
| Governing ADR | 0001, 0002 | 0008 | none | none | none |
| Read path | required output section | session-start skim | nothing reads it | every session | `_my_status`, `_my_project_find` |
| Write trigger | design accept + close | close | owner prose | 6 commands | close |
| Entries today | 12 | 0 | 0 | 13 active + 13 completed | 5 |

Read the bottom two rows together. The register with an unskippable write gate and an enforced read has 12 entries. The two with weaker triggers have none. That comparison is why the new register's write sits at `close` and `wrap_up`, and why its emptiness would be a finding rather than a failure.

## Appendix B: Prior art for item F

- `claude-pack/scripts/product-lens.md:3` — "This is not a slash command and not an always-on rule." A rule-set relocated into an on-demand subagent, spawned from four call sites, verdict appended to a ledger that downstream gates read. `:60` — "Return little. You read a lot; the call site's context stays clean if your output is just the point, the findings, and the gate — not a re-narration of the WORK."
- `.project/adr/0012` and `claude-pack/skills/_my_mental_model/SKILL.md:101-153` — a fresh, isolated, model-pinned reviewer reads the prompt, both feedback tiers, and the artifact, writes notes to a file, and the coordinator relays the path without opening it. Advisory, never a gate. `review.md:38` — "Drop any note you cannot cite."
- `.project/adr/0012:33` — "A rule in a prompt file stands without an example. A lesson that needs an example to be understood is feedback, not a rule." The sharpest available boundary test between a rule and a learning.
- `.project/research/20260818-151200_anchor-on-the-point-inventory.md:336-400` — three hook implementation options (static command, prompt handler, agent handler) with a state-file activation pattern, plus the `[AOP-005]` backlog item that carries them.
