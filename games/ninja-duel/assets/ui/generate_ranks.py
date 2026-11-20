import asyncio
from playwright.async_api import async_playwright
K='#141011'
def chev(n,col,y0=118):
    return ''.join(f'<path d="M78 {y0+i*24} L128 {y0-26+i*24} L178 {y0+i*24}" fill="none" stroke="{col}" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>' for i in range(n))
def plate(fill,rim,inner=''):
    return f'<path d="M128 14 L228 58 L214 176 L128 242 L42 176 L28 58 Z" fill="{fill}" stroke="{K}" stroke-width="10" stroke-linejoin="round"/><path d="M128 34 L210 70 L198 168 L128 222 L58 168 L46 70 Z" fill="none" stroke="{rim}" stroke-width="6" stroke-linejoin="round"/>{inner}'
R={
'academy':plate('#C99A5B','#8A5A2B',f'<rect x="86" y="96" width="84" height="60" rx="6" fill="#F4E3C1" stroke="{K}" stroke-width="7"/><path d="M98 112 H158 M98 126 H158 M98 140 H140" stroke="{K}" stroke-width="5"/>'),
'genin':plate('#B9C2CC','#5D6670',chev(1,K,132)),
'chunin':plate('#5E8A4A','#2F4A23',chev(2,'#F4E3C1',120)),
'jonin':plate('#2F4A3A','#7FA88A',chev(3,'#F4E3C1',108)),
'anbu':plate('#F2EFE8','#9A9AA0',f'<path d="M86 84 C 86 60, 170 60, 170 84 L164 164 C 150 190, 106 190, 92 164 Z" fill="#fff" stroke="{K}" stroke-width="7"/><path d="M100 112 L120 120 L100 126 Z M156 112 L136 120 L156 126 Z" fill="{K}"/><path d="M104 140 C 112 150, 104 160, 112 170 M152 140 C 144 150, 152 160, 144 170" fill="none" stroke="#C3121D" stroke-width="6" stroke-linecap="round"/>'),
'kage':plate('#C3121D','#FFC23D',f'<path d="M58 150 L128 70 L198 150 Z" fill="#F4E3C1" stroke="{K}" stroke-width="8" stroke-linejoin="round"/><path d="M98 150 L128 112 L158 150" fill="#C3121D" stroke="{K}" stroke-width="6"/><path d="M50 158 H206" stroke="{K}" stroke-width="10" stroke-linecap="round"/><circle cx="128" cy="62" r="9" fill="#FFC23D" stroke="{K}" stroke-width="5"/>'),
}
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg=await b.new_page(viewport={'width':256,'height':256})
        for n,s in R.items():
            await pg.set_content(f'<html><body style="margin:0;background:transparent"><svg viewBox="0 0 256 256" width="256" height="256" style="display:block">{s}</svg></body></html>')
            await pg.screenshot(path=f'ranks/rank_{n}.png',omit_background=True)
        await b.close()
asyncio.run(main())
