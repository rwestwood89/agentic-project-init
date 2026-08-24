# Spec Review: Directory-Skill Codex Adapter

**Spec:** `.project/active/directory-skill-build-pattern/spec.md` (revision 2)
**Contract:** `claude-pack/commands/_my_spec.md`
**Review File:** `.project/active/directory-skill-build-pattern/spec-review.md`
**Date:** 2026-08-20

---

## Reality Check

**Sound.** The spec is about the right work item, the Problem section is accurate where I could
check it, and the core requirements point the right way. I verified the load-bearing code cites
directly: the two `-mindepth 2 -maxdepth 2 -name 'SKILL.md'` walks (`build-codex-pack.sh:395`,
`setup-codex.sh:267`), the allowlist check keyed pack-side (`:370`), the flat lane (`:338-365`),
the substitution dictionary (`:136-160`), the description path (`:243-255`), the install guard
(`setup-codex.sh:19-22`), the Claude whole-directory symlink (`setup-global.sh:126-134`), and the
false symlink claims at `build-codex-pack.sh:521` / `CLAUDE.md:53`. All accurate. The seven-spot
table's line numbers all land on the right lines of `SKILL.md`, and `design_synthesis.md:30` really
is the only sibling hit.

Full audit follows. The findings are about **completeness and criterion coverage**, not direction.

---

## Audit

### Lens 1 — Faithfulness

**L1-1 · Direct claim:** *The seven-spot table is incomplete, and the spec has the evidence to know
it.* Three more lines of `SKILL.md` are harness-specific, and they are the ones that decide where
the skill's actual output lands:

| Line | Text | Why it differs per harness |
|---|---|---|
| `SKILL.md:51` | `mkdir -p .project/mental-alignment/runs` | relative to cwd |
| `SKILL.md:54` | target path `.project/mental-alignment/runs/{...}.md` | relative to cwd |
| `SKILL.md:66` | `.project/mental-alignment/feedback-synthesis.md` | relative to cwd |

The spec's own `[HARD]` says Claude runs a skill with the **project** directory as cwd and Codex
runs with the **skill** directory as cwd (A8, B5). Applied to these three lines, that means on
Codex the coordinator creates `~/.agents/skills/my-mental-model/.project/mental-alignment/runs/`
and writes the synthesis there — the one artifact the skill exists to produce, in the wrong place,
with no error. This is the exact silent one-sided failure the Problem section says the item exists
to remove.

Two consequences the spec should absorb:

- SC4 counts "seven known spots." Design will treat the table as the work list, so it needs to be
  right or it needs to stop claiming a count.
- These three are **not translatable by a substitution dictionary**. There is no string the adapter
  can swap `.project/…` for, because the Codex-side skill has no way to name the project root from
  inside its own directory. That makes them a different class of problem from the other seven, and
  it is the one place where "extend the same adapter pattern" does not reach.

Smaller point in the same table: some entries are paraphrases, not literal strings — `SKILL.md:84`
actually reads "using the `Read` tool (not\n`cat` via Bash — that clutters the terminal)". A
substitution dictionary needs exact source strings, so design will have to re-derive them from the
file anyway.

**L1-2 · Question to the user:** *The Codex-cwd premise is contradicted by ~30 shipped skills, and
I can't resolve it from here.* Spike B5 found `pwd` inside a Codex skill run returns the skill's own
directory, twice, on two probes. But `dist/codex/skills/my-spec/SKILL.md:63` instructs
`mkdir -p .project/active/{feature-name}`, and roughly thirty command-derived Codex skills do the
same thing. If B5 generalizes to normal skill runs, every one of those has been writing project
files into `~/.agents/skills/<name>/`. Nothing in `dist/codex/AGENTS.md` mentions a working
directory either way.

So one of two things is true, and they lead to different work:

- **B5 generalizes.** Then L1-1's three lines are real breakage, *and* there is a much larger
  pre-existing defect across the command lane that this item did not sign up for. The spec should
  say which half it is taking.
