#!/usr/bin/env bash
# Unit tests for dh functions

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/tests/lib.sh"

echo "=== Testing dh ==="

cd "$REPO_ROOT"

# 1. Bash syntax check
assert_cmd "dh: bash syntax valid" bash -n ./dh

# 2. Mock external dependencies before sourcing
yad()      { return 0; }
loginctl() { echo "Type=x11"; }
export -f yad loginctl

# 3. Source in test mode — only functions should be defined, nothing executed
DH_TEST_MODE=1 source ./dh 2>/dev/null
assert_eq "dh: sources in test mode (exit 0)" "0" "$?"

# 4. set_variables sets all required variables
set_variables 2>/dev/null
assert_ne "dh: DH_CONFIG_DIR is set" "" "$DH_CONFIG_DIR"
assert_ne "dh: DH_CONFIG is set"     "" "$DH_CONFIG"
assert_ne "dh: DH_ICON_DIR is set"   "" "$DH_ICON_DIR"
assert_ne "dh: VMS_DIR is set"       "" "$VMS_DIR"
assert_ne "dh: TMP_DIR is set"       "" "$TMP_DIR"
assert_ne "dh: terminal is set"      "" "$terminal"
assert_ne "dh: version is set"       "" "$version"
assert_ne "dh: replace is set"       "" "$replace"

# 5. GETTER is set to a valid value after set_variables
assert_ne "dh: GETTER is set" "" "$GETTER"
if [ "$GETTER" = "qget" ] || [ "$GETTER" = "quickget" ]; then
    pass "dh: GETTER is 'qget' or 'quickget'"
else
    fail "dh: GETTER is 'qget' or 'quickget' (got '$GETTER')"
fi

# 6. getter_list_os function exists
assert_fn_exists "dh: getter_list_os function exists" "getter_list_os"

# 7. root_check sets root to a valid privilege escalator (or empty if root)
root_check 2>/dev/null
if [ "$root" = "sudo" ] || [ "$root" = "doas" ] || [ "$root" = "" ]; then
    pass "dh: root_check sets root to valid value ('$root')"
else
    fail "dh: root_check sets root to valid value (got '$root')"
fi

# 8. wayland_check handles mocked x11 session
output=$(XDG_SESSION_ID="1" wayland_check 2>/dev/null)
assert_match "dh: wayland_check handles x11 session" "Running on X" "$output"

# 9. wayland_check handles empty session type (TTY fallback)
loginctl() { echo "Type="; }
export -f loginctl
output=$(XDG_SESSION_ID="" wayland_check 2>/dev/null)
assert_match "dh: wayland_check handles empty session type" "(Running|Not sure)" "$output"

# 10. All required functions are defined
for fn in distrohopper_about help_show first_run create_desktop_entry \
          desktop_entry_dh renew_ready renew_ready_vms renew_supported_vms \
          installation_process create_dirs root_check wayland_check set_variables; do
    assert_fn_exists "dh: function $fn exists" "$fn"
done

# 11. comment field has no stray #TODO marker
assert_cmd "dh: comment field has no #TODO" bash -c '! grep -q "comment=.*#TODO" dh'

# 12. DH_CONFIG_DIR is inside HOME
assert_match "dh: DH_CONFIG_DIR is under HOME" "^$HOME" "$DH_CONFIG_DIR"

summary
