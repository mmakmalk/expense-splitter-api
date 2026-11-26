#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit): after Claude edits a build-relevant file, check that the code still builds.
# Fast check only (~5 s). Full tests run once at the end, in run-tests-on-stop.sh (ADR-0002).
# Exit code 2 = stderr goes back to Claude, so it sees the build errors and fixes them.

input="$(cat)"
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

# Only for files that affect the build.
file="$(json_field file_path)"
case "$file" in
  *.cs|*.csproj|*.props|*.targets|*.sln|*.slnx) ;;
  *) exit 0 ;;
esac

# Remember that code changed in this session, so the Stop hook runs the tests
# even if Claude commits before finishing.
touch "$(hook_state_file needs-tests)"

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# No solution yet (before step 2): nothing to build.
solution="$(find_solution)"
[ -n "$solution" ] || exit 0

if ! out="$(dotnet build "$solution" --nologo -tl:off -v q -clp:ErrorsOnly 2>&1)"; then
  echo "Build FAILED after your edit. Fix these errors:" >&2
  printf '%s\n' "$out" | tail -n 40 >&2
  exit 2
fi

exit 0
