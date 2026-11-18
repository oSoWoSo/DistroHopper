#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	export SLAX_FIXTURES="$TEST_DIR"
	cat > "$TEST_DIR/root" <<'EOF'
<a href="Slax-12.x/">Debian</a>
<a href="Slax-15.x/">Slackware</a>
<a href="Slax-2026/">Current</a>
<a href="Slax-Debian-12.x/">Alias</a>
<a href="Slax-old/">Archive</a>
EOF
	cat > "$TEST_DIR/Slax-12.x" <<'EOF'
<a href="slax-32bit-debian-12.2.0.iso">32-bit</a>
<a href="slax-64bit-debian-12.2.0.iso">64-bit</a>
EOF
	cat > "$TEST_DIR/Slax-15.x" <<'EOF'
<a href="slax-64bit-slackware-15.0.4.iso">Newest</a>
<a href="slax-64bit-15.0.1.iso">Older</a>
EOF
	cat > "$TEST_DIR/Slax-2026" <<'EOF'
<a href="slax-2026.11-64bit-10.iso">Newest build</a>
<a href="slax-2026.11-64bit-9.iso">Older build</a>
<a href="slax-2026.11-64bit-10.iso.sha256sum.txt">Checksum, not ISO</a>
EOF
	printf '%032d  slax-64bit-debian-12.2.0.iso\n' 2 > "$TEST_DIR/md5-12"
	{
		printf '%032d *slax-64bit-slackware-15.0.4.iso\n' 1
		printf '%032d  slax-64bit-15.0.1.iso\n' 0
	} > "$TEST_DIR/md5-15"
	# Current upstream SHA256 files use CRLF line endings.
	printf '%064d  slax-2026.11-64bit-10.iso\r\n' 3 > "$TEST_DIR/sha256"
	cat > "$TEST_DIR/mock.sh" <<'EOF'
web_pipe() {
	case "$1" in
		*/slax/) cat "$SLAX_FIXTURES/root" ;;
		*/Slax-12.x/) cat "$SLAX_FIXTURES/Slax-12.x" ;;
		*/Slax-15.x/) cat "$SLAX_FIXTURES/Slax-15.x" ;;
		*/Slax-2026/) cat "$SLAX_FIXTURES/Slax-2026" ;;
		*/Slax-2027/) cat "$SLAX_FIXTURES/Slax-2027" ;;
		*/Slax-12.x/md5.txt) cat "$SLAX_FIXTURES/md5-12" ;;
		*/Slax-15.x/md5.txt) cat "$SLAX_FIXTURES/md5-15" ;;
		*.iso.sha256sum.txt) cat "$SLAX_FIXTURES/sha256" ;;
		*) return 1 ;;
	esac
}
EOF
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "Slax discovers numeric releases from both filename generations" {
	run bash -c '
		source "$SLAX_FIXTURES/mock.sh"
		source "$1/templates/slax"
		releases_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = $'latest\n2026.11\n15.0.4\n15.0.1\n12.2.0' ]
}

@test "Slax picks up a new upstream release directory without template changes" {
	printf '<a href="Slax-2027/">New release</a>\n' >> "$TEST_DIR/root"
	printf '<a href="slax-2027.01-64bit-1.iso">ISO</a>\n' > "$TEST_DIR/Slax-2027"
	run bash -c '
		source "$SLAX_FIXTURES/mock.sh"
		source "$1/templates/slax"
		releases_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "${lines[1]}" = 2027.01 ]
}

@test "Slax editions are scoped to the selected release" {
	run bash -c '
		source "$SLAX_FIXTURES/mock.sh"
		source "$1/templates/slax"
		RELEASE=2026.11 editions_
		RELEASE=12.2.0 editions_
		RELEASE=15.0.4 editions_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = $'debian\ndebian\nslackware' ]
}

@test "Slax latest selects the newest build and its matching SHA256" {
	run bash -c '
		source "$SLAX_FIXTURES/mock.sh"
		source "$1/templates/slax"
		RELEASE=latest EDITION=debian get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = "https://ftp.fi.muni.cz/pub/linux/slax/Slax-2026/slax-2026.11-64bit-10.iso $(printf '%064d' 3)" ]
}

@test "Slax resolves old releases with the exact MD5 record" {
	run bash -c '
		source "$SLAX_FIXTURES/mock.sh"
		source "$1/templates/slax"
		RELEASE=latest EDITION=slackware get_
		RELEASE=12.2.0 EDITION=debian get_
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "https://ftp.fi.muni.cz/pub/linux/slax/Slax-15.x/slax-64bit-slackware-15.0.4.iso $(printf '%032d' 1)" ]
	[ "${lines[1]}" = "https://ftp.fi.muni.cz/pub/linux/slax/Slax-12.x/slax-64bit-debian-12.2.0.iso $(printf '%032d' 2)" ]
}

@test "Slax rejects nonexistent combinations and invalid checksums" {
	run bash -c '
		source "$SLAX_FIXTURES/mock.sh"
		source "$1/templates/slax"
		if RELEASE=2026.11 EDITION=slackware get_; then exit 1; fi
		if RELEASE=missing EDITION=debian get_; then exit 1; fi
		if ARCH=arm64 RELEASE=latest EDITION=debian get_; then exit 1; fi
		printf "<html>404</html>\n" > "$SLAX_FIXTURES/sha256"
		if RELEASE=latest EDITION=debian get_; then exit 1; fi
	' _ "$REPO_ROOT"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Slax generated metadata preserves release-scoped editions and all versions" {
	mkdir -p "$TEST_DIR/bin" "$TEST_DIR/public"
	cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
source "$SLAX_FIXTURES/mock.sh"
web_pipe "${@: -1}"
EOF
	chmod +x "$TEST_DIR/bin/curl"
	run env PATH="$TEST_DIR/bin:$PATH" PUBLIC_DIR="$TEST_DIR/public" "$REPO_ROOT/generate" slax
	[ "$status" -eq 0 ]
	run bash -c '
		source "$1/lib.sh"
		source "$2/public/slax"
		releases_
		printf "new:%s\n" "$(dh_editions 2026.11 amd64)"
		printf "old:%s\n" "$(dh_editions 15.0.4 amd64)"
	' _ "$REPO_ROOT" "$TEST_DIR"
	[ "$status" -eq 0 ]
	[[ "$output" == *2026.11* ]]
	[[ "$output" == *12.2.0* ]]
	[[ "$output" == *'new:debian'* ]]
	[[ "$output" == *'old:slackware'* ]]
}
