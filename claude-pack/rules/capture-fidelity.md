# Capture Fidelity

Four laws for the chat → artifact → artifact pipeline. Every hop is an agent writing
something a later agent treats as ground truth; these laws keep the writing honest about
where its authority came from.

**Budget: this rule stays ≤ ~40 lines of substance.** A correction lands as a sharper
existing law, never as a new one — the ratchet this rule exists to stop applies to it too.

**Scope.** These laws govern decision-carrying items — settled lists, requirements, ground
rules, non-goals, referents — never ordinary prose. Enforcement is structural where it can
be (provenance, at review) and honest best-effort where it cannot (surfacing; the first
chat → concept hop, whose only checker is the owner reading the capture).

## 1. Provenance — mark who decided

Authority comes from the source, not from being written down. Grade every decision-carrying
item by who decided it, and preserve the grade across every hop.

| register | vocabulary | settled-eligible |
|---|---|---|
| shaping (concept, epic, settled lists) | `[OWNER-VERBATIM]` (quote required) `[OWNER]` `[AGENT]` `[INHERITED: src]` | owner grades only |
| spec (requirements) | `[HARD]` `[NEED]` (owner-stated) `[INFERRED]` `[INHERITED]` | `[HARD]`, `[NEED]` |
| payload (any artifact) | `[EXAMPLE]` / `[REFERENT]`, or force stated in words | force must be stated |
| design (bets, decisions) | agent-grade by construction | n/a |

**The settled rule.** Only owner-grade items may be marked settled / do-not-relitigate.
Agent- and inherited-grade items are challengeable when evidence warrants; inherited items
are never settled by default.

**Absorb mapping (concept → spec).** `[OWNER-VERBATIM]` → `[NEED]` carrying the quote or a
path-cite to the concept; `[OWNER]` → `[NEED]`; `[AGENT]` → `[INFERRED]`; `[INHERITED: src]`
→ `[INHERITED]`, source carried. An inferred outcome is `[INFERRED]`, never `[NEED]`.

## 2. Compression — the owner's payload survives

Owner-given examples, referents, numbers, and named standards are payload: they survive
capture verbatim or by path, at the owner's emphasis, with their force marked — an example
illustrates the kind (`[EXAMPLE]`), a referent is the bar to match (`[REFERENT]`). An example
must not harden into the required form, nor a referent soften into a vibe. Unclear force → ask.

## 3. Correction — shrink or amend, never accrete

A correction deletes or amends the corrected content at the owner's emphasis. Deleted means
deleted: no compensating prose about the non-requirement, no emphasis markers beyond what the
owner expressed. A rejected path that must be recorded gets one line in its designated home
(Non-Goals, or a design's rejected-alternative note), phrased as a decision record, never as
an instruction to future agents. Governs every artifact write, memories and handoffs included.

- BAD: suggestion → rejection → "WE MUST NOT \<suggestion\>". The prohibition anchors future
  agents on the suggestion in a way the owner never intended.
- GOOD: suggestion → rejection → "Out of scope: \<suggestion\> is not required because
  \<reason\>". Context and color along a well-worn agent reasoning path.

## 4. Surfacing — never resolve a premise conflict silently

Trigger: following a recorded rule would work against the recorded goal, or genuine surprise
produces evidence against a premise the plan rests on. Response: surface it — to the owner
when reachable, otherwise loudly in the artifact, with dependent conclusions parked. Never
resolve it silently, in either direction.
