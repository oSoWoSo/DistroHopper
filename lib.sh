#!/usr/bin/env bash
#
# lib.sh — shared functions for web-create and web-deploy
#
# Author: zenobit <zen@duck.com>
# License: MIT
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Colored output — gum if available, ANSI fallback
# Bordered: _r _re _g _b _y (messages, errors)
# Inline:   _red _green _blue _yel (for use inside printf/echo)
# ---------------------------------------------------------------------------
if command -v gum &>/dev/null; then
	_r() {
		gum style --border rounded --border-foreground "#e50203" --padding "0 1" "${@}"
	}
	_re() {
		gum style --border rounded --border-foreground "#e50203" --padding "0 1" "${@}"
		exit 1
	}
	_g() {
		gum style --border rounded --border-foreground "#14a113" --padding "0 1" "$@"
	}
	_b() {
		gum style --border rounded --border-foreground "#004EFB" --padding "0 1" "$@"
	}
	_y() {
		gum style --border rounded --border-foreground "#fdde13" --padding "0 1" "$@"
	}
	_header() {
		local text green red yellow
		text="${1}"
		red=$(gum style --border rounded --border-foreground "#e50203" --padding "0 1" "$text")
		yellow=$(gum style --border rounded --border-foreground "#fdde13" --padding "0 1" "$red")
		green=$(gum style --border rounded --border-foreground "#14a113" --padding "0 1" "$yellow")
		echo "$green"
	}
	_footer() {
		local text green red yellow
		text="${1}"
		green=$(gum style --border rounded --border-foreground "#14a113" --padding "0 1" "$text")
		yellow=$(gum style --border rounded --border-foreground "#fdde13" --padding "0 1" "$green")
		red=$(gum style --border rounded --border-foreground "#e50203" --padding "0 1" "$yellow")
		echo "$red"
	}
	_red() { gum style --foreground "#e50203" "$1"; }
	_green() { gum style --foreground "#14a113" "$1"; }
	_blue() { gum style --foreground "#004EFB" "$1"; }
	_yel() { gum style --foreground "#fdde13" "$1"; }
else
	_g() { echo -e "${GREEN}${1}${NC}"; }
	_r() { echo -e "${RED}${1}${NC}"; }
	_re() {
		echo -e "${RED}${1}${NC}" >&2
		exit 1
	}
	_b() { echo -e "${BLUE}${1}${NC}"; }
	_y() { echo -e "${YELLOW}${1}${NC}"; }
	_header() { echo -e "\n${RED}${1}${NC}\n"; }
	_footer() { echo -e "\n${RED}${1}${NC}\n"; }
	_red() { printf "${RED}%s${NC}" "$1"; }
	_green() { printf "${GREEN}%s${NC}" "$1"; }
	_blue() { printf "${BLUE}%s${NC}" "$1"; }
	_yel() { printf "${YELLOW}%s${NC}" "$1"; }
fi

export -f _r _re _g _b _y _red _green _blue _yel

# ---------------------------------------------------------------------------
# Config file helpers — single KEY=value file, bash-sourceable
# ---------------------------------------------------------------------------

# config_set KEY VALUE FILE  — upsert a key in a bash-sourceable config file
config_set() {
	local key="$1" val="$2" file="$3"
	mkdir -p "$(dirname "$file")"
	if grep -q "^${key}=" "$file" 2>/dev/null; then
		sed -i "s|^${key}=.*|${key}=${val}|" "$file"
	else
		echo "${key}=${val}" >>"$file"
	fi
}

export -f config_set

# ---------------------------------------------------------------------------
# Interactive wrappers — gum if available, plain read fallback
# ---------------------------------------------------------------------------
_confirm() {
	if command -v gum &>/dev/null; then
		gum confirm "$@"
	else
		echo -e "${YELLOW}${1}${NC}"
		echo "Press Enter to continue, anything else to quit..."
		read -r -n 1 -s key
		[[ "$key" == '' ]]
	fi
}

_input() {
	if command -v gum &>/dev/null; then
		gum input --placeholder "$1"
	else
		echo -e "${YELLOW}${1}${NC}"
		read -r value
		echo "$value"
	fi
}

_write() {
	if command -v gum &>/dev/null; then
		gum write --placeholder "$1"
	else
		echo -e "${YELLOW}${1} (finish with empty line):${NC}"
		local lines=""
		while IFS= read -r line; do
			[ -z "$line" ] && break
			lines+="$line"$'\n'
		done
		echo "$lines"
	fi
}

