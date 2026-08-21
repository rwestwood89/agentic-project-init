# Spec Review: Coordinator + Synthesis Step (Claude)

**Spec:** `.project/active/coordinator-synthesis/spec.md`
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/coordinator-synthesis/spec-review.md`
**Date:** 2026-08-20

---

## Reality Check

**Concerns — but the work item is right.** The spec is about the correct slice (coordinator
classification + synthesis agent + mandatory pause), the Problem section diagnoses v1 accurately,
and the core requirements are directionally correct. Two things stop it short of trustworthy as a
contract. First, it reopens a question the epic explicitly closed with measured evidence and drops
the epic's one in-scope forward-compatibility requirement. Second, it asserts two things (SC3 and
SC6) that cannot both be true as written. Both are fixable by targeted edits, so the full audit is
worth running.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim: the spec reopens a settled, measured question, and offers design two options
already proven to fail.**

Open Question 1 reads: *"How the SKILL.md references sibling files. Relative path
(`./design_synthesis.md`), absolute path, or an injected variable — design discovers the working
form."*

That is not open. The spike measured it on 2026-08-20
(`.project/active/directory-skill-build-pattern/spike-findings.md`, A8):

- Claude prepends `Base directory for this skill: <absolute path>` to the invocation.
- `pwd` during a skill run is the **project** directory, not the skill's.
- `cat notes.md`, `cat ./notes.md`, `cat reference/deep.md`, and `cat <skill-dir-name>/notes.md` all
  exited 1. Only the absolute path succeeded.

So `./design_synthesis.md` — the first option the spec offers design — is measured to fail. The epic
is emphatic about this: *"The working form of the sibling reference is already measured, not open…
Confirm it holds for this skill; do not re-derive it"* (Item 3 Success/Done State).

Worse, the epic's In Scope for this item carries a requirement the spec does not contain anywhere:

> Write every sibling reference as a **bare filename in prose** — `design_synthesis.md`,
> `feedback/synthesis.md` — never as a path containing the skill's own directory name… writing it
> that way now is what keeps Item 5 from needing a rewrite pass it is forbidden to have (ADR 0010).

This is the one forward-compatibility obligation the epic deliberately put *inside* Item 3 while
pushing everything else Codex to Item 5. It belongs in Known Requirements as `[INHERITED: epic
MENTAL-ALIGN-V2 Item 3 In Scope; evidence spike-findings A8, B5]`, and Open Question 1 should be
deleted, not reworded.

**L1-2 · Direct claim: Required Reading is missing the file that answers L1-1.**

The epic lists three Required Reading files for Item 3. The spec's Related Artifacts lists two. The
missing one is `.project/active/directory-skill-build-pattern/spike-findings.md`, which the epic
annotates: *"read 'Relative paths resolve differently' before authoring any instruction file."* The
spec contract (Stage 3, step 5) requires the epic's Required Reading files be carried into Related
Artifacts. The omission and L1-1 are the same failure seen from two sides.

**L1-3 · Direct claim: SC7 and the requirements disagree about who reads the sibling files.**

SC7: *"the **coordinator** reads its sibling instruction file and nested feedback file."*

Known Requirements, "Synthesis agent behavior": *"The **synthesis agent** reads `design_synthesis.md`
plus both synthesis feedback bodies."*

The concept-design's Core Model sides with the requirement — the coordinator is explicitly *"NOT
responsible for authoring synthesis"* and reads no instruction file. The epic's done-state uses the
"coordinator reads" wording, so the spec inherited the error rather than inventing it, but it can't
carry it forward: which agent does the reading decides whether the mechanism works at all, because
only the invoking agent receives the base-directory line (see L1-4).

**L1-4 · Direct claim: as specified, the synthesis agent has no way to find `design_synthesis.md`.**

The spec requires the synthesis agent to read `design_synthesis.md` and `feedback/synthesis.md`, and
inherits the spawn-prompt contents from the concept-design: *"Short and situational (question,
policy, target path) travels in the spawn prompt."* Question, policy, target path. Not the skill's
base directory.

The base-directory line is handed to the agent that *invokes the skill* — the coordinator, in the
main conversation. A spawned subagent (fork or fresh) receives only the spawn prompt. The spike
never tested a subagent; every read in A6–A9 was made from inside the skill's own invocation
context. And `pwd` for a spawned agent is the project directory, same as the coordinator's, so a
bare filename resolves to nothing.

Concretely: the coordinator must resolve the absolute path from the base-directory line it was given
and put it in the spawn prompt. Whether that is the skill's base directory or the two file paths is
design's call — but the spec's inherited spawn-prompt contents are incomplete in a way that breaks
SC7, and the spec asserts SC7 as verified. Either the spawn-prompt requirement gains this element or
this becomes the item's stated open risk. It should not stay invisible.

**L1-5 · Direct claim: provenance grades move in both directions across the hop.**

`claude-pack/rules/capture-fidelity.md` fixes the absorb mapping: `[OWNER]` → `[NEED]`, `[AGENT]` →
`[INFERRED]`. Three items break it:

- **Upgraded.** *"Carried policy: `subagent_type: \"fork\"`"* is tagged `[NEED]`. The concept grades
  the fork mechanism `[AGENT]`: *"Carried context is a fork, not a transcription; the mechanism
  exists in both runtimes"* (Next-Stage Handoff). `[AGENT]` → `[INFERRED]`. As `[NEED]` it becomes
  settled-eligible and non-relitigable when it should stay challengeable.
