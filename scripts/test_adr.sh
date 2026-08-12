#!/bin/bash
# Tests for project-pack/scripts/adr.sh — allocation, collision, flips,
# idempotent index regeneration, lazy bootstrap.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADR_SH="$SCRIPT_DIR/../project-pack/scripts/adr.sh"

PASS=0
FAIL=0

check() { # check <description> <command...>
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        echo "  ✓ $desc"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ $desc"
    fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
git init -q .
git config user.name "Test User"
mkdir .project

echo "adr.sh tests (in $WORK)"

# --- new: lazy bootstrap + allocation ---
FIRST="$("$ADR_SH" new first-entry --title "First entry")"
check "bootstrap creates .project/adr/" test -d .project/adr
check "first entry gets id 0001" test -f .project/adr/0001-first-entry.md
check "new prints the entry path" test "$FIRST" = "$PWD/.project/adr/0001-first-entry.md"
check "frontmatter has title" grep -q "^title: First entry$" .project/adr/0001-first-entry.md
check "frontmatter has owner from git" grep -q "^owner: Test User$" .project/adr/0001-first-entry.md
check "frontmatter starts active" grep -q "^status: active$" .project/adr/0001-first-entry.md
check "INDEX.md generated" test -f .project/adr/INDEX.md
check "INDEX.md lists 0001" grep -q "0001 · First entry" .project/adr/INDEX.md

"$ADR_SH" new second-entry >/dev/null
check "second entry gets id 0002" test -f .project/adr/0002-second-entry.md
check "default title from slug" grep -q "^title: second entry$" .project/adr/0002-second-entry.md

# --- collision guard: manually claimed number is skipped ---
touch .project/adr/0003-manually-claimed.md
"$ADR_SH" new third-entry >/dev/null
check "collision guard skips claimed 0003" test -f .project/adr/0004-third-entry.md
rm .project/adr/0003-manually-claimed.md

# --- supersede: atomic pair of flips ---
"$ADR_SH" supersede 0001 0002 >/dev/null
check "old entry marked superseded" grep -q "^status: superseded$" .project/adr/0001-first-entry.md
check "old entry links successor" grep -q "^superseded_by: 0002$" .project/adr/0001-first-entry.md
check "new entry links predecessor" grep -q "^supersedes: 0001$" .project/adr/0002-second-entry.md
check "index shows supersession" grep -q "superseded → 0002" .project/adr/INDEX.md
check "body untouched by flip" grep -q "## Decision" .project/adr/0001-first-entry.md

# --- amend: list append, superseded not downgraded ---
"$ADR_SH" new fourth-entry >/dev/null
"$ADR_SH" amend 0004 0005 >/dev/null
check "amended_by records first amender" grep -q "^amended_by: \[0005\]$" .project/adr/0004-third-entry.md
check "amended status set" grep -q "^status: amended$" .project/adr/0004-third-entry.md
"$ADR_SH" new sixth-entry >/dev/null
"$ADR_SH" amend 0004 0006 >/dev/null
check "amended_by appends second amender" grep -q "^amended_by: \[0005, 0006\]$" .project/adr/0004-third-entry.md
"$ADR_SH" amend 0001 0006 >/dev/null
check "superseded status not downgraded by amend" grep -q "^status: superseded$" .project/adr/0001-first-entry.md

# --- index: regeneration is idempotent and derived-only ---
cp .project/adr/INDEX.md "$WORK/index.before"
"$ADR_SH" index >/dev/null
check "index regeneration idempotent" diff -q "$WORK/index.before" .project/adr/INDEX.md
echo "HAND EDIT" >> .project/adr/INDEX.md
"$ADR_SH" index >/dev/null
check "hand edits to index are discarded" diff -q "$WORK/index.before" .project/adr/INDEX.md
check "active entries listed before superseded" awk '/^- 0002/{a=NR} /^- 0001/{s=NR} END{exit !(a<s)}' .project/adr/INDEX.md

# --- errors ---
check "unknown id fails" bash -c "! '$ADR_SH' supersede 9999 0002"
check "no-args prints usage and fails" bash -c "! '$ADR_SH'"

# --- lifecycle guards: invalid transitions are rejected, not warned past ---
check "self-supersession rejected" bash -c "! '$ADR_SH' supersede 0004 0004"
check "self-amendment rejected" bash -c "! '$ADR_SH' amend 0004 0004"
check "re-supersession rejected (would overwrite successor link)" bash -c "! '$ADR_SH' supersede 0001 0004"
check "re-supersession left history intact" grep -q "^superseded_by: 0002$" .project/adr/0001-first-entry.md

# --- concurrency: parallel new calls never reuse an id ---
for i in 1 2 3 4 5 6 7 8; do "$ADR_SH" new "conc-$i" >/dev/null 2>&1 & done
wait
CONC_FILES="$(ls .project/adr/[0-9][0-9][0-9][0-9]-conc-*.md 2>/dev/null | wc -l)"
DUP_IDS="$(ls .project/adr/[0-9][0-9][0-9][0-9]-*.md | sed 's/.*\/\([0-9]\{4\}\)-.*/\1/' | sort | uniq -d | wc -l)"
check "all 8 concurrent new calls filed" test "$CONC_FILES" -eq 8
check "concurrent allocation produced no duplicate ids" test "$DUP_IDS" -eq 0
check "allocation lock released" bash -c "! test -d .project/adr/.lock"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