_choose() {
	if command -v gum &>/dev/null; then
		gum choose "$@"
	else
		echo -e "${YELLOW}Choose action:${NC}"
		local i=1
		for opt in "$@"; do
			echo "  $i) $opt"
			((i++))
		done
		read -r choice
		echo "${@:$choice:1}"
	fi
}

# qget functions

# ---------------------------------------------------------------------------
# Error functions
# ---------------------------------------------------------------------------
error_specify_os() {
	_re "Please specify an OS argument."
	echo "Usage: qget <os> [<release>] [<edition>]"
	echo "Run 'qget --list' to see available OSes."
}

error_specify_release() {
	_re "Please specify a release for ${1}."
	echo "Usage: qget ${1} <release> [<edition>]"
	echo "Run 'qget --list ${1}' to see available releases."
}

error_not_supported_release() {
	_re "Release '${2}' is not supported for ${1}."
	echo "Run 'qget --list ${1}' to see available releases."
}

error_not_supported_lang() {
	_re "Language '${1}' is not supported."
	echo "Run 'qget --list' to see supported languages."
}

error_not_supported_argument() {
	_re "Unknown argument: ${1}"
	echo "Run 'qget --help' to see available options."
}

error_unable_to_create_dir() {
	_re "Unable to create directory: ${1}"
	echo "Reason: ${2}"
}

error_not_supported_image() {
	_re "Image format '${1}' is not supported."
	echo "Supported formats: qcow2, raw, vdi"
}

# ---------------------------------------------------------------------------
# Web functions
# ---------------------------------------------------------------------------
function web_pipe() {
	curl --disable --silent --location "${1}"
}

function web_pipe_json() {
	curl --disable --silent --location --header "Accept: application/json" "${1}"
}

# Download a file from the web
function web_get() {
	local CHECK=""
	local HEADERS=()
	local URL="${1}"
	local DIR="${2}"
	local FILE=""
	local USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"

	if [ -n "${3}" ]; then
		FILE="${3}"
	else
		FILE="${URL##*/}"
	fi

	# Process any URL redirections after the file name has been extracted
	URL=$(web_redirect "${URL}")

	# Process any headers
	while (( "$#" )); do
		if [ "${1}" == "--header" ]; then
			HEADERS+=("${1}" "${2}")
			shift 2
		else
			shift
		fi
	done

	# Test mode for ISO
	if [ "${OPERATION}" == "show" ]; then
		test_result "${OS}" "${RELEASE}" "${EDITION}" "${URL}"
		exit 0
	elif [ "${OPERATION}" == "test" ]; then
		CHECK=$(web_check "${URL}" && echo "PASS" || echo "FAIL")
		test_result "${OS}" "${RELEASE}" "${EDITION}" "${URL}" "${CHECK}"
		exit 0
	elif [ "${OPERATION}" == "download" ]; then
		DIR="$(pwd)"
	fi

	if [ "${DIR}" != "$(pwd)" ] && ! mkdir -p "${DIR}" 2>/dev/null; then
		error_unable_to_create_dir
	fi

	if [[ ${OS} != windows && ${OS} != macos && ${OS} != windows-server ]]; then
		echo $"Downloading ${PRETTY} ${RELEASE} ${EDITION}"
		echo $"- URL: ${URL}"
		echo "- PATH: ${PWD}/${DIR}/${FILE}"
	fi

	if ! curl --disable --progress-bar --location --output "${DIR}/${FILE}" --continue-at - --user-agent "${USER_AGENT}" "${HEADERS[@]}" -- "${URL}"; then
		echo $"ERROR! Failed to download ${URL} with curl."
		rm -f "${DIR}/${FILE}"
	fi
}

# Check if a URL needs to be redirected and return the final URL
function web_redirect() {
	local REDIRECT_URL=""
	local URL="${1}"
	REDIRECT_URL=$(curl --silent --location --head --max-time 10 --write-out '%{url_effective}' --output /dev/null "${URL}" 2>/dev/null)
	if [ -n "${REDIRECT_URL}" ] && [ "${REDIRECT_URL}" != "${URL}" ]; then
		echo "${REDIRECT_URL}"
	else
		echo "${URL}"
	fi
}

