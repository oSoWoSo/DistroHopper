#!/bin/bash

echo "Updating VMs..."
QUICKEMU_VMS_DIR="$HOME/.local/share/quickemu"
CONFIG_DIR="$HOME/.config/quickemu"
ICON_DIR="$CONFIG_DIR/vms_icons"
export "QUICKEMU_VMS_DIR" "CONFIG_DIR" "ICON_DIR"
# create default dirs if they are not present
mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/vms_ready" "$CONFIG_DIR/vms_supported"
# remove desktop files (ready to run VMs)
rm "$CONFIG_DIR"/vms_ready/*
# Enter quickemu VMs dir
cd "$QUICKEMU_VMS_DIR" || exit
# check for VMs .conf files (ready to run VMs)
for vm_config_file in *.conf; do
    vm_desktop_file=$(basename "$QUICKEMU_VMS_DIR/$vm_config_file" .conf)
    # Use fuzzy matching to find the best matching icon file (ready to run VMs)
    icon_name=$(basename "$QUICKEMU_VMS_DIR/$vm_config_file" .conf | cut -d'-' -f -2)
    icon_file=$(find "$ICON_DIR" -type f -iname "${icon_name// /}.*")
    # If no icon was found, try shorter name (ready to run VMs)
    if [ -z "$icon_file" ]; then
        icon_name=$(basename "$QUICKEMU_VMS_DIR/$vm_config_file" .conf | cut -d'-' -f1)
        icon_file=$(find "$ICON_DIR" -type f -iname "${icon_name// /}.*")
    fi
    # If no icon was found, use a default icon (ready to run VMs)
    if [ -z "$icon_file" ]; then
        icon_file="$ICON_DIR/tux.svg"
    fi
    # content of desktop files (ready to run VMs)
    desktop_file_content="[Desktop Entry]
Type=Application
Name=$vm_desktop_file
Exec=quickemu -vm \"$vm_config_file\"
Icon=$icon_file
Categories=System;Virtualization;"
    # create desktop files (ready to run VMs)
    echo "$desktop_file_content" > "$CONFIG_DIR"/vms_ready/"$vm_desktop_file".desktop
done
echo "Done"
exit 0
