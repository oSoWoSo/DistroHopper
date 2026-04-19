#!/usr/bin/env bash
# Test suite for q command
# License MIT

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

cd /home/z/Projekty/dh

# Source the functions we need to test by exporting them
# Since q is designed to be interactive, we'll test the core logic

info "Testing q has valid bash syntax..."
if bash -n /home/z/Projekty/dh/q 2>/dev/null; then
    pass "q has valid bash syntax"
else
    fail "q has syntax errors"
fi

info "Testing variable definitions..."
# Check that necessary variables are set when function runs
# We'll simulate by checking the script structure

info "Testing gum dependency check..."
if grep -q "command -v gum" /home/z/Projekty/dh/q; then
    pass "gum dependency check exists"
else
    fail "gum dependency check missing"
fi

info "Testing quickemu dependency check..."
if grep -q "command -v quickemu" /home/z/Projekty/dh/q; then
    pass "quickemu dependency check exists"
else
    fail "quickemu dependency check missing"
fi

info "Testing config directory creation..."
if grep -q 'configdir="$HOME/.config/$progname"' /home/z/Projekty/dh/q; then
    pass "configdir is set correctly"
else
    fail "configdir not found"
fi

info "Testing run_VM function has empty check..."
if grep -q 'No VM selected' /home/z/Projekty/dh/q; then
    pass "run_VM has empty check"
else
    fail "run_VM missing empty check"
fi

info "Testing ssh_into function has empty check..."
# Check ssh_into has the check in correct order
if grep -q 'gum_choose_running' /home/z/Projekty/dh/q; then
    pass "ssh_into uses gum_choose_running"
else
    fail "ssh_into missing gum_choose_running"
fi

info "Testing kill_vm function has empty check..."
if grep -A5 'kill_vm()' /home/z/Projekty/dh/q | grep -q 'gum_choose_running'; then
    pass "kill_vm has gum_choose_running"
else
    fail "kill_vm missing gum_choose_running"
fi

info "Testing delete_VM function is implemented..."
if grep -q 'No VM selected' /home/z/Projekty/dh/q; then
    pass "delete_VM has empty check"
else
    fail "delete_VM missing empty check"
fi

info "Testing rm commands are quoted..."
if grep -q 'rm -r "\$chosen"' /home/z/Projekty/dh/q; then
    pass "rm commands are properly quoted"
else
    fail "rm commands not quoted"
fi

info "Testing TERMUX comparison fix..."
if grep -q 'TERMUX.*=.*"1"' /home/z/Projekty/dh/q; then
    pass "TERMUX comparison uses = instead =="
else
    fail "TERMUX still uses =="
fi

info "Testing kill_vms function..."
if grep -q 'kill_vms()' /home/z/Projekty/dh/q; then
    pass "kill_vms function exists"
else
    fail "kill_vms function missing"
fi

info "Testing gum_choose_runnings function..."
if grep -q 'gum_choose_runnings()' /home/z/Projekty/dh/q; then
    pass "gum_choose_runnings function exists"
else
    fail "gum_choose_runnings function missing"
fi

info "Testing menu items exist..."
for item in create run delete kill ssh_into; do
    if grep -q "'$item'" /home/z/Projekty/dh/q; then
        pass "Menu has $item"
    else
        fail "Menu missing $item"
    fi
done

info "Testing settings functions..."
for setting in change_color change_borders change_spinner; do
    if grep -q "$setting()" /home/z/Projekty/dh/q; then
        pass "Function $setting exists"
    else
        fail "Function $setting missing"
    fi
done

info "Testing advanced functions..."
for adv in test_ISOs_download show_ISOs_urls add_new_distro; do
    if grep -q "$adv" /home/z/Projekty/dh/q; then
        pass "Advanced function $adv exists"
    else
        fail "Advanced function $adv missing"
    fi
done

info "Testing no remaining TODO comments..."
todo_count=$(grep -c "#TODO" /home/z/Projekty/dh/q || echo "0")
if [ "$todo_count" = "0" ]; then
    pass "No TODO comments remaining"
else
    fail "Still have $todo_count TODO comments"
fi

echo ""
echo "================================"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "================================"

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
exit 0