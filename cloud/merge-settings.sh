#!/bin/sh
# Merges the settings in file $1 into the settings file $2, creating it if needed.
# Settings in $1 win and the rest of $2 is kept. A $2 that isn't valid JSON is left alone.

[ -f "$1" ] || exit 1
if [ ! -f "$2" ]; then
  mkdir -p "$(dirname "$2")" && cp "$1" "$2"
  exit
fi
jq -s '.[0] * .[1]' "$2" "$1" >"$2.new" && mv "$2.new" "$2" || {
  rm -f "$2.new"
  exit 1
}
