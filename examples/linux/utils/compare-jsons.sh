#!/usr/bin/env bash
set -euo pipefail

# strict-json-compare.sh
# Compare JSON files across envs with type-aware canonicalization using jq.

usage() {
  echo "Usage: $0 <ref.json> <other1.json> [other2.json ...]" >&2
  exit 2
}

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 3; }
}

[[ $# -ge 2 ]] || usage

need jq
need diff
need sha256sum

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

# Build a canonical, type-annotated representation.
# - Objects: keys sorted, values normalized
# - Arrays: order preserved (if order shouldn't matter, say so and I'll change it)
# - Leaves: replaced by {"__t": "<type>", "__v": <value>}
jq_filter='
def norm:
  if type == "object" then
    to_entries
    | sort_by(.key)
    | map({key: .key, value: (.value | norm)})
    | {__t:"object", __v: .}
  elif type == "array" then
    {__t:"array", __v:(map(norm))}
  else
    {__t: type, __v: .}
  end;
norm
'

normalize() {
  local in="$1"
  local out="$2"
  jq -e -S -c "$jq_filter" "$in" > "$out"
}

ref="$1"
shift

# Validate + normalize reference
[[ -f "$ref" ]] || { echo "Ref file not found: $ref" >&2; exit 4; }
normalize "$ref" "$tmp_dir/ref.norm.json"
ref_sum="$(sha256sum "$tmp_dir/ref.norm.json" | awk '{print $1}')"

status=0

for f in "$@"; do
  [[ -f "$f" ]] || { echo "File not found: $f" >&2; status=4; continue; }

  out="$tmp_dir/$(basename "$f").norm.json"
  if ! normalize "$f" "$out"; then
    echo "Invalid JSON: $f" >&2
    status=5
    continue
  fi

  sum="$(sha256sum "$out" | awk '{print $1}')"
  if [[ "$sum" == "$ref_sum" ]]; then
    echo "OK  : $f matches $ref (structure + values + types)"
  else
    echo "DIFF: $f differs from $ref (structure/values/types)"
    diff -u "$tmp_dir/ref.norm.json" "$out" || true
    status=1
  fi
done

exit "$status"