#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
}

@test "Bedrock aliases resolve to sourceable base templates" {
	run bash -c '
		. "$1/templates/bedrock-linux"
		TEMPLATES_DIR="$1/templates"
		while IFS="|" read -r base template; do
			[ "$(_base_template_ "$base")" = "$template" ] || exit 1
			[ -f "$TEMPLATES_DIR/$template" ] || exit 1
		done <<"CASES"
alpine|alpine-linux
arch|arch-linux
devuan|devuan-gnu-linux
gentoo|gentoo-linux
void|void-linux
CASES
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
}
@test "Bedrock base discovery loads Alpine, Devuan, and Gentoo templates" {
	run bash -c '
		web_pipe() {
			case "$1" in
				https://dl-cdn.alpinelinux.org/alpine/) echo v3.24/;;
				https://files.devuan.org/) printf "%s\n" "devuan_excalibur/" "LATEST_STABLE_IS_EXCALIBUR";;
				*/installer-iso/) echo devuan_excalibur_6.1.1_amd64_netinstall.iso;;
				*/desktop-live/) echo devuan_excalibur_6.1.1_amd64_desktop-live.iso;;
				*/latest-iso.txt) printf "%s\n" "20261025T170057Z/install-amd64-minimal-20261025T170057Z.iso 100" "20260913T163055Z/livegui-amd64-20260913T163055Z.iso 200";;
			esac
		}
		. "$1/templates/bedrock-linux"
		TEMPLATES_DIR="$1/templates"
		ARCH=amd64
		for base in alpine-linux devuan-gnu-linux gentoo-linux; do
			release=$(_base_releases_ "$base" | awk "NR == 1 {print; exit}")
			edition=$(_base_editions_ "$base" | awk "NR == 1 {print; exit}")
			printf "%s|%s|%s\n" "$base" "$release" "$edition"
		done
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${output}" = $'alpine-linux|v3.24|standard\ndevuan-gnu-linux|excalibur|desktop-live\ngentoo-linux|latest|minimal' ]
}


@test "Alpine returns standard ISOs for both supported architectures" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*/releases/x86_64/) echo alpine-standard-3.24.3-x86_64.iso;;
				*/releases/aarch64/) echo alpine-standard-3.24.3-aarch64.iso;;
				*.sha256) printf "%064d  %s\n" 0 "${1##*/}";;
			esac
		}
		. "$1/templates/alpine-linux"
		RELEASE=v3.24
		EDITION=standard
		ARCH=amd64
		get_
		ARCH=arm64 get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${lines[0]}" == "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-standard-3.24.3-x86_64.iso "* ]]
	[[ "${lines[1]}" == "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/aarch64/alpine-standard-3.24.3-aarch64.iso "* ]]
}

@test "Devuan selects its stable release and matches installer checksums" {
	run bash -c '
		web_pipe() {
			case "$1" in
				https://files.devuan.org/)
					printf "%s\n" "devuan_excalibur/" "devuan_daedalus/" "LATEST_STABLE_IS_EXCALIBUR";;
				*/installer-iso/)
					echo devuan_excalibur_6.1.1_amd64_netinstall.iso;;
				*/SHA256SUMS.txt)
					printf "%064d  devuan_excalibur_6.1.1_amd64_netinstall.iso\n" 0;;
			esac
		}
		. "$1/templates/devuan-gnu-linux"
		RELEASES="$(releases_)"
		RELEASE=excalibur ARCH=amd64 editions_
		RELEASE=excalibur ARCH=amd64 EDITION=netinstall get_
		printf "releases=%s\n" "${RELEASES}"
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"https://files.devuan.org/devuan_excalibur/installer-iso/devuan_excalibur_6.1.1_amd64_netinstall.iso "* ]]
	[[ "${output}" == *"releases=excalibur"* ]]
	[[ "${output}" == *"netinstall"* ]]
}

@test "Bedrock resolves Devuan editions using its selected base release" {
	run bash -c '
		web_pipe() {
			case "$1" in
				https://files.devuan.org/)
					printf "%s\n" "devuan_excalibur/" "LATEST_STABLE_IS_EXCALIBUR";;
				*/installer-iso/)
					printf "%s\n" "devuan_excalibur_6.1.1_amd64_desktop.iso" "devuan_excalibur_6.1.1_amd64_netinstall.iso";;
				*/desktop-live/)
					echo devuan_excalibur_6.1.1_amd64_desktop-live.iso;;
				*/SHA256SUMS.txt)
					printf "%064d  devuan_excalibur_6.1.1_amd64_desktop.iso\n" 0;;
			esac
		}
		. "$1/templates/bedrock-linux"
		TEMPLATES_DIR="$1/templates"
		ARCH=amd64
		RELEASE=0.7.31
		EDITION=devuan-gnu-linux
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${output}" == "https://files.devuan.org/devuan_excalibur/installer-iso/devuan_excalibur_6.1.1_amd64_desktop.iso "* ]]
	[[ "${output##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "Bedrock leaves editions empty for base templates without editions" {
	run bash -c '
		. "$1/templates/bedrock-linux"
		TEMPLATES_DIR="$1/templates"
		ARCH=amd64
		_base_editions_ arch-linux 2026.10
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ -z "${output}" ]
}

@test "Gentoo resolves the selected edition from the signed ISO manifest" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*/latest-iso.txt)
					printf "%s\n" "20261025T170057Z/install-amd64-minimal-20261025T170057Z.iso 100" "20260913T163055Z/livegui-amd64-20260913T163055Z.iso 200";;
				*.DIGESTS)
					printf "%s\n" "# SHA512 HASH" "$(printf "%0128d" 0) livegui-amd64-20260913T163055Z.iso" "# SHA256 HASH";;
			esac
		}
		. "$1/templates/gentoo-linux"
		RELEASE=latest EDITION=livegui get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${output}" == "https://distfiles.gentoo.org/releases/amd64/autobuilds/20260913T163055Z/livegui-amd64-20260913T163055Z.iso "* ]]
}
