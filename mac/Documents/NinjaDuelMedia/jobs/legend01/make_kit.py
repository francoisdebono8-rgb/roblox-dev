import json, os, subprocess, sys, shutil
sys.path.insert(0, os.path.expanduser("~/mnt/Documents/NinjaDuelMedia/factory"))
import ov
FACT = os.path.expanduser("~/mnt/Documents/NinjaDuelMedia/factory")
# hits relative to each beat's start (from the take logs), per take
BEAT0 = {
 "T1": {"rush":2.666,"counter":4.383,"seals":6.200,"dragon":7.516,"rendan":10.517},
 "T2": {"rush":2.700,"counter":4.416,"seals":6.216,"dragon":7.517,"rendan":10.533},
 "T3": {"rush":2.683,"counter":4.400,"seals":6.200,"dragon":7.519,"rendan":10.550},
}
HITS = {
 "T1": [("Light",3.267),("Light",3.483),("Light",3.800),("Light",4.516),("Light",4.850),("Light",5.149),("Heavy",5.566),("Heavy",7.416),("Heavy",10.982),("Heavy",11.765)],
 "T2": [("Light",3.300),("Light",3.516),("Light",3.833),("Light",4.550),("Light",4.883),("Light",5.183),("Heavy",5.583),("Heavy",7.417),("Heavy",11.000),("Heavy",11.783)],
 "T3": [("Light",3.267),("Light",3.501),("Light",3.816),("Light",4.533),("Light",4.867),("Light",5.166),("Heavy",5.583),("Heavy",7.400),("Heavy",11.016),("Heavy",11.784)],
}
BEATS = {"T1": {"faceoff":0.666,"rush":2.666,"counter":4.383,"seals":6.200,"dragon":7.516,"clones":9.016,"rendan":10.517,"charge":12.632,"clash":14.233,"after":15.849},
         "T2": {"faceoff":0.684,"rush":2.700,"counter":4.416,"seals":6.216,"dragon":7.517,"clones":9.033,"rendan":10.533,"charge":12.650,"clash":14.266,"after":15.882},
         "T3": {"faceoff":0.667,"rush":2.683,"counter":4.400,"seals":6.200,"dragon":7.519,"clones":9.034,"rendan":10.550,"charge":12.666,"clash":14.283,"after":15.899}}
NUM = {"faceoff":"01","rush":"02","counter":"03","seals":"04","dragon":"05","clones":"06","rendan":"07","charge":"08","clash":"09","after":"10"}
# the edit: (take, beat, in, out, speed, label)
EDL = [
 ("T2","charge",0.25,1.05,1.0,"hook_sharingan"),
 ("T3","clash",0.10,0.55,1.0,"hook_chidori"),
 ("T1","faceoff",0.20,1.60,1.0,"faceoff"),
 ("T3","faceoff",0.40,0.80,1.0,"naruto_eye"),
 ("T2","faceoff",1.20,1.60,1.0,"sasuke_eye"),
 ("T2","rush",0.00,0.75,1.0,"naruto_rush"),
 ("T1","rush",0.55,1.45,1.0,"naruto_hits"),
 ("T3","counter",0.00,1.55,1.0,"sasuke_counter"),
 ("T1","seals",0.00,0.75,1.0,"seals_mid"),
 ("T2","seals",0.60,1.20,1.0,"seals_hands"),
 ("T2","dragon",0.00,0.90,1.0,"dragon_hit"),
 ("T1","clones",0.10,1.30,1.0,"shadow_clones"),
 ("T1","rendan",0.30,1.00,1.0,"rendan_launch"),
 ("T2","rendan",1.00,1.75,0.6,"rendan_slam"),
 ("T1","charge",0.30,1.20,1.0,"chidori_charge"),
 ("T3","charge",0.50,0.90,1.0,"naruto_glare"),
 ("T3","clash",0.00,0.80,0.5,"clash_slowmo"),
]
HOLD = 3.6  # frozen last frame: WHO WINS? then the CTA
out = "capcut"; shutil.rmtree(out, ignore_errors=True); os.makedirs(out + "/clips"); os.makedirs(out + "/overlays"); os.makedirs(out + "/audio")
t = 0.0; rows = []; sfx = []
for i, (tk, beat, a, b, sp, lab) in enumerate(EDL):
    src = f"clips/{tk}_{NUM[beat]}_{beat}.mp4"
    name = f"c{i+1:02d}_{lab}.mp4"
    subprocess.run(["ffmpeg","-v","error","-y","-ss",f"{a:.3f}","-i",src,"-t",f"{b-a:.3f}","-c:v","libx264","-preset","veryfast","-crf","16","-pix_fmt","yuv420p","-an",f"{out}/clips/{name}"], check=True)
    start = t; t += (b - a) / sp
    rows.append((name, start, t, sp, lab))
    b0 = BEATS[tk][beat]
    for kind, h in HITS[tk]:
        rel = h - b0
        if a <= rel <= b:
            sfx.append({"t": round(start + (rel - a) / sp, 3), "name": "heavy" if kind == "Heavy" else "hit"})
    if i > 0: sfx.append({"t": round(start, 3), "name": "whoosh", "vol": 0.35})
