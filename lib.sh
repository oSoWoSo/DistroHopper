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
	_red()   { gum style --foreground "#e50203" "$1"; }
	_green() { gum style --foreground "#14a113" "$1"; }
	_blue()  { gum style --foreground "#004EFB" "$1"; }
	_yel()   { gum style --foreground "#fdde13" "$1"; }
else
	_g()      { echo -e "${GREEN}${1}${NC}"; }
	_r()      { echo -e "${RED}${1}${NC}"; }
	_re()     { echo -e "${RED}${1}${NC}" >&2; exit 1; }
	_b()      { echo -e "${BLUE}${1}${NC}"; }
	_y()      { echo -e "${YELLOW}${1}${NC}"; }
	_header() { echo -e "\n${RED}${1}${NC}\n"; }
	_footer() { echo -e "\n${RED}${1}${NC}\n"; }
	_red()    { printf "${RED}%s${NC}" "$1"; }
	_green()  { printf "${GREEN}%s${NC}" "$1"; }
	_blue()   { printf "${BLUE}%s${NC}" "$1"; }
	_yel()    { printf "${YELLOW}%s${NC}" "$1"; }
fi

export -f _r _re _g _b _y _red _green _blue _yel

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
