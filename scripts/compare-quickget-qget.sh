#!/usr/bin/env bash
# compare-quickget-qget.sh - Compare upstream quickget with qget and templates

set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Comparing upstream quickget with qget/actions ==="
echo ""

# Get OS names from quickget (upstream)
echo "1. Extracting OS from upstream quickget..."
if [[ -f quickget ]]; then
    UPSTREAM_OS=$(grep -oE '^\s+[a-z][a-z0-9-]+\)' quickget 2>/dev/null | sed 's/)//;s/^[[:space:]]*//' | sort -u)
    echo "   Found UPSTREAM OS count: $(echo "$UPSTREAM_OS" | wc -l)"
else
    UPSTREAM_OS=""
    echo "   quickget not found"
fi
echo ""

# Get OS from actions/
echo "2. Extracting OS from actions/..."
if [[ -d actions ]]; then
    ACTIONS_OS=$(ls actions/ 2>/dev/null | sort -u)
    echo "   Found ACTIONS OS count: $(echo "$ACTIONS_OS" | wc -l)"
else
    ACTIONS_OS=""
    echo "   actions/ not found"
fi
echo ""

# Compare
echo "=== Comparison Results ==="
echo ""

echo "In ACTIONS but NOT in UPSTREAM:"
comm -23 <(echo "$ACTIONS_OS") <(echo "$UPSTREAM_OS") | head -20 || echo "  (none)"
echo ""

echo "In UPSTREAM but NOT in ACTIONS:"
comm -13 <(echo "$ACTIONS_OS") <(echo "$UPSTREAM_OS") | head -20 || echo "  (none)"
echo ""

# Check TODO items
echo "=== Checking TODO items ==="
if [[ -f TODO/all ]]; then
    TODO_OS=$(cut -d' ' -f1 TODO/all | sort -u)
    echo "Found $(echo "$TODO_OS" | wc -l) unique OS in TODO"
    
    echo ""
    echo "TODO OS NOT in ACTIONS:"
    comm -23 <(echo "$TODO_OS") <(echo "$ACTIONS_OS") | sort -u | head -30
fi
