# Konoha, the drawn map (DESIGN, passe 2, 26/11: « la carte dessinée de Konoha,
# pas un plan de blocs »). Read from src/Shared/KonohaLayout.luau: districts,
# streets, the river, the walls, every building (its roof seen from above),
# the trees, the places. Drawn on parchment, ink lines, warm watercolour,
# hand-lettered names. 2 px per base stud: 1160 x 956 -> map_konoha.png.
# Run: python3 generate_map.py  (Playwright + Chrome; FONTS as the others)
import asyncio,os,re,math,random
from playwright.async_api import async_playwright
HERE=os.path.dirname(os.path.abspath(__file__))
SRC=os.path.join(HERE,'..','..','src','Shared','KonohaLayout.luau')
FONTS=os.environ.get('FONTS','/home/claude/ds/project/fonts')
s=open(SRC).read()
HX,MINZ,MAXZ=290,-262,216
Z=2.0
W,H=int(2*HX*Z),int((MAXZ-MINZ)*Z)
def P(x,z): return ((x+HX)*Z,(z-MINZ)*Z)
K='#2A1E17';INK='#3A2A20';RED='#B8352A'
D=re.findall(r'\{id="(\w+)",name="([^"]*)",x0=(-?\d+),z0=(-?\d+),x1=(-?\d+),z1=(-?\d+),color=Color3.fromRGB\((\d+),(\d+),(\d+)\)',s)
ST=re.findall(r'\{id="(\w+)",name="([^"]*)",a=Vector2.new\((-?[\d.]+),(-?[\d.]+)\),b=Vector2.new\((-?[\d.]+),(-?[\d.]+)\),width=(\d+)',s)
BL=s[s.index('M.Buildings={'):s.index('M.Outside={')]
B=re.findall(r'\{"(\w+)",(-?[\d.]+),(-?[\d.]+),([\d.]+),([\d.]+),([\d.]+),(-?\d+),"(\w+)"',BL)
TR=re.findall(r'\{"tree",(-?[\d.]+),(-?[\d.]+),',s)
PO=re.findall(r'\{id="(\w+)",name="([^"]*)",at=Vector2.new\((-?[\d.]+),(-?[\d.]+)\),icon="(\w+)",tier=(\d)([^}]*)\}',s)
WL=re.findall(r'\{"(\w+)",(-?[\d.]+),(-?[\d.]+),([\d.]+),([\d.]+),([\d.]+)\}',s[s.index('M.Walls={'):s.index('M.RoofDecks={')])
BR=re.findall(r'\{(-?[\d.]+),(-?[\d.]+),[\d.]+,(-?[\d.]+),(-?[\d.]+),[\d.]+,\d\}',s[s.index('M.Bridges={'):s.index('M.Fills={')])
rnd=random.Random(13)
svg=[]
add=svg.append
# parchment and a soft vignette
add(f'<defs><filter id="rough"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="4"/><feDisplacementMap in="SourceGraphic" scale="3"/></filter>'
    f'<filter id="paper"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" seed="2"/><feColorMatrix values="0 0 0 0 0.45  0 0 0 0 0.32  0 0 0 0 0.2  0 0 0 .10 0"/></filter>'
    f'<radialGradient id="vig" cx=".5" cy=".5" r=".75"><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#5a3a1a" stop-opacity=".35"/></radialGradient>'
    f'<pattern id="tiles" width="5" height="5" patternUnits="userSpaceOnUse"><path d="M0 4.5 H5" stroke="#000" stroke-opacity=".25" stroke-width="1"/></pattern></defs>')
add(f'<rect width="{W}" height="{H}" fill="#EAD9B6"/><rect width="{W}" height="{H}" filter="url(#paper)"/>')
# districts: warm watercolour washes
for i,n,x0,z0,x1,z1,r,g,b in D:
    a=P(int(x0),int(z0));c=P(int(x1),int(z1))
    col=f'rgb({int(r)},{int(g)},{int(b)})'
    add(f'<rect x="{a[0]+3}" y="{a[1]+3}" width="{c[0]-a[0]-6}" height="{c[1]-a[1]-6}" rx="18" fill="{col}" opacity=".28" filter="url(#rough)"/>')
