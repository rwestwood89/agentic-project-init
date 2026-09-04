# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: "How does Cutwater decide to reject a request?"
reviewed against: design_synthesis.md, feedback/synthesis.md (no project-local feedback file for this project)

## Things to reconsider

1. Section 2.3 ("The allowance drains and refills") writes out the refill formula as four numbered steps with specific percentages, a rounding rule, and a stated execution order — this is the detail layer the HTML render is supposed to add, not the skeleton. Cites design_synthesis.md: "Stay at the skeleton level," and the bad-synthesis criterion "Dense detail without a narrative thread. If a reader has to hold ten facts before any conclusion lands, the structure is wrong." The same instruction also says a concept whose backing is multi-step reasoning "gets its own numbered section further down... do not decompose it in place" — 2.3 should become its own top-level section rather than living inside section 2.
2. Sections 2.1, 2.2, and 2.3 carry no Provenance, Visual form, or Detail-lives-in lines, unlike every other section in the doc (1, 2, 3, 4, 5 all have all three). Cites design_synthesis.md's per-section requirement: "For each section in the narrative: state the claim... note its provenance... name the visual form... point to where the underlying detail lives."
3. "the amount added on each tick is computed in four steps" (section 2.3) introduces the mechanism by its count before naming what organizes it. Cites feedback/synthesis.md rule 10: "Name the members; never introduce a category by how many parts it has. If you cannot name the organizing principle, stop: that is a finding."
4. "capped by the route group's own ceiling" (section 2.3) uses "route group" without ever defining it or saying how it differs from the "route" introduced in 2.2. Cites feedback/synthesis.md rule 4: "Define a term in plain words before using it, or use plain words instead."
5. "The remaining budget decides whether the call goes through" (section 2 opener) makes an abstraction the actor of a verb. Cites feedback/synthesis.md rule 5 and its own worked example almost exactly: "Rejected: `stored energy decides the check`. Correct: `whether the check passes depends on how much energy the store holds`."
6. "Failing open is a deliberate choice recorded in the design document, not an accident of the code" (TLDR bullet 4, echoed in section 4) appends a negative clause to a positive claim for contrast. Cites feedback/synthesis.md rule 8: "Never append a negative clause to a positive claim for contrast or rhythm."
7. "A rejected request never reaches a service" (section 1, second paragraph) restates what the same paragraph already said one sentence earlier ("forwards the request or returns a rejection"). Cites feedback/synthesis.md rule 7: "Cut every clause the reader already has, from an earlier sentence or from the layout."

## Techniques worth considering

8. The aside in section 2.3 — "the order matters: capping before scaling would leave a failing tenant its full ceiling" — answers a reader's likely question inline in the main sentence. Cites design_synthesis.md's dropdown instruction: "Where a less-familiar reader would ask a question that answers in a few sentences, write the answer inline and mark it as a dropdown." Marking it as a dropdown would shorten the main sentence.
9. The four ordered steps in section 2.3 (base rate, error-rate scaling, ceiling cap, carry-forward) are a natural fit for a short table or numbered list rather than one paragraph. Cites feedback/synthesis.md rule 15: "If something cannot be explained in three or four short phrases, prose is the wrong medium. Use a table, a list, or a diagram."
