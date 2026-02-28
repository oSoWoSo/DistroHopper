#!/usr/bin/env bash
# Tests for structure and metadata of every file in actions/

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/tests/lib.sh"

echo "=== Testing action files ==="

ACTIONS_DIR="$REPO_ROOT/actions"
file_count=0

for action_file in "$ACTIONS_DIR"/*; do
    OS=$(basename "$action_file")
    file_count=$((file_count + 1))

    # Required metadata: grep without ^ to handle case-block indentation
    for field in OSNAME PRETTY HOMEPAGE DESCRIPTION; do
        val=$(grep "${field}=" "$action_file" | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
        assert_ne "$OS: $field is set" "" "$val"
    done

    # HOMEPAGE must look like a URL
    homepage=$(grep "HOMEPAGE=" "$action_file" | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
    assert_match "$OS: HOMEPAGE is a URL" '^https?://' "$homepage"

    # Required functions (windows uses get_windows() instead of get_())
    assert_cmd "$OS: has releases_() function" grep -q 'function releases_()' "$action_file"
    assert_cmd "$OS: has get_() function" grep -q 'function get_' "$action_file"
done

echo ""
echo "Checked $file_count action files."
summary
