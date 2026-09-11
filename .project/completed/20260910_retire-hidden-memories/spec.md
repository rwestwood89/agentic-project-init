# Spec: Retire Dead Pack Content

**Status:** Certified.
**Owner:** Reid W
**Created:** 2026-09-09 16:31 PDT
**Complexity:** MEDIUM
**Branch:** mental-model-reviewer
**Epic:** KNOWLEDGE-HOMES, Item 1

---

## Problem

The pack tells agents to write knowledge into places that are hidden, empty, or nonexistent, and it ships an entire subsystem built to solve a problem that no longer exists.

**Two hidden stores.** The native memory directory (`~/.claude/projects/*/memory/`) sits outside the repo and outside git. `.project/memories/` is gitignored (`.gitignore:18`), and its `index.json` is literally `{}` — nothing has ever been written to it, despite it being served by the pack's only wired hook.

**A subsystem serving them, 1008 lines.** Four commands (`_my_capture`, `_my_memorize`, `_my_recall`, `_my_review_compact`), one agent (`recall.md`), two Python tools (`parse-transcript.py`, `query-transcript.py`), two hook scripts (`capture.sh`, `precompact-capture.sh`), two PreCompact registrations, and a `.hook-paths.json` indirection written by both installers. It exists to compensate for running out of context and disliking autocompaction. Owner-stated: 1M context windows and better compaction removed the need.

**Four references that point at nothing.** `context-loading.md:9` tells every session to check auto-memory. `_my_implement.md:152` and `_my_audit.md:92` send the agent to read `feedback_*` entries — a glob that matches zero files in this repo's memory directory and never has. `_my_wrap_up.md:37-54` instructs the agent to update a "Recent Decisions" section that is not in the file it targets.

**31 lines of boilerplate in the always-on budget.** `claude-pack/rules/example-rules.md` is unedited template content — "Use descriptive variable names," "Never commit secrets" — auto-loaded into every session in every project, and into every generated Codex `AGENTS.md`.

**The documentation presents all of it as shipped.** This is a distributable template. `README.md` lists hooks under "What's Included," walks a new user through installing them, and carries a "Hook Not Running" troubleshooting section at `:408-421`. `docs/STRUCTURE.md` shows `hooks/` and `memories/` in both directory trees and in its "What Ships" list. A new user follows that text to a hook that will not exist.

The store's actual contents are the evidence that shaped this item. All five entries in this repo's memory directory are corrections to the pack's own prompts, not facts about the code. Their disposition is settled below — and none of them migrate.

---

## Success Criteria

- [x] A grep of executable and shipped product surfaces for the removed command, hook, agent, and script names returns nothing except targeted legacy-cleanup code and its tests. Durable `.project/` records remain historical evidence and are excluded.
- [x] `grep -inE "hook|memories|auto-memory|recall|transcript|memorize" README.md docs/STRUCTURE.md CLAUDE.md docs/guide.md` returns no line presenting any of them as a shipped component.
- [x] `ls -L .claude/hooks` fails because the symlink is gone, not because it dangles.
- [x] `context-loading.md` still sends every session to skim the product ledger (ADR 0008).
- [x] `setup-global.sh` and `init-project.sh` install no hooks against a fresh target, and both uninstallers remove the retired registrations and files cleanly.
- [x] Running `setup-global.sh` against a `~/.claude/settings.json` that already carries a pack-written `PreCompact` entry leaves that file with no `PreCompact` entry and the user's `PreToolUse` entry present and unmodified.
- [x] `dist/codex/AGENTS.md` has no `example-rules` section, and the Codex exclusion lists no longer name deleted files.
- [x] `_my_handoff.md` instructs the agent to pause after writing and wait for further instruction.
- [x] `working-voice.md` states that a decision is presented in prose, not through the multiple-choice question tool.
- [x] `.project/feedback/ENTRIES.md` is unchanged — no entries are added by this item.
- [x] `grep -n "ENTRIES.md" .project/concepts/agent-knowledge-and-enforcement.md .project/backlog/epic_knowledge_homes.md` returns no line requiring four migrated entries, and the register's subject boundary at concept `:116` still stands.
- [x] No tracked script backup exists, and every tracked executable under `scripts/` is checked for code that creates `.claude/hooks` or `.project/memories`.
- [x] `README.md`'s "Updating" section names this change as the exception that requires re-running `setup-global.sh`.
- [x] This repo's six native memory files are gone, and no pack instruction points at the native memory directory or at `.project/memories/`.
- [x] `test_global_setup.sh`, `test_rename.sh`, `test_init_project.sh`, `test_docs.sh`, `test_uninstall.sh`, and `test_codex_orchestrator_pack.sh` pass.

---

## Known Requirements

### Deletions

