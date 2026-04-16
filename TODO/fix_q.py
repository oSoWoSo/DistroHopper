#!/usr/bin/env python3
"""Fix bugs in q command"""
import re

def main():
    with open('/home/z/Projekty/dh/q', 'r') as f:
        content = f.read()
    
    fixes = [
        # Fix 1: TERMUX comparison
        ('if [ "$TERMUX" == 1 ];', 'if [ "$TERMUX" = "1" ];'),
        
        # Fix 2: rm command (quoted)
        ('rm -r $chosen & rm $chosen.conf', 'rm -r "$chosen"; rm "$chosen".conf'),
    ]
    
    for old, new in fixes:
        content = content.replace(old, new)
    
    # Fix 3: add run_VM check
    old_run = '''run_VM() {
	title="Starting $chosen..."
	show_header
	if [ -f "${configdir}/command" ]; then
		quickemu < "${configdir}/command" -vm "$chosen.conf"
	else
			quickemu -vm "$chosen.conf"
	fi
	show_headers
}'''

    new_run = '''run_VM() {
	if [ -z "$chosen" ]; then
		gum style --foreground 1 "No VM selected!"
		show_headers
		return 1
	fi
	title="Starting $chosen..."
	show_header
	if [ -f "${configdir}/command" ]; then
		quickemu < "${configdir}/command" -vm "$chosen.conf"
	else
		quickemu -vm "$chosen.conf"
	fi
	show_headers
}'''
    
    content = content.replace(old_run, new_run)
    
    # Fix 4: ssh_into - already has the check, just ensure order is correct
    old_ssh = '''ssh_into() {
	if [ -z "$selected" ]; then
		show_headers
		return 1
	fi
	gum_choose_running
	if [ -n "$selected" ]; then
		get_ssh_port'''

    new_ssh = '''ssh_into() {
	gum_choose_running
	if [ -z "$selected" ]; then
		show_headers
		return 1
	fi
	get_ssh_port'''

    content = content.replace(old_ssh, new_ssh)
    
    # Fix 5: kill_vm
    old_kill = '''kill_vm() {
	gum_choose_running
	if [ ${#pid_files[@]} -gt 0 ]; then
		mapfile -t running < <(find . -name '*.pid' -printf '%P\\n' | sed 's/\\.pid$//')

		if [ ${#running[@]} -gt 0 ]; then
			selected=$(gum choose --select-if-one "${running[@]}")
		else
			gum style --foreground 1 "Can't!" && selected=""
		fi
	else
		gum style --foreground 1 "Can't!" && selected=""
	fi
	if [ -n "$selected" ]; then
		echo "${selected}"
		gum confirm "Really kill $selected?" && pid=$(cat "$selected".pid) && kill "$pid"
		show_headers
	fi
}'''

    new_kill = '''kill_vm() {
	gum_choose_running
	if [ -z "$selected" ]; then
		show_headers
		return 1
	fi
	echo "${selected}"
	gum confirm "Really kill $selected?" && pid=$(cat "$selected".pid) && kill "$pid"
	show_headers
}'''

    content = content.replace(old_kill, new_kill)
    
    # Fix 6: delete_VM 
    old_delete = '''delete_VM() {
	#chosen_to_delete=$(cat $chosen | while read line; echo $line | rev | cut -d'.' -f2-5 | rev; done)
	echo "#TODO"
	echo $chosen | tr " " "\\n" | while read line
	do
		echo 'Removing dir(s)...'
		rm -r $(echo $line | rev | cut -d'.' -f2-5 | rev)
	done
	echo 'Removing config(s)...'
	rm $(echo "$chosen")
}'''

    new_delete = '''delete_VM() {
	if [ -z "$chosen" ]; then
		gum style --foreground 1 "No VM selected!"
		return 1
	fi
	for vm_name in $chosen; do
		vm_dir="${vm_name}"
		vm_conf="${vm_name}.conf"
		if [ -d "$vm_dir" ]; then
			gum confirm "Really delete $vm_name directory?" && rm -rf "$vm_dir"
		fi
		if [ -f "$vm_conf" ]; then
			gum confirm "Really delete $vm_conf?" && rm -f "$vm_conf"
		fi
	done
}'''

    content = content.replace(old_delete, new_delete)
    
    with open('/home/z/Projekty/dh/q', 'w') as f:
        f.write(content)
    
    print("All fixes applied!")

if __name__ == '__main__':
    main()