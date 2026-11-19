import asyncio
from playwright.async_api import async_playwright
S='fill="#000"'; L='fill="none" stroke="#000" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"'
I={
'kunai':f'<path {S} d="M32 4 L41 30 L32 38 L23 30 Z"/><rect {S} x="28.5" y="38" width="7" height="14" rx="1"/><circle {L} cx="32" cy="57" r="4.5" stroke-width="4"/>',
'bolt':f'<path {S} d="M37 3 L13 37 L29 37 L23 61 L51 24 L34 24 Z"/>',
'mark':f'<circle {L} cx="32" cy="32" r="20" stroke-width="5"/><path {S} d="M32 6 L38 26 L32 31 L26 26 Z M32 58 L38 38 L32 33 L26 38 Z M6 32 L26 26 L31 32 L26 38 Z M58 32 L38 26 L33 32 L38 38 Z"/>',
'wind':f'<path {L} d="M6 22 H40 a8 8 0 1 0 -8 -8"/><path {L} d="M6 34 H50 a8 8 0 1 1 -8 8"/><path {L} d="M10 46 H28"/>',
'flash':f'<path {S} d="M40 2 L18 34 L32 34 L26 62 L52 25 L37 25 Z"/><path {L} stroke-width="4" d="M4 20 H14 M2 32 H12 M6 44 H14"/>',
'fire':f'<path {S} d="M32 4 C 36 18, 50 22, 50 40 C 50 52, 42 60, 32 60 C 22 60, 14 52, 14 40 C 14 30, 20 26, 22 18 C 26 26, 28 28, 30 28 C 30 20, 30 12, 32 4 Z"/><path fill="#fff" d="M32 34 C 36 40, 40 44, 40 50 C 40 55, 36 58, 32 58 C 28 58, 24 55, 24 50 C 24 44, 30 42, 32 34 Z"/>',
'spiral':f'<circle {S} cx="32" cy="32" r="26"/><path fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round" d="M32 32 m0 -4 a4 4 0 1 1 -4 4 a9 9 0 1 1 9 9 a14 14 0 1 1 -14 -14 a19 19 0 1 1 19 19"/>',
'clone':f'<circle {S} cx="22" cy="18" r="8"/><path {S} d="M10 54 C 10 36, 14 28, 22 28 C 30 28, 34 36, 34 54 Z"/><circle {L} stroke-width="4" cx="42" cy="18" r="8"/><path {L} stroke-width="4" d="M30 54 C 30 36, 34 28, 42 28 C 50 28, 54 36, 54 54 Z"/>',
'sand':f'<circle {S} cx="14" cy="46" r="6"/><circle {S} cx="28" cy="50" r="5"/><circle {S} cx="44" cy="46" r="7"/><circle {S} cx="22" cy="34" r="4"/><circle {S} cx="38" cy="32" r="5"/><circle {S} cx="50" cy="30" r="3"/><circle {S} cx="30" cy="20" r="3.5"/><circle {S} cx="44" cy="16" r="2.5"/>',
'eye':f'<path {S} d="M2 32 C 14 12, 50 12, 62 32 C 50 52, 14 52, 2 32 Z"/><circle fill="#fff" cx="32" cy="32" r="12"/><circle {S} cx="32" cy="32" r="6"/>',
'palm':f'<path {S} d="M18 60 L16 34 L10 24 C 8 20, 13 17, 16 21 L20 28 L20 8 C 20 4, 26 4, 26 8 L26 26 L28 4 C 28 0, 34 0, 34 4 L33 26 L36 7 C 36 3, 42 3, 42 7 L39 28 L44 13 C 45 9, 51 10, 50 14 L44 40 L40 60 Z"/>',
'water':f'<path {S} d="M32 4 C 40 18, 50 28, 50 40 C 50 52, 42 60, 32 60 C 22 60, 14 52, 14 40 C 14 28, 24 18, 32 4 Z"/><path fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" d="M22 42 C 22 48, 26 52, 32 52"/>',
'whirl':f'<path {L} d="M32 8 a24 24 0 1 1 -22 14"/><path {L} d="M32 18 a14 14 0 1 1 -12 8"/><path {S} d="M4 18 L16 14 L14 28 Z"/>',
'shuriken':f'<path {S} d="M32 2 L37 27 L62 32 L37 37 L32 62 L27 37 L2 32 L27 27 Z"/><circle fill="#fff" cx="32" cy="32" r="5"/>',
'fist':f'<path {S} d="M12 26 C 12 18, 18 16, 22 18 C 24 12, 32 12, 34 18 C 36 12, 44 13, 45 19 C 48 15, 56 17, 55 25 L54 44 C 53 54, 46 60, 36 60 L24 60 C 16 60, 12 54, 12 46 Z"/><path fill="none" stroke="#fff" stroke-width="3" d="M22 22 L23 34 M34 20 L34 34 M45 22 L44 34"/>',
'weights':f'<rect {S} x="6" y="20" width="14" height="24" rx="3"/><rect {S} x="44" y="20" width="14" height="24" rx="3"/><rect {S} x="18" y="28" width="28" height="8"/><path {L} stroke-width="4" d="M10 54 L54 54"/>',
'hound':f'<path {S} d="M8 50 L14 30 L10 14 L22 22 L40 22 L52 12 L50 28 L58 34 L52 40 L40 38 L34 50 Z"/>',
'wire':f'<path {L} stroke-width="4" d="M4 16 L60 48 M4 48 L60 16"/><circle {S} cx="32" cy="32" r="6"/><circle {S} cx="6" cy="16" r="4"/><circle {S} cx="58" cy="48" r="4"/>',
'scroll':f'<rect {S} x="14" y="8" width="36" height="48" rx="3"/><rect fill="#fff" x="20" y="16" width="24" height="3"/><rect fill="#fff" x="20" y="24" width="24" height="3"/><rect fill="#fff" x="20" y="32" width="16" height="3"/>',
}
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg=await b.new_page(viewport={'width':128,'height':128})
        for n,s in I.items():
            await pg.set_content(f'<html><body style="margin:0;background:transparent"><svg viewBox="0 0 64 64" width="128" height="128" style="display:block">{s}</svg></body></html>')
            await pg.screenshot(path=f'icons/icon_{n}.png',omit_background=True)
        await b.close()
asyncio.run(main())