- **B5 is an artifact of how the probe ran** (Codex may set cwd only for the probe's own shell
  calls, or the owner's session was rooted differently). Then the `[HARD]` is overstated, and any
  rewrite that tells a Codex agent "your working directory is the skill directory" would be wrong.

**Have you seen a Codex `$my-spec` (or similar) run actually write `.project/active/…` into the
repo?** That single observation settles it. Recommendation if it can't be settled cheaply: re-run
one Codex probe that does `pwd` *and* writes a relative file, and record where the file lands —
it's a five-minute check that de-risks the item's central `[HARD]`.

**L1-3 · Direct claim:** *Two of the six "leftovers" are misidentified.* The Problem section says
v1 wiring "is still in the tree" and lists six places. Two of them contain no v1 surface:

- **`scripts/test_docs.sh`'s retired list** is line 59:
  `RETIRED="_my_code_review _my_code_quality _my_project_manage _my_audit_implementation _my_review_design"`.
  `_my_mental_model` is not in it. Nothing there needs deleting — *adding* the name is new work,
  and it would then fail against the stale `README.md:131` row, which is the actual leftover. The
  companion check (every shipped command listed in README) stopped requiring that row the moment
  the command file was deleted, so today nothing catches it.
- **`scripts/uninstall-project.sh:108-114`** lists `example-skill.md` and `show-me`. No
  mental-model reference exists anywhere in either uninstall script (`grep -i mental` returns
  nothing). The epic labels this entry "skill list," which is accurate — it is coupled to the
  `example-skill` directory conversion, not to v1. The spec dropped the qualifier and the Open
  Question ("what `uninstall-project.sh:108-114` should list") inherits the confusion, along with
  the fact that its trigger is a requirement the spec marks droppable (see L3-2).

SC8 ("No v1 surface remains, and no script or test references one") will be checked against this
list, so the list should be right.

**L1-4 · Rewrite request:** *The name-mapping `[INHERITED]` cites no source, and understates its
own force.* Capture-fidelity requires every `[INHERITED]` item to cite where it came from; this one
doesn't (the sources are ADR 0011's invariants and
`.project/concepts/mental-alignment-skill-design.md:255`). More importantly, the bullet says the
mapping is "required for consistency with the ~33 command-derived skills … not by Codex." It is
stronger than consistency. `claude-pack/commands/_my_epic_plan.md:44` and
`_my_concept_design_review.md:219` both reference `/_my_mental_model`; the command lane rewrites
that to `` `my-mental-model` `` (`build-codex-pack.sh:155-158`, `COMMAND_SKILL_PREFIX="my-"`). Ship
the native skill as `_my_mental_model` and those two Codex skills offer the owner a skill name
nothing answers to. Please state the breakage, not the tidiness — a reader deciding what is
droppable needs to know this one isn't.

**L1-5 · Direct claim:** *"fails the existing dist scan today" is not true today.*
`claude-pack/skills/_my_mental_model/` is not in `NATIVE_SKILL_ALLOWLIST`, so it is absent from
`dist/` and the scan passes. The claim you want is "is a phrase the scan would catch if it reached
`dist/` untranslated." Worth being exact, because the same check reveals something useful: the scan's
regex matches `subagent_type=` with an **equals sign**, while `SKILL.md:75` and `:78` use the colon
form. Exactly one of the seven spots (`` `Agent` tool `` at `:77`) would trip it. That is directly
relevant to the Open Question about whether the scan survives.

### Lens 2 — Problem & Approach

**L2-1 · Direct claim:** *The resumed-render requirement contradicts the Non-Goals and is covered by
no criterion.* Known Requirements carries `[INHERITED]` "The Codex resumed-render path gets wired
here … the comparison must state that limitation rather than estimate." Non-Goals says
"Mental-alignment behavior — epic Items 3 and 4. The phrase-level adjustments this item requires
are the exception, and they change wording, not behavior." Wiring a render path and deciding how a
comparison reports a missing token count is behavior, not wording. The upstream record is split
too: the epic's Item 1 says the token-measurement constraint is "carried into Item 4," while Item
5's In Scope says "Wire the Codex resumed-render path." No success criterion covers it either way,
so as written it can silently not happen. Pick an owner and make the spec say so.

