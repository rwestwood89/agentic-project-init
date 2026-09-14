---
id: 0013
title: Mental-model coordinator owns readiness; feedback remains filtered
date: 2026-09-06
owner: Reid W
status: active
amended_by: []
superseded_by: null
provenance: "[OWNER]"
seams: [claude-pack/skills/_my_mental_model_v2, project-pack .project/mental-alignment-v2 feedback tiers]
supersedes: null
promoted_to: null
---

## Decision

The mental-model coordinator judges every initial and revised artifact against its best current understanding of the user and releases it only when it clears that bar. The reviewer is an advisory pattern checker: only it reads both shared and project-local feedback, while writers retain their relevant project-local feedback and the coordinator receives filtered findings rather than the feedback files.

## Why

Historical feedback is useful as pattern memory, but exposing the whole corpus to a writer makes its many checks displace the writing objective. The reviewer isolates that corpus and surfaces relevant instances. The coordinator retains the request and conversation, so it must own the final reader judgment instead of treating reviewer findings or completed fixes as proof of quality.

## Invariants established

- A clean review never grants a pass, and reviewer findings never decide readiness.
- A user correction updates the coordinator's judgment across the whole artifact and later iterations, not only the named defect.
- Attempt count never lowers the bar; if the workflow cannot clear it, the coordinator reports failure rather than presenting below-bar work as ready.
- The synthesis writer reads project-local synthesis feedback; the render writer reads project-local synthesis and HTML feedback; neither reads shared feedback.
- The coordinator reads artifacts and review findings, not shared or project-local feedback files.

## Rejected alternatives

- The reviewer as readiness gate was rejected because rule matching cannot establish that an artifact is good for the user.
- A coordinator expectation ledger was rejected because the coordinator already has the authoritative request and conversation.
- Giving writers the full feedback corpus was rejected because conditional historical patterns would compete with their objective.
