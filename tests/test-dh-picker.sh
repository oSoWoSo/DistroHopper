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
os=${!#}
arch=amd64
release=''
while (($#)); do
 case $1 in --arch) arch=$2; shift;; --release) release=$2; shift;; esac
 shift
done
if [[ $os == agarimos || $os == fixed || $os == fixed-no-editions ]]; then
 echo 'Archs: x86_64'
 echo 'Releases: latest'
 if [[ $os == agarimos ]]; then
  printf 'EditionsList:\ncinnamon\nplasma\nxfce4\n'
 elif [[ $os == fixed ]]; then
  printf 'EditionsList:\ncinnamon\n'
 fi
 echo 'Description: fixed values fixture'
 exit
fi
echo 'Archs: amd64 arm64'
if [[ $arch == amd64 ]]; then echo 'Releases: old new-lts'; else echo 'Releases: arm-only'; fi
if [[ $os != no-editions && $release == new-lts ]]; then
 printf 'Editions: Brazilian Portuguese desktop-pro\nEditionsList:\nBrazilian Portuguese\ndesktop-pro\n'
 echo "Developer's Edition"
elif [[ $os != no-editions && $release == arm-only ]]; then
 printf 'Editions: console\nEditionsList:\nconsole\n'
fi
echo 'Description: picker fixture'
EOF
cat > "$WORK/bin/yad" <<'EOF'
#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
if '--error' in args:
 sys.exit(0)
labels = [label for label in ['Architecture', 'Release', 'Edition']
          if any('--field=' + label + ':' + kind in args for kind in ['CB', 'RO'])]
options, types = {}, {}
for label in labels:
 field = next(arg for arg in args if arg.startswith('--field=' + label + ':'))
 types[label] = field.rsplit(':', 1)[1]
 options[label] = args[args.index(field) + 1].split('!')
 assert types[label] == ('CB' if len(options[label]) > 1 else 'RO'), args
assert '--button=Cancel:1' in args and '--button=OK:0' in args, args
with open(os.environ['YAD_LOG'], 'a') as f:
 f.write(json.dumps({'args': args, 'options': options, 'types': types}) + '\n')
if os.environ.get('CANCEL_FIELD'):
 sys.exit(1)
values = [options[label][0] if types[label] == 'RO' else
          (os.environ.get('PICK_' + label.upper(), '') or
           ('(none)' if label == 'Edition' else '')) for label in labels]
sys.stdout.write('|'.join(values) + '|')
EOF
chmod +x "$SCRIPT_DIR/qget" "$WORK/bin/yad"
set +u
renew_supported_vm fixture "$SCRIPT_DIR/qget"
renew_supported_vm no-editions "$SCRIPT_DIR/qget"
for os in agarimos fixed fixed-no-editions; do
 renew_supported_vm "$os" "$SCRIPT_DIR/qget"
 cp "$DH_CONFIG_DIR/supported/$os.desktop" "$WORK/$os.desktop"
done
cp "$DH_CONFIG_DIR/supported/no-editions.desktop" "$WORK/no-editions.desktop"
cp "$SCRIPT_DIR/qget" "$WORK/bin/qget"
cp "$DH_CONFIG_DIR/supported/fixture.desktop" "$WORK/fixture.desktop"
# Prove this is standalone: remove the generator, source metadata and config.
rm -rf "$SCRIPT_DIR" "$DH_CONFIG_DIR"
export HOME="$WORK/home" PATH="$WORK/bin:$PATH" QGET_LOG="$WORK/qget.json" YAD_LOG="$WORK/yad.jsonl"
/usr/bin/python3 - "$WORK/fixture.desktop" "$VMS_DIR" <<'PY'
import json, os, pathlib, subprocess, sys, time
from gi.repository import Gio, GLib
path, vm_dir = map(pathlib.Path, sys.argv[1:])
key = GLib.KeyFile()
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
command = key.get_string('Desktop Entry', 'Exec')
assert '%' not in command, command
# YAD reads the key-file value, strips at the last percent sign, then uses
# shell argv parsing. The entire picker must be embedded, not a helper call.
_, argv = GLib.shell_parse_argv(command)
assert argv[:2] == ['bash', '-c'], argv
assert len(argv) == 3, argv
assert 'qget --arch' in argv[2], argv
assert '--desktop-picker' not in argv[2]
assert 'base64' not in argv[2]
log = pathlib.Path(os.environ['QGET_LOG'])
yad_log = pathlib.Path(os.environ['YAD_LOG'])

def run(arch, release, edition='', desktop=False, cancel='', status=0):
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
        result = subprocess.run(argv, timeout=10)
        assert result.returncode == status, result
    dialogs = [json.loads(line) for line in yad_log.read_text().splitlines()] if yad_log.exists() else []
    assert len(dialogs) == 1, dialogs
    for dialog in dialogs:
        args = dialog['args']
        labels = [label for label in ['Architecture', 'Release', 'Edition']
                  if "--field='" + label + ":" in argv[2]]
        for label in labels:
            field = '--field=' + label + ':' + dialog['types'][label]
            assert field in args, args
            assert ';' not in args[args.index(field) + 1], args
    return dialogs

def downloaded(arch, release, edition='', os_name='fixture'):
    data = json.loads(log.read_text())
    expected = ['--arch', arch, os_name, release] + ([edition] if edition else [])
    assert data['args'] == expected, data
    assert data['cwd'] == str(vm_dir), data

run('amd64', 'new-lts', 'Brazilian Portuguese')
downloaded('amd64', 'new-lts', 'Brazilian Portuguese')
dialogs = run('arm64', 'arm-only', 'console', desktop=True)
downloaded('arm64', 'arm-only', 'console')
assert 'arm-only' in dialogs[0]['options']['Release'], dialogs
assert 'console' in dialogs[0]['options']['Edition'], dialogs
run('amd64', 'old')
downloaded('amd64', 'old')
run('amd64', 'new-lts', 'desktop-pro')
downloaded('amd64', 'new-lts', 'desktop-pro')
run('amd64', 'new-lts', "Developer's Edition")
downloaded('amd64', 'new-lts', "Developer's Edition")
for cancel in ['Architecture', 'Release', 'Edition']:
    run('amd64', 'new-lts', 'desktop-pro', cancel=cancel)
    assert not log.exists(), cancel
# Invalid cross-architecture releases and invalid editions never reach qget.
run('arm64', 'new-lts', 'desktop-pro', status=1)
assert not log.exists()
run('amd64', 'new-lts', 'missing-edition', status=1)
assert not log.exists()
# Systems without any editions must not display an Edition field at all.
path = path.with_name('no-editions.desktop')
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
command = key.get_string('Desktop Entry', 'Exec')
_, argv = GLib.shell_parse_argv(command)
assert "--field='Edition:CB'" not in argv[2], argv
assert "edition='';" in argv[2], argv
dialogs = run('amd64', 'old')
assert '--field=Edition:CB' not in dialogs[0]['args'], dialogs
downloaded('amd64', 'old', os_name='no-editions')
# AgarimOS: show fixed x86_64/latest read-only and pick only an edition.
path = path.with_name('agarimos.desktop')
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
_, argv = GLib.shell_parse_argv(key.get_string('Desktop Entry', 'Exec'))
assert "--field='Architecture:RO'" in argv[2], argv
assert "--field='Release:RO'" in argv[2], argv
assert "--field='Edition:CB'" in argv[2], argv
dialogs = run('ignored', 'ignored', 'plasma')
assert dialogs[0]['types'] == {'Architecture': 'RO', 'Release': 'RO', 'Edition': 'CB'}, dialogs
downloaded('x86_64', 'latest', 'plasma', os_name='agarimos')
# Even when all values are fixed, require confirmation and allow cancellation.
path = path.with_name('fixed.desktop')
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
_, argv = GLib.shell_parse_argv(key.get_string('Desktop Entry', 'Exec'))
dialogs = run('ignored', 'ignored', 'ignored')
assert dialogs[0]['types'] == {'Architecture': 'RO', 'Release': 'RO', 'Edition': 'RO'}, dialogs
downloaded('x86_64', 'latest', 'cinnamon', os_name='fixed')
run('ignored', 'ignored', 'ignored', cancel='Cancel')
assert not log.exists(), 'fixed values downloaded without confirmation'
# No editions: show just the two read-only values, still requiring OK.
path = path.with_name('fixed-no-editions.desktop')
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
_, argv = GLib.shell_parse_argv(key.get_string('Desktop Entry', 'Exec'))
dialogs = run('ignored', 'ignored')
assert dialogs[0]['types'] == {'Architecture': 'RO', 'Release': 'RO'}, dialogs
downloaded('x86_64', 'latest', os_name='fixed-no-editions')
run('ignored', 'ignored', cancel='Cancel')
assert not log.exists()
print('OK: fixed values stay visible, only real choices use dropdowns, and all downloads require OK')
PY
