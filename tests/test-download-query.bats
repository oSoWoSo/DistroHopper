#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	TEST_DIR=$(mktemp -d)
	source lib.sh
	# Load the real VM creation function without running qget's CLI entry point.
	source <(awk '/^function create_vm\(\)/ {copy=1} /^function create_config\(\)/ {copy=0} copy' qget)
	VM_PATH="${TEST_DIR}/vm"
	DOWNLOAD_LOG="${TEST_DIR}/download"
	CONFIG_LOG="${TEST_DIR}/config"
	check_download_url() { return 0; }
	web_get() { printf '%s\n' "$@" > "${DOWNLOAD_LOG}"; }
	dh_load_os() { :; }
	make_vm_config() { printf '%s\n' "$1" > "${CONFIG_LOG}"; }
	table_write() { :; }
	unset ISO_DIR TORRENT MAGNET
}

teardown() {
	rm -rf "${TEST_DIR}"
}

@test "VM creation preserves artifact query parameters but saves a clean ISO filename" {
	URL='https://git.example.test/artifacts/main/raw/blendOS.iso?job=build-job'
	create_vm "$URL"
	mapfile -t args < "${DOWNLOAD_LOG}"
	[ "${args[0]}" = "$URL" ]
	[ "${args[1]}" = "$VM_PATH" ]
	[ "${args[2]}" = blendOS.iso ]
	[ "$(<"${CONFIG_LOG}")" = blendOS.iso ]
}

@test "Artifact ISOs still use the shared ISO directory" {
	ISO_DIR="${TEST_DIR}/shared"
	create_vm 'https://example.test/blendOS.iso?job=build-job#download'
	mapfile -t args < "${DOWNLOAD_LOG}"
	[ "${args[1]}" = "$ISO_DIR" ]
	[ "${args[2]}" = blendOS.iso ]
	[ "$(<"${CONFIG_LOG}")" = blendOS.iso ]
}

@test "Ordinary ISO URLs retain their existing filenames" {
	create_vm 'https://example.test/installer.iso'
	mapfile -t args < "${DOWNLOAD_LOG}"
	[ "${args[0]}" = 'https://example.test/installer.iso' ]
	[ "${args[2]}" = installer.iso ]
	[ "$(<"${CONFIG_LOG}")" = installer.iso ]
}