- **[NEED]** The hidden stores and the whole transcript stack go. Owner-verbatim: *"Let's kill hidden memories."* Scope is the four commands, the `recall` agent, both Python tools, both hook scripts, both PreCompact registrations, `.hook-paths.json`, `.project/memories/`, `project-pack/memories/`, the `.gitignore:18` line, and the `memories/index.json` entry in the `USER_DATA_FILES` list at `scripts/init-project.sh:122`. Source: `.project/concepts/agent-knowledge-and-enforcement.md`, Owner's Words and Success Criterion 2; the `USER_DATA_FILES` entry from epic `:106`, surfaced by product-lens finding spec-F2.
- **[NEED]** `example-rules.md` is deleted — from `claude-pack/rules/`, from `~/.claude/rules/`, and from the generated `dist/codex/AGENTS.md`. Owner-verbatim: *"we should kill `example-rules.md`."* Source: same concept, Success Criterion 8.
- **[NEED]** The `feedback_*` instructions in `_my_implement.md:152` and `_my_audit.md:92` are deleted outright, not repointed. Owner decision, 2026-09-09. Every register that exists holds the wrong subject, and the register that would hold the right subject is forbidden a read path by Item 2's non-goal.
- **[NEED]** This repo's six native memory files are deleted. Owner decision, 2026-09-09. The ten other projects' memory directories are untouched — see Non-Goals.
- **[INHERITED]** `claude-pack/hooks/` and the `.claude/hooks` symlink are deleted, and the documentation sweep covers `README.md`, `docs/STRUCTURE.md`, `CLAUDE.md`, and `docs/guide.md`. Source: `.project/backlog/epic_knowledge_homes.md`, product-lens finding epic_plan-F2 (agent-grade, dispositioned DISPOSE-and-proceed, resolved 2026-09-09). Verified independently here.

### Migration

- **[NEED]** No entries are migrated into `.project/feedback/ENTRIES.md`. Owner decision, 2026-09-09, taken entry by entry. See *Why nothing migrates* below.
- **[INFERRED]** The retracted obligation is amended at every live site, not just recorded here. Seven lines currently require the migration: concept `:52` (Success Criterion 1) and `:232` (Item B decomposition), and epic `:42`, `:54`, `:112`, `:127`, `:134`. Items 2 and 3 carry the *concept* as Required Reading and never read this spec, so leaving those lines standing hands every downstream agent a requirement the owner retracted, and points epic-scope audit and close at a done-state that no longer applies. Each line is rewritten to state what is now true, carrying a path-cite to this spec for the reasoning — not annotated with a note about the change. Source: capture-fidelity §3; surfaced by product-lens finding spec-F1.
- **[INFERRED]** Concept `:116` is **not** amended. It states that a pack-prompt correction's home is `.project/feedback/ENTRIES.md`, which is still true — this item changes what gets filed, not where that class of fact belongs.
- **[NEED]** `_my_handoff.md` gains the instruction to *"pause when you are done writing and wait for further instruction."* Owner-verbatim, 2026-09-09. This replaces migrating `feedback-handoff-means-stop` as an entry — the correction is live and unfixed, and `_my_handoff.md` currently says nothing about stopping.
- **[NEED]** `working-voice.md` gains a line stating that a decision is walked through in prose rather than presented through the multiple-choice question tool. Owner decision, 2026-09-09. The rule's "Presenting a decision" section already describes the prose shape and never states the negative; today only `_my_spec.md:39` does, and only inside its own questioning loop.

### Installer

- **[NEED]** Global setup, project init, global uninstall, and project uninstall remove the previously-written `PreCompact` registration through one shared cleanup function. Owner decision, 2026-09-09; the four-route scope is inherited from the owner-approved concept, and safe grouping and invalid-JSON behavior were corrected after audit on 2026-09-10. The cleanup matches the exact retired script name, removes individual matching commands rather than whole entries, removes empty containers, backs up changed valid files, and fails visibly without writing when the input is invalid JSON.
- **[HARD]** The user's own `PreToolUse` hook in `~/.claude/settings.json` (`auto-approve-paths.sh`) is not pack content and must survive untouched. It serves the teasp and Julia workspaces.
- **[INFERRED]** The cleanup step above is unreachable as the README stands. `README.md:319` tells users "Changes are instantly available via symlinks - no need to re-run setup," so a user who pulls gets deleted hook scripts and keeps a `PreCompact` entry pointing at a script that is no longer there, firing on every autocompact. This update must be marked as the exception that requires re-running `setup-global.sh`. Surfaced by product-lens finding spec-F3.
- **[INFERRED]** The epic's stated reason for that risk is wrong and is not carried forward. Verified 2026-09-09: jq's `*` merges objects recursively, so `jq -s '.[0] * .[1]'` preserves `.hooks.PreToolUse` and replaces only the `.hooks.PreCompact` array. The requirement above stands on its own; the merge never threatened it. `uninstall-global.sh` is likewise safe — it removes only symlinks resolving into the pack source, and `auto-approve-paths.sh` is a real file.

### Constraints on verification

