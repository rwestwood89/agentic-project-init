---
id: 0006
title: Concept-design review reads ADRs but does not file them
date: 2026-08-07
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[AGENT]"
seams: [claude-pack/commands, project-pack]
supersedes: null
promoted_to: null
---

## Decision

`_my_concept_design_review` reads the ADR index and relevant live entries so it can
pressure-test the concept's Prior Art and ADR candidates against current decisions. It
does not file, amend, or supersede records; accepted concept decisions remain filed only
after review resolutions and final concept acceptance.

## Why

The owner requires ADR candidates to be visible during concept design and pressure-tested
by a fresh architecture reviewer. Reviewing a candidate without checking the live record
it may duplicate or contradict would inherit the author's framing and miss the conflict.
The read therefore extends ADR 0005's touch-point map. Keeping writes at final concept
acceptance preserves ADR 0002's write discipline and prevents a reviewer from turning a
candidate into durable policy.

## Invariants established

- Concept-design review reads only the live ADRs relevant to Prior Art or a candidate's seams.
- A review may recommend `keep`, `reshape`, or `drop`; it never files the candidate.
- Final concept acceptance remains the write point and preserves the decision's actual provenance.

## Rejected alternatives

- Review only the concept's candidate summary: rejected because a summary cannot reveal an omitted or misrepresented live decision.
- Let the reviewer file accepted candidates: rejected because review findings are not owner acceptance and would move ADR writes into an evaluator.
