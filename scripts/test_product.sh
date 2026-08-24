#!/bin/bash
# Tests for project-pack/scripts/product.sh — allocation, collision, flips,
# checked stamps, idempotent index regeneration, lazy bootstrap.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRODUCT_SH="$SCRIPT_DIR/../project-pack/scripts/product.sh"

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

TODAY="$(date '+%Y-%m-%d')"

echo "product.sh tests (in $WORK)"

# --- new: lazy bootstrap + allocation ---
FIRST="$("$PRODUCT_SH" new one-source --title "One modeled source produces one public input")"
check "bootstrap creates .project/product/" test -d .project/product
check "first entry gets id 0001" test -f .project/product/0001-one-source.md
check "new prints the entry path" test "$FIRST" = "$PWD/.project/product/0001-one-source.md"
check "frontmatter has title" grep -q "^title: One modeled source produces one public input$" "$FIRST"
check "frontmatter has owner from git" grep -q "^owner: Test User$" "$FIRST"
check "frontmatter starts active" grep -q "^status: active$" "$FIRST"
check "frontmatter checked starts null (unverified until stamped)" grep -q "^checked: null$" "$FIRST"
check "skeleton has Promise section" grep -q "^## Promise$" "$FIRST"
check "skeleton has Authority section" grep -q "^## Authority$" "$FIRST"
check "skeleton has Evidence section" grep -q "^## Evidence$" "$FIRST"
check "skeleton has Scope section" grep -q "^## Scope$" "$FIRST"
check "INDEX.md generated" test -f .project/product/INDEX.md
check "INDEX.md lists 0001" grep -q "0001 · One modeled source produces one public input" .project/product/INDEX.md
check "index carries no checked stamp before first check" bash -c "! grep -q 'checked:' .project/product/INDEX.md"

"$PRODUCT_SH" new second-promise >/dev/null
check "second entry gets id 0002" test -f .project/product/0002-second-promise.md
check "default title from slug" grep -q "^title: second promise$" .project/product/0002-second-promise.md

# --- collision guard: manually claimed number is skipped ---
touch .project/product/0003-manually-claimed.md
"$PRODUCT_SH" new third-promise >/dev/null
check "collision guard skips claimed 0003" test -f .project/product/0004-third-promise.md
rm .project/product/0003-manually-claimed.md

# --- no content gates: skeleton-only entries flip freely (README owns the bar) ---
"$PRODUCT_SH" supersede 0001 0002 >/dev/null
check "old entry marked superseded" grep -q "^status: superseded$" .project/product/0001-one-source.md
check "old entry links successor" grep -q "^superseded_by: 0002$" .project/product/0001-one-source.md
check "new entry links predecessor" grep -q "^supersedes: 0001$" .project/product/0002-second-promise.md
check "index shows supersession" grep -q "superseded → 0002" .project/product/INDEX.md
check "body untouched by flip" grep -q "## Promise" .project/product/0001-one-source.md

# --- amend: list append, superseded not downgraded ---
"$PRODUCT_SH" new fourth-promise >/dev/null
"$PRODUCT_SH" amend 0004 0005 >/dev/null
check "amended_by records first amender" grep -q "^amended_by: \[0005\]$" .project/product/0004-third-promise.md
check "amended status set" grep -q "^status: amended$" .project/product/0004-third-promise.md
"$PRODUCT_SH" new sixth-promise >/dev/null
"$PRODUCT_SH" amend 0004 0006 >/dev/null
check "amended_by appends second amender" grep -q "^amended_by: \[0005, 0006\]$" .project/product/0004-third-promise.md
"$PRODUCT_SH" amend 0001 0006 >/dev/null
check "superseded status not downgraded by amend" grep -q "^status: superseded$" .project/product/0001-one-source.md

# --- check: script-managed re-verification stamp ---
"$PRODUCT_SH" check 0002 >/dev/null
check "check stamps today's date" grep -q "^checked: $TODAY$" .project/product/0002-second-promise.md
"$PRODUCT_SH" check 0002 abc1234 >/dev/null
check "check with ref stamps date @ ref" grep -q "^checked: $TODAY @ abc1234$" .project/product/0002-second-promise.md
check "index carries checked date" grep -q "checked: $TODAY" .project/product/INDEX.md
check "check leaves body untouched" grep -q "## Promise" .project/product/0002-second-promise.md

# --- index: regeneration is idempotent and derived-only ---
cp .project/product/INDEX.md "$WORK/index.before"
"$PRODUCT_SH" index >/dev/null
check "index regeneration idempotent" diff -q "$WORK/index.before" .project/product/INDEX.md
echo "HAND EDIT" >> .project/product/INDEX.md
"$PRODUCT_SH" index >/dev/null
check "hand edits to index are discarded" diff -q "$WORK/index.before" .project/product/INDEX.md
check "active entries listed before superseded" awk '/^- 0002/{a=NR} /^- 0001/{s=NR} END{exit !(a<s)}' .project/product/INDEX.md

# --- errors ---
check "unknown id fails" bash -c "! '$PRODUCT_SH' supersede 9999 0002"
check "check on unknown id fails" bash -c "! '$PRODUCT_SH' check 9999"
check "no-args prints usage and fails" bash -c "! '$PRODUCT_SH'"
check "usage names all five subcommands" bash -c "u=\$('$PRODUCT_SH' 2>&1); for c in new supersede amend check index; do grep -q \"\$c\" <<<\"\$u\" || exit 1; done"

# --- lifecycle guards: invalid transitions are rejected, not warned past ---
check "self-supersession rejected" bash -c "! '$PRODUCT_SH' supersede 0004 0004"
check "self-amendment rejected" bash -c "! '$PRODUCT_SH' amend 0004 0004"
check "re-supersession rejected (would overwrite successor link)" bash -c "! '$PRODUCT_SH' supersede 0001 0004"
check "re-supersession left history intact" grep -q "^superseded_by: 0002$" .project/product/0001-one-source.md

# --- malformed entries fail loudly, never silently no-op ---
sed -i '/^checked:/d' .project/product/0006-sixth-promise.md
check "check on entry missing the field fails" bash -c "! '$PRODUCT_SH' check 0006"
touch .project/product/0002-duplicate-id.md
check "ambiguous id rejected" bash -c "! '$PRODUCT_SH' check 0002"
rm .project/product/0002-duplicate-id.md

# --- concurrency: parallel new calls never reuse an id ---
for i in 1 2 3 4 5 6 7 8; do "$PRODUCT_SH" new "conc-$i" >/dev/null 2>&1 & done
wait
CONC_FILES="$(ls .project/product/[0-9][0-9][0-9][0-9]-conc-*.md 2>/dev/null | wc -l)"
DUP_IDS="$(ls .project/product/[0-9][0-9][0-9][0-9]-*.md | sed 's/.*\/\([0-9]\{4\}\)-.*/\1/' | sort | uniq -d | wc -l)"
check "all 8 concurrent new calls filed" test "$CONC_FILES" -eq 8
check "concurrent allocation produced no duplicate ids" test "$DUP_IDS" -eq 0
check "allocation lock released" bash -c "! test -d .project/product/.lock"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
