# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: "How does Cutwater decide to reject a request?"
reviewed against: design_synthesis.md, synthesis.md (shared feedback)

## Things to reconsider

1. Line 45: "The remaining budget decides whether the call goes through." — Abstraction performing verb. Refactor to "Whether the call goes through depends on the remaining budget." (cites: FEEDBACK ENTRY 5)

2. TLDR lines 23–30: Terms 'tenant', 'caller', 'route', and 'Redis' appear before definition. Define each in plain words before first use. (cites: FEEDBACK ENTRY 4)

3. Line 38: "A rejected request never reaches a service." — Redundant with the previous sentence "either forwards the request or returns a rejection." Cut this clause. (cites: FEEDBACK ENTRY 7)

4. Section 2.3 body ("Refill runs on a ten-second tick..."): State the organizing principle (four-step refill computation) explicitly before enumerating the steps, not after. (cites: FEEDBACK ENTRY 10)

## Techniques worth considering

5. TLDR: Most bullets carry 0–2 sub-bullets; the suggested range is 5–10. Expand sub-bullets to support the claim that the TLDR "carries the entire story." (cites: prompt line 65, FEEDBACK ENTRY 2)
