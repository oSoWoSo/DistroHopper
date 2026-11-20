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
EDITIONS_LIST="KDE
Server
Workstation
Xfce
Brazilian Portuguese
English International"
_release_editions_() {
	case "$1" in
		"ppc64el|43") echo "KDE Server Workstation";;
		"amd64|45") echo "Brazilian Portuguese English International";;
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
	[[ "${output}" == *$'EditionsList:\nKDE\nServer\nWorkstation'* ]]
}

@test "plain architecture output preserves scoped multiword edition names" {
	run "${REPO_ROOT}/qget" --show --plain --arch amd64 --release 45 fedora-linux
	[ "${status}" -eq 0 ]
	[[ "${output}" == *$'EditionsList:\nBrazilian Portuguese\nEnglish International'* ]]
	[[ "${output}" != *$'EditionsList:\nKDE'* ]]
}

@test "live edition queries do not rediscover an already selected release" {
	mkdir -p "${TEST_DIR}/templates"
	export DISCOVERY_LOG="${TEST_DIR}/discovery.log"
	cat >"${TEST_DIR}/templates/scoped" <<'EOF'
PRETTY="Scoped"
QEMU_ARCH="amd64"
arch_() { echo amd64; }
releases_() { echo rediscovered >> "$DISCOVERY_LOG"; echo latest; }
editions_() { echo desktop; }
EOF
	for arch in '' amd64; do
		args=(--show --plain)
		[ -z "$arch" ] || args+=(--arch "$arch")
		run env DH_USE_TEMPLATES=yes TEMPLATES_DIR="${TEST_DIR}/templates" \
			"${REPO_ROOT}/qget" "${args[@]}" --release latest scoped
		[ "$status" -eq 0 ]
		[[ "$output" == *"Releases:    latest"* ]]
		[[ "$output" == *$'EditionsList:\ndesktop'* ]]
		[ ! -e "$DISCOVERY_LOG" ]
	done
	# The unscoped listing still performs discovery normally.
	run env DH_USE_TEMPLATES=yes TEMPLATES_DIR="${TEST_DIR}/templates" \
		"${REPO_ROOT}/qget" --show --plain scoped
	[ "$status" -eq 0 ]
	[ "$(wc -l < "$DISCOVERY_LOG")" -eq 1 ]
}

@test "plain output keeps every multiline discovery value on its field line" {
	mkdir -p "${TEST_DIR}/templates"
	cat >"${TEST_DIR}/templates/multiline" <<'EOF'
PRETTY="Multiline"
arch_() { printf 'amd64\narm64\n'; }
releases_() { printf 'new\nold\n'; }
editions_() { printf 'desktop\nserver\n'; }
EOF
	run env DH_USE_TEMPLATES=yes TEMPLATES_DIR="${TEST_DIR}/templates" \
		"${REPO_ROOT}/qget" --show --plain multiline
	[ "$status" -eq 0 ]
	[[ "$output" == *"Archs:       amd64 arm64"* ]]
	[[ "$output" == *"Releases:    new old"* ]]
	[[ "$output" == *"Editions:    desktop server"* ]]
	[[ "$output" == *$'EditionsList:\ndesktop\nserver'* ]]
	# Architecture-specific discovery must use the same single-line format.
	run env DH_USE_TEMPLATES=yes TEMPLATES_DIR="${TEST_DIR}/templates" \
		"${REPO_ROOT}/qget" --show --plain --arch arm64 multiline
	[ "$status" -eq 0 ]
	[[ "$output" == *"Archs:       amd64 arm64"* ]]
	[[ "$output" == *"Releases:    new old"* ]]
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
