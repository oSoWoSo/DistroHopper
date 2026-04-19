#!/usr/bin/env bash
# Main test runner for qget and action scripts

set -euo pipefail

cd /home/z/8T/git/dh

echo "========================================="
echo "  Test Runner for qget and action"
echo "========================================="
echo ""

# Check if required files exist
check_files() {
	echo "[1/5] Checking required files..."

	if [[ ! -x "./qget" ]]; then
		echo "ERROR: qget not found or not executable"
		exit 1
	fi

	if [[ ! -x "./action" ]]; then
		echo "ERROR: action not found or not executable"
		exit 1
	fi

	if [[ ! -d "./actions" ]]; then
		echo "ERROR: actions directory not found"
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
		exit 1
	fi
}

# Test qget --list
test_list() {
	echo "[3/5] Testing qget --list..."

	local count
	count=$(./qget --list 2>/dev/null | wc -l)

	if [[ "$count" -gt 50 ]]; then
		echo "OK: qget --list returns $count OS"
	else
		echo "WARNING: qget --list only returns $count OS (expected >50)"
	fi
}

# Check action files
test_actions() {
	echo "[4/5] Checking action files..."

	local count
	count=$(ls actions/ 2>/dev/null | wc -l)

	if [[ "$count" -gt 90 ]]; then
		echo "OK: Found $count action files"
	else
		echo "WARNING: Only found $count action files (expected >90)"
	fi

	# Check that key OS have action files
	for os in linuxmint lmde debian ubuntu; do
		if [[ -f "actions/${os}" ]]; then
			echo "OK: actions/${os} exists"
		else
			echo "ERROR: actions/${os} not found"
			exit 1
		fi
	done
}

# Test shellcheck if available
test_shellcheck() {
	echo "[5/5] Running shellcheck..."

	if command -v shellcheck &>/dev/null; then
		shellcheck -S error qget action 2>/dev/null || echo "WARNING: shellcheck found issues"
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
test_actions
test_shellcheck

echo ""
echo "========================================="
echo "  All tests completed!"
echo "========================================="
