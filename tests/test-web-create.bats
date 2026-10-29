#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	cd "${REPO_ROOT}"
	TEST_DIR="$(mktemp -d)"
	mkdir -p "${TEST_DIR}/public"
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
