#!/bin/bash

yad --form --field="Name" "" --field="Releases" "" --field="Editions" "" --field="URL" "" --field="ISO" ""

# little script for adding distros to quickemu
# This version use desktop files and notebook

#TODO ADD_PRETTY_NAME_${DISTRO}
    ${DISTRO})            PRETTY_NAME="VX Linux";;

#TODO ADD_NAME_${DISTRO}
    ${DISTRO} \

#TODO ADD_releases_${DISTRO} function
function releases_${DISTRO}() {
    echo 6.1 5.0 4.2 4.1 4.0
}
#TODO ADD_editions_${DISTRO} function
function editions_${DISTRO}() {
    echo
}
#TODO ADD_get_${DISTRO} function
function get_${DISTRO}() {
    local HASH=""
    local ISO=""
    local URL="https://github.com/dessington/${DISTRO}/releases/download/${RELEASE}"

    if [ "$RELEASE" == "4.0" ]; then
        ISO="vx-linux-4.0-qt.iso"
    else
        ISO="vx-linux-${RELEASE}.iso"
    fi
    echo "${URL}/${ISO} ${HASH}"
}

function get_voidpup() {
    local HASH=""
    local URL=""
    local TMPURL=""

    TMPURL=$(wget -q -S -O- --max-redirect=0 "https://sourceforge.net/projects/vpup/files/latest/download" 2>&1 | grep -i Location | cut -d' ' -f4)
    URL=${TMPURL%\?*}
    echo "${URL} ${HASH}"
}
