#!/usr/bin/env bash
# Exercise generated desktop entries through both YAD parsing and Gio launch.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
source <(awk '/^run_in_terminal$/ {exit} {print}' "$REPO/dh")
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
SCRIPT_DIR="$WORK/source tools's"
DH_CONFIG_DIR="$WORK/config choices"
DH_ICON_DIR="$WORK/icons"
VMS_DIR="$WORK/VM directory's"
DH_NULL=/dev/null
version=1
mkdir -p "$SCRIPT_DIR" "$DH_CONFIG_DIR/supported" "$DH_ICON_DIR" "$VMS_DIR" "$WORK/bin" "$WORK/home"
cp "$REPO/dh" "$SCRIPT_DIR/dh"
cat > "$SCRIPT_DIR/qget" <<'EOF'
#!/usr/bin/env bash
if [[ $1 != --show ]]; then
 /usr/bin/python3 - "$@" <<'PY'
import json, os, sys
with open(os.environ['QGET_LOG'], 'w') as f:
 json.dump({'args': sys.argv[1:], 'cwd': os.getcwd()}, f)
PY
 exit
fi
arch=amd64
release=''
while (($#)); do
 case $1 in --arch) arch=$2; shift;; --release) release=$2; shift;; esac
 shift
done
echo 'Archs: amd64 arm64'
if [[ $arch == amd64 ]]; then echo 'Releases: old new-lts'; else echo 'Releases: arm-only'; fi
if [[ $release == new-lts ]]; then
 printf 'Editions: Brazilian Portuguese desktop-pro\nEditionsList:\nBrazilian Portuguese\ndesktop-pro\n'
elif [[ $release == arm-only ]]; then
 printf 'Editions: console\nEditionsList:\nconsole\n'
fi
echo 'Description: picker fixture'
EOF
cat > "$WORK/bin/yad" <<'EOF'
#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
field = next((a for a in args if a.startswith('--field=')), '')
with open(os.environ['YAD_LOG'], 'a') as f:
 f.write(json.dumps(args) + '\n')
label = field.removeprefix('--field=').removesuffix(':CB')
if label == os.environ.get('CANCEL_FIELD'):
 sys.exit(1)
value = os.environ.get('PICK_' + label.upper(), '')
sys.stdout.write(value + '\t')
EOF
chmod +x "$SCRIPT_DIR/qget" "$WORK/bin/yad"
set +u
renew_supported_vm fixture "$SCRIPT_DIR/qget"
export HOME="$WORK/home" PATH="$WORK/bin:$PATH" QGET_LOG="$WORK/qget.json" YAD_LOG="$WORK/yad.jsonl"
/usr/bin/python3 - "$DH_CONFIG_DIR/supported/fixture.desktop" "$VMS_DIR" <<'PY'
import json, os, pathlib, subprocess, sys, time
from gi.repository import Gio, GLib
path, vm_dir = map(pathlib.Path, sys.argv[1:])
key = GLib.KeyFile()
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
command = key.get_string('Desktop Entry', 'Exec')
assert '%' not in command, command
# YAD reads the key-file value, strips at the last percent sign, then uses
# shell argv parsing. This must execute the same helper as a desktop launch.
_, argv = GLib.shell_parse_argv(command)
assert argv[0] == 'bash' and argv[2] == '--download-picker', argv
assert len(argv) == 7, argv
log = pathlib.Path(os.environ['QGET_LOG'])
yad_log = pathlib.Path(os.environ['YAD_LOG'])

def run(arch, release, edition='', desktop=False, cancel=''):
    log.unlink(missing_ok=True)
    yad_log.unlink(missing_ok=True)
    os.environ.update(PICK_ARCHITECTURE=arch, PICK_RELEASE=release,
                      PICK_EDITION=edition, CANCEL_FIELD=cancel)
    if desktop:
        context = Gio.AppLaunchContext()
        for key, value in os.environ.items():
            context.setenv(key, value)
        app = Gio.DesktopAppInfo.new_from_filename(str(path))
        assert app is not None
        assert app.launch([], context)
        for _ in range(100):
            if log.exists():
                try:
                    json.loads(log.read_text())
                    break
                except json.JSONDecodeError:
                    pass
            time.sleep(0.05)
    else:
        subprocess.run(argv, check=True, timeout=10)
    dialogs = [json.loads(line) for line in yad_log.read_text().splitlines()]
    for args in dialogs:
        field = next(arg for arg in args if arg.startswith('--field='))
        assert ';' not in args[args.index(field) + 1], args
        assert field in ('--field=Architecture:CB', '--field=Release:CB', '--field=Edition:CB'), args
    return dialogs

def downloaded(arch, release, edition=''):
    data = json.loads(log.read_text())
    expected = ['--arch', arch, 'fixture', release] + ([edition] if edition else [])
    assert data['args'] == expected, data
    assert data['cwd'] == str(vm_dir), data

run('amd64', 'new-lts', 'Brazilian Portuguese')
downloaded('amd64', 'new-lts', 'Brazilian Portuguese')
dialogs = run('arm64', 'arm-only', 'console', desktop=True)
downloaded('arm64', 'arm-only', 'console')
release_dialog = next(args for args in dialogs if '--field=Release:CB' in args)
assert release_dialog[release_dialog.index('--field=Release:CB') + 1] == 'arm-only', release_dialog
run('amd64', 'old')
downloaded('amd64', 'old')
run('amd64', 'new-lts', 'desktop-pro')
downloaded('amd64', 'new-lts', 'desktop-pro')
for cancel in ['Architecture', 'Release', 'Edition']:
    run('amd64', 'new-lts', 'desktop-pro', cancel=cancel)
    assert not log.exists(), cancel
# Invalid cross-architecture releases and invalid editions never reach qget.
run('arm64', 'new-lts', 'desktop-pro')
assert not log.exists()
run('amd64', 'new-lts', 'missing-edition')
assert not log.exists()
# A single-architecture distro skips only the redundant architecture dialog.
choices = pathlib.Path(argv[4])
choices.write_text(''.join(line for line in choices.read_text().splitlines(True)
                        if line.startswith('amd64\t')))
dialogs = run('ignored', 'new-lts', 'Brazilian Portuguese')
downloaded('amd64', 'new-lts', 'Brazilian Portuguese')
assert not any('--field=Architecture:CB' in args for args in dialogs)
print('OK: generated desktop entries launch through YAD and Gio with filtered, readable pickers')
PY
