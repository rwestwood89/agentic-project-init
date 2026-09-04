# Review notes — fixture-planted-synthesis.md

artifact: /home/rwestwood/agentic-project-init/.project/active/mental-model-reviewer/fixture-planted-synthesis.md
question: How does Cutwater decide to reject a request?
reviewed against: design_synthesis.md, feedback/synthesis.md

## Things to reconsider

1. Section 2.3's four-step refill process is dense and would be clearer as a bulleted list or table instead of continuous prose. The process involves multiple interdependent steps (base rate → error scaling → ceiling cap → unspent carryover) with conditional logic and example thresholds; this structure warrants visual separation per Rule 15 (cites: feedback/synthesis.md Rule 15).

## Techniques worth considering

2. Section 2.3 could include granular code line references within its prose—e.g., "the tier table (services/cutwater/budget.py:20–35)" and "route group ceiling (services/cutwater/budget.py:40–50)"—to ground each abstraction directly at its source, rather than relying solely on the section-level "detail lives in" pointer (cites: feedback/synthesis.md Rule 11).

3. Inline explanations that answer a less-familiar reader's likely question could be marked as dropdowns so the render agent structures them as interactive details. Example: the error-rate scaling rationale in section 2.3 ("the argument in the design document is that a failing tenant is usually retrying...") would benefit from dropdown markup (cites: design_synthesis.md, "mark it as a dropdown").

4. Section 4's opening could state purpose before mechanism: lead with "Cutwater holds only one piece of persistent state" (purpose), then explain "a Redis hash per tenant" (mechanism), to follow Rule 9 more explicitly (cites: feedback/synthesis.md Rule 9).
