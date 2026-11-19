#!/usr/bin/env bats

@test "plain menu returns only the selected action on stdout" {
	local root
	root="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	run bash -c '
		# Force the plain terminal fallback even if gum is installed.
		command() {
			if [[ "$*" == "-v gum" ]]; then return 1; fi
			builtin command "$@"
		}
		source "$1/lib.sh"
		selected=$(_choose "Build this website" "Exit" <<< 1)
		[[ "$selected" == "Build this website" ]]
	' _ "$root"
	[ "$status" -eq 0 ]
	[[ "$output" == *'1) Build this website'* ]]
	[[ "$output" == *'2) Exit'* ]]
}
