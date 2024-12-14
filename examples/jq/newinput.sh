#!/bin/bash

# Check if input file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_json_file>"
  exit 1
fi

input_file=$1
output_file="new_input.json"

# Use jq to generate a new JSON file with current_ts and previous_ts
jq '
  [.config.account[]? | {key, ts: (.ts | sub("\\.[0-9]+\\+[0-9:]+$"; "Z") | fromdateiso8601)}]
  | sort_by(.ts)
  | [range(0; length)] as $indices
  | map({
      key: .key,
      ts: (.ts | todate),
      previous_ts: (if . > 0 then (.[.-1].ts | todate) else null end)
    })
' "$input_file" > "$output_file"

echo "New input file with 'previous_ts' has been generated: $output_file"
