from fx import *
from PIL import Image, ImageDraw, ImageChops

W, H = 1920, 1080
S = (W, H)
chars = grade(Image.open("cap/H.png").convert("RGBA"), 1.1, 1.2)

# Background: dusk sky over the arena, the brand's vermilion band, ink burst
bg = vgradient(S, [(0, (22, 10, 46)), (0.45, (120, 32, 70)), (0.72, (232, 96, 40)), (1, (255, 178, 70))])
cx, cy = 960, 470
bg.alpha_composite(radial(S, (cx, cy), 900, (255, 120, 40), power=1.4, alpha=170))
bg.alpha_composite(rays(S, (cx, cy), 36, (255, 236, 200), alpha=55, spread=0.45))
k = text_layer(S, (300, 560), "忍", font(CJK, 760), (0, 0, 0))
k.putalpha(k.getchannel("A").point(lambda v: v * 0.10))
bg.alpha_composite(k)
k2 = text_layer(S, (1640, 560), "闘", font(CJK, 760), (0, 0, 0))
k2.putalpha(k2.getchannel("A").point(lambda v: v * 0.10))
bg.alpha_composite(k2)
bg.alpha_composite(ink_band(S, 880, 120, -9, VERMILION, 235))
ground = vgradient((W, 260), [(0, (40, 18, 22)), (1, (12, 6, 10))])
ground.putalpha(vgradient((W, 260), [(0, (0, 0, 0)), (0.25, (200, 200, 200)), (1, (255, 255, 255))]).convert("L"))
bg.alpha_composite(ground, (0, H - 260))
bg.alpha_composite(speed_lines(S, (cx, cy), 160, (255, 250, 235), inner=380, alpha=(40, 140)))

# Fighters, scaled to fill the frame
scale = 1.24
layer, bb, pos = place(bg, chars, scale, (W / 2, H + 10))
naruto_fist = map_point((880, 396), bb, scale, pos)
sasuke_fist = map_point((1040, 396), bb, scale, pos)
clash = ((naruto_fist[0] + sasuke_fist[0]) / 2, naruto_fist[1])

# split rim lights: orange from the left (Naruto side), blue from the right
half = Image.new("L", S, 0); ImageDraw.Draw(half).rectangle([0, 0, W // 2, H], fill=255)
gl = glow_of(layer, (255, 150, 40), grow=6, blur=22, strength=1.2); gl.putalpha(ImageChops.multiply(gl.getchannel("A"), half))
gr = glow_of(layer, (70, 140, 255), grow=6, blur=22, strength=1.3); gr.putalpha(ImageChops.multiply(gr.getchannel("A"), ImageChops.invert(half)))
bg.alpha_composite(gl); bg.alpha_composite(gr)
bg.alpha_composite(outline_of(layer, INK, 5))
bg.alpha_composite(layer)
bg.alpha_composite(rim_light(layer, (255, 170, 60), (-1, 0), 9, 0.9))
bg.alpha_composite(rim_light(layer, (110, 170, 255), (1, 0), 9, 0.9))

# The clash: Rasengan (blue swirl) meets Chidori (lightning)
bg.alpha_composite(radial(S, clash, 520, (255, 255, 255), power=2.4, alpha=210))
bg.alpha_composite(orb(S, (naruto_fist[0] + 6, naruto_fist[1] - 4), 92))
bg.alpha_composite(chidori(S, (sasuke_fist[0] - 4, sasuke_fist[1] + 4), 70))
bg.alpha_composite(lightning(S, (sasuke_fist[0]+30, sasuke_fist[1]+40), (sasuke_fist[0] + 200, sasuke_fist[1] + 330), (130, 185, 255), 6, seed=4, branches=1, jag=22))
bg.alpha_composite(sparks(S, clash, 40, (255, 236, 170), rmin=60, rmax=200, length=(15, 45)))
bg.alpha_composite(radial(S, clash, 150, (235, 245, 255), power=0.8, alpha=255))

# Logo
bg.alpha_composite(text_layer(S, (W / 2, 128), "NINJA DUEL", font(LUCKY, 190), PAPER, stroke=16, stroke_fill=INK,
                              gradient=((255, 242, 160), (255, 138, 30)), shadow=(0, 14, INK, 0), angle=0))
bg.alpha_composite(badge(S, (1505, 214), "BETA", font(LUCKY, 64), VERMILION, PAPER, angle=-8))
bg.alpha_composite(vignette(S, 0.5))
bg.convert("RGB").save("out/thumb1_clash.png")
print("ok", clash)
