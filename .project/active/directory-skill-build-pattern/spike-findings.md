# Spike Findings: How Claude Code and Codex load directory skills

**Status:** Draft — two rows awaiting an owner check
**Owner:** Reid W
**Date:** 2026-08-20
**Branch:** anchor-on-the-point
**Runtimes probed:** `claude-code 2.1.237`; Codex (interactive terminal, owner-driven)
**Triggered by:** `.project/active/directory-skill-build-pattern/design.md` — bets B1, B2, B3
**Prompt:** `/tmp/directory-skill-spike-prompt.md`

---

## Summary

*(written last — see the end of this file)*

---

## Verdict table

| # | Assumption | Verdict | Note |
|---|---|---|---|
| A1 | Underscores legal in a Claude skill dir name, leading underscore legal | **CONFIRMED** | `_my_probe_alpha` and `_my_probe_gamma` both loaded and both ran |
| A2 | `/_my_probe_alpha` invokes the skill directory | *pending owner slash-menu check* | The `Skill` tool resolves it; the user-facing menu is the untested half |
| A3 | Command file and skill directory of the same name coexist, one wins predictably | *pending owner slash-menu check* | Both halves installed; the `Skill` tool reaches the skill, which does not settle precedence |
| A4 | Frontmatter `name` differing from directory name | **PARTLY — both names work** | Listing shows the **directory** name; the **frontmatter** name is also a registered handle. No warning. |
| A5 | Missing `description:` | **CONFIRMED (loads)** | Loaded silently; the listing synthesised the description from the body's first heading |
| A6 | Skill can read a flat sibling | **CONFIRMED, absolute path only** | Bare relative path fails |
| A7 | Skill can read a nested sibling | **CONFIRMED, absolute path only** | Two different nested dirs both readable |
| A8 | How a skill refers to its own directory | **ANSWERED — explicit base-dir line** | Invocation prepends `Base directory for this skill: <abs path>`. Every relative form failed. `pwd` is the project dir. |
| A9 | Symlinked skill directory behaves identically | **CONFIRMED** | Base dir is reported as the **symlink** path, unresolved; siblings readable through it |
| A10 | Dangling symlink in `~/.claude/skills/` | **CONFIRMED harmless** | Absent from the listing, no warning, rest of the skill set unaffected |
| B1 | Codex loads a skill from a symlinked directory | **CONFIRMED** | Contradicts the repo's own claim — see below |
| B2 | Codex loads a skill whose `SKILL.md` is a symlink | **FALSE** | `probe-eta` never registered |
| B3 | Codex tolerates a mismatched frontmatter `name`, and which one invokes | **FALSE as hoped — frontmatter wins** | `probe-delta-renamed` works, `probe-delta` does not |
| B4 | Codex reads siblings, flat and nested | **CONFIRMED** | Flat, two nested dirs, and a non-markdown file |
| B5 | How a Codex skill refers to its own directory | **ANSWERED — cwd is the skill dir** | Opposite of Claude. Bare relative works; `<dirname>/notes.md` fails. |
| B6 | Codex accepts underscores, including a leading one | **CONFIRMED** | `$_my_probe_alpha` loaded and ran |
| B7 | How a native skill is invoked on Codex | **CONFIRMED** | `$<skill-name>`; underscore makes no syntactic difference; a plain-text mention also triggers selection |
| B8 | Codex tolerates extra files and subdirectories | **CONFIRMED** | `stray.txt` plus two subdirectories, `no load warnings` |

---

## The two findings that change the design

### 1. The two harnesses key a skill's identity on different fields

Claude lists a skill under its **directory** name. Codex registers it under its **frontmatter
`name`**, and does not answer to the directory name at all.

Same source directory, `probe-delta/`, whose `SKILL.md` says `name: probe-delta-renamed`:

- Claude's skill listing: `- probe-delta: Spike probe delta. …`
- Codex, asked which of the two names is present: `probe-delta: absent` / `probe-delta-renamed:
  present`, and on invocation, "`probe-delta` failed registry selection because no loaded skill has
  that name."

