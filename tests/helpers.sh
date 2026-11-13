root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failed=0

check() {
  if [ "$2" = "$3" ]; then
    echo "ok    $1"
  else
    echo "FAIL  $1: expected [$2], got [$3]"
    failed=1
  fi
}

check_contains() {
  case "$3" in
    *"$2"*) echo "ok    $1" ;;
    *) echo "FAIL  $1: [$3] lacks [$2]"; failed=1 ;;
  esac
}

decision() {
  [ -n "$1" ] || { echo allow; return; }
  printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecision // (if .systemMessage then "warn" else "allow" end)'
}

reason() {
  printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecisionReason // .systemMessage // empty'
}

bash_call() {
  jq -n --arg c "$1" --arg d "$2" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}'
}

tool_call() {
  jq -n --arg t "$1" --arg d "$2" --arg ti "$3" --arg b "$4" \
    '{tool_name: $t, cwd: $d, tool_input: ((if $ti == "" then {} else {title: $ti} end) + (if $b == "" then {} else {body: $b} end))}'
}

new_repo() {
  git init -q -b main "$1"
  git -C "$1" config user.name test
  git -C "$1" config user.email test@example.com
  echo base >"$1/README.md"
  git -C "$1" add README.md
  git -C "$1" commit -qm "${2:-Add a readme}"
  git -C "$1" update-ref refs/remotes/origin/main HEAD
}

commit_file() {
  echo "$3" >>"$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit -qm "Change $2"
}

finish() {
  [ "$failed" = 0 ] && echo "all passed" || echo "some failed"
  exit "$failed"
}
