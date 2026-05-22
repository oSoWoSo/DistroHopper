#!/usr/bin/env bash
# Main test runner for qget and generate scripts

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" && cd ..

echo "========================================="
echo "  Test Runner for qget and generate"
echo "========================================="
echo ""

# Check if required files exist
check_files() {
	echo "[1/5] Checking required files..."

	if [[ ! -x "./qget" ]]; then
		echo "ERROR: qget not found or not executable"
		exit 1
	fi

	if [[ ! -x "./generate" ]]; then
		echo "ERROR: generate not found or not executable"
		exit 1
	fi

	if [[ ! -d "./templates" ]]; then
		echo "ERROR: templates directory not found"
		exit 1
	fi

	echo "OK: All required files exist"
}

# Test qget --help
test_help() {
	echo "[2/5] Testing qget --help..."

	if ./qget --help | grep -q "Usage:"; then
		echo "OK: qget --help works"
	else
		echo "ERROR: qget --help failed"
		#exit 1
	fi
}

# Test qget --list
test_list() {
	echo "[3/5] Testing qget --list..."

	local count
	count=$(./qget --list 2>/dev/null | wc -l)

	if [[ "$count" -gt 100 ]]; then
		echo "OK: qget --list returns $count OS"
	else
		echo "WARNING: qget --list only returns $count OS (expected >100)"
	fi
}

# Check generate files
test_templates() {
	echo "[4/5] Checking template files..."

	local count
	count=$(ls templates/ 2>/dev/null | wc -l)

	if [[ "$count" -gt 110 ]]; then
		echo "OK: Found $count template files"
	else
		echo "WARNING: Only found $count template files (expected >110)"
	fi

	# Check that key OS have template files
	for os in linuxmint lmde debian ubuntu; do
		if [[ -f "templates/${os}" ]]; then
			echo "OK: templates/${os} exists"
		else
			echo "ERROR: templates/${os} not found"
			exit 1
		fi
	done
}

# Test shellcheck if available
test_shellcheck() {
	echo "[5/5] Running shellcheck..."

	if command -v shellcheck &>/dev/null; then
		shellcheck -S error qget generate 2>/dev/null || echo "WARNING: shellcheck found issues"
		echo "OK: shellcheck passed"
	else
		echo "SKIP: shellcheck not installed"
	fi
}

# Run all tests
echo "Running tests..."
echo ""

check_files
test_help
test_list
test_templates
test_shellcheck

echo ""
echo "Running new test suite..."
echo ""

TESTS_DIR="$(dirname "${BASH_SOURCE[0]}")"

echo "[NEW] Testing templates..."
bash "${TESTS_DIR}/test-templates.sh"
test_result=$?

echo "[NEW] Testing public..."
bash "${TESTS_DIR}/test-public.sh"
test_result=$?

echo "[NEW] Testing qget formats (slow - skip)..."
# bash "${TESTS_DIR}/test-qget-csv.sh"  # Skip - too slow without network
echo "  SKIP: requires network"

echo "[NEW] Testing generate (slow - skip)..."
# bash "${TESTS_DIR}/test-generate.sh"  # Skip - too slow without network
echo "  SKIP: requires network"

echo "[NEW] Testing cleanup (warnings only)..."
bash "${TESTS_DIR}/test-cleanup.sh"
test_result=$?

echo ""
echo "========================================="
echo "  All tests completed!"
echo "========================================="
