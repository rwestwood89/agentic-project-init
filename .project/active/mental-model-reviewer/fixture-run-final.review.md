# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: "How does Cutwater decide to reject a request?"
reviewed against: claude-pack/skills/_my_mental_model/design_synthesis.md, claude-pack/skills/_my_mental_model/feedback/synthesis.md

## Things to reconsider

1. "The remaining budget decides whether the call goes through" gives the verb to an abstraction instead of the actor, the same shape as the quoted bad examples — section 2, line 45 (the pattern recurs at "A Redis outage fails open" in the TLDR, line 27) (cites: feedback/synthesis.md, "Abstraction performing a verb")
2. Section 2.3 introduces the refill computation by its count — "computed in four steps" — before naming a single step, then runs all four as one dense paragraph instead of a list — section 2.3, line 61 (cites: design_synthesis.md Rule 6, "never introduce a category by how many parts it has," and Rule 11, "if something cannot be explained in three or four short phrases... use a table, a list, or a diagram")
3. Section 2.3 states "the argument in the design document is that a failing tenant is usually retrying, and retries are the cheapest traffic to shed" under section 2's blanket "Provenance: code observation" tag (line 47), without marking that this particular claim's source is the design document rather than the code — section 2.3, line 61 (cites: design_synthesis.md, Narrative body, "Say whether you saw it in the code or read it as an aspiration in a design document")

## Techniques worth considering

4. No sentence in the artifact is marked as a dropdown, though the prompt calls for one wherever a less-familiar reader would ask a question answerable in a few sentences. Two candidates: section 2.1's aside on a request with no tenant id (line 53), and section 2.3's rationale for ticking the refill rather than running it continuously (line 61) (cites: design_synthesis.md, Narrative body, "write the answer inline and mark it as a dropdown")
