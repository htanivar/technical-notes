#!/bin/bash

# Define the two-dimensional array for student information
students=(
    ("Alice" "101" "20" "New York")
    ("Bob" "102" "22" "Los Angeles")
    ("Charlie" "103" "21" "Chicago")
)

# Check if all three parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <name> <age> <city>"
    exit 1
fi

# Assign parameters to variables
name="$1"
age="$2"
city="$3"

# Search for the student in the two-dimensional array
found=false
for ((i = 0; i < ${#students[@]}; i++)); do
    if [[ "${students[i][0]}" == "$name" && "${students[i][2]}" == "$age" && "${students[i][3]}" == "$city" ]]; then
        echo "Student ID for $name (Age: $age, City: $city) is: ${students[i][1]}"
        found=true
        break
    fi
done

# Check if the student was found
if [ "$found" = false ]; then
    echo "Student not found."
fi
