#!/usr/bin/env bash
# Set up a cloud session for the SyphoDev skills (.claude/skills/roblox-*).
#   bash tools/syphodev/setup_cloud.sh            (from the repository root)
# What it installs, all inside the session (nothing on François's Mac):
#   - Blender 5.2.3 as the `bpy` module (the same version as the Mac) and a `blender`
#     command that runs the skill scripts headless (tools/syphodev/blender_shim.py);
#   - numpy, scipy, Pillow, PyYAML (UI, maps, VFX texture library, renders);
#   - Rojo, Wally, Selene, StyLua and Lune 0.8.9 (the roblox-code skill's four gates;
#     its scaffolds pin Lune 0.8.9);
#   - Lune 0.10.5 + Luau for Ninja Duel's own tests (tests/run.sh): 0.10.0-0.10.4 do not
#     intern Instances and 0.11.x has no Enum.KeyCode.Unknown, both fail suites;
#   - Selene's Roblox standard library is written per project by
#     tools/syphodev/selene_roblox_std.py (Selene cannot download it through the proxy).
# About 3 minutes (bpy is 400 MB). Safe to run again.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bin="${NINJA_DUEL_TOOLS:-$HOME/tools}"
mkdir -p "$bin"
python3 -c "import bpy" 2>/dev/null || pip install --break-system-packages -q bpy==5.2.3
pip install --break-system-packages -q numpy scipy pillow pyyaml 2>/dev/null || true
cat > "$bin/blender" <<EOF
#!/usr/bin/env bash
exec python3 "$here/blender_shim.py" "\$@"
EOF
chmod +x "$bin/blender"

tmp="$(mktemp -d)"
get() {  # name url
  [ -x "$bin/$1" ] && return 0
  curl -sSL -o "$tmp/$1.zip" "$2" && unzip -o -q "$tmp/$1.zip" -d "$tmp/$1" &&
    find "$tmp/$1" -type f -name "$1" -exec cp {} "$bin/$1" \; && chmod +x "$bin/$1"
}
get rojo   https://github.com/rojo-rbx/rojo/releases/download/v7.6.1/rojo-7.6.1-linux-x86_64.zip
get selene https://github.com/Kampfkarren/selene/releases/download/0.29.0/selene-0.29.0-linux.zip
get stylua https://github.com/JohnnyMorganz/StyLua/releases/download/v2.3.1/stylua-linux-x86_64.zip
get wally  https://github.com/UpliftGames/wally/releases/download/v0.3.2/wally-v0.3.2-linux.zip
if [ ! -x "$bin/lune-0.8.9/lune" ]; then
  mkdir -p "$bin/lune-0.8.9"
  curl -sSL -o "$tmp/lune.zip" https://github.com/lune-org/lune/releases/download/v0.8.9/lune-0.8.9-linux-x86_64.zip &&
    unzip -o -q "$tmp/lune.zip" -d "$tmp/lune089" && cp "$tmp/lune089/lune" "$bin/lune-0.8.9/lune" && chmod +x "$bin/lune-0.8.9/lune"
fi
if [ ! -x "$bin/lune-0.10.5/lune" ]; then
  mkdir -p "$bin/lune-0.10.5"
  curl -sSL -o "$tmp/lune105.zip" https://github.com/lune-org/lune/releases/download/v0.10.5/lune-0.10.5-linux-x86_64.zip &&
    unzip -o -q "$tmp/lune105.zip" -d "$tmp/lune105" && cp "$tmp/lune105/lune" "$bin/lune-0.10.5/lune" && chmod +x "$bin/lune-0.10.5/lune"
fi
rm -rf "$tmp"
for t in blender rojo selene stylua wally lune-0.8.9/lune lune-0.10.5/lune; do printf '%-16s %s\n' "$t" "$("$bin/$t" --version 2>&1 | head -1)"; done
echo "PATH: export PATH=$bin:\$PATH   (put $bin/lune-0.8.9 first only inside a roblox-code scaffold)"
echo "Ninja Duel suite: LUNE=$bin/lune-0.10.5/lune bash games/ninja-duel/tests/run.sh   (Luau: any recent luau on PATH)"