# Check if a URL is reachable
function web_check() {
	local HEADERS=()
	local URL="${1}"
	while (( "$#" )); do
		if [ "${1}" == "--header" ]; then
			HEADERS+=("${1}" "${2}")
			shift 2
		else
			shift
		fi
	done
	curl --disable --silent --location --head --output /dev/null --fail --connect-timeout 30 --max-time 30 --retry 3 "${HEADERS[@]}" "${URL}"
}

# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------
cleanup() {
	rm -f "${1}" || return $?
}

is_valid_language() {
	local lang="${1}"
	[[ "$lang" =~ ^(en|cs|de|es|fr|hu|it|ja|ko|nl|pl|pt|ru|sv|tr|zh)$ ]]
}

handle_missing() {
	if [ -z "${1}" ]; then
		_re "Missing required value for ${2}"
		exit 1
	fi
}

validate_release() {
	local os="${1}"
	local release="${2}"
	local valid_releases
	valid_releases=$(qget --list "$os" 2>/dev/null | grep -oP "^\d+\.\d+|^\d+")
	echo "$valid_releases" | grep -qx "$release"
}

test_result() {
	if [ $? -eq 0 ]; then
		_g "OK"
	else
		_r "FAILED"
		return 1
	fi
}

test_all() {
	local total=0
	local passed=0
	local failed=0
	for test in "$@"; do
		((total++))
		if eval "$test" >/dev/null 2>&1; then
			((passed++))
		else
			((failed++))
		fi
	done
	echo "Results: $passed/$total passed, $failed/$total failed"
	[ $failed -eq 0 ]
}

function check_hash() {
	local iso=""
	local hash=""
	local hash_algo=""
	local sig="${3:-}"
	local key_id="${4:-}"
	if [ "${OPERATION}" == "download" ]; then
		iso="${1}"
	else
		iso="${VM_PATH}/${1}"
	fi
	if [[ -n "$sig" && ( -n "$key_id" || -n "${GPG:-}" ) ]]; then
		check_signature "$iso" "$sig" "${key_id:-${GPG:-}}"
	elif [[ -n "${GPG:-}" && -n "${SUMS_URL:-}" ]]; then
		local auto_sig
		auto_sig=$(mktemp)
		if curl --disable --silent --location --fail -o "${auto_sig}" "${SUMS_URL}.asc" 2>/dev/null \
		|| curl --disable --silent --location --fail -o "${auto_sig}" "${SUMS_URL}.gpg" 2>/dev/null; then
			check_signature "${iso}" "${auto_sig}" "${GPG}"
		else
			echo $"WARNING! GPG set but no .asc/.gpg signature found at ${SUMS_URL}"
		fi
		rm -f "${auto_sig}"
	fi
	hash="${2}"
	case ${#hash} in
		32) hash_algo=md5sum;;
		40) hash_algo=sha1sum;;
		64) hash_algo=sha256sum;;
		128) hash_algo=sha512sum;;
		*) echo $"WARNING! Can't guess hash algorithm, not checking ${iso} hash."
			return;;
	esac
	echo -n $"Checking ${iso} with ${hash_algo}... "
	if ! echo "${hash} ${iso}" | ${hash_algo} --check --status; then
		status="FAIL"
		echo $"ERROR!"
		echo $"${iso} doesn't match ${hash}. Try running 'qget' again."
		table_add_row "$OS" "amd64" "$RELEASE" "$EDITION" "$iso" "$status"
		exit 1
	else
		status="PASS"
		echo $"Good!"
		table_add_row "$OS" "amd64" "$RELEASE" "$EDITION" "$iso" "$status"
	fi
}

function zsync_get() {
	local CHECK=""
	local DIR="${2}"
	local FILE="${1##*/}"
	local OUT=""
	local URL="${1}"
	if [ "${OPERATION}" == "show" ]; then
		test_result "${OS}" "${RELEASE}" "${EDITION}" "${URL}"
		exit 0
	elif [ "${OPERATION}" == "test" ]; then
		CHECK=$(web_check "${URL}" && echo "PASS" || echo "FAIL")
		test_result "${OS}" "${RELEASE}" "${EDITION}" "${URL}" "${CHECK}"
		exit 0
	elif command -v zsync &>/dev/null; then
		if [ -n "${3}" ]; then
			OUT="${3}"
		else
			OUT="${FILE}"
		fi
		if ! mkdir -p "${DIR}" 2>/dev/null; then
			error_unable_to_create_dir
		fi
		echo $"Downloading ${PRETTY} ${RELEASE} ${EDITION} from ${URL}"
		if ! zsync "${URL/https/http}.zsync" -i "${DIR}/${OUT}" -o "${DIR}/${OUT}" 2>/dev/null; then
			echo $"ERROR! Failed to download ${URL/https/http}.zsync"
			exit 1
		fi
		if [ -e "${DIR}/${OUT}.zs-old" ]; then
			rm "${DIR}/${OUT}.zs-old"
		fi
	else
		echo $"INFO: zsync not found, falling back to curl"
		if [ -n "${3}" ]; then
			web_get "${1}" "${2}" "${3}"
		else
			web_get "${1}" "${2}"
		fi
	fi
}