This kills the simplification that assumption B3 was hunting for. A pack directory
`_my_mental_model` installed on Codex as a **renamed symlink** at `~/.agents/skills/my-mental-model`
would still carry frontmatter `name: _my_mental_model`, so Codex would register it as
`_my_mental_model` — and the command-lane rewrite that turns `/_my_mental_model` mentions in other
commands into `my-mental-model` (`scripts/build-codex-pack.sh:155-158`) would point at a name
nothing answers to.

So the Codex lane **must** generate a modified entry point. That is design decision D1, and the
spike promotes it from a convenience to a requirement. It also makes D2 sharper: deriving the Codex
name from the pack directory name is right, and the derived name must be **written into the
generated frontmatter**, because that is the only field Codex reads. The build already does this
(`scripts/build-codex-pack.sh:386`), so no code change follows — but the reason it matters is now
evidence, not assumption.

### 2. Relative paths resolve differently, so sibling references must be written a specific way

| | Claude | Codex |
|---|---|---|
| `pwd` during a skill run | the project directory | the skill's own directory |
| `cat notes.md` | **fails** | succeeds |
| `cat <skill-dir-name>/notes.md` | **fails** | **fails** |
| `cat <abs-skill-dir>/notes.md` | succeeds | succeeds |
| How the abs path is known | prepended `Base directory for this skill:` line | it is the cwd |

Neither harness resolves a path containing the skill's own directory name. Exactly one written form
is portable: **name the sibling by bare filename in prose and let the agent join it to the
directory it was given.** That is how Anthropic's own skills do it — the `pdf` skill says "see
REFERENCE.md", the `xlsx` skill says `python scripts/recalc.py`.

This does **not** break ADR 0010's no-rewriting rule, but it adds a writing convention that rule
does not currently state, and that a future author will get wrong by default. Concretely: an
instruction file that says `cat feedback/improve.md` works on Codex and silently fails on Claude —
the same one-sided silent failure this whole work item exists to remove, mirrored again.

---

## Per-assumption detail

### A1 — underscores in a Claude skill directory name

**Built:** `~/.claude/skills/_my_probe_alpha/` (real directory, `cp -R` from
`/tmp/skill-spike/_my_probe_alpha/`) and `~/.claude/skills/_my_probe_gamma/`.

**Ran:** session refresh, then read the session's available-skills listing.

**Literal output** — both present:

```
- _my_probe_alpha: Spike probe alpha. Use only when explicitly invoked by name to test skill directory path resolution.
- _my_probe_gamma: Spike probe gamma skill half. Use only when explicitly invoked by name to test command-versus-skill precedence.
```

Both then invoked and ran. **Reading:** a leading underscore and internal underscores are legal.
The inference from the binary's error strings recorded in the spec was right. Design bet B1's naming
half is confirmed by a live load, not just by error text.

### A2 — `/_my_probe_alpha` resolving to a skill directory

**Ran:** invoked `_my_probe_alpha` through the `Skill` tool. It launched and delivered its body.

**Not yet answered:** whether the string `/_my_probe_alpha`, typed by the user, appears in the slash
menu and routes to the skill. That is the form ADR 0009 promises is unchanged across a
command→skill migration, and it needs the owner's eyes on their own autocomplete. Awaiting.

### A3 — command file versus skill directory, same name

**Built:** `~/.claude/skills/_my_probe_gamma/SKILL.md` reporting `GAMMA-SKILL-WINS-4T7Z`, and
`~/.claude/commands/_my_probe_gamma.md` reporting `GAMMA-COMMAND-WINS-6Y2B`. Both confirmed present
on disk.

**Ran:** the `Skill` tool reaches the skill half, which does not settle precedence — that tool
addresses skills by construction. The skill also appears in the session listing while commands do
not appear there at all, so the listing cannot answer it either.

**Not yet answered:** which half a typed `/_my_probe_gamma` runs. Awaiting the owner. This matters
for migration ordering: if the command wins, a migration must delete the command in the same change
that adds the skill, or the new skill is dead on arrival.

