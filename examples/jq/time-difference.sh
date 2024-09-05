#!/bin/bash

# Check if input file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_json_file>"
  exit 1
fi

input_file=$1

# Use jq to extract timestamps and calculate time differences
jq '
  [.config.account[].ts | fromdateiso8601] as $timestamps |
  reduce range(1; length) as $i (
    [];
    . + [{ts_diff: ($timestamps[$i] - $timestamps[$i - 1]), current_ts: $timestamps[$i], previous_ts: $timestamps[$i - 1]}]
  )
' "$input_file"
