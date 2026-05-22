#!/usr/bin/env bash
# Test suite for public/
# Validates generated OS info files

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
echo "  Testing public/"
echo "========================================="
echo ""

# Count files
file_count=$(ls public/ 2>/dev/null | wc -l)
echo "[1/5] Files count: $file_count"
if [[ "$file_count" -gt 200 ]]; then
	pass "Found $file_count public/ files (>200)"
else
	fail "Only $file_count files (expected >200)"
fi

# Test file format (KEY=VALUE)
echo "[2/5] Testing KEY=VALUE format..."
empty_count=0
has_osname=0
for f in public/*; do
	[[ -f "$f" ]] || continue
	[[ "$f" == public/tmp_* ]] && continue
	if [[ ! -s "$f" ]]; then
		empty_count=$((empty_count + 1))
		continue
	fi
	if grep -q "^OSNAME=" "$f" 2>/dev/null; then
		has_osname=$((has_osname + 1))
	fi
done
echo "  Empty files: $empty_count"
echo "  With OSNAME: $has_osname"
if [[ "$empty_count" -gt 0 ]]; then
	warn "$empty_count empty files (need regenerate)"
fi
if [[ "$has_osname" -gt 100 ]]; then
	pass "$has_osname files have OSNAME"
else
	fail "Only $has_osname files have OSNAME"
fi

# Test tmp_ files
echo "[3/5] Testing tmp_ files..."
tmp_count=$(ls public/tmp_* 2>/dev/null | wc -l)
echo "  tmp_ files: $tmp_count"
if [[ "$tmp_count" -gt 100 ]]; then
	pass "Found $tmp_count tmp_ files"
else
	warn "Only $tmp_count tmp_ files (expected >100)"
fi

# Test key distributions
echo "[4/5] Testing key distributions..."
for os in debian ubuntu fedora arch linuxmint; do
	if [[ -f "public/$os" ]]; then
		pass "public/$os exists"
	else
		fail "public/$os missing"
	fi
done

# Test consistency with templates
echo "[5/5] Testing public/ vs templates/..."
template_count=$(ls templates/ | wc -l)
public_count=$(ls public/[^t]* | wc -l)
gap=$((template_count - public_count))
echo "  Templates: $template_count, Public: $public_count, Gap: $gap"
if [[ "$gap" -lt 10 ]]; then
	pass "public/ matches templates ($gap gap)"
else
	warn "Gap of $gap between templates and public"
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed, $warnings warnings"
echo "========================================="

[[ $failed -eq 0 ]]
