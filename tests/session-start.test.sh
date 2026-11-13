#!/bin/sh
. "$(dirname "$0")/helpers.sh"
hook="$root/hooks/session-start.sh"
registry="$work/fred.md"

start() {
  FRED_REGISTRY="$registry" CLAUDE_PROJECT_DIR="$1" CLAUDE_PLUGIN_ROOT="$root" sh "$hook" $2
}

matched() {
  start "$1" | grep -o 'Tracker: by-[a-z]*' | tr '\n' ' ' | sed 's/ $//'
}

clone_with_origin() {
  mkdir -p "$1"
  git init -q "$1"
  git -C "$1" remote add origin "$2"
}

printf '# FRED\n\nRule for every project.\n\n## github.com/me/app\nTracker: by-repo\n' >"$registry"
clone_with_origin "$work/anywhere/app" https://github.com/me/app.git
check "a repository section matches a clone in any folder" "Tracker: by-repo" "$(matched "$work/anywhere/app")"
check_contains "the registry's rules for every project come with the section" "Rule for every project." "$(start "$work/anywhere/app")"
check_contains "the workflow comes with the section" "# FRED workflow" "$(start "$work/anywhere/app")"

clone_with_origin "$work/ssh/app" git@github.com:Me/App.git
check "a repository section matches an SSH remote in any case" "Tracker: by-repo" "$(matched "$work/ssh/app")"

clone_with_origin "$work/proxy/app" http://local_proxy@127.0.0.1:9/git/me/app
check "a repository section matches a remote behind a proxy" "Tracker: by-repo" "$(matched "$work/proxy/app")"

clone_with_origin "$work/other" https://github.com/me/other.git
check_contains "another repository gets a pointer to the workflow" "not in the user's FRED registry" "$(start "$work/other")"
check "another repository gets nothing with --registered-only" "" "$(start "$work/other" --registered-only)"

printf '# FRED\n\n## github.com/me/app\nTracker: by-repo\n\n## %s/anywhere/app\nTracker: by-folder\n' "$work" >"$registry"
check "a folder section wins over a repository section" "Tracker: by-folder" "$(matched "$work/anywhere/app")"

printf '# FRED\n\n## %s\nTracker: by-outer\n\n## %s/proj\nTracker: by-inner\n' "$work" "$work" >"$registry"
mkdir -p "$work/proj/.claude/worktrees/x"
check "the deepest folder section wins" "Tracker: by-inner" "$(matched "$work/proj")"
check "a worktree inside a project counts as that project" "Tracker: by-inner" "$(matched "$work/proj/.claude/worktrees/x")"

mkdir -p "$work/home/code/app"
printf '# FRED\n\n## ~/code/app\nTracker: by-home\n' >"$registry"
check "a folder section can start from the home folder" "Tracker: by-home" "$(HOME="$work/home" matched "$work/home/code/app")"

finish
