---
id: 0001
title: The harness directs agents by outcome and permission, not procedure
date: 2026-09-11
owner: Reid W
status: active
amended_by: []
superseded_by: null
supersedes: null
provenance: "[OWNER]"
surfaces: [commands, rules, reviewers, tests, hooks]
checked: null
---

## Promise

The pack is a harness for non-deterministic agents. It raises the odds of quality work and lowers slop and disorganization through hooks, scripts, and process, but it never tries to make the agent deterministic. Every instruction the pack gives an agent sets the expected outcome, says what the agent is allowed to do, and offers suggestions; it does not prescribe the exact procedural steps as the way to reach the outcome. Tests and hooks are spent where they add leverage to the agent, and the agent is trusted to make the rest of the system work.

## Authority

- `[OWNER-VERBATIM]` 2026-09-11, in chat, after Items 1 and 2 of epic KNOWLEDGE-HOMES each drew long review and audit cycles over literal mechanics: "This is a HARNESS. the goal is use hooks, scripts, and process to: maximize the chances of quality; minimize slop and disorganization. However, AI agents are still non-deterministic systems. This will never be fully deterministic. We must lean into that: focus the tests and hooks on what adds leverage to the agents; but we need to lean on agents to make sure the system works: give clear outcomes and expectations; provide some leeway in terms of 'how'. Pattern: Set the expectations, say what the agent is allowed to do, provide helpful suggestions. Anti-pattern: specifying exact procedural steps as a way to get to the end goals."
- `[OWNER]` `claude-pack/rules/pipeline.md:5` — "Stages are quality tools, not mandatory ceremony. Use the smallest set of stages that can produce high-quality, auditable work for the risk in front of you."
- `[OWNER]` `docs/guide.md:111` — "Reviews are for managing risk, not ceremony."

## Evidence

- The two cited lines are the only places the stance was written down before this entry. Exercised as a judgment standard, not by test.

## Scope

This is the standard every command, rule, reviewer, and test in the pack is held to. It is not yet uniformly met: Item 2 of epic KNOWLEDGE-HOMES (execution register) took eight audit iterations to certify (owner, 2026-09-11), and its audits and the Item 3 reviews (`.project/completed/20260910_execution-register/audit.md`, `.project/completed/20260911_session-bookkeeping/{spec-review,design-review}.md`) graded against exact greps, literal wording, and line-level invariants, which is the anti-pattern this promise names. Bringing the pack's prompts and reviewers in line is follow-up work, not part of this entry.
