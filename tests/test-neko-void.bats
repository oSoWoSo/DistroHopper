#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	export NEKO_PAGE="${TEST_DIR}/downloads.html"
	{
		# The featured image is repeated in the editions list with its hash.
		printf '<a href="https://huggingface.co/example/resolve/main/nekovoid-mate-20261016.iso">Featured</a>\n'
		printf '<a href="https://huggingface.co/example/resolve/main/nekovoid-mate-20261016.iso">MATE</a>\n'
		printf '<span>SHA256: %064d</span>\n' 0
		printf '<a href="https://huggingface.co/example/resolve/main/nekovoid-matelibre-20261016.iso">XLibre</a>\n'
		printf '<span>SHA256: Generando</span>\n'
		printf '<a href="https://huggingface.co/buckets/example/resolve/nekovoid-lts-icewm-20260921.iso">IceWM</a>\n'
		printf '<span>SHA256: invalid</span>\n'
		printf '<a href="https://huggingface.co/buckets/example/resolve/nekovoid-labwc-20261011.iso?download=true&amp;test=1">Labwc</a>\n'
		printf '<span>SHA256: %064d</span>\n' 1
		printf '<a href="https://drive.google.com/file/d/example/view">NVIDIA</a>\n'
	} > "${NEKO_PAGE}"
}

teardown() {
	rm -rf "${TEST_DIR}"
}

@test "Neko-Void discovers rolling editions from the official website" {
	run bash -c '
		web_pipe() { cat "$NEKO_PAGE"; }
		source "$1/templates/neko-void"
		releases_
		editions_
	' _ "${REPO_ROOT}"
	[ "$status" -eq 0 ]
	[ "$output" = $'latest\nlabwc\nlts-icewm\nmate\nmatelibre' ]
}

@test "Neko-Void resolves the published URL and matching SHA256" {
	run bash -c '
		web_pipe() { cat "$NEKO_PAGE"; }
		source "$1/templates/neko-void"
		RELEASE=latest EDITION=mate get_
		EDITION=labwc get_
	' _ "${REPO_ROOT}"
	[ "$status" -eq 0 ]
	[[ "${lines[0]}" == "https://huggingface.co/example/resolve/main/nekovoid-mate-20261016.iso "* ]]
	[[ "${lines[0]##* }" =~ ^[[:xdigit:]]{64}$ ]]
	[[ "${lines[1]}" == "https://huggingface.co/buckets/example/resolve/nekovoid-labwc-20261011.iso?download=true&test=1 "* ]]
	[[ "${lines[1]##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "Neko-Void omits invalid or unavailable checksums" {
	run bash -c '
		web_pipe() { cat "$NEKO_PAGE"; }
		source "$1/templates/neko-void"
		EDITION=matelibre get_
		EDITION=lts-icewm get_
	' _ "${REPO_ROOT}"
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "https://huggingface.co/example/resolve/main/nekovoid-matelibre-20261016.iso" ]
	[ "${lines[1]}" = "https://huggingface.co/buckets/example/resolve/nekovoid-lts-icewm-20260921.iso" ]
}

@test "Neko-Void rejects obsolete releases, missing editions, and unavailable pages" {
	run bash -c '
		web_pipe() { cat "$NEKO_PAGE"; }
		source "$1/templates/neko-void"
		if RELEASE=6.3 EDITION=xorg get_; then exit 1; fi
		if RELEASE=latest EDITION=missing get_; then exit 1; fi
		web_pipe() { printf "<html>Unavailable</html>\n"; }
		[ -z "$(editions_)" ] || exit 1
		if EDITION=mate get_; then exit 1; fi
	' _ "${REPO_ROOT}"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
