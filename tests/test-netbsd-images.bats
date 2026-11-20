#!/usr/bin/env bats

@test "NetBSD downloads and checksums use the published shared images tree" {
	cd "${BATS_TEST_DIRNAME}/.."
	source templates/netbsd
	web_pipe() {
		[ "$1" = 'https://cdn.netbsd.org/pub/NetBSD/images/11.1/MD5' ] || return 1
		echo 'MD5 (NetBSD-11.1-amd64.iso) = 0123456789abcdef0123456789abcdef'
	}
	RELEASE=11.1
	run get_
	[ "$status" -eq 0 ]
	[ "$output" = 'https://cdn.netbsd.org/pub/NetBSD/images/11.1/NetBSD-11.1-amd64.iso 0123456789abcdef0123456789abcdef' ]
}
