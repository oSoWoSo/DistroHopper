#!/usr/bin/env bash
# Test suite for generate script
# Validates generate --help and basic operations

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
echo "  Testing generate script"
echo "========================================="
echo ""

# Test --help
echo "[1/4] Testing generate --help..."
help_output=$(./generate --help 2>&1)
if echo "$help_output" | grep -q "Usage:"; then
	pass "generate --help works"
else
	fail "generate --help failed"
fi

# Test single OS generate
echo "[2/4] Testing generate arch..."
echo "  SKIP: requires network"

# Test -t flag (show ISO links)
echo "[3/4] Testing generate -t arch..."
echo "  SKIP: requires network"

# Test --version
echo "[4/4] Testing generate --version..."
version=$(./generate --version 2>&1)
if [[ -n "$version" ]]; then
	pass "generate --version: $version"
else
	fail "generate --version failed"
fi

# ---------------------------------------------------------------------------
# Unit tests for write_output (no network required)
# ---------------------------------------------------------------------------

# Source only function definitions from generate (skip main execution block).
# awk prints every line that is inside a function body (from "^function " to "^}").
_load_generate_fns() {
	source lib.sh
	source <(awk '/^function /{in_f=1} in_f{print} /^\}$/{in_f=0}' generate)
}

test_spec_func_no_leakage() {
	echo "[spec_func] Testing SPEC_FUNC does not leak between OSes..."
	local tmpdir pub_dir
	tmpdir=$(mktemp -d)
	pub_dir="${tmpdir}/public"
	mkdir -p "${tmpdir}/tpl" "$pub_dir"

	cat >"${tmpdir}/tpl/os_with_tweaks" <<'EOF'
OSNAME="os_with_tweaks"
PRETTY="OS With Tweaks"
RELEASES="1.0"
releases_() { echo "1.0"; }
get_() { :; }
specific_tweaks() { echo "do_something_special"; }
EOF

	cat >"${tmpdir}/tpl/os_plain" <<'EOF'
OSNAME="os_plain"
PRETTY="OS Plain"
RELEASES="1.0"
releases_() { echo "1.0"; }
get_() { :; }
EOF

	(
		set +u
		_load_generate_fns
		export PUBLIC_DIR="$pub_dir"
		export TEMPLATES_DIR="${tmpdir}/tpl"
		OPERATION="generate"
		OS="os_with_tweaks"
		write_output 2>/dev/null
		OS="os_plain"
		write_output 2>/dev/null
	)

	if grep -q "specific_tweaks" "${pub_dir}/os_plain" 2>/dev/null; then
		fail "SPEC_FUNC leaked into os_plain"
	else
		pass "SPEC_FUNC does not leak between OSes"
	fi
	rm -rf "$tmpdir"
}

test_pipeline_two_os_isolation() {
	echo "[pipeline] Testing two-OS isolation: no state cross-contamination..."
	local tmpdir pub_dir
	tmpdir=$(mktemp -d)
	pub_dir="${tmpdir}/public"
	mkdir -p "${tmpdir}/tpl" "$pub_dir"

	cat >"${tmpdir}/tpl/os_a" <<'EOF'
OSNAME="os_a"
PRETTY="OS A"
RELEASES="1.0 2.0"
releases_() { echo "1.0"; echo "2.0"; }
get_() { :; }
specific_tweaks() { echo "tweaked"; }
EOF

	cat >"${tmpdir}/tpl/os_b" <<'EOF'
OSNAME="os_b"
PRETTY="OS B"
RELEASES="1.0"
releases_() { echo "1.0"; }
get_() { :; }
EOF

	(
		set +u
		_load_generate_fns
		export PUBLIC_DIR="$pub_dir"
		export TEMPLATES_DIR="${tmpdir}/tpl"
		OPERATION="generate"
		OS="os_a"; write_output 2>/dev/null
		OS="os_b"; write_output 2>/dev/null
	)

	local errors=0
	if ! grep -q "specific_tweaks" "${pub_dir}/os_a" 2>/dev/null; then
		fail "os_a missing specific_tweaks in output"
		((errors++)) || true
	fi
	if grep -q "specific_tweaks" "${pub_dir}/os_b" 2>/dev/null; then
		fail "os_b has specific_tweaks leaked from os_a"
		((errors++)) || true
	fi
	if ! grep -q 'OSNAME="os_b"' "${pub_dir}/os_b" 2>/dev/null; then
		fail "os_b output missing OSNAME"
		((errors++)) || true
	fi
	[[ $errors -eq 0 ]] && pass "pipeline: two-OS isolation correct"
	rm -rf "$tmpdir"
}

echo ""
echo "[5/6] Testing SPEC_FUNC isolation..."
test_spec_func_no_leakage || true

echo ""
echo "[6/6] Testing two-OS pipeline isolation..."
test_pipeline_two_os_isolation || true

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed, $warnings warnings"
echo "========================================="

[[ $failed -eq 0 ]]
