import asyncio
from playwright.async_api import async_playwright
K='#141011';R='#C3121D'
ink=f'fill="none" stroke="{K}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"'
def eye(cx,cy,rx=26,ry=30,px=0,py=0,pr=11): return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#fff" stroke="{K}" stroke-width="7"/><circle cx="{cx+px}" cy="{cy+py}" r="{pr}" fill="{K}"/><circle cx="{cx+px+4}" cy="{cy+py-4}" r="3.5" fill="#fff"/>'
F={
# hit: squeezed eyes > <, open wobbly mouth, sweat drop
'hit':f'<path {ink} d="M58 92 L94 110 L58 126"/><path {ink} d="M198 92 L162 110 L198 126"/><path d="M96 176 C 108 160, 148 160, 160 176 C 150 206, 106 206, 96 176 Z" fill="{K}"/><path d="M118 196 C 124 190, 134 190, 140 196" fill="none" stroke="{R}" stroke-width="6" stroke-linecap="round"/><path d="M214 40 C 224 58, 232 66, 232 76 C 232 86, 224 92, 214 92 C 204 92, 196 86, 196 76 C 196 66, 204 58, 214 40 Z" fill="#9fd8ff" stroke="{K}" stroke-width="5"/>',
# guard break: huge round shocked eyes small pupils, O mouth, shock lines
'guardbreak':eye(84,108,32,36,0,0,6)+eye(172,108,32,36,0,0,6)+f'<ellipse cx="128" cy="190" rx="18" ry="22" fill="{K}"/><path {ink} stroke-width="6" d="M40 50 L58 66 M128 26 L128 48 M216 50 L198 66"/>',
# ko: X eyes, wavy mouth, tongue
'ko':f'<path {ink} d="M60 90 L104 130 M104 90 L60 130"/><path {ink} d="M152 90 L196 130 M196 90 L152 130"/><path {ink} d="M84 182 C 98 170, 112 194, 128 182 C 144 170, 158 194, 172 182"/><path d="M134 186 C 136 204, 154 206, 156 190" fill="#F07A86" stroke="{K}" stroke-width="5"/><g fill="{K}"><path d="M40 40 l6 14 l14 6 l-14 6 l-6 14 l-6 -14 l-14 -6 l14 -6z"/><path d="M216 34 l5 11 l11 5 l-11 5 l-5 11 l-5 -11 l-11 -5 l11 -5z"/></g>',
# victory: happy closed arcs ^ ^, big grin, sparkle
'victory':f'<path {ink} d="M56 116 C 66 88, 102 88, 112 116"/><path {ink} d="M144 116 C 154 88, 190 88, 200 116"/><path d="M78 160 C 100 214, 156 214, 178 160 Z" fill="{K}"/><path d="M90 166 L166 166 L162 176 L94 176 Z" fill="#fff"/><path d="M220 36 C 222 52, 226 56, 242 58 C 226 60, 222 64, 220 80 C 218 64, 214 60, 198 58 C 214 56, 218 52, 220 36 Z" fill="#FFC23D" stroke="{K}" stroke-width="4"/>',
# focus: narrowed eyes, brows down straight, small flat mouth, drop of sweat? no: lines
'focus':f'<path {ink} d="M50 82 L108 94"/><path {ink} d="M206 82 L148 94"/><path d="M58 112 C 72 102, 96 102, 108 112 C 96 122, 72 122, 58 112 Z" fill="#fff" stroke="{K}" stroke-width="6"/><circle cx="86" cy="112" r="8" fill="{K}"/><path d="M148 112 C 160 102, 184 102, 198 112 C 184 122, 160 122, 148 112 Z" fill="#fff" stroke="{K}" stroke-width="6"/><circle cx="170" cy="112" r="8" fill="{K}"/><path {ink} d="M104 184 L152 184"/>',
# rage: angled brows, sharp eyes, gritted teeth, red vein
'rage':f'<path {ink} stroke-width="11" d="M46 76 L110 100"/><path {ink} stroke-width="11" d="M210 76 L146 100"/><path d="M56 108 L108 108 L100 128 L64 124 Z" fill="#fff" stroke="{K}" stroke-width="6"/><circle cx="90" cy="116" r="7" fill="{K}"/><path d="M200 108 L148 108 L156 128 L192 124 Z" fill="#fff" stroke="{K}" stroke-width="6"/><circle cx="166" cy="116" r="7" fill="{K}"/><rect x="82" y="166" width="92" height="38" rx="6" fill="#fff" stroke="{K}" stroke-width="7"/><path d="M82 185 L174 185 M105 166 L105 204 M128 166 L128 204 M151 166 L151 204" stroke="{K}" stroke-width="4"/><g fill="none" stroke="{R}" stroke-width="8" stroke-linecap="round"><path d="M206 28 C 208 42, 202 46, 190 46"/><path d="M222 28 C 220 42, 226 46, 238 46"/><path d="M206 74 C 208 60, 202 56, 190 56"/><path d="M222 74 C 220 60, 226 56, 238 56"/></g>',
}
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg=await b.new_page(viewport={'width':256,'height':256})
        for n,s in F.items():
            await pg.set_content(f'<html><body style="margin:0;background:transparent"><svg viewBox="0 0 256 256" width="256" height="256" style="display:block">{s}</svg></body></html>')
            await pg.screenshot(path=f'faces/face_{n}.png',omit_background=True)
        await b.close()
asyncio.run(main())
