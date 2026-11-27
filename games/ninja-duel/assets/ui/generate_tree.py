# The skill trees, painted (DESIGN 27/11, François: « y'a de l'idée mais c'est
# super moche, on ne voit pas que ça vient de vrais jeux »). Real games paint
# their trees; ours is an ink-wash painting (sumi-e), the way Ghost of
# Tsushima paints its menus: a parchment, a red sun behind the crown, a trunk
# and boughs in dry-brush ink, pine "cloud" pads of grey-green wash, roots in
# a band of earth. The seals stay UI (Client/TreePanel), placed on the very
# points this painting is drawn to: the layout comes from the game's own
# TreePanel.treeLayout (lune run tools/tree_layouts.luau writes tree_layouts.json).
# Run: python3 generate_tree.py [layouts.json] [--preview]
# Out: trees/<kit>_top.jpg and trees/<kit>_bottom.jpg (1024 wide, halves of
# the canvas, as Roblox images stop at 1024), and with --preview a composite
# with the seals drawn, to judge the look.
import asyncio,os,sys,math,random,json
from playwright.async_api import async_playwright
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__))
FONTS=os.environ.get('FONTS','/home/claude/ds/project/fonts')
SRC=sys.argv[1] if len(sys.argv)>1 and not sys.argv[1].startswith('--') else os.path.join(HERE,'tree_layouts.json')
PREVIEW='--preview' in sys.argv
ONLY=[a[7:] for a in sys.argv if a.startswith('--only=')]
OUT=os.path.join(HERE,'trees');os.makedirs(OUT,exist_ok=True)
INK='#1E1814';RED='#B8352A';PAPER='#EFE5CF';W=1024

def catmull(pts,steps=8):
    out=[]
    p=[pts[0]]+pts+[pts[-1]]
    for i in range(1,len(p)-2):
        a,b,c,d=p[i-1],p[i],p[i+1],p[i+2]
        for s in range(steps):
            t=s/steps;t2=t*t;t3=t2*t
            out.append(tuple(.5*((2*b[k])+(-a[k]+c[k])*t+(2*a[k]-5*b[k]+4*c[k]-d[k])*t2+(-a[k]+3*b[k]-3*c[k]+d[k])*t3) for k in (0,1)))
    out.append(pts[-1])
    return out

def stroke(pts,w0,w1,rnd,wobble=1.0):
    """A tapered brush stroke as a filled outline (w0 at the start, w1 at the end)."""
    pts=catmull(pts)
    L=[];R=[]
    n=len(pts)
    for i,(x,y) in enumerate(pts):
        a=pts[max(0,i-1)];b=pts[min(n-1,i+1)]
        dx,dy=b[0]-a[0],b[1]-a[1];l=math.hypot(dx,dy) or 1
        nx,ny=-dy/l,dx/l
        t=i/max(1,n-1)
        w=(w0+(w1-w0)*t)*(1+wobble*.12*math.sin(i*.7+rnd.random()))/2
        L.append((x+nx*w,y+ny*w));R.append((x-nx*w,y-ny*w))
    poly=L+R[::-1]
    return 'M'+' L'.join(f'{x:.1f} {y:.1f}' for x,y in poly)+' Z'

def bough_items(d):
    b=d.get('boughs') or {}
    return list(b.items()) if isinstance(b,dict) else [(i+1,v) for i,v in enumerate(b) if v]

def pad(cx,cy,w,h,rnd,tone):
    """A pine 'cloud' pad: overlapping wash lobes, darker on top, ragged."""
    s=[]
    for k in range(7):
        ox=rnd.uniform(-w*.42,w*.42);oy=rnd.uniform(-h*.25,h*.2)
        rx=rnd.uniform(w*.22,w*.36);ry=rnd.uniform(h*.35,h*.55)
        s.append(f'<ellipse cx="{cx+ox:.0f}" cy="{cy+oy:.0f}" rx="{rx:.0f}" ry="{ry:.0f}" fill="{tone}" opacity=".55"/>')
    # needle strokes along the top edge
    for k in range(14):
        x=cx+rnd.uniform(-w*.48,w*.48);y=cy-h*.35+rnd.uniform(-6,8)
        s.append(f'<path d="M{x:.0f} {y:.0f} l{rnd.uniform(-9,9):.0f} {rnd.uniform(-12,-5):.0f}" stroke="{INK}" stroke-opacity=".55" stroke-width="2.2" stroke-linecap="round"/>')
    return f'<g filter="url(#wash)">{"".join(s)}</g>'

