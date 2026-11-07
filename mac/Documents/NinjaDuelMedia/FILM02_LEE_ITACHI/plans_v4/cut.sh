#!/bin/bash
cd "$(dirname "$0")"
RAW="../2026-11-06 15-28-46.mov"
declare -A OFF=([1]=14.07 [2]=49.75 [3]=85.52 [4]=121.33)
while read n take a b; do
  [ -s "p$n.mp4" ] && [ "$n" -le 10 -o "$n" = "15" -o "$n" = "19" ] && continue
  t0=$(python3 -c "print(round(${OFF[$take]}+$a,3))"); d=$(python3 -c "print(round($b-$a,3))")
  ffmpeg -nostdin -v error -y -ss $t0 -i "$RAW" -t $d -vf "crop=626:1114:729:210,scale=1080:1920:flags=lanczos,setsar=1,fps=60" \
    -c:v libx264 -preset veryfast -crf 15 -pix_fmt yuv420p -c:a aac -b:a 192k -ar 48000 "p$n.mp4" && echo "p$n ok $t0 $d"
done < edl.txt
