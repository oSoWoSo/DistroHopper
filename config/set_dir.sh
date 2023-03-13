#!/bin/bash
source distrohopper.conf
NEWDIR="$(yad --file --directory --title="Where to save VMs?")"
QUICKEMU_VMS_DIR="$NEWDIR"
export QUICKEMU_VMS_DIR
echo "New dir is: $QUICKEMU_VMS_DIR"
#cat distrohopper.conf | grep 'QUICKEMU_VMS_DIR='
#sed -f distrohopper.conf --posix -E 's/QUICKEMU_VMS_DIR="$HOME/.local/share/quickemu"/QUICKEMU_VMS_DIR="$QUICKEMU_VMS_DIR"/g'
