#!/bin/bash
source distrohopper.conf

# distrohopper first run
CONFIG_DIR="$HOME/.config/distrohopper"

# create default dirs
mkdir -p "$CONFIG_DIR"
sudo mkdir -p "$ICON_DIR"

# copy everything to config dir
cp -r * "$CONFIG_DIR/"
# move icons
sudo mv "$CONFIG_DIR/icons/"* "$ICON_DIR/"
rm -r "$CONFIG_DIR/icons"
# install prerequisities (Void linux)

# Install distrohopper to all users
sudo cp ../dh ../quickget ../quickemu ../macrecovery ../windowskey /usr/bin/

# Set VMs dir
"$CONFIG_DIR/set_dir.sh"

source distrohopper.conf

# Renew VMs
"$CONFIG_DIR/renew.sh"

echo "Done"
