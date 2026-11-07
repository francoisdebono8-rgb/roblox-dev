#!/bin/bash
# mk.sh out "file:start:end:speed" ...
out=$1; shift; n=0; f=""; inputs=(); 
for s in "$@"; do IFS=: read src a b sp <<< "$s"; inputs+=(-ss $a -to $b -i $src.mp4); f+="[$n:v]setpts=(PTS-STARTPTS)/$sp,fps=60,setsar=1[v$n];"; n=$((n+1)); done
c=""; for i in $(seq 0 $((n-1))); do c+="[v$i]"; done
ffmpeg -v error -y "${inputs[@]}" -filter_complex "${f}${c}concat=n=$n:v=1:a=0[o]" -map "[o]" -c:v libx264 -preset veryfast -crf 17 -pix_fmt yuv420p -r 60 ../clips/$out.mp4 && echo "$out $(ffprobe -v error -show_entries format=duration -of csv=p=0 ../clips/$out.mp4)"
