#!/usr/bin/bash

DH_CONFIG_DIR="$HOME"/.config/distrohopper
DH_CONFIG="$DH_CONFIG_DIR/distrohopper.conf"
source "$DH_CONFIG"
yad --file --directory > target
echo "It will take while..."
cd "$VMS_DIR" || exit 1
cp */*.iso "$target"
echo "Done"
