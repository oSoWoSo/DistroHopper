#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	cd "${REPO_ROOT}"
	TEST_DIR="$(mktemp -d)"
	mkdir -p "${TEST_DIR}/home" "${TEST_DIR}/public"
	PUBLIC_DIR="${TEST_DIR}/public"
	HOME="${TEST_DIR}/home"
	ICON_LOG="${TEST_DIR}/icons.log"
	mkdir "${TEST_DIR}/bin"
	cat >"${TEST_DIR}/bin/chafa" <<'CHafa'
#!/usr/bin/env bash
printf '%s\n' "${@: -1}" >>"${ICON_LOG}"
CHafa
	chmod +x "${TEST_DIR}/bin/chafa"
	PATH="${TEST_DIR}/bin:${PATH}"
	export PATH HOME ICON_LOG PUBLIC_DIR
}

teardown() {
	rm -rf "${TEST_DIR}"
}

write_public_fixture() {
	local os="$1" icon="$2"
	cat >"${PUBLIC_DIR}/${os}" <<EOF
OSNAME="${os}"
PRETTY="${os}"
ICON="${icon}"
CATEGORY="Test"
BASEDOF="-"
HOMEPAGE="https://example.com"
CREDENTIALS="-"
RELEASES="test"
EOF
}

@test "qget passes mapped distro icons to the renderer" {
	while IFS='|' read -r os icon; do
		write_public_fixture "${os}" "${icon}"
		: >"${ICON_LOG}"
		run "${REPO_ROOT}/qget" --show --plain "${os}"
		[ "${status}" -eq 0 ]
		[ "$(cat "${ICON_LOG}")" = "icons/${icon}" ]
	done <<'CASES'
afagos|afagos.svg
gobolinux|gobolinux.svg
athena-os|athena-os.svg
bedrock|bedrock-linux.svg
bedrock-linux|bedrock-linux.svg
klv-airedale|klv-airdale.svg
kodachi-os|kodachi.svg
mabox|mabox-linux.svg
miyolinux|miyo-linux.svg
odyssey|odyssey-linux.svg
spirallinux|spirallinux.svg
talos|talos-linux.svg
trisquel-gnu-linux|trisquel.svg
ventoy|ventoy.svg
truenas-scale|truenas-scale.svg
vx-linux|vx-linux.svg
redox-os|redox.svg
whonix|whonix.svg
CASES
}
@test "Rosette entries have local icons and official homepages" {
	while IFS= read -r file; do
		icon="$(sed -n 's/^icon: *//p' "data/rosette/${file}")"
		homepage="$(sed -n 's/^homepage: *//p' "data/rosette/${file}")"
		[ -n "${icon}" ]
		[ -f "icons/${icon}" ]
		[[ "${homepage}" == https://* || "${homepage}" == http://* ]]
	done < <(jq -r '.[].file' data/rosette/index.json)
}

@test "template icon references resolve to website assets" {
	local template icon missing=0
	for template in "${REPO_ROOT}"/templates/*; do
		while IFS= read -r icon; do
			if [ -n "${icon}" ] && [ ! -f "${REPO_ROOT}/icons/${icon}" ]; then
				printf "missing icon %s referenced by %s\n" "${icon}" "${template}" >&2
				missing=1
			fi
		done < <(sed -n 's/^[[:space:]]*ICON="\([^"]*\)".*/\1/p' "${template}")
	done
	return "${missing}"
}

@test "qget skips icon rendering when no local asset is available" {
	for os in grml; do
		icon="$(bash -c '. "$1"; printf "%s" "${ICON:-}"' _ "${REPO_ROOT}/templates/${os}")"
		write_public_fixture "${os}" "${icon}"
		: >"${ICON_LOG}"
		run "${REPO_ROOT}/qget" --show --plain "${os}"
		[ "${status}" -eq 0 ]
		[ ! -s "${ICON_LOG}" ]
	done
}

@test "legacy Bedrock base names resolve to current templates" {
	# shellcheck disable=SC1091
	. "${REPO_ROOT}/templates/bedrock-linux"
	TEMPLATES_DIR="${REPO_ROOT}/templates"
	while IFS='|' read -r base template; do
		[ "$(_base_template_ "${base}")" = "${template}" ]
		[ -f "${TEMPLATES_DIR}/${template}" ]
	done <<'CASES'
alpine|alpine-linux
arch|arch-linux
devuan|devuan-gnu-linux
gentoo|gentoo-linux
void|void-linux
CASES
}

@test "templates with local SVG icons omit online icon overrides" {
	run bash -c '
		for template in "$@"; do
			unset ICON ICON_ONLINE
			. "$template"
			if [[ "${ICON:-}" == *.svg && -n "${ICON_ONLINE:-}" ]]; then
				printf "%s defines ICON_ONLINE despite local icon %s\n" "$template" "$ICON" >&2
				exit 1
			fi
		done
	' _ "${REPO_ROOT}"/templates/*
	[ "${status}" -eq 0 ]
}
