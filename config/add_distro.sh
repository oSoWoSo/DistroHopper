#!/bin/bash

yad --form --field="Pretty name" "" --field="Name" "" --field="Releases" "" --field="Editions" "" --field="URL" "" --field="ISO" "" --field="Hash" "" > template.tmp


PRETTY_NAME="$(cat template.tmp | cut -d'|' -f1)"
NAME="$(cat template.tmp | cut -d'|' -f2)"
RELEASES="$(cat template.tmp | cut -d'|' -f3)"
EDITIONS="$(cat template.tmp | cut -d'|' -f4)"
URL="$(cat template.tmp | cut -d'|' -f5)"
ISO="$(cat template.tmp | cut -d'|' -f6)"
HASH="$(cat template.tmp | cut -d'|' -f7)"
echo "    $NAME)           PRETTY_NAME=$PRETTY_NAME;;
" > newvm.tmp
echo "    $NAME \\
" >> newvm.tmp
echo "function releases_$NAME() {
    echo $RELEASES
}
" >> newvm.tmp
echo "function editions_$NAME() {
    echo $EDITIONS
}
" >> newvm.tmp
echo "function get_$NAME() {
    local EDITION="${1:-}"
    local HASH=""
    local ISO="$ISO"
    local URL="$URL"
    HASH=\"$(wget -q -O- "${URL}/CHECKSUM" | grep "(${ISO}" | cut -d' ' -f4)\"
    echo "${URL}/${ISO} ${HASH}"
}
" >> newvm.tmp
echo "template.tmp content:
"
cat template.tmp
echo "newvm.tmp content:
"
cat newvm.tmp
