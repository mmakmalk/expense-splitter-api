#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit): after Claude edits a C#/project file, check that the code still builds.
# Fast check only (~5 s). Full tests run once at the end, in run-tests-on-stop.sh (ADR-0002).
# Exit code 2 = stderr goes back to Claude, so it sees the build errors and fixes them.

input="$(cat)"

# Only for files that affect the build.
if ! printf '%s' "$input" | grep -Eq '"file_path"[[:space:]]*:[[:space:]]*"[^"]*\.(cs|csproj|props|targets|slnx?)"'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# No solution yet (before step 2): nothing to build.
shopt -s nullglob
solutions=( ./*.sln ./*.slnx )
if [ "${#solutions[@]}" -eq 0 ]; then
  exit 0
fi

if ! out="$(dotnet build --nologo -tl:off -v q -clp:ErrorsOnly 2>&1)"; then
  echo "Build FAILED after your edit. Fix these errors:" >&2
  printf '%s\n' "$out" | tail -n 40 >&2
  exit 2
fi

exit 0
