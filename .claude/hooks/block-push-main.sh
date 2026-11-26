#!/usr/bin/env bash
# PreToolUse hook (Bash): stops Claude from pushing to main/master and from force-pushing.
# Claude Code passes the tool call as JSON on stdin. Exit code 2 = block, and stderr goes back to Claude.
# Second lock: GitHub branch protection on main also refuses direct pushes.

input="$(cat)"
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

cmd="$(json_field command)"
cwd="$(json_field cwd)"
[ -n "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-.}"

block() {
  echo "BLOCKED by .claude/hooks/block-push-main.sh: $1" >&2
  echo "Rule: never push to main and never force push. Work on a branch (feat/..., fix/..., chore/...) and open a PR." >&2
  exit 2
}

unquote() { local s="$1"; s="${s#[\"\']}"; s="${s%[\"\']}"; printf '%s' "$s"; }

# Split the command into simple commands at && || ; | & and newlines, then check each one.
segments="$(printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\||&)/\n/g')"

while IFS= read -r seg; do
  # xargs splits words like the shell does (respects "..." and '...') but never executes anything.
  if ! mapfile -t w < <(printf '%s' "$seg" | xargs -n1 printf '%s\n' 2>/dev/null) || [ ${#w[@]} -eq 0 ]; then
    read -ra w <<<"$seg"
  fi
  n=${#w[@]}
  i=0

  # Find `git`, then skip its global options (-C <dir>, -c <k=v>, ...) to get the subcommand.
  while [ $i -lt $n ] && [ "$(unquote "${w[$i]}")" != "git" ]; do i=$((i + 1)); done
  [ $i -lt $n ] || continue
  i=$((i + 1))
  dir="$cwd"
  while [ $i -lt $n ]; do
    case "${w[$i]}" in
      -C) dir="$(unquote "${w[$((i + 1))]}")"; i=$((i + 2)) ;;
      -c|--git-dir|--work-tree|--namespace) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  [ "${w[$i]}" = "push" ] || continue
  i=$((i + 1))

  # Look at push's own arguments.
  positional=()
  for a in "${w[@]:$i}"; do
    a="$(unquote "$a")"
    case "$a" in
      --force*|--mirror|--all) block "'$a' is not allowed (force push / pushes every branch)." ;;
      --*) ;;
      -*f*) block "force push ('$a') is not allowed." ;;
      -*) ;;
      *) positional+=("$a") ;;
    esac
  done

  # positional[0] = remote, the rest = refspecs like `main`, `HEAD:main`, `+feat:refs/heads/main`.
  for ((k = 1; k < ${#positional[@]}; k++)); do
    ref="${positional[$k]}"
    case "$ref" in +*) block "force push ('$ref') is not allowed." ;; esac
    dst="${ref##*:}"
    dst="${dst#refs/heads/}"
    case "$dst" in main|master) block "pushing to '$dst' is not allowed." ;; esac
  done

  # No refspec given: git pushes the current branch, so check which branch that is.
  if [ ${#positional[@]} -le 1 ]; then
    case "$dir" in /*|[A-Za-z]:*) ;; *) dir="$cwd/$dir" ;; esac
    branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)"
    if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
      block "you are on '$branch'. Create a branch first: git switch -c feat/<name>"
    fi
  fi
done <<<"$segments"

exit 0
