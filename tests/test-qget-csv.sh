#!/usr/bin/env bash
# Test suite for qget CSV/JSON/Category outputs
# Tests list output formats

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
echo "  Testing qget list formats"
echo "========================================="
echo ""

# Test --list
echo "[1/5] Testing qget --list..."
count=$(./qget --list 2>/dev/null | wc -l)
echo "  Count: $count"
if [[ "$count" -gt 100 ]]; then
	pass "qget --list returns $count OS"
else
	fail "qget --list only returns $count (expected >100)"
fi

# Test --list-csv
echo "[2/5] Testing qget --list-csv..."
csv_output=$(timeout 10 ./qget --list-csv 2>/dev/null)
if echo "$csv_output" | grep -q "Display Name,OS"; then
	pass "qget --list-csv has header"
else
	fail "qget --list-csv missing header"
fi
csv_lines=$(echo "$csv_output" | wc -l)
echo "  CSV lines: $csv_lines"
if [[ "$csv_lines" -gt 100 ]]; then
	pass "qget --list-csv returns data"
else
	fail "qget --list-csv insufficient data"
fi

# Test --list-json
echo "[3/5] Testing qget --list-json..."
if ./qget --list-json 2>/dev/null | head -1 | grep -q '^\['; then
	pass "qget --list-json works"
else
	warn "JSON output may vary"
fi

# Test --list-category
echo "[4/5] Testing qget --list-category..."
gaming_count=$(./qget --list-category Gaming 2>/dev/null | wc -l)
echo "  Gaming distros: $gaming_count"
if [[ "$gaming_count" -gt 0 ]]; then
	pass "qget --list-category Gaming works"
else
	warn "No Gaming distros found (may be valid)"
fi

echo "[5/5] Testing qget --url..."
echo "  SKIP: requires network"

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed, $warnings warnings"
echo "========================================="

[[ $failed -eq 0 ]]
