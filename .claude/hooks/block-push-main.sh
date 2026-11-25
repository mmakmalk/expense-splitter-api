#!/usr/bin/env bash
# PreToolUse hook (Bash): stops Claude from pushing to main/master and from force-pushing.
# Claude Code passes the tool call as JSON on stdin. Exit code 2 = block, and stderr goes back to Claude.
# Second lock: GitHub branch protection on main also refuses direct pushes.

input="$(cat)"

# Only care about commands that run `git ... push`.
if ! printf '%s' "$input" | grep -Eq '\bgit\b[^"]*\bpush\b'; then
  exit 0
fi

block() {
  echo "BLOCKED by .claude/hooks/block-push-main.sh: $1" >&2
  echo "Rule: never push to main. Work on a branch (feat/..., fix/..., chore/...) and open a PR." >&2
  exit 2
}

# 1. Force push rewrites history. Never allowed.
if printf '%s' "$input" | grep -Eq -- '(--force|--force-with-lease|[[:space:]]-f([[:space:]]|"|$))'; then
  block "force push is not allowed."
fi

# 2. Explicit target main/master, e.g. `git push origin main` or `git push origin HEAD:main`.
if printf '%s' "$input" | grep -Eq '\bpush\b[^"]*[[:space:]:](main|master)([[:space:]]|"|$)'; then
  block "pushing to main/master is not allowed."
fi

# 3. Plain `git push` while the current branch is main/master.
branch="$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  block "you are on '$branch'. Create a branch first: git switch -c feat/<name>"
fi

exit 0
