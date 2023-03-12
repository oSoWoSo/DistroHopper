#!/bin/bash
source config/distrohopper.conf

# distrohopper first run
CONFIG_DIR="$HOME/.config/distrohopper"

# create default dirs
mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/vms_ready" "$CONFIG_DIR/vms_supported" "$CONFIG_DIR/vms_icons"

# copy icons
cp -r config/vms_icons "$CONFIG_DIR/"

# Install distrohopper to all users
sudo cp quickgui quicktui quickget quickemu /usr/bin/
cp config/distrohopper.conf "$CONFIG_DIR/"
