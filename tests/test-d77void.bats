#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	export D77_FEED="${TEST_DIR}/feed.xml"
	{
		printf '<rss><channel>\n'
		for image in \
			d77void-live-x86_64-20261113-hypr-dms.iso \
			d77void-live-x86_64-20261005-hypr-dms.iso \
			d77void-live-x86_64-20261015-niri-noctalia.iso \
			d77void-live-x86_64-20260826-fluxbox.iso \
			d77void-live-x86_64-20261113-hypr-dms.iso.sha256 \
			d77void-live-x86_64-musl-20261113-sway.iso \
			d77void-live-aarch64-20261113-sway.iso \
			d77orphaned-live-x86_64-20261109.iso; do
			printf '<item>\n<link>https://sourceforge.net/projects/d77void/files/ISO-x86_64/%s/download</link>\n' "$image"
			case "$image" in
				*fluxbox.iso) printf '<media:hash algo="md5">invalid</media:hash>\n';;
				*20261113-hypr-dms.iso) printf '<media:content><media:hash algo="md5">%032d</media:hash></media:content>\n' 1;;
				*) printf '<media:content><media:hash algo="md5">%032d</media:hash></media:content>\n' 0;;
			esac
			printf '</item>\n'
		done
		printf '</channel></rss>\n'
	} > "$D77_FEED"
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "d77void discovers only published editions from the current ISO folder" {
	run bash -c '
		web_pipe() {
			[ "$1" = "https://sourceforge.net/projects/d77void/rss?path=/ISO-x86_64" ] || return 1
			cat "$D77_FEED"
		}
		source "$1/templates/d77void"
		releases_
		arch_
		editions_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = $'latest\namd64\nfluxbox\nhypr-dms\nniri-noctalia' ]
}

@test "d77void selects the newest exact edition and its matching checksum" {
	run bash -c '
		web_pipe() { cat "$D77_FEED"; }
		source "$1/templates/d77void"
		RELEASE=latest ARCH=amd64 QEMU_ARCH=amd64 EDITION=hypr-dms
		get_
		printf "qemu_arch=%s\n" "$QEMU_ARCH"
		ARCH=x86_64 EDITION=niri-noctalia get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "https://sourceforge.net/projects/d77void/files/ISO-x86_64/d77void-live-x86_64-20261113-hypr-dms.iso/download 00000000000000000000000000000001" ]
	[ "${lines[1]}" = "qemu_arch=amd64" ]
	[ "${lines[2]}" = "https://sourceforge.net/projects/d77void/files/ISO-x86_64/d77void-live-x86_64-20261015-niri-noctalia.iso/download 00000000000000000000000000000000" ]
}

@test "d77void omits invalid checksums instead of using unrelated hashes" {
	run bash -c '
		web_pipe() { cat "$D77_FEED"; }
		source "$1/templates/d77void"
		EDITION=fluxbox get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = "https://sourceforge.net/projects/d77void/files/ISO-x86_64/d77void-live-x86_64-20260826-fluxbox.iso/download" ]
}

@test "d77void rejects unavailable editions, unsupported architectures and empty feeds" {
	run bash -c '
		web_pipe() { cat "$D77_FEED"; }
		source "$1/templates/d77void"
		if EDITION=missing get_; then exit 1; fi
		if EDITION=niri get_; then exit 1; fi
		if ARCH=arm64 EDITION=hypr-dms get_; then exit 1; fi
		if RELEASE=old EDITION=hypr-dms get_; then exit 1; fi
		web_pipe() { printf "<html>Unavailable</html>\n"; }
		[ -z "$(editions_)" ] || exit 1
		if EDITION=hypr-dms get_; then exit 1; fi
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
