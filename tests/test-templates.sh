#!/usr/bin/env bash
# Test suite for templates/
# Validates all 118 OS template files

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
echo "  Testing templates/"
echo "========================================="
echo ""

# Count templates
template_count=$(ls templates/ 2>/dev/null | wc -l)
echo "[1/6] Templates count: $template_count"
if [[ "$template_count" -gt 110 ]]; then
	pass "Found $template_count templates (>110)"
else
	fail "Only $template_count templates (expected >110)"
fi

# Test releases_() in all templates
echo "[2/6] Testing releases_()..."
missing_releases=0
for os in templates/*; do
	os_name="${os##*/}"
	if ! grep -q "^function releases_()" "$os" 2>/dev/null; then
		missing_releases=$((missing_releases + 1))
	fi
done
echo "  Missing releases_: $missing_releases"
if [[ "$missing_releases" -eq 0 ]]; then
	pass "All templates have releases_()"
else
	fail "$missing_releases templates missing releases_()"
fi

# Test get_() in all templates (except windows - special case)
echo "[3/6] Testing get_()..."
missing_get=0
for os in templates/*; do
	os_name="${os##*/}"
	# windows doesn't have get_() - special case
	if [[ "$os_name" == "windows" ]] || [[ "$os_name" == "windows-server" ]]; then
		continue
	fi
	if ! grep -q "^function get_()" "$os" 2>/dev/null; then
		missing_get=$((missing_get + 1))
	fi
done
echo "  Missing get_: $missing_get"
if [[ "$missing_get" -eq 0 ]]; then
	pass "All templates have get_() (except windows)"
else
	fail "$missing_get templates missing get_()"
fi

# Test key distributions
echo "[4/6] Testing key distributions..."
for os in debian ubuntu fedora arch linuxmint; do
	if [[ -f "templates/$os" ]]; then
		pass "templates/$os exists"
	else
		fail "templates/$os missing"
	fi
done

# Test editions_()
echo "[5/6] Testing editions_()..."
has_editions=0
for os in templates/*; do
	if grep -q "^function editions_()" "$os" 2>/dev/null; then
		has_editions=$((has_editions + 1))
	fi
done
echo "  Templates with editions_: $has_editions"
if [[ "$has_editions" -gt 0 ]]; then
	pass "$has_editions templates have editions_()"
else
	warn "No templates with editions_() found"
fi

# Test arch_()
echo "[6/6] Testing arch_()..."
has_arch=0
for os in templates/*; do
	if grep -q "^function arch_()" "$os" 2>/dev/null; then
		has_arch=$((has_arch + 1))
	fi
done
echo "  Templates with arch_: $has_arch"
if [[ "$has_arch" -gt 0 ]]; then
	pass "$has_arch templates have arch_()"
else
	warn "No templates with arch_() found"
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed, $warnings warnings"
echo "========================================="

[[ $failed -eq 0 ]]
