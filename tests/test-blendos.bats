#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR=$(mktemp -d)
	source "${REPO_ROOT}/templates/blendos"
	TEST_SHA=$(printf '%064d' 1)
	web_pipe() {
		[ "$1" = "${BLENDOS_BUILD_URL}/checksum?job=build-job" ] || return 1
		printf '%s  blendOS.iso\n' "$TEST_SHA"
	}
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "blendOS advertises a rolling amd64 build without obsolete GitHub tags" {
	[ "$(releases_)" = latest ]
	[ "$(arch_)" = amd64 ]
}

@test "blendOS resolves the German master ISO and its own SHA256 artifact" {
	RELEASE=latest ARCH=amd64
	run get_
	[ "$status" -eq 0 ]
	[ "$output" = "https://git.blendos.co/api/v4/projects/32/jobs/artifacts/main/raw/blendOS.iso?job=build-job ${TEST_SHA}" ]
}

@test "blendOS accepts binary checksum records but rejects unrelated hashes and HTML" {
	RELEASE=latest ARCH=amd64
	web_pipe() { printf '%s *blendOS.iso\n' "$TEST_SHA"; }
	[ "$(get_)" = "${BLENDOS_BUILD_URL}/blendOS.iso?job=build-job ${TEST_SHA}" ]
	for body in "${TEST_SHA} other.iso" 'invalid blendOS.iso' '<html>unavailable</html>' ''; do
		web_pipe() { printf '%s\n' "$body"; }
		run get_
		[ "$status" -eq 1 ]
		[[ "$output" == *'No valid SHA256 checksum'* ]]
	done
}

@test "blendOS propagates checksum fetch failure rather than emitting an unverified ISO" {
	RELEASE=latest ARCH=amd64
	web_pipe() { return 22; }
	run get_
	[ "$status" -eq 1 ]
	[[ "$output" == *'Could not fetch'* ]]
}

@test "blendOS refuses obsolete releases and unsupported architectures" {
	RELEASE=23.06 ARCH=amd64
	run get_
	[ "$status" -eq 1 ]
	[ -z "$output" ]
	RELEASE=latest ARCH=arm64
	run get_
	[ "$status" -eq 1 ]
	[ -z "$output" ]
}

@test "generated blendOS metadata passes the real qget check and creates a clean ISO config" {
	mkdir -p "$TEST_DIR/bin" "$TEST_DIR/public" "$TEST_DIR/TODO"
	printf 'test ISO contents\n' > "$TEST_DIR/image.iso"
	export BLEND_TEST_IMAGE="$TEST_DIR/image.iso"
	cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
case "$url" in
	*/checksum\?job=build-job)
		printf '%s  blendOS.iso\n' "$(sha256sum "$BLEND_TEST_IMAGE" | cut -d' ' -f1)";;
	*/blendOS.iso\?job=build-job)
		out=''
		while [ "$#" -gt 0 ]; do
			case "$1" in
				--write-out)
					if [ "$2" = '%{url_effective}' ]; then
						printf '%s' "$url"
					else
						printf '200 application/octet-stream'
					fi
					shift;;
				--output|-o) out="$2"; shift;;
			esac
			shift
		done
		if [ -n "$out" ] && [ "$out" != /dev/null ]; then
			cp "$BLEND_TEST_IMAGE" "$out"
		fi;;
	*) exit 22;;
esac
EOF
	chmod +x "$TEST_DIR/bin/curl"
	run env PATH="$TEST_DIR/bin:$PATH" PUBLIC_DIR="$TEST_DIR/public" \
		"$REPO_ROOT/generate" blendos
	[ "$status" -eq 0 ]
	[ -s "$TEST_DIR/public/blendos" ]
	grep -q '^RELEASES="latest"' "$TEST_DIR/public/blendos"
	run env PATH="$TEST_DIR/bin:$PATH" PUBLIC_DIR="$TEST_DIR/public" \
		"$REPO_ROOT/qget" --arch amd64 --check blendos
	[ "$status" -eq 0 ]
	[[ "$output" == *'PASS: blendos-latest'* ]]
	[[ "$output" != *'FAIL:'* ]]
	cd "$TEST_DIR"
	run env PATH="$TEST_DIR/bin:$PATH" PUBLIC_DIR="$TEST_DIR/public" \
		"$REPO_ROOT/qget" --arch amd64 blendos latest
	[ "$status" -eq 0 ]
	[ -f blendos-latest/blendOS.iso ]
	cmp image.iso blendos-latest/blendOS.iso
	grep -q '^iso="blendos-latest/blendOS.iso"$' blendos-latest.conf
	! grep -q 'job=' blendos-latest.conf
}
