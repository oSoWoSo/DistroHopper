#!/bin/bash
QUICKEMU_VMS_DIR="$(yad --file --directory)"
export QUICKEMU_VMS_DIR
echo "New dir is: $QUICKEMU_VMS_DIR"
sed -f config 's/QUICKEMU_VMS_DIR=""/QUICKEMU_VMS_DIR="$QUICKEMU_VMS_DIR"/g'
