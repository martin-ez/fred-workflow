#!/bin/sh
. "$(dirname "$0")/helpers.sh"
hook="$root/plugins/rules/hooks/strict-pr-text.sh"
repo="$work/repo"
export TMPDIR="$work"

mkdir -p "$work/judge" "$work/nojudge"
printf '#!/bin/sh\ncat >/dev/null\nprintf "%%s\\n" "$VERDICT"\n' >"$work/judge/claude"
chmod +x "$work/judge/claude"
ln -s "$(command -v jq)" "$work/nojudge/jq"
ok='{"structured_output": {"ok": true, "problems": []}}'
export VERDICT="$ok"

text() {
  printf '%s' "$1" | PATH="$work/judge:$PATH" sh "$hook"
}

run() {
  decision "$(text "$1")"
}

body='Lets the backend run its tests, so that pull requests are checked.

## Changes
- Adds a test command
- Runs it in CI

Closes #7'
title="Run the backend tests on every pull request"

new_repo "$repo"
create() {
  tool_call mcp__github__create_pull_request "$repo" "$1" "$2"
}

check "gh pr create is denied" deny "$(run "$(bash_call 'gh pr create --title x --body y' "$repo")")"
check_contains "the denial points to gh api with an --input file" "--input FILE" \
  "$(reason "$(text "$(bash_call 'gh pr create' "$repo")")")"
check "gh pr edit with a new title is denied" deny "$(run "$(bash_call 'gh pr edit 3 --title x' "$repo")")"
check "gh pr edit without new text is allowed" allow "$(run "$(bash_call 'gh pr edit 3 --add-label x' "$repo")")"
check "gh api opening a pull request without --input is denied" deny \
  "$(run "$(bash_call 'gh api repos/o/r/pulls -f title=x -f body=y' "$repo")")"
check "gh api with an --input file that can't be read is denied" deny \
  "$(run "$(bash_call 'gh api repos/o/r/pulls --method POST --input missing.json' "$repo")")"
jq -n --arg t "A title that goes on for far too long to fit in the seventy-two characters" --arg b "$body" \
  '{title: $t, body: $b}' >"$repo/long.json"
check_contains "gh api text is read from its --input file" "Shorten the title" \
  "$(reason "$(text "$(bash_call 'gh api repos/o/r/pulls --method POST --input long.json' "$repo")")")"
jq -n --arg t "$title" --arg b "$body" '{title: $t, body: $b}' >"$repo/good.json"
check "gh api with good text in its --input file is allowed" allow \
  "$(run "$(bash_call 'gh api repos/o/r/pulls/3 --method PATCH --input good.json' "$repo")")"
check "gh api calls that don't write a pull request are allowed" allow \
  "$(run "$(bash_call 'gh api repos/o/r/pulls/3/comments -f body=hi' "$repo")")"

check_contains "a new pull request needs a description" "Add a description" "$(reason "$(text "$(create "$title" "")")")"
check_contains "a title over 72 characters is denied" "Shorten the title" \
  "$(reason "$(text "$(create "A title that goes on for far too long to fit in the seventy-two characters" "$body")")")"
check_contains "an issue number in the title is denied" "Take the issue number out" "$(reason "$(text "$(create "Run tests for #7" "$body")")")"
check_contains "a type prefix is denied where titles don't use one" "Drop the type prefix" \
  "$(reason "$(text "$(create "feat: run the tests" "$body")")")"
check_contains "a description that opens with a heading is denied" "Open the description" \
  "$(reason "$(text "$(create "$title" "## Changes
- x")")")"
check_contains "a description without a Changes section is denied" 'Add a "## Changes" section' \
  "$(reason "$(text "$(create "$title" "Does a thing.")")")"
check_contains "a description over 150 words is denied" "Cut the opening and Changes" \
  "$(reason "$(text "$(create "$title" "$(printf 'word %.0s' $(seq 1 151))

## Changes
- x")")")"

check "text the judge accepts is allowed" allow "$(run "$(create "$title" "$body")")"
check "an update with only a title is judged on the title" allow \
  "$(run "$(tool_call mcp__github__update_pull_request "$repo" "$title" "")")"
check_contains "text the judge rejects is denied with its problems" "Say why it matters." \
  "$(reason "$(export VERDICT='{"structured_output": {"ok": false, "problems": ["Say why it matters."]}}'; text "$(create "$title" "$body")")")"
check "without the claude CLI the check warns and lets the text through" warn \
  "$(decision "$(printf '%s' "$(create "$title" "$body")" | PATH="$work/nojudge:/usr/bin:/bin" sh "$hook")")"

prefixed="$work/prefixed"
new_repo "$prefixed" "feat: add a readme"
check "a type prefix is allowed where titles use one" allow \
  "$(run "$(tool_call mcp__github__create_pull_request "$prefixed" "feat: run the tests" "$body")")"

finish
