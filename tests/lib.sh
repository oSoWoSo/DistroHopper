#!/usr/bin/env bash
# Shared test helpers for DistroHopper test suite

PASS=0
FAIL=0
declare -a FAIL_MSGS=()

_green='\033[0;32m'
_red='\033[0;31m'
_nc='\033[0m'

pass() {
    echo -e "  ${_green}✓${_nc} $1"
    ((PASS++))
}

fail() {
    echo -e "  ${_red}✗${_nc} $1"
    ((FAIL++))
    FAIL_MSGS+=("$1")
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$desc"
    else
        fail "$desc (expected='$expected', got='$actual')"
    fi
}

assert_ne() {
    local desc="$1" notexpected="$2" actual="$3"
    if [ "$notexpected" != "$actual" ]; then
        pass "$desc"
    else
        fail "$desc (should not be '$notexpected')"
    fi
}

assert_match() {
    local desc="$1" pattern="$2" actual="$3"
    if [[ "$actual" =~ $pattern ]]; then
        pass "$desc"
    else
        fail "$desc (pattern='$pattern' not matched in: '$actual')"
    fi
}

assert_cmd() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc (command failed: $*)"
    fi
}

assert_fn_exists() {
    local desc="$1" fn="$2"
    if declare -f "$fn" >/dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc (function '$fn' not defined)"
    fi
}

summary() {
    local total=$((PASS + FAIL))
    echo ""
    if [ $FAIL -eq 0 ]; then
        echo -e "${_green}All $total tests passed${_nc}"
    else
        echo -e "${_red}$FAIL / $total tests failed:${_nc}"
        for msg in "${FAIL_MSGS[@]}"; do
            echo "  - $msg"
        done
    fi
    [ $FAIL -eq 0 ]
}
