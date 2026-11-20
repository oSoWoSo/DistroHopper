#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	mkdir -p "${TEST_DIR}/bin" "${TEST_DIR}/public"
	PUBLIC_DIR="${TEST_DIR}/public"
	export PUBLIC_DIR
	# Exercise CLI selection without requiring generated metadata or the network.
	cat >"${PUBLIC_DIR}/fedora-linux" <<'EOF'
OSNAME="fedora-linux"
PRETTY="Fedora"
QEMU_ARCH="amd64 arm64 ppc64el s390x"
RELEASES="45 44 43"
EDITIONS="KDE Server Workstation Xfce"
_release_editions_() {
	case "$1" in
		"ppc64el|43") echo "KDE Server Workstation";;
	esac
}
EOF
	cat >"${TEST_DIR}/bin/chafa" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
	chmod +x "${TEST_DIR}/bin/chafa"
	PATH="${TEST_DIR}/bin:${PATH}"
	export PATH
}

teardown() {
	rm -rf "${TEST_DIR}"
}

@test "show selects editions for the requested architecture and release" {
	run "${REPO_ROOT}/qget" --show --plain --arch ppc64le --release 43 fedora-linux
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"Archs:       amd64 arm64 ppc64el s390x"* ]]
	[[ "${output}" == *"Releases:    45 44 43"* ]]
	[[ "${output}" == *"Editions:    KDE Server Workstation"* ]]
}

@test "show rejects missing architecture and release values promptly" {
	run timeout 2 "${REPO_ROOT}/qget" --show --arch
	[ "${status}" -eq 1 ]
	[[ "${output}" == *"--arch requires an architecture"* ]]

	run timeout 2 "${REPO_ROOT}/qget" --show --release
	[ "${status}" -eq 1 ]
	[[ "${output}" == *"--release requires a release"* ]]
}

@test "show does not consume another option as an argument value" {
	run timeout 2 "${REPO_ROOT}/qget" --show --arch --plain debian
	[ "${status}" -eq 1 ]
	[[ "${output}" == *"--arch requires an architecture"* ]]

	run timeout 2 "${REPO_ROOT}/qget" --show --release --plain debian
	[ "${status}" -eq 1 ]
	[[ "${output}" == *"--release requires a release"* ]]
}
