#!/bin/sh
# Adds the FRED workflow to the session's context when the project is listed
# in the user's registry; elsewhere, leaves a one-line pointer to it, unless
# called with --registered-only.

project="${CLAUDE_PROJECT_DIR:-$PWD}"
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
registry="${FRED_REGISTRY:-$HOME/.claude/fred.md}"

origin_owner_and_repo=$(git -C "$project" remote get-url origin 2>/dev/null |
  sed -E 's#/+$##; s#\.git$##; s#^.*[/:]([^/:]+/[^/:]+)$#\1#' | tr '[:upper:]' '[:lower:]')

section=$(awk -v project="$project/" -v home="$HOME" -v repo="$origin_owner_and_repo" '
  /^## / {
    name = substr($0, 4)
    sub(/[ \t]+$/, "", name)
    sub(/\/+$/, "", name)
    infolder = inrepo = 0
    if (name ~ /^[~\/]/) {
      if (substr(name, 1, 1) == "~") name = home substr(name, 2)
      infolder = (index(project, name "/") == 1 && length(name) > deepest)
      if (infolder) { deepest = length(name); folder = "" }
    } else if (repo != "") {
      n = split(tolower(name), part, "/")
      inrepo = (n >= 2 && (part[n - 1] "/" part[n]) == repo)
      if (inrepo) byrepo = ""
    }
  }
  infolder { folder = folder $0 "\n" }
  inrepo { byrepo = byrepo $0 "\n" }
  END { printf "%s", (folder != "" ? folder : byrepo) }
' "$registry" 2>/dev/null)

if [ -n "$section" ]; then
  cat "$root/WORKFLOW.md"
  printf '\n---\n\nFrom the user'"'"'s FRED registry (%s):\n\n' "$registry"
  awk '/^## /{exit} {print}' "$registry"
  printf '%s' "$section"
elif [ "$1" != "--registered-only" ]; then
  echo "The FRED workflow is installed, but this project is not in the user's FRED registry ($registry). If the user wants to use FRED here, read $root/WORKFLOW.md and set the project up."
fi