**L2-2 · Question to the user:** *SC3 and SC5 both hinge on a policy that has never been proven on
any runtime.* `CURRENT_WORK.md` records Item 3 as complete with "Carried and clean-room policies
untested" and its epic done-state at 4/6. SC3 requires carried-policy forking to work on Codex, and
SC5 requires it to "still" work on Claude — but there is no baseline for "still." So this packaging
item would absorb the first-ever proof of a behavior Item 3 owns, and if carried policy turns out
to be broken for reasons unrelated to the phrase edits, the debugging lands here.

Two clean options. **Close Item 3's remaining two done-state boxes first**, and SC5 becomes a real
regression check. Or **scope SC5 to what was actually proven** — the skill locates its directory,
the synthesis agent reads its two instruction files, discovered policy produces a run — and let
carried policy stay Item 3's. I'd take the first if it's cheap; a fork check is one invocation.

**L2-3 · If-then tradeoff:** *The dictionary is a global list; two of the seven spots are one-off
sentences from one file.* `sanitize_command_body_for_skill` applies every substitution to every
body it processes. Entries like `subagent_type: "fork"` → `fork_turns: "all"` belong there — that's
stock vocabulary. But "The skill preamble gives this skill's base directory" is a sentence from one
skill, and putting it in a global list turns the dictionary into a per-file patch table that fires
on any body containing the string. This is fine **if** the pack stays at a handful of directory
skills, and a growing maintenance hazard **if** ADR 0009's migration sweep eventually lands. The
spec's Open Question already asks where the dictionary lives (inline vs. shared table); consider
extending it to ask whether substitutions are global or scoped per source, because that changes the
shape of the answer, not just its location.

### Lens 3 — Pipeline Risk

**L3-1 · Direct claim:** *SC7 is unsatisfiable as written and would corrupt append-only records.*
"Every document citing ADR 0010 is updated to 0011." There are 56 mentions of `0010` across 15
files outside `dist/`. Several must keep citing it:

- `.project/adr/INDEX.md` — must keep the superseded row (`0010 · … · superseded → 0011`).
- `.project/adr/0010-*.md` itself, and `0011`, which must name what it supersedes.
- `.project/active/directory-skill-build-pattern/product-lens.md`,
  `.../render-switch-feedback/product-lens.md` — **append-only** ledgers. Editing a past block to
  say 0011 breaks the rule that makes them trustworthy.
- `spike-findings.md` — a dated record of what was true when the probe ran.

Known Requirements also says "~10 existing citations," which is off by 50%. The criterion needs to
be scoped to documents that still *steer* future work (the epic, `CURRENT_WORK.md`, the two active
specs, `design.md`) and to say explicitly that historical and append-only records keep their 0010
citations.

**L3-2 · Direct claim:** *SC9 depends on a requirement the spec marks optional.* SC9 is "The pattern
is generic: a second directory skill with siblings ships the same way." The only other directory
skill in the pack is `claude-pack/skills/show-me/`, and it has exactly one file — no siblings. So
SC9's subject can only be the converted `example-skill`, which the spec records as **[NEED]** and
then, in the same bullet, "droppable at the owner's discretion." An unconditional criterion resting
on an optional requirement means design cannot tell whether to plan for it. Separately: a `[NEED]`
is an owner-stated outcome the design must satisfy — tagging something `[NEED]` and calling it
droppable in one breath is a tag that doesn't mean anything. Either commit to the conversion (and
SC9 stands), or drop it (and SC9 must name a different subject or go).

