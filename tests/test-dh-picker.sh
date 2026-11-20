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
mkdir -p "$WORK/standalone"
cp "$REPO/qget" "$REPO/lib.sh" "$WORK/standalone/"
export REAL_QGET="$WORK/standalone/qget"
cat > "$SCRIPT_DIR/qget" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == --desktop-picker* ]]; then exec "$REAL_QGET" "$@"; fi
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
import json, os, shlex, subprocess, sys
args = sys.argv[1:]
labels = ['Architecture', 'Release', 'Edition']
options = {}
for label in labels:
 field = '--field=' + label + ':CB'
 assert field in args, args
 options[label] = args[args.index(field) + 1].split('!')
selected = {label: values[0] for label, values in options.items()}
action = next(a.split('=', 1)[1] for a in args if a.startswith('--changed-action='))
updates = []
for number, label in enumerate(labels, 1):
 value = os.environ.get('PICK_' + label.upper(), '')
 if label == 'Edition' and not value:
  value = '(none)'
 selected[label] = value
 if number < 3:
  # Reproduce YAD's expand_action and appended changed-field arguments.
  cmd = action.replace('%1', shlex.quote(selected['Architecture']))
  cmd = cmd.replace('%2', shlex.quote(selected['Release']))
  output = subprocess.check_output(shlex.split(cmd) + [str(number), value], text=True)
  updates.append(output)
  for line in output.splitlines():
   field, items = line.split(':', 1)
   target = labels[int(field) - 1]
   options[target] = items.split('!')
   selected[target] = options[target][0]
with open(os.environ['YAD_LOG'], 'a') as f:
 f.write(json.dumps({'args': args, 'options': options, 'updates': updates}) + '\n')
if os.environ.get('CANCEL_FIELD'):
 sys.exit(1)
sys.stdout.write('\t'.join(selected[label] for label in labels) + '\t')
EOF
chmod +x "$SCRIPT_DIR/qget" "$WORK/bin/yad"
set +u
renew_supported_vm fixture "$SCRIPT_DIR/qget"
cp "$SCRIPT_DIR/qget" "$WORK/bin/qget"
cp "$DH_CONFIG_DIR/supported/fixture.desktop" "$WORK/fixture.desktop"
# Prove this is standalone: remove the generator, source metadata and config.
rm -rf "$SCRIPT_DIR" "$DH_CONFIG_DIR"
export HOME="$WORK/home" PATH="$WORK/bin:$PATH" QGET_LOG="$WORK/qget.json" YAD_LOG="$WORK/yad.jsonl"
/usr/bin/python3 - "$WORK/fixture.desktop" "$VMS_DIR" <<'PY'
import base64, json, os, pathlib, subprocess, sys, time
from gi.repository import Gio, GLib
path, vm_dir = map(pathlib.Path, sys.argv[1:])
key = GLib.KeyFile()
key.load_from_file(str(path), GLib.KeyFileFlags.NONE)
command = key.get_string('Desktop Entry', 'Exec')
assert '%' not in command, command
# YAD reads the key-file value, strips at the last percent sign, then uses
# shell argv parsing. This must execute the same helper as a desktop launch.
_, argv = GLib.shell_parse_argv(command)
assert argv[:2] == ['qget', '--desktop-picker'], argv
assert len(argv) == 5, argv
assert 'Brazilian Portuguese' in base64.b64decode(argv[3]).decode()
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
    dialogs = [json.loads(line) for line in yad_log.read_text().splitlines()]
    assert len(dialogs) == 1, dialogs
    for dialog in dialogs:
        args = dialog['args']
        for label in ['Architecture', 'Release', 'Edition']:
            field = '--field=' + label + ':CB'
            assert field in args, args
            assert ';' not in args[args.index(field) + 1], args
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
assert dialogs[0]['options']['Release'] == ['arm-only'], dialogs
assert dialogs[0]['options']['Edition'] == ['console'], dialogs
assert '2:arm-only\n3:console\n' in dialogs[0]['updates'], dialogs
run('amd64', 'old')
downloaded('amd64', 'old')
run('amd64', 'new-lts', 'desktop-pro')
downloaded('amd64', 'new-lts', 'desktop-pro')
for cancel in ['Architecture', 'Release', 'Edition']:
    run('amd64', 'new-lts', 'desktop-pro', cancel=cancel)
    assert not log.exists(), cancel
# Invalid cross-architecture releases and invalid editions never reach qget.
run('arm64', 'new-lts', 'desktop-pro', status=1)
assert not log.exists()
run('amd64', 'new-lts', 'missing-edition', status=1)
assert not log.exists()
# A single-architecture distro still displays all three fields together.
choices = base64.b64decode(argv[3]).decode()
choices = ''.join(line for line in choices.splitlines(True) if line.startswith('amd64\t'))
argv[3] = base64.b64encode(choices.encode()).decode()
dialogs = run('amd64', 'new-lts', 'Brazilian Portuguese')
downloaded('amd64', 'new-lts', 'Brazilian Portuguese')
assert dialogs[0]['options']['Architecture'] == ['amd64'], dialogs
print('OK: generated desktop entries launch through YAD and Gio with filtered, readable pickers')
PY
