#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	web_check() { return 0; }
	web_get() { printf '%s\n' "$1"; }
	zsync_get() { printf '%s\n' "$1"; }
	check_hash() { :; }
	make_vm_config() { :; }
	web_pipe() {
		case "$1" in
			*/series) echo '{"entries":[{"name":"nextcodename","status":"Active Development"}]}';;
			*/SHA256SUMS)
				printf '%064d *ubuntu-24.04.3-desktop-amd64.iso\n' 1
				printf '%064d *ubuntu-24.04.5.1-desktop-amd64.iso\n' 2
				printf '%064d *ubuntu-24.04.3-live-server-amd64.iso\n' 3
				printf '%064d *ubuntu-24.04.5-live-server-amd64.iso\n' 4
				printf '%064d *ubuntu-24.04.6-live-server-arm64.iso\n' 5
				printf '%064d *ubuntu-24.04.6-live-server-amd64.iso.zsync\n' 6;;
		esac
	}
}

@test "Ubuntu desktop picks the newest point ISO and matching checksum" {
	OS=ubuntu ARCH=amd64 RELEASE=24.04
	source templates/ubuntu
	run get_
	[ "$status" -eq 0 ]
	[ "$output" = 'https://releases.ubuntu.com/24.04/ubuntu-24.04.5.1-desktop-amd64.iso' ]
}

@test "Ubuntu Server selects one newest point ISO rather than concatenating records" {
	OS=ubuntu-server RELEASE=24.04
	source templates/ubuntu-server
	run get_
	[ "$status" -eq 0 ]
	[ "$output" = 'https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso' ]
}

@test "Ubuntu Server daily uses the active development codename directory" {
	OS=ubuntu-server RELEASE=daily-live
	source templates/ubuntu-server
	run get_
	[ "$status" -eq 0 ]
	[[ "$output" == https://cdimage.ubuntu.com/ubuntu-server/nextcodename/daily-live/current/*.iso ]]
}

@test "Ubuntu Server refuses an empty manifest instead of emitting a directory URL" {
	OS=ubuntu-server RELEASE=24.04
	source templates/ubuntu-server
	web_pipe() { echo '<html>unavailable</html>'; }
	run get_
	[ "$status" -ne 0 ]
	[ -z "$output" ]
}
