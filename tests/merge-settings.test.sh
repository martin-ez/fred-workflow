#!/bin/sh
. "$(dirname "$0")/helpers.sh"
merge="$root/cloud/merge-settings.sh"
rules="$root/plugins/rules/user-settings.json"

fresh="$work/fresh/settings.json"
sh "$merge" "$rules" "$fresh"
check "a missing settings file is created with attribution turned off" '{"commit":"","pr":"","sessionUrl":false}' \
  "$(jq -c '.attribution' "$fresh")"

existing="$work/existing.json"
printf '%s\n' '{"model": "sonnet", "attribution": {"pr": "Made by a bot"}}' >"$existing"
sh "$merge" "$rules" "$existing"
check "the rules' settings replace the same settings" '{"pr":"","commit":"","sessionUrl":false}' \
  "$(jq -c '.attribution' "$existing")"
check "other settings are kept" '"sonnet"' "$(jq -c '.model' "$existing")"

broken="$work/broken.json"
printf 'not json' >"$broken"
sh "$merge" "$rules" "$broken" 2>/dev/null
check "a settings file that isn't JSON is left alone" "not json" "$(cat "$broken")"

finish
