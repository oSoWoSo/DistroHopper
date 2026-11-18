#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	cd "${REPO_ROOT}"
	TEST_DIR="$(mktemp -d)"
	mkdir -p "${TEST_DIR}/public" "${TEST_DIR}/templates"
	cat >"${TEST_DIR}/public/sample" <<'EOF'
OSNAME="sample"
PRETTY="Sample Distro"
ICON="alpine-linux.svg"
ICON_ONLINE=""
CATEGORY="Test"
BASEDOF="-"
DESCRIPTION="Test distro"
HOMEPAGE="https://example.com"
EOF
	cp "${TEST_DIR}/public/sample" "${TEST_DIR}/templates/sample"
}

teardown() {
	rm -rf "${TEST_DIR}"
}

@test "website build emits a valid download icon for distro cards" {
	command -v pandoc >/dev/null 2>&1 || skip "pandoc is required to build the website"

	local site_dir="${TEST_DIR}/website"
	run env \
		SRC_DIR="${REPO_ROOT}/website-source" \
		PUBLIC_DIR="${TEST_DIR}/public" \
		TEMPLATES_DIR="${TEST_DIR}/templates" \
		OUT_DIR="${site_dir}" \
		TITLE="Catalog Test" \
		"${REPO_ROOT}/web-create" build

	[ "${status}" -eq 0 ]
	[ -s "${site_dir}/distros.html" ]
	[ -s "${site_dir}/all.html" ]
	[ -s "${site_dir}/icons/download.svg" ]
	grep -Fq 'icons/download.svg' "${site_dir}/distros.html"
	! grep -Fq 'icons/floppy.svg' "${site_dir}/distros.html"
	[[ "${output}" != *"sed:"*"floppy.svg"* ]]
}

@test "supported catalog includes templates without generated metadata and excludes stale public files" {
	cp "${TEST_DIR}/templates/sample" "${TEST_DIR}/templates/missing"
	printf 'OSNAME="missing"\nPRETTY="Missing Metadata"\n' > "${TEST_DIR}/templates/missing"
	printf 'OSNAME="obsolete"\n' > "${TEST_DIR}/public/obsolete"
	run env PUBLIC_DIR="${TEST_DIR}/public" TEMPLATES_DIR="${TEST_DIR}/templates" \
		bash -c 'source "$1"; _generate_distro_cards; _generate_distro_data_js' _ "${REPO_ROOT}/web-create"
	[ "$status" -eq 0 ]
	[[ "$output" == *'data-osname="sample"'* ]]
	[[ "$output" == *'data-osname="missing"'* ]]
	[[ "$output" == *'"missing": {'* ]]
	[[ "$output" != *'data-osname="obsolete"'* ]]
}

@test "catalog fallback includes every template including shared Ubuntu flavours" {
	run env PUBLIC_DIR="${TEST_DIR}/public" TEMPLATES_DIR="${REPO_ROOT}/templates" \
		bash -c 'source "$1"; _generate_distro_cards' _ "${REPO_ROOT}/web-create"
	[ "$status" -eq 0 ]
	local expected actual
	expected=$(find -L "${REPO_ROOT}/templates" -maxdepth 1 -type f | wc -l)
	actual=$(printf '%s\n' "$output" | grep -c 'data-osname=')
	[ "$actual" -eq "$expected" ]
	[[ "$output" == *'data-osname="ubuntu"'* ]]
	[[ "$output" == *'data-osname="kubuntu"'* ]]
}

@test "local icon URLs change when icon contents change" {
	mkdir -p "${TEST_DIR}/icons" "${TEST_DIR}/website"
	printf '<svg/>' > "${TEST_DIR}/icons/sample.svg"
	run bash -c '
		source "$1"
		cd "$2"
		first=$(_icon_url icons/sample.svg)
		printf "<svg><!-- updated --></svg>" > icons/sample.svg
		second=$(_icon_url icons/sample.svg)
		[[ "$first" != "$second" ]] || exit 1
		[[ "$second" == icons/sample.svg?v=* ]] || exit 1
		_icon_html sample Sample sample.svg | grep -Fq "$second" || exit 1
		_generate_icons_list_js >/dev/null
		grep -Fq "\"svgUrl\":\"$second\"" website/icons-available.js
	' _ "${REPO_ROOT}/web-create" "${TEST_DIR}"
	[ "$status" -eq 0 ]
}
