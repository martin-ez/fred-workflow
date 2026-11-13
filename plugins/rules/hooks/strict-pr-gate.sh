#!/bin/sh
# PreToolUse hook: blocks opening a pull request, or pushing to one, while the
# branch has code that hasn't passed the strict-tests and strict-comments skills.
# Run it with --checked inside a repo to record that its current commit passed.

stamp() { git rev-parse --git-path strict-checked; }

if [ "$1" = --checked ]; then
  git rev-parse HEAD > "$(stamp)" || exit 1
  echo "Recorded $(git rev-parse --short HEAD) as passing the strict checks."
  exit 0
fi

opens_pull_request_through_api() {
  printf '%s\n' "$1" | grep -Eq '(^|[;&|(])[[:space:]]*gh[[:space:]]+api[[:space:]][^;&|]*/pulls(["'"'"'[:space:]]|$)' &&
    printf '%s\n' "$1" | grep -Eq -- '--input|--method[[:space:]=]+POST|-X[[:space:]]*POST|[[:space:]]-[fF][[:space:]]|--(raw-)?field'
}

push_or_create='(^|[;&|(])[[:space:]]*(git([[:space:]]+-C[[:space:]]+[^[:space:];&|]+)?[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create)([[:space:]]|$)'

runs_after_other_commands() {
  case "$2" in [\;\&\|\(]*) return 0 ;; esac
  ! printf '%s\n' "$1" | grep -m 1 '[^[:space:]]' | grep -Eq "$push_or_create"
}

deny() {
  jq -n --arg reason "Strict PR gate: $1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

self="$(cd "$(dirname "$0")" && pwd)/strict-pr-gate.sh"
input=$(cat)
case "$input" in
  *git*push*|*gh*pr*create*|*gh*api*pulls*|*create_pull_request*) ;;
  *) exit 0 ;;
esac
dir=$(printf '%s' "$input" | jq -r '.cwd // empty')

if [ "$(printf '%s' "$input" | jq -r '.tool_name')" = Bash ]; then
  command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  match=$(printf '%s\n' "$command" | grep -Eo "$push_or_create" | head -n 1)
  [ -n "$match" ] || opens_pull_request_through_api "$command" || exit 0
  case "$command" in *--delete*) exit 0 ;; esac
  [ -n "$match" ] && runs_after_other_commands "$command" "$match" &&
    deny "run \`git push\` or \`gh pr create\` as its own command, not chained after other commands. The gate checks the branch before the command runs, so changes made earlier in the same command would skip the strict checks."
  path=$(printf '%s' "$match" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | tr -d "\"'")
  case "$path" in "~"*) path="$HOME${path#\~}" ;; esac
  [ -n "$path" ] && dir=$(cd "$dir" 2>/dev/null; cd "$path" 2>/dev/null && pwd)
fi
cd "$dir" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1 || exit 0

for base in "$(git symbolic-ref -q --short refs/remotes/origin/HEAD)" origin/main origin/master main master; do
  [ -n "$base" ] && git rev-parse -q --verify "$base^{commit}" >/dev/null && break
  base=
done
fork=$(git merge-base "$base" HEAD 2>/dev/null) || exit 0
last_pass_or_fork=$(cat "$(stamp)" 2>/dev/null)
git merge-base --is-ancestor "$fork" "$last_pass_or_fork" 2>/dev/null &&
  git merge-base --is-ancestor "$last_pass_or_fork" HEAD || last_pass_or_fork=$fork
git diff --name-only "$last_pass_or_fork" HEAD | grep -Evq '\.(md|mdx|txt)$|(^|/)docs/' || exit 0

deny "this branch's code has changed since it last passed the strict checks. Run the strict-tests skill and then the strict-comments skill (tests first, since new tests can add comments) on the branch diff, and commit their fixes. Then run \`sh '$self' --checked\` from the repo and retry."
