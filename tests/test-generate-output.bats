#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	mkdir -p "${TEST_DIR}/templates" "${TEST_DIR}/public"
	cat >"${TEST_DIR}/templates/sample" <<'EOF'
OSNAME="sample"
PRETTY="Sample"
ICON="sample.svg"
ICON_ONLINE="https://sample.example/icon.png"
HOMEPAGE="https://sample.example/"
QEMU_ARCH="amd64 arm64"
function releases_() {
	echo "1.0"
}
arch_() {
	echo "amd64 arm64"
}
function get_() {
	echo "first"
}
function get_() {
	echo "last"
}
EOF
	printf 'amd64\t1.0\t-\thttps://example.com/sample.iso\tOK\n' >"${TEST_DIR}/public/tmp_sample.dat"
}

teardown() {
	rm -rf "${TEST_DIR}"
}

@test "generated metadata preserves bare functions and the last duplicate" {
	run bash -c '
		source "$1/lib.sh"
		_DH_SKIP_MAIN=1
		source "$1/generate"
		PUBLIC_DIR="$2/public"
		TEMPLATES_DIR="$2/templates"
		OS=sample
		OPERATION=generate
		write_output >/dev/null || exit $?
		unset -f arch_ get_
		source "$PUBLIC_DIR/sample" 2>/dev/null
		printf "%s|%s\n" "$(arch_ 2>/dev/null)" "$(get_ 2>/dev/null)"
	' _ "${REPO_ROOT}" "${TEST_DIR}"
	[ "${status}" -eq 0 ]
	[ "${output}" = "amd64 arm64|last" ]
}

@test "generated distro metadata does not leak from the previous template" {
	cat >"${TEST_DIR}/templates/second" <<'EOF'
OSNAME="second"
PRETTY="Second"
function releases_() {
	echo "1.0"
}
function get_() {
	echo "https://example.com/second.iso"
}
EOF
	printf 'amd64\t1.0\t-\thttps://example.com/second.iso\tOK\n' >"${TEST_DIR}/public/tmp_second.dat"
	run bash -c '
		source "$1/lib.sh"
		_DH_SKIP_MAIN=1
		source "$1/generate"
		PUBLIC_DIR="$2/public"
		TEMPLATES_DIR="$2/templates"
		OPERATION=generate
		for OS in sample second; do
			write_output >/dev/null || exit $?
		done
		printf "%s|%s|%s\n" \
			"$(grep "^ICON=" "$PUBLIC_DIR/second")" \
			"$(grep "^ICON_ONLINE=" "$PUBLIC_DIR/second")" \
			"$(grep "^HOMEPAGE=" "$PUBLIC_DIR/second")"
	' _ "${REPO_ROOT}" "${TEST_DIR}"
	[ "${status}" -eq 0 ]
	[ "${output}" = 'ICON=""|ICON_ONLINE=""|HOMEPAGE=""' ]
}

@test "template-specific entry dispatch does not leak to the next distro" {
	cat >"${TEST_DIR}/templates/override" <<'EOF'
function releases_() {
	echo test
}
function get_entries_() {
	echo override
}
EOF
	cat >"${TEST_DIR}/templates/clean" <<'EOF'
function releases_() {
	echo test
}
function get_() {
	echo "https://example.com/clean.iso HASH"
}
EOF
	run bash -c '
		_DH_SKIP_MAIN=1
		source "$1/generate"
		PUBLIC_DIR="$2/public"
		TEMPLATES_DIR="$2/templates"
		OPERATION=show
		_iterate_os override
		_iterate_os clean
	' _ "${REPO_ROOT}" "${TEST_DIR}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "override" ]
	[[ "${lines[1]}" =~ ^OK[[:space:]]+clean[[:space:]]+amd64[[:space:]]+test[[:space:]] ]]
}

@test "entry output warns on missing or malformed download URLs" {
	run bash -c '
		source "$1/lib.sh"
		public_dir="$2/public"
		_emit_entry sample amd64 missing "" "" generate "$public_dir" >/dev/null
		_emit_entry sample amd64 malformed "" "../" generate "$public_dir" >/dev/null
		_emit_entry sample amd64 valid "" "https://example.com/sample.iso" generate "$public_dir" >/dev/null
		_emit_entry sample amd64 unchecked "" "" test "$public_dir" >/dev/null
		_emit_entry macos amd64 sonoma "" "" generate "$public_dir" true >/dev/null
		[ "$(awk -F "\t" "{ print \$5 }" "$public_dir/tmp_sample.dat")" = $'WARN\nWARN\nOK\nFAIL' ]
		[ "$(awk -F "\t" "{ print \$5 }" "$public_dir/tmp_macos.dat")" = "OK" ]
	' _ "${REPO_ROOT}" "${TEST_DIR}"
	[ "${status}" -eq 0 ]
}
