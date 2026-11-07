#!/bin/bash
# A1 v3 takes, cut from the single raw (OBS 2026-11-05 14-58-35.mov) — prep only, the edit is in CapCut.
F="2026-11-05 14-58-35.mov"
cut() { # name start dur
  ffmpeg -v error -y -ss "$2" -t "$3" -i "$F" -vf "crop=836:1487:977:279,scale=1080:1920:flags=lanczos" -c:v libx264 -preset veryfast -crf 16 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "01_RUSHES_v3/$1.mp4"
  echo "done $1"
}
b1=48.883; b2=64.766; b3=80.649; b4=96.548
a() { python3 -c "print(round($1+$2,3))"; }
#cut A_HOOK_SEALCU_v39t_T4 $(a $b4 3.85) 1.3
cut A_HOOK_SEALCU_v39t_T3 $(a $b3 3.85) 1.3
cut R_CLASH_BEHINDA_v39t_T4 $(a $b4 -0.1) 1.6
cut R_CLASH_LOW_v39t_T3 $(a $b3 -0.1) 2.0
cut R_CLASH_WIDE_v39t_T1 $(a $b1 -0.1) 2.3
cut B_THROW_TRACK_v39t_T4 $(a $b4 2.2) 1.5
cut B_THROW_OTS_v39t_T1 $(a $b1 2.2) 1.6
cut C_BAIT_CLOSE_v39t_T2 $(a $b2 3.8) 2.5
cut C_BAIT_WIDE_v39t_T1 $(a $b1 3.8) 2.5
cut DEF_WARP_COUNTER_FIT_v39t_T1 $(a $b1 6.2) 2.7
cut DEF_WARP_COUNTER_TOP_v39t_T3 $(a $b3 6.2) 2.7
cut DEF_WARP_COUNTER_FIT_v39t_T4 $(a $b4 6.2) 2.7
cut DEF_WARP_CLOSE_v39t_T2 $(a $b2 6.2) 2.7
cut G_AFTER_CLOSE_v39t_T2 $(a $b2 8.6) 2.2
cut G_AFTER_WIDE_v39t_T3 $(a $b3 8.6) 2.2
cut H_CTA_ARENA_v39t_CTA 155.6 5.6
ffmpeg -v error -y -ss 222.7 -t 13.5 -i "$F" -vf "scale=1920:-2" -c:v libx264 -preset veryfast -crf 20 -c:a aac -b:a 160k -movflags +faststart 00_PROOF/UNCUT_GAMEPLAY_WITH_HUD_v39t.mp4 && echo "done proof"
echo ALLDONE
