#!/bin/bash

# Define function for Yad dialog box
function show_dialog {
  yad --title="DistroHopper" \
    --text="Please select an option:" \
    --button="Help:1" \
    --button="Choose VM directory:2" \
    --button="Install:3" \
    --button="Portable mode:4" \
    --button="Update supported VMs:5" \
    --button="Update ready VMs:6" \
    --button="Run TUI:7" \
    --button="Start GUI:8" \
    --button="Add new distro:9" \
    --button="Sort functions:10" \
    --button="Push changes:11" \
    --button="Copy ISOs:12" \
    --button="Translate:13" \
    --button="Run new TUI:14"
}

# Call Yad function and store result in $button
button=$(show_dialog)

# Parse $button and execute corresponding function
case $button in
  1) help_show ;;
  2) virtual_machines_directory_choose ;;
  3) echo $"Starting installation..." ; installation_process ;;
  4) echo $"Switching to portable mode!" ; work_in_current_dir ;;
  5) echo $"Updating supported VMs..." ; virtual_machines_update_supported ;;
  6) echo $"Updating ready VMs..." ; virtual_machines_update_ready ;;
  7) echo $"Running DistroHopper TUI..." ; distrohopper_run_tui ;;
  8) echo $"Starting DistroHopper GUI..." ; distrohopper_run_gui ;;
  9) echo $"Adding new distro started..." ; add_distro ;;
  10) echo $"Sorting functions in template..." ; TOOL_sort_functions_in_quickget ;;
  11) echo $"Pushing changes to... #TODO" ; push_changes ;;
  12) echo $"Copying ISOs to dir. It will take some time..." ; TOOL_copy_ISOs_to_dir ;;
  13) TOOL_translate ;;
  14) run_tui_new ;;
  *) echo $"No option selected." ;;

esac
