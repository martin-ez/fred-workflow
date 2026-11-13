#!/bin/sh
# Runs every test file and exits non-zero if any test fails.

status=0
for file in "$(dirname "$0")"/*.test.sh; do
  echo "== $(basename "$file")"
  sh "$file" || status=1
done
exit "$status"
