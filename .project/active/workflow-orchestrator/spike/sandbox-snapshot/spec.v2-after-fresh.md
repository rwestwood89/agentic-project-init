# Spec: wordfreq CLI

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Complexity:** LOW
**Branch:** N/A (no commits yet in this sandbox)

---

## Problem

There's no quick way to see which words dominate a text document. Doing this
by hand, or with a one-off script each time, is repetitive, and a naive word
count is dominated by function words (the, a, is, of, ...) that carry no
information about what the document is actually about. A small CLI that
counts words, strips stopwords, and shows the top N gives an at-a-glance
read on any text file's content.

## Success Criteria

- [ ] Running the tool against a text file prints a ranked list of the
      document's most frequent words, so the user can see what the document
      is about at a glance.
- [ ] Common stopwords (the, a, is, of, etc.) never appear in the output,
      even when they are the most frequent raw tokens in the text.
- [ ] The number of words shown is configurable by the user, without
      editing the tool itself.
- [ ] The tool runs standalone, with no dependency on any existing codebase
      or project.

## Known Requirements

- **[HARD]** Standalone CLI with no dependency on any existing codebase —
  stated directly as a boundary condition for this work.
- **[NEED]** Reads a UTF-8-encoded text file given as input.
- **[NEED]** Excludes a built-in list of common stopwords from the output.
- **[NEED]** The count of words displayed is configurable per run.
- **[INFERRED]** Word matching is case-insensitive ("The" and "the" count as
  the same word) — a case-sensitive count would fragment common words across
  capitalization variants and make the "most frequent" list less meaningful,
  which conflicts with the stated goal of an at-a-glance, meaningful result.
- **[INFERRED]** Tokenization must not corrupt or split accented/non-ASCII
  Latin characters (e.g. "café", "naïve" stay single tokens) — this follows
  directly from the stated UTF-8 input requirement; accepting UTF-8 but
  tokenizing as if input were ASCII would silently misparse them. How far
  tokenization support extends past accented Latin text (other scripts, e.g.
  Cyrillic, Greek, CJK) is not settled here — see Open Questions.
- **[INFERRED]** The stopword list is a built-in English list for v1 — the
  user's examples (the, a, is, of) are English, and no other language was
  mentioned.
- **[INFERRED]** Output must be deterministic — the same input file produces
  the same output on every run, including a stable order among words tied in
  frequency. This follows from the goal of a trustworthy at-a-glance tool;
  the specific tie-break rule (alphabetical vs. first-occurrence vs. other)
  is a design choice — see Open Questions.

## Non-Goals

- No GUI or interactive/REPL mode.
- No batch or multi-file processing in one invocation.
- No multi-language stopword lists or locale-specific tokenization.
- No persistence, history, or writing results to a file (stdout only).
- No charting or visualization of frequencies.
- Not intended for source code, logs, or other structured/repetitive text —
  designed for natural-language prose.

## Open Questions / Deferred to design

- **Implementation language/runtime** — not specified by the user. The
  requirement is language-agnostic, so this is a design choice.
- **CLI flag names/syntax** for the input file and the "number of words"
  option, and the default count used when the flag is omitted — a mechanism
  choice, not a stated requirement.
- **Tokenization edge cases** — contractions ("don't"), hyphenated
  compounds, embedded digits, and how far Unicode support extends past
  accented Latin text (Cyrillic, Greek, CJK, etc. — full script coverage is
  not required, only that UTF-8 input isn't corrupted). Affects both word
  boundaries and stopword matching; belongs to design.
- **Tie-break rule for equal-frequency words** — alphabetical order is a
  sensible default, but not a stated requirement; first-occurrence order is
  an equally valid choice. Belongs to design.
- **Stopword list customization** — whether a user can supply their own
  list/file in addition to the built-in default. Not requested; a plausible
  future extension.
- **Output format** — plain list vs. word/count columns vs. alignment.
  Cosmetic, belongs to design/UX.
- **Error handling** — behavior on missing file, invalid/non-UTF-8 encoding,
  empty file, or a file with zero non-stopword words. Deferred to design,
  but should fail with a clear message rather than a crash/stack trace.

---

## Related Artifacts

- **Epic:** None
- **Research:** None
- **Design:** `.project/active/wordfreq/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