function make_vm_config() {
	local CONF_FILE=""
	local IMAGE_FILE=""
	local ISO_FILE=""
	if [ "${OPERATION}" == "download" ]; then
		exit 0
	fi
	IMAGE_FILE="${1}"
	ISO_FILE="${2}"

	if [ "${OS}" == 'custom' ]; then
		GUEST="${CUSTOM_OS}"
		IMAGE_TYPE="${CUSTOM_IMAGE_TYPE}"
	fi
	if [ -z "$GUEST" ]; then
		GUEST="linux"
	fi
	if [ -z "${IMAGE_TYPE}" ]; then
		IMAGE_TYPE="iso"
	fi

	CONF_FILE="${VM_PATH}.conf"

	if [ ! -e "${CONF_FILE}" ]; then
		echo $"Making ${CONF_FILE}"
		cat << EOF > "${CONF_FILE}"
#!${QUICKEMU} --vm
guest_os="${GUEST}"
disk_img="${VM_PATH}/disk.qcow2"
${IMAGE_TYPE}="${VM_PATH}/${IMAGE_FILE}"
EOF
		echo $" - Setting ${CONF_FILE} executable"
		chmod u+x "${CONF_FILE}"
		if [ -n "${ISO_FILE}" ]; then
			echo "fixed_iso=\"${VM_PATH}/${ISO_FILE}\"" >> "${CONF_FILE}"
		fi
		if declare -F config_ &>/dev/null; then
			config_
		fi
		if [ "${OPERATION}" == ui ]; then
			echo
			gum confirm $"Run new ${OS} VM?" && quickemu --vm "${CONF_FILE}"
		fi
	fi
	echo -e $"\nTo start your ${PRETTY} virtual machine run:"
	if [ "${OS}" == "slint" ]; then
		echo -e $"    quickemu --vm ${CONF_FILE}\nTo start Slint with braille support run:\n    quickemu --vm --braille --display sdl ${CONF_FILE}"
	else
		echo "    quickemu --vm ${CONF_FILE}"
	fi
	echo
	unset GUEST IMAGE_TYPE
}

os_support() {
	local os="${1}"
	qget --list "$os" 2>/dev/null | grep -q "$release"
}

# qget wrappers for TUI scripts
qget_list_os() {
	"${SCRIPT_DIR}/qget" --list-os "${@}" 2>/dev/null
}

qget_show() {
	local os="${1}"
	"${SCRIPT_DIR}/qget" --show "$os" 2>/dev/null
}

qget_download() {
	local os="${1}"
	local release="${2}"
	local edition="${3:-}"
	local arch="${4:-x86_64}"
	if [ -n "$edition" ]; then
		"${SCRIPT_DIR}/qget" --arch "$arch" "$os" "$release" "$edition"
	else
		"${SCRIPT_DIR}/qget" --arch "$arch" "$os" "$release"
	fi
}

# Optional fallback to system quickget if installed
qget_or_quickget() {
	if command -v quickget >/dev/null 2>&1; then
		quickget "${@}"
	elif [ -x "${SCRIPT_DIR}/qget" ]; then
		"${SCRIPT_DIR}/qget" "${@}"
	else
		_re "Neither qget nor quickget found"
		exit 1
	fi
}

# Shortcut for qget (uses lib.sh or quickget fallback)
qget() {
	qget_or_quickget "${@}"
}

# Public directory for OS info files
PUBLIC_DIR="${PUBLIC_DIR:-${SCRIPT_DIR:-.}/public}"
export PUBLIC_DIR

