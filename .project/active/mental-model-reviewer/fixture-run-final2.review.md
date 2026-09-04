# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: "How does Cutwater decide to reject a request?"
reviewed against: design_synthesis.md, feedback/synthesis.md

## Things to reconsider

1. Three sentences give the verb to an abstraction instead of to whatever does the thing: "the remaining budget decides whether the call goes through" (section 2 body), "A rejection tells the caller when to come back" (section 3 heading), and "a Redis outage removes all rate limiting at once" (Judgment, Concerns). This is the pattern the shared feedback names first and says to sweep the whole document for, not just the line you were shown (cites: feedback/synthesis.md, "Abstraction performing a verb").
2. Section 2.3 introduces its refill computation by count before naming the parts — "the amount added on each tick is computed in four steps. First, ... Second, ... Third, ... Fourth, ..." — instead of stating the structure first and presenting the steps as instances of it (cites: design_synthesis.md rule 6, "State the structure before the members... never introduce a category by how many parts it has"; the same phenomenon appears in feedback/synthesis.md as "Count standing in for the members").
3. Section 2.3's refill algorithm — four ordered steps with percentages, a cap, and reasoning about why the order matters — is multi-step backing for a concept that gets unpacked in place inside a subsection, rather than given its own numbered section further down with a pointer from where it's raised (cites: design_synthesis.md, narrative-body instructions, "When a concept's backing is itself multi-step reasoning, give that concept its own numbered section further down... Do not break the concept down where it first comes up"). At that level of detail it also reads closer to what the HTML render should add than to the skeleton (cites: design_synthesis.md, "What makes a bad synthesis," "The same words the HTML will use").

## Techniques worth considering

4. The aside in section 2.3 on why the four steps run in that order ("capping before scaling would leave a failing tenant its full ceiling") is exactly the kind of question a less-familiar reader would ask and that answers in a few sentences — a candidate to mark as a dropdown instead of leaving inline (cites: design_synthesis.md, narrative-body instructions, "Where a less-familiar reader would ask a question that answers in a few sentences, write the answer inline and mark it as a dropdown").
