#!/usr/bin/env bash
# Unit tests for qget functions

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/tests/lib.sh"

echo "=== Testing qget ==="

cd "$REPO_ROOT"

# 1. Bash syntax check
assert_cmd "qget: bash syntax valid" bash -n ./qget

# 2. Source in test mode - all functions must be defined without executing
QGET_TEST_MODE=1 source ./qget 2>/dev/null
assert_eq "qget: sources in test mode (exit 0)" "0" "$?"

# Provide stubs for variables required by functions under test
QUICKEMU="/usr/bin/true"
CURL=$(command -v curl 2>/dev/null || echo "/usr/bin/curl")
I18NS=()
OPERATION=""

# 3. os_support lists files from actions/
assert_fn_exists "qget: os_support function exists" "os_support"
os_list=$(os_support 2>/dev/null)
assert_ne  "qget: os_support returns non-empty list" "" "$os_list"
assert_match "qget: os_support includes alpine"  "alpine"  "$os_list"
assert_match "qget: os_support includes ubuntu"  "ubuntu"  "$os_list"
assert_match "qget: os_support includes debian"  "debian"  "$os_list"

# 4. test_result format — without edition
result=$(test_result "ubuntu" "22.04" "" "https://example.com/ubuntu.iso")
assert_match "qget: test_result includes OS-RELEASE"   "ubuntu-22.04"               "$result"
assert_match "qget: test_result includes URL"          "https://example.com"         "$result"

# 5. test_result format — with edition
result=$(test_result "debian" "12" "gnome" "https://example.com/debian.iso")
assert_match "qget: test_result includes OS-RELEASE-EDITION" "debian-12-gnome" "$result"

# 6. is_valid_language — valid entry
I18NS=("English International" "French" "German")
assert_cmd "qget: is_valid_language returns 0 for valid lang" is_valid_language "French"

# 7. is_valid_language — invalid entry
if is_valid_language "Klingon" 2>/dev/null; then
    fail "qget: is_valid_language returns 1 for invalid lang"
else
    pass "qget: is_valid_language returns 1 for invalid lang"
fi

# 8. check_hash — unknown length triggers WARNING, not ERROR
result=$(OPERATION="" check_hash "nonexistent.iso" "badlength" 2>&1 || true)
assert_match "qget: check_hash warns on unknown hash length" "WARNING" "$result"

# 9. Required utility functions are defined
for fn in web_pipe web_pipe_json web_check web_redirect web_get zsync_get make_vm_config cleanup; do
    assert_fn_exists "qget: function $fn exists" "$fn"
done

# 10. list_supported and list_csv are defined
assert_fn_exists "qget: list_supported function exists" "list_supported"
assert_fn_exists "qget: list_csv function exists"       "list_csv"

summary