export -f error_specify_os error_specify_release error_not_supported_release \
	error_not_supported_lang error_not_supported_argument \
	error_unable_to_create_dir error_not_supported_image \
	web_pipe web_pipe_json web_get web_redirect web_check \
	cleanup is_valid_language handle_missing validate_release \
	test_result test_all check_hash zsync_get make_vm_config os_support \
	qget_list_os qget_show qget_download qget_or_quickget

# List all OS with releases and editions
#qget --list

detect_capabilities() {
	HAS_CHAFA=0
	HAS_NERD_FONT=0
	command -v chafa >/dev/null && HAS_CHAFA=1
	if command -v fc-match &>/dev/null; then
		fc-match monospace 2>/dev/null | grep -qi 'nerd\|NF' && HAS_NERD_FONT=1
	fi
	# Kitty and WezTerm bundle nerd fonts
	[[ -n "${KITTY_WINDOW_ID}" || "${TERM}" == "xterm-kitty" || -n "${WEZTERM_PANE}" ]] && HAS_NERD_FONT=1
	export HAS_CHAFA HAS_NERD_FONT
}

# ---------------------------------------------------------------------------
# VM management helpers — shared by q and any future VM UI scripts
# ---------------------------------------------------------------------------

# Populate global array $vms with only valid quickemu .conf files
load_vm_confs() {
	vms=()
	shopt -s nullglob
	for _c in *.conf; do
		grep -ql 'guest_os=\|quickemu --vm' "$_c" 2>/dev/null && vms+=("$_c")
	done
	shopt -u nullglob
}

# Print basenames (without .conf) of valid quickemu configs in cwd
list_vm_conf_names() {
	shopt -s nullglob
	for _c in *.conf; do
		grep -ql 'guest_os=\|quickemu --vm' "$_c" 2>/dev/null && echo "${_c%.conf}"
	done
	shopt -u nullglob
}

# Echo path to the primary disk image for the VM named $chosen
get_vm_disk() {
	local conf="${chosen}.conf"
	local disk
	disk=$(grep '^disk_img=' "$conf" 2>/dev/null | head -1 | cut -d'"' -f2)
	[ -z "$disk" ] && disk="${chosen}/disk.qcow2"
	echo "$disk"
}

# Show qemu-img info for the selected VM (uses gum; sets $chosen via gum_choose_VM)
disk_info() {
	gum_choose_VM || return
	local disk
	disk=$(get_vm_disk)
	if [ ! -f "$disk" ]; then
		gum style --foreground 1 "No disk found: $disk"
		return
	fi
	gum style --border rounded "Disk: $disk"
	qemu-img info "$disk"
	echo
	printf "[enter] to continue "
	read -r
}

# List snapshots on $1 (disk path)
snapshot_list() {
	qemu-img snapshot -l "$1" 2>/dev/null
}

# Interactive snapshot create/delete UI for the selected VM
snapshot_manage() {
	gum_choose_VM || return
	local disk
	disk=$(get_vm_disk)
	if [ ! -f "$disk" ]; then
		gum style --foreground 1 "No disk found: $disk"
		return
	fi
	while true; do
		gum style --border rounded "Snapshots: $chosen"
		snapshot_list "$disk"
		echo
		local action
		action=$(printf 'create\ndelete\nback' | gum choose --header="Snapshot action")
		case "$action" in
		create)
			local tag
			tag=$(gum input --placeholder "snapshot name (empty = timestamp)")
			[ -z "$tag" ] && tag=$(date +%Y%m%d-%H%M%S)
			if qemu-img snapshot -c "$tag" "$disk"; then
				gum style --foreground 2 "Snapshot '$tag' created."
			else
				gum style --foreground 1 "Failed to create snapshot."
			fi
			;;
		delete)
			local snaps snap
			snaps=$(qemu-img snapshot -l "$disk" 2>/dev/null | awk 'NR>2 && NF{print $2}')
			if [ -z "$snaps" ]; then
				gum style --foreground 1 "No snapshots to delete."
				continue
			fi
			snap=$(echo "$snaps" | gum choose --header="Choose snapshot to delete")
			[ -z "$snap" ] && continue
			gum confirm "Delete snapshot '$snap'?" &&
				qemu-img snapshot -d "$snap" "$disk" &&
				gum style --foreground 2 "Deleted '$snap'."
			;;
		back | '') break ;;
		esac
	done
}

