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

@test "cached web_pipe forwards Redox curl options and retries failed requests" {
	run bash -c '
		_DH_SKIP_MAIN=yes
		source "$1/generate"
		_WEB_CACHE_DIR=$(mktemp -d)
		trap '\''rm -rf "${_WEB_CACHE_DIR}"'\'' EXIT
		curl() {
			printf "%s\n" "$@" >> "${_WEB_CACHE_DIR}/calls"
			[[ " $* " == *" --fail --retry 3 "* ]] || return 2
			if [ ! -f "${_WEB_CACHE_DIR}/attempted" ]; then
				touch "${_WEB_CACHE_DIR}/attempted"
				echo "<html>Just a moment...</html>"
				return 22
			fi
			echo manifest
		}
		if web_pipe https://example.test/SHA256SUM --fail --retry 3; then exit 1; fi
		[ "$(web_pipe https://example.test/SHA256SUM --fail --retry 3)" = manifest ] || exit 1
		[ "$(web_pipe https://example.test/SHA256SUM --fail --retry 3)" = manifest ] || exit 1
		[ "$(grep -c -- --fail "${_WEB_CACHE_DIR}/calls")" = 2 ]
	' _ "${REPO_ROOT}"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "web_pipe does not reuse a lenient response for an HTTP-failing request" {
	run bash -c '
		_DH_SKIP_MAIN=yes
		source "$1/generate"
		_WEB_CACHE_DIR=$(mktemp -d)
		trap '\''rm -rf "${_WEB_CACHE_DIR}"'\'' EXIT
		curl() {
			[[ " $* " != *" --fail "* ]] || return 22
			echo "<html>Just a moment...</html>"
		}
		web_pipe https://example.test/SHA256SUM >/dev/null
		web_pipe https://example.test/SHA256SUM --fail
	' _ "${REPO_ROOT}"
	[ "$status" -eq 22 ]
	[ -z "$output" ]
}

@test "cached JSON requests propagate failures without caching error pages" {
	run bash -c '
		_DH_SKIP_MAIN=yes
		source "$1/generate"
		_WEB_CACHE_DIR=$(mktemp -d)
		trap '\''rm -rf "${_WEB_CACHE_DIR}"'\'' EXIT
		curl() { echo "partial response"; return 28; }
		web_pipe_json https://example.test/data.json
		rc=$?
		[ "$rc" = 28 ] || exit 1
		[ -z "$(find "${_WEB_CACHE_DIR}" -name "*.body" -print)" ]
	' _ "${REPO_ROOT}"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
