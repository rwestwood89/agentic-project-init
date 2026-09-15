# Context Loading

## Before Starting Non-Trivial Work

1. **Read `.project/CURRENT_WORK.md`** — what is active right now and what is up next
2. **Skim `.project/product/INDEX.md` if present** — the product's implemented promises; open
   only the entries relevant to your task. An absent or empty ledger just means none recorded.
3. **Read the newest completions in `.project/completed/CHANGELOG.md` if present** — what just shipped, so you know whether the area you are about to touch was just changed. Run the bound rather than reading the file, so the cost is the same at 7 entries and at 70: `awk '/^## \[[0-9]/{n++; p=1} n>5{exit} /^### Deliverables/{p=0} /^---$/{p=0} p' .project/completed/CHANGELOG.md`. It returns the newest 5 entries, heading through `Summary`.
4. **Read the relevant docs** for the area you're working in (check CLAUDE.md for pointers)

## After Completing Work

If you discovered something that would save a future session time:
1. Suggest running `/_my_wrap_up` to persist context
2. Or at minimum, update `.project/CURRENT_WORK.md` with the current status

## Durable Knowledge Goes in Project Registers, Not Memory

Before saving to the native memory store, check whether it belongs in a `.project/` knowledge home instead — decisions in `adr/`, product promises in `product/`, discovered behaviors in `execution/`, pack-prompt corrections in `feedback/`. The routing table is in `.project/README.md` under "Knowledge Homes." The memory store is device-local and not owner-reviewed; the registers are git-tracked and durable.

## Don't Re-Research What's Already Documented

Before exploring the codebase to understand how something works, check:
- Project docs (often in `docs/`) for existing documentation
- `.project/research/` for previous deep investigations
- `.project/CURRENT_WORK.md` for recent work that may already cover the area
