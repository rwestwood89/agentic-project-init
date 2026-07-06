# Spike: Codex skill description YAML hazards

**Branch:** spike-and-learning-test-commands
**Date:** 2026-07-03
**Home folder:** this work-item folder (spike scripts co-located here)

## Summary of Findings

**Assumption confirmed:** a skill description that starts with `*` (or `**`) breaks the SKILL.md
YAML, because `*` begins a YAML alias reference. Both `*foo` and `**Purpose:**` fail to parse.

**The local build does not catch it.** `build-codex-pack.sh:250` emits the description with a raw
`printf "description: %s\n"` — no quoting, no YAML validation. An invalid description sails
through the build; the failure only surfaces when the SKILL.md is actually parsed downstream.

**A tempting over-generalization is wrong: colon-space in the middle of a description is safe.**
A strict PyYAML parse *also* rejects `description: Certify a work item or epic: evaluate ...`
("mapping values are not allowed here"). But three such descriptions already ship in
`dist/codex/skills/*/SKILL.md` and work in Codex today. So Codex's real parser tolerates
mid-value colons; only the leading-`*` case is a genuine hazard. Do not add a colon rule.

**So the rule for Phase 4 is narrow:** the `spike` and `learning-test` description strings must
not *start* with `*` or `**`. The existing `"<action>. Use when <trigger>."` pattern (periods,
no leading punctuation) already satisfies this. No other characters need avoiding.

## Question / Goal

Does a Codex skill description starting with `*` actually break the build's YAML, and does
anything in the build catch it? (De-risks Phase 4, where two new description strings are added
and the build is run.)

## Log

1. **Traced the emit path.** `build-codex-pack.sh:250` writes `printf "description: %s\n"
   "$description"` into SKILL.md frontmatter — raw string, unquoted. `description_for_command_skill`
   (`:144`) sources the string from `COMMAND_SKILL_DESCRIPTIONS` first, else extracted
   purpose/heading. Nothing validates YAML at build time.

2. **Confirmed a YAML parser is available:** PyYAML 6.0.1 via `python3`.

3. **Probed parsing behavior** with `probe_yaml_description.py` (co-located). Result:
   ```
   [ OK ] plain prose        -> parses
   [FAIL] leading single *   -> ScannerError: while scanning an alias
   [FAIL] leading double **  -> ScannerError: while scanning an alias
   [ OK ] leading &          -> parses but SILENTLY drops the '&anchor' token (corruption)
   [FAIL] colon inside       -> ScannerError: mapping values are not allowed here
   ```
   Leading `*`/`**` confirmed broken. Two surprises: leading `&` corrupts silently, and a
   mid-value colon-space appeared to break too.

4. **Checked the colon result against reality.** Grepped existing descriptions:
   `codex-overrides/config.sh` and the built `dist/codex/skills/*/SKILL.md` both contain three
   descriptions with mid-value colon-space (e.g. audit's "Certify a work item or epic: evaluate
   ..."). These ship and work in Codex today. Re-ran PyYAML on the real strings — PyYAML rejects
   them, but Codex clearly does not. **Conclusion:** the colon "failure" is a PyYAML strictness
   artifact, not a real Codex hazard. Only the leading-`*` case is load-bearing.

## Reproduction

From this folder:
```bash
python3 probe_yaml_description.py            # shows which description shapes break strict YAML
```
To confirm the colon case is a false alarm (real shipped descriptions with colons):
```bash
cd <repo root>
grep -h '^description:' dist/codex/skills/*/SKILL.md | grep -E '^description: .*: '
```
These lines exist and Codex loads them, so mid-value colons are safe in practice.

## Open Questions / Follow-ups

- **Leading `&` corrupts silently** rather than crashing. Out of scope for this feature (our
  descriptions never start with `&`), but a lurking hazard for the build generally. A build-time
  guard that quotes the description, or rejects a leading `*`/`&`, would remove the whole class.
  Not doing it here — noted for whoever hardens the build.
