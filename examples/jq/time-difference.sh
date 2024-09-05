#!/bin/bash

# Check if input file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_json_file>"
  exit 1
fi

input_file=$1

# Use jq to handle timestamps, calculate time differences, and include key in the output
jq '
  [.config.account[] | {key, ts: (.ts | sub("\\.[0-9]+\\+[0-9:]+$"; "Z") | fromdateiso8601)}] as $entries |
  reduce range(1; length) as $i (
    [];
    . + [{
      key: $entries[$i].key,
      ts_diff: ($entries[$i].ts - $entries[$i - 1].ts),
      current_ts: ($entries[$i].ts | todate),
      previous_ts: ($entries[$i - 1].ts | todate)
    }]
  )
' "$input_file"
