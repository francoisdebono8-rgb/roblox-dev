import asyncio
from playwright.async_api import async_playwright
F='/home/claude/ds/project/fonts/'
DEFS='''<svg width="0" height="0" style="position:absolute"><defs>
<filter id="rough" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="0.04" numOctaves="3" seed="4" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="8" xChannelSelector="R" yChannelSelector="G"/></filter>
<filter id="brushy" x="-5%" y="-30%" width="110%" height="160%"><feTurbulence type="fractalNoise" baseFrequency="0.09 0.5" numOctaves="2" seed="7" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="7" xChannelSelector="R" yChannelSelector="G"/></filter>
<filter id="ink" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="0.6" numOctaves="2" seed="2" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="3"/></filter>
<filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" seed="9" stitchTiles="stitch"/><feColorMatrix type="matrix" values="0 0 0 0 0.30  0 0 0 0 0.22  0 0 0 0 0.14  0 0 0 0.22 0"/></filter>
<filter id="fibre"><feTurbulence type="fractalNoise" baseFrequency="0.012 0.18" numOctaves="2" seed="5" stitchTiles="stitch"/><feColorMatrix type="matrix" values="0 0 0 0 0.35  0 0 0 0 0.25  0 0 0 0 0.15  0 0 0 0.12 0"/></filter>
</defs></svg>'''
R='#C3121D'
A={
'paper_9s':(256,256,f'<svg width="256" height="256"><rect x="6" y="6" width="244" height="244" fill="#FFFDF8" filter="url(#rough)"/><g filter="url(#rough)"><rect x="6" y="6" width="244" height="244" filter="url(#grain)"/><rect x="6" y="6" width="244" height="244" filter="url(#fibre)"/></g></svg>'),
'ink_frame_9s':(256,256,'<svg width="256" height="256"><rect x="10" y="10" width="236" height="236" fill="none" stroke="#141011" stroke-width="9" filter="url(#rough)"/></svg>'),
'ink_band':(512,96,'<svg width="512" height="96"><path d="M14 18 L500 10 L496 84 L10 88 Z" fill="#141011" filter="url(#rough)"/></svg>'),
'stamp_done':(512,512,f'<svg width="512" height="512" viewBox="0 0 200 200"><g filter="url(#ink)"><rect x="14" y="52" width="172" height="96" fill="none" stroke="{R}" stroke-width="9"/><rect x="26" y="64" width="148" height="72" fill="none" stroke="{R}" stroke-width="3"/><text x="100" y="122" text-anchor="middle" font-family="Bangers" font-size="62" fill="{R}">DONE</text></g></svg>'),
'stamp_approved':(512,512,f'<svg width="512" height="512" viewBox="0 0 200 200"><g filter="url(#ink)" fill="none" stroke="{R}"><circle cx="100" cy="100" r="88" stroke-width="9"/><circle cx="100" cy="100" r="70" stroke-width="3"/></g><g filter="url(#ink)"><text x="100" y="114" text-anchor="middle" font-family="Bangers" font-size="36" fill="{R}">APPROVED</text></g></svg>'),
'brush_circle':(512,256,f'<svg width="512" height="256" viewBox="0 0 300 150"><path d="M40 86 C 30 34, 150 14, 236 22 C 296 28, 300 100, 222 122 C 150 140, 40 134, 18 104 C 6 80, 46 46, 104 34" fill="none" stroke="{R}" stroke-width="8" stroke-linecap="round" filter="url(#brushy)"/></svg>'),
'brush_underline':(512,64,f'<svg width="512" height="64"><path d="M14 38 C 120 24, 320 22, 498 32" stroke="{R}" stroke-width="16" fill="none" stroke-linecap="round" filter="url(#brushy)"/></svg>'),
'halftone_tile':(64,64,'<svg width="64" height="64">'+''.join(f'<circle cx="{x*8+4}" cy="{y*8+4}" r="2" fill="#141011"/>' for x in range(8) for y in range(8))+'</svg>'),
}
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome',args=['--allow-file-access-from-files'])
        for n,(w,h,svg) in A.items():
            pg=await b.new_page(viewport={'width':w,'height':h})
            open("/tmp/a.html","w").write(f"<html><head><style>@font-face{{font-family:Bangers;src:url(file://{F}Bangers-400.woff2)}}body{{margin:0;background:transparent}}svg{{display:block}}</style></head><body>{DEFS}{svg}</body></html>"); await pg.goto("file:///tmp/a.html")
            await pg.wait_for_timeout(400)
            await pg.screenshot(path=f'{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h}); await pg.close()
        await b.close()
asyncio.run(main())
