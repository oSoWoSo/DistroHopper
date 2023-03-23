#!/bin/bash

source distrohopper.conf

NEWDIR="$(yad --file --directory --title="Where to save VMs?")"
VMS_DIR="$NEWDIR"

echo "VMS_DIR=\"$VMS_DIR\"
export \"VMS_DIR\"" >> distrohopper.conf

export VMS_DIR
echo "New dir is: $VMS_DIR"
