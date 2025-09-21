#!/usr/bin/env bash
# Author: zenobit
# Description: Uses gum to provide a simple TUI for VMs using qemu
# Based of: https://github.com/quickemu-project/quickemu
# License MIT

#set -eu

## NEEDED

CHARACTERS="                                                                                                               "

define_variables() {
	color=$(( RANDOM % 255 + 1 ))
	progname="${progname:="${0##*/}"}"
	configdir="$HOME/.config/$progname"
	tmpdir="/tmp"
	version='0.70'
	vms=(*.conf)
	if ! command -v gum >/dev/null 2>&1; then
		echo 'You are missing gum! Exiting...' && exit 1
	fi
	if ! command -v quickemu >/dev/null 2>&1; then
		if ! command -v ./quickemu >/dev/null 2>&1; then
		  gum style --foreground 1 'You are missing quickemu!'
		else
		  echo 'Using quickemu in current directory'
		fi
	fi
	#export BORDER="rounded"
	color2=$(( RANDOM % 255 + 1 ))
	export BORDERS_FOREGROUND="$color"
	export GUM_CHOOSE_CURSOR_FOREGROUND="$color"
	export GUM_CHOOSE_SELECTED_FOREGROUND="$color"
	export GUM_CONFIRM_PROMPT_FOREGROUND=""
	export GUM_CONFIRM_SELECTED_FOREGROUND="$color"
	export GUM_CONFIRM_UNSELECTED_FOREGROUND=0
	export GUM_FILTER_CURSOR_TEXT_FOREGROUND=""
	export GUM_FILTER_HEADER_FOREGROUND=""
	export GUM_FILTER_INDICATOR_FOREGROUND="$color2"
	export GUM_FILTER_MATCH_FOREGROUND="$color2"
	export GUM_FILTER_PROMPT_FOREGROUND="$color2"
	export GUM_FILTER_SELECTED_PREFIX_FOREGROUND="$color2"
	export GUM_FILTER_SELECTED_PREFIX_BORDER_FOREGROUND="$color2"

	# Set traps to catch the signals and exit gracefully
	trap 'exit' INT
	trap 'exit' EXIT
	# just for development in termux
	if command -v termux-info >/dev/null 2>&1; then
		echo "Running in termux!"
		TERMUX=1
		tmpdir="$(pwd)/tmp"
	fi

  if [ "$TERMUX" == 1 ]; then
    QUICKGET=./quickget
  else
    QUICKGET=quickget
  fi
	# use configdir
	if [ -f "${configdir}/border" ]; then
		BORDER="$(cat "${configdir}"/border)"
	else
		BORDER="double"
	fi
	if [ -f "${configdir}/color" ]; then
		BORDERS_FOREGROUND="$(cat "${configdir}"/color)"
	else
		BORDERS_FOREGROUND="$(( RANDOM % 255 + 1 ))"
	fi
	if [ -f "${configdir}/spinner" ]; then
		spinner="$(cat "${configdir}"/spinner)"
	else
		spinner="globe"
	fi
}

generate_supported() {
	echo "Extracting OS Editions and Releases..."
	rm -rf "$tmpdir/distros"
	mkdir -p "$tmpdir/distros"
	"$QUICKGET" | awk 'NR==2,/zorin/' | cut -d':' -f2 | grep -o '[^ ]*' > $tmpdir/supported
	while read -r get_name; do
		supported=$($QUICKGET "$get_name" | awk 'NF && NR>=5 && NR<=8')
		echo "$get_name"
		echo "$supported" > "$tmpdir/distros/${get_name}"
	done < $tmpdir/supported
}

if_needed() {
	if [ ! -f "$tmpdir"/supported ]; then
		generate_supported
	fi
}

## HELP

show_help() {
	clear
	show_headers_full
	gum style --padding "0 1"  --border="$BORDER" --border-foreground="$BORDERS_FOREGROUND" "$title"
}

help_main() {
	title="    $progname $version
Uses gum to provide a simple TUI for quickemu and quickget 'https://github.com/quickemu-project/quickemu'
 'https://github.com/charmbracelet/gum'

For menus you can use arrow keys or fuzzy filtering and then ENTER
(e + ENTER for exit or b + ENTER for back to main menu)

If is posible choose more options use TAB for highliting desired and then ENTER

Config files are stored at $configdir

As temp folder is used $tmpdir
"
}

## MAIN

gum_choose_os() {
	title="Choose OS"
	show_header
	os=$(gum choose --prompt='Choose OS' < "$tmpdir"/supported)
	choices=$("$QUICKGET" "$os" | sed 1d | sed '/^$/q')
}

gum_choose_release() {
	title="Choose release"
	show_header
	release=$(echo "$choices" | grep 'Releases' | cut -f2 | grep -o '[^ ]*' | gum choose --prompt='Choose release')
}

gum_choose_edition() {
	title="Choose edition"
	show_header
	edition=$(echo "$choices" | grep 'Editions' | cut -f2 | grep -o '[^ ]*' | gum choose --prompt='Choose edition')
}

gum_filter_os() {
	os=$(gum filter < "$tmpdir/supported")
	choices=$(cat "$tmpdir/distros/${os}")
}

gum_filter_release() {
	release=$(echo "$choices" | grep 'Releases:' | cut -f2 | grep -o '[^ ]*' | gum filter --sort)
}

gum_filter_edition() {
	edition=$(echo "$choices" | grep 'Editions:' | cut -f2 | grep -o '[^ ]*' | gum filter --sort)
}

gum_choose_VM() {
	if find . -maxdepth 1 -name '*.conf' >/dev/null 2>&1 ; then
		chosen=$(find . -maxdepth 1 -name '*.conf' | cut -d'/' -f2 | rev | cut -d'.' -f2-9 | rev | gum filter --select-if-one)
	else
		gum style --foreground 1 "Can't!"
	fi
}

gum_choose_VM2() {
	if ls | grep ".conf" ; then
		height=$(ls -1 | grep ".conf" | wc -l)
		title="Choose VM"
		show_header
		chosen=$(ls -1 | grep ".conf" | rev | cut -d'.' -f2- | rev | gum filter --height "$height")
	else
		echo "No VMs to run."
	fi
	#chosen=$(printf '%s\n' "${vms[@]%.conf}" | gum filter --height "$("${vms[@]%.conf}" | wc -l)" --header='Choose VM to run')
}

create_VM() {
	gum_filter_os
	if [ -z "$os" ]; then exit 100
	elif ! echo "$choices" | grep -q "Editions:"; then
		#clear
		gum_filter_release
		#clear
		"$QUICKGET" "$os" "$release"
	else
		#clear
		gum_filter_release
		#clear
		gum_filter_edition
		#clear
		"$QUICKGET" "$os" "$release" "$edition"
	fi
	show_headers
}

create_VM2() {
	gum_choose_os
	if [ -z "$os" ]; then exit 100
	elif [ "$(echo "$choices" | wc -l)" = 1 ]; then
		clear
		gum_choose_release
		#gum spin --spinner $spinner --show-output --title="Downloading $os $/release" -- "$QUICKGET" "$os" "$release"
		"$QUICKGET" "$os" "$release"
		if [ -f "${configdir}/default_vm_config" ]; then
			echo 'Adding default values to config...'
			cat "${configdir}/default_vm_config" >> "$os-$release.conf"
		fi
	else
		clear
		gum_choose_release
		gum_choose_edition
		gum spin --spinner $spinner --show-output --title="Downloading $os $release $edition" -- "$QUICKGET" "$os" "$release" "$edition"
		if [ -f "${configdir}/default_vm_config" ]; then
			echo 'Adding default values to config...'
			cat "${configdir}/default_vm_config" >> "$os-$release-$edition.conf"
		fi
	fi
	echo "
To start your new $os virtual machine use 'run' from menu"
show_headers_small
}

edit_default_VMs_config() {
	title="Editing default VM's config..."
	show_header
	printf 'For example:\ncpu_cores="2"\nram="4G"\n'
	title="CTRL+D to complete.  CTRL+C and esc will cancel"
	show_header
	gum write > "${configdir}"/default_vm_config
}

edit_VM_config() {
	if [ -z "$EDITOR" ]; then
		echo "Editor not set! Can't continue!"
	else
		height=$(ls -1 | grep ".conf" | wc -l)
		${EDITOR} "$(ls | grep ".conf" | gum filter --height "$height")"
	fi

}

custom_quickemu_command() {
	custom=$(echo "edit delete" | grep -o '[^ ]*' | gum choose --header='Edit or delete custom command?')
	if [ "$custom" = "edit" ]; then
		quickemu
		printf '\nEnter quickemu custom command:\n For example:--public-dir ~/Downloads\n:'
		read -r command
		mkdir -p "$configdir"
		echo "$command" > "${configdir}/command"
	elif [ "$custom" = "delete" ]; then
		rm "${configdir}/command"
	fi
}

run_VM() {
	title="Starting $chosen..."
	show_header
	if [ -f "${configdir}/command" ]; then
		quickemu < "${configdir}/command" -vm "$chosen.conf"
	else
			quickemu -vm "$chosen.conf"
	fi
	show_headers
}

gum_choose_running() {
	pid_files=( */*.pid )
	if [ ${#pid_files[@]} -gt 0 ]; then
		mapfile -t running < <(find . -name '*.pid' -printf '%P\n' | sed 's/\.pid$//')

		if [ ${#running[@]} -gt 0 ]; then
			selected=$(gum choose --select-if-one "${running[@]}")
		else
			gum style --foreground 1 "Can't!" && selected=""
		fi
	else
		gum style --foreground 1 "Can't!" && selected=""
	fi
}

#TODO:
gum_choose_runnings() {
	pid_files=( */*.pid )
	if [ ${#pid_files[@]} -gt 0 ]; then
		mapfile -t running < <(find . -name '*.pid' -printf '%P\n' | sed 's/\.pid$//')

		if [ ${#running[@]} -gt 0 ]; then
			selected=$(gum choose --select-if-one "${running[@]}")
		else
			gum style --foreground 1 "Can't!" && selected=""
		fi
	else
		gum style --foreground 1 "Can't!" && selected=""
	fi
}

gum_choose_VM_to_delete() {
	height=$(ls -1 | grep ".conf" | wc -l)
	GUM_FILTER_HEADER="Choose VM to delete"
	GUM_FILTER_HEADER_FOREGROUND=""
	if ls | grep ".conf" ; then
		chosen=$(echo ${vms[@]%.*} | tr " " "\n" | gum filter --height "$height" --no-limit)
		echo 'Removing config(s)...'
		rm -r $chosen & rm $chosen.conf
	else
		echo "No VMs to delete"
	fi
}

gum_choose_VM_to_delete2() {
	if [ -n "$(echo *.conf)" ]; then
		chosen=$(echo "${vms[@]%.*}" | tr " " "\n" | gum choose --select-if-one)
		gum confirm "Really delete $chosen" && rm -r "$chosen" && rm "$chosen".conf
		show_headers
	else
		gum style --foreground 1 "No VMs!"
	fi
}

gum_choose_VM_to_delete3() {
	if ls | grep ".conf" ; then
		GUM_FILTER_HEADER="Choose VM to delete"
		height=$(ls -1 | grep ".conf" | wc -l)
		chosen=$(ls -1 | grep ".conf" | gum filter --height "$height" --no-limit)
		delete_VM
	else
		echo "No VMs to delete"
	fi
}

delete_VM() {
	#chosen_to_delete=$(cat $chosen | while read line; echo $line | rev | cut -d'.' -f2-5 | rev; done)
	echo "#TODO"
	echo $chosen | tr " " "\n" | while read line 
	do
		echo 'Removing dir(s)...'
		rm -r $(echo $line | rev | cut -d'.' -f2-5 | rev)
	done
	echo 'Removing config(s)...'
	rm $(echo "$chosen")
}

## ADVANCED

# shellcheck disable=SC2016,2034,2153
add_new_distro() {
	mkdir -p "$configdir"
	echo "add new OS, all lowercase"
	NAME="$(gum input --header="NAME" --placeholder="arch")"
	echo "add a pretty name for new OS *only if the catch all is not suitable*"
	PRETTY_NAME="$(gum input --header="PRETTY_NAME" --placeholder="Arch Linux")"
	echo "add a homepage for new OS"
	HOMEPAGE="$(gum input --header="HOMEPAGE" --placeholder="https://voidlinux.org/")"
	echo "current supported release versions"
	RELEASES="$(gum input --header="RELEASES" --placeholder="8 9")"
	echo "the editions if new OS has multiple flavours/editions"
	EDITIONS="$(gum input --header="EDITIONS" --placeholder="kde gnome")"
	echo "base URL for ISO download"
	URL="$(gum input --header="URL" --placeholder="https://ddl.bunsenlabs.org/ddl")"
	echo "Name of ISO"
	ISO="$(gum input --header="ISO" --placeholder="GhostBSD-${RELEASE}-XFCE.iso")"
	echo "name of hash file "
	CHECKSUM="$(gum input --header="CHECKSUM" --placeholder='${ISO}.sha256sum')"
	cat <<EOF > "$configdir/template"
#line 58+

$NAME)           PRETTY_NAME="$PRETTY_NAME";;

#line 207+

$NAME \\

#line 292+

		$NAME)              HOMEPAGE=$HOMEPAGE;;

#line 374+

function releases_$NAME() {
echo $RELEASES
}

function editions_$NAME() {
echo $EDITIONS
}

#line 1176+

function get_$NAME() {
local EDITION="\${1:-}"
local HASH=""
local ISO="$ISO"
local URL="$URL"
HASH="\$(wget -q -O- \${URL}/\$CHECKSUM | grep (\${ISO} | cut -d' ' -f4)"
echo "\${URL}/\${ISO}" "\${HASH}"
}

EOF
	diff "$configdir/template" "quickget"
}

# shellcheck disable=SC2154
create_desktop_entry() {
	cat <<EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Version=$version
Type=$type
Name=$name
GenericName=$progname
Comment=$comment
Exec=$execmd
Icon=$icon
Terminal=$terminal
X-MultipleArgs=$args
Type=$type
Categories=$categories
StartupNotify=$notify
MimeType=$mime
Keywords=$keyword

EOF
}

test_ISOs_download() {
	rm "$tmpdir/test" 2>/dev/null
	cd "$tmpdir" || exit
	touch "$tmpdir/test"
	#"$QUICKGET" | sed 1d | cut -d':' -f2 | grep -o '[^ ]*' > supported
	os=$(gum filter < "$tmpdir"/supported)
	choices=$("$QUICKGET" "$os" | sed 1d)
		while read -r get_name; do
		echo "Trying $get_name..."
		mkdir -p "$tmpdir/_distros/$get_name" && cd "$tmpdir/_distros/$get_name" || exit
		releases=$("$QUICKGET" "$get_name" | grep 'Releases:' | cut -f2 | sed 's/^ //' | sed 's/ *$//')
		echo "$releases" > releases
		editions=$("$QUICKGET" "$get_name" | grep 'Editions:' | cut -f2 | sed 's/^ //' | sed 's/ *$//')
		echo "$editions" > editions
		if [ -z "$editions" ]; then
			for release in $releases; do
				echo "$get_name" >> "$tmpdir/test"
				timeout 10 "$QUICKGET" -t "$get_name" "${release}" >> "$tmpdir/test"
			done
		else
			while read -r release; do
				for edition in $editions; do
					echo "$get_name" >> "$tmpdir/test"
					timeout 10 "$QUICKGET" -t "$get_name" "${release}" "${edition}" >> "$tmpdir/test"
				done
			done < releases
		fi
		cd "$tmpdir" || exit
	done < supported
	printf "\nDone"
}

show_ISOs_urls(){
	rm -r "$tmpdir/test" 2>/dev/null
	cd "$tmpdir" || exit
	touch "$tmpdir/test"
	"$QUICKGET" | sed 1d | cut -d':' -f2 | grep -o '[^ ]*' > supported
	while read -r get_name; do
		echo "Trying $get_name..."
		mkdir -p "$tmpdir/_distros/$get_name" && cd "$tmpdir/_distros/$get_name" || exit
		releases=$("$QUICKGET" "$get_name" | grep 'Releases' | cut -d':' -f2 | sed 's/^ //' | sed 's/ *$//')
		echo "$releases" > releases
		editions=$("$QUICKGET" "$get_name" | grep 'Editions' | cut -d':' -f2 | sed 's/^ //' | sed 's/ *$//')
		echo "$editions" > editions
		if [ -z "$editions" ]; then
			for release in $releases; do
				echo "$get_name" >> "$tmpdir/test"
				timeout 5 "$QUICKGET" -s "$get_name" "${release}" >> "$tmpdir/test" #&& $(killall zsync >> /dev/null)
			done
		else
			while read -r release; do
				for edition in $editions; do
					echo "$get_name" >> "$tmpdir/test"
					timeout 5 "$QUICKGET" -s "$get_name" "${release}" "${edition}" >> "$tmpdir/test" #&& $(killall zsync >> /dev/null)
				done
			done < releases
		fi
		cd "$tmpdir" || exit
	done < supported
	printf "\nDone"
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

kill_vm() {
	gum_choose_running
	if [ -n "$selected" ]; then
		echo "${selected}"
		gum confirm "Really kill $selected?" && pid=$(cat "$selected".pid) && kill "$pid"
		show_headers
	fi
}

#TODO:
kill_vms() {
	gum_choose_runnings
	if [ -n "$selected" ]; then
		for vm_name in "${selected[@]}"; do
			gum confirm "Really kill $vm_name?"
			pid=$(cat "${vm_name}.pid")
			kill "$pid"
		done
		show_headers
	fi
}

headers_small_or() {
	printf '\n\nsmall:\n'
	show_headers_small
	printf '\n\nfull:\n'
	show_headers_full
	printf '\n\ncurrent:\n'
	show_headers
	use_headers=$(gum choose --header "   Use small headers or full?" "small" "full" "current")
	echo "will use $use_headers"
	show_headers
}

change_borders() {
	title="Change borders style"
	show_header
	BORDER=$(echo "none
hidden
normal
rounded
thick
double" | gum filter --height $height)
	mkdir -p ${configdir}
	touch "${configdir}"/border
	echo $BORDER > "${configdir}"/border
}

change_color() {
	title="Define color number or choose random"
	show_header
	BORDER_FOREGROUND=$(echo 'random' | gum filter --height 1 --prompt="Enter custom" --no-strict)
	mkdir -p ${configdir}
	touch "${configdir}"/color
	echo $BORDER_FOREGROUND > "${configdir}"/color
}

use_color() {
	if [ -f "${configdir}/color" ]; then
		BORDER_FOREGROUND=$(cat ${configdir}/color)
	fi
}

change_spinner() {
	spinner=$(echo "line
dot
minidot
jump
pulse
points
globe
moon
monkey
meter
hamburger" | gum filter --height 11)
	mkdir -p ${configdir}
	touch "${configdir}"/spinner
	echo "$spinner" > "${configdir}"/spinner
}

# shellcheck disable=SC2015
icons_or() {
	gum confirm "   Use icons?
need Nerd Fonts" && echo "yes" > "$configdir/icons" || rm "$configdir/icons"
	show_headers
}

use_icons() {
	if [ -f "$configdir/icons" ]; then
		icons=yes
	else
		icons=""
	fi
}

## HEADERS

show_header() {
	gum style --padding "0 1"  --border="$BORDER" --border-foreground="$BORDERS_FOREGROUND" "$title"
}

show_version_qemu() {
	qemu-x86_64 -version | sed 2d | cut -d' ' -f3
}

show_version_quickemu() {
	quickemu --version | grep "ERROR! QEMU not found" && echo "QEMU is missing!" || quickemu --version
}

show_editor() {
	if [ -z "$EDITOR" ]; then
		echo '  editor Not set!'
	else
		echo "  editor $EDITOR"
	fi
}

show_vms() {
	if [ ${#vms[@]} -eq 0 ]; then
		gum style --foreground 1 "No VMs!"
	else
	echo "${vms[@]%.*}" | tr " " "\n"
	fi
}

show_custom_small() {
	if [ -f "${configdir}/command" ]; then
		gum style --bold --foreground "$color2" "command:"
		gum style "quickemu $(cat "${configdir}/command")"
	fi
	if [ -f "${configdir}/default_vm_config" ]; then
		gum style --bold --foreground "$color2" "default config:"
		gum style "$(cat "${configdir}/default_vm_config")"
	fi
}

show_custom() {
	show_custom_small
	if [ -f "${configdir}/color" ]; then
		gum style --bold --foreground "$color2" "color:"
		gum style "$(cat "${configdir}/color")"
	fi
	if [ -f "${configdir}/border" ]; then
		gum style --bold --foreground "$color2" "borders:"
		gum style "$(cat "${configdir}/border")"
	fi
	if [ -f "${configdir}/spinner" ]; then
		gum style --bold --foreground "$color2" "spinner:"
		gum style "$(cat "${configdir}/spinner")"
	fi
}

show_header_vms() {
	pid_files=(*/*.pid)
	vms=(*.conf)
	vms_running=()
	vms_not=()
	vms_vm=$(gum style --bold --foreground "$color2" "ready:")
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
	vms_not_next=$(gum style --align center < <(printf '%s\n' "${vms_not[@]}"))
	if [ -n "$(find . -name '*.pid')" ]; then
		vms_run_next=$(echo "$vms_run" | tr " " "\n")
		vms_header=$(gum join --vertical --align center "$vms_vm" "$vms_run_next" "$vms_not_next")
	else
		vms_header=$(gum join --vertical --align center "$vms_vm" "$vms_not_next")
	fi
	vms_border=$(gum style --padding "0 1" --border="$BORDER" --border-foreground $color "$vms_header")
	header_vms=$(gum join --vertical --align left "$vms_border" "$tip_border")
}

show_header_tip() {
	tip1=$(gum style --bold --foreground "$color2" "Tip: ")
	tip2=$(gum style "try ")
	tip3=$(shuf -n 1 "$tmpdir/supported")
	tip4=$(gum style --bold --foreground="$color" "$tip3")
	tip5=$(gum join "$tip1" "$tip2" "$tip4")
	tip6=$("$QUICKGET" "$tip3" | awk 'NR==3,NR==8')
	tip7=$(gum style --width=77 "$tip6")
	tip8=$(gum join --vertical --align top "$tip5" "$tip7")
	header_tip=$(gum style --padding "0 1" --border="$BORDER" --border-foreground $color "$tip8")
}

show_headers_small() {
	logo1=$(gum style --foreground "$color2" " ▄▄▄▄
 █  █
 █  █
 █▄▀▄")
	logo2=$(gum style "v$version")
	logo3=$(gum style --foreground "$color2" "▀")
	logo4=$(gum join "$logo2" "$logo3")
	logo5=$(gum join --vertical "$logo1" "$logo4")
	header_logo=$(gum style --padding "0 1" --border=rounded --border-foreground $color "$logo5" )

	show_header_vms
	show_header_tip

	custom1=$(gum style --bold --foreground "$color2" "workdir:")
	custom2=$(gum style "$(pwd)")
	custom3=$(gum join --vertical --align center "$custom1" "$custom2" "$(show_custom_small)")
	header_custom=$(gum style --padding "0 1"  --border="$BORDER" --border-foreground="$color" "$custom3")

	header12=$(gum join --vertical "$header_tip" "$header_custom")
	header34=$(gum join "$header_logo" "$header12")
	gum join --align top --vertical "$header34" "$header_vms"
}

show_headers_full() {
	logo0=$(gum style " simple VMs runner")
	logo1=$(gum style --foreground "$color2" " ▄▄▄▄ ▄▄▄▄ ▄  ▄  ▄
 █  █   █  █  █  █
 █  █   █  █  █  █
 █▄▀▄   █  █▄▄█  █")
	logo2=$(gum style "v$version")
	logo3=$(gum style --foreground "$color2" "▀")
	logo4=$(gum style " for ")
	logo5=$(gum style "quickemu")
	logo6=$(gum join --align center --vertical "$logo0" "$logo1")
	logo7=$(gum join "$logo2" "$logo3" "$logo4" "$logo5")
	logo8=$(gum join --vertical "$logo6" "$logo7")
	header_logo=$(gum style --align left --padding "0 1" --border=rounded --border-foreground $color "$logo8" )

	header_dep=$(gum style --padding "0 1" --border="$BORDER" --border-foreground $color "    qemu $(show_version_qemu)
quickemu $(show_version_quickemu)
$(show_editor)")

	show_header_vms
	show_header_tip

	custom1=$(gum style --bold --foreground "$color2" "workdir:")
	custom2=$(gum style "$(pwd)")
	custom3=$(gum join --vertical --align center "$custom1" "$custom2" "$(show_custom)")
	header_custom=$(gum style --padding "0 1"  --border="$BORDER" --border-foreground="$color" "$custom3")

	header1=$(gum join --vertical --align right "$header_logo" "$header_vms")
	header2=$(gum join --vertical "$header_dep" "$header_custom" "$header_tip")
	gum join --align top "$header1" "$header2"
}

show_headers() {
	if [ "$use_headers" == full ]; then
		show_headers_full
	else
		show_headers_small
	fi
}

## MENU

show_menus() {
	if [ "$icons" == yes ]; then
		show_menu_main_icons
	else
		show_menu_main
	fi
}

show_menu_main() {
	while true
	do
		height=13
		start=$(echo "create
run
OS homepage
ssh into
kill
delete
advanced
settings
help
exit $progname" | gum filter --height "$height")
# from choose:  --selected '󰜎 run'
		case $start in
			'create' ) create_VM;;
			'run' ) gum_choose_VM && run_VM;;
			'OS homepage' ) open_distro_homepage;;
			'ssh into' ) ssh_into;;
			'kill' ) kill_vm;;
			'delete' ) gum_choose_VM_to_delete;;
			'advanced' ) show_menu_advanced;;
			'settings' ) show_menu_settings;;
			'help' ) help_main; show_help;;
			"exit $progname" ) exit 0;;
		esac
	done
}

show_menu_main_icons() {
	while true
	do
	height=13
	start=$(echo " create
󰜎 run
󰖟 OS homepage
 ssh into
 kill
󰆳 delete
 advanced
 settings
󰘥 help
󰩈 exit $progname" | gum filter --height "$height")
# from choose:  --selected '󰜎 run'
	case $start in
		' create' ) create_VM;;
		'󰜎 run' ) gum_choose_VM && run_VM;;
		'󰖟 OS homepage' ) open_distro_homepage;;
		' ssh into' ) ssh_into;;
		' kill' ) kill_vm;;
		'󰆳 delete' ) gum_choose_VM_to_delete;;
		' advanced' ) show_menu_advanced_icons;;
		' settings' ) show_menu_settings_icons;;
		'󰘥 help' ) help_main; show_help;;
		"󰩈 exit $progname" )	exit 0;;
	esac
	done
}

show_menu_advanced() {
	while true
	do
	title="advanced"
	show_header
	height=11
	start=$(echo "test ISOs download
show ISOs URLs
set default config for VMs
edit VM config
custom quickemu command
add new distro
back to main menu
exit $progname" | gum filter --height "$height")
	case $start in
		'set default config for VMs' ) edit_default_VMs_config;;
		'edit VM config' ) edit_VM_config;;
		'custom quickemu command' ) custom_quickemu_command;;
		'add new distro' ) add_new_distro;;
		'test ISOs download' ) test_ISOs_download;;
		'show ISOs URLs' ) show_ISOs_urls;;
		'back to main menu') clear; show_headers; break;;
		"exit $progname" ) exit 0;;
	esac
	done
}

show_menu_advanced_icons() {
	while true
	do
	title="advanced"
	show_header
	height=11
	start=$(echo "󰙨 test ISOs download
 show ISOs URLs
 set default config for VMs
󱋆 edit VM config
 custom quickemu command
󰎔 add distro
 back to main menu
󰩈 exit $progname" | gum filter --height "$height")
	case $start in
		' set default config for VMs' ) edit_default_VMs_config;;
		'󱋆 edit VM config' ) edit_VM_config;;
		' custom quickemu command' ) custom_quickemu_command;;
		'󰎔 add distro' ) add_new_distro;;
		'󰙨 test ISOs download' ) test_ISOs_download;;
		' show ISOs URLs' ) show_ISOs_urls;;
		' back to main menu') clear; show_headers; break;;
		"󰩈 exit $progname" ) exit 0;;
	esac
	done
}

show_menu_settings() {
	while true
	do
	title="settings"
	show_header
	height=13
	start=$(echo "update $progname
regenerate supported
icons
accent color
borders color
borders style
spinner
headers
back to main menu
exit $progname" | gum filter --height "$height")
	case $start in
		"update $progname" ) update_quicktui;;
		'regenerate supported' ) generate_supported;;
		'icons' ) icons_or;;
		'accent color' ) change_color;;
		'borders color' ) change_color;;
		'borders style' ) change_borders;;
		'spinner' ) change_spinner;;
		'headers' ) headers_small_or;;
		'back to main menu') clear; show_headers; break;;
		"exit $progname" ) exit 0;;
	esac
	done
}

show_menu_settings_icons() {
	while true
	do
	title="settings"
	show_header
	height=13
	start=$(echo " update $progname
 regenerate supported
󱌝 icons
 accent color
 borders color
󰴱 borders style
 spinner
󰛼 headers
 back to main menu
󰩈 exit $progname" | gum filter --height "$height")
	case $start in
		" update $progname" ) update_quicktui;;
		' regenerate supported' ) generate_supported;;
		'󱌝 icons' ) icons_or;;
		' accent color' ) change_color;;
		' borders color' ) change_color_border;;
		'󰴱 borders style' ) change_borders;;
		' spinner' ) change_spinner;;
		'󰛼 headers' ) headers_small_or;;
		' back to main menu') clear; show_headers; break;;
		"󰩈 exit $progname" ) exit 0;;
	esac
	done
}

## RUN
#clear
define_variables
if_needed
use_color
use_icons
show_headers
show_menus
