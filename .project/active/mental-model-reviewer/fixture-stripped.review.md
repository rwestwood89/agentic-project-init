# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: How does Cutwater decide to reject a request?
reviewed against: design_synthesis.md, feedback/synthesis.md

## Things to reconsider

1. "The remaining budget decides whether the call goes through" gives the decision to an abstraction instead of to Cutwater — section 2's opening paragraph (cites: feedback/synthesis.md, "Abstraction performing a verb" — matches its bad example "stored energy decides the check" almost exactly).
2. "2.3 The allowance drains and refills" decomposes a four-step reasoning chain in place, inside a subsection, instead of giving it its own numbered section, and the four steps run as one dense paragraph where a list or table would carry it (cites: design_synthesis.md, "a concept whose backing is itself multi-step reasoning gets its own numbered section further down... do not decompose it in place," and rule 10, "if something cannot be explained in three or four short phrases, prose is the wrong medium").
3. The TLDR's last bullet names an implementation file, `budget.py`, pulling a lower layer's detail into the highest-level summary (cites: design_synthesis.md's TLDR rule, "no loaded terms... as little background knowledge as possible," and rule 7, "state every fact at its own layer").
4. "Tenant" is used from the TLDR's second bullet onward, and load-bearing in "2.1 The tenant id names the allowance," but is never given a plain-word definition anywhere in the artifact (cites: design_synthesis.md rule 3, "define a term in plain words before using it, or use plain words instead," and the TLDR rule against a term the reader has not already been given).
5. In section 4, "`admit.py` forwards the request and records nothing" tacks the absence on as a trailing clause rather than giving it the sentence and stating the consequence directly (cites: feedback/synthesis.md, "Negative clause added for rhythm" — compare its bad example "A client sends a bearer token and nothing else").

## Techniques worth considering

6. Nothing in the artifact is marked as a dropdown, though section 2.3's aside on why failing tenants are scaled down ("a failing tenant is usually retrying, and retries are the cheapest traffic to shed") is exactly the short "why" answer the prompt asks to mark as a dropdown — it would apply there, and similarly to section 4's aside on why fail-open is deliberate (cites: design_synthesis.md, "where a less-familiar reader would ask a question that answers in a few sentences, write the answer inline and mark it as a dropdown").
