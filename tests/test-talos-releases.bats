#!/usr/bin/env bats

setup() {
	cd "${BATS_TEST_DIRNAME}/.."
	source templates/talos-linux
	atom_feed_iso_entries() { :; }
	web_pipe_json() {
		echo '[{"tag_name":"v1.14.6","assets":[{"name":"metal-amd64.iso"},{"name":"metal-arm64.iso"}]},{"tag_name":"v1.15.0-beta.0","assets":[{"name":"metal-amd64.iso"}]},{"tag_name":"v1.13.0","assets":[]},{"tag_name":"v2.0.0","draft":true,"assets":[{"name":"metal-amd64.iso"}]}]'
	}
}

@test "Talos falls back to official published ISO releases when the feed is empty" {
	ARCH=amd64
	run releases_
	[ "$status" -eq 0 ]
	[ "$output" = $'1.15.0-beta.0\n1.14.6' ]
}

@test "Talos fallback only advertises releases with an ISO for the selected architecture" {
	ARCH=arm64
	run releases_
	[ "$status" -eq 0 ]
	[ "$output" = 1.14.6 ]
}
