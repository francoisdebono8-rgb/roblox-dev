import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
S=1024
random.seed(7)
INK=(16,14,19); VERM=(190,40,36); PAPER=(240,232,212); GOLD=(230,184,86)
img=Image.new("RGB",(S,S),INK)
# soft radial light behind the centre
glow=Image.new("L",(S,S),0); g=ImageDraw.Draw(glow)
for r in range(520,0,-8):
    g.ellipse((S/2-r,S/2-r,S/2+r,S/2+r),fill=int(60*(1-r/520)**1.6))
img=Image.composite(Image.new("RGB",(S,S),(52,30,34)),img,glow.filter(ImageFilter.GaussianBlur(30)))
# the menu's vermilion brush band, rotated -9 deg
band=Image.new("L",(S,S),0); b=ImageDraw.Draw(band)
for i in range(240):
    y=S*0.58+random.gauss(0,1)*4; x0=-60+random.random()*40; x1=S+60-random.random()*40
    h=150+random.gauss(0,1)*10
    yy=y+random.uniform(-h/2,h/2)
    b.line((x0,yy,x1,yy+random.uniform(-6,6)),fill=255,width=random.randint(2,6))
band=band.rotate(9,resample=Image.BICUBIC,center=(S/2,S/2)).filter(ImageFilter.GaussianBlur(1.2))
img.paste(Image.new("RGB",(S,S),VERM),(0,0),band)
# enso: a brush ring, thick where it lands, thinning out and broken at the end
ring=Image.new("L",(S,S),0); r=ImageDraw.Draw(ring)
cx,cy,R=S/2,S/2,390
start=math.radians(110); sweep=math.radians(320)
N=900
for k in range(N):
    t=k/N; a=start+t*sweep
    w=(18+t/0.06*30) if t<0.06 else 48-38*t**1.5
    rr=R+math.sin(t*11)*6
    x=cx+math.cos(a)*rr; y=cy+math.sin(a)*rr
    for _ in range(3):
        ox,oy=random.gauss(0,w*0.12),random.gauss(0,w*0.12)
        if t>0.86 and random.random()<0.45: continue
        r.ellipse((x+ox-w/2,y+oy-w/2,x+ox+w/2,y+oy+w/2),fill=255)
ring=ring.filter(ImageFilter.GaussianBlur(1.5))
img.paste(Image.new("RGB",(S,S),PAPER),(0,0),ring)
# the character, brushed: 忍, with an ink shadow
font=ImageFont.truetype("/usr/share/fonts/opentype/noto/NotoSerifCJK-Black.ttc",560,index=0)
txt=Image.new("L",(S,S),0); d=ImageDraw.Draw(txt)
bbox=d.textbbox((0,0),"忍",font=font); tw,th=bbox[2]-bbox[0],bbox[3]-bbox[1]
d.text(((S-tw)/2-bbox[0],(S-th)/2-bbox[1]-20),"忍",font=font,fill=255)
txt=txt.rotate(-6,resample=Image.BICUBIC,center=(S/2,S/2))
shadow=ImageChops.offset(txt,14,16).filter(ImageFilter.GaussianBlur(6))
img.paste(Image.new("RGB",(S,S),(0,0,0)),(0,0),shadow.point(lambda v:int(v*0.7)))
img.paste(Image.new("RGB",(S,S),PAPER),(0,0),txt)
# ink edge on the character
edge=txt.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(5))
img.paste(Image.new("RGB",(S,S),INK),(0,0),edge.point(lambda v:int(v*0.55)))
# small seal, lower right inside the circle
seal=Image.new("RGBA",(150,150),(0,0,0,0)); sd=ImageDraw.Draw(seal)
sd.rounded_rectangle((8,8,142,142),radius=18,fill=VERM+(255,),outline=PAPER+(255,),width=6)
sf=ImageFont.truetype("/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc",64,index=0)
sd.text((75,72),"ND",font=sf,fill=PAPER+(255,),anchor="mm")
seal=seal.rotate(12,resample=Image.BICUBIC,expand=True)
img.paste(seal,(int(S*0.66),int(S*0.64)),seal)
img.resize((512,512),Image.LANCZOS).save("discord-icon-512.png",optimize=True)
img.save("discord-icon-1024.png",optimize=True)
# circle preview as Discord shows it
m=Image.new("L",(512,512),0); ImageDraw.Draw(m).ellipse((0,0,511,511),fill=255)
p=Image.new("RGB",(512,512),(49,51,56)); p.paste(img.resize((512,512),Image.LANCZOS),(0,0),m); p.save("preview-circle.png")
