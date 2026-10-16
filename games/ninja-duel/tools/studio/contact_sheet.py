"""python nd_sheet.py out.jpg cols width img1 img2 ... -> contact sheet"""
import sys
from PIL import Image, ImageDraw
out, cols, width = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
paths = sys.argv[4:]
import os
crop=os.environ.get('CROP')
ims = [Image.open(p).convert('RGB') for p in paths]
if crop:
    box=tuple(int(v) for v in crop.split(','))
    ims=[im.crop(box) for im in ims]
w = width; h = int(ims[0].height * w / ims[0].width)
rows = (len(ims) + cols - 1) // cols
sheet = Image.new('RGB', (cols * w, rows * h), (0, 0, 0))
for i, (p, im) in enumerate(zip(paths, ims)):
    im = im.resize((w, h))
    d = ImageDraw.Draw(im); d.text((6, 6), os.path.basename(p)[:28], fill=(255, 255, 0))
    sheet.paste(im, ((i % cols) * w, (i // cols) * h))
sheet.save(out, quality=88)
print(out)
