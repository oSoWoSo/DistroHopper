#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	source templates/solus
	releases_() { printf '%s\n' 2025-01-26 2026-01-01; }
	web_pipe_json() {
		case "$1" in
			*/2025-01-26/) echo '[{"name":"Solus-XFCE-Beta-Release-2025-01-26.iso"},{"name":"Solus-XFCE-Beta-Release-2025-01-26.iso.sha256sum"}]';;
			*/2026-01-01/) echo '[{"name":"Solus-Xfce-Release-2026-01-01.iso"}]';;
			*) return 1;;
		esac
	}
}

@test "Solus editions come from the selected release, not the newest release" {
	RELEASE=2025-01-26
	run editions_
	[ "$status" -eq 0 ]
	[ "$output" = XFCE-Beta ]
}

@test "Solus defaults to the newest release only when no release was selected" {
	unset RELEASE
	run editions_
	[ "$status" -eq 0 ]
	[ "$output" = Xfce ]
}
