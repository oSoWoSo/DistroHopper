#!/usr/bin/env bash
# Test suite for orphan detection
# Finds public/ files without templates and vice versa
# WARNING: This test only WARNS, does not fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0
warnings=0

pass() {
	echo -e "${GREEN}✓${NC} $1"
	((passed++)) || true
}
fail() {
	echo -e "${RED}✗${NC} $1"
	((failed++)) || true
}
warn() {
	echo -e "${YELLOW}⚠${NC} $1"
	((warnings++)) || true
}

echo "========================================="
echo "  Testing orphan detection (warn only)"
echo "========================================="
echo ""

# Orphan public/ files (no template)
echo "[1/2] Finding orphan public/ files (no template)..."
orphan_public=0
for f in public/*; do
	[[ -f "$f" ]] || continue
	[[ "$f" == public/tmp_* ]] && continue
	os="${f##*/}"
	if [[ ! -f "templates/$os" ]]; then
		echo "  Orphan: $os"
		orphan_public=$((orphan_public + 1))
	fi
done
echo "  Total orphan public/: $orphan_public"
if [[ "$orphan_public" -eq 0 ]]; then
	pass "No orphan public/ files"
else
	warn "$orphan_public orphan files in public/ (should be removed)"
fi

# Orphan tmp_ files (no template)
echo "[2/2] Finding orphan tmp_ files (no template)..."
orphan_tmp=0
for f in public/tmp_*; do
	[[ -f "$f" ]] || continue
	os="${f##tmp_}"
	if [[ ! -f "templates/$os" ]]; then
		echo "  Orphan tmp_: $os"
		orphan_tmp=$((orphan_tmp + 1))
	fi
done
echo "  Total orphan tmp_: $orphan_tmp"
if [[ "$orphan_tmp" -eq 0 ]]; then
	pass "No orphan tmp_ files"
else
	warn "$orphan_tmp orphan tmp_ files (should be removed)"
fi

# Missing public/ files (has template but no public)
echo ""
echo "[BONUS] Finding missing public/ files (have template)..."
missing_public=0
for f in templates/*; do
	os="${f##templates/}"
	if [[ ! -f "public/$os" ]]; then
		echo "  Missing: $os"
		missing_public=$((missing_public + 1))
	fi
done
echo "  Total missing: $missing_public"
if [[ "$missing_public" -gt 0 ]]; then
	warn "$missing_public missing public/ files (run generate)"
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed, $warnings warnings"
echo "========================================="
echo "NOTE: This test only warns, does not fail"

[[ $failed -eq 0 ]]
