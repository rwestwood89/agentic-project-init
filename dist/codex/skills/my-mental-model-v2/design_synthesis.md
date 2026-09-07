# Design Synthesis V2 — Instruction File

Produce one markdown synthesis for the assigned question. Do not produce HTML or any other artifact. Write only to the assigned path; the saved markdown is your whole output.

## Purpose

Reconstruct the mental model a reader needs: what the subject is, why it exists, how its important parts interact, and where its boundaries or uncertainties are. Write for an intelligent reader who lacks the source context. Choose a teaching sequence instead of following source order or inventorying files.

## Context and evidence

Follow the context policy in your brief.

- **Discovered:** Explore project sources by relevance to the question.
- **Clean room:** Read only sources allowed by the user's restriction.
**Carried**: you were spawned with `fork_turns: "all"`, so the conversation's completed turns came
with you. What the coordinator produced during the turn that spawned you did not, so treat the spawn
prompt as the authority on the classification.

Read project-local synthesis feedback named in the brief when it exists. Do not read shared feedback.

Ground important claims with useful source pointers. State whether each claim describes current code, intended design, an owner decision, or your inference. Preserve contradictions, missing evidence, and uncertainty instead of quietly resolving them. Name what you examined and the material limits of your search.

## Outcome qualities

- **Important stuff up front.** Do not assume the reader finishes the synthesis. If they stop at any point, they should already have consumed the most important information available for understanding the subject.
- **A connected explanation.** Use explicit references to later sections when a concept appears before its full explanation. Give multi-step reasoning its own section instead of interrupting the idea that introduced it.
- **Exact names and definitions.** Name every important concept using its real code or domain name. Say exactly what it is, what role it plays, and what is true about it. Do not replace that explanation with a generic label or a source pointer, and do not defer it to the HTML.
- **Explicit invariants.** State the conditions that must remain true across valid states and transitions. Name who or what owns each invariant and the boundary over which it holds.
- **Concrete code shapes.** Name the actual data structures that define important types, along with the relevant data models, signatures, and class structures. Include the fields, states, relationships, constraints, and meaningful real numbers needed to understand the model. Omit exhaustive code or data dumps that add no understanding.
- **Clear on one reading.** Use plain language, define unfamiliar terms, and make every heading and sentence understandable without rereading. A heading states the section's real claim rather than naming a topic, counting its contents, or introducing a coined label.
- **Reasoning the reader can inspect.** The narrative makes its logic visible without requiring the reader to open every source. Source pointers support the explanation; they do not stand in for it.
- **Use the right scope.** Say exactly which part of the system each fact applies to. Do not present one component's behavior as a rule for the whole system.
- **Definitions before measurements.** Explain what something is before reporting what a run measured. Label measurements clearly so observed results do not masquerade as definitions.
- **No invented rationale.** Explain why a structure exists when the evidence establishes the reason. When it does not, name the uncertainty instead of manufacturing a motive.
- **Deliberate compression.** Spend detail where it carries the answer. Keep the narrative coherent and independently readable without turning it into an inventory or pre-writing the HTML detail layer.

## The synthesis

Begin with these metadata fields:

```
---
question: "<the user's question, verbatim>"
date: YYYY-MM-DD HH:MM
policy: carried | discovered | clean_room | carried_clean_room
shape: checkpoint | plain_document
evidence:
  - <source consulted>
code_inspected: "<what you inspected, or 'not inspected'>"
limits: "<material gaps>"
---
```

Then write:

- `# TLDR`: the compressed answer for a reader who sees nothing else.
- A top-down narrative that puts the reason to care and the most important ideas first. Decompose the subject into concepts the reader can hold, explain the evidence-backed pressures behind important structure, and add detail only where it advances the model.
- Section-level source pointers and visual cues. Give the render writer a strong narrative skeleton, the detail worth expanding, and visual opportunities that would clarify relationships. Mark short optional explanations as dropdown candidates.
- `# Judgment`: your concerns, unresolved uncertainty, source disagreements, and useful spot checks, visibly separate from the explanation.
- `# Appendix` only for relevant material the main reasoning does not depend on.

Keep the synthesis independently readable, concise enough to review at the owner checkpoint, and thinner than the eventual HTML. Use plain, specific headings and sentences. Preserve the user's own outline when they supplied one. Remove any section that does not help answer the question.
