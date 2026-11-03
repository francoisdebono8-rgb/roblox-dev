import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
random.seed(3)
W,H=2560,1440
INK=(16,14,19); VERM=(190,40,36); PAPER=(240,232,212); GOLD=(230,184,86)
img=Image.new("RGB",(W,H),INK)
# warm glow in the middle band
glow=Image.new("L",(W,H),0); g=ImageDraw.Draw(glow)
g.ellipse((W/2-1100,H/2-380,W/2+1100,H/2+380),fill=70)
img=Image.composite(Image.new("RGB",(W,H),(58,30,34)),img,glow.filter(ImageFilter.GaussianBlur(160)))
# vermilion brush band, -9 deg, through the safe area
band=Image.new("L",(W,H),0); b=ImageDraw.Draw(band)
for i in range(700):
    yy=H*0.5-40+random.uniform(-70,70); 
    b.line((-200+random.random()*120,yy,W+200-random.random()*120,yy+random.uniform(-8,8)),fill=255,width=random.randint(2,7))
band=band.rotate(-7,resample=Image.BICUBIC,center=(W/2,H/2)).filter(ImageFilter.GaussianBlur(1.4))
img.paste(Image.new("RGB",(W,H),VERM),(0,0),band)
# big faint kanji right and left
kf=ImageFont.truetype("/usr/share/fonts/opentype/noto/NotoSerifCJK-Black.ttc",620,index=0)
k=Image.new("L",(W,H),0); kd=ImageDraw.Draw(k)
kd.text((W*0.80,H*0.50),"忍",font=kf,fill=26,anchor="mm"); kd.text((W*0.20,H*0.50),"闘",font=kf,fill=26,anchor="mm")
img.paste(Image.new("RGB",(W,H),PAPER),(0,0),k)
# title (Anton-like: use Inter Black italic)
tf=ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-BlackItalic.otf",190)
t=Image.new("L",(W,H),0); td=ImageDraw.Draw(t)
td.text((W/2,H/2-40),"NINJA DUEL",font=tf,fill=255,anchor="mm")
sh=t.filter(ImageFilter.GaussianBlur(10))
img.paste(Image.new("RGB",(W,H),(0,0,0)),(14,18),sh.point(lambda v:int(v*0.8)))
edge=t.filter(ImageFilter.MaxFilter(13))
img.paste(Image.new("RGB",(W,H),INK),(0,0),edge)
img.paste(Image.new("RGB",(W,H),PAPER),(0,0),t)
sf=ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Black.otf",52)
d=ImageDraw.Draw(img)
d.text((W/2,H/2+112),"1v1 NINJA FIGHTING ON ROBLOX  •  BETA TESTERS WANTED",font=sf,fill=PAPER,anchor="mm",stroke_width=6,stroke_fill=INK)
img.save("youtube-banner-2560.jpg",quality=88)
# preview of the safe area (what desktop shows: 2560x423 center strip)
img.crop((0,(H-423)//2,W,(H+423)//2)).resize((1280,212)).save("banner-preview.jpg",quality=85)
# square avatar for TikTok/YouTube = the Discord icon at 800
Image.open("discord-icon-1024.png").convert("RGB").resize((800,800),Image.LANCZOS).save("avatar-800.jpg",quality=90)
