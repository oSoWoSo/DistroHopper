#!/usr/bin/bash
# Author: zenobit
# Description: Uses gum to provide a simple VMs runner for quickemu and quickget
# License MIT

_define_variables() {
	color=$(( RANDOM % 255 + 1 ))
	progname="${progname:="${0##*/}"}"
	#configdir="$HOME/.config/$progname"
	version='0.2'
	vms=(*.conf)
	if ! command -v gum >/dev/null 2>&1; then
		echo 'You are missing gum! Exiting...' && exit 1
	fi
	if ! command -v quickemu >/dev/null 2>&1; then
		gum style --foreground 1 "You are missing quickemu!"
	fi
	QUICKGET=$(command -v quickget)
	#export BORDER="rounded"
	export BORDERS_FOREGROUND="$color"
	export GUM_CHOOSE_CURSOR_FOREGROUND="$color"
	export GUM_CHOOSE_SELECTED_FOREGROUND="$color"
	export GUM_CONFIRM_PROMPT_FOREGROUND=""
	export GUM_CONFIRM_SELECTED_FOREGROUND="$color"
	export GUM_CONFIRM_UNSELECTED_FOREGROUND=0
	export GUM_FILTER_CURSOR_TEXT_FOREGROUND=""
	export GUM_FILTER_HEADER_FOREGROUND=""
	export GUM_FILTER_INDICATOR_FOREGROUND="$color"
	export GUM_FILTER_MATCH_FOREGROUND="$color"
	export GUM_FILTER_PROMPT_FOREGROUND="$color"
	export GUM_FILTER_SELECTED_PREFIX_FOREGROUND="$color"
	export GUM_FILTER_SELECTED_PREFIX_BORDER_FOREGROUND="$color"
}

_generate_supported(){
	echo "Extracting OS Editions and Releases..."
	rm -rf /tmp/distros
	mkdir -p /tmp/distros
	"$QUICKGET" | awk 'NR==2,/zorin/' | cut -d':' -f2 | grep -o '[^ ]*' > /tmp/supported
	while read -r get_name; do
		supported=$($QUICKGET "$get_name" | sed 1d)
		echo "$get_name"
		echo "$supported"
		echo "$supported" > "/tmp/distros/${get_name}"
	done < /tmp/supported
}

_if_needed() {
	if [ ! -f /tmp/supported ]; then
		_generate_supported
	fi
}

color2=$(( RANDOM % 255 + 1 ))

show_headers() {
	if [ -f /tmp/icons ]; then
		icons=yes
	else
		icons=""
	fi
	logo_1=$(gum style --foreground "$color2" "▄▄▄▄
█  █
█  █
█▄▀▄")
	logo_2=$(gum style "v$version")
	logo_3=$(gum style --foreground "$color2" "▀")
	logo_23=$(gum join "$logo_2" "$logo_3")
	logo=$(gum join --vertical "$logo_1" "$logo_23")
	logo_border=$(gum style --padding "0 1" --border=rounded --border-foreground $color "$logo" )

	tip_header=$(gum style --bold "Tip: ")
	distro=$(shuf -n 1 /tmp/supported)
	tip_distro=$(gum style --align="center" "try $distro")
	tip_temp=$(gum join --align="center" "$tip_header" "$tip_distro")
	homepage=$("$QUICKGET" -s "${distro}")
	tip_homepage=$(gum style "$homepage")
	tip=$(gum join --vertical --align top "$tip_temp" "$tip_homepage")
	tip_border=$(gum style --padding "0 1" --border=rounded --border-foreground $color "$tip")

	pid_files=(*/*.pid)
	vms=(*.conf)
	vms_running=()
	vms_not=()
	vms_vm=$(gum style --align="center" --bold "ready:")
	vms_run=""
	if [ -n "$(find . -name '*.pid')" ]; then
		for pid_file in "${pid_files[@]}"; do
			instance_name=$(basename "$pid_file" .pid)
			vms_running+=("$instance_name")
		done
		if [ "$icons" == yes ]; then
			running_logo=$(gum style --foreground "$color" --bold ".")
		else
			running_logo=$(gum style --foreground "$color" --bold ">")
		fi
		for instance in "${vms_running[@]}"; do
			vms_run+="$running_logo$instance "
		done
	fi
	mapfile -t vms_not < <(comm -23 <(printf "%s\n" "${vms[@]}" | rev | cut -d'.' -f2-9 | rev | sort) <(printf "%s\n" "${vms_running[@]}" | sort))
	vms_not_next=$(gum style < <(printf '%s\n' "${vms_not[@]}"))
	if [ -n "$(find . -name '*.pid')" ]; then
		vms_run_next=$(echo "$vms_run" | tr " " "\n")
		vms_header=$(gum join --vertical "$vms_vm" "$vms_run_next" "$vms_not_next")
	else
		vms_header=$(gum join --vertical "$vms_vm" "$vms_not_next")
	fi
	vms_border=$(gum style --padding "0 1" --border=rounded --border-foreground $color "$vms_header")
	header=$(gum join --align top "$logo_border" "$vms_border")
	gum join --align center --align top --vertical "$header" "$tip_border"
}

gum_filter_os() {
	os=$(gum filter < /tmp/supported)
	choices=$(cat "/tmp/distros/$os")
}

gum_filter_release() {
	release=$(echo "$choices" | grep 'Releases:' | cut -d':' -f2 | grep -o '[^ ]*' | gum filter --sort)
}

gum_filter_edition() {
	edition=$(echo "$choices" | grep 'Editions:' | cut -d':' -f2 | grep -o '[^ ]*' | gum filter --sort)
}

gum_choose_VM() {
	if find . -maxdepth 1 -name '*.conf' >/dev/null 2>&1 ; then
		chosen=$(find . -maxdepth 1 -name '*.conf' | cut -d'/' -f2 | rev | cut -d'.' -f2-9 | rev | gum filter --select-if-one)
	else
		gum style --foreground 1 "Can't!"
	fi
}

create_VM() {
	gum_filter_os
	if [ -z "$os" ]; then exit 100
	elif [ "$(echo "$choices" | wc -l)" = 1 ]; then
		clear
		gum_filter_release
		clear
		"$QUICKGET" "$os" "$release"
	else
		clear
		gum_filter_release
		clear
		gum_filter_edition
		clear
		"$QUICKGET" "$os" "$release" "$edition"
	fi
	show_headers
}

run_VM() {
	quickemu -vm "$chosen.conf"
	show_headers
}

gum_choose_running() {
	pid_files=( */*.pid )
	if [ ${#pid_files[@]} -gt 0 ]; then
		mapfile -t running < <(find . -name '*.pid' -printf '%P\n' | sed 's/\.pid$//')

		if [ ${#running[@]} -gt 0 ]; then
			selected=$(gum filter --select-if-one "${running[@]}")
		else
			gum style --foreground 1 "Can't!" && selected=""
		fi
	else
		gum style --foreground 1 "Can't!" && selected=""
	fi
}

get_ssh_port() {
	port=$(grep 'ssh' < "$selected".ports | cut -d',' -f2)
}

ssh_into() {
	gum_choose_running
	if [ -n "$selected" ]; then
		get_ssh_port
		username=$(gum input --prompt "$selected user? ")
		ssh "$username"@localhost -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -p "$port"
		show_headers
	fi
}

open_distro_homepage(){
	gum_filter_os
	"$QUICKGET" -o "${os}" >/dev/null 2>&1 &
}

gum_choose_VM_to_delete() {
	if [ -n "$(echo *.conf)" ]; then
		chosen=$(echo "${vms[@]%.*}" | tr " " "\n" | gum choose --select-if-one)
		gum confirm "Really delete $chosen" && rm -r "$chosen" && rm "$chosen".conf
		show_headers
	else
		gum style --foreground 1 "No VMs!"
	fi
}

# MENU
_show_menu() {
	while true
	do
			start=$(echo "create
run
ssh into
homepage
delete
exit $progname" | gum filter --height 6)
# from choose:  --selected '󰜎 run'
			case $start in
				create ) create_VM;;
				run ) gum_choose_VM && run_VM;;
				'ssh into' ) ssh_into;;
				homepage ) open_distro_homepage;;
				delete ) gum_choose_VM_to_delete;;
				"exit $progname" ) exit 0;;
			esac

	done
}

# run
#clear
_define_variables
_if_needed
show_headers
_show_menu
