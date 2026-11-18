#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
}

@test "web_pipe preserves the existing URL-only curl defaults" {
	run bash -c '
		source "$1/lib.sh"
		curl() { printf "%s\n" "$@"; }
		web_pipe "https://example.com/file?name=two words"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = $'--disable\n--silent\n--location\nhttps://example.com/file?name=two words' ]
}

@test "web_pipe forwards optional curl arguments without splitting them" {
	run bash -c '
		source "$1/lib.sh"
		curl() { printf "%s\n" "$@"; }
		web_pipe "https://example.com/SHA256SUM" --fail --retry 3 --header "X-Test: two words"
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = $'--disable\n--silent\n--location\n--fail\n--retry\n3\n--header\nX-Test: two words\nhttps://example.com/SHA256SUM' ]
}

@test "web_pipe propagates curl failure status" {
	run bash -c '
		source "$1/lib.sh"
		curl() { return 22; }
		web_pipe "https://example.com/missing" --fail
	' _ "$REPO_ROOT"
	[ "$status" -eq 22 ]
	[ -z "$output" ]
}
