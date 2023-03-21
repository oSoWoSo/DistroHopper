#!/usr/bin/bash

CONFIG_DIR="$HOME"/.config/distrohopper
source "$CONFIG_DIR"/distrohopper.conf
yad --file --directory > target
echo "It will take while..."
cd "$VMS_DIR" || exit 1
cp */*.iso "$target"
echo "Done"
