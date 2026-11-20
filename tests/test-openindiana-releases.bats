#!/usr/bin/env bats

setup() {
 REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
 TEST_DIR="$(mktemp -d)"
 export PROBES="${TEST_DIR}/probes"
}

teardown() {
 rm -rf "${TEST_DIR}"
}

@test "OpenIndiana stops probing after five releases even with SIGPIPE ignored" {
 run bash -c '
  source "$1/templates/openindiana"
  trap "" PIPE
  web_pipe() {
   for date in 20261001 20260901 20260801 20260701 20260601 20140214; do
    echo "<a href=\"./${date}/\">${date}</a>"
   done
  }
  web_check() { echo "$1" >> "$PROBES"; return 0; }
  releases_
 ' _ "${REPO_ROOT}"
 [ "$status" -eq 0 ]
 [ "$output" = '20261001 20260901 20260801 20260701 20260601' ]
 [ "$(wc -l < "$PROBES")" -eq 5 ]
 ! grep -q 20140214 "$PROBES"
}

@test "OpenIndiana skips missing images while collecting five valid releases" {
 run bash -c '
  source "$1/templates/openindiana"
  web_pipe() {
   for date in 20261001 20260901 20260801 20260701 20260601 20260501 20140214; do
    echo "<a href=\"./${date}/\">${date}</a>"
   done
  }
  web_check() {
   echo "$1" >> "$PROBES"
   [[ "$1" != *20260901* ]]
  }
  releases_
 ' _ "${REPO_ROOT}"
 [ "$status" -eq 0 ]
 [ "$output" = '20261001 20260801 20260701 20260601 20260501' ]
 [ "$(wc -l < "$PROBES")" -eq 6 ]
 ! grep -q 20140214 "$PROBES"
}
