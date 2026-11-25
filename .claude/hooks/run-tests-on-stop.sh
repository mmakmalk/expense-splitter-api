#!/usr/bin/env bash
# Stop hook: when Claude wants to finish its turn, run ALL tests (also the slow ones with Docker).
# Runs only when code changed (edited in this session, or uncommitted code files), so a plain chat answer doesn't wait ~30 s.
# Exit code 2 = Claude is not allowed to stop yet and gets the test output to fix.
# After 3 failed attempts in a row it lets Claude stop (no endless loop) and warns the user.

MAX_TRIES=3

input="$(cat)"
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

marker="$(hook_state_file needs-tests)"
counter="$(hook_state_file stop-tries)"

# First stop attempt of a turn: start counting from zero.
if ! printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  rm -f "$counter"
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# No solution yet (before step 2): nothing to test.
solution="$(find_solution)"
[ -n "$solution" ] || exit 0

# Did code change? Either the edit hook left a marker, or there are uncommitted code files.
needs_tests=0
[ -f "$marker" ] && needs_tests=1
if git -c core.quotePath=false status --porcelain --untracked-files=all \
    | sed -E 's/"$//' | grep -Eq '\.(cs|csproj|props|targets|slnx?)$'; then
  needs_tests=1
fi
[ "$needs_tests" -eq 1 ] || exit 0

if out="$(dotnet test "$solution" --nologo -tl:off -v q 2>&1)"; then
  rm -f "$marker" "$counter"
  exit 0
fi

tries="$(cat "$counter" 2>/dev/null || echo 0)"
tries=$((tries + 1))
echo "$tries" >"$counter"

if [ "$tries" -ge "$MAX_TRIES" ]; then
  rm -f "$counter"
  # Let Claude stop, but show the user a visible warning.
  echo '{"systemMessage": "UWAGA: testy nadal nie przechodza po 3 probach naprawy. Sprawdz wynik dotnet test."}'
  exit 0
fi

echo "Tests FAILED (attempt $tries of $MAX_TRIES). Fix them before finishing." >&2
echo "(If the error mentions Docker: Docker Desktop must be running for integration tests.)" >&2
printf '%s\n' "$out" | tail -n 60 >&2
exit 2
