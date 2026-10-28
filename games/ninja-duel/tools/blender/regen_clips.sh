#!/usr/bin/env bash
# Regenerate src/Client/AuthoredClips*.luau from the staged Blender exports
# (DEC-030). Order matters: later files override earlier clips of the same name.
set -euo pipefail
cd "$(dirname "$0")/../.."
O=${ND_CLIPS:-/mnt/user-data/uploads/Documents/NinjaDuelBlender/out}
python3 tools/blender/clips_to_luau.py src/Client/AuthoredClips.luau \
  $O/clips_Lion.json $O/clips_Flashstep.json $O/clips_Lion_loco.json $O/clips_Flashstep_loco.json \
  $O/clips_Lion_react.json $O/clips_Flashstep_react.json $O/clips_Lion2.json $O/clips_Flashstep2.json \
  $O/clips_Lion_react2.json $O/clips_Flashstep_react2.json $O/clips_Lion_p1.json $O/clips_Kunai.json \
  $O/clips_Mirage_p3.json $O/clips_Flashstep_p4.json $O/clips_Legion_p5.json $O/clips_Copycat_p6.json \
  $O/clips_Sand_p7.json $O/clips_Leaf_p8.json $O/clips_GentleFist_p9.json
