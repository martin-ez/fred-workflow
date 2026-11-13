#!/bin/sh
. "$(dirname "$0")/helpers.sh"
hook="$root/plugins/rules/hooks/strict-pr-gate.sh"
repo="$work/repo"

gate() {
  printf '%s' "$1" | sh "$hook"
}

run() {
  decision "$(gate "$1")"
}

new_repo "$repo"
git -C "$repo" switch -qc topic
commit_file "$repo" app.ts "export const a = 1;"

check "pushing unchecked code is denied" deny "$(run "$(bash_call 'git push -u origin HEAD' "$repo")")"
check "gh pr create is denied while code is unchecked" deny "$(run "$(bash_call 'gh pr create --fill' "$repo")")"
check "opening a pull request through the REST API is denied while code is unchecked" deny \
  "$(run "$(bash_call 'gh api repos/o/r/pulls --method POST --input pr.json' "$repo")")"
check "a create_pull_request tool is denied while code is unchecked" deny \
  "$(run "$(tool_call mcp__github__create_pull_request "$repo" "A title" "A body")")"
check "reading pull requests through the REST API is allowed" allow "$(run "$(bash_call 'gh api repos/o/r/pulls' "$repo")")"
check "deleting a remote branch is allowed" allow "$(run "$(bash_call 'git push origin --delete topic' "$repo")")"
check "unrelated commands are allowed" allow "$(run "$(bash_call 'ls' "$repo")")"
check "git -C checks the repository it names" deny "$(run "$(bash_call "git -C $repo push" "$work")")"
check_contains "the denial gives the command that records a pass" "sh '$hook' --checked" \
  "$(reason "$(gate "$(bash_call 'git push' "$repo")")")"

check_contains "--checked records the current commit" "as passing the strict checks" "$(cd "$repo" && sh "$hook" --checked)"
check "pushing after a recorded pass is allowed" allow "$(run "$(bash_call 'git push' "$repo")")"

commit_file "$repo" app.ts "export const b = 2;"
check "a code change after the recorded pass is denied" deny "$(run "$(bash_call 'git push' "$repo")")"

prose="$work/prose"
new_repo "$prose"
git -C "$prose" switch -qc docs
commit_file "$prose" GUIDE.md "More words."
check "a branch that only changes prose can be pushed" allow "$(run "$(bash_call 'git push' "$prose")")"

finish
