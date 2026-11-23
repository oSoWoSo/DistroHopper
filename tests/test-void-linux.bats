#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "Void i686 configs use legacy BIOS while amd64 and arm64 keep default firmware" {
	run bash -e -c '
		source "$1/lib.sh"
		source "$1/templates/void-linux"
		cd "$2"
		OS=void-linux OPERATION=create
		for ARCH in i686 amd64 arm64; do
			VM_PATH="void-${ARCH}"
			touch "${VM_PATH}.iso"
			make_vm_config "${VM_PATH}.iso"
			bash -n "${VM_PATH}.conf"
			if [ "$ARCH" = i686 ]; then
				grep -Fxq '\''arch="i686"'\'' "${VM_PATH}.conf"
				grep -Fxq '\''boot="legacy"'\'' "${VM_PATH}.conf"
			else
				! grep -q "^boot=" "${VM_PATH}.conf"
			fi
		done
	' _ "$REPO_ROOT" "$TEST_DIR"
	[ "$status" -eq 0 ]
}
