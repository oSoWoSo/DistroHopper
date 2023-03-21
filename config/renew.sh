#!/bin/bash

# config path
CONFIG_DIR="$HOME/.config/distrohopper"
source "$CONFIG_DIR"/distrohopper.conf
# Renew VMs
renew_ready() {
    echo "Updating VMs..."
    # Enter ditrohopper VMs dir
    cd "$VMS_DIR" || exit
    # check for VMs .conf files (ready to run VMs)
    for vm_conf in *.conf; do
        vm_desktop=$(basename "$VMS_DIR/$vm_conf" .conf)
        # Use fuzzy matching to find the best matching icon file (ready to run VMs)
        icon_name=$(basename "$VMS_DIR/$vm_conf" .conf | cut -d'-' -f -2)
        icon_file=$(find "$ICON_DIR" -type f -iname "${icon_name// /}.*")
        # If no icon was found, try shorter name (ready to run VMs)
        if [ -z "$icon_file" ]; then
            icon_name=$(basename "$VMS_DIR/$vm_conf" .conf | cut -d'-' -f1)
            icon_file=$(find "$ICON_DIR" -type f -iname "${icon_name// /}.*")
        fi
        # If no icon was found, use a default icon (ready to run VMs)
        if [ -z "$icon_file" ]; then
            icon_file="$ICON_DIR/tux.svg"
        fi
        # content of desktop files (ready to run VMs)
        desktop_file_content="[Desktop Entry]
Type=Application
Name=$vm_desktop
Exec=sh -c 'cd \"$VMS_DIR\" && quickemu -vm \"$vm_conf\"'
Icon=$icon_file
Categories=System;Virtualization;"
    # create desktop files (ready to run VMs)
    echo "$desktop_file_content" > "$CONFIG_DIR"/ready/"$vm_desktop".desktop
    done
}

renew_supported() {
    # get supported VMs
    quickget | sed 1d | cut -d':' -f2 | grep -o '[^ ]*' > "$CONFIG_DIR/supported.md"
    while read -r get_name; do
        vm_desktop=$(echo "$get_name" | tr ' ' '_')
        releases=$(quickget "$vm_desktop" | grep 'Releases' | cut -d':' -f2 | sed 's/^ //')
        editions=$(quickget "$vm_desktop" | grep 'Editions' | cut -d':' -f2 | sed 's/^ //')
        icon_name="$ICON_DIR/$get_name"
        if [ -f "$icon_name.svg" ]; then
            icon_file="$icon_name.svg"
        elif [ -f "$icon_name.png" ]; then
            icon_file="$icon_name.png"
        else
            icon_file="$ICON_DIR/tux.svg"
        fi
        # Check if there are editions
        if [ -z "$editions" ]; then
            # Create desktop file for VMs without editions
            desktop_file_content="[Desktop Entry]
Type=Application
Name=$get_name
releases=$releases
replace=$replace
Exec=sh -c 'cd \"$VMS_DIR\" && yad --form --field=\"Release:CB\" \"${releases// /$replace}\" | cut -d\"|\" -f1 | xargs -I{} sh -c \"quickget $get_name {}\"'
Icon=$icon_file
Categories=System;Virtualization;"
            echo "$desktop_file_content" > "$CONFIG_DIR"/supported/"$vm_desktop".desktop
        else
            # Create desktop file for VMs with editions
            desktop_file_content="[Desktop Entry]
Type=Application
Name=$get_name
releases=$releases
editions=$editions
replace=$replace
Exec=sh -c 'cd \"$VMS_DIR\" && yad --form --separator=\" \" --field=\"Release:CB\" \"${releases// /$replace}\" --field=\"Edition:CB\" \"${editions// /$replace}\" | xargs -I{} sh -c \"quickget $get_name {}\"'
Icon=$icon_file
Categories=System;Virtualization;"
            echo "$desktop_file_content" > "$CONFIG_DIR"/supported/"$vm_desktop".desktop
        fi
    done < "$CONFIG_DIR"/supported.md
}

renew_supported
renew_ready

echo "Done"