### A4 — frontmatter `name` not matching the directory name

**Built:** `~/.claude/skills/probe-delta/SKILL.md` with `name: probe-delta-renamed`.

**Ran and observed, in order:**

1. Session listing showed the **directory** name: `- probe-delta: Spike probe delta. …`. So the
   displayed identity is the directory, and the *description* still comes from frontmatter.
2. Invoking `probe-delta` worked. Base-dir line:
   `Base directory for this skill: /home/rwestwood/.claude/skills/probe-delta`.
3. Invoking `probe-delta-renamed` returned
   `Skill /probe-delta-renamed is already loaded above; instructions unchanged.`
4. To rule out fuzzy matching, invoking `probe-delta-bogus` returned
   `Unknown skill: probe-delta-bogus`, and invoking `probe-beta-renamed` returned
   `Unknown skill: probe-beta-renamed. Did you mean probe-delta-renamed?`

**Reading:** step 4 is decisive. The harness names `probe-delta-renamed` back as a real candidate,
so the frontmatter name is a genuinely registered handle rather than a loose match. Claude accepts
**both** names; it displays only the directory name. No warning was emitted about the mismatch.

Caveat worth stating plainly: I verified this through the `Skill` tool only. Whether both names show
up in the user's slash menu is part of the pending owner check.

### A5 — missing `description:`

**Built:** `~/.claude/skills/probe-epsilon/SKILL.md` with a `name` and no `description`.

**Observed:** it loaded. The listing entry was `- probe-epsilon: Probe Epsilon` — the description
slot was filled from the body's first heading (`# Probe Epsilon`), not from frontmatter. Invocation
worked normally. No warning reached the agent.

**Reading:** Claude degrades gracefully and silently. Low stakes, as expected, but it does mean a
build that drops a description produces a skill with a useless trigger description and no error.

### A6, A7, A8 — sibling reads and self-directory reference

**Built:** `_my_probe_alpha/notes.md` (token `ALPHA-FLAT-TOKEN-7Q4X`) and
`_my_probe_alpha/reference/deep.md` (token `ALPHA-NESTED-TOKEN-9K2M`).

**The invocation's first line, verbatim:**

```
Base directory for this skill: /home/rwestwood/.claude/skills/_my_probe_alpha
```

That single line is the answer to A8. Claude hands the skill an absolute path to its own directory,
unprompted, before the body.

**Every read form, verbatim:**

```
### CMD: cat notes.md
exit=1
out=cat: notes.md: No such file or directory

### CMD: cat ./notes.md
exit=1
out=cat: ./notes.md: No such file or directory

### CMD: cat _my_probe_alpha/notes.md
exit=1
out=cat: _my_probe_alpha/notes.md: No such file or directory

### CMD: cat reference/deep.md
exit=1
out=cat: reference/deep.md: No such file or directory

### CMD: cat /home/rwestwood/.claude/skills/_my_probe_alpha/notes.md
exit=0
out=ALPHA-FLAT-TOKEN-7Q4X : this line lives in the flat sibling notes.md next to SKILL.md.

### CMD: cat /home/rwestwood/.claude/skills/_my_probe_alpha/reference/deep.md
exit=0
out=ALPHA-NESTED-TOKEN-9K2M : this line lives in reference/deep.md, one level below SKILL.md.

### pwd
/home/rwestwood/agentic-project-init
```

**Reading:** A6 and A7 are confirmed — flat and nested siblings are both readable, so the
split-instruction-file shape works on Claude and design bet B2 holds. But the mechanism is not
relative-path resolution. The working directory during a skill run is the *project* directory, so
every relative form fails. The skill only reaches its own files by joining the base-directory path
it was handed.

### A9 — symlinked skill directory

**Built:** `~/.claude/skills/probe-beta` → `/tmp/skill-spike/probe-beta/`, holding `SKILL.md`,
`notes.md`, `reference/deep.md`, `feedback/improve.md`, and `stray.txt`.

