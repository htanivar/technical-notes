#!/bin/bash

# Function to get student mark
get_student_mark() {
  local student="$1"
  local college="$2"
  local subject="$3"
  local file="/home/ravi/code/technical-notes/examples/linux/bash_scripts/config/student.csv"
  local port="2245"

  if [ ! -f "$file" ]; then
    echo "Error: File $file not found!"
    return 1
  fi

  while IFS=, read -r Student College Subject URL Mark; do
    if [[ "$Student" == "$student" && "$College" == "$college" && "$Subject" == "$subject" ]]; then
      # Extract base URL (before the port)
      base_url=$(echo "$URL" | cut -d: -f1,2)
      # Combine base URL with new port
      combined_url="${base_url}:${port}"
      echo "Student: $Student"
      echo "College: $College"
      echo "Subject: $Subject"
      echo "URL: $combined_url"
      echo "Mark: $Mark"
      return 0
    fi
  done < <(tail -n +2 "$file")  # Skip header line

  echo "No matching record found for Student: $student, College: $college, Subject: $subject."
  return 1
}

# Ensure script is executed with three arguments
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <student> <college> <subject>"
  exit 1
fi

# Call the function with arguments
get_student_mark "$1" "$2" "$3"
