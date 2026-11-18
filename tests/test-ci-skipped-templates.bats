#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
	# Exercise the actual check step, without a YAML dependency.
	python3 - "$REPO_ROOT/.github/workflows/test-qget.yml" "$TEST_DIR/check.sh" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
step = text.split('        id: check\n', 1)[1].split('        run: |\n', 1)[1]
lines = []
for line in step.splitlines():
    if line.strip() and not line.startswith('          '):
        break
    lines.append(line[10:])
pathlib.Path(sys.argv[2]).write_text('\n'.join(lines) + '\n')
PY
	printf '#!/usr/bin/env bash\necho "qget must not run" >&2\nexit 99\n' > "$TEST_DIR/qget"
	chmod +x "$TEST_DIR/qget"
}

teardown() {
	rm -rf "$TEST_DIR"
}

@test "Windows and Windows Server appear as skipped rather than failing" {
	for distro in windows windows-server; do
		run bash -c '
			cd "$1"
			export DISTRO="$2" GITHUB_OUTPUT="$1/outputs" WINDOWS_PROBE=false
			bash -e -o pipefail check.sh
		' _ "$TEST_DIR" "$distro"
		[ "$status" -eq 0 ]
		grep -qx 'passed=0' "$TEST_DIR/outputs"
		grep -qx 'failed=0' "$TEST_DIR/outputs"
		grep -qx 'skipped=1' "$TEST_DIR/outputs"
		grep -q "^SKIP: $distro " "$TEST_DIR/results/check.txt"
		! grep -q 'qget must not run' "$TEST_DIR/results/check.txt"
		rm -f "$TEST_DIR/outputs"
	done
}

@test "manual Windows probe invokes the probe script and counts its results" {
	mkdir -p "$TEST_DIR/scripts"
	printf '#!/usr/bin/env bash\necho "PASS: $1-11-english URL generated and reachable"\n' > "$TEST_DIR/scripts/check-windows-ci"
	chmod +x "$TEST_DIR/scripts/check-windows-ci"
	run bash -c '
		cd "$1"
		export DISTRO=windows WINDOWS_PROBE=true GITHUB_OUTPUT="$1/outputs"
		bash -e -o pipefail check.sh
	' _ "$TEST_DIR"
	[ "$status" -eq 0 ]
	grep -qx 'passed=1' "$TEST_DIR/outputs"
	grep -qx 'failed=0' "$TEST_DIR/outputs"
	grep -qx 'skipped=0' "$TEST_DIR/outputs"
	! grep -q 'qget must not run' "$TEST_DIR/results/check.txt"
}

@test "non-Windows checks still call qget and count zero skipped rows" {
	printf '#!/usr/bin/env bash\necho "PASS: sample https://example.com/image.iso"\n' > "$TEST_DIR/qget"
	run bash -c '
		cd "$1"
		export DISTRO=sample GITHUB_OUTPUT="$1/outputs"
		bash -e -o pipefail check.sh
	' _ "$TEST_DIR"
	[ "$status" -eq 0 ]
	grep -qx 'passed=1' "$TEST_DIR/outputs"
	grep -qx 'failed=0' "$TEST_DIR/outputs"
	grep -qx 'skipped=0' "$TEST_DIR/outputs"
}
