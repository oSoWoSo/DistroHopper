#!/usr/bin/env bash
# Test runner for lib.sh library functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_DIR"
source lib.sh

echo "========================================="
echo "  Tests for lib.sh library functions"
echo "========================================="
echo ""

passed=0
failed=0

test_is_valid_language() {
	echo "[1/10] Testing is_valid_language..."
	if is_valid_language "en" && ! is_valid_language "xx"; then
		echo "OK: is_valid_language"
		((passed++))
	else
		echo "FAIL: is_valid_language"
		((failed++))
	fi
}

test_cleanup() {
	echo "[2/10] Testing cleanup..."
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
	echo "[3/10] Testing make_vm_config..."
	# make_vm_config IMAGE_FILE [ISO_FILE] writes the quickemu .conf next to
	# the VM directory and points it at the image.
	local tmpdir conf
	tmpdir="$(mktemp -d)"
	conf="${tmpdir}/test-vm.conf"
	(
		cd "${tmpdir}" || exit 1
		VM_PATH="test-vm"
		OS="linux"
		GUEST="linux"
		IMAGE_TYPE="iso"
		make_vm_config "test-vm.iso" >/dev/null 2>&1
	)
	if [ -f "${conf}" ] &&
		grep -q '^guest_os="linux"$' "${conf}" &&
		grep -q 'test-vm.iso' "${conf}"; then
		echo "OK: make_vm_config"
		((passed++))
	else
		echo "FAIL: make_vm_config (no usable .conf written to ${conf})"
		((failed++))
	fi
	rm -rf "${tmpdir}"
}

test_shellcheck() {
	echo "[4/10] Running shellcheck on lib.sh..."
	if command -v shellcheck &>/dev/null; then
		if shellcheck -S error -x lib.sh; then
			echo "OK: shellcheck"
			((passed++))
		else
			echo "FAIL: shellcheck found errors"
			((failed++))
		fi
	else
		echo "SKIP: shellcheck not installed"
	fi
}

test_table_add_row() {
	echo "[5/10] Testing table_add_row..."
	table_add_row "ubuntu" "amd64" "24.04" "desktop" "http://test.iso" "PASS"
	if [[ "${#TABLE_ROWS[@]}" -eq 1 && "${TABLE_ROWS[0]}" == *"ubuntu"* && "${TABLE_ROWS[0]}" == *"24.04"* ]]; then
		echo "OK: table_add_row"
		((passed++))
	else
		echo "FAIL: table_add_row"
		((failed++))
	fi
}

test_table_dedup() {
	echo "[6/10] Testing table_add_row deduplication..."
	table_add_row "ubuntu" "amd64" "24.04" "desktop" "http://test.iso" "PASS"
	table_add_row "ubuntu" "amd64" "24.04" "desktop" "http://test.iso" "FAIL"
	if [[ "${#TABLE_ROWS[@]}" -eq 1 && "${TABLE_ROWS[0]}" == *"FAIL"* ]]; then
		echo "OK: table dedup"
		((passed++))
	else
		echo "FAIL: table dedup"
		((failed++))
	fi
}

test_table_write() {
	echo "[7/10] Testing table_write..."
	local testfile="/tmp/test-table-$$"
	table_clear
	table_add_row "fedora-linux" "amd64" "40" "server" "http://fedora.iso" "PASS"
	table_write "$testfile"
	if [[ -f "$testfile" ]] && grep -q "fedora-linux" "$testfile"; then
		echo "OK: table_write"
		((passed++))
	else
		echo "FAIL: table_write"
		((failed++))
	fi
	rm -f "$testfile"
}

test_qarch_mapping() {
	echo "[8/10] Testing architecture mapping..."
	if [[ "$(_upstream_to_qarch x86_64)" == "amd64" ]] &&
		[[ "$(_upstream_to_qarch aarch64)" == "arm64" ]] &&
		[[ "$(_upstream_to_qarch ppc64le)" == "ppc64el" ]] &&
		[[ "$(_qarch_to_upstream amd64)" == "x86_64" ]] &&
		[[ "$(_qarch_to_upstream arm64)" == "aarch64" ]]; then
		echo "OK: qarch mapping"
		((passed++))
	else
		echo "FAIL: qarch mapping"
		((failed++))
	fi
}

test_arch_suffix() {
	echo "[9/10] Testing arch_suffix..."
	host_arch="$(_host_arch)"
	if [[ "$host_arch" == "amd64" ]]; then
		foreign_arch="arm64"
	else
		foreign_arch="amd64"
	fi
	native_suffix=$(ARCH="${host_arch}" arch_suffix)
	foreign_suffix=$(ARCH="${foreign_arch}" arch_suffix)
	if [[ -z "$native_suffix" && "$foreign_suffix" == "-${foreign_arch}" ]]; then
		echo "OK: arch_suffix distinguishes native and foreign architectures"
		((passed++))
	else
		echo "FAIL: arch_suffix (native='$native_suffix', foreign='$foreign_suffix')"
		((failed++))
	fi
}