**Observed:** loaded and ran. The base-dir line gave the **symlink** path, not the target:

```
Base directory for this skill: /home/rwestwood/.claude/skills/probe-beta
```

All four siblings read successfully through that path, including the second nested directory and
the non-markdown file. All four bare-relative forms failed, same as A8. Directory listing through
the symlink showed every file.

**Reading:** the symlink is transparent, and path resolution does not bite — the harness reports the
link path and reads succeed through it. `setup-global.sh`'s one-symlink-per-skill install
(`scripts/setup-global.sh:126-134`) is sufficient, as the design assumes. A `feedback/`
subdirectory is a viable home for improvable instructions on Claude.

### A10 — dangling symlink

**Built:** `~/.claude/skills/probe-zeta` → `/tmp/skill-spike/does-not-exist-zeta` (confirmed
dangling: `test -e` failed).

**Observed:** `probe-zeta` did not appear in the skill listing. No warning reached the agent. Every
other skill, including the five real probes, loaded normally.

**Reading:** a dangling symlink is inert, not hazardous. A half-finished migration cannot break a
user's skill list this way. This lowers the urgency of design decision D4 from "prevents breakage"
to "hygiene" — see below.

**Not established:** whether a warning appeared in the owner's terminal. Debug logging was off
(`~/.claude/debug/` holds nothing from today), so there is no log-side evidence either way. Part of
the pending owner check.

### B1, B4, B5, B8 — Codex, via a symlinked directory

**Built:** `~/.agents/skills/probe-beta` → `/tmp/skill-spike/probe-beta/`.

**Asked** the owner to run it in a fresh Codex terminal. **Codex's literal report:**

```
probe-beta: present
```
```
Step 0

/home/rwestwood/.agents/skills/probe-beta

The given path is a symlink:

lrwxrwxrwx 1 rwestwood rwestwood 27 Aug 20 11:00 /home/rwestwood/.agents/skills/probe-beta -> /tmp/skill-spike/probe-beta

It resolves to:

/tmp/skill-spike/probe-beta
```
```
Step 2.1  Command: cat notes.md          Result: succeeded
Step 2.2  Command: cat reference/deep.md Result: succeeded
Step 2.3  Command: cat feedback/improve.md Result: succeeded
Step 2.4  Command: cat stray.txt         Result: succeeded
```
```
Step 4

Command: pwd
Output:
/tmp/skill-spike/probe-beta
```

and, at the end of the whole run, `no load warnings`.

**Reading, four separate findings:**

- **B1 is confirmed, and the repo is wrong about it.** `scripts/build-codex-pack.sh:521` prints
  "Codex reads copies, not symlinks", and `CLAUDE.md:53` calls standalone files "Codex's current
  expectation". Codex loaded a symlinked skill directory without complaint. The original
  compatibility research was the accurate one — it proposed `ln -sf`
  (`.project/research/20260418-083015_codex-cli-compatibility-mapping.md:304`). Those two claims in
  the repo should be corrected or scoped; as written they are unsupported.
- **B4 is confirmed.** Flat sibling, two distinct nested directories, and a non-markdown file all
  read. Design bet B3 holds, so Codex parity for the split-instruction shape does not require
  inlining.
- **B5 is answered, and diverges from Claude.** `pwd` was the skill's own directory — the resolved
  target, not the symlink. Bare relative reads therefore work on Codex and fail on Claude.
- **B8 is confirmed.** `stray.txt` and two subdirectories produced no warning and no parse failure.
  The install does not have to filter what it copies.

### B2 — Codex with a symlinked `SKILL.md` inside a real directory

**Built:** `~/.agents/skills/probe-eta/` as a real directory, containing
`SKILL.md` → `/tmp/skill-spike/probe-eta-src/SKILL.md` (symlink) and a real `notes.md`.

**Codex's literal report:**

```
probe-eta: absent

No runner error text was emitted because skills are selected from the loaded registry rather than
invoked through an executable skill command.
```

Codex confirmed the file was readable when pointed at it directly, so the symlink itself is not
broken — the skill simply never registered.

