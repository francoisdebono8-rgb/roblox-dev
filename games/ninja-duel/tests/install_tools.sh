#!/usr/bin/env bash
# Installs the two runners of the Luau suites (tests/run.sh): luau and lune.
# For a session that has neither (20/11, the OUTILLEUR: « je ne peux pas
# lancer les specs Luau ici »). Linux x86_64 or macOS arm64.
#   bash tests/install_tools.sh          # then: bash tests/run.sh
# Installs into $NINJA_DUEL_TOOLS (default ~/.ninja-duel-tools), which
# tests/run.sh also looks in.
set -euo pipefail
DEST=${NINJA_DUEL_TOOLS:-$HOME/.ninja-duel-tools}
LUNE_VERSION=0.10.5
mkdir -p "$DEST"
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  LUAU_ZIP=luau-ubuntu.zip; LUNE_ZIP=lune-$LUNE_VERSION-linux-x86_64.zip ;;
  Darwin-arm64)  LUAU_ZIP=luau-macos.zip;  LUNE_ZIP=lune-$LUNE_VERSION-macos-aarch64.zip ;;
  Darwin-x86_64) LUAU_ZIP=luau-macos.zip;  LUNE_ZIP=lune-$LUNE_VERSION-macos-x86_64.zip ;;
  *) echo "unsupported platform: $(uname -s)-$(uname -m)" >&2; exit 2 ;;
esac
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/luau.zip" "https://github.com/luau-lang/luau/releases/latest/download/$LUAU_ZIP"
curl -fsSL -o "$tmp/lune.zip" "https://github.com/lune-org/lune/releases/download/v$LUNE_VERSION/$LUNE_ZIP"
(cd "$tmp" && unzip -oq luau.zip -d luau && unzip -oq lune.zip -d lune)
cp "$tmp/luau/luau" "$DEST/luau"
cp "$tmp/lune/lune" "$DEST/lune"
chmod +x "$DEST/luau" "$DEST/lune"
echo "luau and lune installed in $DEST"
echo "run the suites: bash tests/run.sh"
