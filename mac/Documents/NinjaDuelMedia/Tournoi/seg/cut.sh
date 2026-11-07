#!/bin/bash
# usage: cut.sh <rec-stamp> <name> <start> <end>
cd "$HOME/mnt/Documents"
f=$(ls *"$1".mov)
d=$(python3 -c "print(round($4-$3,3))")
ffmpeg -v error -y -ss "$3" -i "$f" -t "$d" -vf "crop=836:1487:977:279,scale=1080:1920" -r 60 -c:v libx264 -preset ultrafast -crf 16 -pix_fmt yuv420p -an "NinjaDuelMedia/Tournoi/seg/$2.mp4"
echo "$2 done"
