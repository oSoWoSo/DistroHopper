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
		echo -e "${YELLOW}Choose action:${NC}" >&2
		local i=1
		for opt in "$@"; do
			echo "  $i) $opt" >&2
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
# Usage: web_pipe URL [additional curl options...]
function web_pipe() {
	local url="${1}"
	shift
	curl --disable --silent --location "$@" "${url}"
}

function web_pipe_json() {
	curl --disable --silent --location --header "Accept: application/json" "${1}"
}

# Emit Atom feed entries as slug<TAB>title<TAB>version<TAB>homepage<TAB>ISO URL<TAB>icon.
atom_feed_entries() {
	local feed_url="${1}"
	web_pipe "${feed_url}" | awk '
		BEGIN { RS = "<entry>" }
		{
			slug = title = version = homepage = iso_url = icon = id = ""
			if (!match($0, /<id>https:\/\/distrowatch\.com\/[^<]*<\/id>/)) {
				next
			}
			id = substr($0, RSTART + 4, RLENGTH - 9)
			slug = id
			sub(/^.*\//, "", slug)
			if (match($0, /<title>[^<]*<\/title>/)) {
				title = substr($0, RSTART + 7, RLENGTH - 15)
				version = title
				if (sub(/^.* /, "", version) == 0) {
					version = "-"
				}
			}
			if (match($0, /&lt;a href="[^"]+"&gt;Homepage&lt;\/a&gt;/)) {
				homepage = substr($0, RSTART, RLENGTH)
				sub(/^&lt;a href="/, "", homepage)
				sub(/"&gt;Homepage&lt;\/a&gt;$/, "", homepage)
			}
			if (match($0, /&lt;a href="[^"]+\.iso[^"]*"&gt;ISO&lt;\/a&gt;/)) {
				iso_url = substr($0, RSTART, RLENGTH)
				sub(/^&lt;a href="/, "", iso_url)
				sub(/"&gt;ISO&lt;\/a&gt;$/, "", iso_url)
			}
			if (match($0, /&lt;img src="[^"]+"/)) {
				icon = substr($0, RSTART, RLENGTH)
				sub(/^&lt;img src="/, "", icon)
				sub(/"$/, "", icon)
			}
			if (slug != "" && title != "") {
				printf "%s\t%s\t%s\t%s\t%s\t%s\n", slug, title, version, \
					(homepage == "" ? "-" : homepage), (iso_url == "" ? "-" : iso_url), \
					(icon == "" ? "-" : icon)
			}
		}'
}

# Emit version<TAB>ISO URL rows for one DistroWatch slug in an Atom feed.
atom_feed_iso_entries() {
	local feed_url="${1}" distro_slug="${2}"
	atom_feed_entries "${feed_url}" |
		awk -F '\t' -v slug="${distro_slug}" '$1 == slug && $5 != "-" { print $3 "\t" $5 }'
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
	while (("$#")); do
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
		local _path="${DIR}/${FILE}"
		[[ "${_path}" != /* ]] && _path="${PWD}/${_path}"
		echo "- PATH: ${_path}"
	fi

	if ! curl --disable --fail --progress-bar --location --output "${DIR}/${FILE}" --continue-at - --user-agent "${USER_AGENT}" "${HEADERS[@]}" -- "${URL}"; then
		echo $"ERROR! Failed to download ${URL} with curl."
		rm -f "${DIR}/${FILE}"
		return 1
	fi
}

# Check if a URL is reachable
function web_check() {
	local HEADERS=()
	local URL="${1}"
	while (("$#")); do
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
		iso="$(find_iso "${1}")"
	fi
	if [[ -n "$sig" && (-n "$key_id" || -n "${GPG:-}") ]]; then
		check_signature "$iso" "$sig" "${key_id:-${GPG:-}}"
	elif [[ -n "${GPG:-}" && -n "${SUMS_URL:-}" ]]; then
		local auto_sig
		auto_sig=$(mktemp)
		if curl --disable --silent --location --fail -o "${auto_sig}" "${SUMS_URL}.asc" 2>/dev/null ||
			curl --disable --silent --location --fail -o "${auto_sig}" "${SUMS_URL}.gpg" 2>/dev/null; then
			check_signature "${iso}" "${auto_sig}" "${GPG}"
		else
			echo $"WARNING! GPG set but no .asc/.gpg signature found at ${SUMS_URL}"
		fi
		rm -f "${auto_sig}"
	fi
	hash="${2}"
	case ${#hash} in
	32) hash_algo=md5sum ;;
	40) hash_algo=sha1sum ;;
	64) hash_algo=sha256sum ;;
	128) hash_algo=sha512sum ;;
	*)
		echo $"WARNING! Can't guess hash algorithm, not checking ${iso} hash."
		return
		;;
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

# Return the directory where a downloaded image file should live.
# When ISO_DIR is set, .iso files go to the shared ISO directory; everything
# else stays in the per-VM directory so template extract_() hooks keep working.
function image_target_dir() {
	if [ -n "${ISO_DIR:-}" ] && [[ "${1}" == *.iso || "${1}" == *.ISO ]]; then
		echo "${ISO_DIR}"
	else
		echo "${VM_PATH}"
	fi
}

# Locate a downloaded image file, whichever directory it currently lives in.
# Used by check_hash(), which may run before make_vm_config relocates an ISO
# into the shared ISO_DIR (e.g. ubuntu downloads + hashes inside its template).
function find_iso() {
	local name="${1}"
	if [ -f "$(image_target_dir "${name}")/${name}" ]; then
		echo "$(image_target_dir "${name}")/${name}"
	elif [ "${ISO_DIR:-}" ] && [ -f "${VM_PATH}/${name}" ]; then
		echo "${VM_PATH}/${name}"
	else
		echo "$(image_target_dir "${name}")/${name}"
	fi
}

# Ensure a downloaded .iso physically resides in ISO_DIR before the .conf is
# written. Covers templates that download into VM_PATH internally (ubuntu,
# windows, reactos extract_...). Non-iso images (disk_img, img=) are untouched.
function ensure_iso_in_shared_dir() {
	local name="${1}"
	if [ -n "${ISO_DIR:-}" ] && [[ "${name}" == *.iso || "${name}" == *.ISO ]]; then
		if [ ! -f "${ISO_DIR}/${name}" ] && [ -f "${VM_PATH}/${name}" ]; then
			mkdir -p "${ISO_DIR}"
			echo $" - Moving ${name} to shared ISO directory ${ISO_DIR}"
			mv "${VM_PATH}/${name}" "${ISO_DIR}/${name}"
		fi
	fi
}

function make_vm_config() {
	local CONF_FILE=""
	local IMAGE_FILE=""
	local ISO_FILE=""
	# OPERATION is not set when make_vm_config is called outside a qget run.
	if [ "${OPERATION:-}" == "download" ]; then
		exit 0
	fi
	IMAGE_FILE="${1:-}"
	ISO_FILE="${2:-}"

	if [ "${OS}" == 'custom' ]; then
		GUEST="${CUSTOM_OS}"
		IMAGE_TYPE="${CUSTOM_IMAGE_TYPE}"
	fi
	if [ -z "$GUEST" ]; then
		GUEST="linux"
	fi
	# IMAGE_TYPE="none" means the image itself is the system disk, so no
	# separate boot medium is attached.
	if [ "${IMAGE_TYPE}" == "none" ]; then
		IMAGE_TYPE=""
	elif [ -z "$IMAGE_TYPE" ]; then
		IMAGE_TYPE="iso"
	fi

	mkdir -p "${VM_PATH}" || return 1
	CONF_FILE="${VM_PATH}.conf"

	ensure_iso_in_shared_dir "${IMAGE_FILE}"
	[ -n "${ISO_FILE}" ] && ensure_iso_in_shared_dir "${ISO_FILE}"

	if [ ! -e "${CONF_FILE}" ]; then
		echo $"Making ${CONF_FILE}"
		local DISK_PATH="${VM_PATH}/disk.qcow2"
		local IMAGE_PATH="$(image_target_dir "${IMAGE_FILE}")/${IMAGE_FILE}"
		if [ "${RAMDISK:-}" == "yes" ]; then
			DISK_PATH="${RAMDISK_DIR:-/dev/shm/quickemu}/${VM_PATH}/disk.qcow2"
			mkdir -p "$(dirname "${DISK_PATH}")" || return 1
			echo $" - Disk will be created in RAM (tmpfs): ${DISK_PATH}"
		fi
		if [ -n "${ISO_DIR:-}" ] && [[ "${IMAGE_FILE}" == *.iso || "${IMAGE_FILE}" == *.ISO ]]; then
			mkdir -p "${ISO_DIR}"
		fi
		local ARCH_LINE=""
		if [ -n "${ARCH:-}" ] && [ "${ARCH}" != "amd64" ]; then
			ARCH_LINE="arch=\"$(_qarch_to_upstream "${ARCH}")\""
		fi
		local IMAGE_LINE=""
		[ -n "${IMAGE_TYPE}" ] && IMAGE_LINE="${IMAGE_TYPE}=\"${IMAGE_PATH}\""
		cat <<EOF >"${CONF_FILE}"
#!${QUICKEMU:-quickemu} --vm
guest_os="${GUEST}"
disk_img="${DISK_PATH}"
${ARCH_LINE:+${ARCH_LINE}
}${IMAGE_LINE}
EOF
		echo $" - Setting ${CONF_FILE} executable"
		chmod u+x "${CONF_FILE}"
		if [ -n "${ISO_FILE}" ]; then
			echo "fixed_iso=\"$(image_target_dir "${ISO_FILE}")/${ISO_FILE}\"" >>"${CONF_FILE}"
		fi
		if declare -F config_ &>/dev/null; then
			config_
		fi
		if [ "${OPERATION:-}" == ui ]; then
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

# Is the given OS supported? Uses the generated metadata, so it works
# without a network connection.
os_support() {
	local os="${1}"
	[ -n "${os}" ] || return 1
	[ -f "${PUBLIC_DIR}/${os}" ]
}

# Update the programs from their git checkout.
#
# The front-ends call this from their settings menu. It only works when the
# programs were run from a git checkout; an installed copy has no repository
# to pull from, which is reported instead of failing silently.
update_programs() {
	local repo="${1:-${SCRIPT_DIR:-.}}"
	if ! command -v git >/dev/null 2>&1; then
		echo "ERROR! git is not installed, cannot update." >&2
		return 1
	fi
	if ! git -C "${repo}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "ERROR! ${repo} is not a git checkout, cannot update." >&2
		return 1
	fi
	local branch
	branch="$(git -C "${repo}" branch --show-current)"
	if [ -z "${branch}" ]; then
		echo "ERROR! ${repo} is on a detached HEAD, cannot update." >&2
		return 1
	fi
	echo "Updating ${progname:-DistroHopper} from branch ${branch}..."
	if ! git -C "${repo}" pull --ff-only; then
		echo "ERROR! The update failed. Resolve the local changes first." >&2
		return 1
	fi
	echo "Update done. The new version is used the next time you start."
	return 0
}

# Is the given release available for the given OS? The release list comes
# from the generated metadata, so it covers the non-numeric release names
# too ("latest", "v3.24", "45_Beta", "daily-live", ...).
validate_release() {
	local os="${1}"
	local release="${2}"
	local valid_releases=""
	if [ -f "${PUBLIC_DIR}/${os}" ]; then
		valid_releases=$(sed -n 's/^RELEASES="\(.*\)"$/\1/p' "${PUBLIC_DIR}/${os}" | head -n 1)
	fi
	if [ -z "${valid_releases}" ]; then
		valid_releases=$(qget --list "$os" 2>/dev/null | tail -n +2 | cut -d' ' -f2)
	fi
	[[ " ${valid_releases} " == *" ${release} "* ]]
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

# Use the repository qget exclusively.
qget_or_quickget() {
	if [ -x "${SCRIPT_DIR}/qget" ]; then
		"${SCRIPT_DIR}/qget" "${@}"
	elif command -v qget >/dev/null 2>&1; then
		qget "${@}"
	else
		_re "qget not found"
		exit 1
	fi
}

# Shortcut for qget (uses lib.sh or quickget fallback)
qget() {
	qget_or_quickget "${@}"
}

append_default_vm_config() {
	local default_config="${1}"
	local vm_config="${2}"
	if [ -f "${default_config}" ]; then
		echo 'Adding default values to config...'
		cat "${default_config}" >>"${vm_config}"
	fi
}

# Public directory for OS info files
PUBLIC_DIR="${PUBLIC_DIR:-${SCRIPT_DIR:-.}/public}"
export PUBLIC_DIR

# Directory holding the dynamic per-distro templates
TEMPLATES_DIR="${TEMPLATES_DIR:-${SCRIPT_DIR:-.}/templates}"
export TEMPLATES_DIR

# ---------------------------------------------------------------------------
# Static release/edition metadata
#
# templates/<os> holds the *dynamic* implementation: releases_(), editions_()
# and arch_() scrape upstream pages to discover what exists right now.
#
# public/<os> is the *generated* counterpart: the same functions plus the
# releases and editions that were parsed at generation time, stored as the
# RELEASES / EDITIONS variables (and their per-architecture overrides).
#
# Runtime code must not need the network to answer "which releases exist?".
# dh_metadata_* below answers that from the static variables when they are
# present, and only falls back to the live template functions when the static
# data is missing (e.g. a distro that was never generated).
# ---------------------------------------------------------------------------

# dh_metadata_ready — true when <os> has generated static metadata.
dh_metadata_ready() {
	local os="${1}"
	[ -n "${os}" ] || return 1
	[ -f "${PUBLIC_DIR}/${os}" ] || return 1
	grep -q '^RELEASES=' "${PUBLIC_DIR}/${os}" 2>/dev/null
}

# dh_metadata_releases — static release list for <os> [arch].
# Prints the per-architecture release list when one is recorded, otherwise
# the shared RELEASES value. Returns 1 when no static data exists.
dh_metadata_releases() {
	local os="${1}" arch="${2:-}"
	local file="${PUBLIC_DIR}/${os}"
	local var=""
	[ -f "${file}" ] || return 1
	if [ -n "${arch}" ]; then
		var="RELEASES_${arch}"
		if [ -n "${!var:-}" ]; then
			printf '%s\n' "${!var}"
			return 0
		fi
	fi
	local releases=""
	releases="$(sed -n 's/^RELEASES="\(.*\)"$/\1/p' "${file}" | head -n 1)"
	[ -n "${releases}" ] || return 1
	printf '%s\n' "${releases}"
}

# dh_metadata_editions — static edition list for <os> [arch].
# Returns 1 when the distro declares no editions at all.
dh_metadata_editions() {
	local os="${1}" arch="${2:-}"
	local file="${PUBLIC_DIR}/${os}"
	local var=""
	[ -f "${file}" ] || return 1
	if [ -n "${arch}" ]; then
		var="EDITIONS_${arch}"
		if [ -n "${!var:-}" ]; then
			printf '%s\n' "${!var}"
			return 0
		fi
	fi
	local editions=""
	editions="$(sed -n 's/^EDITIONS="\(.*\)"$/\1/p' "${file}" | head -n 1)"
	[ -n "${editions}" ] || return 1
	printf '%s\n' "${editions}"
}

# dh_metadata_arches — static architecture list for <os>.
dh_metadata_arches() {
	local os="${1}"
	local file="${PUBLIC_DIR}/${os}"
	[ -f "${file}" ] || return 1
	local arches=""
	arches="$(sed -n 's/^QEMU_ARCH="\(.*\)"$/\1/p' "${file}" | head -n 1)"
	[ -n "${arches}" ] || return 1
	printf '%s\n' "${arches}"
}

export -f dh_metadata_ready dh_metadata_releases dh_metadata_editions dh_metadata_arches update_programs

# ---------------------------------------------------------------------------
# Load one distro's generated metadata (public/<os>).
#
# Sourcing a distro file defines its helper functions (releases_, editions_,
# arch_, get_, config_, extract_). When several distros are handled in one
# shell — as qget --list does — those definitions leak into the next distro:
# a distro without an editions_() function would still answer with the
# previous distro's editions. Unset the helpers first so each distro is
# described only by its own file.
# ---------------------------------------------------------------------------
dh_load_os() {
	local os="${1}"
	local file=""
	if [ "${DH_USE_TEMPLATES:-no}" == "yes" ]; then
		file="${TEMPLATES_DIR}/${os}"
	else
		file="${PUBLIC_DIR}/${os}"
	fi
	[ -f "${file}" ] || return 1
	unset -f releases_ editions_ arch_ get_ config_ extract_ languages_ 2>/dev/null
	# Per-architecture overrides are distro specific (EDITIONS_amd64, ...).
	# Without clearing them, a distro that has no override of its own would
	# keep the previous distro's values.
	unset RELEASES EDITIONS RELEASES_amd64 RELEASES_arm64 RELEASES_i386 \
		RELEASES_i586 RELEASES_i686 RELEASES_armhf RELEASES_armv7 \
		RELEASES_loongarch64 RELEASES_ppc64el RELEASES_riscv64 RELEASES_s390x \
		RELEASES_x86 \
		EDITIONS_amd64 EDITIONS_arm64 EDITIONS_i386 EDITIONS_i586 EDITIONS_i686 \
		EDITIONS_armhf EDITIONS_armv7 EDITIONS_loongarch64 EDITIONS_ppc64el \
		EDITIONS_riscv64 EDITIONS_s390x EDITIONS_x86 2>/dev/null
	# shellcheck source=/dev/null
	. "${file}"
	return 0
}
export -f dh_load_os

# ---------------------------------------------------------------------------
# Mode-independent accessors for the distro metadata.
#
# In the default (static) mode the answers come from the variables that were
# parsed at generation time. In template mode the discovery functions are
# used, so the answers always reflect the current upstream state.
# ---------------------------------------------------------------------------

# dh_releases — release list of the currently loaded distro.
dh_releases() {
	local arch="${1:-${ARCH:-}}"
	if [ "${DH_USE_TEMPLATES:-no}" == "yes" ]; then
		if [[ $(type -t releases_) == function ]]; then
			releases_
			return 0
		fi
		return 1
	fi
	# The per-architecture release list wins when it was recorded.
	if [ -n "${arch}" ]; then
		local per_arch="RELEASES_${arch}"
		if [ -n "${!per_arch:-}" ]; then
			printf '%s\n' "${!per_arch}"
			return 0
		fi
	fi
	printf '%s\n' "${RELEASES:-}"
}

# dh_editions — edition list of the currently loaded distro for $1 (release).
dh_editions() {
	local release="${1:-}"
	local arch="${2:-${ARCH:-}}"
	if [ "${DH_USE_TEMPLATES:-no}" == "yes" ]; then
		if [[ $(type -t editions_) == function ]]; then
			RELEASE="${release}" ARCH="${arch}" editions_
			return 0
		fi
		return 1
	fi
	# Release-scoped editions. The map is keyed by "arch|release"; when no
	# architecture was selected, try every known architecture and use the
	# first match.
	local scoped=""
	if [ -n "${release}" ] && declare -F _release_editions_ >/dev/null; then
		if [ -n "${arch}" ]; then
			scoped=$(_release_editions_ "${arch}|${release}")
		else
			local candidate
			for candidate in ${QEMU_ARCH:-}; do
				scoped=$(_release_editions_ "${candidate}|${release}")
				[ -n "${scoped}" ] && break
			done
		fi
	fi
	if [ -n "${scoped}" ]; then
		printf '%s\n' "${scoped}"
		return 0
	fi
	local per_arch="EDITIONS_${arch}"
	if [ -n "${!per_arch:-}" ]; then
		printf '%s\n' "${!per_arch}"
		return 0
	fi
	printf '%s\n' "${EDITIONS:-}"
}
export -f dh_releases dh_editions

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
	# Windows/macOS rows intentionally contain metadata without a download URL.
	local ALLOW_EMPTY="${8:-false}"
	local STATUS="OK"
	local HAS_DOWNLOAD_URL=false
	[[ "${URL}" =~ ^https?://[^[:space:]]+$ ]] && HAS_DOWNLOAD_URL=true

	if [ "${OPERATION}" == "test" ]; then
		if [[ "${ALLOW_EMPTY}" != true && "${HAS_DOWNLOAD_URL}" != true ]]; then
			STATUS="FAIL"
		else
			STATUS=$(web_check "${URL}" && echo "PASS" || echo "FAIL")
		fi
		table_add_row "$OS" "$ARCH" "$RELEASE" "$EDITION" "$URL" "$STATUS"
	elif [[ "${ALLOW_EMPTY}" != true && "${HAS_DOWNLOAD_URL}" != true ]]; then
		STATUS="WARN"
	fi

	# Human-readable progress line
	printf "%-5s %-13s %-10s %-10s %-16s %-30s\n" \
		"${STATUS}" "${OS}" "${ARCH}" "${RELEASE}" "${EDITION}" "${URL}" |
		tee -a "${PUBLIC_DIR}/tmp_${OS}"

	# Structured data (consumed by write_output).
	# Empty EDITION or URL → "-" so bash `read` doesn't collapse adjacent tabs.
	printf '%s\t%s\t%s\t%s\t%s\n' \
		"${ARCH}" "${RELEASE}" "${EDITION:--}" "${URL:--}" "${STATUS}" \
		>>"${PUBLIC_DIR}/tmp_${OS}.dat"
}

function _default_get_entries_() {
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

function get_entries_() {
	_default_get_entries_ "$@"
}
export -f _emit_entry _default_get_entries_ get_entries_

# ---------------------------------------------------------------------------
# Architecture name mapping
# Templates use Debian-style names (amd64, arm64, i386, ppc64el, s390x,
# riscv64, armv7, armhf, x86, i686, i586, loongarch64). Upstream URLs often
# need the qemu/kernel-style name (x86_64, aarch64, ppc64le, ...).
# Pass dh-style ARCH and get the upstream name back.
# ---------------------------------------------------------------------------
_qarch_to_upstream() {
	case "${1}" in
	amd64) echo x86_64 ;;
	arm64) echo aarch64 ;;
	ppc64el) echo ppc64le ;;
	x86) echo x86 ;;
	i386 | i686 | i586 | armv7 | armhf | riscv64 | s390x | loongarch64) echo "${1}" ;;
	*) echo "${1}" ;;
	esac
}
export -f _qarch_to_upstream

# Inverse of _qarch_to_upstream: normalise upstream/quickemu-style architecture
# names (x86_64, aarch64, ppc64le) to the dh-style names used by templates
# (amd64, arm64, ppc64el) at the CLI/config boundary.
_upstream_to_qarch() {
	case "${1}" in
	x86_64) echo amd64 ;;
	aarch64) echo arm64 ;;
	ppc64le) echo ppc64el ;;
	*) echo "${1}" ;;
	esac
}
export -f _upstream_to_qarch

# ---------------------------------------------------------------------------
# VM_PATH suffix for non-native architectures. When the target VM arch differs
# from the host arch, append -<ARCH> to keep per-arch VMs separate.
# Host arch: NORMALISED_HOST_ARCH if set (qget sets it), else uname -m.
# ---------------------------------------------------------------------------
_host_arch() {
	case "$(uname -m)" in
	aarch64 | arm64) echo arm64 ;;
	*) echo amd64 ;;
	esac
}

function arch_suffix() {
	if [ "${ARCH:-amd64}" != "${NORMALISED_HOST_ARCH:-$(_host_arch)}" ]; then
		echo "-${ARCH}"
	fi
}
export -f arch_suffix _host_arch

# ---------------------------------------------------------------------------
# Quicktest results directory resolution. Results normally live next to the
# VMs, but the base can be overridden per-config with RESULTS_DIR:
#   (empty)      -> "${VMS_DIR:-$HOME/vm}/results"
#   ./           -> relative to the current working directory
#   /abs/path    -> as-is
#   ~/short/path -> expanded against $HOME
# Trailing slashes are stripped. Echoes the base directory.
# ---------------------------------------------------------------------------
expand_results_dir() {
	local dir="${1:-$RESULTS_DIR}"
	case "${dir}" in
	'') dir="${VMS_DIR:-$HOME/vm}/results" ;;
	~*)
		dir="${dir#\~}"
		dir="${HOME}${dir}"
		;;
	/*) : ;;
	*) dir="$(pwd)/${dir#./}" ;;
	esac
	dir="${dir%/}"
	echo "${dir}"
}
export -f expand_results_dir

# ---------------------------------------------------------------------------
# Quicktest mouse payload builders. Pure string generators (no I/O), so they
# can be unit-tested. Honour QT_MOUSE_MODE (relative|absolute) unless an
# explicit mode is passed as the last argument.
#   relative -> HMP commands for the -monitor socket:
#               "mouse_move X Y", "mouse_button <bits>"
#   absolute -> QMP "input-send-event" JSON lines for a QMP socket
#               (absolute coordinates + button press/release events).
# Button names: left|right|middle (or L/R/M, or bitmask 1/2/4).
# ---------------------------------------------------------------------------
_qt_btn_bits() {
	case "${1}" in
	left | L | 1) echo "1" ;;
	right | R | 2) echo "2" ;;
	middle | M | 4) echo "4" ;;
	*) echo "${1}" ;;
	esac
}

_qt_btn_name() {
	case "${1}" in
	left | L | 1) echo "left" ;;
	right | R | 2) echo "right" ;;
	middle | M | 4) echo "middle" ;;
	*) echo "${1}" ;;
	esac
}
export -f _qt_btn_bits _qt_btn_name

qt_mouse_cmd_move() {
	local mode="${3:-${QT_MOUSE_MODE:-relative}}"
	if [ "${mode}" = "absolute" ]; then
		printf '{"execute":"input-send-event","arguments":{"events":[{"type":"abs","data":{"axis":"x","value":%s}},{"type":"abs","data":{"axis":"y","value":%s}}]}}\n' "${1}" "${2}"
	else
		printf 'mouse_move %s %s\n' "${1}" "${2}"
	fi
}

qt_mouse_cmd_button() {
	local mode="${3:-${QT_MOUSE_MODE:-relative}}"
	if [ "${mode}" = "absolute" ]; then
		if [ "${2}" = "down" ]; then
			printf '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":true,"button":"%s"}}]}}\n' "$(_qt_btn_name "${1}")"
		else
			printf '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":false,"button":"%s"}}]}}\n' "$(_qt_btn_name "${1}")"
		fi
	else
		if [ "${2}" = "down" ]; then
			printf 'mouse_button %s\n' "$(_qt_btn_bits "${1}")"
		else
			printf 'mouse_button 0\n'
		fi
	fi
}

qt_mouse_cmd_click() {
	qt_mouse_cmd_button "${1}" down "${2:-}"
	printf '\n'
	qt_mouse_cmd_button "${1}" up "${2:-}"
}
export -f qt_mouse_cmd_move qt_mouse_cmd_button qt_mouse_cmd_click

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
	if [ -z "${_WEB_CACHE_DIR:-}" ]; then
		cat >/dev/null
		return 0
	fi
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
# Hardcoded fallback tracker list used when the magnet URI carries no tr. params.
# Override with DH_TRACKERS env var (space-separated list).
# Keep as a single string so it can be passed to aria2c --bt-tracker=...
# Source: https://github.com/ngosang/trackerslist (trackers_best.txt, 2026-09-29)
# shellcheck disable=SC2034
DH_TRACKERS_DEFAULT="udp://tracker.opentrackr.org:1337/announce udp://open.stealth.si:80/announce udp://open.demonii.com:1337/announce udp://exodus.desync.com:6969/announce udp://tracker.skynetcloud.site:6969/announce"

function torrent_get() {
	local MAGNET="${1}"
	local DIR="${2:-.}"
	local EXPECTED_ISO="${3:-}"

	if ! command -v aria2c &>/dev/null; then
		echo "INFO: aria2c not found, use 'web_get' fallback" >&2
		return 1
	fi

	# Ensure target directory exists — aria2c --dir= fails on missing dir (Bug #1)
	mkdir -p "${DIR}"

	# Build tracker list: use DH_TRACKERS if set, else default fallback list.
	# If the magnet already contains tr.= parameters, aria2c will prefer those;
	# --bt-tracker= adds *additional* trackers, it does not replace.
	local trackers="${DH_TRACKERS:-${DH_TRACKERS_DEFAULT}}"

	echo "Downloading via aria2c..."
	# Robust aria2c invocation (Bug #6):
	#  --continue=true          : resume partial downloads
	#  --max-connection-per-server=4 : polite connection limit
	#  --bt-tracker=...         : fallback trackers when magnet has none
	#  --timeout=60             : per-request timeout (seconds)
	#  --max-tries=5            : retry limit for transient failures
	#  --seed-time=0            : do not seed after download (existing behaviour)
	#  --dir="${DIR}"           : destination directory
	aria2c \
		--continue=true \
		--max-connection-per-server=4 \
		--bt-tracker="${trackers}" \
		--timeout=60 \
		--max-tries=5 \
		--seed-time=0 \
		--dir="${DIR}" \
		"${MAGNET}" || return $?

	# Post-download filename reconciliation (Bug #7):
	# aria2c names the file from the magnet's dn= parameter, which may not
	# match the expected ISO filename. If EXPECTED_ISO is provided and the
	# file doesn't exist, look for exactly one .iso in DIR and rename it.
	if [ -n "${EXPECTED_ISO}" ] && [ ! -f "${DIR}/${EXPECTED_ISO}" ]; then
		local found_iso
		found_iso=$(find "${DIR}" -maxdepth 1 -type f -name '*.iso' 2>/dev/null | head -n1)
		local iso_count
		iso_count=$(find "${DIR}" -maxdepth 1 -type f -name '*.iso' 2>/dev/null | wc -l)
		if [ "${iso_count}" -eq 1 ] && [ -n "${found_iso}" ]; then
			echo "Renaming downloaded file to expected name: ${EXPECTED_ISO}"
			mv "${found_iso}" "${DIR}/${EXPECTED_ISO}"
		else
			echo "ERROR: Downloaded ISO not found or ambiguous (expected ${EXPECTED_ISO}, found ${iso_count} .iso files)" >&2
			return 1
		fi
	fi

	return 0
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

	# Read BASEDOF without sourcing the whole template. Sourcing it would
	# replace the caller's releases_/editions_/get_ functions with the live,
	# network-scraping ones — the static metadata would be lost for the rest
	# of the run.
	local basedof_raw=""
	basedof_raw="$(grep -m1 '^BASEDOF=' "$template_file" 2>/dev/null)"
	if [ -z "$basedof_raw" ]; then
		echo "Template not found: $osname"
		return 1
	fi
	BASEDOF="${basedof_raw#BASEDOF=}"
	BASEDOF="${BASEDOF%\"}"
	BASEDOF="${BASEDOF#\"}"

	# Map BASEDOF to rosette ID
	local rosette_id=""
	local basedof_lower
	basedof_lower=$(echo "${BASEDOF:-}" | tr '[:upper:]' '[:lower:]')

	case "$basedof_lower" in
	*arch*) rosette_id="arch" ;;
	*debian* | *ubuntu*) rosette_id="debian" ;;
	*void*) rosette_id="void" ;;
	*fedora* | *rhel* | *"red hat"*) rosette_id="fedora" ;;
	*gentoo*) rosette_id="gentoo" ;;
	*alpine*) rosette_id="alpine" ;;
	*opensuse* | *suse*) rosette_id="opensuse" ;;
	*slackware*) rosette_id="slackware" ;;
	*nix*) rosette_id="nix" ;;
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
	[ -n "$remove_cmd" ] && printf "   ${GREEN}remove${NC}   %s\n" "$remove_cmd"
	[ -n "$update_cmd" ] && printf "   ${GREEN}update${NC}   %s\n" "$update_cmd"
	[ -n "$search_cmd" ] && printf "   ${GREEN}search${NC}   %s\n" "$search_cmd"
	echo ""
}
export -f rosette_info
