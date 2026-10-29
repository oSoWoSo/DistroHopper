#!/usr/bin/env bash
# Smoke checks for the dh launcher script

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" && cd ..

echo "[dh] syntax check..."
bash -n ./dh
echo "OK: dh passes bash -n"

if command -v shellcheck >/dev/null 2>&1; then
	echo "[dh] shellcheck..."
	shellcheck -S error ./dh
	echo "OK: dh passes shellcheck"
else
	echo "SKIP: shellcheck not installed"
fi