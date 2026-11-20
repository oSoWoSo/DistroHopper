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
		source "$1/lib.sh"
		curl() { cat "$REDOX_SUMS"; }
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
		source "$1/lib.sh"
		curl() {
			local url="${@: -1}"
			local upstream="${url%/SHA256SUM}"
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
		source "$1/lib.sh"
		curl() { cat "$REDOX_SUMS"; }
		source "$1/templates/redox-os"
		ARCH=amd64 RELEASE=livedisk EDITION=server
		if get_; then exit 1; fi
		if ARCH=i686 get_; then exit 1; fi
		if EDITION=missing get_; then exit 1; fi
		if RELEASE=missing get_; then exit 1; fi
		curl() { printf "<html>404 Not Found</html>\n"; }
		if EDITION=desktop get_; then exit 1; fi
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[[ "$output" == *'no matching image'* ]]
	[[ "$output" == *'<html>404 Not Found</html>'* ]]
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

@test "Redox reports manifest fetch failures and enables HTTP retries" {
	run bash -c '
		source "$1/lib.sh"
		curl() {
			[[ " $* " == *" --fail "* ]] || exit 2
			[[ " $* " == *" --retry 3 "* ]] || exit 2
			[[ " $* " == *" --retry-all-errors "* ]] || exit 2
			return 22
		}
		source "$1/templates/redox-os"
		RELEASE=livedisk EDITION=desktop get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 1 ]
	[[ "$output" == *'ERROR: Redox could not fetch https://static.redox-os.org/img/x86_64/SHA256SUM'* ]]
}

@test "Redox identifies HTTP 200 Cloudflare challenges as blocked access, not missing images" {
	run bash -c '
		source "$1/lib.sh"
		curl() { echo "<!DOCTYPE html><title>Just a moment...</title>"; }
		source "$1/templates/redox-os"
		ARCH=amd64 RELEASE=livedisk EDITION=desktop get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Cloudflare browser challenge"* ]]
	[[ "$output" == *"no image checksum can be verified"* ]]
	[[ "$output" != *"no matching image"* ]]
}

@test "Redox generated metadata passes the actual qget check path" {
	mkdir -p "$TEST_DIR/bin" "$TEST_DIR/public"
	cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
case "$url" in
	*/SHA256SUM)
		# Generation must retain the template HTTP options, not just the URL.
		[[ " $* " == *" --fail "* && " $* " == *" --retry-all-errors "* ]] || exit 2
		arch="${url%/SHA256SUM}"
		arch="${arch##*/}"
		for edition in demo desktop server; do
			printf '%064d *redox_%s_%s_2026-11-18_588_livedisk.iso.zst\n' 0 "$edition" "$arch"
			printf '%064d *redox_%s_%s_2026-11-18_588_harddrive.img.zst\n' 0 "$edition" "$arch"
		done
		;;
	*.iso.zst|*.img.zst) exit 0 ;;
	*) exit 22 ;;
esac
EOF
	chmod +x "$TEST_DIR/bin/curl"
	run env PATH="$TEST_DIR/bin:$PATH" PUBLIC_DIR="$TEST_DIR/public" \
		"$REPO_ROOT/generate" redox-os
	[ "$status" -eq 0 ]
	run env PATH="$TEST_DIR/bin:$PATH" PUBLIC_DIR="$TEST_DIR/public" \
		"$REPO_ROOT/qget" --arch amd64 --check redox-os
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^PASS:')" -eq 6 ]
	[[ "$output" != *'FAIL:'* ]]
}
