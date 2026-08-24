# Concept-Design Review: Mental Alignment Skill Design

**Concept:** `.project/concepts/mental-alignment-skill-design.md`
**Review File:** `.project/concepts/mental-alignment-skill-design-review.md`
**Date:** 2026-08-20

## Fundamental Assessment

**Judgment:** Sound

### Are we actually solving the right problem?

Yes. The v1 shipped a single fresh agent with one instruction set covering discovery, thinking, and rendering. Three structural failures followed — all diagnosed in the concept, all confirmed by reading the shipped code (`claude-pack/commands/_my_mental_model.md`, `claude-pack/scripts/mental-model-builder.md`):

1. The thinking step was unnamed, so the agent treated it mechanically and optimized toward the deliverable.
2. The fresh-agent handoff dropped the owner's conversation reasoning.
3. The output shape was mandatory regardless of context.

These are prompt-architecture failures, not implementation bugs. A fix that keeps the one-agent, one-prompt shape cannot address them. Splitting the work into two agents with a human pause between them — where the synthesis agent's prompt ends at the synthesis — is the right structural repair.

### Architecture verdict

The system shape is correct. The invariant "thinking must happen independently" is owned by prompt design (the synthesis prompt contains no render instruction), not by asking the agent to be disciplined. The coordinator classification (carried / discovered / clean room) belongs at the coordinator because only it can read both the owner's request and the conversation state. The human pause is a genuine architectural element: it makes the thinking correctable, makes the render choice free, and lets one synthesis carry multiple renders.

The design deletes v1 wholesale rather than accommodating it. The transition inventory (Appendix) is verified against the working tree and covers both runtimes. The skill-directory migration is the right precedent for the pack — `setup-global.sh:126-134` already symlinks whole directories, so the Claude lane needs no change, and the three Codex build changes are correctly identified.

## Ponytail Challenge

**Intensity:** Ultra | **Verdict:** CLEAR

The ponytail found the architecture sound. The core two-agent, one-pause shape directly repairs the diagnosed failure. The coordinator classification is well-placed. The skill-directory migration is the right precedent. The deletion inventory is thorough.

One reservation: the **comparison mechanism is over-specified** for its stated purpose (owner curiosity, a few runs). The suffix naming scheme (`__resumed` / `__fresh`), wall-clock and token recordings in synthesis metadata, concurrent-render analysis as a "dangerous combination," and the Codex resume spike as a design-level shape decision — all are scaffolding for problems that haven't happened yet.

The ponytail's smallest architecture: owner-decided pieces stay intact. Strip the comparison infrastructure to "if the owner asks for both, do both sequentially; the coordinator reports times and tokens in the terminal; the owner decides which is better and says so."

A second point: the unscanned-sibling convention (ADR candidate 3) is "a convention that cannot be checked — don't write an ADR for an unchecked convention."

### Disposition

**Comparison mechanism — Partially accepted.** The ponytail correctly identifies that the suffix naming convention, the metadata field list, and the concurrent-render analysis are spec details, not design-level architecture. The design can shed them without losing its shape. However, the *requirement* to record wall-clock time, tokens, and quality is owner-originated (`[OWNER-VERBATIM]`: "A/B test a few times (wall clock time, tokens consumed, and my assessment of artifact quality)"). The comparison capability (both options ship, the owner can ask for both at the pause) is owner-decided and stays. What moves to spec: the specific naming convention, where and how the readings get recorded, and whether renders run concurrently or sequentially.

Concretely: the design's System Confidence section should stop listing "two renders running concurrently against one synthesis" as a dangerous combination — sequential is fine and avoids the whole problem. The suffix scheme and metadata field list should move to the Next-Stage Handoff as spec details rather than being designed here.

**Unscanned-sibling ADR — Rejected with evidence.** The ADR candidate records the *decision* to copy sibling files whole and keep their bodies runtime-neutral. That decision affects every future native skill and would otherwise be invisible to a future author. Whether the convention is enforced by a scan or by discipline is a separate question — the scan is spec's call, but the decision to adopt the convention needs a record. ADR-0006 is the precedent: it records a touch-point convention that is enforced by output structure, not by a mechanical check.

**Codex resume spike timing — Partially accepted.** The spike is better framed as a spec-time question than a design-time shape decision, since the design already handles the fallback ("if Codex cannot resume, Codex simply always takes the fresh-agent branch"). The design correctly identifies it as the first risk to de-risk, but its resolution doesn't change the design's shape — only Codex's implementation. Move from "architectural bet" framing to "spec/epic risk" framing.