def paint(kit,d):
    H=int(math.ceil(d['height']+10))
    rnd=random.Random(hash(kit)%1000)
    g=d['ground'];tx=d['trunkX'];cy=d['crownY']
    svg=[]
    add=svg.append
    add('<defs>'
        '<filter id="rough" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.06" numOctaves="2" seed="3"/><feDisplacementMap in="SourceGraphic" scale="5"/></filter>'
        # dry brush: the ink cut by streaks along the stroke, and its edge torn
        '<filter id="dry" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.9 0.05" numOctaves="2" seed="7" result="n"/>'
        '<feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.4 1.75" result="m"/>'
        '<feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="5" result="t"/><feDisplacementMap in="SourceGraphic" in2="t" scale="6" result="d"/>'
        '<feComposite in="d" in2="m" operator="in"/></filter>'
        '<filter id="bleed" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="5"/></filter>'
        '<filter id="wash" x="-30%" y="-30%" width="160%" height="160%"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="3" seed="11"/><feDisplacementMap in="SourceGraphic" scale="18"/><feGaussianBlur stdDeviation="1.4"/></filter>'
        '<filter id="paper"><feTurbulence type="fractalNoise" baseFrequency="0.75" numOctaves="3" seed="2"/><feColorMatrix values="0 0 0 0 0.42  0 0 0 0 0.30  0 0 0 0 0.18  0 0 0 .09 0"/></filter>'
        '<filter id="fibres"><feTurbulence type="fractalNoise" baseFrequency="0.012 0.3" numOctaves="2" seed="9"/><feColorMatrix values="0 0 0 0 0.45  0 0 0 0 0.33  0 0 0 0 0.2  0 0 0 .07 0"/></filter>'
        f'<radialGradient id="sun"><stop offset="0" stop-color="{RED}" stop-opacity=".95"/><stop offset=".86" stop-color="{RED}" stop-opacity=".88"/><stop offset="1" stop-color="{RED}" stop-opacity="0"/></radialGradient>'
        f'<linearGradient id="earth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5B4636" stop-opacity="0"/><stop offset=".18" stop-color="#5B4636" stop-opacity=".22"/><stop offset="1" stop-color="#3E2E22" stop-opacity=".34"/></linearGradient>'
        '<radialGradient id="vig" cx=".5" cy=".45" r=".8"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#4a2f14" stop-opacity=".28"/></radialGradient>'
        '</defs>')
    # the parchment
    add(f'<rect width="{W}" height="{H}" fill="{PAPER}"/><rect width="{W}" height="{H}" filter="url(#paper)"/><rect width="{W}" height="{H}" filter="url(#fibres)"/>')
    # the tiers: a faint mist line each, a closed one is a UI veil over this
    for b in d['bands']:
        y=b['bottom']
        add(f'<path d="M{110} {y:.0f} Q{W/2} {y-6:.0f} {W-30} {y:.0f}" stroke="{INK}" stroke-opacity=".16" stroke-width="3" fill="none" filter="url(#rough)"/>')
    # the red sun behind the crown
    sr=min(190,d['crownY']+60) if any(n['crown'] for n in d['nodes']) else 0
    if sr:
        add(f'<circle cx="{tx:.0f}" cy="{cy+10:.0f}" r="{sr}" fill="url(#sun)" filter="url(#rough)"/>')
    # the earth
    add(f'<path d="M0 {g+36:.0f} Q{W*.3:.0f} {g+20:.0f} {W/2:.0f} {g+30:.0f} T{W} {g+28:.0f} V{H+60} H-20 Z" fill="url(#earth)" filter="url(#rough)"/>')
    # the roots: to each starting technique (the UI puts its seal at the tip)
    ns=d.get('starts',0)
    for i in range(ns):
        rx=96+(W-96-16)*(i+.5)/ns
        pts=[(tx,g+20),(tx+(rx-tx)*.35,g+60),(rx+(tx-rx)*.15,g+96),(rx,g+110)]
        add(f'<path d="{stroke(pts,22,5,rnd)}" fill="{INK}" opacity=".35" filter="url(#bleed)"/>')
        add(f'<path d="{stroke(pts,20,4,rnd)}" fill="{INK}" filter="url(#dry)"/>')
        for k in range(2):
            ox=rnd.uniform(-40,40)
            add(f'<path d="{stroke([(rx+(tx-rx)*.3,g+80),(rx+(tx-rx)*.3+ox,g+110),(rx+(tx-rx)*.3+ox*1.6,g+140)],7,1,rnd)}" fill="{INK}" opacity=".7" filter="url(#dry)"/>')
    # the boughs, behind the trunk's edge: dry ink, a bleed under each
    for b,pts in bough_items(d):
        P=[(p['x'],p['y']) for p in pts]
        add(f'<path d="{stroke(P,24,7,rnd)}" fill="{INK}" opacity=".3" filter="url(#bleed)"/>')
        add(f'<path d="{stroke(P,20,6,rnd)}" fill="{INK}" filter="url(#dry)"/>')
        add(f'<path d="{stroke(P,20,6,rnd)}" fill="{INK}" opacity=".55" filter="url(#rough)"/>')
    # the twigs, from the bough to each node
    for n in d['nodes']:
        if n.get('fx') is None: continue
        P=[(n['fx'],n['fy']),((n['fx']+n['x'])/2,(n['fy']+n['y'])/2+6),(n['x'],n['y'])]
        add(f'<path d="{stroke(P,9,4,rnd,.4)}" fill="{INK}" filter="url(#dry)"/>')
    # the trunk: thick, a lean and a knot, from the earth into the crown
    top=cy+30 if sr else min(n['y'] for n in d['nodes'])-30
    T=[(tx-6,g+40),(tx+10,g-120),(tx-14,(g+top)/2),(tx+8,top+120),(tx,top)]
    add(f'<path d="{stroke(T,62,18,rnd,.6)}" fill="{INK}" opacity=".3" filter="url(#bleed)"/>')
    add(f'<path d="{stroke(T,54,15,rnd,.6)}" fill="{INK}" filter="url(#dry)"/>')
    add(f'<path d="{stroke(T,54,15,rnd,.6)}" fill="#3A2C22" opacity=".55" filter="url(#rough)"/>')
    for k in range(9):  # bark: light dry streaks up the trunk
        y=g-rnd.uniform(40,g-top-60);x=tx+rnd.uniform(-16,16)
        add(f'<path d="M{x:.0f} {y:.0f} q{rnd.uniform(-6,6):.0f} -30 {rnd.uniform(-4,4):.0f} -{rnd.uniform(40,90):.0f}" stroke="{PAPER}" stroke-opacity=".45" stroke-width="{rnd.uniform(2,4):.1f}" fill="none" filter="url(#dry)"/>')
    # the pine pads: at the top of every bough, a few along it, and the canopy
    tones=['#4E5B45','#5F6B50','#3F4A38']
    for b,pts in bough_items(d):
        last=pts[-1]
        add(pad(last['x'],last['y']-8,170,56,rnd,rnd.choice(tones)))
        if len(pts)>8:
            mid=pts[len(pts)//2]
            side=rnd.choice([-1,1])
            add(pad(mid['x']+side*58,mid['y']-30,110,40,rnd,rnd.choice(tones)))
    if sr:
        for k in range(5):
            ang=math.pi*(.15+.7*k/4)
            add(pad(tx-math.cos(ang)*230,cy+40-math.sin(ang)*60,200,62,rnd,rnd.choice(tones)))
    add(f'<rect width="{W}" height="{H}" fill="url(#vig)"/>')
    return H,svg

def seals(d):
    s=[]
    for n in d['nodes']:
        r=52 if n['crown'] else (38 if n['major'] else 30)
        fill=RED if n['crown'] else '#F6EEDC'
        s.append(f'<circle cx="{n["x"]:.0f}" cy="{n["y"]:.0f}" r="{r}" fill="{fill}" stroke="{INK}" stroke-width="3"/>')
        s.append(f'<circle cx="{n["x"]:.0f}" cy="{n["y"]:.0f}" r="{r-7}" fill="none" stroke="{INK}" stroke-opacity=".35" stroke-width="1.5"/>')
    ns=d.get('starts',0)
    for i in range(ns):
        rx=96+(W-96-16)*(i+.5)/ns
        s.append(f'<circle cx="{rx:.0f}" cy="{d["ground"]+110:.0f}" r="24" fill="{INK}" stroke="#F6EEDC" stroke-width="3"/>')
    return s

async def main():
    data=json.load(open(SRC))
    async with async_playwright() as p:
        br=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--allow-file-access-from-files'])
        for kit,d in data.items():
            if ONLY and kit not in ONLY: continue
            H,svg=paint(kit,d)
            for name,extra in [('paint',[])]+([('preview',seals(d))] if PREVIEW else []):
                html=f'<html><body style="margin:0"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{"".join(svg+extra)}</svg></body></html>'
                path=os.path.join(OUT,'_t.html');open(path,'w').write(html)
                pg=await br.new_page(viewport={'width':W,'height':H})
                await pg.goto('file://'+path);await pg.wait_for_timeout(300)
                if name=='paint':
                    half=H//2
                    for part,clip in (('top',{'x':0,'y':0,'width':W,'height':half}),('bottom',{'x':0,'y':half,'width':W,'height':H-half})):
                        tmp=os.path.join(OUT,'_t.png')
                        await pg.screenshot(path=tmp,clip=clip)
                        Image.open(tmp).convert('RGB').save(os.path.join(OUT,f'{kit}_{part}.jpg'),quality=90,optimize=True)
                        os.remove(tmp)
                else:
                    await pg.screenshot(path=os.path.join(OUT,f'_preview_{kit}.png'),full_page=True)
                await pg.close()
            os.remove(path)
            print(kit,W,H)
        await br.close()
asyncio.run(main())