- **Downgraded.** The compound rule *"use what we just discussed and read nothing new" = fork with a
  read-nothing-new instruction* is tagged `[INFERRED]`. The concept states it as `[OWNER]` in Key
  Concepts §4: *"Clean room means a fresh agent, not a fork… unless the owner says to use what was
  just discussed and read nothing new."*
- **Downgraded.** The judgment section's contents are tagged `[INFERRED]`. Concept SC5 is `[OWNER]`
  and near-verbatim identical: *"concerns, unresolved uncertainty, disagreements between sources,
  suggested spot checks."* The product-lens noticed this (Observation 1) and waved it through on the
  grounds that the three-region structure is `[NEED]`. That covers the *section existing*; it does
  not protect the *contents* from being relitigated at design.

**L1-6 · Direct claim: the spec drops the skeleton/compression obligation, and its own product-lens
named that as the falsifier.**

Concept SC3 is `[OWNER]`, backed by owner-verbatim text: *"synthesis.md = skeleton. the high level
logic. the narrative. the way you structure the information for maximum compression."* The
concept-design repeats it: *"it stays a short readable page"* (Key Concepts §2). It is the reason
this whole epic exists — the synthesis is the artifact the owner reads at the pause, and the HTML in
Item 4 inherits its narrative.

The spec mentions "the skeleton" once, inside an `[INHERITED]` bullet about section contents. Nothing
requires the synthesis to be short, compressed, or a pointer to detail rather than the detail
itself. SC1 asks only for "narrative, metadata, and judgment sections." A 4,000-word dense document
with those three headings satisfies every success criterion in the spec.

The sharp part: `product-lens.md` states the falsifier as *"…or lets the synthesis be something
other than a skeleton (detailed document rather than compressed narrative with pointers)"* — and
then returns **"Findings: none"** and gate CLEAR. Its own re-derived point includes *"The synthesis
is the skeleton: high-level logic, narrative, maximum compression"*, while the governing-obligation
block the spec wrote from that point drops the clause. The lens named the trap and walked into it.

### Lens 2 — Problem & Approach

**L2-1 · Direct claim: SC3 and SC6 cannot both hold as written, and the conflict is exactly the v1
failure mode.**

SC6: *"no render instruction is visible to the synthesis agent."*
SC3: *"Under carried policy, the synthesis agent is a **fork**."*

