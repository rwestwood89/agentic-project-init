# Spec: wordfreq CLI

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-07-02
**Complexity:** LOW
**Branch:** main (no commits yet)

---

## Problem

When someone has a text file and wants to know which words appear most often, there's no quick way to see it — they'd have to count manually or write a one-off script each time. Filler words like "the" and "and" would dominate any naive count, burying the words that actually matter.

## Success Criteria

- [ ] Running the tool against a UTF-8 text file prints a ranked list of the most frequent words, readable at a glance (word + count).
- [ ] Common English stopwords ("the", "and", "of", etc.) are excluded from the list automatically.
- [ ] The number of words shown is configurable at runtime, with a sensible default when not specified.

## Known Requirements

- **[HARD]** Reads a UTF-8-encoded text file, given as input.
- **[HARD]** Accepts a file path as a command-line argument (the ask specifies reading "a" file, not stdin or multiple files).
- **[NEED]** Frequency counting excludes a built-in set of common stopwords by default.
- **[NEED]** The count of words displayed is configurable by the user, not hardcoded.
- **[INFERRED]** Word matching is case-insensitive ("The" and "the" count as the same word) — otherwise capitalization would fragment counts and defeat "most-used words at a glance."
- **[INFERRED]** Punctuation attached to a word (commas, quotes, periods) is stripped before counting, so "word," and "word" count as the same token.
- **[INFERRED]** The stopword list is a fixed, built-in English list for this iteration — no user-supplied list required.
- **[INFERRED]** A sensible default count (e.g., top 10) applies when the user doesn't specify one.
- **[INFERRED]** The tool reports a clear, readable error if the file doesn't exist or isn't valid UTF-8, rather than surfacing a raw stack trace.

## Non-Goals

- Multi-language stopword lists or non-English text handling.
- User-supplied/custom stopword lists.
- Reading from stdin or accepting multiple input files.
- Exporting results to a file or format other than stdout.
- Performance work for very large files (streaming, memory limits) — no stated constraint.

## Open Questions / Deferred to design

- Target language/runtime and how the tool is packaged/invoked — no constraint was stated.
- Exact CLI flag names/syntax for the file path and the count (e.g., `-n`, `--top`).
- Output format details: plain list vs. table, column alignment, header line.
- Tie-breaking order when multiple words share the same frequency.
- Whether stdin or multiple-file input is worth adding later.

---

## Related Artifacts

- **Design:** `.project/active/wordfreq/design.md` (to be created)

---

**Next Steps:** After approval, proceed to `/_my_design`.