**Reading: B2 is false, and the failure is silent.** Codex resolves a symlinked *directory* (B1) but
does not pick up a skill whose *entry point* is a symlink. So of the two symlink strategies, only
the whole-directory one exists. Never symlink `SKILL.md` alone.

### B3 — Codex and a mismatched frontmatter name

**Built:** `~/.agents/skills/probe-delta/` (real directory copy) with `name: probe-delta-renamed`.

**Codex's literal report:**

```
probe-delta: absent
probe-delta-renamed: present
```
```
Working loaded name:      probe-delta-renamed
Non-working loaded name:  probe-delta

probe-delta failed registry selection because no loaded skill has that name. No error text was
emitted. probe-delta is the filesystem directory name.
```

**Reading:** Codex invokes by frontmatter `name` and ignores the directory name. This is the
opposite of Claude's displayed identity, and it is the hinge finding — see "The two findings that
change the design" above. Note also that the mismatch produced **no error on either harness**; each
simply exposed a different name.

### B6, B7 — Codex, underscores and invocation form

**Built:** `~/.agents/skills/_my_probe_alpha/` (real directory copy).

**Codex's literal report:**

```
_my_probe_alpha: present
```
```
2. Exact invocation syntax:

$probe-beta
$probe-delta-renamed
$_my_probe_alpha

A leading underscore makes no syntactic difference. It remains part of the name:

$_my_probe_alpha

Mentioning the exact skill name in plain text also triggers selection.
```

Its read results:

```
Step 2.1 Command: cat notes.md                  Result: succeeded
Step 2.2 Command: cat ./notes.md                Result: succeeded
Step 2.3 Command: cat _my_probe_alpha/notes.md  Result: failed
         Exit code: 1
         Error:
         cat: _my_probe_alpha/notes.md: No such file or directory
Step 2.4 Command: cat reference/deep.md         Result: succeeded
Step 2.5 Command: cat /home/rwestwood/.agents/skills/_my_probe_alpha/notes.md  Result: succeeded
Step 2.6 Command: cat /home/rwestwood/.agents/skills/_my_probe_alpha/reference/deep.md  Result: succeeded
Step 4   pwd → /home/rwestwood/.agents/skills/_my_probe_alpha
```

**Reading:**

- **B6 is confirmed.** Codex accepts an underscore-prefixed skill name. So the `_my_x` → `my-x`
  mapping is not required *by Codex*. It remains required for consistency with the ~33
  command-derived skills, which the command lane already maps, and with the cross-reference rewrite
  at `scripts/build-codex-pack.sh:155-158`. Shipping native skills under `_my_*` while command
  skills ship under `my-*` would put two naming conventions in one registry. Keep the mapping.
- **B7 is confirmed.** `$<skill-name>`, no special handling for a leading underscore. Note the
  extra detail Codex volunteered: a plain-text mention of the exact name also triggers selection,
  which is a mild argument for distinctive skill names.
- **Step 2.3 is the useful negative.** `_my_probe_alpha/notes.md` failed on Codex too, because the
  cwd is already inside that directory. Combined with A8, no path containing the skill's own
  directory name works anywhere.

---

## Reproduction steps

All probe sources live under `/tmp/skill-spike/` and are throwaway. To rebuild from scratch:

