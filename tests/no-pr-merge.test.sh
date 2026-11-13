#!/bin/sh
. "$(dirname "$0")/helpers.sh"
hook="$root/plugins/rules/hooks/no-pr-merge.sh"

run() {
  decision "$(printf '%s' "$1" | sh "$hook")"
}

check "a merge tool is denied" deny "$(run "$(tool_call mcp__github__merge_pull_request "$work" "" "")")"
check "gh pr merge is denied" deny "$(run "$(bash_call 'gh pr merge 12 --squash' "$work")")"
check "the REST merge endpoint is denied" deny "$(run "$(bash_call 'gh api -X PUT repos/o/r/pulls/12/merge' "$work")")"
check "the GraphQL merge mutation is denied" deny "$(run "$(bash_call "gh api graphql -f query='mutation { mergePullRequest(input: {}) { clientMutationId } }'" "$work")")"
check "turning on auto-merge is denied" deny "$(run "$(bash_call "gh api graphql -f query='mutation { enablePullRequestAutoMerge(input: {}) { clientMutationId } }'" "$work")")"
check "reading pull requests is allowed" allow "$(run "$(bash_call 'gh api repos/o/r/pulls' "$work")")"
check "other tools are allowed" allow "$(run "$(tool_call mcp__github__create_pull_request "$work" "A title" "")")"
check_contains "the denial says the user merges" "Leave the pull request for the user to merge" \
  "$(reason "$(printf '%s' "$(bash_call 'gh pr merge 1' "$work")" | sh "$hook")")"

finish