A fork inherits the conversation. The coordinator's conversation contains `SKILL.md`, which the
coordinator read to know what to do — and `SKILL.md` must describe the pause and the render choice,
because the spec requires the coordinator to offer it. So under carried policy the synthesis agent
sees the render step by inheritance, no matter what the spawn prompt says.

The concept-design's invariant is carefully worded — *"The synthesis agent's initial **prompt**
contains no instruction to produce an HTML"* — and survives a fork. SC6 as the spec writes it does
not. That is not just wording: the entire second bet of the concept is that *"an agent whose prompt
contains the final deliverable races to it,"* and carried policy is the one path where the deliverable
leaks in anyway. Under the policy the owner cares most about, the repair may not hold.

Design can mitigate (keep render detail in `visualize.md`, keep `SKILL.md`'s render mention to a
routing stub, restate the stop-here boundary in the fork's prompt), but the spec should decide
whether it is stating the prompt-scoped invariant (achievable) or the visibility invariant
(not achievable under a fork), and say which. Right now it states the stronger one and cannot meet it.

**L2-2 · Question to the user: Item 2 is not actually finished, and the loose end is the exact
confound SC7 is meant to resolve.**

`CURRENT_WORK.md:19` says *"Item 2 (release the name) done."* The two pack files are gone, but both
installed symlinks are still present and now dangling:

```
~/.claude/commands/_my_mental_model.md -> …/claude-pack/commands/_my_mental_model.md   (target missing)
~/.claude/scripts/mental-model-builder.md -> …/claude-pack/scripts/mental-model-builder.md  (target missing)
```

Item 2's Done State required their removal, and said why: leaving the command symlink means Item 3's
first `/_my_mental_model` faces *"a stale command symlink **and** a real skill directory under the
same name, which is precisely the command-versus-skill precedence question the probe could not
settle"* (spike-findings A3). The spike proved a dangling *skill* symlink is inert (A10); a dangling
*command* symlink was never tested.

SC7 is the epic's directory-skill-resolution proof. **Do you want the two `rm`s done before this spec
moves forward, or should the spec state the confound as a precondition on SC7?** My call: two `rm`s
now, it is a minute of work and it makes SC7 mean what it claims.

**L2-3 · Question to the user: should this item author `feedback/synthesis.md` at all?**

SC8 requires the shared starter feedback file to ship *"with useful cross-project guidance, not
empty."* That traces to the epic's product-lens Observation 1, so it is correctly captured.

But hold it against your own words in the concept: *"95% of the time the feedback an agent writes is
REALLY bad and needs a revision to be generalized and useful."* The whole two-tier design exists
because agent-written feedback needs your rewrite before it is shareable. This spec asks an agent to
write the shared body **before a single run has happened** — no run to learn from, no failure to
generalize from. The most likely output is plausible-sounding filler that then ships to every project
and gets read by every future run.

Three ways to go: (a) keep SC8 and accept that you will rewrite the file by hand; (b) ship the file
with real content you dictate, treating the agent's draft as a starting point at the pause; (c) ship
it near-empty with structure only, and let it fill from real runs as designed. **Which?** I lean (b) —
the loop only works if the shared body starts honest.

**L2-4 · If-then tradeoff: `subagent_type: "fork"` in `SKILL.md` breaks the Codex parity strategy,
and the automated guard will not catch it.**

Three requirements name `subagent_type: "fork"` as the mechanism. If that literal token lands in
`SKILL.md`, it collides with ADR 0010's invariant: *"Native skill bodies (entry and siblings) contain
no runtime-specific delegation vocabulary"* — because there is no sanitization pass for native
skills, by design, and Item 5 is forbidden from adding one.

The guard is worse than useless here. `test_codex_orchestrator_pack.sh:336` greps for
`subagent_type=` — with an equals sign. `subagent_type: "fork"` does not match. So this breaks Codex
silently at Item 5 rather than failing the build.

This is fine **if** you intend Item 5 to hand-edit the delegation phrasing (a hand edit is not the
forbidden "rewrite pass"). It is a problem **if** Item 5's premise is that Item 3's output is already
parity-clean. Note the spec is asymmetric about this today: it carries the minor Codex-forward
constraint (frontmatter description must be plain prose) while its Non-Goals says "Anything Codex…
(Item 5)", and it drops the major one (L1-1). Whichever way you decide, the spec should be consistent
about which Codex obligations Item 3 owns.

### Lens 3 — Pipeline Risk

**L3-1 · Rewrite request: the same fact appears in two sections under two different tags.**

Under "Synthesis agent behavior": `[INHERITED: concept-design §Core Model]` — *"the skeleton:
narrative, per-section claim with register and provenance, the visual form that fits each section,
and a pointer to where details live."*

Under "Synthesis file structure": `[INFERRED]` — *"**Narrative** (middle): … Each section states its
claim, the claim's provenance, the visual form that would fit it…, and a pointer to where the
underlying detail lives."*

Same content, two homes, two grades. The spec contract is explicit: *"There is exactly one home for
each idea."* Pick one home and one grade — the `[INHERITED]` grade is the correct one, since the
concept-design states it directly.

**L3-2 · Direct claim: nothing in the spec constrains the shape of the artifact this item exists to
produce.**

Follow the chain. The compression obligation is absent from Known Requirements (L1-6). No success
criterion tests it. The Non-Goals hand off *"the exact prose content of `design_synthesis.md`"* as an
authored deliverable. And Open Question 5 defers *"whether `design_synthesis.md` prescribes section
types … or leaves the structure entirely to the agent."*

Net effect: two strong implementers reading this spec produce materially different synthesis files,
and both pass every stated criterion. For an item whose entire value is "the thinking actually
happens and the owner can read it," that is the wrong place to be under-specified. Adding the
compression requirement from L1-6 fixes most of it — the deferrals are then deferrals of *how*, not
of *what good looks like*.

**L3-3 · Question to the user: the compound policy has no success criterion, and it is the design's
named never-exercised combination.**

The concept-design's System Confidence section names it directly: *"Dangerous, never-exercised
combination: fork + clean-room restriction."* The spec carries it as one `[INFERRED]` bullet
(mis-graded, see L1-5) with no matching success criterion — SC3, SC4, SC5 cover the three pure
policies only.

**Is exercising fork + clean-room in scope for this item, or does it wait?** If it is in scope it
needs its own criterion. If it waits, it belongs in Non-Goals, not buried as an inferred requirement.

### Lens 4 — Hygiene

**L4-1 · Rewrite request:** SC7 bundles three separate obligations into one checkbox — the slash name
resolves to the skill directory, the sibling files are readable, and the working reference form is
recorded. They are proven by different observations and can fail independently, so a single tick
cannot mean "done." Split it. (The third obligation also changes shape under L1-1: it becomes
*confirm the measured form holds here*, not *discover the form*.)

### Lens 5 — Reader Comprehension

**L5-1 · Rewrite request:** the governing-obligation block at the end of the Problem section is a
five-line bracketed run-on carrying six ideas — the grade, the re-derivation and its three source
IDs, on-demand invocation, question-led output, three instructable steps, the pause with its three
owner actions, and no-flags classification. A reader has to hold all of it before any of it lands,
and the one sentence that matters most for this item (the pause is mandatory, and the synthesis is a
compressed skeleton) is buried mid-clause.

Per `claude-pack/rules/working-voice.md`: lead with the point, one idea per sentence, decompose into
points. What needs to be true: the obligation reads as two or three plain sentences a tired engineer
absorbs on one pass, with the provenance grade and source IDs alongside rather than woven through.

**L5-2 · Note, no action:** the rest of the spec reads well. Section boundaries are clean, the
`[INHERITED]` cites are specific, and the Problem's first two paragraphs state the v1 failure and
this item's slice plainly. The findings above are about content, not voice.

---

## Engagement Summary

**Overall take:** The work item is right and the spec is 80% of a good contract, but it drops the one
epic requirement that was deliberately placed inside this item and reopens a question the spike
already answered — pointing design at two forms measured to fail. Separately, it asserts a
prompt-isolation guarantee (SC6) that a fork structurally cannot provide, which is the same class of
failure the epic exists to repair. Neither is deep; both need to be fixed before design starts.

**Here's what I need you to weigh in on:**

1. **[L1-1, L1-2]** The sibling-reference form is measured, not open. Delete Open Question 1, add the
   bare-filename-in-prose requirement from the epic's In Scope, and add `spike-findings.md` to
   Required Reading. This is the one thing that would make design re-derive a wrong answer.
2. **[L2-1]** SC6 says no render instruction is visible to the synthesis agent; SC3 says carried
   policy forks the conversation, which carries `SKILL.md` and the render step with it. Decide which
   invariant you're buying — the prompt-scoped one (achievable) or the visibility one (not, under a
   fork) — and say so.
