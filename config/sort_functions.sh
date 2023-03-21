#!/bin/bash

# Get the name of the script from the command line argument
script_name=$1

# Get a list of all the function names in the script
function_names=$(grep -oP '^[[:space:]]*function \K\w+' "$script_name")

# Sort the function names alphabetically
sorted_function_names=$(echo "$function_names" | sort)

# Loop through the sorted function names and print the function definitions
for function_name in $sorted_function_names
do
# Print the function definition to stdout
grep -A $(wc -l < "$script_name") -w "function $function_name" "$script_name"
done
