#!/bin/bash

# Function to display help
display_help() {
  echo "Usage: $0 [option]"
  echo "Options:"
  echo "  1    Select a field from an object"
  echo "  2    Select multiple fields"
  echo "  3    Filter objects based on a condition"
  echo "  4    Iterate over arrays"
  echo "  5    Extract nested fields"
  echo "  6    Map over arrays"
  echo "  7    Add fields to objects"
  echo "  8    Remove fields from objects"
  echo "  9    Concatenate arrays"
  echo "  10   Sort arrays"
  echo "  11   Group by a field"
  echo "  12   Count elements in an array"
  echo "  13   Get unique values from an array"
  echo "  14   Join array elements with a separator"
  echo "  15   Format JSON output"
  echo "  16   Parse CSV"
  echo "  17   Convert JSON to CSV"
  echo "  18   Check if a key exists"
  echo "  19   Set default value if key is missing"
  echo "  20   Conditional (if-else)"
  echo "  21   Get distinct elements based on a key"
  echo "  22   Sum values in an array"
  echo "  23   Average values in an array"
  echo "  24   Extract keys from an object"
  echo "  25   Flatten nested arrays"
  echo "  26   Split a string"
  echo "  27   Convert Unix epoch to human-readable date"
  echo "  -h   Display this help message"
}

# Check if no arguments were passed
if [ $# -eq 0 ]; then
  display_help
  exit 1
fi

# Create the complex JSON file
bash setup.sh

# Execute the selected JQ command
case $1 in
  1) cat complex.json | jq '.government.name' ;;
  2) cat complex.json | jq '{government: .government.name, school: .school.name}' ;;
  3) cat complex.json | jq 'map(select(.school.students[]?.age > 30))' ;;
  4) cat complex.json | jq '.government.state[]' ;;
  5) cat complex.json | jq '.government.state[].skills' ;;
  6) cat complex.json | jq 'map(.government.state[].name)' ;;
  7) cat complex.json | jq '.government.state[] + {capital: "Unknown"}' ;;
  8) cat complex.json | jq 'map(del(.government.state[].skills))' ;;
  9) cat complex.json | jq '.government.state[].skills + .school.students[].skills' ;;
  10) cat complex.json | jq 'sort_by(.government.state[].name)' ;;
  11) cat complex.json | jq 'group_by(.government.state[].name)' ;;
  12) cat complex.json | jq '.government.state | length' ;;
  13) cat complex.json | jq 'map(.government.state[].name) | unique' ;;
  14) cat complex.json | jq '.government.state[].skills | join(", ")' ;;
  15) cat complex.json | jq '.' ;;
  16) cat input.csv | jq -R -s -c 'split("\n") | .[1:] | map(split(",")) | map({key1: .[0], key2: .[1]})' ;;
  17) cat complex.json | jq -r '(map(keys) | add | unique) as \$keys | \$keys, map([.[ \$keys[] ]])[] | @csv' ;;
  18) cat complex.json | jq 'has("government")' ;;
  19) cat complex.json | jq '.school.fees.hostel // 0' ;;
  20) cat complex.json | jq 'if .school.students[]?.age > 30 then "senior" else "junior" end' ;;
  21) cat complex.json | jq 'unique_by(.school.students[].name)' ;;
  22) cat complex.json | jq 'map(.school.students[].age) | add' ;;
  23) cat complex.json | jq 'map(.school.students[].age) | add / length' ;;
  24) cat complex.json | jq 'keys' ;;
  25) cat complex.json | jq 'flatten' ;;
  26) cat complex.json | jq '.school.name | split(" ")' ;;
  27) cat complex.json | jq '(.school.fees.college | todate)' ;;
  -h) display_help ;;
  *) echo "Invalid option. Use -h for help." ;;
esac
