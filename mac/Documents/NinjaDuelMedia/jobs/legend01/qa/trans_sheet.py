import subprocess, os, glob
from PIL import Image, ImageDraw, ImageFont
clips = sorted(glob.glob("capcut/clips/c*.mp4"))
W,H = 180,320
def grab(path, where, out):
    if where == "first":
        cmd = ["ffmpeg","-v","error","-y","-i",path,"-frames:v","1","-vf",f"scale={W}:{H}",out]
    elif where == "last":
        cmd = ["ffmpeg","-v","error","-y","-sseof","-0.04","-i",path,"-frames:v","1","-update","1","-vf",f"scale={W}:{H}",out]
    else:
        cmd = ["ffmpeg","-v","error","-y","-ss",str(where),"-i",path,"-frames:v","1","-vf",f"scale={W}:{H}",out]
    subprocess.run(cmd, check=True)
    return Image.open(out).convert("RGB")
try: font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
except: font = ImageFont.load_default()
F, L = [], []
for i,c in enumerate(clips):
    F.append(grab(c,"first",f"qa/fr/f{i:02d}.png")); L.append(grab(c,"last",f"qa/fr/l{i:02d}.png"))
names = [os.path.basename(c)[:3] for c in clips]
pairs = len(clips)-1
cols = 3; rows = (pairs+cols-1)//cols
gap=14; pw = 2*W+4
sheet = Image.new("RGB",(cols*(pw+gap),rows*(H+24)),(30,30,30)); d = ImageDraw.Draw(sheet)
for k in range(pairs):
    x = (k%cols)*(pw+gap); y=(k//cols)*(H+24)
    sheet.paste(L[k],(x,y+20)); sheet.paste(F[k+1],(x+W+4,y+20))
    d.text((x+4,y+2),f"{names[k]} fin  ->  {names[k+1]} debut",fill=(255,230,80),font=font)
sheet.save("qa/transitions.jpg",quality=85)
print(sheet.size)
