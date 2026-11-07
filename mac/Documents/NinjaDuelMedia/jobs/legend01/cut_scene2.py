import json, subprocess, os, time
T0 = time.time()
FL = {"T1": 1.150, "T2": 20.433, "T3": 39.683}
BEATS = {
 "T1": {"faceoff":0.683,"rush":2.683,"counter":4.399,"seals":6.216,"dragon":7.532,"clones":9.033,"rendan":10.549,"charge":12.666,"clash":14.283,"after":15.899,"end":17.299},
 "T2": {"faceoff":0.650,"rush":2.667,"counter":4.384,"seals":6.200,"dragon":7.516,"clones":9.034,"rendan":10.550,"charge":12.667,"clash":14.283,"after":15.899,"end":17.316},
 "T3": {"faceoff":0.683,"rush":2.700,"counter":4.416,"seals":6.233,"dragon":7.549,"clones":9.050,"rendan":10.566,"charge":12.666,"clash":14.282,"after":15.899,"end":17.300},
}
ORDER = ["faceoff","rush","counter","seals","dragon","clones","rendan","charge","clash","after"]
os.makedirs("clips2", exist_ok=True)
rep = json.load(open("clips2/qc.json")) if os.path.exists("clips2/qc.json") else {}
for t in ["T1","T2","T3"]:
    b = BEATS[t]
    for i, name in enumerate(ORDER):
        if time.time() - T0 > 150: print("partial"); raise SystemExit
        a = FL[t] + b[name]; e = FL[t] + b[ORDER[i+1] if i+1 < len(ORDER) else "end"]
        out = f"clips2/{t}_{i+1:02d}_{name}.mp4"
        if out in rep and os.path.exists(out): continue
        subprocess.run(["ffmpeg","-v","error","-y","-ss",f"{a:.3f}","-i","raw2/T123b.mov","-t",f"{e-a:.3f}",
            "-vf","crop=830:1476:976:286,scale=1080:1920,fps=60,setsar=1","-an","-c:v","libx264","-preset","veryfast","-crf","17","-pix_fmt","yuv420p",out], check=True)
        r = subprocess.run(["ffmpeg","-hide_banner","-i",out,"-vf","scale=270:480,mpdecimate=hi=200:lo=100:frac=0.1,showinfo","-f","null","-"],stderr=subprocess.PIPE,text=True).stderr
        ts=[float(x.split(":")[1]) for x in r.split() if x.startswith("pts_time:")]
        gaps=[round(y-x,3) for x,y in zip(ts,ts[1:]) if y-x>0.08]
        rep[out]={"dur":round(e-a,2),"frames":len(ts),"fps":round(len(ts)/(e-a),1),"gaps":gaps}
        json.dump(rep, open("clips2/qc.json","w"), indent=1)
print("done", len(rep))
