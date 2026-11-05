"""FILM01 « THE KUNAI WAS BAIT » text overlays (1080x1920 transparent PNGs).
One font family (Luckiest Guy), two colours: white and Minato's seal gold.
Text sits in the TikTok/Shorts safe band (y 300-1350), never over the fighters'
centre line when placed in CapCut. Run from the factory folder:
    python3 film01_overlays.py OUTDIR
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ov import F, LUCKY, text_layer, canvas, center, INK
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
WHITE = ((255, 255, 255), (232, 232, 232))
SEAL = ((255, 236, 150), (255, 196, 40))   # Minato's seal yellow
def card(name, lines, y=420):
    c = canvas()
    yy = y
    for text, grad, size in lines:
        fnt = F(LUCKY, size)
        lay = text_layer((1080, size + 80), (540, (size + 80) // 2), text, fnt, stroke=12, gradient=grad, shadow=(0, 8, INK, 0))
        center(c, lay, 540, yy)
        yy += int(size * 1.05)
    c.save(os.path.join(OUT, name + ".png"))
card("t1_he_missed", [("HE MISSED?", WHITE, 132)])
card("t2_watch_the_kunai", [("WATCH THE KUNAI", SEAL, 96)])
card("t3_the_kunai_was_the_plan", [("THE KUNAI", WHITE, 110), ("WAS THE PLAN", SEAL, 110)])
card("t4_neji_saw_it", [("NEJI SAW IT.", WHITE, 132)])
card("t5_cta", [("WOULD YOU", WHITE, 112), ("COUNTER IT?", SEAL, 112)], y=430)
card("t6_brand", [("NINJA DUEL", SEAL, 96), ("ON ROBLOX", WHITE, 70)], y=1250)
print("ok", sorted(os.listdir(OUT)))