**L3-3 · Rewrite request:** *Two documented-false claims have no criterion.* The spec establishes
that `build-codex-pack.sh:521` ("Codex reads copies, not symlinks") and `CLAUDE.md:53` ("Codex's
current expectation") are false, and epic Item 5's In Scope says to "correct that line plus
`CLAUDE.md:53` **either way**" — i.e. regardless of which install strategy wins. The spec keeps the
strategy choice in Open Questions but drops the correction obligation entirely. SC8 doesn't reach
it; neither of these is a v1 surface. Add a criterion, or state in Non-Goals why the falsehoods
stay.

**L3-4 · Direct claim:** *The loudest owner decision in the spec has no matching criterion, and it
conflicts with the allowlist's design.* `[OWNER-VERBATIM]` "if the build fails, the build fails" is
recorded, with the gloss: "Where the build can know something is wrong — a missing allowlist entry,
a malformed skill directory — it fails rather than exiting 0." No success criterion covers it, so
design can satisfy every listed outcome and leave silent exclusion exactly as it is — which is the
hazard `[HARD]` #4 names.

There is also a real tension the spec doesn't surface. `NATIVE_SKILL_ALLOWLIST` is **opt-in by
design**: it is how a Claude-only skill stays out of the Codex build. Making the build fail on a
skill directory that isn't listed converts opt-in into mandatory, and the next Claude-only skill
someone drops in `claude-pack/skills/` breaks the build. Possible readings of the owner's decision:
fail only when a listed skill is malformed; fail on an unlisted directory unless it carries an
explicit opt-out marker; or warn loudly on unlisted rather than fail. This is a spec-stage question
(it changes what "done" means), not a design detail.

### Lens 4 — Hygiene

**L4-1 · Rewrite request:** The two harness differences (where the skill folder is, how to spawn a
context-inheriting agent) are enumerated in full in the Revision note *and* in the Problem's "The
part ADR 0010 got wrong" *and* in ADR 0011. The spec contract asks for one home per idea. The
Revision note earns its place as orientation for a reader mid-revision; the enumeration inside it
doesn't. Trim it to what changed and why, and let the Problem carry the mechanism.

### Lens 5 — Reader Comprehension

**L5-1 · Rewrite request:** "smell-1-shaped" appears twice — once in the Problem-adjacent Open
Questions ("Two lanes sharing one hand-maintained substitution list is smell-1-shaped") and once in
the ledger. A reader who hasn't memorized the product-lens smell numbering can't decode it, and it
sits on a line that is otherwise the clearest statement of a real risk. Say the thing plainly: two
hand-maintained copies of the same list, kept in step by nobody. Anchor the term in parentheses if
you want to keep the pointer.

---

## Engagement Summary

**Overall take:** The item is pointed at the right thing and the code claims hold up under checking
— which is unusual and worth saying. What it gets wrong is coverage. The phrase inventory misses
the three lines that decide where the skill's output actually lands, one success criterion is
literally unsatisfiable, another has no subject unless an optional requirement happens, and the
loudest owner decision in the document ("if the build fails, the build fails") is attached to no
criterion at all. All fixable in the spec; none of it changes the work item.

**Here's what I need you to weigh in on:**

1. **[L1-2]** Does a Codex skill run really have the skill directory as its working directory? Thirty
   shipped command skills write relative `.project/…` paths and would be broken if so. If you've
   seen `$my-spec` write into the repo on Codex, say so and the `[HARD]` needs softening; if not,
   one five-minute probe settles it. Everything in L1-1 hangs off the answer.

2. **[L1-1]** Assuming the cwd finding holds: `SKILL.md:51`, `:54`, and `:66` are three more
   harness-specific spots, and unlike the other seven a substitution dictionary **cannot** fix them
   — the Codex-side skill has no way to name the project root. Do you want them in scope here
   (making it ten spots, one of which needs a structural answer), or handled by Item 4 as part of
   the render/output work?

3. **[L3-4]** "If the build fails, the build fails" — what should the build actually fail on? Failing
   on a missing allowlist entry turns an opt-in list into a mandatory one and breaks the next
   Claude-only skill someone adds. Pick the rule (malformed-only / unlisted-unless-opted-out /
   warn-loudly), and it becomes a success criterion.

4. **[L3-2]** Is the `example-skill` directory conversion in or out? SC9's "a second directory skill
   with siblings" has no subject without it — `show-me` is a single file. In means SC9 stands and
   `uninstall-project.sh:108-114` needs updating; out means SC9 needs rewriting or deleting.

5. **[L3-1]** SC7 should be scoped. Fifty-six mentions of 0010 across fifteen files, including two
   append-only product-lens ledgers, the spike findings, and the ADR index row that must keep saying
   "superseded → 0011." Which documents do you actually want re-pointed?

6. **[L2-1]** Who wires the Codex resumed-render path — this item or Item 4? The spec asks for it in
   Known Requirements and forbids it in Non-Goals, and the epic says both.

7. **[L2-2]** Carried policy has never been verified on either runtime. Close Item 3's last two
   done-state boxes first, or scope SC5 down to what was actually proven?

---

## Resolutions

Recorded 2026-08-20 in an owner walkthrough. Owner-originated calls are marked; the rest are
reviewer dispositions the owner did not need to arbitrate.

### Owner decisions

- **[L1-2] — the project directory is the correct behavior; probe the cause.** Owner: *"it SHOULD
  be this — moving to the skill directory would be really dumb. so yes, we need to run a small
  probe to figure out why it would be changing directories and how to prevent it."* The intent is
  to **fix the cause, not adapt to it**. Grade: `[OWNER]`, quote verbatim.

  The probe must answer three things, not one — the third exists because removing the
  skill-directory working directory removes the only way a Codex skill currently locates its own
  files (Claude supplies a base-directory line; Codex supplies nothing but the working directory):

  1. Where does a *relative write* actually land during a Codex skill run? (The existing probe only
     read `pwd`; it never wrote a file, which is the operation that breaks.)
  2. Is the working directory controllable — a setting, a frontmatter field, an invocation flag?
  3. If it is forced to the project directory, how does the skill then reach its own siblings?

- **[L2-1] — Item 4 is Claude-only; Item 5 owns all Codex adaptation.** Owner: *"Item 4 is not
  going to worry about Codex whatsoever. Item 4's job is to ship a usable claude skill. that's it.
  Item 5 needs to figure out how to make it work for codex."* Grade: `[OWNER]`, quote verbatim.

  This resolves the contradiction rather than picking a side of it. The spec's Non-Goal —
  "Mental-alignment behavior … the phrase-level adjustments this item requires are the exception,
  and they change wording, not behavior" — is wrong and must be rewritten. The correct boundary:
  **this item does not change what the skill does on Claude, and does whatever it takes to make the
  same capability work on Codex.** That covers the phrase edits, the working-directory problem, the
  resumed-render path, and reporting the missing token count — all of it here, none of it Item 4's.

- **[L3-4] — the requirement is not real; delete it.** Owner, on the gloss the spec attached to
  *"if the build fails, the build fails"*: *"when I said that I meant 'if it fails for any reason'.
  we are not adding more checks. … I am not here to try and catch a one-time issue — we will test
  it, find out, fix it."* Grade: `[OWNER]`, quote verbatim.

  The spec's second sentence — "Where the build can know something is wrong — a missing allowlist
  entry, a malformed skill directory — it fails rather than exiting 0" — is an agent inference
  carrying an owner quote's authority. **Delete it.** Keep the quote, meaning what the owner meant:
  no tolerance is built for failure, and no new failure conditions are added. The allowlist stays
  opt-in and silent. Detection posture is unchanged from what ADR 0011 already records — the
  detector is the skill failing on the runtime.

  Reviewer note on its own error: this finding asked *which* checks to add rather than *whether the
  requirement was real*. The requirement was the defect.

- **[L3-2 + the flat-lane open question] — delete `example-skill.md`.** Owner: *"delete it."*
  Grade: `[OWNER]`, quote verbatim. Consequences to fold into the spec:
  - The `[NEED]` for converting it to directory form comes out entirely.
  - SC9 ("the pattern is generic: a second directory skill with siblings ships the same way") comes
    out. With `example-skill` gone and `show-me` a single file, it has no subject, and a synthetic
    fixture built only to satisfy it contradicts the posture in L3-4.
  - The flat native-skill lane (`build-codex-pack.sh:338-365`) loses its only user and is
    **deleted**, not guarded — "keep it and make it fail loudly" is ruled out by L3-4. The Open
    Question collapses into an action.
  - `scripts/uninstall-project.sh:109` (`for f in example-skill.md`) drops that entry.

### Reviewer dispositions (no owner arbitration needed)

- **[L1-1] — PARKED, dependent on the L1-2 probe.** `SKILL.md`'s project-relative paths are real
  harness-specific spots, but whether they get rewritten in the skill or fixed underneath by
  correcting the working directory depends on what the probe finds. Dependent conclusions parked
  rather than guessed. See the staleness note below — the count has grown.

- **[L3-1] — SC7 scoped by the repo's own rules.** Re-point only documents that still steer future
  work: the epic, `CURRENT_WORK.md`, this item's spec and design, and `.../coordinator-synthesis/`
  and `.../render-switch-feedback/` where 0010 is cited as live guidance. Leave 0010 citations in
  place in: `.project/adr/INDEX.md` (the superseded row is the record), `0010` and `0011`
  themselves, `spike-findings.md` (a dated record), and every `product-lens.md` block (append-only;
  editing a past block breaks the property that makes the ledger trustworthy). The "~10 existing
  citations" figure in Known Requirements is wrong — 56 mentions across 15 files. Grade:
  `[AGENT]`.

- **[L2-2] — reword, don't reschedule.** Carried policy has never been verified on any runtime, so
  the Claude-side criterion cannot say the skill "**still**" works. Given the L3-4 posture ("we will
  test it, find out, fix it"), it is verified here for the first time, not re-verified, and a
  Claude-side break found here is fixed here rather than handed back to Item 3. Grade: `[AGENT]`.

- **[L1-3, L1-4, L1-5, L4-1, L5-1] — accepted as written**, for the spec agent to apply. Summarised:
  drop `test_docs.sh` and `uninstall-project.sh:108-114` from the v1-leftovers list (neither
  contains a v1 surface; the uninstall entry belongs to the `example-skill` deletion above); cite a
  source on the name-mapping `[INHERITED]` item and state its real force (two live commands break
  without it, it is not consistency); fix "fails the existing dist scan today"; trim the duplicated
  harness-difference enumeration between the Revision note and the Problem; replace "smell-1-shaped"
  with plain words.

### Fact discovered during the walkthrough — the phrase inventory is stale

Item 4's files landed mid-session. `visualize.md` (136 lines) and `feedback/html.md` are **clean** —
no harness-specific vocabulary in either. But `SKILL.md` grew from 98 to **277 lines** and gained
new harness-specific spots the seven-spot table does not list:

| Line | Spot |
|---|---|
| `:115` | `SendMessage` to the synthesis agent by name |
| `:153` | "the absolute base directory from Step 1" |
| `:170` | `SendMessage` to `synthesis-{slug}` |
| `:171-172` | the `Agent` tool with no `subagent_type`; "never `fork`" |
| `:256` | "Resolve the Step 1 base directory" |
| `:260` | `base=$(cd -- "<base directory from Step 1>" && pwd -P)` |

Project-relative paths in `SKILL.md` now number **8** (`:51`, `:54`, `:66`, `:132`, `:134`, `:148`,
`:231`, `:233`), up from the 3 this review found.

Consequence for the spec: **stop stating a count.** The Open Question "Item 4's files don't exist
yet" is now stale and should be replaced by a requirement to re-derive the inventory from the file
at execution time. The exact source strings must come from the file itself in any case — several
table entries are paraphrases, and a substitution dictionary needs literals.

---

**Verdict:** Revise

**Next Steps:** Re-run `/_my_spec` (or return to the spec-agent session) and point it at this
review. Everything above is applicable now except **L1-1**, which the spec should carry as an
explicit Open Question naming the working-directory probe as its dependency — revise now, run the
probe (`/_my_spike`), fold the result in, rather than blocking the revision on it. The reviewer does
not edit the spec.
