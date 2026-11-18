#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	command -v jq >/dev/null || skip 'jq is required by the Windows resolvers'
	TEST_DIR="$(mktemp -d)"
	mkdir -p "$TEST_DIR/bin"
	export WINDOWS_TEST_CALLS="$TEST_DIR/calls"
	export WINDOWS_TEST_MODE=pass
	cat > "$TEST_DIR/bin/uuidgen" <<'EOF'
#!/usr/bin/env bash
printf '00000000-0000-0000-0000-000000000001\n'
EOF
	cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$WINDOWS_TEST_CALLS"
args=("$@")
url="${@: -1}"
headers=''
head=false
for ((i=0; i<${#args[@]}; i++)); do
	case "${args[i]}" in
		--dump-header) headers="${args[i+1]}" ;;
		--head) head=true ;;
	esac
done
if [ "$WINDOWS_TEST_MODE" = restricted ]; then
	printf 'HTTP/2 403 Forbidden\r\n' > "$headers"
	exit 22
fi
printf 'HTTP/2 200 OK\r\n' > "$headers"
case "$url" in
	*/software-download/windows11|*/software-download/windows10ISO)
		printf '<option value="123">Windows</option>\n' ;;
	*vlscppe.microsoft.com/tags*) ;;
	*getskuinformationbyproductedition*)
		printf '{"Skus":[{"LocalizedLanguage":"English (United States)","Id":1}]}\n' ;;
	*GetProductDownloadLinksBySku*)
		case "$WINDOWS_TEST_MODE" in
			rejected) printf '{"Error":"Sentinel marked this request as rejected."}\n' ;;
			empty) ;;
			*) printf '{"ProductDownloadOptions":[{"Uri":"https://software.download.prss.microsoft.com/dbazure/windows_x64.iso?secret=temporary"}]}\n' ;;
		esac ;;
	*/evalcenter/download-windows-server-*)
		printf '<a href="https://go.microsoft.com/fwlink/p/?LinkID=123&clcid=0x409&culture=en-us&country=US">ISO</a>\n' ;;
	https://go.microsoft.com/fwlink/*)
		[ "$head" = true ] || exit 99
		printf 'https://software.download.prss.microsoft.com/dbazure/server.iso?secret=temporary' ;;
	https://software.download.prss.microsoft.com/*)
		# Fail the test if a resolver attempts an actual ISO GET.
		[ "$head" = true ] || { echo 'Unexpected ISO download'; exit 99; }
		[ "$WINDOWS_TEST_MODE" != broken_link ] || exit 22
		;;
	*) exit 99 ;;
esac
EOF
	chmod +x "$TEST_DIR/bin/curl" "$TEST_DIR/bin/uuidgen"
	export PATH="$TEST_DIR/bin:$PATH"
}

teardown() {
	[ -z "${TEST_DIR:-}" ] || rm -rf "$TEST_DIR"
}

@test "Windows probe exercises the real workstation resolver without ISO downloads" {
	run "$REPO_ROOT/scripts/check-windows-ci" windows
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^PASS:')" -eq 2 ]
	[[ "$output" != *'FAIL:'* ]]
	[[ "$output" != *'secret=temporary'* ]]
	grep -q 'GetProductDownloadLinksBySku' "$WINDOWS_TEST_CALLS"
	grep -q -- '--head.*windows_x64.iso' "$WINDOWS_TEST_CALLS"
}

@test "Windows probe exercises the server resolver and redacts signed URLs" {
	run "$REPO_ROOT/scripts/check-windows-ci" windows-server
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^PASS:')" -eq 3 ]
	[[ "$output" != *'secret=temporary'* ]]
	[[ "$output" != *'command not found'* ]]
	grep -q 'evalcenter/download-windows-server-' "$WINDOWS_TEST_CALLS"
}

@test "Windows probe marks explicit Microsoft rejection as skipped" {
	export WINDOWS_TEST_MODE=rejected
	run "$REPO_ROOT/scripts/check-windows-ci" windows
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^SKIP:')" -eq 2 ]
	[[ "$output" != *'FAIL:'* ]]
}

@test "Windows probe marks HTTP access restrictions as skipped" {
	export WINDOWS_TEST_MODE=restricted
	run "$REPO_ROOT/scripts/check-windows-ci" windows-server
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^SKIP:')" -eq 3 ]
	[[ "$output" != *'FAIL:'* ]]
}

@test "Windows probe does not misclassify empty API responses as IP blocking" {
	export WINDOWS_TEST_MODE=empty
	run "$REPO_ROOT/scripts/check-windows-ci" windows
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^FAIL:')" -eq 2 ]
	[[ "$output" != *'SKIP:'* ]]
}

@test "Windows probe reports unreachable resolved URLs as failures" {
	export WINDOWS_TEST_MODE=broken_link
	run "$REPO_ROOT/scripts/check-windows-ci" windows
	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -c '^FAIL:')" -eq 2 ]
	[[ "$output" != *'PASS:'* ]]
}
