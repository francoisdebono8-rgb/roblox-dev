#!/usr/bin/env bash
# Regenerate src/Client/AuthoredClips*.luau from the staged key-posed exports
# (regen_clips.sh's list) followed by the Mixamo-based clips (DEC-032), which
# override the key-posed clips of the same name.
#   ND_MOCAP=<folder with clips_<F>_mocap.json / clips_<F>_strikes.json>
set -euo pipefail
cd "$(dirname "$0")/../.."
O=${ND_CLIPS:-/mnt/user-data/uploads/Documents/NinjaDuelBlender/out}
M=${ND_MOCAP:?set ND_MOCAP to the folder of the mocap exports}
BASE=$(sed -n '/clips_to_luau.py/,$p' tools/blender/regen_clips.sh | tr -d '\\' | tr ' ' '\n' | grep '\$O/' | sed "s#\$O#$O#")
EXTRA=""
for F in Lion Legion Sand Leaf GentleFist Mirage Copycat Flashstep; do
  for kind in mocap strikes; do
    [ -f "$M/clips_${F}_${kind}.json" ] && EXTRA="$EXTRA $M/clips_${F}_${kind}.json"
  done
done
python3 tools/blender/clips_to_luau.py src/Client/AuthoredClips.luau $BASE $EXTRA
# drop the modules the new split no longer uses
n=$(grep -c 'require(script.Parent.AuthoredClips' src/Client/AuthoredClips.luau)
for f in src/Client/AuthoredClips[0-9]*.luau; do
  k=${f##*AuthoredClips}; k=${k%.luau}
  if [ "$k" -gt "$n" ]; then git rm -q "$f" 2>/dev/null || rm -f "$f"; fi
done
