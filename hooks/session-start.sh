#!/bin/sh
# Adds the FRED workflow to the session's context when the project is listed
# in the user's registry; elsewhere, leaves a one-line pointer to it, unless
# called with --registered-only.

project="${CLAUDE_PROJECT_DIR:-$PWD}"
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
registry="${FRED_REGISTRY:-$HOME/.claude/fred.md}"

# The registry section whose folder holds the project; the deepest one wins,
# so a worktree inside a project counts as that project.
section=$(awk -v project="$project/" -v home="$HOME" '
  /^## / {
    folder = substr($0, 4)
    sub(/[ \t]+$/, "", folder)
    sub(/\/+$/, "", folder)
    if (substr(folder, 1, 1) == "~") folder = home substr(folder, 2)
    keep = index(project, folder "/") == 1 && length(folder) > deepest
    if (keep) { deepest = length(folder); found = "" }
  }
  keep { found = found $0 "\n" }
  END { printf "%s", found }
' "$registry" 2>/dev/null)

if [ -n "$section" ]; then
  cat "$root/WORKFLOW.md"
  printf '\n---\n\nFrom the user'"'"'s FRED registry (%s):\n\n' "$registry"
  awk '/^## /{exit} {print}' "$registry"
  printf '%s' "$section"
elif [ "$1" != "--registered-only" ]; then
  echo "The FRED workflow is installed, but this project is not in the user's FRED registry ($registry). If the user wants to use FRED here, read $root/WORKFLOW.md and set the project up."
fi
