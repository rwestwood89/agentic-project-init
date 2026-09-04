# Current Work

**Last Updated**: 2026-09-02

---

## Active Work

### mental-model-reviewer — reviewer subagent + prompt-versus-feedback split
- Epic MENTAL-ALIGN-V2, Item 6. **Phases 1-3 of 4 implemented 2026-09-02, uncommitted on `main`. Phase 4 (install + live run) is all that remains.** Spec revised after spec-review; product-lens CLEAR; ADR 0012 filed and amended; design approved. `.project/active/mental-model-reviewer/{spec,spec-review,product-lens,design,plan}.md`.
- **Built.** `review.md` (new sibling, the reviewer's instruction file with a three-pass reading method). The split: ten rules into `design_synthesis.md`, nine into `visualize.md`, both with `## Before delivering`; the two shared feedback files rewritten as 8 and 5 entries in the D9 shape, every one carrying a `From:` line traced to a real echo-workspace run. `SKILL.md` 370→420 lines: new Step 4 (the review pass), old 4-10 renumbered 5-11 with all nineteen cross-references updated, read set narrowed to the prompt, promotion reduced to a pointer. Two harness blocks (`reviewer-spawn`, `notes-relay`) registered in `build-codex-pack.sh`; dist `review.md` assertion added; `harness-phrases.md` has both rows.
- **Owner decision, 2026-09-02: the reviewer runs on sonnet, not haiku.** Amends the spec `[NEED]` ("a small model"), design D6, and ADR 0012, all three recorded with the owner's original verbatim quote left intact. Reason: the isolation that requirement protected — no sources, no conversation — comes from the reviewer's brief, not the model size.
- **The evidence behind it.** Six planted-fixture runs, all kept in the work-item folder (`fixture-planted-synthesis.md`, `fixture-expected-notes.md` with the run log, six `*.review.md`). Haiku never cited an example entry in any run and the split made it worse; sonnet cites entries by name, finds both plants, and found true defects nobody planted. Bet B1 true at sonnet, false at haiku; B2 holds (every Appendix A row passed the placement test). `review.md` was adjusted twice during Phase 1 and never after; the fixture was never adjusted.
- **Voice pass 2026-09-03:** the owner rejected the prose across every artifact. Fresh reviewers checked all six skill files against `working-voice.md` in three rounds: ~125 findings, then 7, then 0. About 130 sentences rewritten. Both prompt files now open with an explanation of how a person reads. `[VOICE-001]` in the backlog covers the same sweep for `.project` artifacts and the other commands.
- **Green:** Phase 2 stencil (11), Phase 3 stencil (11), `test_codex_orchestrator_pack.sh`, `test_docs.sh`, `git diff --check`.
- **Installed on both runtimes 2026-09-03.** Claude runs from the directory symlink; Codex copy refreshed at `~/.agents/skills/my-mental-model/`. Acceptance fixture passes (`fixture-run-final2.review.md`, both plants, all notes cited). **Next: the owner's live `/_my_mental_model` run in `~/echo-workspace`**, watching that the coordinator opens no feedback file and no `.review.md`, and that a notes file lands beside the synthesis and beside each HTML. Then `/_my_audit`.

### product-intent-ledger — ADR-like ledger of implemented product promises
- **Audit remediated (2026-08-12) per owner dispositions, uncommitted on `anchor-on-the-point`; pending re-audit.** Owner calls: pointer-entry title restates the promise one-liner with a citation-only body (audit-F1 BLOCK → resolved, README cross-seam reworked); no withdrawal/retire status — supersession covers disappearance, D3 unchanged (audit-F2 INTENDED-CHANGE); audit-F3 disposed citing D2's recorded duplication acceptance. Ledger gate CLEAR pending re-audit confirmation.
- Engine fixes in **both** scripts per D2 (`product.sh` + `adr.sh`, `.project/scripts/` copies diff-verified): atomic id allocation (mkdir lock), `set_field` fails on missing field, ambiguous-id rejection, self/re-supersede and self-amend rejected (no successor-link overwrite), `new` writes `checked: null` with the stamp moved to close's filing beat (`product.sh check <id>` in `_my_close` 4b). Tests: product 46 green (was 36), adr 32 green (was 25) — incl. 8-way concurrent allocation in both.
- Evidence completed: E4 raw lens verdict preserved verbatim in `fixture-transcripts.md`; E3 rerun with script execution permitted (clean PASS — proper `product.sh supersede` offer, no hand-minted state); E5 rerun graded strictly (Codex named `docs/report-contract.md` by path, full transcript kept). Full suite 8/8; Codex dist rebuilt + both installs refreshed.
- Implemented surface (first pass): `project-pack/{product/README.md,scripts/product.sh}` + `scripts/test_product.sh`; touch points per **ADR 0008** (context-loading INDEX skim, lens SOURCES ×6 discovery-not-authority, `_my_close` promise scan/confirm/file beats, status/project-find pointers); docs mentions + 3 `test_docs.sh` wired-guards; init-project seeds `product` both paths; this repo re-inited (README-only ledger, no backfill).
- Artifacts: `.project/concepts/product-intent-ledger.md`; `.project/active/product-intent-ledger/{spec,design,plan,product-lens,audit}.md` + `fixture-{sandbox,expected-findings,transcripts}.md`.
- Next: fresh-session re-audit; then `/_my_close`, `/_my_pre_pr` when the branch ships.

### coordinator-synthesis — coordinator + synthesis step (Claude)
- Epic MENTAL-ALIGN-V2, Item 3. **Complete (2026-08-20).** Spec reviewed and revised, implementation done, first real run verified.
- Skill directory live at `claude-pack/skills/_my_mental_model/` with `SKILL.md`, `design_synthesis.md`, `feedback/synthesis.md`.
- First run: `.project/mental-alignment/runs/20260820-131155_ralph-loop.md` — discovered-policy, plain-document shape, ~6m15s.
- Carried and clean-room policies untested. Item 3 epic done-state: 4/6 checked, 2 unchecked (those two policies).

### render-switch-feedback — render paths, comparison, and feedback (Claude)
- Epic MENTAL-ALIGN-V2, Item 4. **Implemented 2026-08-20; first validation run passed.** Spec → spec-review → design → design-review (Rework, DR-1/2/3 dispositioned by owner) → revised design approved by owner → implemented with no separate plan (owner call: small enough).
- Landed: `claude-pack/skills/_my_mental_model/visualize.md` (136 lines, the render agent's instruction file), `feedback/html.md` (shared starter, header only), and `SKILL.md` Steps 5–9 replacing the terminal stop — correction gate, routing + one brief with two envelopes, `# Renders` readings write-back, plain-document judgment read-back, feedback recording and promotion. `SKILL.md` 98 → 277 lines. Installation needed nothing: `~/.claude/skills/_my_mental_model` is a directory symlink, so both new files are already live.
- Three owner decisions from design-review are baked in: clean room constrains the synthesis, not the render (default is free exploration, override offered at the pause); an unreachable synthesis agent at the correction gate **stops the run** — the coordinator never writes synthesis content; cross-runtime correctness belongs to the Codex adapter under ADR 0011, so the prose is Claude-native.
- **Run V1 passed (2026-08-20): resumed path, clean-room policy, checkpoint shape.** Run in `echo-workspace`, not here, so it also proved reachability through the global directory symlink from another repo. Artifacts: `/home/rwestwood/echo-workspace/.project/mental-alignment/runs/20260820-152840_lofi-runner-architecture{.md,_resumed.html}`. Owner: "it worked … got my artifact." The central risk is answered for this run — the HTML labels 17 `render addition` spots, carries 11 tables and 3 inline SVG, and its source footer separates the owner's named clean-room sources from the four external sources it read for detail. It went after exactly the four claims the synthesis had flagged as cited-not-verified. D9's clean-room default held and the HTML says so on its face ("Clean room for the synthesis … Unrestricted for this render"). Safety limits clean: no script, handlers, embeds, or remote URLs. Step 7 wrote its `# Renders` block (`10m 44s`, `tokens: not measured`, `owner quality: not asked`).
- SC1, SC3, SC7, SC9 checked. **Still untested: the fresh path (SC2), the comparison (SC5), plain-document shape and the terminal judgment read-back (SC4 half), the correction gate (SC10), feedback recording (SC6), promotion (SC8).**
- Two observations from V1, neither a spec failure: the coordinator recorded `owner quality: not asked` where Step 7 says to offer it on a solo render, and the HTML used no `<details>` disclosure at all — a candidate for `feedback-html.md` once feedback recording gets exercised. The v1 `echo-workspace/.project/mental-alignment/feedback.md` was left untouched, which is the "deprecated in place" non-goal behaving.
- Also landed: `.project/active/render-switch-feedback/harness-phrases.md` — the seven Claude-specific phrases Steps 5–9 introduced, with what each means for translation. **Item 5's dictionary input.** Nothing checks for it; an unlisted phrase ships clean and surfaces only on Codex. `visualize.md` needs no entries (it names no tool).
- Known gap by design: no automated checks anywhere, and tokens read `not measured` on both runtimes (the spec's last open question, closed with a negative answer by the Claude resume probe in `design.md` Appendix A).
- Deliberately not built: a second entry point for rendering a past synthesis through the skill. The design says it falls out of the fresh path rather than being a feature, so validation run 1 is driven by hand.
- Next: a fresh-path render (design validation run 1 — cheapest against the existing local `runs/20260820-131155_ralph-loop.md`, whose agent is long gone), then plain-document shape, the correction gate, and feedback + promotion. Then `/_my_audit`.

### directory-skill-build-pattern — ship a skill directory with siblings on both runtimes
- Epic MENTAL-ALIGN-V2, Item 5 (renumbered from old Item 2). **All four plan phases implemented (Phases 1-3 on 2026-08-21, Phase 4 on 2026-08-24); full suite green; both installs refreshed. Claude gate passed (owner). Next: the Codex behavioral gates, then `/_my_audit`.**
- **Phases 1-3 landed:** the build copies the whole skill tree under the derived Codex name and runs the adapter over every `.md` (`codex_name_for_skill_dir`, `adapt_skill_file_in_place`, flat lane deleted); six `harness-block` spans in the pack skill are substituted from a keyed table (`CODEX_SKILL_HARNESS_BLOCKS` + `substitute_harness_blocks`); `setup-codex.sh` mirrors each dist skill directory with a directory-level managed check. `example-skill.md` deleted. `~/.agents/skills/my-mental-model/` now holds all five files — **the first time siblings have ever reached a Codex install.**
- **Claude gate PASSED (owner, 2026-08-24):** `/_my_mental_model` runs end to end, behavior unchanged, and the `harness-block` comments do not confuse the coordinator. **Codex gates outstanding, both manual:** an end-to-end `my-mental-model` run, and a clean-room run confirming the synthesis agent did **not** inherit the conversation. Nothing automated catches an omitted `fork_turns: "none"`.
- **`followup_task` is an inherited name, not a captured one.** `fork-spike/evidence/collaboration-surface.txt` documents `spawn_agent` only; the resume spike says "the follow-up-task mechanism" without a literal tool name. The Codex text reads "send a follow-up task (`followup_task`)" so it survives a different spelling. The Codex run verifies it.
- **The dist neutrality scan had never executed** — `test_codex_orchestrator_pack.sh` called `rg`, which is not on `PATH` inside the script, so the `if` was always false. Now `grep -rnE`, widened to bare `subagent_type` and to every `.md` under dist skills. It passes.
- **Phase 4 landed:** v1 wiring gone (`mental-model-builder` path rewrite + shared-spec copy, the `mental-model` description override, the README command row); the false "Codex reads copies, not symlinks" claim corrected in `build-codex-pack.sh` and `CLAUDE.md`; `uninstall-project.sh` swapped to skill directories; D4's `sweep_dead_symlinks` added to `setup-global.sh`; ADR 0010 re-pointed in the only two documents that cited it as live guidance (epic `:176`, `coordinator-synthesis/spec.md:154`).
- **Third silently-broken guard found and fixed:** `setup-global.sh --dry-run` exited 1 straight after the banner. `create_dir` ended with `[ ! -d "$dir" ] && echo …`, which returns 1 when the directory exists; `set -e` then killed the script at the first call. Nothing ever noticed because the real (non-dry) run works. Same family as the dead `rg` scan and the plan's `[ … ] && fail` stencils.
- **The D4 sweep found four dead symlinks, not one:** `skills/example-skill.md` plus `scripts/git-copy-custom.sh`, `git-manage-README.md`, `git-merge-clean.sh`, dangling since they left the pack. D4's premise (removals recur) confirmed on first run.
- **Installer gap, open:** neither installer removes an orphaned top-level asset whose dist source is gone. Two instances were removed by hand under the owner's "delete it" call — `~/.agents/skills/example-skill/` and `~/.codex/scripts/mental-model-builder.md`. The mirror only converges *within* a skill directory it still visits.
- **Known doc gap:** the README now documents no skills at all, so `/_my_mental_model` and `show-me` are undocumented there. `_my_mental_model` was deliberately **not** added to `test_docs.sh`'s `RETIRED` list — the name still resolves, as a skill.
- **Working-directory blocker resolved:** activating a Codex skill preserves the project/session working root. Two controlled `codex exec` runs performed real relative writes under different `-C` roots; each write followed `-C`, neither landed in the skill directory. Codex supplies the absolute `SKILL.md` path in its skills inventory, so sibling files resolve from that locator. The eight project-relative paths and ~30 command-derived skills need no cwd fix. Findings and raw evidence: `.project/active/directory-skill-build-pattern/cwd-spike-findings.md`, `cwd-spike/evidence/`.
- Owner boundary (2026-08-20): Item 4 is Claude-only; **Item 5 owns all Codex adaptation** — phrase edits, working directory, resumed-render path, token reporting.
- `example-skill.md` is deleted, not converted; the flat native-skill build lane goes with it. No new build checks (the "if the build fails" gloss in revision 2 was an agent inference and was deleted from both the spec and ADR 0011).
- **Owner reversed ADR 0010** (2026-08-20): skill directories now go through the same Codex adapter as commands, applied recursively over every file in the directory. ADR 0010 superseded by 0011, not deleted. `design.md` revision 2 deleted the three invariants it had inherited from 0010.
- **Context-inheriting spawn confirmed on Codex** (2026-08-20): `spawn_agent` with `fork_turns: "all"` carried a conversation-only nonce out of the parent's completed turn; `"none"` did not. `codex exec resume` is a same-thread continuation, not a second worker. **`fork_turns` defaults to `"all"`, the inverse of Claude's fresh default** — so discovered and clean room must state `"none"` explicitly or they silently inherit. This was already documented in `codex-overrides/rules/collaboration.md`; the probe added the completed-turn boundary. Findings: `fork-spike-findings.md`.
- **Five adapter decisions taken by the owner (2026-08-21)**, now design D1/D8/D9/D10 + D3 confirmed: translate the Codex body rather than authoring a separate one; per-lane substitution lists over a shared common pass; delimit harness-specific spans with keyed `harness-block` markers so substitution survives rewording (owner-originated); restructure the Claude prose to keep the agent handle it was given; install by copy mirror, not a whole-directory symlink.
- **Found while checking scope:** the command lane's `/_my_x` rule corrupts a real path in a skill body — `_my_mental_model/SKILL.md:265` becomes `` `claude-pack/skills`my-mental-model`` ``. The skill lane omits that rule.
- **Corrected in `spike-findings.md`:** its claim that the build already writes the derived Codex name was wrong. `build-codex-pack.sh:375` reads the frontmatter name and `:386` writes it, so at HEAD the skill would ship as `_my_mental_model`. D2 is code to write.
- Audit of `claude-pack/skills/_my_mental_model/`: seven harness-specific spots, none in the dictionary; `SKILL.md:77` already fails the existing dist scan. No test will enumerate harness phrases (owner: if we knew them they'd be in the dictionary).
- Deferred until after Items 3 and 4 — the real skill is the test subject, not a placeholder.
- **Item 4 handed over a dictionary input** (2026-08-20): `.project/active/render-switch-feedback/harness-phrases.md`, seven new Claude-specific phrases in `SKILL.md` Steps 5–9. The seven pre-existing spots tabled in `spec.md:143-153` still have correct line numbers — Item 4's edits above line 87 replaced text line-for-line.

### mental-alignment-checkpoint — owner-facing HTML comprehension surface
- **Implemented directly from the revised design by owner instruction (2026-08-09, "basic feature, straight to implementation"); uncommitted on `anchor-on-the-point`, no spec/plan/audit run.**
- **Concept overhauled 2026-08-19/20 after using the shipped version; the v1 design chain is archived and its invariants are superseded.** Live concept: `.project/concepts/mental-alignment-checkpoint.md`. Archive with a per-document supersession header: `.project/completed/20260820_mental-alignment-design-v1/{design,design-review,design-revised}.md`. Public name stays **`/_my_mental_model`** (distinct from orchestration's launch-time Align checkpoint).
- New shape settled in the concept (no design doc yet): a skill directory `claude-pack/skills/_my_mental_model/` holding the entry point plus `design_synthesis.md` and `visualize.md`; policy and output shape classified from the request rather than flagged; every run pauses on the markdown synthesis, where the owner picks resume-same-agent, fresh agent, or both for a comparison; feedback in two bodies across two tiers with manual promotion; no automated checks. `claude-pack/scripts/mental-model-builder.md` is to be deleted.
- Shipped v1 shape (product-lens pattern, superseded): command `claude-pack/commands/_my_mental_model.md` (generate / feedback / promote modes) delegates whole to builder contract `claude-pack/scripts/mental-model-builder.md`, which solely owns discovery, two-layer HTML, safety/redaction, and success-or-failure. Runs → `.project/mental-alignment/runs/{YYYYMMDD-HHMMSS}_{slug}.html`; feedback → `.project/mental-alignment/feedback.md`; promotion fail-closed to authored source only.
- Stage offers wired: `_my_concept_design_review` (after presenting, before owner resolution) and `_my_epic_plan` (after decomposition, before approval); both suppressed under the NON-INTERACTIVE orchestration marker. Product-design-sibling discovery rider added at both stages' input discovery.
- Codex: `build-codex-pack.sh` copies the builder + rewrites its path (generalized shared-spec loop); `config.sh` description added; dist rebuilt; global Claude + Codex installs refreshed. Suite green (docs, pipeline-sync, concept-design-gate, adr, global-setup, codex-orchestrator).
- Next: begin the Mental Alignment Skill v2 epic. Item 1's Codex resume spike completed 2026-08-20: a follow-up task resumed the same completed agent with context continuity, so Codex can support the resumed-render path; current collaboration results expose no per-agent token count, which Item 5 must resolve or report as unavailable. Findings: `.project/active/codex-resume-spike/spike-findings.md`. Secret scanning remains deliberately deferred — see `BACKLOG.md` **[BL-009]**.

### concept-design-quality-gate — architectural decisions + independent pressure test
- **Committed on `anchor-on-the-point` (`338147d`, `9431d83`, `b3adc03`); still pending fresh audit.**
- **Implemented directly from the reviewed spec; design skipped by owner instruction (2026-08-07), pending fresh audit.** `my-concept-design` now centers root ownership, deletion before compensation, load-bearing decisions, and visible ADR candidates. New `my-concept-design-review` is a separate architecture-quality gate with a mandatory ultra-intensity ponytail-role subagent whose written challenge must be dispositioned. Pipeline, orchestrators, docs, Claude/Codex distribution, and focused tests are wired; broader install/docs/ADR suites pass. Global Claude and Codex installs refreshed.
- ADR 0006 extends the live touch-point map: review reads relevant ADRs but never files candidates; final concept acceptance remains the write point.
- Artifacts: `.project/active/concept-design-quality-gate/{spec,spec-review,product-lens}.md`; command `claude-pack/commands/_my_concept_design_review.md`.

### anchor-on-the-point — keep the pipeline anchored to product purpose
- Replaces the earlier `product-truth-gates` direction by owner decision (2026-08-05).
- **Implemented on branch `anchor-on-the-point`** (spec → design → plan → implement in one session). Second line of ground truth beside the artifact chain: a single-job product-lens subagent (shared spec `claude-pack/scripts/product-lens.md`) re-derives the product's point at 4 narrowing sites (epic_plan, spec, design_review, audit), records findings in an append-only per-item ledger (`.project/active/{item}/product-lens.md`), graded by source authority (reuses capture-fidelity provenance); design_review + audit lead with a loud "is this the right piece of work?" that outranks a green rubric; the seven smells are tripwires split design/code by layer; pre_pr + close honor an unresolved BLOCK; move 1 carries the problem (design "The Point" slot, plan anti-restatement reversed).
- **Phase-1 gate passed decisively:** fresh uncoached lens stopped a fusion-tea fixture two independent ways (product-check BLOCK + duplicate-selecting-test smell), zero FPs, and the can't-find control refused to fabricate an oracle. Repo suite green (adr 25/25, pipeline-sync, docs).
- **Audited Needs Work then remediated (2026-08-05, pending re-audit):** fresh-session audit BLOCKED the ledger because the touch points changed ADR 0002's map without the record ADR 0001 requires — the feature catching its own author silently resolving a premise conflict. Remediation (owner-directed): filed ADR 0003 + amended 0002; ledger now DISPOSED. Also fixed fail-closed ledger reads, epic→item propagation (D2), audit escalation≠resolution, spec Problem grading, problem carriage at review/audit (SC1), status-aware ADR clearing, canonical smell numbering, fixture drift; retired `product-truth-gates.md` (owner quotes moved to the concept). Deferred by scope: vendored/Codex reachability + a live command-level e2e. Repo suite green; fixture re-run reconfirmed. Next: fresh-session re-audit.
- **v3 review → remediation v3 applied (2026-08-05, pending re-audit):** v3 found three fail-open paths + two grading gaps, all fixed: `_my_spec` records the parent epic unconditionally (`Epic: <id>`) and pre_pr/close/audit always read the epic's live gate (late epic BLOCKs now reach existing items); item audit scans every ledger block (can't certify over an older BLOCK); epic-scope close reads the epic's own gate directly; lens §2 separates ADR liveness (status) from authority (only `[OWNER]` provenance BLOCKs — `[AGENT](ratified)` no longer laundered to owner-grade), recorded by **ADR 0005** superseding 0004; lens §3 gives findings stable IDs + structured `Resolves:` records. Suite green; diff clean. ADR chain: 0005 active, 0002 amended, 0003→0004→0005 superseded. **Codex build wired** (`build-codex-pack.sh` copies the shared spec into `dist/codex/scripts` + rewrites the path to `$HOME/.codex/scripts/product-lens.md`; dist rebuilt). Committed on branch; global + Codex installed. Still deferred: vendored/copy-install project reachability (DEFER-F1b) + live command-level e2e (DEFER-F2). Next: fresh-session re-audit (v4).
- **Prior — re-audit v2 Needs Work → remediation v2 applied (2026-08-05):** v2 found five subtler blockers, two of them my own prior fixes backfiring. All closed: plan template gains a structural `## The Point` (SC1); amended ADRs now bind (only `superseded` stops binding); epic→item is a grade-preserving *reference* not a copy (kills smell 1) with ship gates + epic audit reading the epic's live gate; epic-scope audit now runs the lens; resolution-by-citation so a later CLEAR can't mask an earlier BLOCK; and ADR 0003's special-category framing (smell 3) superseded by **ADR 0004** (states the map is extended, amends 0002). Ledger `remediation v2` block disposes the audit_v2 BLOCK by citation → DISPOSED. Suite green (adr 25/25, pipeline-sync, docs, global-setup); `git diff --check` clean. Still owner-deferred: vendored/Codex reachability + live command-level e2e. Next: fresh-session re-audit (v3).
- Artifacts: `.project/concepts/anchor-on-the-point.md`; `.project/active/anchor-on-the-point/{spec,design,plan,audit,audit_v2,product-lens}.md` + `fixture-{planted-input,expected-findings}.md`; research `20260803-210317_...md`.

### decision-records — `.project/adr/` append-only decision log + pipeline touch points
- From the constraint-execution post-mortem (2026-07-19): durable, high-density record of load-bearing decisions; read at concept-design/design, written at design acceptance and close.
- **Implemented on branch `decision-records`** (with the post-mortem's System Confidence / EPIC_GUIDE slicing changes): `adr.sh` + convention README in project-pack, installer seeding, touch points in `_my_concept_design`/`_my_design`/`_my_close`, `test_adr.sh` 25/25 green, dogfood entries 0001–0002 filed here.
- **Certified (2026-07-19, `audit.md`)** — spec criteria 2–6 verified; criterion 1's surfaced seeding discrepancy resolved by owner (2026-07-22): amended the spec parenthetical to match approved design D5 (lazy `INDEX.md` bootstrap, no installer-seeded placeholder), criterion 1 now marked. Minor non-blocking notes remain: slug validation and self-supersede guard in `adr.sh`. Committed and PR'd.

### capture-fidelity — provenance, compression, and correction laws for the pipeline
- From forensics on the echo-workspace band-study failure: one always-loaded rule (provenance grading, compression protection, correction discipline, surfacing duty) + minimal touches to concept/spec/reviews/orchestrate/audit/handoff.
- **All 5 phases implemented on branch `capture-fidelity`.** Rule `claude-pack/rules/capture-fidelity.md` (40 lines) + 8 command touches; installed globally + Codex rebuilt. Phase-2 gate passed 4/4 (through real `spec_review`, 0 FPs) after refitting plant P3.
- **Audited: Certify (2026-07-10, `audit.md`); committed with refinements; merged origin/main. Next: PR.**
- Key calls during implement: P3 fixture was mis-specified for a concept hop (first-hop compression is owner-checked, not reviewer-checked — `design.md:71`), refit to a "softened referent" plant; audit + handoff deliberately don't reference the rule (their behaviors aren't among the four laws); rule content ships to Codex via `AGENTS.md`, not a separate file.
- Artifacts: `.project/active/capture-fidelity/{spec,spec-review,design,design-review,plan,audit}.md` + `fixture-{planted-concept,expected-findings}.md`

### capture-fidelity-refinements — second-layer fixes from the first pipeline run under the new laws
- Origination-vs-ratification provenance, fresh-session reviews, minted-provenance approval presentations, declared template adaptation, durable orchestrate briefs.
- **Implemented directly on owner instruction (owner curated the diff); committed alongside the parent item.**
- Spec: `.project/active/capture-fidelity-refinements/spec.md`

### codex-orchestrator-fork — Codex-native autonomous pipeline orchestration
- Spec, design, spike, and implementation plan drafted. Phases 1-5 are implemented and validated: Codex helper dry-run and real execution paths, generated script install lane, full `my-orchestrate` replacement, Codex `AGENTS.md` transforms, generated-product tests, installer dry-run, and project checks are in place. Optional live smoke was not run.
- Artifacts: `.project/active/codex-orchestrator-fork/{spec,design,spike-findings,plan}.md`

### codex-orchestrator-observable-waiting — readable, token-efficient long-stage waiting
- **Audit remediation applied 2026-08-13; pending fresh certification.** The authored and generated Codex orchestrator now leave both `$my-close` and the post-close `$my-pre-pr` branch gate to the human unless asked, with an exact generated-product regression assertion. The assertion failed before the fix and passes after it; the pack was rebuilt, reinstalled, and byte-matched. An independent product-lens rerun returned CLEAR and resolved `audit-F1` by citation, so SC8 is re-checked. The auditor's six-command validation set passes. Evidence wording is now precise: direct helper cancellation is proven, host-cell interrupt delivery is not; the live resume preserved its thread but used the single bounded fallback wait after the outer cell yielded early. The audit artifact still says Needs Work until a fresh audit certifies the remediation; close and pre-PR remain gated. Non-blocking hardening remains deferred; see `audit.md` and `plan.md`.
- Separate issue observed during the live fixture: the resumed `my-spec` stage entered a collaboration wait with zero product-lens recipients and reached the helper timeout. A corrective same-thread resume spawned the lens and finished. This item records but does not change that stage-agent routing behavior.

---

## Recently Completed

### 2026-08-26: feedback-capture-file — record agent learnings where the owner can act on them
- Added `.project/feedback/README.md` instructions and an append-only `ENTRIES.md` so agents can record corrections while the context is fresh.
- Protected accumulated entries from `init-project.sh --force` while allowing updated recording instructions to propagate, with focused init coverage.
- Archived the standalone item to `.project/completed/20260826_feedback-capture-file/`.

### 2026-08-08: docs-overhaul — question-driven guide, single command catalog, pre_pr after close (committed `43bca3c`)
- **Minimum doc set with one owner per fact:** `docs/guide.md` absorbed and replaced `docs/working-with-claude.md`; README owns the complete command catalog (31 commands, legacy marked); project-pack README/EPIC_GUIDE defer to `/_my_pipeline` instead of restating the flow; `.project/` template instances re-synced.
- **Owner's mental model now canonical (owner-stated 2026-08-08):** not a strict pipeline — entry follows the questions "how well do you understand the problem?" → UX to understand (`product_design`), impact (`concept_design` + `research` first), size (`epic_plan`). Guide, `/_my_pipeline`, `rules/pipeline.md`, and both orchestrators reframed around it.
- **`product_design` is dual-tier:** runs off a concept (shaping) or a spec (single item); same function. Command, pipeline, and guide updated.
- **`pre_pr` is a branch gate after `close`** — per item when shippable alone, once at epic end otherwise (**ADR 0007**, `[OWNER]`). Audit of 12 timing references found 8 wrong (root cause: old shape line `audit → pre_pr → close` + no when-to-run guidance in the command); all fixed, incl. pre_pr's product-lens gate now reading ledgers from `completed/` post-close.
- **New drift guards in `test_docs.sh`:** README catalog completeness, no retired command names, no stage-sequence restatements outside the canonical pair (guide's flow line exempted by owner decision, comment marks it). Suite 9/9 green; Codex dist rebuilt.
- Next: guide is ready for the upstream PR (Up Next item 1).

### 2026-07-06: spike-and-learning-test-commands — hands-on de-risking commands (certified, archived)
- Two new commands: `/_my_spike` (confirm a known assumption, throwaway probe + findings doc) and
  `/_my_learning_test` (map an unfamiliar surface, findings doc + real kept tests) — write-code-to-learn
  siblings of read-only `/_my_research`, sharing one discipline (reproducible, living doc,
  summary-on-top, close the loop).
- Soft de-risking suggestions wired into `concept_design`/`spec`/`design`/`epic_plan`/`research`;
  orchestration awareness in `_my_orchestrate`/`_my_pipeline`/`orchestrate-stage.sh`
  (`bypassPermissions` for headless runs). Codex-exposed; documented in README + CLAUDE.md.
- Audit verdict Certify (all 9 spec criteria). Archived to
  `.project/completed/20260706_spike-and-learning-test-commands/`.

### 2026-07: workflow-orchestrator — autonomous pipeline orchestrator (merged, PR #25)
- High-judgment agent (Fable) drives the v2 pipeline end to end via opus subagents, fully autonomous, Claude-only.
- Helper `orchestrate-stage.sh` + uniform preamble; command `_my_orchestrate.md`. Merged to `main`.

### 2026-07: pipeline-guide — canonical shipped pipeline overview (merged)
- Canonical `/_my_pipeline` command + always-on shape rule; other docs point here instead of restating the flow. Merged to `main` (`46020d8`).


### 2026-07-01: Epic WORKFLOW-V2 — Workflow v2 Redesign (certified, archived)
- Pipeline redesign: new bridge command (`epic_plan`), certification step (`audit`), archive command (`close`), consolidated pre-PR gate, Required Reading traceability from concepts through implementation.
- 9 items: epic template foundation, epic_plan, pipeline Required Reading, audit certification, close, pre_pr, status, design_review rename, cross-reference cleanup + Codex rebuild.
- All 6 epic success criteria verified. Retired 5 old commands, created 6 new ones, modified 3 pipeline commands.

### 2026-06-25: agent-working-voice rule (merged, PR #21)
- Global working-voice rule + reader-comprehension checks in spec/design reviewers; 2 surgical prompt fixes.
- Full pipeline run: spec → design → plan → implement, with user checkpoints on the rule and pilot rewrites.
- Two feedback memories saved: plain-writing voice, and dislike of the Q&A tool for complex decisions.
- Merged to `main` via PR #21; Codex dist rebuilt and committed (`aa652a9`).

### 2026-06-25: /_my_handoff command (committed `22e4437`)
- New command: writes a handoff doc to the OS temp dir for a fresh agent (focus, references to read, key discoveries, suggested skills).
- Spec at `.project/active/handoff-command/spec.md`; Codex skill + description added; pushed to `main`.

### 2026-04-18: CLAUDE.md created
- Added CLAUDE.md with architecture overview, key commands, session workflow
- Documents the meta-project nature (building commands while using them)
- Highlights that `setup-global.sh` must run after adding new commands

### 2026-02-11: Security Analyzer (branch: `security-analyzer`)
- Two scripts in `claude-pack/hooks/` for transcript security analysis
- All 6 checks pass against real data (943 transcripts, 14.6K findings)
- Not yet PR'd -- iteration-ready on branch

### 2026-02-07: Session context boot sequence (PRs #4, #5, #6)
- Added `/_my_wrap_up` command — end-of-session context persistence
- Added `context-loading.md` rule — auto-loaded rule that tells Claude to read CURRENT_WORK.md before starting non-trivial work
- Added "Session Start" section to `claude-md-checklist.md`
- Added `docs/working-with-claude.md` — practical guide for working with the toolkit
- Fixed concurrent session bug — wrap-up now uses conversation context as primary source, git as cross-validation
- Split original PR #3 into #4 (guide doc) + #5 (boot sequence feature) + #6 (concurrent fix)
- All merged to upstream `rwestwood89/agentic-project-init`

### 2025-12-30: codebase-organization
- Established `claude-pack/` and `project-pack/` structure
- Set up symlinks for development workflow

### 2025-12-30: init-project.sh improvements
- Added `.project/` merge strategy for existing projects
- Added CLAUDE.md check with `/init` suggestion

---

## Up Next

1. Finalize production guide and PR to upstream
2. Iterate on security-analyzer: tune rules, reduce false positives, PR when ready

---

## Session Notes

### 2026-06-25
- Diagnosed the voice problem as two axes: clarity/structure (partly handled) and texture/voice (the real gap). Settled a three-register model; this work owns only the *working voice* (chat + internal artifacts), not external explainers, not a command's task stance, not artifact structure.
- Core bet: the agent mirrors the register of its own prompts — so the lever was rewriting dense prompts, not just adding a rule. Pilots showed the prompts were already mostly good, which reframed the win toward the rule + review check.
- Rule grew real teeth from live user examples: a "precision is the work behind the voice" section, and "decompose into points; avoid block text" (a console wall-of-text was the trigger).
- `dist/codex/` deliberately excluded from the commit — the local rebuild entangled unrelated `handoff` WIP and `my-design` staleness.

### 2026-04-18
- Created `/_my_concept_design` command based on user feedback about `/_my_concept` being too spec-like for architecture work
- Good example: `echo-workspace/.project/concepts/20260417_forecast-handling-pattern.md` — clear design principles, invariants, vocabulary
- Bad example: `echo-workspace/.project/concepts/20260417_dispatch-guidance-restart.md` — too implementation-heavy, obscures decisions
- Key insight: design concepts should make decisions explicit, not bury them in details
- Gotcha: new commands need `setup-global.sh` to create symlinks in `~/.claude/commands/`

### 2026-02-16
- Wrote production codebase guide with collaborator feedback loop
- Created workflow-accountability rule for auto-loaded process enforcement
- Cherry-picked guide commit from security-analyzer to clean production-guide branch
- Accidentally pushed security-analyzer to remote, deleted it, pushed production-guide instead

### 2026-02-07
- Reviewed PR as upstream maintainer, identified `working-with-claude.md` scope issue
- Concurrent session safety: git log can't distinguish which session made which commits — conversation context is the right source of truth
- PR splitting workflow: create base branch from main, cherry-pick feature changes on top