```bash
# 1. Sources (see "Cleanup performed" for the exact file list and tokens)
mkdir -p /tmp/skill-spike
#    ... write _my_probe_alpha/, probe-beta/, _my_probe_gamma/, probe-delta/,
#        probe-epsilon/, probe-eta-src/ as described per assumption above

# 2. Claude install
cp -R /tmp/skill-spike/_my_probe_alpha  ~/.claude/skills/_my_probe_alpha
ln -s   /tmp/skill-spike/probe-beta     ~/.claude/skills/probe-beta
cp -R /tmp/skill-spike/_my_probe_gamma  ~/.claude/skills/_my_probe_gamma
cp      /tmp/skill-spike/_my_probe_gamma_COMMAND.md ~/.claude/commands/_my_probe_gamma.md
cp -R /tmp/skill-spike/probe-delta      ~/.claude/skills/probe-delta
cp -R /tmp/skill-spike/probe-epsilon    ~/.claude/skills/probe-epsilon
ln -s   /tmp/skill-spike/does-not-exist-zeta ~/.claude/skills/probe-zeta   # deliberately dangling

# 3. Codex install
ln -s   /tmp/skill-spike/probe-beta     ~/.agents/skills/probe-beta
cp -R /tmp/skill-spike/probe-delta      ~/.agents/skills/probe-delta
cp -R /tmp/skill-spike/_my_probe_alpha  ~/.agents/skills/_my_probe_alpha
mkdir -p ~/.agents/skills/probe-eta
ln -s   /tmp/skill-spike/probe-eta-src/SKILL.md ~/.agents/skills/probe-eta/SKILL.md
cp      /tmp/skill-spike/probe-eta-src/notes.md ~/.agents/skills/probe-eta/notes.md
```

**Claude side:** skills are discovered at session start, so suspend and resume the session
(`CTRL+Z`, then resume) before probing. Then invoke each probe and follow its steps literally.

**Codex side:** open a fresh terminal and paste the seven-item diagnostic prompt (recorded in the
chat transcript for this spike; it asks Codex to list probe-named skills, state its invocation
syntax, run each probe, and report load warnings verbatim).

**One caution when rerunning:** each probe reports a unique token
(`ALPHA-FLAT-TOKEN-7Q4X`, `BETA-NESTED-TOKEN-5W1J`, `GAMMA-SKILL-WINS-4T7Z`, and so on). Grep for
the token rather than trusting a summary — an agent asked to test path resolution will otherwise
tend to report the intent rather than the exit code.

---

## What this changes in the design

Nothing in `.project/active/directory-skill-build-pattern/design.md` was edited. These are the
decisions that need revisiting, named by their labels.

**Confirmed, and now on evidence rather than inference:**

- **Bet B1** (Claude identity is the directory name; underscore prefix legal) — confirmed by a live
  load. One correction to fold in: the directory name is what Claude *displays*, but the frontmatter
  name is also a working handle (A4).
- **Bet B2** (a Claude skill can read a sibling) — confirmed, flat and nested, including through a
  symlink. The split-instruction-file shape works. Qualified by the path rule below.
- **Bet B3** (Codex reads siblings) — confirmed, flat, twice-nested, and non-markdown.
- **D1** (copy the tree, then overwrite the entry point) — **promoted from convenience to
  requirement.** Because Codex registers the frontmatter name, the entry point must be regenerated
  for any `_my_*` skill. The rejected alternative in D1 was the wrong `find` walk; the spike adds a
  second rejected alternative that looked more attractive — a renamed whole-directory symlink — and
  kills it.
- **D2** (derive the Codex name from the pack directory name) — confirmed, with the reason
  sharpened: the derived name must be written into the generated frontmatter because that is the
  only field Codex reads. `scripts/build-codex-pack.sh:386` already does this. Do not "simplify" it
  away.
- **D6** (delete the flat native-skill lane) — independently corroborated. The flat
  `~/.claude/skills/example-skill.md` symlink is installed right now and does **not** appear in this
  session's skill listing, while `dist/codex/skills/example-skill/SKILL.md` exists and builds clean.
  That is the one-sided failure D6 removes, observed directly.
- **D5** (overridable build roots for a fixture build) — untouched by the spike; still the only way
  to exercise the `_my_x` → `my-x` mapping at HEAD.

**Weakened or needing a rescope:**

- **D3** (the install mirrors the dist directory onto the target). Still correct for `--copy`, but
  its justification narrows. B1 shows Codex loads a symlinked directory, so
  `~/.agents/skills/<name>` → `dist/codex/skills/<name>` would converge with no mirror logic at
  all — the whole "did the copy go stale" class disappears. That is a real option the design
  dismissed on a claim (`build-codex-pack.sh:521`) that is now shown to be false. Worth a deliberate
  choice rather than an inherited assumption. Note the constraint that survives: the symlink must be
  to the **whole directory**, never to `SKILL.md` alone (B2).