3. **[L1-4]** A spawned agent never receives the base-directory line; only the invoking coordinator
   does. As written, the synthesis agent is told to read `design_synthesis.md` with no way to locate
   it, and the spike never tested a subagent. Either the spawn prompt carries the resolved path or
   this becomes the item's stated open risk.
4. **[L1-6, L3-2]** The skeleton/compression obligation (concept SC3, owner-verbatim) is missing
   entirely — no requirement, no criterion — and the product-lens named exactly that as its falsifier
   before returning "Findings: none." Nothing in the spec would catch a synthesis that is a long dense
   document.
5. **[L2-2]** Item 2 is recorded as done but left two dangling symlinks, including the command one
   that recreates the A3 precedence confound SC7 exists to settle. Two `rm`s, or state it as a
   precondition.
6. **[L2-3]** Should an agent author the shared starter feedback body before any run exists? Your own
   concept says 95% of agent-written feedback needs your rewrite. Options in L2-3; I lean toward you
   dictating the real content.
7. **[L1-5]** Three provenance grades moved across the hop — the fork mechanism upgraded `[AGENT]` →
   `[NEED]`, the compound clean-room rule and the judgment-section contents downgraded `[OWNER]` →
   `[INFERRED]`. The downgrades let design relitigate things you settled.

---