## Dimensional Review

### 1. Semantic Model — Pass

The architecture represents the domain directly. Three named steps (collect, synthesize, render) map to the three activities the concept identifies. The two output shapes (checkpoint, plain document) differ only in where judgment renders, not in what the synthesis contains — the semantic model is the same underneath. The policy classification (clean room, carried, discovered) maps to real owner behaviors diagnosed in the concept.

No mechanism category exempts a case whose user-visible meaning is unchanged. No preservation evidence protects defective behavior — v1 is deleted, not preserved.

### 2. Responsibility and Invariant Ownership — Pass

Each guarantee has one clear owner:

- Coordinator: classification, routing, the pause, token/time recording, feedback routing
- Synthesis agent: the narrative, metadata, judgment — one file, then stop
- Render agent: the HTML — inherits the narrative, adds the detail layer
- Owner: correction at the pause, quality judgment, feedback, promotion

The "synthesis prompt contains no render instruction" invariant is owned by the coordinator's spawn-prompt composition — the coordinator is the only entity that composes the prompt, so the invariant has a single enforcement point. This is the design's best structural decision.

### 3. Simplification and Deletion — Pass

The design replaces v1 rather than accommodating it. The deletion inventory (Appendix) lists every file, build-script line, and test reference that needs to change. The transition is verified against the working tree.

Per the ponytail disposition: the comparison mechanism's implementation details (suffix scheme, metadata fields, concurrent-render analysis) should move to spec. This is weight, not a structural problem.

### 4. Abstraction Quality — Pass with Concerns

**Concern: the filename-stem pairing rule.** The design says "every HTML filename resolves to exactly one synthesis file by stem." This is a clean abstraction, but the design also says comparison renders add a suffix (`__resumed` / `__fresh`). The stem-pairing rule plus the suffix convention means parsing filenames to discover relationships. A simpler representation — the synthesis metadata lists its HTML paths — would avoid the parsing, but the design treats the pairing as a file-convention invariant rather than a data-model choice. This is a spec detail, but the design should note that the pairing mechanism has two candidate implementations (filename stem vs. metadata pointer) and let spec choose.

**The two instruction files are necessary and well-scoped.** `design_synthesis.md` covers how to think about a system; `visualize.md` covers how to render it. Each grows independently via its feedback body. A single file would recreate the v1 problem (rendering instructions visible during thinking).

### 5. System Confidence — Pass with Concerns

The design's System Confidence section is honest about what isn't proven. Three unowned proofs are correctly identified. Two concerns:

**Concern: token measurement mechanism.** The design says "The runtime can message a spawned agent to continue it and reports its token usage" (line 69). The architectural bet cites the orchestration helper's `cost` stdout as evidence, but that helper uses headless `claude -p` sessions — which the design explicitly rejects. For in-session `SendMessage` continuation, the token reading comes from the task notification's `usage` field. The design should confirm this is sufficient for the comparison or flag it as a spec question.

**Concern: dropped v1 ADR candidate.** The v1 design proposed an ADR candidate "The checkpoint is a read-only decision-record touch point" — the synthesis agent may read ADRs but never files them, which would amend ADR-0005's touch-point map. The new design drops this candidate without explanation. The synthesis agent still "may read live decisions" (concept SC8, design Core Model). If discovery-led ADR reading is permissive rather than mandatory, it may not need to amend the touch-point map — but the design should say so explicitly, since the v1 design thought it did.

### 6. Decisions and ADR Candidates — Pass with Concerns

Three ADR candidates. All meet the density bar. Specific assessments below in the ADR section.

**Concern:** The bets section presents "Resume means continuing the live synthesis agent in-session" as a rejected alternative to headless sessions. The reasoning is correct (headless plumbing is wrong for an interactive skill), but the bet's provenance is `[AGENT] (ratified)`. The ratification was on the same day as the design — which is fine, but the ADR candidate should note that the only resume precedent in the repo is headless, so a future agent would have strong pattern-matching pressure to copy it.

### 7. Comprehension — Pass

A cold reader can follow: the semantic problem (v1 merged thinking and rendering, so thinking was skipped), the ownership (prompt boundary enforces the split), and why this is simpler than the alternative (one undifferentiated instruction set). The vocabulary section defines terms clearly and the flow diagram is readable.

The coined vocabulary is proportionate — "coordinator," "synthesis," "render," "pairing" all name real things. No term hides a mechanism.

