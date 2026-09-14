---
name: convince-me
description: Prove a claim with evidence the user can inspect, not prose. Break the argument into claims, run the discriminating test or simulation for each, and assemble the captured results into one self-contained HTML the user can audit.
---

The user does not trust confident prose, and does not follow the code closely enough to catch a wrong assumption inside a reasonable-sounding argument. Your job is to make the claim checkable by eye. Words are the index, evidence is the content.

`/show-me` explains a shape. `/convince-me` proves a claim. Use this skill when the user asks whether something is true, works, is fixed, is faster, converges, is equivalent, or is safe to ship.

## The method

1. **Decompose the argument into claims.** Write the chain of claims that has to hold for the conclusion to be true. Keep only the load-bearing ones: a claim earns a place if its being false would change the user's decision. Three to seven is typical. If the conclusion rests on a claim you cannot test, say so up front rather than burying it.
2. **For each claim, name the falsifier.** State what you would expect to observe if the claim were false. This is the whole skill. Evidence that looks the same whether the claim is true or false is decoration, not evidence.
3. **Design the discriminating check.** Pick the smallest test, simulation, query, or run whose output differs visibly between the claim being true and false. Prefer the repo's existing tests, sims, fixtures, and scripts. Write a small script only when nothing suitable exists.
4. **Run it and capture the raw result.** Real command, real output, saved to disk. Never type out what a command "would" print. If the check cannot run in this environment, the claim is `untested`, not `supported`.
5. **Show the evidence can fail.** For any claim the decision hinges on, run a control: break the thing on purpose (wrong parameter, reverted fix, perturbed input, shuffled labels) and show the same check catching it. A plot that stays green under sabotage proves nothing.
6. **Assemble the HTML.** Verdict table first, then one section per claim with its evidence embedded. Then open it for the user.

Report refuted claims as the headline, not as a footnote. If the evidence contradicts the conclusion you were asked to prove, that is the deliverable. Do not soften it, and do not quietly re-scope the claim until it passes.

## What counts as evidence

Match the evidence to the kind of claim. The examples below are the common shapes; pick what discriminates.

- **Numerical or simulation claims** ("the solver converges", "the fix removes the drift", "these two implementations agree"). Run the sim and plot the specific quantity that would differ if the claim were false. Useful shapes: expected versus actual overlaid on the same axes; a residual or error plot with the tolerance drawn as a line; a convergence plot on log axes; the same seed before and after a change; a parameter sweep showing the boundary where behavior changes; an invariant (conservation, monotonicity, symmetry) tracked over the run; a limiting case compared against a closed-form answer.
- **Code-soundness claims** ("this handles the empty case", "the retry path works", "the parser accepts the new format"). Real input in, real output out, both captured: the exact command, its stdout and stderr, exit code, and the relevant log lines. A test run with its full output. A before/after diff of behavior on the same input. A trace or debug log showing the code path was actually taken.
- **Data claims** ("no rows are duplicated", "the distribution is unchanged"). The query and the resulting table or histogram, with counts. Show the shape of the data, not a summary statistic alone.
- **Performance claims** ("this is faster", "memory is flat"). A table of repeated runs with n, mean, and spread for both variants, on the same machine and input. A single timing is an anecdote.
- **Equivalence claims** ("the refactor preserves behavior"). Old and new run on the same inputs, outputs diffed. For numerical code, the max absolute and relative difference over a representative input set, with the tolerance stated.
- **External behavior claims** ("the API returns X", "the library streams"). The captured request and response, not a description of them.

Plots exist to make a discrepancy visible at a glance. Overlay when the claim is "these match". Plot the difference when the match is close. Draw the threshold, tolerance, or expected value as a reference line so the reader does not have to know the number. Use log axes when the data spans decades. Label axes with units. One figure per claim is usually right; a figure with nothing to compare against is usually wrong.

## Not evidence

- Prose that explains why the code is correct.
- A plot with no reference, expected value, or comparison on it.
- Output you wrote by hand instead of captured.
- A passing test that does not exercise the claim.
- A single run of anything stochastic.
- A check that could not have failed.
- A mocked or stubbed version of the thing under question.

## Auditability

Every piece of evidence carries enough to re-run it. Record, per check: the exact command, the working directory, the git SHA and whether the tree was dirty, the seed or fixed inputs, and the timestamp. Save the script and the raw output next to the HTML so the reader can re-run without you.

Layout:

```text
convince-me-{slug}/
├── index.html          # self-contained: images as data URIs, logs inline
└── evidence/
    ├── 01-{claim}.py   # or .sh, .sql — whatever ran
    ├── 01-{claim}.log  # raw captured output
    ├── 01-{claim}.png  # the figure, also embedded in index.html
    └── ...
```

Put the folder where the user can find it: the active work-item folder under `.project/active/` if one is in play, otherwise the repo root. Delete it when the user is done if they ask; the evidence folder is the receipt, not a fixture.

## The HTML

Self-contained and static: images embedded as data URIs or inline SVG, logs in `<pre>` blocks, no `<script>`, no remote URLs. The reader may open it later, offline, from a different machine.

Shape:

- **Verdict table at the top.** One row per claim: the claim in one sentence, the verdict (`supported`, `refuted`, `untested`), and a thumbnail or one-line pointer to its evidence. A reader who stops here knows the answer and where the weak link is.
- **One section per claim**, in dependency order. Each section has: the claim; the falsifier ("if this were false, we would see …"); the evidence with one sentence saying what to look at ("the two curves should overlay; the residual stays below the dashed line"); the control if one was run; and a collapsed reproduce block with the command, environment, and pointer to the raw file.
- **An untested or refuted section says so in the section heading**, not in the body.

Keep prose to one or two sentences per element. If a sentence is doing the convincing, cut it and let the evidence do it.

Open the HTML when it is ready (`xdg-open` on Linux, `open` on macOS):

```
Bash(xdg-open convince-me-{slug}/index.html)
```

## Guidance

Spend the effort on the claim most likely to be wrong, not the one easiest to show. If you find yourself writing a paragraph to explain why a figure supports a claim, the figure is the wrong figure. If a check would take real time to run (a long sim, a large sweep), say how long before starting and run it; a fast proxy that does not exercise the claim is not a substitute.

When the user's question is broad ("is this right?"), propose the claim list first and let them cut or add before you run anything. When it is narrow ("does the fix remove the drift?"), go straight to the check.
