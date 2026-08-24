# Product-Lens Ledger: Anchor the Pipeline on the Point

## audit — 2026-08-05 — rev 823cd21/worktree
Point (re-derived): Keep multi-session work anchored to what was agreed, independently and traceably verify that the delivered work is the right work, and test the same distributable pack users receive.   [source: `docs/guide.md:7`, `docs/STRUCTURE.md:49`, grade: INHERITED]
Falsifier: A fresh global or self-contained installation receives work that contradicts a durable ADR, but the lens cannot run, loses the finding, or allows audit/pre-PR/close to proceed without a blocking latest ledger verdict.
Findings:
- [DO] Record and supersede or amend the load-bearing ADR touch-point contract changed by the new epic-plan/spec/design-review/audit readers — `.project/adr/0001-decision-records-convention.md:17` (owner/HARD) — disposition: BLOCK
- [DON'T] New ADR reads at epic-plan, spec, design-review, and audit contradict active ADR 0002's exact touch-point decision — `.project/adr/0002-adr-touch-points.md:17` (`[AGENT]`, ratified by owner 2026-07-19) — disposition: pending new/superseding ADR id
- [DON'T] Vendored commands require the absent global `~/.claude/scripts/product-lens.md` instead of the copied `.claude/scripts/product-lens.md` — `README.md:284` (INHERITED) — disposition: pending global-and-vendored path resolution plus test
- [DO] Keep a customer-shaped end-to-end test proving lens → ledger → BLOCKED verdict → pre-PR/close stop; current evidence is non-executable prose and generic green checks — `docs/working-with-claude.md:163` (INHERITED) — disposition: pending live command-level fixture
- [DO] Require the expected latest ledger rather than treating a missing `product-lens.md` as clear — `docs/guide.md:88` (AGENT) — disposition: pending fail-closed gate behavior
Gate: BLOCKED (owner-grade decision-record obligation is unmet; product-drift smells also require escalation)

## remediation (owner-directed) — 2026-08-05 — rev anchor-on-the-point/worktree
Point (re-derived): unchanged from the audit block above.
Disposition of the audit findings:
- [owner/HARD] ADR touch-point obligation — DISPOSED: filed `.project/adr/0003` (product-lens touch points; provenance `[AGENT]` ratified by owner 2026-08-05) and ran `adr.sh amend 0002 0003`. Owner-grade obligation met.
- [DON'T] ADR reads conflict with active 0002 — DISPOSED: 0002 is now amended by 0003; its four-point core stands and the product-lens contacts are recorded, so no active decision is contradicted.
- fail-closed missing ledger — FIXED: `pre_pr` + `close` treat a missing expected ledger as a control failure.
- epic→item propagation (D2) — FIXED: `spec` carries an unresolved epic finding into the per-item ledger.
- audit escalation-≠-resolution + spec Problem grading + problem carriage at review/audit (SC1) — FIXED.
- smell numbering (canonical concept scheme) + fixture/answer-key drift — FIXED.
- [INHERITED] vendored + Codex reachability — DEFERRED (owner scope decision): distribution surfaces beyond global install are out of scope for this pass; tracked open.
- [INHERITED] live command-level e2e — DEFERRED: the lens engine is fixture-validated; a live BLOCK→disposition→CLEAR run is left to a fresh re-audit.
Gate: DISPOSED (owner-grade ADR obligation met via ADR 0003 + amend of 0002; lower-authority distribution/e2e items deferred with visible disposition — no unresolved owner/`[HARD]` contradiction remains)

## audit_v2 — 2026-08-05 — rev 823cd21/worktree
Point (re-derived): The pipeline must identify and STOP bugs instead of letting design, review,
testing, and certification approve the wrong work.   [source:
`.project/concepts/anchor-on-the-point.md:18-20`, grade: owner/HARD]
Falsifier: A supported installation or epic-level audit receives work that violates a durable
product obligation, but the lens does not run, the finding does not reach the ship gate, or the
audit certifies it.
Findings:
- [DO] Run the independent product-lens in epic-scope audit; `_my_audit` currently wires it only
  into work-item scope — `docs/guide.md:88-100` (INHERITED) and
  `.project/adr/0003-product-lens-touch-points.md:17-23` (AGENT, ratified) — disposition: pending
- [DON'T] Vendored commands point to absent `~/.claude/scripts/product-lens.md` instead of their
  copied `.claude/scripts/product-lens.md` — `README.md:284-292` (INHERITED) — disposition:
  deferred at the 2026-08-05 remediation block above
- [DON'T] Epic findings are duplicated between the epic Product-Lens block and copied per-item
  ledger findings, requiring manual synchronization — `docs/guide.md:7-19` (AGENT/INFERRED) —
  disposition: pending; smell 1
- [DO] Add an executable customer-shaped lens → ledger → BLOCKED → pre-PR/close test; the retained
  fixture is an expected-output document only — `docs/STRUCTURE.md:69-72` (INHERITED) —
  disposition: deferred at the 2026-08-05 remediation block above
- [DON'T] ADR 0003 preserves “exactly four touch points” by categorizing additional reads and
  writes as a separate product-lens-mediated kind despite unchanged observable ADR use —
  `.project/adr/0001-decision-records-convention.md:17-23` (AGENT/INFERRED application) —
  disposition: pending; smell 3
Gate: BLOCKED (unresolved §4 smells 1 and 3 must be dispositioned before certification; no
unresolved owner/HARD source contradiction remains)

## remediation v2 (owner-directed) — 2026-08-05 — rev anchor-on-the-point/worktree
Resolves the `audit_v2` BLOCK above, by citation (per §3 resolution-by-citation):
- **smell 1 (epic finding duplicated → manual sync)** — RESOLVED: `_my_spec` no longer copies the
  epic finding; it writes a one-line reference preserving the original grade, and ship gates +
  epic-scope audit read the epic's live gate. No duplicated representation remains (`_my_spec.md`,
  `_my_pre_pr.md`, `_my_close.md`, `_my_audit.md` epic scope).
- **smell 3 (ADR special-category exemption)** — RESOLVED: ADR 0003 superseded by **ADR 0004**,
  which states the touch-point map is extended (drops the "exactly four" framing) and amends 0002.
- **plan lacks a full-problem slot (SC1)** — FIXED: `_my_plan` template gains a structural
  "## The Point"; this plan carries it too.
- **amended ADRs treated as nonbinding** — FIXED: lens §2 counts a live ADR (`active` or `amended`)
  as owner-grade; only `superseded` stops binding.
- **later CLEAR masks earlier BLOCK** — FIXED: lens §3 requires resolution-by-citation; ship gates
  and epic audit scan every block, not just the latest.
- **epic-scope audit skipped the lens** — FIXED: epic scope now runs the lens over the assembled
  work and honors every item ledger + referenced epic finding.
- vendored/Codex reachability + live command-level e2e — still DEFERRED (owner scope), tracked open.
Gate: DISPOSED (audit_v2 BLOCK resolved by citation — smells 1 and 3 dispositioned via the fixes
above; no unresolved owner/`[HARD]` contradiction; distribution/e2e deferred with visible disposition)

## remediation v3 (owner-directed) — 2026-08-05 — rev anchor-on-the-point/worktree
Mechanism-hardening from the v3 review (fail-open paths + grading). No fresh product-lens BLOCK on
the work; gate stays DISPOSED.
Resolves:
- fail-open-1 (late epic BLOCK misses existing items): FIXED — authority: owner (directed) — basis: `_my_spec` records `Epic: <id>` unconditionally; `_my_pre_pr`/`_my_close`/`_my_audit` always read the epic's live gate for epic items.
- fail-open-2 (item audit certifies over an older BLOCK): FIXED — authority: owner — basis: item audit scans every ledger block, resolution-by-citation (§3).
- fail-open-3 (epic close skips the epic's own gate): FIXED — authority: owner — basis: epic-scope close reads the epic Product-Lens gate directly.
- grading-1 (live ADR laundered `[AGENT](ratified)` into owner authority): FIXED — authority: adr-0005 — basis: §2 separates liveness (status) from authority (provenance); ADR 0004 superseded by 0005.
- grading-2 (ambiguous resolution citations): FIXED — authority: owner — basis: §3 gives findings stable IDs (`<stage>-F<n>`) and a structured `Resolves:` record.
Open (deferred, owner scope):
- DEFER-F1: vendored + Codex distribution reachability.
- DEFER-F2: live command-level BLOCK→disposition→CLEAR e2e.
Gate: DISPOSED (no unresolved owner/`[HARD]`; DEFER-F1 and DEFER-F2 remain deferred with visible disposition)

## remediation v3.1 (owner-directed) — 2026-08-05 — rev anchor-on-the-point/worktree
Resolves:
- DEFER-F1 (Codex half): FIXED — authority: owner — basis: `scripts/build-codex-pack.sh` copies the
  shared product-lens spec into `dist/codex/scripts/` and rewrites command refs to
  `$HOME/.codex/scripts/product-lens.md`; dist rebuilt; `setup-codex.sh` installs it.
Still deferred: vendored/copy-install project reachability (commands hard-code `~/.claude/…`, which a
  project-local copy install would not resolve); DEFER-F2 (live command-level e2e).
Gate: DISPOSED (unchanged — no unresolved owner/`[HARD]`)
