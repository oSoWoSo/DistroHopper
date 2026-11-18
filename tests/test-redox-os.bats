#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	export REDOX_SUMS="${TEST_DIR}/SHA256SUM"
	{
		printf '%064d *redox_desktop_x86_64_2026-11-18_100_livedisk.iso.zst\n' 1
		printf '%064d  redox_desktop_x86_64_2026-11-18_99_livedisk.iso.zst\n' 2
		printf '%064d *redox_desktop_x86_64_2026-11-17_588_livedisk.iso.zst\n' 3
		printf '%064d  redox_desktop_x86_64_2026-11-18_100_harddrive.img.zst\n' 4
		printf '%064d *redox_demo_x86_64_2026-11-18_100_livedisk.iso.zst\n' 5
		printf '%064d *redox_desktop_aarch64_2026-11-18_100_livedisk.iso.zst\n' 6
		printf 'invalid *redox_desktop_x86_64_2026-11-19_100_livedisk.iso.zst\n'
		printf '%064d *../redox_desktop_x86_64_2026-11-19_100_livedisk.iso.zst\n' 7
	} > "$REDOX_SUMS"
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "Redox selects the newest exact image from binary and text checksum records" {
	run bash -c '
		web_pipe() { cat "$REDOX_SUMS"; }
		source "$1/templates/redox-os"
		ARCH=amd64 EDITION=desktop RELEASE=livedisk get_
		ARCH=amd64 EDITION=desktop RELEASE=harddrive get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "https://static.redox-os.org/img/x86_64/redox_desktop_x86_64_2026-11-18_100_livedisk.iso.zst $(printf '%064d' 1)" ]
	[ "${lines[1]}" = "https://static.redox-os.org/img/x86_64/redox_desktop_x86_64_2026-11-18_100_harddrive.img.zst $(printf '%064d' 4)" ]
}

@test "Redox maps every advertised architecture to the upstream manifest" {
	run bash -c '
		web_pipe() {
			local upstream="${1%/SHA256SUM}"
			upstream="${upstream##*/}"
			printf "%064d *redox_demo_%s_2026-11-18_588_livedisk.iso.zst\n" 0 "$upstream"
		}
		source "$1/templates/redox-os"
		for ARCH in $(arch_); do
			RELEASE=livedisk EDITION=demo get_ || exit 1
		done
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 4 ]
	[[ "${lines[0]}" == https://static.redox-os.org/img/x86_64/* ]]
	[[ "${lines[1]}" == https://static.redox-os.org/img/aarch64/* ]]
	[[ "${lines[2]}" == https://static.redox-os.org/img/i586/* ]]
	[[ "${lines[3]}" == https://static.redox-os.org/img/riscv64gc/* ]]
}

@test "Redox rejects unavailable images, invalid options and error pages" {
	run bash -c '
		web_pipe() { cat "$REDOX_SUMS"; }
		source "$1/templates/redox-os"
		ARCH=amd64 RELEASE=livedisk EDITION=server
		if get_; then exit 1; fi
		if ARCH=i686 get_; then exit 1; fi
		if EDITION=missing get_; then exit 1; fi
		if RELEASE=missing get_; then exit 1; fi
		web_pipe() { printf "<html>404 Not Found</html>\n"; }
		if EDITION=desktop get_; then exit 1; fi
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Redox livedisk extraction preserves the ISO boot medium" {
	run bash -c '
		source "$1/templates/redox-os"
		zstd() { return 0; }
		qemu-img() { echo "Unexpected conversion"; return 1; }
		ISO=redox_livedisk.iso.zst VM_PATH="$2"
		extract_ || exit 1
		[ "$ISO" = redox_livedisk.iso ]
	' _ "$REPO_ROOT" "$TEST_DIR"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Redox harddrive extraction boots the converted qcow2 disk without an ISO" {
	run bash -c '
		source "$1/templates/redox-os"
		zstd() { return 0; }
		qemu-img() {
			[ "$*" = "convert -f raw -O qcow2 $VM_PATH/redox_harddrive.img $VM_PATH/disk.qcow2" ]
		}
		ISO=redox_harddrive.img.zst VM_PATH="$2"
		extract_ || exit 1
		[ "$ISO" = disk.qcow2 ] && [ "$IMAGE_TYPE" = none ]
	' _ "$REPO_ROOT" "$TEST_DIR"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Redox extraction propagates decompression and conversion failures" {
	run bash -c '
		source "$1/templates/redox-os"
		VM_PATH="$2" ISO=redox_harddrive.img.zst
		zstd() { return 1; }
		if extract_; then exit 1; fi
		[ "$ISO" = redox_harddrive.img.zst ] || exit 1
		zstd() { return 0; }
		qemu-img() { return 1; }
		if extract_; then exit 1; fi
		[ "$ISO" = redox_harddrive.img ] || exit 1
		[ "${IMAGE_TYPE:-}" != none ]
	' _ "$REPO_ROOT" "$TEST_DIR"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