## Resolutions

Recorded 2026-08-20 with the owner. Entries keyed by finding ID; this is what the spec agent reads
to incorporate the review.

### Resolved

- **[L2-1] — narrow the wording, add nothing.** Owner's call: a forked agent knowing that an HTML
  comes later does not damage the thinking. The point of the split is that the task the agent is
  handed is focused on processing, not that the render step is invisible. So SC6 drops "no render
  instruction is visible to the synthesis agent" in favour of the prompt-scoped form the
  concept-design already uses — the synthesis agent's prompt contains no instruction to produce an
  HTML. **No mitigation requirement, and no constraint on how Item 4 writes its half.** Owner
  explicitly rejected further engineering here.

- **[L1-6, L3-2] — the owner supplied the definition; capture it as a requirement.**

  `[OWNER-VERBATIM]`, 2026-08-20, on what makes a good synthesis:

  > - It is readable and interpretable by someone familiar with the overall project, but has none of
  >   the details
  > - It progresses quickly enough not to get bogged down in details. to the audience I just
  >   described, we need to make it from the introduction to the conclusion in no more than 5-6
  >   logical steps
  > - If further detail is required, it should come later. Like the consulting approach, you should
  >   be ok with getting cut off any any point in time. Important stuff up front.
  > - It is extremely important that the **narrative logic is clear**. This is what I mean by the
  >   "skeleton". Any smart person can read this and tell if the thought process is sound, even
  >   without the details. It really is what sets up the abstractions or "compression" of what is
  >   being presented

  And, same turn, as hard limits:

  > - the "body" can be no longer than 150 lines
  > - any additional information (if deemed important) must be in an appendex which doesn't count
  >   towards line count. but the "body" is what needs to pass the narrative logic test.

  **Force:** the four bullets are the standard the synthesis is judged against, not illustrations.
  The 5-6 logical steps and the 150 lines are owner-stated numbers — carry them as numbers, do not
  soften to "short" or "a few". The body/appendix split is structural: the appendix is exempt from
  the line count, and only the body is judged on narrative logic.

  **Spec agent, on absorbing this:** these become owner-stated requirements, not inferences. The
  "narrative logic is clear" bullet is the governing one — the owner names it as what "skeleton"
  has meant all along, so it belongs in the Problem's governing obligation, not only in the
  requirement list. It also constrains Open Question 5 (whether `design_synthesis.md` prescribes
  section types): whatever structure that file offers has to serve the 5-6 step progression and the
  cut-off-at-any-point ordering.

