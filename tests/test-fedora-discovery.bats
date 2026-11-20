#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	source templates/fedora-linux
	_qarch_to_upstream() { echo x86_64; }
	web_pipe() {
		printf '%s\n' '[
		 {"version":"45 Beta","arch":"x86_64","variant":"KDE","subvariant":"KDE","link":"https://example.test/beta.iso","sha256":"beta"},
		 {"version":"45","arch":"x86_64","variant":"KDE","subvariant":"KDE","link":"https://example.test/kde.iso","sha256":"kde"},
		 {"version":"45","arch":"x86_64","variant":"COSMIC-Atomic","subvariant":"COSMIC-Atomic","link":"https://example.test/cosmic.ociarchive","sha256":"oci"},
		 {"version":"45","arch":"x86_64","variant":"COSMIC-Atomic","subvariant":"COSMIC-Atomic","link":"https://example.test/cosmic.iso","sha256":"cosmic"},
		 {"version":"45","arch":"x86_64","variant":"Cloud","subvariant":"Cloud","link":"https://example.test/cloud.raw","sha256":"raw"},
		 {"version":"46 Beta","arch":"x86_64","variant":"KDE","subvariant":"KDE","link":"https://example.test/next.iso","sha256":"next"}
		]'
	}
}

@test "Fedora omits superseded betas but retains upcoming betas" {
	run releases_
	[ "$status" -eq 0 ]
	[ "$output" = $'46_Beta\n45' ]
}

@test "Fedora offers only ISO editions for the selected release and architecture" {
	RELEASE=45 ARCH=amd64
	run editions_
	[ "$status" -eq 0 ]
	[ "$output" = $'COSMIC-Atomic\nKDE' ]
}

@test "Fedora resolves KDE outside Spins without mutating the release" {
	RELEASE=45 EDITION=KDE ARCH=amd64
	[ "$(get_)" = 'https://example.test/kde.iso kde' ]
	RELEASE=46_Beta
	[ "$(get_)" = 'https://example.test/next.iso next' ]
	[ "$RELEASE" = 46_Beta ]
}

@test "Fedora selects Atomic installer ISO instead of OCI archive" {
	RELEASE=45 EDITION=COSMIC-Atomic ARCH=amd64
	run get_
	[ "$status" -eq 0 ]
	[ "$output" = 'https://example.test/cosmic.iso cosmic' ]
}
