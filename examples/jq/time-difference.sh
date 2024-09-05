#!/bin/bash

# Check if input file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_json_file>"
  exit 1
fi

input_file=$1

# Use jq to handle timestamps, calculate time differences, and include all entries
jq '
  [.config.account[] | {key, ts: (.ts | sub("\\.[0-9]+\\+[0-9:]+$"; "Z") | fromdateiso8601)}] as $entries |
  [range(0; length)] as $indices |
  map({
    key: $entries[.].key,
    ts_diff: (if . > 0 then ($entries[.] | .ts - $entries[. - 1].ts) else null end),
    current_ts: ($entries[.].ts | todate),
    previous_ts: (if . > 0 then ($entries[. - 1].ts | todate) else null end)
  })
' "$input_file"
