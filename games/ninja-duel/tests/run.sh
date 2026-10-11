#!/usr/bin/env bash
# Run every headless Ninja Duel suite. Works from the repository root or from
# games/ninja-duel. Exit code is non-zero if any suite fails.
set -uo pipefail
cd "$(dirname "$0")/.."

TOOLS=${NINJA_DUEL_TOOLS:-/private/tmp/ninja-duel-tools}
LUAU=${LUAU:-$TOOLS/luau}
LUNE=${LUNE:-$TOOLS/lune}
command -v "$LUAU" >/dev/null 2>&1 || LUAU=$(command -v luau || true)
command -v "$LUNE" >/dev/null 2>&1 || LUNE=$(command -v lune || true)
if [ -z "${LUAU:-}" ] || [ -z "${LUNE:-}" ]; then
  echo "luau and lune are required; set LUAU / LUNE or install both" >&2
  exit 2
fi

status=0
run() {
  local label=$1; shift
  local output
  if output=$("$@" 2>&1); then
    printf '%-12s PASS  %s\n' "$label" "$(printf '%s\n' "$output" | tail -1)"
  else
    status=1
    printf '%-12s FAIL  %s\n' "$label" "$(printf '%s\n' "$output" | tail -1)"
    printf '%s\n' "$output" | grep -E '^(FAIL|.*Error)' | head -5
  fi
}
run Rules      "$LUAU" tests/Rules.spec.luau
run Input      "$LUNE" run tests/Input.spec.luau
run Combat     "$LUNE" run tests/Combat.spec.luau
run Sequences  "$LUNE" run tests/Sequences.spec.luau
run Regression "$LUNE" run tests/Regression.spec.luau
run Feedback   "$LUNE" run tests/Feedback.spec.luau
run Animation  "$LUNE" run tests/Animation.spec.luau
run Branches   "$LUNE" run tests/Branches.spec.luau
run Phase4     "$LUNE" run tests/Phase4.spec.luau
run Neji       "$LUNE" run tests/Neji.spec.luau
run Systems    "$LUNE" run tests/Systems.spec.luau
run Tools      "$LUNE" run tests/Tools.spec.luau
run Sasuke     "$LUNE" run tests/Sasuke.spec.luau
run Gaara      "$LUNE" run tests/Gaara.spec.luau

run Preparation "$LUNE" run tests/Preparation.spec.luau
exit $status
