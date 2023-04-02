#!/bin/bash

key=$((RANDOM % 9000 + 1000))
yad --plug="$key" --tabnum=1 --monitor --icons --borders=0 --icon-size=46 --item-width=76 --form --no-buttons --text-align=center \
 --field="Help!!Show this help and exit":fbtn "$HELP" \
 --field="Set VMs Directory:2!!Set default directory where VMs are stored":fbtn "$DIR" \
 --field="!Enter new language string" "${lang:-$lang}" \
 --field="Install DistroHopper:3!!Install DistroHopper":fbtn "$INSTALL" \
 --field="Portable mode:4!Portable mode":fbtn "$MODE" \
 --field="Supported!!Update supported VMs":fbtn "$SUPPORTED" \
 --field="Ready!!Update ready to run VMs":fbtn "$READY" \
 --field="Tui!!Run terminal user interface (TUI)":fbtn "$TUI" \
 --field="Add!!Add new distro to quickget":fbtn "$ADD" \
 --field="Sort!!Sort functions in quickget":fbtn "$SORT" \
 --field="Push!!Push changed quickget to quickemu project #todo":fbtn "$PUSH" \
 --field="Copy!!Copy all ISOs to target dir (for Ventoy)":fbtn "$COPY" \
 --field="Translate DistroHopper!!Translate DistroHopper":fbtn "$TRANSLATE" \
 --field="Test!!Work in Progress":fbtn "$TEST" \
 --field="ne!!XXX":fbtn "$NEXT" \
 --button="Exit":0 &
yad --dynamic --notebook --key="$key" --monitor --listen --window-icon="$DH_ICON_DIR"/hop.svg \
 --width=900 --height=900 --no-buttons --title="DistroHopper" --tab="Advanced"
VAR1="$?"
echo "  DEBUG: VAR1 = $VAR1"
echo $?