last = rows[-1][0]
subprocess.run(["ffmpeg","-v","error","-y","-sseof","-0.05","-i",f"{out}/clips/{last}","-frames:v","1","-update","1",f"{out}/clips/c{len(EDL)+1:02d}_freeze.png"], check=True)
end = t + HOLD
# overlays (from ov.py)
OV = [
 ({"type":"title","text":"NARUTO vs SASUKE","size":118,"y":330,"sub":"LEGENDARY FIGHTS"}, 0.0, rows[1][2]),
 ({"type":"caption","text":"KATON: DRAGON FLAME","y":1480,"sub":"HAND SEALS  RAT · TIGER"}, rows[8][1], rows[10][2]),
 ({"type":"caption","text":"SHADOW CLONE JUTSU","y":1480}, rows[11][1], rows[11][2]),
 ({"type":"caption","text":"UZUMAKI BARRAGE","y":1480}, rows[12][1], rows[13][2]),
 ({"type":"caption","text":"CHIDORI","y":1480,"color":"white"}, rows[14][1], rows[14][2]),
 ({"type":"caption","text":"RASENGAN","y":1480}, rows[15][1], rows[15][2]),
 ({"type":"stamp","lines":["WHO","WINS?"],"color":"gold","y":900}, t, t + 1.6),
 ({"type":"cta","lines":["NINJA DUEL","IS FREE ON ROBLOX"],"ask":"NARUTO OR SASUKE? COMMENT"}, t + 1.6, end),
]
ovs = []
for i, (spec, a, b) in enumerate(OV):
    p = ov.render(spec, f"{out}/overlays/o{i+1:02d}_{spec['type']}.png")
    ovs.append((os.path.basename(p), a, b, spec.get("text") or " / ".join(spec.get("lines", []))))
# game sounds at their frames
for e in ("hit","heavy","whoosh"): shutil.copy(f"{FACT}/sfx/{e}.wav", f"{out}/audio/{e}.wav")
vol = {"hit":0.85,"heavy":1.0,"whoosh":0.45}
ins, fl = [], []
for i, e in enumerate(sfx):
    ins += ["-i", f"{FACT}/sfx/{e['name']}.wav"]; ms = int(e["t"] * 1000)
    fl.append(f"[{i}:a]volume={e.get('vol', vol[e['name']])},adelay={ms}|{ms}[a{i}]")
fl.append("".join(f"[a{i}]" for i in range(len(sfx))) + f"amix=inputs={len(sfx)}:normalize=0,apad=whole_dur={end:.3f},atrim=0:{end:.3f},alimiter=limit=0.95[o]")
subprocess.run(["ffmpeg","-v","error","-y"] + ins + ["-filter_complex", ";".join(fl), "-map", "[o]", "-ar", "48000", "-ac", "2", f"{out}/audio/sfx_bed.wav"], check=True)
L = [f"KIT CAPCUT — legend01 NARUTO vs SASUKE — {end:.2f} s (9:16, 1080x1920, 60 i/s)", "", "PISTE PRINCIPALE"]
for name, a, b, sp, lab in rows:
    L.append(f"  {a:6.2f} -> {b:6.2f}  clips/{name:<28}" + (f"  vitesse {sp:g}x" if sp != 1 else ""))
L.append(f"  {t:6.2f} -> {end:6.2f}  clips/c{len(EDL)+1:02d}_freeze.png  (image figée)")
L += ["", "INCRUSTATIONS"] + [f"  {a:6.2f} -> {b:6.2f}  overlays/{n:<24} {txt}" for n, a, b, txt in ovs]
L += ["", "AUDIO", f"  0.00 -> {end:.2f}  audio/sfx_bed.wav", "  musique CapCut (usage commercial), -12 dB, coupe nette sur le WHO WINS"]
open(f"{out}/timeline.txt", "w").write("\n".join(L) + "\n")
json.dump({"rows": rows, "overlays": ovs, "sfx": sfx, "end": end}, open(f"{out}/kit.json", "w"), indent=1)
print("\n".join(L))
