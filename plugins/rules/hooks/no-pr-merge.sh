#!/bin/sh
# Blocks merging pull requests, through a GitHub tool, gh or the GitHub API:
# agents open and update pull requests, and only the user merges them.

input=$(cat)
deny() {
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "Agents never merge pull requests, only open and update them. Leave the pull request for the user to merge and tell them it is ready."}}'
  exit 0
}

case "$(printf '%s' "$input" | jq -r '.tool_name // empty')" in
  *merge_pull_request) deny ;;
esac
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$command" ] || exit 0

if printf '%s' "$command" | grep -Eq '\bgh\b.*\bpr[[:space:]]+merge\b|/pulls/[0-9]+/merge\b|mergePullRequest|enablePullRequestAutoMerge'; then
  deny
fi