## Issues by Severity

### Critical

None.

### Major

- **M1: Comparison implementation details belong at spec, not design.** The suffix naming scheme, the metadata field list for recordings, and the concurrent-render analysis are spec concerns. The design should state the requirement (the owner can ask for both renders; the results include time, tokens, and quality) and leave the mechanism to spec. Remove "two renders running concurrently against one synthesis" from the dangerous-combinations list — sequential execution avoids the problem and the design doesn't need to solve it. *(Ponytail-derived, partially accepted.)*

### Minor

- **m1: Filename-stem pairing vs. metadata pointer.** The design treats stem pairing as an invariant but the spec may find a metadata pointer simpler. Note both candidates and let spec choose.
- **m2: Token measurement for in-session resume.** Confirm that `SendMessage` continuation reports token usage in the task notification (it does — `usage.subagent_tokens`), or flag as a spec question. The orchestration helper's `cost` stdout is not the mechanism here.
- **m3: Dropped v1 ADR candidate — read-only touch point.** State whether discovery-led ADR reading by the synthesis agent amends ADR-0005's touch-point map or not. The v1 design thought it did; this design is silent.
- **m4: Unscanned sibling enforcement.** The runtime-neutrality obligation for sibling files is convention-only (`test_codex_orchestrator_pack.sh:336-338` scans `-g 'SKILL.md'`). The design correctly says "whether to widen the glob is spec's call." Note this in the ADR candidate so the decision to leave it unscanned (or not) is visible.

## ADR Candidate Assessment

- **"The synthesis prompt withholds the render deliverable"**: **keep**. `[OWNER]` provenance, high density. A future merge recreates the v1 failure — this is the design's most important decision to record.
- **"Resume is in-session subagent continuation"**: **keep**. `[AGENT] (ratified)`. The repo's only resume precedent is headless (`orchestrate-stage.sh`); without this record a future agent would plausibly copy it. Consider noting the headless precedent pressure in the rejected-alternative section.
- **"Native-skill Codex lane: copy whole, keep bodies runtime-neutral"**: **keep**, with a note per m4 that sibling enforcement is unscanned and the glob decision is spec's. The ADR records the convention decision; whether to add a scan is a separate follow-up.

## Resolutions

All findings resolved in the design (2026-08-20, authoring session, per owner-relayed dispositions):

- **M1 — resolved.** Suffix scheme, metadata recording home, and concurrent-render analysis removed; comparison stated as a requirement (both renders on request, sequential, reported on wall-clock/tokens/owner-judged quality) with naming and recording moved to the spec-detail list. "Two concurrent renders" removed from dangerous combinations.
- **m1 — resolved.** Pairing softened to "every HTML resolves to exactly one synthesis"; both candidate mechanisms (filename stem, metadata pointer) named and left to spec.
- **m2 — resolved.** Token-measurement bet corrected: the reading comes from the in-session completion notification's usage report, not the headless helper's cost output.
- **m3 — resolved.** Prior Art now states explicitly: the synthesis agent's ADR reading is discovery-led and permissive, never filing/amending/resolving, and deliberately does not extend the 0002/0005 touch-point map (the archived v1 design's proposed amendment is dropped on purpose).
- **m4 — resolved.** ADR candidate 3 now notes sibling enforcement is convention-only and the scan-widening decision is spec's; the record covers the convention decision itself. (Ponytail's rejection of this candidate stands rejected per the disposition — ADR-0006 precedent.)
- **§6 concern — resolved.** ADR candidate 2's rejected-alternative now names the headless precedent's pattern-matching pressure.
- **ADR candidates — owner override (2026-08-20, post-review).** The owner rejected the withheld-render and in-session-resume candidates as scoped to this one skill, not architecture; both decisions remain recorded in the design itself. Replaced by an `[OWNER]`-grade candidate recording the commands→directory-skills migration pattern (entry point + sibling files, single-symlink install), with the native-skill Codex lane kept as its consequence.

## Verdict

**Approve**

The architecture is sound. The two-agent, one-pause shape directly repairs the three diagnosed v1 failures. The coordinator classification is correctly placed. The invariant ownership (prompt boundary) is the right structural choice. The skill-directory migration is the right precedent. The deletion inventory is thorough and verified. The ponytail challenge returned CLEAR.

One major finding (M1) asks the design to shed comparison implementation details to spec — this is a weight reduction, not a shape change, and does not block approval. Four minor findings are notes for the concept-design author or spec.
