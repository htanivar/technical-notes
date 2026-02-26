#!/usr/bin/env bash

printf "%-20s %-10s %-10s %-10s %-10s %-10s %-20s %-15s\n" \
"Filesystem" "Type" "Total" "Used" "Avail" "Avail%" "Mount" "Comment"
printf "%-20s %-10s %-10s %-10s %-10s %-10s %-20s %-15s\n" \
"----------" "----" "-----" "----" "-----" "------" "-----" "-------"

df -hT --exclude-type=tmpfs --exclude-type=devtmpfs | tail -n +2 | while read -r fs type size used avail usep mount; do
  usep_val=${usep%\%}
  availp=$((100 - usep_val))

  comment=""
  if [ "$usep_val" -gt 60 ]; then
    comment="ACTION NEEDED"
  fi

  printf "%-20s %-10s %-10s %-10s %-10s %-9s%% %-20s %-15s\n" \
  "$fs" "$type" "$size" "$used" "$avail" "$availp" "$mount" "$comment"
done

