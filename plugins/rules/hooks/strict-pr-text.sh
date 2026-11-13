#!/bin/sh
# PreToolUse hook: checks a pull request's title and description against the
# strict-pr rules before it is opened or edited. Countable rules are checked
# here; a model with no context of the repo judges the rest, as their reader.
# Pull requests must go through a GitHub tool, or through `gh api` with the
# text in an --input file, so that the text can be read.

model=${STRICT_PR_MODEL:-sonnet}
input=$(cat)
deny() {
  jq -n --arg reason "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}
warn() { jq -n --arg message "Strict PR check skipped: $1" '{systemMessage: $message}'; exit 0; }
field() { printf '%s' "$input" | jq -r "$1 // empty"; }

tool=$(field .tool_name)
title=$(field .tool_input.title)
body=$(field .tool_input.body)
if [ "$tool" = Bash ]; then
  command=$(field .tool_input.command)
  via="Open pull requests with a GitHub tool's create_pull_request, and change a title or description with its update_pull_request. Where there is no such tool, use \`gh api repos/OWNER/REPO/pulls --method POST --input FILE\`, or \`gh api repos/OWNER/REPO/pulls/N --method PATCH --input FILE\`, where FILE is JSON with the title and body (and head, base and draft when opening). The strict PR check reads the text from there. Write it as the strict-pr skill says."
  start='(^|[;&|(])[[:space:]]*gh[[:space:]]+pr[[:space:]]+'
  printf '%s\n' "$command" | grep -Eq "${start}create([[:space:]]|\$)" && deny "$via"
  printf '%s\n' "$command" | grep -Eq "${start}edit[[:space:]].*(--title|--body|[[:space:]]-[tbF][[:space:]])" && deny "$via"
  # A pull request opened or edited through the REST API.
  pulls=$(printf '%s\n' "$command" | grep -Eo '(^|[;&|(])[[:space:]]*gh[[:space:]]+api[[:space:]][^;&|]*' |
    grep -E '/pulls(/[0-9]+)?(["'"'"'[:space:]]|$)' | head -n 1)
  [ -n "$pulls" ] || exit 0
  printf '%s\n' "$pulls" | grep -Eq -- '--input|--method[[:space:]=]+(POST|PATCH)|-X[[:space:]]*(POST|PATCH)|[[:space:]]-[fF][[:space:]]|--(raw-)?field' || exit 0
  file=$(printf '%s\n' "$pulls" | sed -nE 's/.*--input[[:space:]=]+([^[:space:]]+).*/\1/p' | tr -d "\"'")
  [ -n "$file" ] && [ "$file" != - ] || deny "$via"
  case "$file" in /*) ;; *) file="$(field .cwd)/$file" ;; esac
  [ -r "$file" ] || deny "The --input file $file can't be read. $via"
  title=$(jq -r '.title // empty' "$file" 2>/dev/null)
  body=$(jq -r '.body // empty' "$file" 2>/dev/null)
  printf '%s\n' "$pulls" | grep -Eq '/pulls(["'"'"'[:space:]]|$)' && tool=create_pull_request
fi
[ -n "$title$body" ] || exit 0
problems=
add() { problems="$problems
- $1"; }
case "$tool" in *create_pull_request) [ -n "$body" ] || add "Add a description: one to three sentences, then a \"## Changes\" section." ;; esac

cd "$(field .cwd)" 2>/dev/null && top=$(git rev-parse --show-toplevel 2>/dev/null) || top=
for base in "$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master main master; do
  [ -n "$top" ] && [ -n "$base" ] && git rev-parse -q --verify "$base^{commit}" >/dev/null && break
  base=
done

if [ -n "$title" ]; then
  [ "$(printf '%s' "$title" | wc -m)" -le 72 ] || add "Shorten the title to 72 characters or fewer."
  printf '%s' "$title" | grep -q '#[0-9]' && add "Take the issue number out of the title; close the issue from the description instead."
  prefix='^[a-z]+(\([^)]*\))?!?: '
  if [ -n "$base" ] && printf '%s' "$title" | grep -Eq "$prefix"; then
    recent=$(git log -n 30 --format=%s "$base")
    [ $(($(printf '%s\n' "$recent" | grep -Ec "$prefix") * 2)) -ge "$(printf '%s\n' "$recent" | wc -l)" ] ||
      add "Drop the type prefix from the title: this repository's titles don't use them."
  fi
fi

if [ -n "$body" ]; then
  case "$(printf '%s\n' "$body" | grep -m1 -v '^[[:space:]]*$')" in
    "#"*) add "Open the description with one to three sentences on what the change does and why, before any heading." ;;
  esac
  printf '%s\n' "$body" | grep -Eq '^## Changes[[:space:]]*$' || add "Add a \"## Changes\" section with a few high-level bullets on how it is done."
  words=$(printf '%s\n' "$body" | awk '
    /^#/ && seen && !/^## Changes[[:space:]]*$/ { exit }
    /^## Changes[[:space:]]*$/ { seen = 1 }
    !/^(Close[sd]?|Fix(e[sd])?|Resolve[sd]?) / { print }' | wc -w | tr -d ' ')
  [ "$words" -le 150 ] || add "Cut the opening and Changes to under 150 words (they are $words)."
fi

retry="Rewrite the title and description as the strict-pr skill says, then retry."
[ -z "$problems" ] || deny "Strict PR check:$problems
$retry"

# The judge: a model that knows nothing of the repo, given only the text, the
# repo's pull request template and the user's recent messages.
command -v claude >/dev/null 2>&1 || warn "the claude CLI is not on PATH."
template=
if [ -n "$top" ]; then
  file=$(git -C "$top" ls-files | grep -i -m1 'pull_request_template')
  [ -n "$file" ] && template=$(head -c 4000 "$top/$file")
fi
messages=$(jq -rs '[.[] | select(.type == "user" and .isMeta != true and .isCompactSummary != true)
  | .message.content | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end
  | select(length > 0 and (startswith("<") | not)) | .[0:800]] | .[-8:] | map("- " + .) | join("\n")' \
  "$(field .transcript_path)" 2>/dev/null)

rules='You review a pull request'"'"'s title and description before they are published. You are their intended reader: someone who does not know this repository and has not seen the change. Check them against these rules:
1. From the title and the opening alone, you can tell what the change does and why. They use plain words, with no internal jargon, codenames or unexplained abbreviations.
2. The description opens with one to three sentences, then a "## Changes" section.
3. Changes explains how the change is done at a high level, in a few short bullets. It has no file paths, lists of functions or classes, line-level detail, or walk through the diff. Naming something the reader needs, such as a new command or setting, is fine.
4. There is nothing else: no other sections, checklists, test plans, emoji or sign-offs, unless the repository'"'"'s pull request template or the user'"'"'s messages explicitly ask for them. Lines that close an issue, such as "Closes #12", are fine.
Length, issue numbers in the title and title prefixes such as "feat:" are checked elsewhere; ignore them. When only the title or only the description is given, judge what is given. Be strict but fair: report only real violations, each as a short instruction saying what to change. ok is true only when there are none.'
schema='{"type":"object","properties":{"ok":{"type":"boolean"},"problems":{"type":"array","items":{"type":"string"}}},"required":["ok","problems"]}'
judge_dir="${TMPDIR:-/tmp}/strict-pr-judge"
mkdir -p "$judge_dir"
verdict=$(printf 'Title: %s\n\nDescription:\n%s\n\nThe repository'"'"'s pull request template:\n%s\n\nThe user'"'"'s recent messages to the agent:\n%s\n' \
    "${title:-(not changed)}" "${body:-(not changed)}" "${template:-(none)}" "${messages:-(none)}" |
  (cd "$judge_dir" && claude -p --model "$model" --setting-sources project --strict-mcp-config --tools "" \
    --no-session-persistence --system-prompt "$rules" --output-format json --json-schema "$schema" 2>/dev/null) |
  jq -c '.structured_output // empty' 2>/dev/null)
[ -n "$verdict" ] || warn "the reviewing model gave no verdict."
[ "$(printf '%s' "$verdict" | jq -r .ok)" = true ] && exit 0
deny "Strict PR check:$(printf '%s' "$verdict" | jq -r '.problems | map("\n- " + .) | join("")')
$retry"
