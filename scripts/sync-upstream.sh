#!/usr/bin/env bash
# sync-upstream.sh - Sync and compare upstream quickemu/quickget with qget templates
# Downloads upstream quickget, parses OS functions, and compares with actions/

set -euo pipefail

# Configuration
UPSTREAM_URL="https://raw.githubusercontent.com/quickemu-project/quickemu/master/quickget"
SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ACTIONS_DIR="${PROJECT_DIR}/actions"
UPSTREAM_CACHE="${TMPDIR:-/tmp}/quickget-upstream-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
SHOW_ALL=false
SHOW_MISSING=false
SHOW_EXTRA=false
SHOW_DIFF=false
FILTER_OS=""

usage() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sync and compare upstream quickemu/quickget with qget templates.

Downloads upstream quickget from GitHub and compares OS functions with
the local actions/ templates.

OPTIONS:
    --os=NAME      Filter to specific OS only
    --all          Show all comparisons (missing, extra, diff)
    --missing      Show OS only in upstream (missing in qget)
    --extra        Show OS only in qget (extra compared to upstream)
    --diff         Show detailed diff for differing implementations
    -h, --help     Show this help message

EXAMPLES:
    $(basename "$0") --all
    $(basename "$0") --missing
    $(basename "$0") --os=ubuntu --diff

EOF
	exit 0
}

log_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	--os=*)
		FILTER_OS="${1#*=}"
		shift
		;;
	--all)
		SHOW_ALL=true
		shift
		;;
	--missing)
		SHOW_MISSING=true
		shift
		;;
	--extra)
		SHOW_EXTRA=true
		shift
		;;
	--diff)
		SHOW_DIFF=true
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		log_error "Unknown option: $1"
		usage
		;;
	esac
done

# Default to --all if no options specified
if [[ "$SHOW_ALL" == "false" && "$SHOW_MISSING" == "false" && "$SHOW_EXTRA" == "false" && "$SHOW_DIFF" == "false" ]]; then
	SHOW_ALL=true
fi

# Cleanup on exit
cleanup() {
	rm -f "$UPSTREAM_CACHE"
}
trap cleanup EXIT

# Download upstream quickget
download_upstream() {
	log_info "Downloading upstream quickget from GitHub..."
	if ! curl -fsSL --connect-timeout 30 --max-time 120 -o "$UPSTREAM_CACHE" "$UPSTREAM_URL" 2>/dev/null; then
		log_error "Failed to download upstream quickget"
		exit 1
	fi
	log_success "Downloaded upstream quickget ($(wc -l <"$UPSTREAM_CACHE") lines)"
}

# Extract OS names from upstream quickget
extract_upstream_os() {
	# Extract from os_info case statement
	grep -oE '^\s+[a-z][a-z0-9_-]+\)' "$UPSTREAM_CACHE" 2>/dev/null |
		sed 's/)//;s/^[[:space:]]*//' |
		sort -u
}

# Extract function names (make_, releases_, get_)
extract_upstream_functions() {
	local os_name="$1"
	# Find functions related to this OS
	grep -oE "^(function )?(make_|releases_|get_)${os_name}\(\)" "$UPSTREAM_CACHE" 2>/dev/null |
		sed 's/^function //;s/()$//' |
		sort -u
}

# Get local qget OS names from actions/
get_local_os() {
	if [[ -d "$ACTIONS_DIR" ]]; then
		ls -1 "$ACTIONS_DIR/" 2>/dev/null | sort -u
	fi
}

# Get function count for OS in upstream
get_upstream_function_count() {
	local os_name="$1"
	extract_upstream_functions "$os_name" | wc -l
}

# Get function count for OS in local actions
get_local_function_count() {
	local os_name="$1"
	local action_file="${ACTIONS_DIR}/${os_name}"
	if [[ -f "$action_file" ]]; then
		# Count function-like patterns: make_, releases_, get_
		grep -cE '^(make_|releases_|get_)' "$action_file" 2>/dev/null || echo "0"
	else
		echo "0"
	fi
}

# Show diff for specific OS
show_os_diff() {
	local os_name="$1"
	local local_file="${ACTIONS_DIR}/${os_name}"

	echo ""
	echo "=== Diff for: ${os_name} ==="
	echo ""

	# Get upstream functions
	echo "Upstream functions:"
	extract_upstream_functions "$os_name" | sed 's/^/  /'
	echo ""

	# Get local functions
	if [[ -f "$local_file" ]]; then
		echo "Local (qget) functions:"
		grep -oE '^(make_|releases_|get_)[a-z_]*' "$local_file" 2>/dev/null | sort -u | sed 's/^/  /'
		echo ""
	else
		echo "Local: (not found)"
		echo ""
	fi

	# Function count comparison
	local up_count=$(get_upstream_function_count "$os_name")
	local local_count=$(get_local_function_count "$os_name")
	echo "Function counts - Upstream: $up_count, Local: $local_count"
}

