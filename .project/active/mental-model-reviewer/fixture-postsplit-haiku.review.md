# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: "How does Cutwater decide to reject a request?"
reviewed against: claude-pack/skills/_my_mental_model/design_synthesis.md, claude-pack/skills/_my_mental_model/feedback/synthesis.md

## Things to reconsider

1. Subsection 2.3 lacks a visual form cue. The four-step refill logic is the most complex mechanism in the synthesis and warrants explicit visual guidance for the render agent. Add a visual form line naming what would represent those steps clearly (a sequence diagram, a state table, or a process flow). — subsection 2.3, "The allowance drains and refills" (cites: design_synthesis.md "For each section in the narrative: Name the visual form that would fit this section if it were rendered")

2. Subsection 2.3 is dense and would benefit from restructuring. The paragraph explaining the four refill steps packs multiple complex ideas—four sequential steps, each with conditional logic and rationale—into a single long narrative. Rule 10 states: "If something cannot be explained in three or four short phrases, prose is the wrong medium. Use a table, a list, or a diagram." Breaking the steps into a clearer structure (numbered list with explanations of each step's purpose) would improve readability. — subsection 2.3, lines 59-62 (cites: design_synthesis.md rule 10)

## Techniques worth considering

nothing to add
