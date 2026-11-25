#!/usr/bin/env bash
# Stop hook: when Claude wants to finish its turn, run ALL tests (also the slow ones with Docker).
# Runs only if there are uncommitted code changes, so a plain chat answer doesn't wait ~30 s.
# Exit code 2 = Claude is not allowed to stop yet and gets the test output to fix.

input="$(cat)"

# Claude is already continuing because of this hook. Let it stop, so we never loop forever.
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# No solution yet (before step 2): nothing to test.
shopt -s nullglob
solutions=( ./*.sln ./*.slnx )
if [ "${#solutions[@]}" -eq 0 ]; then
  exit 0
fi

# No changed code files: nothing new to test.
if ! git status --porcelain --untracked-files=all | grep -Eq '\.(cs|csproj|props|targets|slnx?|json)$'; then
  exit 0
fi

if ! out="$(dotnet test --nologo -tl:off -v q 2>&1)"; then
  echo "Tests FAILED. Fix them before finishing." >&2
  echo "(If the error mentions Docker: Docker Desktop must be running for integration tests.)" >&2
  printf '%s\n' "$out" | tail -n 60 >&2
  exit 2
fi

exit 0
