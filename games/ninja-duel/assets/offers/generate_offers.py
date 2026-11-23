# The offers' images for the Creator Dashboard (512 x 512), DA v3 (manga page:
# paper, ink, red brush, Bangers). DESIGN, step 5. Pictograms drawn here; the
# kits, outfits, weapons and the VIP cape wait for the ANIMATEUR's 3D renders.
# Run: python3 generate_offers.py  (Playwright + Chrome; fonts from FONTS)
import asyncio,os,sys
from playwright.async_api import async_playwright
HERE=os.path.dirname(os.path.abspath(__file__))
FONTS=os.environ.get('FONTS','/home/claude/ds/project/fonts')
K='#141011';R='#C3121D';P='#F4E9D4';G='#FFC23D';C='#FFF8EC'
def coin(cx,cy,r):
    return f'<ellipse cx="{cx}" cy="{cy+10}" rx="{r}" ry="{r*.35}" fill="{K}"/><ellipse cx="{cx}" cy="{cy}" rx="{r}" ry="{r*.35}" fill="{G}" stroke="{K}" stroke-width="7"/><rect x="{cx-r*.18}" y="{cy-r*.12}" width="{r*.36}" height="{r*.24}" fill="none" stroke="{K}" stroke-width="5"/>'
def stack(cx,base,n,r=80):
    return ''.join(coin(cx,base-i*30,r) for i in range(n))
def bolt(): return f'<path d="M286 70 L190 262 H262 L222 430 L338 210 H262 L306 70 Z" fill="{G}" stroke="{K}" stroke-width="12" stroke-linejoin="round"/>'
def cape():
    return (f'<path d="M180 120 Q256 96 332 120 L382 400 Q256 440 130 400 Z" fill="{R}" stroke="{K}" stroke-width="12" stroke-linejoin="round"/>'
            f'<path d="M180 120 Q256 150 332 120" fill="none" stroke="{K}" stroke-width="10"/><path d="M220 200 L256 380 M292 200 L256 380" stroke="#8E0C15" stroke-width="8"/>'
            f'<rect x="198" y="236" width="116" height="54" rx="6" fill="{G}" stroke="{K}" stroke-width="7"/><text x="256" y="278" text-anchor="middle" font-family="Bangers" font-size="44" fill="{K}">VIP</text>')
def scrolls():
    out=''
    for i,(x,y,r) in enumerate([(150,190,-12),(256,170,0),(362,190,12),(200,300,-6),(312,300,6)]):
        out+=f'<g transform="rotate({r} {x} {y})"><rect x="{x-44}" y="{y-62}" width="88" height="124" rx="8" fill="{C}" stroke="{K}" stroke-width="7"/><rect x="{x-44}" y="{y-62}" width="88" height="22" fill="{R}" stroke="{K}" stroke-width="7"/><path d="M{x-22} {y-10} h44 M{x-22} {y+12} h44 M{x-22} {y+34} h30" stroke="{K}" stroke-width="5"/></g>'
    return out
def gate():
    return (f'<rect x="120" y="150" width="34" height="250" fill="{R}" stroke="{K}" stroke-width="9"/><rect x="358" y="150" width="34" height="250" fill="{R}" stroke="{K}" stroke-width="9"/>'
            f'<path d="M84 130 Q256 96 428 130 L420 160 Q256 130 92 160 Z" fill="{K}"/><rect x="108" y="186" width="296" height="24" fill="{R}" stroke="{K}" stroke-width="8"/>'
            f'<path d="M176 400 L206 300 L236 400 M276 400 L306 300 L336 400" fill="none" stroke="{K}" stroke-width="12" stroke-linecap="round"/><circle cx="206" cy="284" r="18" fill="{K}"/><circle cx="306" cy="284" r="18" fill="{K}"/>')
O={
 'pass_2x_mastery':('2X MASTERY','EVERY DUEL COUNTS DOUBLE',f'<text x="256" y="330" text-anchor="middle" font-family="Bangers" font-size="250" fill="{R}" stroke="{K}" stroke-width="10" paint-order="stroke">2X</text>{bolt()}'),
 'pass_vip':('VIP','GOLDEN NAME • CAPE • TAG',cape()),
 'pass_private_server_plus':('PRIVATE SERVER+','YOUR TOURNAMENT, YOUR FRIENDS',gate()),
 'product_outfits_bundle':('8 PRODIGY OUTFITS','THE WHOLE SET, ONE PRICE',scrolls()),
 'product_ryo_small':('1 000 RYŌ','FOR LOOKS ONLY',stack(256,320,4,96)),
 'product_ryo_medium':('3 000 RYŌ','FOR LOOKS ONLY',stack(190,330,5,84)+stack(326,330,7,84)),
 'product_ryo_large':('8 000 RYŌ','FOR LOOKS ONLY',stack(132,330,6,74)+stack(256,330,9,74)+stack(380,330,7,74)),
}
def page(title,sub,art):
    return f'''<html><head><style>
@font-face{{font-family:Bangers;src:url(file://{FONTS}/Bangers-400.woff2)}}
@font-face{{font-family:Builder;src:url(file://{FONTS}/BuilderSans-ExtraBold-800.otf)}}
body{{margin:0}}</style></head><body>
<svg viewBox="0 0 512 512" width="512" height="512" style="display:block">
<defs><pattern id="dots" width="12" height="12" patternUnits="userSpaceOnUse"><circle cx="6" cy="6" r="1.6" fill="{K}" opacity=".13"/></pattern></defs>
<rect width="512" height="512" fill="{P}"/><rect width="512" height="512" fill="url(#dots)"/>
<path d="M0 400 L512 360 L512 512 L0 512 Z" fill="{K}"/>
<g>{art}</g>
<path d="M40 418 Q256 396 470 412" stroke="{R}" stroke-width="16" stroke-linecap="round" fill="none"/>
<text x="256" y="466" text-anchor="middle" font-family="Bangers" font-size="{60 if len(title)<12 else 46}" fill="{C}" letter-spacing="1">{title}</text>
<text x="256" y="498" text-anchor="middle" font-family="Builder" font-size="18" fill="{G}">{sub}</text>
<rect x="8" y="8" width="496" height="496" fill="none" stroke="{K}" stroke-width="16"/>
</svg></body></html>'''
async def main():
    out=os.path.join(HERE,'png');os.makedirs(out,exist_ok=True)
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--allow-file-access-from-files'])
        pg=await b.new_page(viewport={'width':512,'height':512})
        for name,(t,s,a) in O.items():
            path=os.path.join(out,name+'.html');open(path,'w').write(page(t,s,a))
            await pg.goto('file://'+path);await pg.wait_for_timeout(250)
            await pg.screenshot(path=os.path.join(out,name+'.png'))
            os.remove(path)
        await b.close()
asyncio.run(main())