- **[L1-1, L1-2] — accepted as written.** Delete Open Question 1. Add the bare-filename-in-prose
  rule as an inherited requirement from the epic's In Scope, evidenced by spike-findings A8/B5. Add
  `.project/active/directory-skill-build-pattern/spike-findings.md` to Required Reading.

- **[L1-5] — accepted.** Restore the concept's grades: the fork mechanism is agent-grade, not
  owner-stated; the compound clean-room rule and the judgment-section contents are owner-grade.

- **[L3-1] — accepted.** The narrative-section contents get one home, carrying the inherited grade.

- **[L4-1, L5-1] — accepted.** Split SC7 into its separate obligations. Rewrite the Problem
  section's bracketed governing-obligation block as plain sentences.

- **[L2-4] — dropped by owner.** Codex phrasing waits for Item 5, per the epic. A hand edit there is
  not the forbidden rewrite pass.

- **[L1-6 follow-up] — the 150-line cap covers the narrative only.** Owner's call: the "body" the
  owner capped is the narrative — the part the narrative logic test applies to. The metadata header
  and the judgment section sit outside the count, as the appendix does. No second cap on them;
  keeping them proportionate is a matter of looking at the file, not a rule.

- **[L1-4] — state the outcome, leave the mechanism to design, no probe.** The spec gains one
  requirement: the synthesis agent can reach its instruction files. How the coordinator gets the
  path there is design's call. No spike — if it is broken, the first run says so in thirty seconds,
  which is cheaper than probing for it.

- **[L2-3] — the shared starter feedback file ships as a header only.** Owner's call: a header plus
  a line saying what belongs in the file, and it fills from real runs. Rationale: the real standard
  now lives in `design_synthesis.md` (see L1-6), so the feedback body has nothing to carry on day
  one, and agent-invented shared feedback written before any run has happened is exactly what the
  two-tier design exists to avoid. SC8 changes from "useful cross-project guidance, not empty" to
  the file existing with its header and stated purpose.

- **[L3-3] — leave it as a plain requirement.** Fork plus a read-nothing-new instruction stays one
  classification rule. No separate success criterion, no special handling, and drop the
  "never-exercised dangerous combination" framing. Owner's call: it is a case, not a feature.

- **[L2-2] — out of scope, owner's call.** The two dangling symlinks under `~/.claude/` are not part
  of this work item. No spec change; no action taken.

---

**Verdict:** Revise

**Review status:** Final — every finding is dispositioned (2026-08-20, with the owner).

**Next Steps:** Re-run `/_my_spec` (or return to the spec-agent session) and point it at this review
to incorporate. Work the Resolutions section top to bottom; the L1-6 entry carries owner-verbatim
text that must survive into the spec at its stated force. The reviewer does not edit the spec.
