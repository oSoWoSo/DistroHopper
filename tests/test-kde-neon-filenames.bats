#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	source templates/kde-neon
	web_pipe() {
		case "$1" in
			*/desktop/*/neon-*-desk-current.sha256sum) printf '%064d  neon-user-desk-20261025.iso\n' 1;;
			*/bigscreen/*/neon-*-big-current.sha256sum) printf '%064d  neon-user-big-20261025.iso\n' 2;;
			*/mobile/*/neon-*-mobile-current.sha256sum) printf '%064d  neon-user-mobile-20261025.iso\n' 3;;
			*) return 1;;
		esac
	}
}

@test "Neon desktop uses desk checksum stem without changing its directory" {
	RELEASE=user EDITION=desktop
	run get_
	[ "$status" -eq 0 ]
	[[ "$output" == 'https://files.kde.org/neon/images/desktop/user/current/neon-user-desk-20261025.iso '* ]]
}

@test "Neon bigscreen uses big checksum stem" {
	RELEASE=user EDITION=bigscreen
	run get_
	[ "$status" -eq 0 ]
	[[ "$output" == 'https://files.kde.org/neon/images/bigscreen/user/current/neon-user-big-20261025.iso '* ]]
}

@test "Neon other editions retain their checksum stems" {
	RELEASE=user EDITION=mobile
	run get_
	[ "$status" -eq 0 ]
	[[ "$output" == 'https://files.kde.org/neon/images/mobile/user/current/neon-user-mobile-20261025.iso '* ]]
}