# Main comparison logic
run_comparison() {
	log_info "Extracting OS from upstream quickget..."
	local upstream_os
	upstream_os=$(extract_upstream_os)
	local upstream_count
	upstream_count=$(echo "$upstream_os" | grep -c . || echo "0")
	log_success "Found $upstream_count OS in upstream"

	log_info "Extracting OS from local actions/..."
	local local_os
	local_os=$(get_local_os)
	local local_count
	local_count=$(echo "$local_os" | grep -c . || echo "0")
	log_success "Found $local_count OS in local actions/"

	echo ""
	echo "============================================"
	echo "Comparison Results"
	echo "============================================"
	echo ""

	# Calculate differences
	# OS only in upstream (missing from qget)
	local missing_os
	missing_os=$(comm -23 <(echo "$upstream_os") <(echo "$local_os") 2>/dev/null || echo "")

	# OS only in local qget (extra compared to upstream)
	local extra_os
	extra_os=$(comm -13 <(echo "$upstream_os") <(echo "$local_os") 2>/dev/null || echo "")

	# Common OS (for diff comparison)
	local common_os
	common_os=$(comm -12 <(echo "$upstream_os") <(echo "$local_os") 2>/dev/null || echo "")

	# Show results based on options
	if [[ "$SHOW_MISSING" == "true" || "$SHOW_ALL" == "true" ]]; then
		echo "----------------------------------------"
		echo "MISSING in qget (only in upstream):"
		echo "----------------------------------------"
		if [[ -n "$missing_os" ]]; then
			if [[ -n "$FILTER_OS" ]]; then
				echo "$missing_os" | grep "^${FILTER_OS}$" || echo "  (none matching filter)"
			else
				echo "$missing_os" | sed 's/^/  /'
			fi
		else
			echo "  (none)"
		fi
		echo ""
	fi

	if [[ "$SHOW_EXTRA" == "true" || "$SHOW_ALL" == "true" ]]; then
		echo "----------------------------------------"
		echo "EXTRA in qget (not in upstream):"
		echo "----------------------------------------"
		if [[ -n "$extra_os" ]]; then
			if [[ -n "$FILTER_OS" ]]; then
				echo "$extra_os" | grep "^${FILTER_OS}$" || echo "  (none matching filter)"
			else
				echo "$extra_os" | sed 's/^/  /'
			fi
		else
			echo "  (none)"
		fi
		echo ""
	fi

	if [[ "$SHOW_DIFF" == "true" || "$SHOW_ALL" == "true" ]]; then
		echo "----------------------------------------"
		echo "IMPLEMENTATION DIFF (common OS with differences):"
		echo "----------------------------------------"

		local has_diff=false

		# Check each common OS for differences
		while IFS= read -r os_name; do
			[[ -z "$os_name" ]] && continue
			[[ -n "$FILTER_OS" && "$os_name" != "$FILTER_OS" ]] && continue

			local up_count local_count
			up_count=$(get_upstream_function_count "$os_name")
			local_count=$(get_local_function_count "$os_name")

			if [[ "$up_count" != "$local_count" ]]; then
				has_diff=true
				if [[ "$SHOW_DIFF" == "true" ]]; then
					show_os_diff "$os_name"
				else
					echo "  $os_name: upstream=$up_count functions, local=$local_count functions"
				fi
			fi
		done <<<"$common_os"

		if [[ "$has_diff" == "false" ]]; then
			echo "  (no implementation differences found)"
		fi
		echo ""
	fi

	# Summary
	echo "============================================"
	echo "Summary:"
	echo "============================================"
	echo "  Upstream OS:  $upstream_count"
	echo "  Local OS:     $local_count"
	echo "  Missing:      $(echo "$missing_os" | grep -c . || echo "0")"
	echo "  Extra:        $(echo "$extra_os" | grep -c . || echo "0")"
	echo "  Common:       $(echo "$common_os" | grep -c . || echo "0")"
}

# Main execution
main() {
	cd "$PROJECT_DIR"

	# Check if actions directory exists
	if [[ ! -d "$ACTIONS_DIR" ]]; then
		log_error "actions/ directory not found in $PROJECT_DIR"
		exit 1
	fi

	# Download upstream
	download_upstream

	# Run comparison
	run_comparison

	log_success "Comparison complete!"
}

main "$@"
