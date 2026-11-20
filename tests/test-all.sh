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
	echo "[1/3] Checking required files..."

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
	echo "[2/3] Testing qget --help..."

	local help_output
	help_output=$(./qget --help 2>&1)
	if [[ "$help_output" == *"Usage:"* ]]; then
		echo "OK: qget --help works"
	else
		echo "ERROR: qget --help failed"
		return 1
	fi
}

# Test shellcheck if available
test_shellcheck() {
	echo "[3/3] Running shellcheck..."

	if command -v shellcheck &>/dev/null; then
		if shellcheck -S error qget generate dh; then
			echo "OK: shellcheck passed"
		else
			echo "ERROR: shellcheck found issues"
			return 1
		fi
	else
		echo "SKIP: shellcheck not installed"
	fi
}

# Run all tests
echo "Running tests..."
echo ""

check_files
test_help
test_shellcheck

echo ""
echo "Running new test suite..."
echo ""

TESTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
if command -v bats >/dev/null 2>&1; then
	echo "[NEW] Testing Bats behavior suites..."
	bats "${TESTS_DIR}"/*.bats
else
	echo "[NEW] Skipping Bats behavior tests (bats not installed)"
fi

echo "[NEW] Testing templates..."
bash "${TESTS_DIR}/test-templates.sh"

echo "[NEW] Testing public..."
bash "${TESTS_DIR}/test-public.sh"

echo "[NEW] Testing qget formats..."
bash "${TESTS_DIR}/test-qget-csv.sh"

echo "[NEW] Testing library behavior..."
bash "${TESTS_DIR}/test-lib.sh"

echo "[NEW] Testing generate behavior..."
bash "${TESTS_DIR}/test-generate.sh"
echo "[NEW] Testing cleanup (warnings only)..."
bash "${TESTS_DIR}/test-cleanup.sh"

echo "[NEW] Testing dh..."
bash "${TESTS_DIR}/test-dh.sh"

echo ""
echo "========================================="
echo "  All tests completed!"
echo "========================================="
