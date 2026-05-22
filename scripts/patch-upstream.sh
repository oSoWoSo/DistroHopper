#!/usr/bin/env bash
# Fetch latest quickemu/quickget from upstream and apply dh patches.
set -euo pipefail

UPSTREAM_QUICKEMU="https://raw.githubusercontent.com/quickemu-project/quickemu/master/quickemu"
UPSTREAM_QUICKGET="https://raw.githubusercontent.com/quickemu-project/quickget/master/quickget"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "Fetching upstream quickemu..."
curl -fsSL "${UPSTREAM_QUICKEMU}" -o "${REPO_ROOT}/quickemu.upstream"

echo "Fetching upstream quickget..."
curl -fsSL "${UPSTREAM_QUICKGET}" -o "${REPO_ROOT}/quickget.upstream"

echo ""
echo "Upstream files saved as:"
echo "  quickemu.upstream"
echo "  quickget.upstream"
echo ""
echo "Review changes with:"
echo "  diff quickget.upstream qget"
echo "  diff quickemu.upstream quickemu"
echo ""
echo "Apply relevant upstream patches manually using:"
echo "  git diff quickget.upstream qget > dh.patch"
echo "  # cherry-pick upstream changes, re-apply dh.patch"
