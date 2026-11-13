#!/bin/bash
# Setup script for a Claude Code cloud environment: fetches this repository to
# /opt/claude/fred-workflow and installs the rules plugin's instructions and user
# settings for the session. It always exits 0; /opt/claude/setup.log says what it did.

repo=martin-ez/fred-workflow
ref=main
dest=${FRED_CLOUD_DIR:-/opt/claude}
user=${FRED_CLOUD_USER_DIR:-$HOME/.claude}
dir=$dest/fred-workflow
raw=https://raw.githubusercontent.com/$repo/$ref

download_listed_files() {
  rm -rf "$dir" && mkdir -p "$dir" || return 1
  curl -fsSL "$raw/files.txt" -o "$dir/files.txt" || return 1
  while read -r file; do
    [ -n "$file" ] || continue
    mkdir -p "$dir/$(dirname "$file")"
    curl -fsSL "$raw/$file" -o "$dir/$file" || return 1
  done <"$dir/files.txt"
}

mkdir -p "$dest"
rm -rf "$dir"
{
  if git clone --quiet --depth 1 --branch "$ref" "https://github.com/$repo.git" "$dir"; then
    echo "Cloned $repo at $(git -C "$dir" rev-parse --short HEAD)."
  elif download_listed_files; then
    echo "Downloaded the files listed in $raw/files.txt."
  else
    echo "Could not fetch $repo."
  fi
  if [ -f "$dir/plugins/rules/instructions.md" ]; then
    mkdir -p "$user" && cp "$dir/plugins/rules/instructions.md" "$user/CLAUDE.md" &&
      echo "Installed the instructions as $user/CLAUDE.md."
  fi
  if [ -f "$dir/plugins/rules/user-settings.json" ]; then
    if sh "$dir/cloud/merge-settings.sh" "$dir/plugins/rules/user-settings.json" "$user/settings.json"; then
      echo "Merged the rules plugin's user settings into $user/settings.json."
    else
      echo "Could not merge the rules plugin's user settings into $user/settings.json."
    fi
  fi
} >"$dest/setup.log" 2>&1
exit 0
