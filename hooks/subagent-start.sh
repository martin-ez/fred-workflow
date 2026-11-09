#!/bin/sh
# Gives subagents the same FRED context as the main session, in registered
# projects only.

command -v jq >/dev/null 2>&1 || exit 0
context=$(sh "$(dirname "$0")/session-start.sh" --registered-only)
[ -n "$context" ] || exit 0
jq -n --arg context "$context" \
  '{hookSpecificOutput: {hookEventName: "SubagentStart", additionalContext: $context}}'
