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
dump() { python3 -c "import base64,gzip,sys;b=base64.b64encode(gzip.compress(open(sys.argv[1],'rb').read())).decode();[print('KJ '+b[i:i+3000]) for i in range(0,len(b),3000)]" "$1"; }
echo "=== kitprint ==="
"$LUNE" run tools/kits/kitprint_lune.luau > /tmp/kitprint.json || status=1
echo "KITPRINT-BEGIN"; dump /tmp/kitprint.json; echo "KITPRINT-END"
echo "=== first combat ==="
"$LUNE" run tests/DuelBot.spec.luau || status=1
echo "=== rounds at the game's DamageScale ==="
"$LUNE" run tools/duelbot/rounds.luau 3 0.9,0.8 joueur,debutant easy,normal || status=1
echo "=== konoha dump ==="
"$LUNE" run tools/syphodev/konoha_dump.luau /tmp/konoha.json || status=1
echo "KONOHA-BEGIN"; dump /tmp/konoha.json; echo "KONOHA-END"
exit $status
