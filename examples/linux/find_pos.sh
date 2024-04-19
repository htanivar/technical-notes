#!/bin/bash

# Function to find the position of an element in an array
# Usage: find_position array_name value_to_find
find_position() {
    local array=("${!1}")  # Get the array from the first parameter
    local value="$2"       # Get the value to find from the second parameter
    local positions=()     # Array to store positions of the value

    # Loop through the array to find the positions of the value
    for (( i = 0; i < ${#array[@]}; i++ )); do
        if [[ "${array[i]}" == "$value" ]]; then
            positions+=("$i")  # Add position to the positions array
        fi
    done

    # Print the positions of the value
    if [ ${#positions[@]} -eq 0 ]; then
        echo "Value '$value' not found in the array."
    else
        echo "Value '$value' found at positions: ${positions[@]}"
    fi
}

# Example usage:
my_array=("Apple" "Banana" "Cherry" "Date" "Banana")
find_position my_array "Banana"
