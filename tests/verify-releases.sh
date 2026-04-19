#!/usr/bin/env bash
# verify-releases.sh - Verify releases and editions against reality
# Checks:
# 1. Releases in templates exist on download servers
# 2. New releases exist on web but not in templates
# 3. Editions in templates exist
# 4. New editions exist on web but not in templates

set -euo pipefail

cd /home/z/8T/git/dh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if URL exists (HEAD request)
check_url() {
	local url="$1"
	curl -s -o /dev/null -w "%{http_code}" --max-time 30 "$url" 2>/dev/null | grep -q "200\|302\|301"
}

# Function to get releases from web for linuxmint
get_linuxmint_releases() {
	curl -s "https://linuxmint.com/download.php" 2>/dev/null |
		grep -oP 'href="/stable/[0-9]+\.[0-9]+"' |
		sed 's|href="/stable/||;s|"||g' | sort -Vu || echo ""
}

# Function to get releases from web for lmde
get_lmde_releases() {
	curl -s "https://linuxmint.com/download_lmde.php" 2>/dev/null |
		grep -oP 'href="/debian/[0-9]+"' |
		sed 's|href="/debian/||;s|"||g' | sort -Vu || echo ""
}

# Main verification function
verify_os() {
	local os="$1"
	local action_file="actions/${os}"

	echo -e "${BLUE}=== Verifying ${os} ===${NC}"

	if [[ ! -f "$action_file" ]]; then
		echo -e "${RED}ERROR: Action file not found: ${action_file}${NC}"
		return 1
	fi

	# Source the action file to get releases
	source "$action_file" 2>/dev/null || true

	# Get releases from template
	local template_releases
	template_releases=$(releases_ 2>/dev/null || echo "")

	if [[ -z "$template_releases" ]]; then
		echo -e "${RED}ERROR: Could not get releases for ${os}${NC}"
		return 1
	fi

	echo -e "Template releases: ${GREEN}${template_releases}${NC}"

	# Get editions if they exist
	if [[ $(type -t "editions_") == "function" ]]; then
		local template_editions
		template_editions=$(editions_ 2>/dev/null || echo "")
		echo -e "Template editions: ${GREEN}${template_editions}${NC}"
	fi

	# TODO: Add web verification for each OS
	# This would require OS-specific URL patterns

	echo -e "${YELLOW}TODO: Web verification not yet implemented for ${os}${NC}"
	echo ""
}

# Main execution
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Release Verification Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verify a few test OS
for os in linuxmint lmde debian ubuntu; do
	verify_os "$os" || true
done

echo -e "${BLUE}Verification complete!${NC}"
