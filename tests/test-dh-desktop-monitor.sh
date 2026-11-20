#!/usr/bin/env bash
# Reproduce YAD's real Gio directory-monitor semantics without a display.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
source <(awk '/^run_in_terminal$/ {exit} {print}' "$REPO/dh")
export -f create_desktop_entry
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
/usr/bin/python3 - "$WORK" <<'PY'
import os
import pathlib
import subprocess
import sys
from gi.repository import Gio, GLib

folder = pathlib.Path(sys.argv[1])
target = folder / 'single-ready.desktop'
monitor = Gio.File.new_for_path(str(folder)).monitor_directory(Gio.FileMonitorFlags.NONE, None)
errors = []
publications = []

def changed(_monitor, file, other_file, event):
    # Match YAD icons.c: reload only on CREATED or DELETED, scanning all
    # .desktop files. CHANGED and CHANGES_DONE_HINT do not refresh icons.
    if event not in (Gio.FileMonitorEvent.CREATED, Gio.FileMonitorEvent.DELETED):
        return
    for desktop in folder.glob('*.desktop'):
        try:
            entry = GLib.KeyFile()
            entry.load_from_file(str(desktop), GLib.KeyFileFlags.NONE)
            assert entry.get_string('Desktop Entry', 'Name') == 'single-ready'
            assert entry.get_string('Desktop Entry', 'Exec') == 'true'
            assert os.access(desktop, os.X_OK), 'entry is not yet executable'
        except Exception as error:
            errors.append(str(error))
    if file.get_basename() == target.name and event == Gio.FileMonitorEvent.CREATED:
        publications.append(target.read_text())

monitor.connect('changed', changed)
env = dict(os.environ, DESKTOP_FILE=str(target), version='1.0', type='Application',
           name='single-ready', execmd='true', terminal='false')
# A delayed writer makes the old empty-file creation race deterministic.
command = 'cat() { sleep 0.3; command cat "$@"; }; create_desktop_entry'
for generation in range(2):
    previous = len(publications)
    process = subprocess.Popen(['bash', '-c', command], env=env)
    loop = GLib.MainLoop()
    def finished():
        if process.poll() is None:
            return True
        GLib.timeout_add(200, lambda: (loop.quit(), False)[1])
        return False
    GLib.timeout_add(20, finished)
    timeout = GLib.timeout_add_seconds(5, lambda: (loop.quit(), False)[1])
    loop.run()
    GLib.source_remove(timeout)
    assert process.wait(timeout=2) == 0
    assert not errors, errors
    assert len(publications) > previous, 'no reload event for the published desktop entry'
    assert '[Desktop Entry]' in publications[-1]
    assert not list(folder.glob('.dh-entry.*')), 'temporary file leaked'
monitor.cancel()
print('OK: a single ready entry is complete on its first YAD reload, including replacement')
PY
