#!/usr/bin/env bash
# Test suite for generate script
# Validates generate --help, basic operations, and write_output unit tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

passed=0
failed=0

pass() {
	echo -e "${GREEN}✓${NC} $1"
	((passed++)) || true
}
fail() {
	echo -e "${RED}✗${NC} $1"
	((failed++)) || true
}

echo "========================================="
echo "  Testing generate script"
echo "========================================="
echo ""

# Test --help
echo "[1/3] Testing generate --help..."
help_output=$(./generate --help 2>&1)
if [[ "$help_output" == *"Usage:"* ]]; then
	pass "generate --help works"
else
	fail "generate --help failed"
fi

# Test --version
echo "[2/3] Testing generate --version..."
version=$(./generate --version 2>&1)
if [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
	pass "generate --version: $version"
else
	fail "generate --version did not return a version: $version"
fi

# Source generate functions without executing main.
_load_generate_fns() {
	source "${PROJECT_DIR}/lib.sh"
	export _DH_SKIP_MAIN=1
	source "${PROJECT_DIR}/generate"
}

# Create a mock tmp_<OS>.dat for write_output to consume.
_mock_dat() {
	local pub_dir="$1" os="$2"
	mkdir -p "$pub_dir"
	printf 'amd64\t1.0\t-\thttps://example.com/%s-1.0.iso\tOK\n' "$os" >"${pub_dir}/tmp_${os}.dat"
}

test_generated_functions_are_isolated() {
	echo "[3/3] Testing generated function behavior..."
	local tmpdir pub_dir
	tmpdir="$(mktemp -d)"
	pub_dir="${tmpdir}/public"
	mkdir -p "${tmpdir}/tpl" "$pub_dir"

	cat >"${tmpdir}/tpl/os_with_tweaks" <<'EOF'
OSNAME="os_with_tweaks"
PRETTY="OS With Tweaks"
RELEASES="1.0"
function releases_() {
	echo "1.0"
}
function get_() {
	specific_tweaks
}
function specific_tweaks() {
	echo "do_something_special"
}
EOF

	cat >"${tmpdir}/tpl/os_plain" <<'EOF'
OSNAME="os_plain"
PRETTY="OS Plain"
RELEASES="1.0"
function releases_() {
	echo "1.0"
}
function get_() {
	echo "plain"
}
EOF

	if ! (
		set +u
		_load_generate_fns
		PUBLIC_DIR="$pub_dir"
		TEMPLATES_DIR="${tmpdir}/tpl"
		OPERATION="generate"

		_mock_dat "$pub_dir" "os_with_tweaks"
		OS="os_with_tweaks"
		write_output >/dev/null || exit $?

		_mock_dat "$pub_dir" "os_plain"
		OS="os_plain"
		write_output >/dev/null || exit $?
	); then
		fail "write_output failed for the isolation fixtures"
		rm -rf "$tmpdir"
		return
	fi

	local special_output plain_output plain_helper
	special_output=$(bash -c '. "$1"; get_' _ "${pub_dir}/os_with_tweaks" 2>/dev/null) || special_output=""
	plain_output=$(bash -c '. "$1"; get_' _ "${pub_dir}/os_plain" 2>/dev/null) || plain_output=""
	plain_helper=$(bash -c '. "$1"; if declare -F specific_tweaks >/dev/null; then echo present; else echo absent; fi' _ "${pub_dir}/os_plain" 2>/dev/null)

	if [[ "$special_output" == "do_something_special" && "$plain_output" == "plain" && "$plain_helper" == "absent" ]]; then
		pass "generated functions execute correctly without cross-OS leakage"
	else
		fail "generated functions leaked or did not preserve behavior (special=$special_output, plain=$plain_output, helper=$plain_helper)"
	fi

	# Sanity: os_with_tweaks should contain specific_tweaks
	if grep -q "specific_tweaks" "${pub_dir}/os_with_tweaks" 2>/dev/null; then
		:
	else
		warn "os_with_tweaks output missing specific_tweaks (maybe write_output changed)"
	fi

	rm -rf "$tmpdir"
}

test_generated_functions_are_isolated

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

[[ $failed -eq 0 ]]
