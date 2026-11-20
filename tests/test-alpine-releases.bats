#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	source templates/alpine-linux
	web_pipe() {
		case "$1" in
			*/alpine/) echo '<a href="v3.4/">v3.4/</a><a href="v3.24/">v3.24/</a><a href="v3.25/">v3.25/</a>';;
			*/v3.4/releases/x86_64/) echo 'alpine-3.4.6-x86_64.iso';;
			*/v3.24/releases/x86_64/) echo 'alpine-standard-3.24.1-x86_64.iso';;
			*/v3.24/releases/aarch64/) echo 'alpine-standard-3.24.1-aarch64.iso';;
			*.sha256) printf '%064d  image.iso\n' 1;;
			*) echo '<html>empty directory</html>';;
		esac
	}
}

@test "Alpine omits empty future branches and deduplicates releases" {
	ARCH=amd64
	run releases_
	[ "$status" -eq 0 ]
	[ "$output" = $'v3.24\nv3.4' ]
}

@test "Alpine release discovery respects architecture availability" {
	ARCH=arm64
	run releases_
	[ "$status" -eq 0 ]
	[ "$output" = v3.24 ]
}

@test "Alpine resolves legacy standard images without the standard filename infix" {
	ARCH=amd64 RELEASE=v3.4
	run get_
	[ "$status" -eq 0 ]
	[[ "$output" == 'https://dl-cdn.alpinelinux.org/alpine/v3.4/releases/x86_64/alpine-3.4.6-x86_64.iso '* ]]
}
