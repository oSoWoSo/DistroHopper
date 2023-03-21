#!/bin/bash
TMP_DIR="/tmp"
yad --form --field="Pretty name" "" --field="Name" "" --field="Releases" "" --field="Editions" "" --field="URL" "" --field="ISO" "" --field="Checksum file" "" > ${TMP_DIR}/template.tmp

PRETTY_NAME="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f1)"
NAME="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f2)"
RELEASES="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f3)"
EDITIONS="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f4)"
URL="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f5)"
ISO="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f6)"
CHECKSUM_FILE="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f7)"
echo "    $NAME)           PRETTY_NAME=$PRETTY_NAME;;
" >  ${TMP_DIR}/${NAME}.tmp
{ echo "    $NAME \\
"; echo "function releases_$NAME() {
    echo $RELEASES
}
"; echo "function editions_$NAME() {
    echo $EDITIONS
}
"; echo "function get_$NAME() {
    local EDITION="${1:-}"
    local HASH=""
    local ISO="$ISO"
    local URL="$URL"
    HASH=\"$(wget -q -O- "${URL}/${CHECKSUM_FILE}" | grep "(${ISO}" | cut -d' ' -f4)\"
    echo \"${URL}/${ISO} ${HASH}\"
}
"; } >> ${TMP_DIR}/${NAME}.tmp

meld ${TMP_DIR}/${NAME}.tmp ../quickget
