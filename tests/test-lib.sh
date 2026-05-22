#!/usr/bin/env bash
# Test runner for lib.sh library functions

set -euo pipefail

cd ..
echo $(pwd)
source lib.sh

echo "========================================="
echo "  Tests for lib.sh library functions"
echo "========================================="
echo ""

passed=0
failed=0

test_error_specify_os() {
	echo "[1/13] Testing error_specify_os..."
	output=$(error_specify_os 2>&1 || true)
	if echo "$output" | grep -q "specify\|OS\|qget"; then
		echo "OK: error_specify_os"
		((passed++))
	else
		echo "FAIL: error_specify_os"
		((failed++))
	fi
}

test_error_specify_release() {
	echo "[2/13] Testing error_specify_release..."
	output=$(error_specify_release ubuntu 2>&1 || true)
	if echo "$output" | grep -q "specify\|release\|ubuntu"; then
		echo "OK: error_specify_release"
		((passed++))
	else
		echo "FAIL: error_specify_release"
		((failed++))
	fi
}

test_error_not_supported_release() {
	echo "[3/13] Testing error_not_supported_release..."
	output=$(error_not_supported_release ubuntu xxx 2>&1 || true)
	if echo "$output" | grep -q "not supported\|xxx"; then
		echo "OK: error_not_supported_release"
		((passed++))
	else
		echo "FAIL: error_not_supported_release"
		((failed++))
	fi
}

test_error_not_supported_lang() {
	echo "[4/13] Testing error_not_supported_lang..."
	output=$(error_not_supported_lang xx 2>&1 || true)
	if echo "$output" | grep -q "Language\|not supported"; then
		echo "OK: error_not_supported_lang"
		((passed++))
	else
		echo "FAIL: error_not_supported_lang"
		((failed++))
	fi
}

test_error_not_supported_argument() {
	echo "[5/13] Testing error_not_supported_argument..."
	output=$(error_not_supported_argument --xyz 2>&1 || true)
	if echo "$output" | grep -q "Unknown\|argument"; then
		echo "OK: error_not_supported_argument"
		((passed++))
	else
		echo "FAIL: error_not_supported_argument"
		((failed++))
	fi
}

test_error_unable_to_create_dir() {
	echo "[6/13] Testing error_unable_to_create_dir..."
	output=$(error_unable_to_create_dir /nonexistent "Permission denied" 2>&1 || true)
	if echo "$output" | grep -q "Unable\|directory"; then
		echo "OK: error_unable_to_create_dir"
		((passed++))
	else
		echo "FAIL: error_unable_to_create_dir"
		((failed++))
	fi
}

test_error_not_supported_image() {
	echo "[7/13] Testing error_not_supported_image..."
	output=$(error_not_supported_image xyz 2>&1 || true)
	if echo "$output" | grep -q "format\|image\|supported"; then
		echo "OK: error_not_supported_image"
		((passed++))
	else
		echo "FAIL: error_not_supported_image"
		((failed++))
	fi
}

test_is_valid_language() {
	echo "[8/13] Testing is_valid_language..."
	if is_valid_language "en" && ! is_valid_language "xx"; then
		echo "OK: is_valid_language"
		((passed++))
	else
		echo "FAIL: is_valid_language"
		((failed++))
	fi
}

test_cleanup() {
	echo "[9/13] Testing cleanup..."
	local testfile="/tmp/test-lib-cleanup-$$"
	echo "test" >"$testfile"
	if cleanup "$testfile" && [[ ! -f "$testfile" ]]; then
		echo "OK: cleanup"
		((passed++))
	else
		echo "FAIL: cleanup"
		((failed++))
	fi
}

test_make_vm_config() {
	echo "[10/13] Testing make_vm_config..."
	local output
	output=$(make_vm_config "test-vm" "ubuntu" "22.04" 4096 2 "20G")
	if echo "$output" | grep -q '"name": "test-vm"'; then
		echo "OK: make_vm_config"
		((passed++))
	else
		echo "FAIL: make_vm_config"
		((failed++))
	fi
}

test_web_check() {
	echo "[11/13] Testing web_check..."
	if web_check "https://nonexistent.invalid" 2>/dev/null; then
		echo "FAIL: web_check should fail for invalid URL"
		((failed++))
	elif [[ $? -eq 22 ]]; then
		echo "OK: web_check (returned not found - expected)"
		((passed++))
	else
		echo "OK: web_check"
		((passed++))
	fi
}

test_shellcheck() {
	echo "[12/13] Running shellcheck on lib.sh..."
	if command -v shellcheck &>/dev/null; then
		if shellcheck -x lib.sh 2>&1 | grep -q "errors"; then
			echo "FAIL: shellcheck found errors"
			((failed++))
		else
			echo "OK: shellcheck"
			((passed++))
		fi
	else
		echo "SKIP: shellcheck not installed"
	fi
}

test_public_dir() {
	echo "[13/13] Testing PUBLIC_DIR..."
	if [[ -n "$PUBLIC_DIR" ]] && [[ -d "$PUBLIC_DIR" ]]; then
		echo "OK: PUBLIC_DIR=$PUBLIC_DIR"
		((passed++))
	else
		echo "FAIL: PUBLIC_DIR not set or not a directory"
		((failed++))
	fi
}

test_table_add_row() {
	echo "[14/16] Testing table_add_row..."
	table_clear
	table_add_row "ubuntu" "amd64" "24.04" "desktop" "http://test.iso" "PASS"
	if [[ "${#TABLE_ROWS[@]}" -eq 1 ]]; then
		echo "OK: table_add_row"
		((passed++))
	else
		echo "FAIL: table_add_row"
		((failed++))
	fi
}

test_table_dedup() {
	echo "[15/16] Testing table_add_row deduplication..."
	table_clear
	table_add_row "ubuntu" "amd64" "24.04" "desktop" "http://test.iso" "PASS"
	table_add_row "ubuntu" "amd64" "24.04" "desktop" "http://test.iso" "FAIL"
	if [[ "${#TABLE_ROWS[@]}" -eq 1 ]]; then
		echo "OK: table dedup"
		((passed++))
	else
		echo "FAIL: table dedup"
		((failed++))
	fi
}

test_table_write() {
	echo "[16/16] Testing table_write..."
	local testfile="/tmp/test-table-$$"
	table_clear
	table_add_row "fedora" "amd64" "40" "server" "http://fedora.iso" "PASS"
	table_write "$testfile"
	if [[ -f "$testfile" ]]; then
		if grep -q "fedora" "$testfile"; then
			echo "OK: table_write"
			((passed++))
		else
			echo "FAIL: table_write content"
			((failed++))
		fi
		rm -f "$testfile"
	else
		echo "FAIL: table_write"
		((failed++))
	fi
}

echo "Running tests..."
echo ""

test_error_specify_os || true
test_error_specify_release || true
test_error_not_supported_release || true
test_error_not_supported_lang || true
test_error_not_supported_argument || true
test_error_unable_to_create_dir || true
test_error_not_supported_image || true
test_is_valid_language || true
test_cleanup || true
test_make_vm_config || true
test_web_check || true
test_shellcheck || true
test_public_dir || true
test_table_add_row || true
test_table_dedup || true
test_table_write || true

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

[[ $failed -eq 0 ]]