- **[HARD]** `CLAUDE.md` is gitignored in this repo (`.gitignore:6`). Its edits will not appear in the commit diff and must be checked in the working tree.
- **[HARD]** `.claude/hooks` is tracked in git as a symlink blob (mode 120000). Deleting the target is not enough — the symlink must be removed from the index.
- **[HARD]** `dist/` is wiped at the start of every Codex build, so every `dist/codex/` change follows from rebuilding rather than from editing.
- **[INFERRED]** Three test scripts will fail on the deletions as written and must be updated in the same change: `test_global_setup.sh:63` and `test_init_project.sh:77` loop over directory lists that include `hooks` and `memories`, and `test_init_project.sh:198` asserts `.project/memories` exists. `test_rename.sh:54` greps `claude-pack/hooks/*` but is guarded by `2>/dev/null || true`, so it degrades to a no-op rather than failing.

---

## Why nothing migrates

Recorded here because it amends two upstream criteria, and because a future agent reading only the epic will expect four entries.

Each of the four candidate entries was checked against the register's own rules (`.project/feedback/README.md`) and against the pack as it stands.

- **`voice-plain-writing`** — already fixed. Every point in it appears in `claude-pack/rules/working-voice.md`, several nearly word for word: the mental model for complex subjects, don't coin a term and reuse it as shared, the decision shape as an example rather than a template, and the tired-engineer test. The memory's own last line names the project that turned it into that rule. The register's README: an entry dies once its target is fixed.
- **`feedback-handoff-means-stop`** — live and unfixed, but the owner chose to fix `_my_handoff.md` directly rather than file the correction.
- **`avoid-askuserquestion-complex-decisions`** — half fixed, and the owner chose to complete the fix in `working-voice.md` rather than file it.
- **`feedback-answer-questions-dont-act`** — no pack target exists. Nothing in `claude-pack/` covers it, and it is a correction to general conversational behavior rather than to a command, skill, or rule, so it cannot carry the bare pack-target tag the register requires. Owner decision: let it die. Owner's reason: *"I don't think it actually worked anyways."*

The fifth entry, `command-symlinks.md`, duplicates content already in `CLAUDE.md` and simply goes.

---

## Non-Goals

- **The native memory directories of the other ten projects.** Out of scope for this item, not a permanent decision. Reasoning and the count are under *Carried to Item 2* below.
- **Any change to `_my_wrap_up.md` beyond removing the auto-memory step.** That step is `:37-54`, plus its traces at `:3`, `:14`, and `:74`. The file's final shape belongs to Item 3.
- **Creating the execution register, or deciding where execution facts go.** That is Item 2.
- **Preserving conversation history in any form.** Owner-stated and accepted.
- **Cleaning up `.hook-paths.json` on installs that already have one.** Owner decision, 2026-09-09. The installers stop writing it and nothing in the pack reads it, so a leftover copy is inert — unlike the `PreCompact` registration, it never runs. No cleanup code is added, and stale copies on other machines are accepted.
- **`claude-pack/agents/example-agent.md` and `claude-pack/commands/_my_example_command.md`.** The owner named `example-rules.md` only. The other two example artifacts are not in scope.
- **Re-pointing implement and audit at another register.** Pointing them at `.project/feedback/ENTRIES.md` would make them its first automatic readers, contradicting its stated design ("Nothing reads this file automatically"), and the subject is wrong — that log holds pack-prompt corrections, not code-quality rejections.

---

## Resolved implementation questions

- The settings cleanup matches the exact retired script name and removes only matching inner hook commands. It runs from global setup, project init, and global uninstall.
- A marked vendored project removes the exact retired copied files whenever `init-project.sh --include-claude` reruns; project uninstall uses the same file list.
- The `_my_handoff.md` and `working-voice.md` corrections landed before the memory files were deleted.
- `EXCLUDED_HOOKS` and the hook-translation path were deleted rather than retained as empty scaffolding.

### Carried to Item 2, not resolved here

The native memory store is live in eleven projects — 77 files, of which this repo holds 6. The concept measured this repo only, found all five entries were pack-prompt corrections, and concluded the population of homeless execution facts was zero while flagging that this repo is a meta-project and a poor indicator. That caveat is now quantified. Seventy-one agent-written entries across ten real projects already record what agents chose to save, unexamined. Item 2's premise is that shipping a write-only register is the way to find that out; this evidence suggests part of the answer may already exist. Surfaced, not resolved — Item 2's spec owns it.

---

## Related Artifacts

- **Epic:** `.project/backlog/epic_knowledge_homes.md` (KNOWLEDGE-HOMES, Item 1)
- **Required Reading:** `.project/concepts/agent-knowledge-and-enforcement.md`
- **Product lens:** `.project/active/retire-hidden-memories/product-lens.md` (latest gate CLEAR; audit-F6 and audit-F7 resolved)
- **Audit:** `.project/active/retire-hidden-memories/audit.md`
- **Design:** none. Skipped by owner decision, 2026-09-09; the mechanism calls it would have made are in the plan under *Decisions carried from design*.

---

**Next Steps:** Run `/_my_close`. `/_my_pre_pr` runs at the end of the epic, not per item.
