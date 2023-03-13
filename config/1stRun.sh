#!/bin/bash
source distrohopper.conf

# distrohopper first run
CONFIG_DIR="$HOME/.config/distrohopper"

# create default dirs
rm -r "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/vms_ready" "$CONFIG_DIR/vms_supported" "$CONFIG_DIR/vms_icons"

# copy icons
#cp -r vms_icons "$CONFIG_DIR/"
# copy everything to config dir
cp -r * "$CONFIG_DIR/"

# install prerequisities (Void linux)



# Install distrohopper to all users
sudo cp ../dh ../quickgui ../quicktui ../quickget ../quickemu /usr/bin/

# Renew VMs
"$CONFIG_DIR/renew.sh"
# Set VMs dir
"$CONFIG_DIR/set_dir.sh"

echo "Done"
