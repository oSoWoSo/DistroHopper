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
# The generated Exec invokes dh's headless download-picker entry point.
cp "$REPO/dh" "$SCRIPT_DIR/dh"
# Launcher functions also use optional, unset desktop-entry fields.
set +u
# A VM created after opening the GUI must appear during regeneration.
touch "$VMS_DIR/single-new.conf"
renew_supported_vms
test -x "$DH_CONFIG_DIR/ready/single-new.desktop"
# Refresh must also remove entries for configs which no longer exist.
rm "$VMS_DIR/single-new.conf"
renew_supported_vms
test ! -e "$DH_CONFIG_DIR/ready/single-new.desktop"
for os in multi single; do
 test -x "$DH_CONFIG_DIR/supported/$os.desktop"
 grep -q -- '--download-picker' "$DH_CONFIG_DIR/supported/$os.desktop"
 grep -q 'Brazilian Portuguese' "$DH_CONFIG_DIR/choices/$os.tsv"
 # No cross-product combination of an ARM release with x86_64.
 ! grep -q $'x86_64\tarm-only' "$DH_CONFIG_DIR/choices/$os.tsv"
done
! grep -q 'aarch64' "$DH_CONFIG_DIR/choices/single.tsv"
# Parse the actual desktop Exec using GLib, then validate the helper arguments.
/usr/bin/python3 - "$DH_CONFIG_DIR/supported" <<'PY'
import pathlib, sys
from gi.repository import GLib
for path in pathlib.Path(sys.argv[1]).glob('*.desktop'):
    entry = GLib.KeyFile()
    entry.load_from_file(str(path), GLib.KeyFileFlags.NONE)
    command = entry.get_string('Desktop Entry', 'Exec')
    _, argv = GLib.shell_parse_argv(command)
    assert argv[0] == 'bash' and argv[2] == '--download-picker', argv
    assert '%' not in command, command  # YAD truncates at percent signs.
    assert argv[3] == path.stem, argv
    choices = pathlib.Path(argv[4]).read_text()
    assert 'x86_64\told\t\n' in choices, choices
    if path.stem == 'multi':
        assert 'aarch64\tarm-only\t' in choices, choices
PY
# A bounded worker pool overlaps distros and waits for every worker.
renew_supported_vm() {
 printf 'start %s\n' "$1" >> "$WORK/workers.log"
 # Finish out of launch order to exercise completion-based progress.
 if [[ $1 == multi ]]; then sleep 0.3; else sleep 0.05; fi
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
# GUI progress is cleaned up on success/failure and overlapping clicks are rejected.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/yad" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GUI_LOG"
while IFS= read -r line; do
 printf '%s\n' "$line" >> "$GUI_PROGRESS_LOG"
 [[ $line == 100 ]] && exit 0
done
EOF
cat > "$WORK/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GUI_NOTIFICATIONS_LOG"
EOF
chmod +x "$WORK/bin/yad" "$WORK/bin/notify-send"
export PATH="$WORK/bin:$PATH" GUI_LOG="$WORK/gui.log" GUI_PROGRESS_LOG="$WORK/progress.log" GUI_NOTIFICATIONS_LOG="$WORK/notifications.log"
# Use the real parallel regeneration and event relay, not just a UI mock.
export DH_RENEW_JOBS=2
if renew_supported_vms_gui; then exit 1; fi
/usr/bin/python3 - "$GUI_PROGRESS_LOG" <<'PY'
import sys
lines = open(sys.argv[1]).read().splitlines()
percentages = [int(line) for line in lines if line.isdecimal()]
assert percentages == [0, 33, 66, 66, 100], percentages
assert any('1/2 completed — single' in line for line in lines), lines
assert any('2/2 completed — multi' in line for line in lines), lines
ready = next(i for i, line in enumerate(lines) if 'Refreshing ready VMs' in line)
assert lines.index('100') > ready
assert any('finished with errors' in line for line in lines)
PY
! grep -q -- '--pulsate' "$GUI_LOG"
! grep -q -- '--percentage' "$GUI_LOG"
grep -q -- '--progress' "$GUI_LOG"
# Empty distro lists still show the ready phase and reach 100 without dividing by zero.
printf 'total 0\nready\nfinished 0\n' | renew_progress_reader > "$WORK/empty-progress"
grep -q '0/0 completed' "$WORK/empty-progress"
grep -qx '100' "$WORK/empty-progress"
renew_supported_vms() { return "${RENEW_STATUS:-0}"; }
renew_supported_vms_gui
test ! -e "$DH_CONFIG_DIR/renew.lock"
grep -q 'Regeneration complete' "$GUI_PROGRESS_LOG"
export RENEW_STATUS=1
if renew_supported_vms_gui; then exit 1; fi
test ! -e "$DH_CONFIG_DIR/renew.lock"
grep -q 'finished with errors' "$GUI_PROGRESS_LOG"
mkdir "$DH_CONFIG_DIR/renew.lock"
if renew_supported_vms_gui 2> "$WORK/duplicate-click.log"; then exit 1; fi
rmdir "$DH_CONFIG_DIR/renew.lock"
grep -q 'already running' "$WORK/duplicate-click.log"
test ! -e "$GUI_NOTIFICATIONS_LOG"
echo 'OK: desktop regeneration regression tests'