# Compact disk (convert to new qcow2, keeping a timestamped backup)
disk_compact() {
	gum_choose_VM || return
	local disk
	disk=$(get_vm_disk)
	if [ ! -f "$disk" ]; then
		gum style --foreground 1 "No disk found: $disk"
		return
	fi
	local free_kb disk_kb
	free_kb=$(df -k . 2>/dev/null | awk 'NR==2{print $4}')
	disk_kb=$(du -k "$disk" 2>/dev/null | cut -f1)
	if [[ -n "$free_kb" && -n "$disk_kb" && "$free_kb" -lt "$disk_kb" ]]; then
		gum style --foreground 1 "Not enough free space for backup (need ~${disk_kb}K, have ${free_kb}K)."
		return
	fi
	gum confirm "Compact '$disk'? A backup (.bak.qcow2) will be created." || return
	local backup="${disk}.$(date +%Y%m%d-%H%M%S).bak.qcow2"
	if mv "$disk" "$backup"; then
		gum style --foreground 3 "Backup: $backup"
		printf "Compacting... "
		if qemu-img convert -O qcow2 "$backup" "$disk"; then
			gum style --foreground 2 "Done. Disk compacted."
		else
			gum style --foreground 1 "Compact failed — restore: mv '$backup' '$disk'"
		fi
	else
		gum style --foreground 1 "Failed to create backup."
	fi
}

# Disk management sub-menu (disk info / snapshots / compact)
show_menu_disk() {
	while true; do
		local action
		action=$(printf 'disk info\nsnapshots\ncompact disk\nback' | gum choose --header="Disk management")
		case "$action" in
		'disk info') disk_info ;;
		'snapshots') snapshot_manage ;;
		'compact disk') disk_compact ;;
		back | '') break ;;
		esac
	done
}

# Prevent two instances of the same script from running simultaneously
# Usage: multi_instance_check  (uses $tmpdir or /tmp, $USER, and $0 basename)
multi_instance_check() {
	local lockfile="${tmpdir:-/tmp}/$(basename "$0")-${USER}.lock"
	if [ -f "$lockfile" ]; then
		local pid
		pid=$(cat "$lockfile" 2>/dev/null)
		if kill -0 "$pid" 2>/dev/null; then
			gum style --foreground 3 "Warning: another instance of $(basename "$0") is already running (PID $pid)"
			gum confirm "Continue anyway?" || exit 1
		fi
	fi
	echo $$ >"$lockfile"
	trap 'rm -f "$lockfile"' EXIT
}

export -f load_vm_confs list_vm_conf_names get_vm_disk disk_info snapshot_list \
	snapshot_manage disk_compact show_menu_disk multi_instance_check

TABLE_ROWS=()

table_clear() {
	TABLE_ROWS=()
}

table_add_row() {
	local os="$1" arch="$2" release="$3" edition="$4" url="$5" status="$6"
	local row

	row=$(printf "| %-12s | %-6s | %-10s | %-16s | %-40s | %-6s |" "$os" "$arch" "$release" "$edition" "$url" "$status")

	for i in "${!TABLE_ROWS[@]}"; do
		if [[ "${TABLE_ROWS[$i]}" == *"$url"* ]]; then
			TABLE_ROWS[$i]="$row"
			return
		fi
	done

	TABLE_ROWS+=("$row")
}

table_write() {
	local output="${1:-./TODO/all}"
	local rows_count="${#TABLE_ROWS[@]}"

	if [ "$rows_count" -eq 0 ]; then
		return
	fi

	{
		echo "### $(date '+%Y-%m-%d')"
		printf "| %-12s | %-6s | %-10s | %-16s | %-40s | %-6s |\n" "OS" "Arch" "Release" "Edition" "URL" "Status"
		printf "|-------------|------|-----------|------------------|----------------------------------------|--------|\n"

		for row in "${TABLE_ROWS[@]}"; do
			echo "$row"
		done

		echo
	} >>"$output"

	TABLE_ROWS=()
}

function table_summary() {
	local os="${1}"
	local pass=0 fail=0
	for row in "${TABLE_ROWS[@]}"; do
		[[ "$row" == *"$os"* ]] || continue
		[[ "$row" == *"| PASS"* ]] && ((pass++)) || ((fail++))
	done
	if [ "$fail" -gt 0 ]; then
		printf "AVAILABILITY: %s — %d PASS, %d FAIL\n" "$os" "$pass" "$fail"
	fi
}

export -f table_clear table_add_row table_write table_summary

