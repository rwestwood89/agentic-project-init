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
- **[INFERRED]** Tokenization is Unicode-aware — words are runs of
  letters/digits (not ASCII-only), matching the stated UTF-8 input
  requirement. Accepting UTF-8 but tokenizing as if input were ASCII would
  silently misparse accented or non-Latin words.
- **[INFERRED]** The stopword list is a built-in English list for v1 — the
  user's examples (the, a, is, of) are English, and no other language was
  mentioned.
- **[INFERRED]** Ties in frequency are broken alphabetically, so output is
  stable and reproducible across runs on the same input.

## Non-Goals

- No GUI or interactive/REPL mode.
- No batch or multi-file processing in one invocation.
- No multi-language stopword lists or locale-specific tokenization.
- No persistence, history, or writing results to a file (stdout only).
- No charting or visualization of frequencies.

## Open Questions / Deferred to design

- **Implementation language/runtime** — not specified by the user. The
  requirement is language-agnostic, so this is a design choice.
- **CLI flag names/syntax** for the input file and the "number of words"
  option, and the default count used when the flag is omitted — a mechanism
  choice, not a stated requirement.
- **Tokenization edge cases** — contractions ("don't"), hyphenated
  compounds, embedded digits, accented characters. Affects both word
  boundaries and stopword matching; belongs to design.
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
