#!/usr/bin/env bash
# Offline regression tests for desktop regeneration; never starts the GUI.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
source <(awk '/^run_in_terminal$/ {exit} {print}' "$REPO/dh")
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
SCRIPT_DIR="$WORK/source"
DH_CONFIG_DIR="$WORK/config"
DH_CONFIG="$DH_CONFIG_DIR/config"
DH_ICON_DIR="$WORK/icons"
VMS_DIR="$WORK/VM directory"
DH_NULL=/dev/null
PATH_PREFIX="$WORK/bin"
version=1
root=''
interminal=yes
mkdir -p "$SCRIPT_DIR" "$DH_CONFIG_DIR" "$DH_ICON_DIR" "$VMS_DIR"
cat > "$SCRIPT_DIR/qget" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == --list-os ]]; then printf 'multi\nsingle\n'; exit; fi
os=${!#}
arch=x86_64
release=''
while (($#)); do
 case $1 in --arch) arch=$2; shift;; --release) release=$2; shift;; esac
 shift
done
if [[ $os == multi ]]; then
 echo 'Archs: x86_64 aarch64'
else
 echo 'Archs: x86_64'
fi
if [[ $arch == aarch64 ]]; then echo 'Releases: arm-only'; else echo 'Releases: old new'; fi
if [[ -n $release && $release != old ]]; then
 printf 'Editions: desktop\nEditionsList:\nBrazilian Portuguese\ndesktop-pro\n'
fi
echo 'Description: fixture'
EOF
chmod +x "$SCRIPT_DIR/qget"
# Launcher functions also use optional, unset desktop-entry fields.
set +u
renew_supported_vms
for os in multi single; do
 test -x "$DH_CONFIG_DIR/supported/$os.desktop"
 grep -q 'Brazilian' "$DH_CONFIG_DIR/supported/$os.desktop"
 grep -q " $os " "$DH_CONFIG_DIR/supported/$os.desktop"
 # No cross-product combination of an ARM release with x86_64.
 ! grep -q 'x86_64;arm-only' "$DH_CONFIG_DIR/supported/$os.desktop"
done
! grep -q 'aarch64;' "$DH_CONFIG_DIR/supported/single.desktop"
# Parse the actual desktop Exec using GLib, then validate the embedded shell.
/usr/bin/python3 - "$DH_CONFIG_DIR/supported" <<'PY'
import pathlib, subprocess, sys
from gi.repository import GLib
for path in pathlib.Path(sys.argv[1]).glob('*.desktop'):
    entry = GLib.KeyFile()
    entry.load_from_file(str(path), GLib.KeyFileFlags.NONE)
    command = entry.get_string('Desktop Entry', 'Exec')
    _, argv = GLib.shell_parse_argv(command)
    assert argv[:2] == ['bash', '-c'], argv
    subprocess.run(['bash', '-n', '-c', argv[2]], check=True)
    assert 'Brazilian\\ Portuguese' in argv[2], argv[2]
    assert 'x86_64\\;old\\;' in argv[2], argv[2]
    if path.stem == 'multi':
        assert 'aarch64\\;arm-only\\;' in argv[2], argv[2]
PY
# A bounded worker pool overlaps distros and waits for every worker.
renew_supported_vm() {
 printf 'start %s\n' "$1" >> "$WORK/workers.log"
 sleep 0.15
 printf 'end %s\n' "$1" >> "$WORK/workers.log"
 [[ $1 != single ]]
}
export DH_RENEW_JOBS=2
if renew_supported_vms; then
 echo 'ERROR: worker failure was not propagated' >&2
 exit 1
fi
/usr/bin/python3 - "$WORK/workers.log" <<'PY'
import sys
active = peak = 0
for line in open(sys.argv[1]):
    active += 1 if line.startswith('start ') else -1
    peak = max(peak, active)
assert active == 0
assert peak == 2, peak
PY
export DH_RENEW_JOBS=1
: > "$WORK/workers.log"
renew_supported_vms && exit 1
[ "$(head -n 2 "$WORK/workers.log" | cut -d' ' -f1 | tr '\n' ' ')" = 'start end ' ]
echo 'OK: desktop regeneration regression tests'