- **D4** (sweep dead managed symlinks in `setup-global.sh`). Keep it, but the stated motivation is
  wrong. A10 shows a dangling symlink is inert — no warning, no effect on the rest of the skill set.
  So this is tidiness, not a hazard that can break a user's skill list, and it should be prioritised
  as such.
- **The risk row "The Claude runtime validates frontmatter `name` against the directory more
  strictly than assumed"** can be retired. A4 shows the opposite: a mismatch is tolerated silently
  on both harnesses, and each simply exposes a different name. The real hazard is the reverse of
  what the row feared — no error tells you the two harnesses disagree.

**New, not covered by any current decision — needs to land somewhere:**

- **A sibling-reference writing convention.** Reference a sibling by **bare filename in prose**, and
  never write a path containing the skill's own directory name. Justification is the A8/B5 table
  above: `cat notes.md` works on Codex and fails on Claude; `cat <dirname>/notes.md` fails on both;
  only the absolute join works, and each harness supplies the absolute prefix differently. This is
  compatible with ADR 0010's no-rewriting rule — it is a rule about how to *write* sibling files,
  not a transformation applied to them — but ADR 0010 does not state it, and a future author will
  get it wrong by default. `claude-pack/skills/example-skill/` (D7) is the natural place to
  demonstrate it, which makes the example's prose load-bearing.
- **Two claims in the repo are unsupported and should be corrected:**
  `scripts/build-codex-pack.sh:521` ("Codex reads copies, not symlinks") and `CLAUDE.md:53`
  (standalone files are "Codex's current expectation"). Codex loaded a symlinked skill directory
  cleanly.
- **`description:` is not validated** (A5). A skill with none loads with a description scraped from
  its first heading. Cheap to guard in the build if desired; nothing depends on it today.

**Still open, and it is the load-bearing one:**

- **A2 and A3.** Whether a typed `/_my_<name>` reaches a skill directory, and what wins when a
  command file and a skill directory share a name. ADR 0009's invariant "slash invocation is
  preserved across a command→skill migration; users see no change" rests on A2. A3 sets migration
  ordering. Both need the owner's slash menu; both are recorded as pending above.

---

## Cleanup performed

**Starting state, recorded before any change.**

`~/.claude/skills/`: `ab-compare/`, `example-skill.md` → pack, `flex-sim-analysis/`,
`flex-study-helper/`, `screenshots-skill/`, `show-me/` → pack.

`~/.agents/skills/`: `example-skill/`, `show-me/`, and 31 `my-*` command-derived skills.

Nothing in `claude-pack/`, `dist/`, `codex-overrides/`, or `scripts/` was modified. No pre-existing
entry in either skills directory was touched.

**Created (all removed at the end of the spike):**

| Path | Kind |
|---|---|
| `/tmp/skill-spike/` (whole tree) | probe sources |
| `~/.claude/skills/_my_probe_alpha/` | copied directory |
| `~/.claude/skills/probe-beta` | symlink → `/tmp/skill-spike/probe-beta` |
| `~/.claude/skills/_my_probe_gamma/` | copied directory |
| `~/.claude/skills/probe-delta/` | copied directory |
| `~/.claude/skills/probe-epsilon/` | copied directory |
| `~/.claude/skills/probe-zeta` | dangling symlink |
| `~/.claude/commands/_my_probe_gamma.md` | copied file (outside the two skills dirs — noted deliberately) |
| `~/.agents/skills/probe-beta` | symlink → `/tmp/skill-spike/probe-beta` |
| `~/.agents/skills/probe-delta/` | copied directory |
| `~/.agents/skills/_my_probe_alpha/` | copied directory |
| `~/.agents/skills/probe-eta/` | real directory with a symlinked `SKILL.md` |

**Removal is recorded at the bottom of this file once performed.**
