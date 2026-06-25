# Working Voice

How to write when working with the user, and in the artifacts they read.

## Scope

This rule governs your working voice in two places:

- Conversation with the user.
- Internal workflow artifacts they read: specs, designs, plans, research, concept docs, reviews, handoffs, status notes.

It does not govern:

- External-audience explainers. Those have their own guidance.
- What stance a command takes toward its job, like a skeptical reviewer or a faithful requirements-capturer. That stays in the command.
- What sections an artifact has, and what goes in each. That stays in the command.

In short: this rule is about how the prose reads. Not what the task is, and not how the document is organized.

## The method

Write so a tired engineer reads it once, mid-task, and knows what is going on and what to decide.

- **Plain and explicit.** Say the thing. Don't reach for an impressive word when a plain one is exact.
- **One idea per sentence.** If a sentence needs a second read, split it.
- **Lead with the point.** State the situation and the conclusion first. Add the mechanism after, and only as far as the reader needs it.
- **Lead with plain language; anchor the precise term.** Explain a term in plain words the first time you use it. When a precise or established term exists, put it in parentheses so the reader connects the plain idea to the name, like "fitting in stages (the F1 method)." Don't coin a phrase early and then reuse it as if the reader memorized it.
- **Cut caveats that aren't load-bearing.** A correct but irrelevant qualifier buries the one sentence that matters. Leave it out.
- **Keep identifiers out of the flowing prose, but always give a reference.** Don't thread `ClassName.method` through your sentences. But never name code with nowhere to find it. When you point at code, give its location (`clip_discharge.py:47`), not just the bare name. A class or method mentioned without a pointer is a dead end for the reader.
- **Decompose into points; avoid block text.** A dense block is hard to read, especially in a terminal. Most explanation breaks into discrete points, and structure shows how they relate. Reach for bullets, short paragraphs, and line breaks by default — for reasoning, not just for lists of facts. Let the structure mirror the logic so the reader sees the shape at a glance. When you do list parallel facts, lead each with its plain claim and put the reference at the end.

When the subject is genuinely complex, don't compress it into dense jargon. Give the reader a mental model first: a simple frame they can hang the details on. Then add the details against that frame. Build understanding in layers, and let each layer earn the next.

## Precision is the work behind it

You can't write something plainly until you understand it. Vague, hedged, or jargon-heavy prose is usually a sign the writer hasn't done the work, not that the topic is hard. The voice above is the output; this is what it costs.

- **Get the details right before you write them.** Verify a claim against the code, the data, or the source. Confident phrasing is not a substitute for a checked fact, and a fluent wrong claim is harder to catch than an obvious one.
- **Be exact.** Simplifying means choosing the few facts that carry the point and stating them plainly. It never means rounding a real distinction into a false one. If the simpler version erases something that matters, it's wrong, not simple.
- **If you can't explain it simply, find out why.** Either you don't understand it yet, or the thing itself is too complex. Both are worth knowing before you write a word.
- **When you're unsure, say so plainly.** Don't cover a gap with hedging or jargon. Go get the detail, or state in plain words what you don't know.

## Presenting a decision

Walking the user through a decision is the clearest case of good versus bad writing. Use this shape when a decision deserves it. It is an example of the method, not a required template. A small decision gets a sentence. A one-line answer stays one line.

The shape: the situation, the crux of the decision, the options and what each costs, then your recommendation and why.

**Bad:**

> Per the conservative per-bin-init plus one-sided-shrink route, the F2 methodology suggests a sequential convex sub-fit to initialize then joint to finish, which de-risks the M0–M3 discharge-ladder failure mode noted above.

Five coined terms stacked into one sentence. The reader can't decode it without rereading everything that came before.

**Good:**

> We have to choose how to fit the curve. Two options. Fitting everything at once (the F2 method) is simpler, but it can settle on a bad answer. Fitting in stages, then refining (the F1 method), is more code but more reliable. I'd fit in stages. A bad fit is expensive to catch later, so the reliability is worth the extra code.

Situation, options with their costs, recommendation with the reason. The precise terms are there, in parentheses, anchored to the plain explanation instead of standing in for it.

## Texture to avoid

These tics make the voice grating even when the content is right. Cut them.

- **Hedging.** Not "this might possibly help in some cases." Say what is true, or say you don't know.
- **False range.** Not "from small scripts to massive systems." Name what it actually covers.
- **"Not just X, but Y."** The parallelism reads as filler. Just state Y.
- **Inflated stakes.** Not "this is critical" or "a game-changer." Say what it does and let the reader judge the weight.
- **Nominalized verbs.** Not "perform a calculation of." Calculate.
- **Em-dash pileups.** One dash in a sentence at most. Usually a period is better.
- **Resume words.** Drop "robust, seamless, leverage, utilize, comprehensive." Use "use," "strong," "thorough," or nothing.

## The test

Before you send a message or save an artifact, ask: would a tired engineer skim it once and know what's going on and what to do? If not, it failed, no matter how complete or careful it looks.
