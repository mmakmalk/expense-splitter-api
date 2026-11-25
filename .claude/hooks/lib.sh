#!/usr/bin/env bash
# Shared helpers for hook scripts. Source it after reading stdin into $input.
# No jq on this machine, so we pull simple string fields out of the hook JSON with grep/sed.

# json_field NAME -> prints the unescaped string value of "NAME" from $input (first match).
json_field() {
  printf '%s' "$input" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -n 1 \
    | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//" \
    | sed -E 's/\\"/"/g; s/\\\\/\\/g'
}

# Per-session temp files (marker "code was edited", retry counter).
hook_state_file() {
  local session
  session="$(json_field session_id)"
  printf '%s/claude-%s-%s' "${TMPDIR:-/tmp}" "$1" "${session:-default}"
}

# Finds the solution file in the project root. Prints nothing if there is none yet.
find_solution() {
  local f
  for f in ./*.slnx ./*.sln; do
    [ -e "$f" ] && { printf '%s' "$f"; return; }
  done
}
