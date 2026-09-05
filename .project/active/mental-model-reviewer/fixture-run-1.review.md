# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: "How does Cutwater decide to reject a request?"
reviewed against: design_synthesis.md, feedback/synthesis.md

## Things to reconsider

1. Subsections 2.1–2.3 lack the structured provenance, visual form, and detail-lives-in markers that top-level sections provide — design_synthesis.md requires "Note its provenance," "Name the visual form," and "Point to where the underlying detail lives" for each section. Section 2.1 (The tenant id names the allowance), section 2.2 (The route has a fixed cost), and section 2.3 (The allowance drains and refills) state their claims but omit the labeled markers (Provenance:, Visual form:, Detail lives in:) that sections 1, 3, 4, and 5 include. This breaks the pattern and prevents the render agent from finding the information it needs (cites: design_synthesis.md, section "For each section in the narrative").

## Techniques worth considering

1. Section 2.3's four-step refill algorithm is dense prose: "First, the tier's base rate...Second, that rate is scaled...Third, the scaled rate is capped...Fourth, any unspent allowance..." — feedback/synthesis.md Rule 15 states: "If something cannot be explained in 3–4 phrases, prose is the wrong medium. Use a table, a list, or a diagram." A bulleted list would make the four steps and their sequencing (especially "the order matters: capping before scaling") clearer — where it would apply: section 2.3, replacing or complementing the paragraph (cites: feedback/synthesis.md Rule 15).