# ---------------------------------------------------------------------------
# OS iteration dispatch — default + template overrides
# ---------------------------------------------------------------------------
function _emit_entry() {
	local OS="$1" ARCH="$2" RELEASE="$3" EDITION="$4" URL="$5" OPERATION="$6" PUBLIC_DIR="$7"
	local STATUS="OK"
	if [ "${OPERATION}" == "test" ]; then
		STATUS=$(web_check "${URL}" && echo "PASS" || echo "FAIL")
		table_add_row "$OS" "$ARCH" "$RELEASE" "$EDITION" "$URL" "$STATUS"
	fi

	# Human-readable progress line
	printf "%-5s %-13s %-10s %-10s %-16s %-30s\n" \
		"${STATUS}" "${OS}" "${ARCH}" "${RELEASE}" "${EDITION}" "${URL}" \
		| tee -a "${PUBLIC_DIR}/tmp_${OS}"

	# Structured data (consumed by write_output).
	# Empty EDITION → "-" so bash `read` doesn't collapse adjacent tabs.
	printf '%s\t%s\t%s\t%s\t%s\n' \
		"${ARCH}" "${RELEASE}" "${EDITION:--}" "${URL}" "${STATUS}" \
		>> "${PUBLIC_DIR}/tmp_${OS}.dat"
}

function get_entries_() {
	local OS="$1" ARCH="$2" RELEASE="$3" OPERATION="$4" PUBLIC_DIR="$5" TEMPLATES_DIR="$6"
	if [[ $(type -t "editions_") == function ]]; then
		for EDITION in $(editions_); do
			. "${TEMPLATES_DIR}/${OS}"
			local URL
			URL=$(get_ | cut -d' ' -f1 | head -n 1)
			_emit_entry "${OS}" "${ARCH}" "${RELEASE}" "${EDITION}" "${URL}" "${OPERATION}" "${PUBLIC_DIR}"
		done
	else
		local URL
		URL=$(get_ | cut -d' ' -f1 | head -n 1)
		_emit_entry "${OS}" "${ARCH}" "${RELEASE}" "" "${URL}" "${OPERATION}" "${PUBLIC_DIR}"
	fi
}
export -f _emit_entry get_entries_

# ---------------------------------------------------------------------------
# Architecture name mapping
# Templates use Debian-style names (amd64, arm64, i386, ppc64el, s390x,
# riscv64, armv7, armhf, x86, i686, i586, loongarch64). Upstream URLs often
# need the qemu/kernel-style name (x86_64, aarch64, ppc64le, ...).
# Pass dh-style ARCH and get the upstream name back.
# ---------------------------------------------------------------------------
_qarch_to_upstream() {
	case "${1}" in
		amd64)       echo x86_64 ;;
		arm64)       echo aarch64 ;;
		ppc64el)     echo ppc64le ;;
		x86)         echo x86 ;;
		i386|i686|i586|armv7|armhf|riscv64|s390x|loongarch64) echo "${1}" ;;
		*)           echo "${1}" ;;
	esac
}
export -f _qarch_to_upstream

# ---------------------------------------------------------------------------
# HTTP cache — memoize web_pipe / web_check for the duration of one OS run.
# Cache lives in $_WEB_CACHE_DIR (set by _iterate_os); when unset, no caching.
# Keys: sha256 of "${METHOD}\t${URL}". Values: response body (web_pipe) or
# exit status file (web_check). The cache survives across worker subshells
# because it's a filesystem directory, but is wiped between OSes.
# ---------------------------------------------------------------------------
_web_cache_key() {
	printf '%s\t%s' "${1}" "${2}" | sha256sum | cut -d' ' -f1
}

_web_cache_get_body() {
	local key="${1}"
	[ -n "${_WEB_CACHE_DIR}" ] || return 1
	local f="${_WEB_CACHE_DIR}/${key}.body"
	[ -s "${f}" ] || return 1
	cat "${f}"
}

_web_cache_put_body() {
	local key="${1}"
	[ -n "${_WEB_CACHE_DIR}" ] || return 0
	cat >"${_WEB_CACHE_DIR}/${key}.body"
}

_web_cache_get_status() {
	local key="${1}"
	[ -n "${_WEB_CACHE_DIR}" ] || return 2
	local f="${_WEB_CACHE_DIR}/${key}.status"
	[ -f "${f}" ] || return 2
	return "$(cat "${f}")"
}

