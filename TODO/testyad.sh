#!/usr/bin/env bash

DH_CONFIG_DIR="/home/z/.config/dh"

_supported(){
	echo supported
}
export -f _supported

_ready() {
	echo ready
}
export -f _ready

key=$((RANDOM % 9000 + 1000))
# posible: --undecorated --fixed ontop --buttons-layout=spread edge start end center --keep-icon-size --image=IMAGE --splash
# tab 1: Ready VMs
# tab 2: Supported VMs
# tab 3: options

 #--field="Help!!Show this help and exit":fbtn "$HELP" \
 #--field="Set VMs Directory!Set default directory where VMs are stored":DIR "$DIR" \
 #--field="Language!Enter new language string" "${lang:-en}" \
 #--field="Install DistroHopper!!Install DistroHopper":fbtn "bash -c install_distrohopper" \
 #--field="Portable mode!Portable mode":fbtn "$MODE" \
 #--field="Tui!!Run terminal user interface (TUI)":fbtn "bash -c tui_run" \
 #--field="Add!!Add new distro to quickget":fbtn "alacritty --hold -e bash -c TOOL_quickget_add_distro" \
 #--field="Sort!!Sort functions in quickget":fbtn "$SORT" \
 #--field="Push!!Push changed quickget to quickemu project #todo":fbtn "$PUSH" \
 #--field="Copy!!Copy all ISOs to target dir (for Ventoy)":fbtn "$COPY" \
 #--field="Translate DistroHopper!!Translate DistroHopper":fbtn "$TRANSLATE" \
 #--field="Test!!Work in Progress":fbtn "$TEST" \

yad --plug="$key" --tabnum=1 --monitor --icons --listen --read-dir="$DH_CONFIG_DIR"/ready --sort-by-name --borders=0 --icon-size=46 --item-width=76 &
yad --plug="$key" --tabnum=2 --monitor --icons --listen --read-dir="$DH_CONFIG_DIR"/supported --sort-by-name --borders=0 --icon-size=46 --item-width=76 &
yad --plug="$key" --tabnum=3 --monitor --borders=0 --icon-size=46 --item-width=76 --columns=2 --form --text-align=center \
 --field="Supported!!Update supported VMs":fbtn 'bash -c "_supported"' \
 --field="Ready!!Update ready to run VMs":fbtn 'bash -c "_ready"' \
 --field="About!!Show info about DistroHopper":fbtn "bash -c distrohopper_about" \
 --button="Exit!exit!gtk-cancel:0" &
yad --notebook \
 --key="$key" \
 --monitor \
 --no-buttons \
 --mouse \
 --selectable-labels \
 --window-icon="$DH_ICON_DIR/hop.svg" \
 --width=900 --height=900 \
 --title="DistroHopper" \
 --tab="run VM" --tab="download VM" --tab="Options" \
 --button="Exit!exit!gtk-cancel:0"
VAR1="$?"
echo "DEBUG: Exit code = $VAR1"
return $VAR1
