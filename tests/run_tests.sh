#!/usr/bin/env bash
# Run all DistroHopper test suites

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_DIR="$REPO_ROOT/tests"

_green='\033[0;32m'
_red='\033[0;31m'
_nc='\033[0m'

suite_pass=0
suite_fail=0

run_suite() {
    local suite_file="$1"
    local name
    name=$(basename "$suite_file" .sh)
    echo ""
    echo "━━━ $name ━━━"
    if bash "$suite_file"; then
        suite_pass=$((suite_pass + 1))
    else
        suite_fail=$((suite_fail + 1))
    fi
}

echo "════════════════════════════════"
echo "    DistroHopper test suite"
echo "════════════════════════════════"

run_suite "$TESTS_DIR/test_dh.sh"
run_suite "$TESTS_DIR/test_qget.sh"
run_suite "$TESTS_DIR/test_action_files.sh"

echo ""
echo "════════════════════════════════"
total=$((suite_pass + suite_fail))
if [ $suite_fail -eq 0 ]; then
    echo -e "${_green}All $total suites passed${_nc}"
else
    echo -e "${_red}$suite_fail / $total suites failed${_nc}"
fi
echo "════════════════════════════════"

[ $suite_fail -eq 0 ]