test_make_vm_config_arch_line() {
	echo "[10/10] Testing make_vm_config arch= line..."
	testdir="$(mktemp -d)"
	host_arch="$(_host_arch)"
	if [[ "$host_arch" == "amd64" ]]; then
		foreign_arch="arm64"
	else
		foreign_arch="amd64"
	fi
	upstream_arch="$(_qarch_to_upstream "${foreign_arch}")"

	if (
		cd "$testdir" || exit 1
		export QUICKEMU=quickemu
		export VM_PATH="archtest-25.10"
		export ARCH="${foreign_arch}"
		export OPERATION=""
		export OS="archtest"
		export PRETTY="Archtest"
		export GUEST=""
		export IMAGE_TYPE=""
		make_vm_config "archtest.iso" "" >/dev/null 2>&1 || exit 1
		grep -Fqx "arch=\"${upstream_arch}\"" "${VM_PATH}.conf" || exit 1
		rm -f "${VM_PATH}.conf"
		export ARCH="${host_arch}"
		export GUEST=""
		export IMAGE_TYPE=""
		make_vm_config "archtest.iso" "" >/dev/null 2>&1 || exit 1
		! grep -q '^arch=' "${VM_PATH}.conf"
	); then
		echo "OK: make_vm_config writes foreign arch and omits native arch"
		((passed++)) || true
	else
		echo "FAIL: make_vm_config arch line behavior"
		((failed++)) || true
	fi
	rm -rf "$testdir"
}

test_qarch_mapping() {
	echo "Testing _upstream_to_qarch / _qarch_to_upstream roundtrip..."
	if [[ "$(_upstream_to_qarch x86_64)" == "amd64" ]] && [[ "$(_upstream_to_qarch aarch64)" == "arm64" ]] && [[ "$(_upstream_to_qarch ppc64le)" == "ppc64el" ]] && [[ "$(_qarch_to_upstream amd64)" == "x86_64" ]] && [[ "$(_qarch_to_upstream arm64)" == "aarch64" ]]; then
		echo "OK: qarch mapping"
		((passed++))
	else
		echo "FAIL: qarch mapping"
		((failed++))
	fi
}

test_arch_suffix() {
	echo "Testing arch_suffix..."
	local host_arch
	host_arch="$(_host_arch)"
	local suffix
	suffix=$(ARCH="${host_arch}" arch_suffix)
	if [[ -z "$suffix" ]]; then
		local foreign
		foreign=$(ARCH=arm64 arch_suffix)
		if [[ "$foreign" == "-arm64" ]]; then
			echo "OK: arch_suffix (native empty, foreign -ARCH)"
			((passed++))
		else
			echo "FAIL: arch_suffix foreign (got '$foreign')"
			((failed++))
		fi
	else
		echo "FAIL: arch_suffix native (got '$suffix')"
		((failed++))
	fi
}

test_make_vm_config_arch_line() {
	echo "Testing make_vm_config arch= line..."
	local testdir
	testdir=$(mktemp -d)
	(
		cd "$testdir" || exit 1
		export QUICKEMU=quickemu
		export VM_PATH="archtest-25.10"
		export ARCH=arm64
		export OPERATION=""
		export OS="archtest"
		export PRETTY="Archtest"
		export GUEST=""
		export IMAGE_TYPE=""
		make_vm_config "archtest.iso" "" >/dev/null 2>&1
		if grep -q '^arch="aarch64"$' "${VM_PATH}.conf"; then
			echo "OK: make_vm_config writes arch=aarch64 for ARCH=arm64"
			((passed++))
		else
			echo "FAIL: no arch line in conf"
			((failed++))
		fi
		export ARCH=amd64
		rm -f "${VM_PATH}.conf"
		make_vm_config "archtest.iso" "" >/dev/null 2>&1
		if grep -cq '^arch=' "${VM_PATH}.conf"; then
			echo "FAIL: arch line present for ARCH=amd64"
			((failed++))
		else
			echo "OK: no arch line for ARCH=amd64"
			((passed++))
		fi
	)
	rm -rf "$testdir"
}

echo "Running tests..."
echo ""

test_is_valid_language || true
test_cleanup || true
test_make_vm_config || true
test_shellcheck || true
test_table_add_row || true
test_table_dedup || true
test_table_write || true
test_qarch_mapping || true
test_arch_suffix || true
test_make_vm_config_arch_line || true

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

[[ $failed -eq 0 ]]
