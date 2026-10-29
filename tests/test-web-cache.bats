#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
}

@test "web_check probes uncached URLs and preserves cached failures" {
	run bash -c '
		_DH_SKIP_MAIN=yes
		source "$1/generate"
		_WEB_CACHE_DIR=$(mktemp -d)
		trap '\''rm -rf "${_WEB_CACHE_DIR}"'\'' EXIT
		CURL_LOG="${_WEB_CACHE_DIR}/calls"
		curl() {
			local url="${@: -1}"
			printf "%s\\n" "${url}" >> "${CURL_LOG}"
			case "${url}" in
				*latest-nixos-minimal-*) return 0;;
				*) return 22;;
			esac
		}
		. "$1/templates/nixos"
		RELEASE=26.05
		FIRST=$(editions_ | tr "\\n" " ")
		SECOND=$(editions_ | tr "\\n" " ")
		printf "first=%s\\nsecond=%s\\ncalls=%s\\n" "${FIRST% }" "${SECOND% }" "$(wc -l < "${CURL_LOG}")"
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "first=minimal" ]
	[ "${lines[1]}" = "second=minimal" ]
	[ "${lines[2]}" = "calls=3" ]
}
