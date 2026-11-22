#!/usr/bin/env bash
# Run every headless Ninja Duel suite. Works from the repository root or from
# games/ninja-duel. Exit code is non-zero if any suite fails.
set -uo pipefail
cd "$(dirname "$0")/.."

TOOLS=${NINJA_DUEL_TOOLS:-/private/tmp/ninja-duel-tools}
LUAU=${LUAU:-$TOOLS/luau}
LUNE=${LUNE:-$TOOLS/lune}
# (20/11) where tests/install_tools.sh puts them
command -v "$LUAU" >/dev/null 2>&1 || { [ -x "$HOME/.ninja-duel-tools/luau" ] && LUAU=$HOME/.ninja-duel-tools/luau; }
command -v "$LUNE" >/dev/null 2>&1 || { [ -x "$HOME/.ninja-duel-tools/lune" ] && LUNE=$HOME/.ninja-duel-tools/lune; }
command -v "$LUAU" >/dev/null 2>&1 || LUAU=$(command -v luau || true)
command -v "$LUNE" >/dev/null 2>&1 || LUNE=$(command -v lune || true)
if [ -z "${LUAU:-}" ] || [ -z "${LUNE:-}" ]; then
  echo "luau and lune are required; set LUAU / LUNE or install both" >&2
  exit 2
fi

status=0
echo "=== first combat, beginner robot, 8 kits x 3 seeds ==="
"$LUNE" run tests/DuelBot.spec.luau || status=1
echo "=== rounds ==="
"$LUNE" run tools/duelbot/rounds.luau 3 0.7,0.8,1 joueur,debutant easy,normal || status=1
echo "=== konoha dump ==="
"$LUNE" run tools/syphodev/konoha_dump.luau /tmp/konoha.json || status=1
echo "KONOHA-JSON-BEGIN"
python3 -c "import base64,gzip,json;d=json.load(open('/tmp/konoha.json'));b=base64.b64encode(gzip.compress(json.dumps(d,separators=(',',':')).encode())).decode();[print('KJ '+b[i:i+3000]) for i in range(0,len(b),3000)]"
echo "KONOHA-JSON-END"
exit $status