# the Hokage rock: a cliff band with four faces
a=P(-290,-262);c=P(290,-196)
add(f'<rect x="0" y="0" width="{W}" height="{c[1]}" fill="#9C8770" filter="url(#rough)"/>')
for k in range(60):
    x=rnd.uniform(0,W);y=rnd.uniform(4,c[1]-8)
    add(f'<path d="M{x:.0f} {y:.0f} l{rnd.uniform(6,18):.0f} {rnd.uniform(-4,4):.0f}" stroke="{INK}" stroke-opacity=".35" stroke-width="2" stroke-linecap="round"/>')
for k,x in enumerate([-75,-25,25,75]):
    px,py=P(x,-232)
    add(f'<ellipse cx="{px}" cy="{py}" rx="30" ry="36" fill="#B39D84" stroke="{INK}" stroke-width="3"/>'
        f'<path d="M{px-14} {py-6} h9 M{px+5} {py-6} h9 M{px-10} {py+14} q10 6 20 0" stroke="{INK}" stroke-width="3" fill="none" stroke-linecap="round"/>')
add(f'<path d="M0 {c[1]} Q{W/2} {c[1]+10} {W} {c[1]}" stroke="{INK}" stroke-width="5" fill="none"/>')
# the river
rx0,rz0=P(186,-232);rx1,rz1=P(212,-40)
add(f'<path d="M{(rx0+rx1)/2} {rz0} C {rx0} {rz0+120}, {rx1+20} {rz0+220}, {(rx0+rx1)/2} {rz1+60} S {rx0+10} {H-40}, {(rx0+rx1)/2+30} {H}" stroke="#6FA3C8" stroke-width="{26*Z}" fill="none" stroke-linecap="round" opacity=".9"/>')
add(f'<path d="M{(rx0+rx1)/2} {rz0} C {rx0} {rz0+120}, {rx1+20} {rz0+220}, {(rx0+rx1)/2} {rz1+60} S {rx0+10} {H-40}, {(rx0+rx1)/2+30} {H}" stroke="#E9F3F8" stroke-width="2" stroke-dasharray="6 14" fill="none"/>')
# streets: cream paths with an ink edge
for i,n,ax,az,bx,bz,w in ST:
    a=P(float(ax),float(az));b=P(float(bx),float(bz))
    add(f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="{INK}" stroke-width="{float(w)*Z+4}" stroke-linecap="round" opacity=".55"/>')
for i,n,ax,az,bx,bz,w in ST:
    a=P(float(ax),float(az));b=P(float(bx),float(bz))
    add(f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="#F3E6C8" stroke-width="{float(w)*Z}" stroke-linecap="round"/>')
# bridges
for x0,z0,x1,z1 in BR:
    a=P(float(x0),float(z0));b=P(float(x1),float(z1))
    add(f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="#A0522D" stroke-width="12" stroke-linecap="square"/><line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="{INK}" stroke-width="12" stroke-dasharray="2 5" opacity=".5"/>')
# trees: round puffs
for x,z in TR:
    px,py=P(float(x),float(z));r=rnd.uniform(7,10)
    add(f'<circle cx="{px+2}" cy="{py+3}" r="{r}" fill="#3B4A2A" opacity=".35"/><circle cx="{px}" cy="{py}" r="{r}" fill="#6E8F4E" stroke="{INK}" stroke-width="1.6"/><circle cx="{px-r*.3}" cy="{py-r*.3}" r="{r*.35}" fill="#93B26C"/>')
# buildings: roofs from above, a shadow, tiles, the ridge
ROOF={'clan_house':'#5E5450','small_house':'#7A5C4A','machiya':'#4F4540','shop_house':'#8C3B2E','tank_house':'#B07A46','apartment':'#9A6B48','tower_house':'#6B4A3A'}
for m,x,z,w,d,h,yaw,dist in B:
    x,z,w,d,h,yaw=float(x),float(z),float(w),float(d),float(h),int(yaw)
    px,py=P(x,z)
    if yaw in (90,270): w,d=d,w
    ww,dd=w*Z,d*Z
    col=ROOF.get(m,'#A0453A' if 'gate' in m or m=='torii' else '#6A5446')
    if m in ('great_gate','torii','hyuga_gate'): col=RED
    sh=min(10,h*.35)
    add(f'<g transform="translate({px} {py})"><rect x="{-ww/2+sh*.6}" y="{-dd/2+sh*.6}" width="{ww}" height="{dd}" fill="#3a2a1a" opacity=".28"/>'
        f'<rect x="{-ww/2}" y="{-dd/2}" width="{ww}" height="{dd}" fill="{col}" stroke="{K}" stroke-width="2.2"/>'
        f'<rect x="{-ww/2}" y="{-dd/2}" width="{ww}" height="{dd}" fill="url(#tiles)"/>'
        + (f'<line x1="{-ww/2+3}" y1="0" x2="{ww/2-3}" y2="0" stroke="{K}" stroke-width="2"/>' if ww>=dd else f'<line x1="0" y1="{-dd/2+3}" x2="0" y2="{dd/2-3}" stroke="{K}" stroke-width="2"/>')
        + (f'<circle cx="{ww*.2}" cy="{-dd*.2}" r="{min(ww,dd)*.22}" fill="#C9A06A" stroke="{K}" stroke-width="1.6"/>' if m in ('tank_house','apartment','tower_house','water_tower') else '')
        + '</g>')
# the walls: a thick double ink line, the gate in red
for i,x,z,w,d,h in WL:
    x,z,w,d=float(x),float(z),float(w),float(d)
    a=P(x-w/2,z-d/2)
    big=float(h)>20
    add(f'<rect x="{a[0]}" y="{a[1]}" width="{max(w*Z,3)}" height="{max(d*Z,3)}" fill="{"#7B6A58" if big else "#9C8A74"}" stroke="{K}" stroke-width="{3 if big else 1.5}"/>')
# the places: a hand-lettered label on a paper slip, a red seal on the masters'
placed=[]
def clash(x,y,w):
    return any(abs(y-py2)<24 and x<x2+w2 and x+w>x2 for x2,py2,w2 in placed)
for i,n,x,z,icon,tier,rest in PO:
    if 'far=true' in rest or int(tier)>2: continue
    n=n.replace('Ū','U').replace('Ō','O').replace('ū','u').replace('ō','o')
    px,py=P(float(x),float(z))
    master='master=' in rest
    tw=len(n)*7.4+14
    east=px>W-tw-30
    tx=px-tw-10 if east else px+10
    ly=py
    while clash(tx,ly,tw): ly+=24
    placed.append((tx,ly,tw))
    if ly!=py: add(f'<line x1="{px}" y1="{py}" x2="{tx+(tw if east else 0)}" y2="{ly}" stroke="{K}" stroke-width="1.5"/>')
    py0,py=py,ly
    add(f'<g transform="rotate({rnd.uniform(-2.5,2.5):.1f} {px} {py})"><rect x="{tx}" y="{py-11}" width="{tw}" height="22" rx="3" fill="#F6EBD2" stroke="{K}" stroke-width="1.6" opacity=".95"/>'
        f'<text x="{tx+tw/2}" y="{py+5}" text-anchor="middle" font-family="Marker" font-size="13" fill="{K}">{n}</text></g>')
    add(f'<circle cx="{px}" cy="{py0}" r="7" fill="{RED if master else K}" stroke="#F6EBD2" stroke-width="2.5"/>')
# compass and frame
cx,cy=W-70,H-70
add(f'<g transform="translate({cx} {cy})"><circle r="34" fill="#F6EBD2" stroke="{K}" stroke-width="3"/><path d="M0 -30 L8 0 L0 30 L-8 0 Z" fill="{K}"/><path d="M0 -30 L8 0 L-8 0 Z" fill="{RED}"/>'
    f'<text y="-38" text-anchor="middle" font-family="Bangers" font-size="20" fill="{K}">N</text></g>')
add(f'<rect width="{W}" height="{H}" fill="url(#vig)"/><rect x="5" y="5" width="{W-10}" height="{H-10}" fill="none" stroke="{K}" stroke-width="10"/>')
html=f'''<html><head><style>
@font-face{{font-family:Bangers;src:url(file://{FONTS}/Bangers-400.woff2)}}
@font-face{{font-family:Marker;src:url(file://{FONTS}/PermanentMarker-400.woff2)}}
body{{margin:0}}</style></head><body><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{"".join(svg)}</svg></body></html>'''
async def main():
    path=os.path.join(HERE,'_map.html');open(path,'w').write(html)
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--allow-file-access-from-files'])
        pg=await b.new_page(viewport={'width':W,'height':H})
        await pg.goto('file://'+path);await pg.wait_for_timeout(500)
        await pg.screenshot(path=os.path.join(HERE,'map_konoha.png'))
        await b.close()
    os.remove(path)
    print(W,H,len(B),'buildings',len(TR),'trees')
asyncio.run(main())
