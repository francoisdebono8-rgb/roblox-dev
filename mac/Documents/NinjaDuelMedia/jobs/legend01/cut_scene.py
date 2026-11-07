import json, subprocess, os
FL = {"T1": 2.217, "T2": 21.467, "T3": 40.767}
BEATS = {
 "T1": {"faceoff":0.666,"rush":2.666,"counter":4.383,"seals":6.200,"dragon":7.516,"clones":9.016,"rendan":10.517,"charge":12.632,"clash":14.233,"after":15.849,"end":17.25},
 "T2": {"faceoff":0.684,"rush":2.700,"counter":4.416,"seals":6.216,"dragon":7.517,"clones":9.033,"rendan":10.533,"charge":12.650,"clash":14.266,"after":15.882,"end":17.28},
 "T3": {"faceoff":0.667,"rush":2.683,"counter":4.400,"seals":6.200,"dragon":7.519,"clones":9.034,"rendan":10.550,"charge":12.666,"clash":14.283,"after":15.899,"end":17.30},
}
ORDER = ["faceoff","rush","counter","seals","dragon","clones","rendan","charge","clash","after"]
os.makedirs("clips", exist_ok=True)
rep = json.load(open("clips/qc.json")) if os.path.exists("clips/qc.json") else {}
for t in ["T1","T2","T3"]:
    b = BEATS[t]
    for i, name in enumerate(ORDER):
        a = FL[t] + b[name]; e = FL[t] + b[ORDER[i+1] if i+1 < len(ORDER) else "end"]
        out = f"clips/{t}_{i+1:02d}_{name}.mp4"
        if out in rep and os.path.exists(out): continue
        subprocess.run(["ffmpeg","-v","error","-y","-ss",f"{a:.3f}","-i","raw/T123.mov","-t",f"{e-a:.3f}",
            "-vf","crop=830:1476:976:286,scale=1080:1920,fps=60,setsar=1","-an","-c:v","libx264","-preset","veryfast","-crf","17","-pix_fmt","yuv420p",out], check=True)
        r = subprocess.run(["ffmpeg","-hide_banner","-i",out,"-vf","scale=270:480,mpdecimate=hi=200:lo=100:frac=0.1,showinfo","-f","null","-"],stderr=subprocess.PIPE,text=True).stderr
        ts=[float(x.split(":")[1]) for x in r.split() if x.startswith("pts_time:")]
        gaps=[round(y-x,3) for x,y in zip(ts,ts[1:]) if y-x>0.08]
        rep[out]={"dur":round(e-a,2),"frames":len(ts),"fps":round(len(ts)/(e-a),1),"gaps":gaps}
        json.dump(rep, open("clips/qc.json","w"), indent=1)
print("done")
