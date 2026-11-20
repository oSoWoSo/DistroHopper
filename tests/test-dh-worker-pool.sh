#!/usr/bin/env bash
# A fast worker must refill a slot while an older, slow worker is still busy.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
source <(awk '/^run_in_terminal$/ {exit} {print}' "$REPO/dh")
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
SCRIPT_DIR="$WORK/source"
DH_CONFIG_DIR="$WORK/config"
DH_ICON_DIR="$WORK/icons"
DH_NULL=/dev/null
DH_RENEW_JOBS=2
mkdir -p "$SCRIPT_DIR" "$DH_CONFIG_DIR" "$DH_ICON_DIR"
printf '#!/usr/bin/env bash\nprintf "slow\\nfast\\nthird\\n"\n' > "$SCRIPT_DIR/qget"
chmod +x "$SCRIPT_DIR/qget"
renew_supported_vm() {
 printf 'start %s\n' "$1" >> "$WORK/events"
 if [[ $1 == slow ]]; then sleep 0.6; else sleep 0.05; fi
 printf 'end %s\n' "$1" >> "$WORK/events"
}
renew_ready_vms() { printf 'ready\n' >> "$WORK/events"; }
renew_supported_vms
/usr/bin/python3 - "$WORK/events" <<'PY'
import sys
lines = open(sys.argv[1]).read().splitlines()
assert lines.index('end fast') < lines.index('start third') < lines.index('end slow'), lines
active = peak = 0
for line in lines:
    if line.startswith('start '):
        active += 1
    elif line.startswith('end '):
        active -= 1
    else:
        assert line == 'ready' and active == 0, lines
    peak = max(active, peak)
assert active == 0 and peak == 2, lines
assert len(lines) == 7, lines
print('OK: finished workers refill slots immediately without exceeding the concurrency limit')
PY
