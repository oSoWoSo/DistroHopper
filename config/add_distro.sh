#!/bin/bash
TMP_DIR="/tmp"
yad --form --field="Pretty name" "" --field="Name" "" --field="Releases" "" --field="Editions" "" --field="URL" "" --field="ISO" "" --field="Hash" "" > ${TMP_DIR}/template.tmp


PRETTY_NAME="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f1)"
NAME="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f2)"
RELEASES="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f3)"
EDITIONS="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f4)"
URL="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f5)"
ISO="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f6)"
HASH="$(cat ${TMP_DIR}/template.tmp | cut -d'|' -f7)"
echo "    $NAME)           PRETTY_NAME=$PRETTY_NAME;;
" >  ${TMP_DIR}/newvm.tmp
echo "    $NAME \\
" >>  ${TMP_DIR}/newvm.tmp
echo "function releases_$NAME() {
    echo $RELEASES
}
" >>  ${TMP_DIR}/newvm.tmp
echo "function editions_$NAME() {
    echo $EDITIONS
}
" >>  ${TMP_DIR}/newvm.tmp
echo "function get_$NAME() {
    local EDITION="${1:-}"
    local HASH=""
    local ISO="$ISO"
    local URL="$URL"
    HASH=\"$(wget -q -O- "${URL}/CHECKSUM" | grep "(${ISO}" | cut -d' ' -f4)\"
    echo "${URL}/${ISO} ${HASH}"
}
" >>  ${TMP_DIR}/newvm.tmp
echo "template.tmp content:
"
cat  ${TMP_DIR}/template.tmp
echo "newvm.tmp content:
"
cat  ${TMP_DIR}/newvm.tmp
