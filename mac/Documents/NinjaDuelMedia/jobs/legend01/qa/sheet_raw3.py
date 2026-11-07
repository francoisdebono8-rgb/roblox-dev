import subprocess, os
from concurrent.futures import ThreadPoolExecutor
from PIL import Image, ImageDraw, ImageFont
OFF = {"T1": 0.0, "T2": 19.349, "T3": 38.583}
F=2.200
B = {k:F+v for k,v in {"faceoff":0.667,"rush":2.684,"counter":4.400,"seals":6.201,"dragon":7.516,"clones":9.017,"rendan":10.534,"charge":12.651,"clash":14.266,"after":15.866}.items()}
P = [("faceoff",0.5),("faceoff",1.7),("rush",0.3),("rush",1.0),("counter",0.4),("counter",1.2),("seals",0.5),("seals",1.1),("dragon",0.4),("clones",0.3),("clones",1.2),("rendan",0.5),("rendan",1.25),("charge",0.4),("charge",1.2),("clash",0.3),("clash",1.0),("after",0.6)]
W,H=150,267
jobs=[]
for tk in ["T1","T2","T3"]:
    for i,(b,r) in enumerate(P):
        t=OFF[tk]+B[b]+r
        jobs.append((tk,i,t,f"qa/r3/{tk}_{i:02d}.png"))
def grab(j):
    tk,i,t,out=j
    subprocess.run(["ffmpeg","-v","error","-y","-ss",f"{t:.3f}","-i","raw3/legend01_brut.mov","-frames:v","1","-vf",f"crop=830:1476:976:286,scale={W}:{H}",out],check=True)
with ThreadPoolExecutor(6) as ex: list(ex.map(grab,jobs))
fp="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
font=ImageFont.truetype(fp,11) if os.path.exists(fp) else ImageFont.load_default()
cols=len(P)//2
for half in (0,1):
    sheet=Image.new("RGB",(cols*(W+4),3*(H+18)),(25,25,25)); d=ImageDraw.Draw(sheet)
    for r,tk in enumerate(["T1","T2","T3"]):
        for c in range(cols):
            i=half*cols+c
            im=Image.open(f"qa/r3/{tk}_{i:02d}.png")
            x=c*(W+4); y=r*(H+18)
            sheet.paste(im,(x,y+16)); d.text((x+2,y+2),f"{tk} {P[i][0]} +{P[i][1]}",fill=(255,230,80),font=font)
    sheet.save(f"qa/raw3_sheet{half+1}.jpg",quality=85)
print("ok")
