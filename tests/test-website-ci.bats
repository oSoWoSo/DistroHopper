#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
	TEST_DIR="$(mktemp -d)"
}

teardown() {
	rm -rf "$TEST_DIR"
}

extract_step() {
	python3 - "$REPO_ROOT/.github/workflows/website.yml" "$1" "$TEST_DIR/step.sh" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
step = text.split('      - name: ' + sys.argv[2] + '\n', 1)[1]
step = step.split('        run: |\n', 1)[1]
lines = []
for line in step.splitlines():
    if line.strip() and not line.startswith('          '):
        break
    lines.append(line[10:])
pathlib.Path(sys.argv[3]).write_text('\n'.join(lines) + '\n')
PY
}

@test "website reuses only public metadata from distro diagnostics" {
	extract_step 'Reuse matrix metadata'
	mkdir -p "$TEST_DIR/artifacts/diagnostics-one/public" "$TEST_DIR/artifacts/diagnostics-two/public" "$TEST_DIR/artifacts/diagnostics-windows/results"
	printf 'OSNAME=one\n' > "$TEST_DIR/artifacts/diagnostics-one/public/one"
	printf 'OSNAME=two\n' > "$TEST_DIR/artifacts/diagnostics-two/public/two"
	printf 'amd64\tlatest\tdesktop\thttps://example.com\tPASS\n' > "$TEST_DIR/artifacts/diagnostics-one/public/tmp_one.dat"
	printf 'diagnostics only\n' > "$TEST_DIR/artifacts/diagnostics-windows/results/check.txt"
	run bash -c 'cd "$1"; METADATA_ARTIFACT_DIR="$1/artifacts" bash -e -o pipefail step.sh' _ "$TEST_DIR"
	[ "$status" -eq 0 ]
	cmp "$TEST_DIR/public/one" "$TEST_DIR/artifacts/diagnostics-one/public/one"
	cmp "$TEST_DIR/public/two" "$TEST_DIR/artifacts/diagnostics-two/public/two"
	[ -s "$TEST_DIR/public/tmp_one.dat" ]
	[ ! -e "$TEST_DIR/public/check.txt" ]
	extract_step 'Validate distro metadata'
	run bash -c 'cd "$1"; bash -e -o pipefail step.sh' _ "$TEST_DIR"
	[ "$status" -eq 0 ]
}

@test "website refuses empty matrix metadata instead of regenerating" {
	extract_step 'Reuse matrix metadata'
	run bash -c 'cd "$1"; METADATA_ARTIFACT_DIR="$1/missing" bash -e -o pipefail step.sh' _ "$TEST_DIR"
	[ "$status" -eq 0 ]
	extract_step 'Validate distro metadata'
	run bash -c 'cd "$1"; bash -e -o pipefail step.sh' _ "$TEST_DIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *'No supported distro metadata was generated'* ]]
}

@test "matrix enables metadata reuse and standalone generation is conditional" {
	grep -q 'reuse_matrix_metadata: true' "$REPO_ROOT/.github/workflows/test-qget.yml"
	grep -Fq 'if: ${{ !inputs.reuse_matrix_metadata }}' "$REPO_ROOT/.github/workflows/website.yml"
	grep -q 'pattern: diagnostics-\*' "$REPO_ROOT/.github/workflows/website.yml"
}