_web_cache_put_status() {
	local key="${1}" rc="${2}"
	[ -n "${_WEB_CACHE_DIR}" ] || return 0
	echo "${rc}" >"${_WEB_CACHE_DIR}/${key}.status"
}
export -f _web_cache_key _web_cache_get_body _web_cache_put_body \
	_web_cache_get_status _web_cache_put_status

# ---------------------------------------------------------------------------
# Torrent / aria2 support
# ---------------------------------------------------------------------------
function torrent_get() {
	local MAGNET="${1}"
	local DIR="${2:-.}"
	if ! command -v aria2c &>/dev/null; then
		echo "INFO: aria2c not found, use 'web_get' fallback"
		return 1
	fi
	echo "Downloading via magnet link..."
	aria2c --dir="${DIR}" --seed-time=0 "${MAGNET}"
}
export -f torrent_get

# ---------------------------------------------------------------------------
# Rosette: Package manager info display
# ---------------------------------------------------------------------------
rosette_info() {
	local osname="${1}"
	if [ -z "$osname" ]; then
		echo "Usage: rosette_info <osname>"
		return 1
	fi
	
	local template_file="${TEMPLATES_DIR}/${osname}"
	if [ ! -f "$template_file" ]; then
		echo "Template not found: $osname"
		return 1
	fi
	
	# Source the template to get BASEDOF
	# shellcheck disable=SC1090
	. "$template_file"
	
	# Map BASEDOF to rosette ID
	local rosette_id=""
	local basedof_lower
	basedof_lower=$(echo "${BASEDOF:-}" | tr '[:upper:]' '[:lower:]')
	
	case "$basedof_lower" in
		*arch*)     rosette_id="arch" ;;
		*debian*|*ubuntu*) rosette_id="debian" ;;
		*void*)     rosette_id="void" ;;
		*fedora*|*rhel*|*"red hat"*) rosette_id="fedora" ;;
		*gentoo*)   rosette_id="gentoo" ;;
		*alpine*)   rosette_id="alpine" ;;
		*opensuse*|*suse*) rosette_id="opensuse" ;;
		*slackware*) rosette_id="slackware" ;;
		*nix*)      rosette_id="nix" ;;
		*)          
			echo "No package manager info available for $osname (based on: ${BASEDOF:-unknown})"
			return 0
			;;
	esac
	
	local rosette_file="${SCRIPT_DIR}/data/rosette/${rosette_id}.yaml"
	if [ ! -f "$rosette_file" ]; then
		echo "Rosette data not found: $rosette_id"
		return 1
	fi
	
	# Parse YAML with grep/sed (no external deps)
	local pkg_manager init_system
	pkg_manager=$(grep "^package_manager:" "$rosette_file" | sed 's/^package_manager: *//' | tr -d '"')
	init_system=$(grep "^init:" "$rosette_file" | sed 's/^init: *//' | tr -d '"')
	
	# Extract commands
	local install_cmd remove_cmd update_cmd search_cmd
	install_cmd=$(sed -n '/^  install:/,/^  [a-z]/p' "$rosette_file" | grep "cmd:" | sed 's/.*cmd: *//' | tr -d '"')
	remove_cmd=$(sed -n '/^  remove:/,/^  [a-z]/p' "$rosette_file" | grep "cmd:" | sed 's/.*cmd: *//' | tr -d '"')
	update_cmd=$(sed -n '/^  update:/,/^  [a-z]/p' "$rosette_file" | grep "cmd:" | sed 's/.*cmd: *//' | tr -d '"')
	search_cmd=$(sed -n '/^  search:/,/^  [a-z]/p' "$rosette_file" | grep "cmd:" | sed 's/.*cmd: *//' | tr -d '"')
	
	# Display formatted output
	echo ""
	_g "📦 Package Manager: $pkg_manager"
	[ -n "$init_system" ] && echo "   Init system: $init_system"
	echo ""
	[ -n "$install_cmd" ] && printf "   ${GREEN}install${NC}  %s\n" "$install_cmd"
	[ -n "$remove_cmd" ]  && printf "   ${GREEN}remove${NC}   %s\n" "$remove_cmd"
	[ -n "$update_cmd" ]  && printf "   ${GREEN}update${NC}   %s\n" "$update_cmd"
	[ -n "$search_cmd" ]  && printf "   ${GREEN}search${NC}   %s\n" "$search_cmd"
	echo ""
}
export -f rosette_info

