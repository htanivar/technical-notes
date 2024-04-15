#!/bin/bash

# Check if all three parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <name> <age> <city>"
    exit 1
fi

# Assign parameters to variables
name="$1"
age="$2"
city="$3"

# Search for the student in the CSV file
id=$(awk -F ',' -v name="$name" -v age="$age" -v city="$city" '$2==name && $3==age && $4==city {print $1}' students.csv)

# Check if the student was found
if [ -n "$id" ]; then
    echo "Student ID for $name (Age: $age, City: $city) is: $id"
else
    echo "Student not found."
fi
